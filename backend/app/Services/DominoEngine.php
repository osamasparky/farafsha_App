<?php

namespace App\Services;

class DominoEngine
{
    /**
     * بناء مجموعة الدومينو الكاملة (28 بلاطة من 0|0 إلى 6|6) مبعثرة عشوائياً
     */
    public static function buildDeck(): array
    {
        $deck = [];
        for ($i = 0; $i <= 6; $i++) {
            for ($j = $i; $j <= 6; $j++) {
                $deck[] = [$i, $j];
            }
        }
        shuffle($deck);

        return $deck;
    }

    /**
     * توزيع جولة جديدة للاعبين (2 أو 3 أو 4 لاعبين، فردي أو 2 ضد 2)
     */
    public static function dealRound(
        array $playerIds,
        bool $teamMode = false,
        array $matchScores = [],
        int $targetScore = 101,
        int $roundNumber = 1,
        ?int $preferredStarterId = null,
        string $playMode = 'draw'
    ): array {
        $deck = self::buildDeck();
        $hands = [];
        $index = 0;

        foreach ($playerIds as $pid) {
            $hands[(string) $pid] = array_slice($deck, $index, 7);
            $index += 7;
        }

        $boneyard = $playMode === 'block' ? [] : array_values(array_slice($deck, $index));
        $is2v2 = $teamMode && count($playerIds) === 4;

        $teams = [];
        if ($is2v2) {
            // اللاعبون المتقابلون في نفس الفريق: (0, 2) ضد (1, 3)
            $teams = [
                'team_a' => [(int) $playerIds[0], (int) $playerIds[2]],
                'team_b' => [(int) $playerIds[1], (int) $playerIds[3]],
            ];
            if (empty($matchScores)) {
                $matchScores = ['team_a' => 0, 'team_b' => 0];
            }
        } else {
            foreach ($playerIds as $pid) {
                $key = (string) $pid;
                if (!isset($matchScores[$key])) {
                    $matchScores[$key] = 0;
                }
            }
        }

        $starterId = ($preferredStarterId && in_array($preferredStarterId, $playerIds, true))
            ? $preferredStarterId
            : self::determineStarter($hands, $playerIds);

        return [
            'game_type' => 'domino',
            'play_mode' => $playMode,
            'round_number' => $roundNumber,
            'target_score' => max(10, $targetScore),
            'team_mode' => $is2v2,
            'teams' => $teams,
            'match_scores' => $matchScores,
            'turn_order' => array_map('intval', $playerIds),
            'current_turn_player_id' => (int) $starterId,
            'turn_started_at' => now()->timestamp,
            'board' => [],
            'left_end' => null,
            'right_end' => null,
            'hands' => $hands,
            'boneyard' => $boneyard,
            'consecutive_passes' => 0,
            'round_ended' => false,
            'match_over' => false,
            'round_winner' => null,
            'last_move' => null,
        ];
    }

    /**
     * تحديد البادئ: صاحب أعلى دبل، وإلا صاحب أعلى مجموع نقاط
     */
    private static function determineStarter(array $hands, array $playerIds): int
    {
        $bestDouble = -1;
        $bestPlayer = (int) $playerIds[0];

        foreach ($playerIds as $pid) {
            foreach ($hands[(string) $pid] ?? [] as $tile) {
                if ($tile[0] === $tile[1] && $tile[0] > $bestDouble) {
                    $bestDouble = $tile[0];
                    $bestPlayer = (int) $pid;
                }
            }
        }

        if ($bestDouble >= 0) {
            return $bestPlayer;
        }

        $bestSum = -1;
        foreach ($playerIds as $pid) {
            foreach ($hands[(string) $pid] ?? [] as $tile) {
                $sum = $tile[0] + $tile[1];
                if ($sum > $bestSum) {
                    $bestSum = $sum;
                    $bestPlayer = (int) $pid;
                }
            }
        }

        return $bestPlayer;
    }

    /**
     * التحقق من إمكانية وضع البلاطة على الطرف المحدد
     */
    public static function canPlayTile(array $tile, ?int $leftEnd, ?int $rightEnd, string $side): bool
    {
        if ($leftEnd === null || $rightEnd === null) {
            return true;
        }

        $target = $side === 'left' ? $leftEnd : $rightEnd;

        return $tile[0] === $target || $tile[1] === $target;
    }

    /**
     * التحقق من وجود أي حركة متاحة في يد اللاعب
     */
    public static function hasAnyValidMove(array $hand, ?int $leftEnd, ?int $rightEnd): bool
    {
        if ($leftEnd === null || $rightEnd === null) {
            return !empty($hand);
        }

        foreach ($hand as $tile) {
            if (self::canPlayTile($tile, $leftEnd, $rightEnd, 'left') || self::canPlayTile($tile, $leftEnd, $rightEnd, 'right')) {
                return true;
            }
        }

        return false;
    }

    /**
     * وضع البلاطة على الطاولة مع تدويرها بالاتجاه الصحيح
     */
    public static function placeTile(array &$state, int $playerId, int $handIndex, string $side): void
    {
        $key = (string) $playerId;
        $tile = $state['hands'][$key][$handIndex];
        array_splice($state['hands'][$key], $handIndex, 1);

        $board = $state['board'];
        if (empty($board)) {
            $placed = [$tile[0], $tile[1]];
            $board[] = $placed;
            $state['left_end'] = $placed[0];
            $state['right_end'] = $placed[1];
        } elseif ($side === 'left') {
            $leftEnd = (int) $state['left_end'];
            // الطرف الأيمن من البلاطة الجديدة يجب أن يطابق leftEnd
            $placed = $tile[1] === $leftEnd ? [$tile[0], $tile[1]] : [$tile[1], $tile[0]];
            array_unshift($board, $placed);
            $state['left_end'] = $placed[0];
        } else {
            $rightEnd = (int) $state['right_end'];
            // الطرف الأيسر من البلاطة الجديدة يجب أن يطابق rightEnd
            $placed = $tile[0] === $rightEnd ? [$tile[0], $tile[1]] : [$tile[1], $tile[0]];
            $board[] = $placed;
            $state['right_end'] = $placed[1];
        }

        $state['board'] = $board;
        $state['consecutive_passes'] = 0;
        $state['last_move'] = [
            'type' => 'play',
            'player_id' => $playerId,
            'tile' => $placed,
            'side' => $side,
        ];

        // التحقق من فوز اللاعب بإنهاء جميع بلاطاته
        if (empty($state['hands'][$key])) {
            self::resolveRoundEnd($state, $playerId, false);
            return;
        }

        self::advanceTurn($state);
    }

    /**
     * الانتقال للدور التالي
     */
    public static function advanceTurn(array &$state): void
    {
        $order = $state['turn_order'];
        $current = (int) $state['current_turn_player_id'];
        $idx = array_search($current, $order, true);
        $nextIdx = ($idx === false) ? 0 : (($idx + 1) % count($order));

        $state['current_turn_player_id'] = (int) $order[$nextIdx];
        $state['turn_started_at'] = now()->timestamp;
    }

    /**
     * حساب مجموع النقاط في يد اللاعب
     */
    public static function handPipSum(array $hand): int
    {
        $sum = 0;
        foreach ($hand as $tile) {
            $sum += ((int) $tile[0]) + ((int) $tile[1]);
        }

        return $sum;
    }

    /**
     * إنهاء الجولة (فوز مباشر أو قفل الطاولة) واحتساب النقاط حتى 100 نقطة
     */
    public static function resolveRoundEnd(array &$state, ?int $directWinnerId, bool $blocked): void
    {
        $hands = $state['hands'];
        $playerIds = $state['turn_order'];
        $is2v2 = !empty($state['team_mode']) && !empty($state['teams']);

        $winnerPlayerId = $directWinnerId;
        if ($blocked || $winnerPlayerId === null) {
            $lowestSum = PHP_INT_MAX;
            foreach ($playerIds as $pid) {
                $sum = self::handPipSum($hands[(string) $pid] ?? []);
                if ($sum < $lowestSum) {
                    $lowestSum = $sum;
                    $winnerPlayerId = (int) $pid;
                }
            }
        }

        $roundPoints = 0;
        $winnerTeam = null;

        if ($is2v2) {
            $teamA = $state['teams']['team_a'];
            $teamB = $state['teams']['team_b'];
            $winnerTeam = in_array($winnerPlayerId, $teamA, true) ? 'team_a' : 'team_b';
            $losingTeam = $winnerTeam === 'team_a' ? $teamB : $teamA;

            foreach ($losingTeam as $lpid) {
                $roundPoints += self::handPipSum($hands[(string) $lpid] ?? []);
            }

            $state['match_scores'][$winnerTeam] = ($state['match_scores'][$winnerTeam] ?? 0) + $roundPoints;
            $winnerTotal = $state['match_scores'][$winnerTeam];
        } else {
            foreach ($playerIds as $pid) {
                if ((int) $pid !== (int) $winnerPlayerId) {
                    $roundPoints += self::handPipSum($hands[(string) $pid] ?? []);
                }
            }
            $wKey = (string) $winnerPlayerId;
            $state['match_scores'][$wKey] = ($state['match_scores'][$wKey] ?? 0) + $roundPoints;
            $winnerTotal = $state['match_scores'][$wKey];
        }

        $targetScore = (int) ($state['target_score'] ?? 100);
        $matchOver = $winnerTotal >= $targetScore;

        $state['round_ended'] = true;
        $state['match_over'] = $matchOver;
        $state['round_winner'] = [
            'player_id' => $winnerPlayerId,
            'team' => $winnerTeam,
            'points_won' => $roundPoints,
            'blocked' => $blocked,
            'remaining_pips' => collect($hands)->map(fn ($h) => self::handPipSum($h))->toArray(),
            'losing_hands' => $hands,
        ];
    }

    /**
     * بناء الحالة العامة الآمنة للاعب (إخفاء بلاطات الخصوم ومنع الغش)
     */
    public static function buildPublicStateForPlayer(array $state, ?int $viewerPlayerId, int $turnDuration = 25): array
    {
        $hands = $state['hands'] ?? [];
        $handCounts = [];
        foreach ($hands as $pid => $tiles) {
            $handCounts[$pid] = count($tiles);
        }

        $myHand = $viewerPlayerId ? ($hands[(string) $viewerPlayerId] ?? []) : [];
        $turnStarted = (int) ($state['turn_started_at'] ?? now()->timestamp);
        $elapsed = max(0, now()->timestamp - $turnStarted);
        $remainingSeconds = max(0, $turnDuration - $elapsed);

        return [
            'game_type' => 'domino',
            'play_mode' => $state['play_mode'] ?? 'draw',
            'round_number' => (int) ($state['round_number'] ?? 1),
            'target_score' => (int) ($state['target_score'] ?? 101),
            'team_mode' => !empty($state['team_mode']),
            'teams' => $state['teams'] ?? [],
            'match_scores' => $state['match_scores'] ?? [],
            'turn_order' => $state['turn_order'] ?? [],
            'current_turn_player_id' => (int) ($state['current_turn_player_id'] ?? 0),
            'remaining_seconds' => $remainingSeconds,
            'turn_duration_seconds' => $turnDuration,
            'board' => $state['board'] ?? [],
            'left_end' => $state['left_end'],
            'right_end' => $state['right_end'],
            'my_hand' => array_values($myHand),
            'hand_counts' => $handCounts,
            'boneyard_count' => count($state['boneyard'] ?? []),
            'round_ended' => !empty($state['round_ended']),
            'match_over' => !empty($state['match_over']),
            'round_winner' => $state['round_winner'] ?? null,
            'last_move' => $state['last_move'] ?? null,
        ];
    }
}
