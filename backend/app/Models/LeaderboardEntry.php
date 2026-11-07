<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LeaderboardEntry extends Model
{
    use HasFactory;

    protected $fillable = [
        'player_name',
        'avatar',
        'score',
        'wins',
        'period_type',
        'rank',
        'badge',
        'is_current_user',
    ];

    protected $casts = [
        'score' => 'integer',
        'wins' => 'integer',
        'rank' => 'integer',
        'is_current_user' => 'boolean',
    ];
}

