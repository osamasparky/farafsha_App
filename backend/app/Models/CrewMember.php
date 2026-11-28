<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CrewMember extends Model
{
    protected $fillable = [
        'crew_id',
        'user_id',
        'role',
        'weekly_score',
    ];

    protected $casts = [
        'weekly_score' => 'integer',
    ];

    public function crew()
    {
        return $this->belongsTo(Crew::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
