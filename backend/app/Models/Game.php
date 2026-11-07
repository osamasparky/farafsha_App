<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;

class Game extends Model
{
    use HasFactory, LogsActivity;

    /**
     * قائمة الأيقونات المعتمدة لقوالب وألعاب فرفشة في تطبيق الهاتف والويب
     */
    public const AVAILABLE_ICONS = [
        'format_quote_rounded' => 'أمثال واقتباسات (format_quote_rounded) 💬',
        'movie_filter_rounded' => 'إفيهات وأفلام وسينما (movie_filter_rounded) 🎬',
        'directions_bus_rounded' => 'أتوبيس كومبليت وسفر وحروف (directions_bus_rounded) 🚌',
        'sort_by_alpha_rounded' => 'حروف وتصنيفات وأبجدية (sort_by_alpha_rounded) 🔤',
        'psychology_rounded' => 'مين أنا وتخمين شخصيات (psychology_rounded) 🧠',
        'block_rounded' => 'ممنوع تقول / تابو (block_rounded) 🚫',
        'casino_rounded' => 'حقيقتان وكذبة / نرد الحظ (casino_rounded) 🎲',
        'bolt_rounded' => 'سؤال على السريع / سرعة وبديهة (bolt_rounded) ⚡',
        'theater_comedy_rounded' => 'تمثيل ومقالب وكوميديا (theater_comedy_rounded) 🎭',
        'lightbulb_rounded' => 'ألغاز وفوازير وأفكار (lightbulb_rounded) 💡',
        'music_note_rounded' => 'نغمات وأغاني وتحديات صوتية (music_note_rounded) 🎵',
        'brush_rounded' => 'رسم وتخمين وشخابيط (brush_rounded) 🎨',
        'emoji_events_rounded' => 'كؤوس وبطولات ومنافسات (emoji_events_rounded) 🏆',
        'sports_esports_rounded' => 'ألعاب عامة وتحكم (sports_esports_rounded) 🎮',
        'groups_rounded' => 'لمّة وتحديات جماعية (groups_rounded) 👥',
        'timer_rounded' => 'تحدي الثواني والسرعة (timer_rounded) ⏱️',
        'celebration_rounded' => 'حفلات ومرح (celebration_rounded) 🎉',
        'star_rounded' => 'لعبة مميزة / نجوم (star_rounded) ⭐',
        'local_fire_department_rounded' => 'تحديات نارية ساخنة (local_fire_department_rounded) 🔥',
    ];

    public static function getAvailableIcons(): array
    {
        return self::AVAILABLE_ICONS;
    }

    protected $fillable = [
        'name',
        'slug',
        'subtitle',
        'description',
        'instructions',
        'icon',
        'cover_image',
        'badge_text',
        'category',
        'template_type',
        'game_mode',
        'is_offline_capable',
        'age_group',
        'min_players',
        'max_players',
        'default_rounds',
        'default_duration_seconds',
        'difficulty_levels',
        'rules_config',
        'how_to_play_steps',
        'scoring_guide',
        'example_round',
        'faqs',
        'seo_title',
        'seo_description',
        'og_image',
        'trailer_video_url',
        'is_active',
        'is_featured',
        'sort_order',
    ];

    protected $casts = [
        'difficulty_levels' => 'array',
        'rules_config' => 'array',
        'how_to_play_steps' => 'array',
        'scoring_guide' => 'array',
        'example_round' => 'array',
        'faqs' => 'array',
        'is_offline_capable' => 'boolean',
        'is_active' => 'boolean',
        'is_featured' => 'boolean',
        'min_players' => 'integer',
        'max_players' => 'integer',
        'default_rounds' => 'integer',
        'default_duration_seconds' => 'integer',
        'sort_order' => 'integer',
    ];

    protected $appends = [
        'cover_image_url',
    ];

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['name', 'slug', 'is_active', 'is_featured', 'sort_order'])
            ->logOnlyDirty();
    }

    public function getCoverImageUrlAttribute(): ?string
    {
        if (!$this->cover_image) {
            return null;
        }

        if (str_starts_with($this->cover_image, 'http://') || str_starts_with($this->cover_image, 'https://')) {
            return $this->cover_image;
        }

        return url('storage/' . ltrim($this->cover_image, '/'));
    }

    public function contentItems(): HasMany
    {
        return $this->hasMany(ContentItem::class);
    }

    public function packs(): HasMany
    {
        return $this->hasMany(Pack::class);
    }

    public function sessions(): HasMany
    {
        return $this->hasMany(GameSession::class);
    }
}
