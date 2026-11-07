<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Dialect extends Model
{
    use HasFactory;

    /**
     * أعلام وأيقونات اللهجات المدعومة
     */
    public const AVAILABLE_ICONS = [
        '🇪🇬' => '🇪🇬 جمهورية مصر العربية (Egyptian)',
        '🇸🇦' => '🇸🇦 المملكة العربية السعودية والخليج (Saudi / Gulf)',
        '🇱🇧' => '🇱🇧 بلاد الشام / لبنان وسوريا والأردن (Levantine)',
        '🇲🇦' => '🇲🇦 المغرب العربي وتونس والجزائر (Maghrebi)',
        '🇮🇶' => '🇮🇶 العراق (Iraqi)',
        '🇸🇩' => '🇸🇩 السودان (Sudanese)',
        '🌍' => '🌍 لهجة عامة / فصحى عربية (Modern Standard)',
    ];

    public static function getAvailableIcons(): array
    {
        return self::AVAILABLE_ICONS;
    }

    protected $fillable = [
        'name',
        'code',
        'icon',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];
}

