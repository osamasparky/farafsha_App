<?php

namespace App\Events;

use App\Models\Room;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class GameStarted implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public string $roomCode;
    public array $roomData;
    public array $firstRound;

    public function __construct(Room $room, array $firstRound)
    {
        $this->roomCode = $room->code;
        $this->roomData = [
            'id' => $room->id,
            'code' => $room->code,
            'game_id' => $room->game_id,
            'total_rounds' => $room->total_rounds,
            'round_duration' => $room->round_duration_seconds,
        ];
        $this->firstRound = $firstRound;
    }

    public function broadcastOn(): array
    {
        return [
            new Channel("room.{$this->roomCode}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'game.started';
    }
}
