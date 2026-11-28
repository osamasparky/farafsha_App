<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Crew extends Model
{
    protected $fillable = [
        'name',
        'code',
        'owner_id',
        'badge_color',
        'emoji',
        'total_score',
        'wins_count',
    ];

    protected $casts = [
        'total_score' => 'integer',
        'wins_count' => 'integer',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function members()
    {
        return $this->hasMany(CrewMember::class);
    }
}
