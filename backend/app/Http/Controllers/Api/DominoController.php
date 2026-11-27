<?php

namespace App\Http\Controllers\Api;

use App\Events\DominoStateUpdated;
use App\Http\Controllers\Controller;
use App\Models\Room;
use App\Models\RoomPlayer;
use App\Services\DominoEngine;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DominoController extends Controller
{
    private function resolvePlayer(Request $request, Room $room): RoomPlayer
    {
        $playerToken = $request->header('X-Player-Token') ?: ($request->input('player_token') ?: $request->query('token'));
        $player = $playerToken
            ? RoomPlayer::where('room_id', $room->id)->where('session_token', $playerToken)->first()
            : null;

        if (!$player) {
            $user = auth('sanctum')->user();
            if ($user) {
                $player = RoomPlayer::where('room_id', $room->id)->where('user_id', $user->id)->first();
            }
        }

        abort_unless($player, 403, 'غير مصرح لك باللعب في هذه الغرفة.');

        return $player;
    }

    /**
     * لعب بلاطة دومينو على الطرف الأيسر أو الأيمن
     */
    public function play(Request $request, string $code): JsonResponse
    {
        $validated = $request->validate([
            'tile' => 'required|array|size:2',
            'tile.*' => 'integer|min:0|max:6',
            'side' => 'required|in:left,right',
        ]);

        $room = Room::where('code', $code)->with(['game', 'players'])->firstOrFail();
        $player = $this->resolvePlayer($request, $room);
        $state = $room->game_state ?? [];

        if (($state['game_type'] ?? '') !== 'domino' || !empty($state['round_ended'])) {
            return response()->json(['status' => 'error', 'message' => 'الجولة غير نشطة حالياً.'], 422);
        }

        if ((int) ($state['current_turn_player_id'] ?? 0) !== (int) $player->id) {
            return response()->json(['status' => 'error', 'message' => 'ليس دورك الآن.'], 422);
        }

        $hand = $state['hands'][(string) $player->id] ?? [];
        $reqTile = [(int) $validated['tile'][0], (int) $validated['tile'][1]];
        $handIndex = null;

        foreach ($hand as $idx => $t) {
            if (($t[0] === $reqTile[0] && $t[1] === $reqTile[1]) || ($t[0] === $reqTile[1] && $t[1] === $reqTile[0])) {
                $handIndex = $idx;
                break;
            }
        }

        if ($handIndex === null) {
            return response()->json(['status' => 'error', 'message' => 'البلاطة غير موجودة في يدك.'], 422);
        }

        $side = $validated['side'];
        if (!DominoEngine::canPlayTile($hand[$handIndex], $state['left_end'], $state['right_end'], $side)) {
            return response()->json(['status' => 'error', 'message' => 'لا يمكن وضع هذه البلاطة على هذا الطرف.'], 422);
        }

        DominoEngine::placeTile($state, (int) $player->id, $handIndex, $side);

        $this->persistAndSyncScores($room, $state);

        return response()->json([
            'status' => 'success',
            'domino_state' => DominoEngine::buildPublicStateForPlayer($state, (int) $player->id, $room->round_duration_seconds),
        ]);
    }

    /**
     * سحب بلاطة من السوق (Boneyard)
     */
    public function draw(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->with(['game', 'players'])->firstOrFail();
        $player = $this->resolvePlayer($request, $room);
        $state = $room->game_state ?? [];

        if (($state['game_type'] ?? '') !== 'domino' || !empty($state['round_ended'])) {
            return response()->json(['status' => 'error', 'message' => 'الجولة غير نشطة حالياً.'], 422);
        }

        if ((int) ($state['current_turn_player_id'] ?? 0) !== (int) $player->id) {
            return response()->json(['status' => 'error', 'message' => 'ليس دورك الآن.'], 422);
        }

        $hand = $state['hands'][(string) $player->id] ?? [];
        if (DominoEngine::hasAnyValidMove($hand, $state['left_end'], $state['right_end'])) {
            return response()->json(['status' => 'error', 'message' => 'لديك بلاطة صالحة للعب بالفعل.'], 422);
        }

        if (($state['play_mode'] ?? 'draw') === 'block') {
            return response()->json(['status' => 'error', 'message' => 'طريقة اللعب بلوك: لا يوجد سحب، اضغط دق للتخطي.'], 422);
        }

        if (empty($state['boneyard'])) {
            return response()->json(['status' => 'error', 'message' => 'السوق فارغ، استخدم التخطي.'], 422);
        }

        $drawn = array_shift($state['boneyard']);
        $state['hands'][(string) $player->id][] = $drawn;
        $state['last_move'] = [
            'type' => 'draw',
            'player_id' => (int) $player->id,
        ];

        $room->update(['game_state' => $state, 'last_active_at' => now()]);
        $this->safeBroadcast(new DominoStateUpdated($room->code, ['type' => 'draw', 'player_id' => $player->id]));

        return response()->json([
            'status' => 'success',
            'drawn_tile' => $drawn,
            'domino_state' => DominoEngine::buildPublicStateForPlayer($state, (int) $player->id, $room->round_duration_seconds),
        ]);
    }

    /**
     * تخطي الدور عند فراغ السوق وعدم توفر حركة صالحة
     */
    public function pass(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->with(['game', 'players'])->firstOrFail();
        $player = $this->resolvePlayer($request, $room);
        $state = $room->game_state ?? [];

        if (($state['game_type'] ?? '') !== 'domino' || !empty($state['round_ended'])) {
            return response()->json(['status' => 'error', 'message' => 'الجولة غير نشطة حالياً.'], 422);
        }

        if ((int) ($state['current_turn_player_id'] ?? 0) !== (int) $player->id) {
            return response()->json(['status' => 'error', 'message' => 'ليس دورك الآن.'], 422);
        }

        $hand = $state['hands'][(string) $player->id] ?? [];
        if (DominoEngine::hasAnyValidMove($hand, $state['left_end'], $state['right_end'])) {
            return response()->json(['status' => 'error', 'message' => 'لديك بلاطة صالحة للعب.'], 422);
        }

        if (($state['play_mode'] ?? 'draw') !== 'block' && !empty($state['boneyard'])) {
            return response()->json(['status' => 'error', 'message' => 'يجب السحب من المخزن أولاً.'], 422);
        }

        $this->applyPass($state, (int) $player->id);
        $this->persistAndSyncScores($room, $state);

        return response()->json([
            'status' => 'success',
            'domino_state' => DominoEngine::buildPublicStateForPlayer($state, (int) $player->id, $room->round_duration_seconds),
        ]);
    }

    /**
     * انتهاء وقت الدور: لعب تلقائي أو سحب/تخطي حتى لا تتجمد الغرفة
     */
    public function timeout(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->with(['game', 'players'])->firstOrFail();
        $player = $this->resolvePlayer($request, $room);
        $state = $room->game_state ?? [];

        if (($state['game_type'] ?? '') !== 'domino' || !empty($state['round_ended'])) {
            return response()->json([
                'status' => 'success',
                'domino_state' => DominoEngine::buildPublicStateForPlayer($state, (int) $player->id, $room->round_duration_seconds),
            ]);
        }

        $elapsed = now()->timestamp - (int) ($state['turn_started_at'] ?? now()->timestamp);
        if ($elapsed < max(5, $room->round_duration_seconds - 1)) {
            return response()->json([
                'status' => 'success',
                'domino_state' => DominoEngine::buildPublicStateForPlayer($state, (int) $player->id, $room->round_duration_seconds),
            ]);
        }

        $turnPid = (int) ($state['current_turn_player_id'] ?? 0);
        $hand = $state['hands'][(string) $turnPid] ?? [];
        $played = false;

        foreach ($hand as $idx => $tile) {
            if (DominoEngine::canPlayTile($tile, $state['left_end'], $state['right_end'], 'right')) {
                DominoEngine::placeTile($state, $turnPid, $idx, 'right');
                $played = true;
                break;
            }
            if (DominoEngine::canPlayTile($tile, $state['left_end'], $state['right_end'], 'left')) {
                DominoEngine::placeTile($state, $turnPid, $idx, 'left');
                $played = true;
                break;
            }
        }

        if (!$played) {
            if (!empty($state['boneyard'])) {
                $drawn = array_shift($state['boneyard']);
                $state['hands'][(string) $turnPid][] = $drawn;
                $newIdx = count($state['hands'][(string) $turnPid]) - 1;
                if (DominoEngine::canPlayTile($drawn, $state['left_end'], $state['right_end'], 'right')) {
                    DominoEngine::placeTile($state, $turnPid, $newIdx, 'right');
                } elseif (DominoEngine::canPlayTile($drawn, $state['left_end'], $state['right_end'], 'left')) {
                    DominoEngine::placeTile($state, $turnPid, $newIdx, 'left');
                } else {
                    DominoEngine::advanceTurn($state);
                }
            } else {
                $this->applyPass($state, $turnPid);
            }
        }

        $this->persistAndSyncScores($room, $state);

        return response()->json([
            'status' => 'success',
            'domino_state' => DominoEngine::buildPublicStateForPlayer($state, (int) $player->id, $room->round_duration_seconds),
        ]);
    }

    /**
     * بدء الجولة التالية حتى الوصول لـ 100 نقطة
     */
    public function nextRound(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->with(['game', 'players'])->firstOrFail();
        $player = $this->resolvePlayer($request, $room);
        $state = $room->game_state ?? [];

        if (($state['game_type'] ?? '') !== 'domino' || empty($state['round_ended'])) {
            return response()->json(['status' => 'error', 'message' => 'الجولة لم تنتهِ بعد.'], 422);
        }

        if (!empty($state['match_over'])) {
            return app(RoomController::class)->finish($request, $code);
        }

        $nextRoundNum = ((int) ($state['round_number'] ?? 1)) + 1;
        $starterId = (int) ($state['round_winner']['player_id'] ?? $state['turn_order'][0]);

        $newState = DominoEngine::dealRound(
            $state['turn_order'],
            !empty($state['team_mode']),
            $state['match_scores'] ?? [],
            (int) ($state['target_score'] ?? 101),
            $nextRoundNum,
            $starterId,
            (string) ($state['play_mode'] ?? 'draw')
        );

        $room->update([
            'current_round' => $nextRoundNum,
            'game_state' => $newState,
            'last_active_at' => now(),
        ]);

        $this->safeBroadcast(new DominoStateUpdated($room->code, ['type' => 'next_round', 'round' => $nextRoundNum]));

        return response()->json([
            'status' => 'success',
            'domino_state' => DominoEngine::buildPublicStateForPlayer($newState, (int) $player->id, $room->round_duration_seconds),
        ]);
    }

    private function applyPass(array &$state, int $playerId): void
    {
        $state['consecutive_passes'] = ((int) ($state['consecutive_passes'] ?? 0)) + 1;
        $state['last_move'] = ['type' => 'pass', 'player_id' => $playerId];

        if ($state['consecutive_passes'] >= count($state['turn_order'])) {
            DominoEngine::resolveRoundEnd($state, null, true);
            return;
        }

        DominoEngine::advanceTurn($state);
    }

    private function persistAndSyncScores(Room $room, array &$state): void
    {
        // تحديث نقاط اللاعبين في الغرفة لتتطابق مع match_scores
        if (!empty($state['round_ended'])) {
            $is2v2 = !empty($state['team_mode']) && !empty($state['teams']);
            foreach ($room->players as $p) {
                if ($is2v2) {
                    $teamKey = in_array((int) $p->id, $state['teams']['team_a'] ?? [], true) ? 'team_a' : 'team_b';
                    $p->update(['score' => (int) ($state['match_scores'][$teamKey] ?? 0)]);
                } else {
                    $p->update(['score' => (int) ($state['match_scores'][(string) $p->id] ?? 0)]);
                }
            }
        }

        $room->update([
            'game_state' => $state,
            'last_active_at' => now(),
        ]);

        if (!empty($state['match_over'])) {
            app(RoomController::class)->finish(request(), $room->code);
        }

        $this->safeBroadcast(new DominoStateUpdated($room->code, [
            'type' => $state['last_move']['type'] ?? 'update',
            'round_ended' => !empty($state['round_ended']),
            'match_over' => !empty($state['match_over']),
        ]));
    }

    private function safeBroadcast($event): void
    {
        try {
            broadcast($event);
        } catch (\Throwable $e) {
            Log::warning('Domino broadcast failed: ' . $e->getMessage());
        }
    }
}
