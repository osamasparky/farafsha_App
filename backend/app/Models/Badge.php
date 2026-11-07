<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class Badge extends Model
{
    use HasFactory;

    /**
     * قائمة الأيقونات المعتمدة للأوسمة والإنجازات
     */
    public const AVAILABLE_ICONS = [
        'trophy' => '🏆 كأس البطولة والتفوق (Trophy)',
        'star' => '⭐ نجمة التميز (Star)',
        'quote' => '💬 اقتباس ومثل شعبي (Quote)',
        'bulb' => '💡 عبقري وفكرة ذكية (Bulb)',
        'music' => '🎵 موسيقى ونغمات (Music)',
        'film' => '🎬 سينما وإفيهات (Film)',
        'mask' => '🎭 شخصيات وأقنعة (Mask)',
        'fire' => '🔥 شعلة حماس مستمرة (Fire)',
        'gem' => '💎 جوهرة نادرة (Gem)',
        'bolt' => '⚡ سرعة وبديهة خارقة (Bolt)',
    ];

    public static function getAvailableIcons(): array
    {
        return self::AVAILABLE_ICONS;
    }

    protected $fillable = [
        'title',
        'description',
        'game_id',
        'required_points',
        'icon',
        'image',
        'color',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'required_points' => 'integer',
        'sort_order' => 'integer',
        'is_active' => 'boolean',
    ];

    protected $appends = [
        'image_url',
    ];

    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class);
    }

    public function getImageUrlAttribute(): ?string
    {
        if (!$this->image) {
            return null;
        }

        if (str_starts_with($this->image, 'http://') || str_starts_with($this->image, 'https://')) {
            return $this->image;
        }

        return url(Storage::url($this->image));
    }
}

