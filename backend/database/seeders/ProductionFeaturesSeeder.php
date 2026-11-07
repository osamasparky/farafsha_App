<?php

namespace Database\Seeders;

use App\Models\Banner;
use App\Models\Dialect;
use App\Models\LeaderboardEntry;
use App\Models\AppNotification;
use App\Models\AppPage;
use Illuminate\Database\Seeder;

class ProductionFeaturesSeeder extends Seeder
{
    public function run(): void
    {
        // 1. البنرات الإعلانية
        Banner::truncate();
        Banner::create([
            'title' => 'بطولة لمّة الأسبوعية الكبرى 🏆',
            'image' => 'banners/banner-lammah.png',
            'external_url' => 'https://lammah.app/tournament',
            'is_active' => true,
            'sort_order' => 1,
        ]);

        Banner::create([
            'title' => 'كروت جديدة وإفيهات حصرية ممتعة 🔥',
            'image' => 'banners/banner-challenge.png',
            'external_url' => null, // بدون رابط خارجي كما طلب المستخدم
            'is_active' => true,
            'sort_order' => 2,
        ]);

        Banner::create([
            'title' => 'العب أونلاين وتحدّى صحابك عن بُعد 🌐',
            'image' => 'banners/banner-online.png',
            'external_url' => 'https://lammah.app/online',
            'is_active' => true,
            'sort_order' => 3,
        ]);

        // 2. إدارة اللهجات
        Dialect::truncate();
        Dialect::create(['name' => 'لهجة مصرية', 'code' => 'egyptian', 'icon' => '🇪🇬', 'is_active' => true, 'sort_order' => 1]);
        Dialect::create(['name' => 'لهجة خليجية', 'code' => 'gulf', 'icon' => '🇸🇦', 'is_active' => true, 'sort_order' => 2]);
        Dialect::create(['name' => 'لهجة شامية', 'code' => 'levantine', 'icon' => '🇱🇧', 'is_active' => true, 'sort_order' => 3]);
        Dialect::create(['name' => 'لهجة مغاربية', 'code' => 'maghrebi', 'icon' => '🇲🇦', 'is_active' => true, 'sort_order' => 4]);

        // 3. لوحة الترتيب (بيانات حقيقية مختلفة لكل فترة)
        LeaderboardEntry::truncate();

        // هذا الأسبوع
        LeaderboardEntry::create(['period_type' => 'weekly', 'rank' => 1, 'player_name' => 'أحمد', 'avatar' => 'assets/images/av-ahmed.png', 'score' => 2840, 'wins' => 18, 'badge' => 'بطل الأسبوع 👑', 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'weekly', 'rank' => 2, 'player_name' => 'سارة', 'avatar' => 'assets/images/av-sara.png', 'score' => 2120, 'wins' => 14, 'badge' => 'محترفة 🥈', 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'weekly', 'rank' => 3, 'player_name' => 'محمود', 'avatar' => 'assets/images/av-mahmoud.png', 'score' => 1980, 'wins' => 11, 'badge' => 'سريع البديهة 🥉', 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'weekly', 'rank' => 4, 'player_name' => 'منة', 'avatar' => 'assets/images/av-mena.png', 'score' => 1760, 'wins' => 9, 'badge' => null, 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'weekly', 'rank' => 5, 'player_name' => 'كريم', 'avatar' => 'assets/images/av-karim.png', 'score' => 1520, 'wins' => 8, 'badge' => null, 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'weekly', 'rank' => 12, 'player_name' => 'أنت (أسامة)', 'avatar' => 'assets/images/av-karim.png', 'score' => 980, 'wins' => 4, 'badge' => 'صاعد 🚀', 'is_current_user' => true]);

        // هذا الشهر
        LeaderboardEntry::create(['period_type' => 'monthly', 'rank' => 1, 'player_name' => 'سارة', 'avatar' => 'assets/images/av-sara.png', 'score' => 8450, 'wins' => 45, 'badge' => 'سيدة الشهر 👑', 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'monthly', 'rank' => 2, 'player_name' => 'محمود', 'avatar' => 'assets/images/av-mahmoud.png', 'score' => 7910, 'wins' => 38, 'badge' => 'الوصيف 🥈', 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'monthly', 'rank' => 3, 'player_name' => 'أحمد', 'avatar' => 'assets/images/av-ahmed.png', 'score' => 7200, 'wins' => 36, 'badge' => 'المتحدي 🥉', 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'monthly', 'rank' => 4, 'player_name' => 'كريم', 'avatar' => 'assets/images/av-karim.png', 'score' => 5830, 'wins' => 29, 'badge' => null, 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'monthly', 'rank' => 5, 'player_name' => 'منة', 'avatar' => 'assets/images/av-mena.png', 'score' => 4920, 'wins' => 24, 'badge' => null, 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'monthly', 'rank' => 8, 'player_name' => 'أنت (أسامة)', 'avatar' => 'assets/images/av-karim.png', 'score' => 3420, 'wins' => 15, 'badge' => 'نجم مميز ⭐', 'is_current_user' => true]);

        // كل الوقت
        LeaderboardEntry::create(['period_type' => 'all_time', 'rank' => 1, 'player_name' => 'محمود', 'avatar' => 'assets/images/av-mahmoud.png', 'score' => 24190, 'wins' => 128, 'badge' => 'أسطورة لمّة 🌟', 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'all_time', 'rank' => 2, 'player_name' => 'أحمد', 'avatar' => 'assets/images/av-ahmed.png', 'score' => 21500, 'wins' => 112, 'badge' => 'المحارب الفضي ⚔️', 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'all_time', 'rank' => 3, 'player_name' => 'سارة', 'avatar' => 'assets/images/av-sara.png', 'score' => 19840, 'wins' => 95, 'badge' => 'عبقرية الأمثال 💡', 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'all_time', 'rank' => 4, 'player_name' => 'ياسين', 'avatar' => 'assets/images/av-ahmed.png', 'score' => 16300, 'wins' => 82, 'badge' => null, 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'all_time', 'rank' => 5, 'player_name' => 'منة', 'avatar' => 'assets/images/av-mena.png', 'score' => 14750, 'wins' => 74, 'badge' => null, 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'all_time', 'rank' => 6, 'player_name' => 'كريم', 'avatar' => 'assets/images/av-karim.png', 'score' => 12900, 'wins' => 60, 'badge' => null, 'is_current_user' => false]);
        LeaderboardEntry::create(['period_type' => 'all_time', 'rank' => 15, 'player_name' => 'أنت (أسامة)', 'avatar' => 'assets/images/av-karim.png', 'score' => 8650, 'wins' => 42, 'badge' => 'المخضرم 🏅', 'is_current_user' => true]);

        // 4. الإشعارات
        AppNotification::truncate();
        AppNotification::create([
            'title' => 'أهلاً بك في لمّة! 🎉',
            'message' => 'استمتع بألعاب القعدة والتحدي مع أصحابك وعائلتك محلياً وأونلاين وبطريقة اللمّة الممتعة.',
            'type' => 'info',
            'icon' => 'celebration',
            'is_read' => false,
            'is_active' => true,
        ]);

        AppNotification::create([
            'title' => 'تحدي نهاية الأسبوع بدأ! 🏆',
            'message' => 'العب أي لعبة الآن واحصل على نقاط مضاعفة لتصعد إلى قمة لوحة الترتيب.',
            'type' => 'reward',
            'icon' => 'military_tech',
            'is_read' => false,
            'is_active' => true,
        ]);

        AppNotification::create([
            'title' => 'تمت إضافة أسئلة وأمثال جديدة 🍿',
            'message' => 'أكثر من 60 سؤال وإفيه ومثل شعبي جديد تمت إضافتهم لجميع فئات الألعاب.',
            'type' => 'update',
            'icon' => 'auto_awesome',
            'is_read' => true,
            'is_active' => true,
        ]);

        // 5. الصفحات الثابتة
        AppPage::truncate();
        AppPage::create([
            'slug' => 'privacy-policy',
            'title' => 'سياسة الخصوصية',
            'content' => "## سياسة الخصوصية لتطبيق لمّة\n\nنحن في **لمّة** نقدر خصوصيتك ونلتزم بحمايتها بالكامل. لا نقوم بمشاركة أي بيانات شخصية مع أطراف ثالثة. جميع جلسات اللعب المحلية تتم بالكامل على جهازك دون إرسال أي تسجيلات صوتية أو وسائط خارجية.\n\n### البيانات التي نجمعها:\n- الاسم المستعار والرمز التعريفي للجولة.\n- إحصائيات النقاط والفوز داخل اللعبة.\n- التفضيلات المختارة (اللهجة والوضع الليلي).\n\nإذا كانت لديك أي استفسارات، يمكنك التواصل معنا في أي وقت عبر الدعم الفني.",
            'is_active' => true,
        ]);

        AppPage::create([
            'slug' => 'terms-conditions',
            'title' => 'الشروط والأحكام',
            'content' => "## شروط وأحكام استخدام تطبيق لمّة\n\nباستخدامك لتطبيق **لمّة**، فإنك توافق على الالتزام بالشروط الآتية:\n\n1. التطبيق مخصص للترفيه الجماعي والمرح بين الأصدقاء والعائلة.\n2. يُمنع استخدام أسماء مسيئة أو غير لائقة في أسماء الفرق والغرف الشبكية.\n3. يحتفظ فريق لمّة بالحق في تحديث وتطوير المحتوى والأسئلة بانتظام.\n4. جميع حقوق الملكية الفكرية لتصميم وأكواد التطبيق محفوظة بالكامل لشركة لمّة.",
            'is_active' => true,
        ]);

        AppPage::create([
            'slug' => 'faq-help',
            'title' => 'المساعدة والأسئلة الشائعة',
            'content' => "## الأسئلة الشائعة وطرق اللعب\n\n### ما هي طرق اللعب المتاحة في لمّة؟\n- **لعبة محلية (Pass & Play):** هاتف واحد يتناوب عليه الأصدقاء للإجابة والتحدي.\n- **طريقة اللمّة (المذيع):** لاعب واحد يمسك الموبايل كالمذيع ويقرأ الأسئلة للقعدة كلها، سواء بنمط (كلنا واحد) للتسلية أو بنمط (فِرق وتحدي) لاحتساب نقاط الفرق الفائزة.\n- **لعبة أونلاين:** غرف شبكية برمز سري من 6 أرقام للعب عن بُعد.\n\n### هل يمكن اللعب بدون إنترنت؟\nنعم! اللعب المحلي وطريقة اللمّة تعملان بكفاءة تامة دون الحاجة لاتصال بالإنترنت مع توفر بنك أسئلة مدمج ضخم.",
            'is_active' => true,
        ]);

        AppPage::create([
            'slug' => 'contact-us',
            'title' => 'التواصل والدعم الفني',
            'content' => "نسعد دائماً بسماع آرائك ومقترحاتك لتطوير لمّة! فريق الدعم متاح على مدار الساعة لمساعدتك.",
            'meta' => [
                'email' => 'support@lammah.app',
                'whatsapp' => '+201000000000',
                'phone' => '+201200000000',
                'website' => 'https://lammah.app',
            ],
            'is_active' => true,
        ]);
    }
}

