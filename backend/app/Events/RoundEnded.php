<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class RoundEnded implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public string $roomCode;
    public int $roundNumber;
    public string $correctAnswer;
    public ?string $explanation;
    public array $leaderboard; // الترتيب المحدث بعد الجولة
    public bool $isGameOver;

    public function __construct(
        string $roomCode,
        int $roundNumber,
        string $correctAnswer,
        ?string $explanation,
        array $leaderboard,
        bool $isGameOver = false
    ) {
        $this->roomCode = $roomCode;
        $this->roundNumber = $roundNumber;
        $this->correctAnswer = $correctAnswer;
        $this->explanation = $explanation;
        $this->leaderboard = $leaderboard;
        $this->isGameOver = $isGameOver;
    }

    public function broadcastOn(): array
    {
        return [
            new Channel("room.{$this->roomCode}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'round.ended';
    }
}
