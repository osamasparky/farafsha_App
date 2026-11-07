<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CountryWaitlist extends Model
{
    use HasFactory;

    protected $fillable = [
        'email',
        'country_code',
        'ip_address',
        'user_agent',
        'consent_given',
    ];

    protected $casts = [
        'consent_given' => 'boolean',
    ];
}

