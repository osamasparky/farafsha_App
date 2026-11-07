<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Level extends Model
{
    use HasFactory;

    /**
     * قائمة الأيقونات المعتمدة للمستويات والرتب
     */
    public const AVAILABLE_ICONS = [
        'star' => '⭐ نجمة اللاعب المبتدئ (Star)',
        'crown' => '👑 تاج الملوك والصدارة (Crown)',
        'shield' => '🛡️ درع الفارس والمدافع (Shield)',
        'fire' => '🔥 شعلة الحماس والنشاط (Fire)',
        'gem' => '💎 جوهرة وألماس الأساطير (Gem)',
        'trophy' => '🏆 كأس البطولة (Trophy)',
        'military_tech' => '🎖️ وسام شرف عسكري (Military Tech)',
        'bolt' => '⚡ صاعقة السرعة والذكاء (Bolt)',
        'rocket_launch' => '🚀 صاروخ الانطلاق والقمة (Rocket)',
    ];

    public static function getAvailableIcons(): array
    {
        return self::AVAILABLE_ICONS;
    }

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

