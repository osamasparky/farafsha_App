<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SocialProvider extends Model
{
    use HasFactory;

    protected $fillable = [
        'provider',
        'name',
        'is_enabled',
        'client_id',
        'client_secret',
        'redirect_url',
        'icon',
        'sort_order',
        'notes',
    ];

    protected $casts = [
        'is_enabled' => 'boolean',
        'sort_order' => 'integer',
    ];
}

