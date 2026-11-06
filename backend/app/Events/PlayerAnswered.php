<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PlayerAnswered implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public string $roomCode;
    public int $playerId;
    public string $playerName;
    public int $answeredCount;
    public int $totalPlayers;

    public function __construct(string $roomCode, int $playerId, string $playerName, int $answeredCount, int $totalPlayers)
    {
        $this->roomCode = $roomCode;
        $this->playerId = $playerId;
        $this->playerName = $playerName;
        $this->answeredCount = $answeredCount;
        $this->totalPlayers = $totalPlayers;
    }

    public function broadcastOn(): array
    {
        return [
            new Channel("room.{$this->roomCode}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'player.answered';
    }
}
