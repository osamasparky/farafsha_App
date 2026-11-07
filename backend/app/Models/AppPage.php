<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppPage extends Model
{
    use HasFactory;

    protected $fillable = [
        'slug',
        'title',
        'content',
        'meta',
        'is_active',
    ];

    protected $casts = [
        'meta' => 'array',
        'is_active' => 'boolean',
    ];
}

