<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RoomPlayer extends Model
{
    use HasFactory;

    protected $fillable = [
        'room_id',
        'user_id',
        'player_name',
        'avatar',
        'score',
        'is_host',
        'is_ready',
        'connection_status',
        'session_token',
        'last_seen_at',
    ];

    protected $casts = [
        'score' => 'integer',
        'is_host' => 'boolean',
        'is_ready' => 'boolean',
        'last_seen_at' => 'datetime',
    ];

    protected $hidden = [
        'session_token',
    ];

    public function room(): BelongsTo
    {
        return $this->belongsTo(Room::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
