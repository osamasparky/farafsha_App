<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Room extends Model
{
    use HasFactory;

    protected $fillable = [
        'code',
        'host_user_id',
        'host_name',
        'game_id',
        'status',
        'max_players',
        'current_round',
        'total_rounds',
        'round_duration_seconds',
        'difficulty',
        'game_state',
        'last_active_at',
    ];

    protected $casts = [
        'game_state' => 'array',
        'max_players' => 'integer',
        'current_round' => 'integer',
        'total_rounds' => 'integer',
        'round_duration_seconds' => 'integer',
        'last_active_at' => 'datetime',
    ];

    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class);
    }

    public function host(): BelongsTo
    {
        return $this->belongsTo(User::class, 'host_user_id');
    }

    public function players(): HasMany
    {
        return $this->hasMany(RoomPlayer::class);
    }
}
