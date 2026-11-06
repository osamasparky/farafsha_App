<?php

namespace App\Events;

use App\Models\RoomPlayer;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PlayerJoinedRoom implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public string $roomCode;
    public array $playerData;
    public int $totalPlayers;

    public function __construct(string $roomCode, RoomPlayer $player, int $totalPlayers)
    {
        $this->roomCode = $roomCode;
        $this->playerData = [
            'id' => $player->id,
            'name' => $player->player_name,
            'avatar' => $player->avatar,
            'is_host' => $player->is_host,
            'score' => $player->score,
        ];
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
        return 'player.joined';
    }
}
