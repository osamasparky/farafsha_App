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
        'client_token',
        'team_id',
        'key_id',
        'redirect_url',
        'scopes',
        'icon',
        'sort_order',
        'notes',
        'extra_config',
    ];

    protected $casts = [
        'is_enabled' => 'boolean',
        'sort_order' => 'integer',
        'extra_config' => 'array',
    ];
}
