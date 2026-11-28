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
use App\Models\Level;
use App\Models\Room;
use App\Models\RoomPlayer;
use App\Models\User;
use App\Services\DominoEngine;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class RoomController extends Controller
{
    /**
     * إنشاء غرفة لعب جديدة بواسطة المضيف (Host)
     */
    public function store(Request $request): JsonResponse
    {
        $user = auth('sanctum')->user();

        $gameId = $request->input('game_id') ?: Game::where('slug', $request->input('game_slug'))->value('id');
        $hostName = $request->input('host_name') ?: ($user?->name ?: 'لاعب فرفشة');

        $data = array_merge($request->all(), [
            'game_id' => $gameId,
            'host_name' => $hostName,
        ]);

        $validated = validator($data, [
            'game_id' => 'required|exists:games,id',
            'host_name' => 'required|string|max:50',
            'max_players' => 'nullable|integer|min:2|max:16',
            'total_rounds' => 'nullable|integer|min:3|max:20',
            'round_duration_seconds' => 'nullable|integer|min:10|max:120',
            'difficulty' => 'nullable|string',
            'team_mode' => 'nullable|boolean',
            'target_score' => 'nullable|integer|min:20|max:500',
            'play_mode' => 'nullable|in:draw,block',
        ])->validate();

        $game = Game::find($validated['game_id']);
        $isDomino = $game?->slug === 'domino';
        $maxPlayers = $isDomino
            ? max(2, min(4, (int) ($validated['max_players'] ?? 4)))
            : ($validated['max_players'] ?? 8);

        // توليد رمز غرفة عشوائي مكون من 6 أرقام فريدة
        $code = null;
        for ($attempt = 0; $attempt < 30; $attempt++) {
            $candidate = (string) random_int(100000, 999999);
            if (!Room::where('code', $candidate)->exists()) {
                $code = $candidate;
                break;
            }
        }
        if ($code === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'تعذر توليد رمز غرفة متاح حالياً، يرجى المحاولة مجدداً.',
            ], 503);
        }

        $initialGameState = $isDomino ? [
            'game_type' => 'domino',
            'play_mode' => $validated['play_mode'] ?? 'draw',
            'team_mode' => (bool) ($validated['team_mode'] ?? false),
            'target_score' => (int) ($validated['target_score'] ?? 101),
        ] : [];

        $room = Room::create([
            'code' => $code,
            'host_user_id' => $user?->id,
            'host_name' => $validated['host_name'],
            'game_id' => $validated['game_id'],
            'status' => 'waiting',
            'max_players' => $maxPlayers,
            'total_rounds' => $validated['total_rounds'] ?? 10,
            'round_duration_seconds' => $validated['round_duration_seconds'] ?? ($isDomino ? 25 : 20),
            'difficulty' => $validated['difficulty'] ?? 'medium',
            'game_state' => $initialGameState,
            'last_active_at' => now(),
        ]);

        $hostToken = Str::random(32);

        $hostPlayer = RoomPlayer::create([
            'room_id' => $room->id,
            'user_id' => $user?->id,
            'player_name' => $validated['host_name'],
            'avatar' => $user?->avatar ?? 'assets/images/av-karim.png',
            'is_host' => true,
            'is_ready' => true,
            'score' => 0,
            'connection_status' => 'online',
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
     * الاستعلام عن تفاصيل الغرفة واللاعبين الحاليين
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
     * انضمام لاعب كـ Client إلى الغرفة عبر الكود المكون من 6 أرقام
     */
    public function join(Request $request, string $code): JsonResponse
    {
        $user = auth('sanctum')->user();

        $validated = $request->validate([
            'player_name' => 'nullable|string|max:50',
            'avatar' => 'nullable|string',
        ]);

        $playerName = $validated['player_name'] ?: ($user?->name ?: 'ضيف ' . random_int(100, 999));

        $room = Room::where('code', $code)->firstOrFail();

        if ($room->status === 'finished') {
            return response()->json([
                'status' => 'error',
                'message' => 'انتهت هذه اللعبة بالفعل، يرجى إنشاء غرفة جديدة أو الانضمام لغرفة أخرى.',
            ], 422);
        }

        if ($room->players()->count() >= $room->max_players) {
            return response()->json([
                'status' => 'error',
                'message' => 'الغرفة ممتلئة بالكامل (' . $room->max_players . ' لاعبين).',
            ], 422);
        }

        $playerToken = Str::random(32);

        $player = RoomPlayer::create([
            'room_id' => $room->id,
            'user_id' => $user?->id,
            'player_name' => $playerName,
            'avatar' => $validated['avatar'] ?? ($user?->avatar ?? 'assets/images/av-ahmed.png'),
            'is_host' => false,
            'is_ready' => true,
            'score' => 0,
            'connection_status' => 'online',
            'session_token' => $playerToken,
            'last_seen_at' => now(),
        ]);

        $room->update(['last_active_at' => now()]);
        $totalPlayers = $room->players()->count();

        // بث لحظي لانضمام اللاعب
        $this->safeBroadcast(new PlayerJoinedRoom($room->code, $player, $totalPlayers));

        return response()->json([
            'status' => 'success',
            'room' => $room->load(['game', 'players']),
            'player' => $player,
            'token' => $playerToken,
        ]);
    }

    /**
     * بدء اللعبة من قِبل المضيف (Host) وتجهيز الجولة الأولى
     */
    public function start(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->with(['game', 'players'])->firstOrFail();

        // التحقق من صلاحية المضيف
        $playerToken = $request->header('X-Player-Token') ?: ($request->input('player_token') ?: $request->query('token'));
        if ($playerToken) {
            $player = RoomPlayer::where('room_id', $room->id)->where('session_token', $playerToken)->first();
            abort_unless($player && $player->is_host, 403, 'غير مصرح: بدء اللعبة متاح لمضيف الغرفة فقط.');
        } else {
            $user = auth('sanctum')->user();
            abort_unless($user && $user->id === $room->host_user_id, 403, 'غير مصرح: بدء اللعبة متاح لمضيف الغرفة فقط.');
        }

        // مسار مخصص لبدء لعبة الدومينو (2 أو 3 أو 4 لاعبين، فردي أو 2 ضد 2)
        if ($room->game?->slug === 'domino') {
            $players = $room->players()->orderBy('id')->get();
            if ($players->count() < 2 || $players->count() > 4) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'تتطلب لعبة الدومينو من 2 إلى 4 لاعبين للبدء.',
                ], 422);
            }

            $existingState = $room->game_state ?? [];
            $teamMode = !empty($existingState['team_mode']) && $players->count() === 4;
            $targetScore = (int) ($existingState['target_score'] ?? 101);
            $playMode = (string) ($existingState['play_mode'] ?? 'draw');

            $dominoState = DominoEngine::dealRound(
                $players->pluck('id')->toArray(),
                $teamMode,
                [],
                $targetScore,
                1,
                null,
                $playMode
            );

            DominoController::runBotTurnsIfNeeded($room, $dominoState);

            $room->update([
                'status' => 'playing',
                'current_round' => 1,
                'game_state' => $dominoState,
                'last_active_at' => now(),
            ]);

            $this->safeBroadcast(new GameStarted($room, ['game_type' => 'domino']));

            return response()->json([
                'status' => 'success',
                'message' => 'تم بدء لعبة الدومينو بنجاح!',
                'room' => $room->fresh(['game', 'players']),
            ]);
        }

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

        // بناء الخيارات المبعثرة
        $choices = collect([$firstCard->answer, ...($firstCard->distractors ?? [])])
            ->filter()
            ->unique()
            ->shuffle()
            ->values()
            ->toArray();

        $room->update([
            'status' => 'playing',
            'current_round' => 1,
            'game_state' => [
                'current_card_id' => $firstCard->id,
                'current_choices' => $choices,
                'round_started_at' => now()->timestamp,
                'round_ended' => false,
                'all_cards_ids' => $cards->pluck('id')->toArray(),
                'answers' => [],
            ],
            'last_active_at' => now(),
        ]);

        $publicCard = [
            'id' => $firstCard->id,
            'prompt' => $firstCard->prompt,
            'choices' => $choices,
            'distractors' => $firstCard->distractors ?? [],
            'media_url' => $firstCard->media_url,
        ];

        // بث بدء اللعبة والجولة الأولى
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
     * الاستعلام المتزامن عن حالة الغرفة واللعبة الحية (Smart State Synchronization)
     */
    public function state(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->with(['game', 'players'])->firstOrFail();
        $playerToken = $request->query('token') ?: $request->header('X-Player-Token');

        $gameState = $room->game_state ?? [];
        $currentCardId = $gameState['current_card_id'] ?? null;
        $roundEnded = !empty($gameState['round_ended']);
        $answers = $gameState['answers'] ?? [];

        // ترتيب اللاعبين تنازلياً حسب النقاط (Leaderboard)
        $players = $room->players->sortByDesc('score')->values();
        $leaderboard = $players->map(function ($p, $index) use ($answers) {
            $pAns = $answers[$p->id] ?? null;
            return [
                'id' => $p->id,
                'player_name' => $p->player_name,
                'avatar' => $p->avatar,
                'score' => $p->score,
                'is_host' => $p->is_host,
                'rank' => $index + 1,
                'has_answered' => !empty($pAns),
                'last_points_earned' => $pAns['points'] ?? 0,
                'is_correct' => $pAns['is_correct'] ?? null,
            ];
        })->toArray();

        $publicCard = null;
        $revealedAnswer = null;
        $explanation = null;

        if ($currentCardId) {
            $card = ContentItem::find($currentCardId);
            if ($card) {
                $choices = !empty($gameState['current_choices']) && is_array($gameState['current_choices'])
                    ? array_values($gameState['current_choices'])
                    : collect([$card->answer, ...($card->distractors ?? [])])
                        ->filter()
                        ->unique()
                        ->shuffle()
                        ->values()
                        ->toArray();

                $publicCard = [
                    'id' => $card->id,
                    'prompt' => $card->prompt,
                    'choices' => $choices,
                    'media_url' => $card->media_url,
                ];

                if ($roundEnded || $room->status === 'finished') {
                    $revealedAnswer = $card->answer;
                    $explanation = $card->explanation;
                }
            }
        }

        $myPlayer = $playerToken ? $room->players->firstWhere('session_token', $playerToken) : null;
        $myAnswer = ($myPlayer && isset($answers[$myPlayer->id])) ? $answers[$myPlayer->id] : null;

        // حالة الدومينو الآمنة (إخفاء بلاطات الخصوم)
        $isDomino = $room->game?->slug === 'domino' && (($gameState['game_type'] ?? '') === 'domino');
        $dominoState = $isDomino
            ? DominoEngine::buildPublicStateForPlayer($gameState, $myPlayer?->id, $room->round_duration_seconds)
            : null;

        return response()->json([
            'status' => 'success',
            'room' => [
                'id' => $room->id,
                'code' => $room->code,
                'status' => $room->status,
                'current_round' => $room->current_round,
                'total_rounds' => $room->total_rounds,
                'round_duration_seconds' => $room->round_duration_seconds,
                'round_ended' => $roundEnded,
                'round_started_at' => $gameState['round_started_at'] ?? null,
                'game' => $room->game ? [
                    'id' => $room->game->id,
                    'name' => $room->game->name,
                    'slug' => $room->game->slug,
                ] : null,
                'total_players' => $players->count(),
                'max_players' => (int) $room->max_players,
                'answered_count' => count($answers),
            ],
            'card' => $publicCard,
            'domino_state' => $dominoState,
            'revealed_answer' => $revealedAnswer,
            'explanation' => $explanation,
            'leaderboard' => $leaderboard,
            'my_player' => $myPlayer,
            'my_answer' => $myAnswer,
            'is_game_over' => $isDomino
                ? ($room->status === 'finished' || !empty($gameState['match_over']))
                : ($room->status === 'finished' || ($roundEnded && $room->current_round >= $room->total_rounds)),
        ]);
    }

    /**
     * إرسال إجابة لاعب مع احتساب نقاط السرعة (Kahoot-style Score System)
     */
    public function answer(Request $request, string $code): JsonResponse
    {
        $validated = $request->validate([
            'player_token' => 'required|string',
            'answer' => 'required|string',
            'time_taken_seconds' => 'nullable|numeric',
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

        $answers = $gameState['answers'] ?? [];

        // منع الإجابة المكررة لنفس اللاعب في نفس الجولة
        if (isset($answers[$player->id])) {
            return response()->json([
                'status' => 'error',
                'message' => 'تم تسجيل إجابتك بالفعل في هذه الجولة.',
            ], 422);
        }

        $isCorrect = trim(mb_strtolower($validated['answer'])) === trim(mb_strtolower($card->answer));

        // احتساب النقاط ديناميكياً من دليل احتساب النقاط (Scoring System) الخاص باللعبة
        $pointsEarned = 0;
        if ($isCorrect) {
            $duration = max(10, $room->round_duration_seconds);
            $timeTaken = min($duration, max(1, (float) ($validated['time_taken_seconds'] ?? 5)));
            [$basePoints, $maxSpeedBonus] = $room->game ? $room->game->resolveScoringGuide() : [3, 0];

            $speedRatio = max(0, ($duration - $timeTaken) / $duration);
            $speedBonus = $maxSpeedBonus > 0 ? (int) round($speedRatio * $maxSpeedBonus) : 0;
            $pointsEarned = max(1, $basePoints + $speedBonus);

            $player->increment('score', $pointsEarned);
        }

        $answers[$player->id] = [
            'player_id' => $player->id,
            'player_name' => $player->player_name,
            'answer' => $validated['answer'],
            'is_correct' => $isCorrect,
            'points' => $pointsEarned,
            'answered_at' => now()->timestamp,
        ];

        $gameState['answers'] = $answers;

        $totalPlayers = $room->players()->count();
        $answeredCount = count($answers);

        // إشعار لحظي أن اللاعب الفلاني أجاب
        $this->safeBroadcast(new PlayerAnswered($room->code, $player->id, $player->player_name, $answeredCount, $totalPlayers));

        // إذا أجاب جميع اللاعبين، يتم إنهاء الجولة فوراً وكشف لوحة الصدارة
        if ($answeredCount >= $totalPlayers) {
            $gameState['round_ended'] = true;
            $room->update(['game_state' => $gameState]);

            $leaderboard = $room->players()->orderBy('score', 'desc')->get(['id', 'player_name', 'score', 'avatar'])->toArray();
            $isGameOver = $room->current_round >= $room->total_rounds;

            $this->safeBroadcast(new RoundEnded(
                $room->code,
                $room->current_round,
                $card->answer,
                $card->explanation,
                $leaderboard,
                $isGameOver
            ));
        } else {
            $room->update(['game_state' => $gameState]);
        }

        return response()->json([
            'status' => 'success',
            'is_correct' => $isCorrect,
            'points_earned' => $pointsEarned,
            'total_score' => $player->fresh()->score,
            'answered_count' => $answeredCount,
            'total_players' => $totalPlayers,
            'round_ended' => $answeredCount >= $totalPlayers,
        ]);
    }

    /**
     * انتهاء وقت السؤال (Timeout) وكشف النتائج حتى وإن لم يجب الجميع
     */
    public function timeout(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->firstOrFail();
        $playerToken = $request->header('X-Player-Token') ?? $request->input('player_token');
        $authUser = $request->user('sanctum') ?? auth('sanctum')->user();
        $isMember = ($playerToken && $room->players()->where('session_token', $playerToken)->exists())
            || ($authUser && ($room->host_user_id === $authUser->id || $room->players()->where('user_id', $authUser->id)->exists()));
        if (!$isMember) {
            return response()->json(['status' => 'error', 'message' => 'غير مصرح لك بإنهاء الجولة.'], 403);
        }

        $gameState = $room->game_state ?? [];

        if (!empty($gameState['round_ended'])) {
            return response()->json(['status' => 'success', 'message' => 'الجولة منتهية بالفعل']);
        }

        $currentCardId = $gameState['current_card_id'] ?? null;
        $card = ContentItem::find($currentCardId);

        $gameState['round_ended'] = true;
        $room->update(['game_state' => $gameState]);

        $leaderboard = $room->players()->orderBy('score', 'desc')->get(['id', 'player_name', 'score', 'avatar'])->toArray();
        $isGameOver = $room->current_round >= $room->total_rounds;

        $this->safeBroadcast(new RoundEnded(
            $room->code,
            $room->current_round,
            $card?->answer ?? '',
            $card?->explanation ?? '',
            $leaderboard,
            $isGameOver
        ));

        return response()->json([
            'status' => 'success',
            'message' => 'انتهى وقت الجولة.',
            'leaderboard' => $leaderboard,
            'revealed_answer' => $card?->answer,
            'explanation' => $card?->explanation,
            'is_game_over' => $isGameOver,
        ]);
    }

    /**
     * الانتقال للجولة التالية (Next Question)
     */
    public function nextRound(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->firstOrFail();

        // التحقق من صلاحية المضيف
        $playerToken = $request->header('X-Player-Token') ?: ($request->input('player_token') ?: $request->query('token'));
        if ($playerToken) {
            $player = RoomPlayer::where('room_id', $room->id)->where('session_token', $playerToken)->first();
            abort_unless($player && $player->is_host, 403, 'غير مصرح: الانتقال للجولة التالية متاح لمضيف الغرفة فقط.');
        } else {
            $user = auth('sanctum')->user();
            abort_unless($user && $user->id === $room->host_user_id, 403, 'غير مصرح: الانتقال للجولة التالية متاح لمضيف الغرفة فقط.');
        }
        $nextRound = $room->current_round + 1;

        if ($nextRound > $room->total_rounds) {
            return $this->finish($request, $code);
        }

        $gameState = $room->game_state ?? [];
        $allCardsIds = $gameState['all_cards_ids'] ?? [];
        $nextCardId = $allCardsIds[$nextRound - 1] ?? null;

        $nextCard = $nextCardId ? ContentItem::find($nextCardId) : null;

        if (!$nextCard) {
            return $this->finish($request, $code);
        }

        $choices = collect([$nextCard->answer, ...($nextCard->distractors ?? [])])
            ->filter()
            ->unique()
            ->shuffle()
            ->values()
            ->toArray();

        $room->update([
            'status' => 'playing',
            'current_round' => $nextRound,
            'game_state' => array_merge($gameState, [
                'current_card_id' => $nextCard->id,
                'current_choices' => $choices,
                'round_started_at' => now()->timestamp,
                'round_ended' => false,
                'answers' => [],
            ]),
            'last_active_at' => now(),
        ]);

        $publicCard = [
            'id' => $nextCard->id,
            'prompt' => $nextCard->prompt,
            'choices' => $choices,
            'distractors' => $nextCard->distractors ?? [],
            'media_url' => $nextCard->media_url,
        ];

        $this->safeBroadcast(new RoundStarted($room->code, $nextRound, $room->total_rounds, $room->round_duration_seconds, $publicCard));

        return response()->json([
            'status' => 'success',
            'message' => 'تم الانتقال للجولة التالية.',
            'current_round' => $nextRound,
            'card' => $publicCard,
        ]);
    }

    /**
     * إنهاء اللعبة بالكامل وتتويج الفائزين وحفظ الإحصائيات في بروفايل اللاعبين
     */
    public function finish(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->firstOrFail();
        $playerToken = $request->header('X-Player-Token') ?? $request->input('player_token');
        $authUser = $request->user('sanctum') ?? auth('sanctum')->user();
        $isMember = ($playerToken && $room->players()->where('session_token', $playerToken)->exists())
            || ($authUser && ($room->host_user_id === $authUser->id || $room->players()->where('user_id', $authUser->id)->exists()));
        if (!$isMember) {
            return response()->json(['status' => 'error', 'message' => 'غير مصرح لك بإنهاء الغرفة.'], 403);
        }

        $alreadyFinished = $room->status === 'finished';
        if (!$alreadyFinished) {
            $room->update(['status' => 'finished']);
        }

        $rankedPlayers = $room->players()->orderBy('score', 'desc')->get();

        // تحديث إحصائيات المستخدمين المسجلين في قاعدة البيانات (مرة واحدة فقط)
        if (!$alreadyFinished) {
            $isDomino = $room->game?->slug === 'domino';
            $topScore = $rankedPlayers->first()?->score ?? 0;
            [$dominoWinPts, $dominoPartPts] = $isDomino && $room->game
                ? $room->game->resolveScoringGuide()
                : [15, 5];

            foreach ($rankedPlayers as $rankIndex => $player) {
                if ($player->user_id) {
                    $user = User::find($player->user_id);
                    if ($user) {
                        $user->increment('games_played');
                        $isWinner = $topScore > 0 && ($isDomino ? $player->score === $topScore : $rankIndex === 0);
                        $earnedForLeaderboard = $isDomino
                            ? ($isWinner ? $dominoWinPts : $dominoPartPts)
                            : $player->score;

                        if ($earnedForLeaderboard > 0) {
                            $user->increment('total_score', $earnedForLeaderboard);
                        }
                        if ($isWinner) {
                            $user->increment('wins_count');
                        }
                        // احتساب الترقية في المستوى من جدول المستويات في لوحة التحكم
                        $user->refresh();
                        $calculatedLevel = Level::where('min_points', '<=', $user->total_score)
                            ->orderByDesc('level_number')
                            ->value('level_number') ?? 1;
                        if ($calculatedLevel != $user->level) {
                            $user->update(['level' => $calculatedLevel]);
                        }
                    }
                }
            }
        }

        $podium = [
            'first' => $rankedPlayers->get(0),
            'second' => $rankedPlayers->get(1),
            'third' => $rankedPlayers->get(2),
        ];

        return response()->json([
            'status' => 'success',
            'message' => 'انتهت اللعبة وتم حفظ النتائج!',
            'podium' => $podium,
            'leaderboard' => $rankedPlayers,
        ]);
    }

    /**
     * توليد توكن LiveKit WebRTC للغرفة الصوتية (مقتصر على لاعبي الغرفة المعتمدين)
     */
    public function getVoiceToken(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->firstOrFail();
        $playerToken = $request->query('token') ?: ($request->header('X-Player-Token') ?: $request->input('player_token'));

        $player = null;
        if ($playerToken) {
            $player = RoomPlayer::where('room_id', $room->id)
                ->where('session_token', $playerToken)
                ->first();
        }

        abort_unless($player, 403, 'غير مصرح: يجب الانضمام للغرفة كلاعب معتمد للحصول على تصريح الاتصال الصوتي.');

        $identity = 'player_' . $player->id;
        $name = $player->player_name;

        $apiKey = (string) config('services.livekit.api_key');
        $apiSecret = (string) config('services.livekit.api_secret');
        $serverUrl = (string) config('services.livekit.url', 'wss://farafsha.com/livekit');
        if ($apiKey === '' || $apiSecret === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'خدمة الصوت غير مهيأة على السيرفر حالياً.',
            ], 503);
        }

        $header = ['alg' => 'HS256', 'typ' => 'JWT'];
        $now = time();
        $payload = [
            'exp' => $now + (4 * 3600), // صالح لمدة 4 ساعات
            'iss' => $apiKey,
            'nbf' => $now - 5,
            'sub' => $identity,
            'name' => $name,
            'video' => [
                'room' => 'room_' . $room->code,
                'roomJoin' => true,
                'canPublish' => true,
                'canSubscribe' => true,
                'canPublishData' => true,
            ],
        ];

        $b64Header = rtrim(strtr(base64_encode(json_encode($header)), '+/', '-_'), '=');
        $b64Payload = rtrim(strtr(base64_encode(json_encode($payload)), '+/', '-_'), '=');
        $signature = rtrim(strtr(base64_encode(hash_hmac('sha256', "$b64Header.$b64Payload", $apiSecret, true)), '+/', '-_'), '=');

        $jwt = "$b64Header.$b64Payload.$signature";

        return response()->json([
            'status' => 'success',
            'server_url' => $serverUrl,
            'token' => $jwt,
            'room' => 'room_' . $room->code,
            'identity' => $identity,
            'name' => $name,
        ]);
    }

    /**
     * مغادرة الغرفة
     */
    public function leave(Request $request, string $code): JsonResponse
    {
        $playerToken = $request->input('player_token') ?: $request->header('X-Player-Token');

        $room = Room::where('code', $code)->first();
        if (!$room) {
            return response()->json(['status' => 'success']);
        }

        if ($playerToken) {
            $player = RoomPlayer::where('room_id', $room->id)->where('session_token', $playerToken)->first();
            if ($player) {
                $wasHost = $player->is_host;
                $player->delete();

                // إذا غادر المضيف ولا يزال هناك لاعبون، نسلّم القيادة لأول لاعب متبقٍ
                if ($wasHost) {
                    $nextHost = $room->players()->first();
                    if ($nextHost) {
                        $nextHost->update(['is_host' => true]);
                        $room->update(['host_name' => $nextHost->player_name, 'host_user_id' => $nextHost->user_id]);
                    } else {
                        $room->update(['status' => 'finished']);
                    }
                }
            }
        }

        return response()->json([
            'status' => 'success',
            'message' => 'تمت مغادرة الغرفة بنجاح.',
        ]);
    }

    /**
     * البحث عن غرفة انتظار متاحة للاعب عشوائي أو إنشاء غرفة جديدة تلقائياً
     */
    public function matchmake(Request $request): JsonResponse
    {
        $user = auth('sanctum')->user();
        $gameSlug = $request->input('game_slug', 'domino');
        $game = Game::where('slug', $gameSlug)->firstOrFail();
        $playerName = trim((string) ($request->input('player_name') ?: ($user?->name ?: 'لاعب فرفشة')));

        $openRoom = Room::where('game_id', $game->id)
            ->where('status', 'waiting')
            ->where('last_active_at', '>=', now()->subMinutes(15))
            ->withCount('players')
            ->orderByDesc('id')
            ->limit(25)
            ->get()
            ->first(fn ($r) => $r->players_count < $r->max_players);

        if ($openRoom) {
            $request->merge(['player_name' => $playerName]);
            return $this->join($request, $openRoom->code);
        }

        $request->merge([
            'game_id' => $game->id,
            'host_name' => $playerName,
        ]);

        return $this->store($request);
    }

    /**
     * إضافة لاعب ذكي (NPC) من السيرفر لإكمال الغرفة في حال عدم توفر لاعبين أونلاين
     */
    public function addBot(Request $request, string $code): JsonResponse
    {
        $room = Room::where('code', $code)->with('players')->firstOrFail();
        $playerToken = $request->header('X-Player-Token') ?? $request->input('player_token');
        $authUser = $request->user('sanctum') ?? auth('sanctum')->user();
        $isHost = ($playerToken && $room->players->where('session_token', $playerToken)->where('is_host', true)->isNotEmpty())
            || ($authUser && $room->host_user_id === $authUser->id);
        if (!$isHost) {
            return response()->json(['status' => 'error', 'message' => 'إضافة البوت مقتصرة على مضيف الغرفة فقط.'], 403);
        }

        if ($room->status !== 'waiting') {
            return response()->json(['status' => 'error', 'message' => 'اللعبة بدأت بالفعل.'], 422);
        }

        if ($room->players->count() >= $room->max_players) {
            return response()->json(['status' => 'error', 'message' => 'الغرفة ممتلئة بالكامل.'], 422);
        }

        $botNames = ['بوت فرفشة 🤖', 'سارة (NPC) 🤖', 'محمود (NPC) 🤖', 'كريم (NPC) 🤖'];
        $existingCount = $room->players->where(fn ($p) => str_starts_with((string) $p->session_token, 'bot_'))->count();
        $botName = $botNames[$existingCount % count($botNames)];

        $bot = RoomPlayer::create([
            'room_id' => $room->id,
            'user_id' => null,
            'player_name' => $botName,
            'avatar' => 'assets/images/av-karim.webp',
            'is_host' => false,
            'is_ready' => true,
            'score' => 0,
            'connection_status' => 'online',
            'session_token' => 'bot_' . Str::random(24),
            'last_seen_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'bot' => $bot,
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
