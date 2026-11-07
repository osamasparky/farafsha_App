<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Level extends Model
{
    use HasFactory;

    protected $fillable = [
        'level_number',
        'title',
        'min_points',
        'icon',
        'color',
        'sort_order',
    ];

    protected $casts = [
        'level_number' => 'integer',
        'min_points' => 'integer',
        'sort_order' => 'integer',
    ];
}
