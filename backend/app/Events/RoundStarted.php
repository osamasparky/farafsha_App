<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class RoundStarted implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public string $roomCode;
    public int $roundNumber;
    public int $totalRounds;
    public int $durationSeconds;
    public array $card; // لا تتضمن الإجابة الصحيحة لحماية العدالة ومنع الغش

    public function __construct(string $roomCode, int $roundNumber, int $totalRounds, int $durationSeconds, array $card)
    {
        $this->roomCode = $roomCode;
        $this->roundNumber = $roundNumber;
        $this->totalRounds = $totalRounds;
        $this->durationSeconds = $durationSeconds;
        $this->card = $card;
    }

    public function broadcastOn(): array
    {
        return [
            new Channel("room.{$this->roomCode}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'round.started';
    }
}
