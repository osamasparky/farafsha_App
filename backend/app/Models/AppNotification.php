<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'message',
        'type',
        'icon',
        'is_read',
        'is_active',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'is_active' => 'boolean',
    ];
}

