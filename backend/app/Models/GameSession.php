<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GameSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'game_id',
        'room_id',
        'mode',
        'players_count',
        'rounds_completed',
        'final_scores',
        'winner_name',
        'duration_seconds',
    ];

    protected $casts = [
        'final_scores' => 'array',
        'players_count' => 'integer',
        'rounds_completed' => 'integer',
        'duration_seconds' => 'integer',
    ];

    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class);
    }

    public function room(): BelongsTo
    {
        return $this->belongsTo(Room::class);
    }
}
