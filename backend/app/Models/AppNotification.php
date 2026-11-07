<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    use HasFactory;

    /**
     * قائمة الأيقونات المعتمدة والمتوافقة مع تطبيق فرفشة (Material Icons)
     */
    public const AVAILABLE_ICONS = [
        'auto_awesome' => 'تحديث مميز وسحر (auto_awesome) ✨',
        'notifications' => 'تنبيه وجرس عام (notifications) 🔔',
        'notifications_active' => 'تنبيه عاجل ونشط (notifications_active) 🚨',
        'emoji_events' => 'كأس وبطولة ومكافأة (emoji_events) 🏆',
        'celebration' => 'احتفال وفعالية خاصة (celebration) 🎉',
        'sports_esports' => 'ألعاب وتحديات جديدة (sports_esports) 🎮',
        'bolt' => 'سرعة وتحدي زمني (bolt) ⚡',
        'lightbulb' => 'فكرة وأسئلة ذكاء (lightbulb) 💡',
        'star' => 'نجوم وتميز (star) ⭐',
        'military_tech' => 'شارة ووسام شرف (military_tech) 🎖️',
        'campaign' => 'إعلان هام أو بيان (campaign) 📢',
        'info' => 'معلومات وإرشاد (info) ℹ️',
        'format_quote_rounded' => 'أمثال واقتباسات (format_quote_rounded) 💬',
        'movie_filter_rounded' => 'أفلام وسينما (movie_filter_rounded) 🎬',
        'theater_comedy_rounded' => 'كوميديا وتمثيل ومقالب (theater_comedy_rounded) 🎭',
        'psychology_rounded' => 'ذكاء وتفكير وشخصيات (psychology_rounded) 🧠',
        'block_rounded' => 'ممنوع ومحظور تابو (block_rounded) 🚫',
        'music_note_rounded' => 'موسيقى ونغمات (music_note_rounded) 🎵',
        'group' => 'جمعة ولمّة وفرق (group) 👥',
        'favorite' => 'قلب وإعجاب (favorite) ❤️',
        'timer' => 'وقت ومؤقت (timer) ⏱️',
        'local_fire_department' => 'حماس وتحدي ناري (local_fire_department) 🔥',
        'card_giftcard' => 'هدية ومفاجأة (card_giftcard) 🎁',
        'help' => 'مساعدة واستفسارات (help) ❓',
    ];

    /**
     * إرجاع خيارات الأيقونات المتاحة للوحة التحكم والتطبيق
     */
    public static function getAvailableIcons(): array
    {
        return self::AVAILABLE_ICONS;
    }

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

