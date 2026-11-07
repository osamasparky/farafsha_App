<?php

namespace App\Http\Controllers\Api;

use App\Events\GameStarted;
use App\Events\PlayerAnswered;
use App\Events\PlayerJoinedRoom;
use App\Events\RoundEnded;
use App\Events\RoundStarted;
use App\Http\Controllers\Controller;
use App\Models\ContentItem;
use App\Models\Game;
use App\Models\Room;
use App\Models\RoomPlayer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class RoomController extends Controller
{
    /**
     * إنشاء غرفة لعب جديدة
     */
    public function store(Request $request): JsonResponse
    {
        $gameId = $request->input('game_id') ?: Game::where('slug', $request->input('game_slug'))->value('id');
        $hostName = $request->input('host_name') ?: 'أسامة';

        $data = array_merge($request->all(), [
            'game_id' => $gameId,
            'host_name' => $hostName,
        ]);

        $validated = validator($data, [
            'game_id' => 'required|exists:games,id',
            'host_name' => 'required|string|max:50',
            'max_players' => 'nullable|integer|min:2|max:12',
            'total_rounds' => 'nullable|integer|min:3|max:20',
            'round_duration_seconds' => 'nullable|integer|min:10|max:120',
            'difficulty' => 'nullable|string',
        ])->validate();

        // توليد رمز غرفة عشوائي مكون من 6 أرقام فريدة مثل 784521
        do {
            $code = (string) random_int(100000, 999999);
        } while (Room::where('code', $code)->exists());

        $room = Room::create([
            'code' => $code,
            'host_name' => $validated['host_name'],
            'game_id' => $validated['game_id'],
            'status' => 'waiting',
            'max_players' => $validated['max_players'] ?? 8,
            'total_rounds' => $validated['total_rounds'] ?? 10,
            'round_duration_seconds' => $validated['round_duration_seconds'] ?? 20,
            'difficulty' => $validated['difficulty'] ?? 'medium',
            'last_active_at' => now(),
        ]);

        $hostToken = Str::random(32);

        $hostPlayer = RoomPlayer::create([
            'room_id' => $room->id,
            'player_name' => $validated['host_name'],
            'is_host' => true,
            'is_ready' => true,
            'score' => 0,
            'session_token' => $hostToken,
            'last_seen_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'room' => $room->load(['game', 'players']),
            'player' => $hostPlayer,
            'token' => $hostToken,
        ], 201);
    }

    /**
     * الاستعلام عن حالة الغرفة واللاعبين الحاليين
     */
    public function show(string $code): JsonResponse
    {
        $room = Room::where('code', $code)
            ->with(['game', 'players'])
            ->firstOrFail();

        return response()->json([
            'status' => 'success',
            'room' => $room,
        ]);
    }

    /**
     * انضمام لاعب إلى الغرفة عبر الكود وبث الحدث لحظياً
     */
    public function join(Request $request, string $code): JsonResponse
    {
        $validated = $request->validate([
            'player_name' => 'required|string|max:50',
            'avatar' => 'nullable|string',
        ]);

        $room = Room::where('code', $code)->firstOrFail();

        if ($room->status !== 'waiting') {
            return response()->json([
                'status' => 'error',
                'message' => 'اللعبة قد بدأت بالفعل أو الغرفة غير متاحة.',
            ], 422);
        }

        if ($room->players()->count() >= $room->max_players) {
            return response()->json([
                'status' => 'error',
                'message' => 'الغرفة ممتلئة بالكامل.',
            ], 422);
        }

        $playerToken = Str::random(32);

        $player = RoomPlayer::create([
            'room_id' => $room->id,
            'player_name' => $validated['player_name'],
            'avatar' => $validated['avatar'] ?? null,
            'is_host' => false,
            'is_ready' => true,
            'score' => 0,
            'session_token' => $playerToken,
            'last_seen_at' => now(),
        ]);

        $room->update(['last_active_at' => now()]);
        $totalPlayers = $room->players()->count();

        // بث لحظي عبر WebSockets لجميع المتواجدين في الغرفة
        $this->safeBroadcast(new PlayerJoinedRoom($room->code, $player, $totalPlayers));

        return response()->json([
            'status' => 'success',
            'room' => $room->load(['game', 'players']),
            'player' => $player,
            'token' => $playerToken,
        ]);
    }

    /**
     * بدء اللعبة من قِبل المضيف وبث أحداث الجولة الأولى
     */
    public function start(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->firstOrFail();

        // جلب أسئلة الجولات عشوائياً
        $cards = ContentItem::where('game_id', $room->game_id)
            ->where('is_active', true)
            ->where('status', 'published')
            ->inRandomOrder()
            ->limit($room->total_rounds)
            ->get();

        if ($cards->isEmpty()) {
            return response()->json([
                'status' => 'error',
                'message' => 'لا يتوفر محتوى كافٍ لهذه اللعبة حالياً.',
            ], 422);
        }

        $firstCard = $cards->first();

        $room->update([
            'status' => 'playing',
            'current_round' => 1,
            'game_state' => [
                'current_card_id' => $firstCard->id,
                'round_started_at' => now()->timestamp,
                'all_cards_ids' => $cards->pluck('id')->toArray(),
                'answers' => [],
            ],
            'last_active_at' => now(),
        ]);

        // تجهيز بيانات السؤال بدون الإجابة الصحيحة لمنع الغش في الفرونت
        $publicCard = [
            'id' => $firstCard->id,
            'prompt' => $firstCard->prompt,
            'distractors' => $firstCard->distractors ?? [],
            'choices' => array_values(collect([$firstCard->answer, ...($firstCard->distractors ?? [])])->shuffle()->toArray()),
            'media_url' => $firstCard->media_url,
        ];

        // بث حدث بدء اللعبة والجولة الأولى لجميع اللاعبين فوراً
        $this->safeBroadcast(new GameStarted($room, $publicCard));
        $this->safeBroadcast(new RoundStarted($room->code, 1, $room->total_rounds, $room->round_duration_seconds, $publicCard));

        return response()->json([
            'status' => 'success',
            'message' => 'تم بدء اللعبة بنجاح.',
            'room' => $room->fresh(['game', 'players']),
            'card' => $publicCard,
        ]);
    }

    /**
     * إرسال إجابة لاعب وبث التحديث لحظياً
     */
    public function answer(Request $request, string $code): JsonResponse
    {
        $validated = $request->validate([
            'player_token' => 'required|string',
            'answer' => 'required|string',
            'time_taken_seconds' => 'nullable|integer',
        ]);

        $room = Room::where('code', $code)->firstOrFail();
        $player = RoomPlayer::where('room_id', $room->id)
            ->where('session_token', $validated['player_token'])
            ->firstOrFail();

        $gameState = $room->game_state ?? [];
        $currentCardId = $gameState['current_card_id'] ?? null;
        $card = ContentItem::find($currentCardId);

        if (!$card) {
            return response()->json(['status' => 'error', 'message' => 'الجولة غير صالحة'], 422);
        }

        $isCorrect = trim(mb_strtolower($validated['answer'])) === trim(mb_strtolower($card->answer));
        $pointsEarned = $isCorrect ? 3 : 0;

        if ($pointsEarned > 0) {
            $player->increment('score', $pointsEarned);
        }

        $answers = $gameState['answers'] ?? [];
        $answers[$player->id] = [
            'player_id' => $player->id,
            'is_correct' => $isCorrect,
            'points' => $pointsEarned,
        ];
        $gameState['answers'] = $answers;
        $room->update(['game_state' => $gameState]);

        $totalPlayers = $room->players()->count();
        $answeredCount = count($answers);

        // بث إشعار أن اللاعب الفلاني أجاب (بدون كشف هل هي صحيحة لحين انتهاء الجميع)
        $this->safeBroadcast(new PlayerAnswered($room->code, $player->id, $player->player_name, $answeredCount, $totalPlayers));

        // إذا أجاب جميع اللاعبين، يتم إنهاء الجولة فوراً وبث النتيجة
        if ($answeredCount >= $totalPlayers) {
            $leaderboard = $room->players()->orderBy('score', 'desc')->get(['id', 'player_name', 'score'])->toArray();
            $isGameOver = $room->current_round >= $room->total_rounds;

            $this->safeBroadcast(new RoundEnded(
                $room->code,
                $room->current_round,
                $card->answer,
                $card->explanation,
                $leaderboard,
                $isGameOver
            ));
        }

        return response()->json([
            'status' => 'success',
            'is_correct' => $isCorrect,
            'points_earned' => $pointsEarned,
            'total_score' => $player->score,
        ]);
    }

    private function safeBroadcast($event): void
    {
        try {
            broadcast($event);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('Broadcast failed (continuing normally): ' . $e->getMessage());
        }
    }
}
