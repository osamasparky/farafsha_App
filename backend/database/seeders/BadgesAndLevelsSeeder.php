<?php

namespace Database\Seeders;

use App\Models\Badge;
use App\Models\Game;
use App\Models\Level;
use Illuminate\Database\Seeder;

class BadgesAndLevelsSeeder extends Seeder
{
    public function run(): void
    {
        $amthalGame = Game::where('slug', 'like', '%amthal%')->first();
        $quotesGame = Game::where('slug', 'like', '%quote%')->first();
        $whoAmIGame = Game::where('slug', 'like', '%who%')->first();
        $forbiddenGame = Game::where('slug', 'like', '%forbidden%')->first();
        $twoTruthsGame = Game::where('slug', 'like', '%two-truths%')->first();
        $speedTriviaGame = Game::where('slug', 'like', '%speed%')->first();
        $autobusGame = Game::where('slug', 'like', '%autobus%')->first();

        // 18 وسام وإنجاز مدروس بدقة لزيادة تفاعل اللاعبين
        $badges = [
            // المستوى 1: البدايات السريعة ومكافآت الترحيب الفورية (50 - 250 نقطة)
            [
                'title' => 'شعلة البداية',
                'description' => 'أول خطوة في عالم الفرفشة! أكمل أول لعبة بنجاح واجمع أولى نقاطك.',
                'game_id' => null,
                'required_points' => 50,
                'icon' => 'fire',
                'color' => '#FF6B4A',
                'sort_order' => 1,
                'is_active' => true,
            ],
            [
                'title' => 'روح القعدة',
                'description' => 'شارك في جولة حماسية مع أصحابك في طريقة اللمّة وكن اللاعب الأكثر تفاعلاً.',
                'game_id' => null,
                'required_points' => 150,
                'icon' => 'heart',
                'color' => '#FF4D80',
                'sort_order' => 2,
                'is_active' => true,
            ],
            [
                'title' => 'سريع البديهة',
                'description' => 'جاوب على سؤال في أقل من 3 ثوانٍ من بداية العداد دون أي تردد.',
                'game_id' => $speedTriviaGame?->id,
                'required_points' => 250,
                'icon' => 'bolt',
                'color' => '#FFD000',
                'sort_order' => 3,
                'is_active' => true,
            ],

            // المستوى 2: إتقان الألعاب التراثية والثقافية (400 - 850 نقطة)
            [
                'title' => 'ابن البلد وأصيل الأمثال',
                'description' => 'فك شفرة 15 مثلاً شعبياً قديماً وأكمل الأمثال التراثية بدقة 100%.',
                'game_id' => $amthalGame?->id,
                'required_points' => 400,
                'icon' => 'quote',
                'color' => '#D2566A',
                'sort_order' => 4,
                'is_active' => true,
            ],
            [
                'title' => 'أفيش السينما المصرية',
                'description' => 'حفظت إفيهات وجمل السينما المصرية والعربية عن ظهر قلب ولم يفتك أي مشهد.',
                'game_id' => $quotesGame?->id,
                'required_points' => 550,
                'icon' => 'film',
                'color' => '#F59E0B',
                'sort_order' => 5,
                'is_active' => true,
            ],
            [
                'title' => 'سائق الأتوبيس المحترف',
                'description' => 'أكملت جميع خانات أتوبيس كومبليت (ولد، بنت، جماد، بلاد) في وقت قياسي.',
                'game_id' => $autobusGame?->id,
                'required_points' => 700,
                'icon' => 'bus',
                'color' => '#06D6A0',
                'sort_order' => 6,
                'is_active' => true,
            ],
            [
                'title' => 'شارلوك هولمز اللمّة',
                'description' => 'خمنت الشخصية الغامضة أو الشيء المستخبي في لعبة "مين أنا؟" بأقل عدد أسئلة.',
                'game_id' => $whoAmIGame?->id,
                'required_points' => 850,
                'icon' => 'mask',
                'color' => '#8B5CF6',
                'sort_order' => 7,
                'is_active' => true,
            ],

            // المستوى 3: التحدي والمنافسة الذكية (1000 - 1600 نقطة)
            [
                'title' => 'كاشف الكدب والخدع',
                'description' => 'كشفت الكذبة من بين الحقيقتين بذكاء 10 مرات متتالية دون الوقوع في الفخ.',
                'game_id' => $twoTruthsGame?->id,
                'required_points' => 1000,
                'icon' => 'bulb',
                'color' => '#3B82F6',
                'sort_order' => 8,
                'is_active' => true,
            ],
            [
                'title' => 'فصيح اللسان بلا تعتعة',
                'description' => 'وصفت الكلمة المطلوبة لفريقك في لعبة "ممنوع تقول" دون النطق بأي كلمة محظورة.',
                'game_id' => $forbiddenGame?->id,
                'required_points' => 1200,
                'icon' => 'shield',
                'color' => '#EC4899',
                'sort_order' => 9,
                'is_active' => true,
            ],
            [
                'title' => 'العبقري المُنقذ',
                'description' => 'حققت ريمونتادا تاريخية لفريقك بانتزاع نقاط الفوز في الجولة الحاسمة الأخيرة.',
                'game_id' => null,
                'required_points' => 1400,
                'icon' => 'bulb',
                'color' => '#10B981',
                'sort_order' => 10,
                'is_active' => true,
            ],
            [
                'title' => 'مذيع القعدة الرسمي',
                'description' => 'توليت إدارة وتحكيم 5 جولات كاملة في طريقة اللمّة وقدت الضحك والتحدي للقعدة.',
                'game_id' => null,
                'required_points' => 1600,
                'icon' => 'star',
                'color' => '#A855F7',
                'sort_order' => 11,
                'is_active' => true,
            ],

            // المستوى 4: قوة الأونلاين والبطولات التنافسية (1800 - 2500 نقطة)
            [
                'title' => 'سفير اللمّة والجماعة',
                'description' => 'أنشأت غرفة أونلاين وجمعت الأصدقاء في بث صوتي وتحدٍ مباشر لا يُنسى.',
                'game_id' => null,
                'required_points' => 1800,
                'icon' => 'people',
                'color' => '#0EA5E9',
                'sort_order' => 12,
                'is_active' => true,
            ],
            [
                'title' => 'قنّاص الثواني الأخيرة',
                'description' => 'حصدت الدرجة الكاملة في 5 أسئلة متتالية في لعبة "سؤال على السريع" بسرعة البرق.',
                'game_id' => $speedTriviaGame?->id,
                'required_points' => 2200,
                'icon' => 'timer',
                'color' => '#F97316',
                'sort_order' => 13,
                'is_active' => true,
            ],
            [
                'title' => 'كابوس المنافسين',
                'description' => 'فزت بـ 3 بطولات أونلاين متتالية دون أي هزيمة وتصدرت لوحة الصدارة بامتياز.',
                'game_id' => null,
                'required_points' => 2500,
                'icon' => 'rocket',
                'color' => '#EF4444',
                'sort_order' => 14,
                'is_active' => true,
            ],

            // المستوى 5: أساطير ونخبة فرفشة (3000 - 6000 نقطة)
            [
                'title' => 'فرفوش مع مرتبة الشرف',
                'description' => 'بلغت 3,000 نقطة وأثبتّ أنك روح القعدة ومصدر الضحك والفرفشة الأول.',
                'game_id' => null,
                'required_points' => 3000,
                'icon' => 'crown',
                'color' => '#F59E0B',
                'sort_order' => 15,
                'is_active' => true,
            ],
            [
                'title' => 'جوهرة اللمّة النادرة',
                'description' => 'لاعب استثنائي! تجاوزت 4,000 نقطة وتواجدت في قائمة أفضل اللاعبين بالمنصة.',
                'game_id' => null,
                'required_points' => 4000,
                'icon' => 'gem',
                'color' => '#06B6D4',
                'sort_order' => 16,
                'is_active' => true,
            ],
            [
                'title' => 'حاوي الألعاب الشامل',
                'description' => 'حققت الفوز في جميع الألعاب السبعة بلا استثناء (أمثال، سينما، أتوبيس، كذبة، ممنوع، إلخ).',
                'game_id' => null,
                'required_points' => 5000,
                'icon' => 'trophy',
                'color' => '#A35BFF',
                'sort_order' => 17,
                'is_active' => true,
            ],
            [
                'title' => 'أسطورة فرفشة الخالدة',
                'description' => 'أعلى وسام فخري في المنصة! تجاوز 6,000 نقطة واعتلِ عرش لوحة الصدارة الشاملة.',
                'game_id' => null,
                'required_points' => 6000,
                'icon' => 'crown',
                'color' => '#FFD700',
                'sort_order' => 18,
                'is_active' => true,
            ],
        ];

        foreach ($badges as $badge) {
            Badge::updateOrCreate(
                ['title' => $badge['title']],
                $badge
            );
        }

        // 10 مستويات ورتب تدرجية للاعبين
        $levels = [
            ['level_number' => 1, 'title' => 'مبتدئ اللمّة 🌱', 'min_points' => 0, 'color' => '#94A3B8', 'sort_order' => 1],
            ['level_number' => 2, 'title' => 'لاعب نشط ⚡', 'min_points' => 200, 'color' => '#38BDF8', 'sort_order' => 2],
            ['level_number' => 3, 'title' => 'صائد النقاط 🎯', 'min_points' => 500, 'color' => '#34D399', 'sort_order' => 3],
            ['level_number' => 4, 'title' => 'متحمس الجلسات 🔥', 'min_points' => 1000, 'color' => '#A78BFA', 'sort_order' => 4],
            ['level_number' => 5, 'title' => 'خبير الألعاب 🧠', 'min_points' => 1800, 'color' => '#F472B6', 'sort_order' => 5],
            ['level_number' => 6, 'title' => 'نجم السهرة ⭐', 'min_points' => 2800, 'color' => '#FB923C', 'sort_order' => 6],
            ['level_number' => 7, 'title' => 'حريف التحديات 🏆', 'min_points' => 4000, 'color' => '#FBBF24', 'sort_order' => 7],
            ['level_number' => 8, 'title' => 'زعيم القعدة 🎩', 'min_points' => 5500, 'color' => '#E879F9', 'sort_order' => 8],
            ['level_number' => 9, 'title' => 'أسطورة اللمّة 💎', 'min_points' => 7500, 'color' => '#60A5FA', 'sort_order' => 9],
            ['level_number' => 10, 'title' => 'سلطان فرفشة المتوج 👑', 'min_points' => 10000, 'color' => '#FFD700', 'sort_order' => 10],
        ];

        foreach ($levels as $lvl) {
            Level::updateOrCreate(
                ['level_number' => $lvl['level_number']],
                $lvl
            );
        }
    }
}
