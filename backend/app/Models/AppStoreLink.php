<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppStoreLink extends Model
{
    use HasFactory;

    protected $fillable = [
        'platform',
        'country_code',
        'store_url',
        'is_available',
        'message',
    ];

    protected $casts = [
        'is_available' => 'boolean',
    ];

    public static function getLinkFor(string $platform, ?string $countryCode = null): ?self
    {
        $query = static::where('platform', $platform)->where('is_available', true);

        if ($countryCode) {
            $countryMatch = (clone $query)->where('country_code', strtoupper($countryCode))->first();
            if ($countryMatch) {
                return $countryMatch;
            }
        }

        return (clone $query)->where('country_code', 'ALL')->first();
    }
}

