<?php

namespace Tests\Unit;

use App\Services\DominoEngine;
use PHPUnit\Framework\TestCase;

class DominoEngineTest extends TestCase
{
    public function test_deals_correctly_for_two_three_and_four_players(): void
    {
        $state2 = DominoEngine::dealRound([1, 2], false, [], 100, 1);
        $this->assertCount(7, $state2['hands']['1']);
        $this->assertCount(7, $state2['hands']['2']);
        $this->assertCount(14, $state2['boneyard']);
        $this->assertFalse($state2['team_mode']);

        $state3 = DominoEngine::dealRound([1, 2, 3], false, [], 100, 1);
        $this->assertCount(7, $state3['hands']['1']);
        $this->assertCount(7, $state3['hands']['3']);
        $this->assertCount(7, $state3['boneyard']);

        $state4 = DominoEngine::dealRound([1, 2, 3, 4], true, [], 100, 1);
        $this->assertCount(7, $state4['hands']['4']);
        $this->assertCount(0, $state4['boneyard']);
        $this->assertTrue($state4['team_mode']);
        $this->assertSame([1, 3], $state4['teams']['team_a']);
        $this->assertSame([2, 4], $state4['teams']['team_b']);
    }

    public function test_can_play_and_orient_tiles_on_both_ends(): void
    {
        $state = DominoEngine::dealRound([1, 2], false, [], 100, 1);
        $state['hands']['1'] = [[6, 4], [2, 1]];
        $state['hands']['2'] = [[4, 3], [5, 5]];
        $state['current_turn_player_id'] = 1;

        DominoEngine::placeTile($state, 1, 0, 'right');
        $this->assertSame(6, $state['left_end']);
        $this->assertSame(4, $state['right_end']);
        $this->assertSame(2, $state['current_turn_player_id']);

        DominoEngine::placeTile($state, 2, 0, 'right');
        $this->assertSame(6, $state['left_end']);
        $this->assertSame(3, $state['right_end']);
        $this->assertCount(2, $state['board']);
    }

    public function test_match_ends_when_reaching_100_points(): void
    {
        $state = DominoEngine::dealRound([1, 2, 3, 4], true, ['team_a' => 90, 'team_b' => 40], 100, 2);
        $state['hands'] = [
            '1' => [[6, 6]],
            '2' => [[5, 5]], // 10
            '3' => [[1, 0]],
            '4' => [[4, 3]], // 7
        ];
        $state['current_turn_player_id'] = 1;
        DominoEngine::placeTile($state, 1, 0, 'right');

        $this->assertTrue($state['round_ended']);
        $this->assertTrue($state['match_over']);
        $this->assertSame(107, $state['match_scores']['team_a']);
    }

    public function test_public_state_hides_opponent_hands(): void
    {
        $state = DominoEngine::dealRound([10, 20], false, [], 100, 1);
        $public = DominoEngine::buildPublicStateForPlayer($state, 10);

        $this->assertCount(7, $public['my_hand']);
        $this->assertSame(['10' => 7, '20' => 7], $public['hand_counts']);
        $this->assertArrayNotHasKey('hands', $public);
        $this->assertArrayNotHasKey('boneyard', $public);
    }
}
