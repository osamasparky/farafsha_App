<?php

namespace Database\Seeders;

use App\Models\ContentItem;
use App\Models\Game;
use App\Models\Pack;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. إنشاء المستخدم المشرف الافتراضي للوحة Filament
        $admin = User::updateOrCreate(
            ['email' => 'admin@lammah.app'],
            [
                'name' => 'أسامة صبري',
                'password' => Hash::make('password'),
                'is_admin' => true,
                'level' => 12,
                'total_score' => 4320,
                'wins_count' => 32,
                'games_played' => 148,
            ]
        );

        // مستخدمين تجريبيين للوحة الشرف
        $demoUsers = [
            ['name' => 'أحمد فتحي', 'email' => 'ahmed@lammah.app', 'total_score' => 2840, 'level' => 10],
            ['name' => 'سارة حسن', 'email' => 'sara@lammah.app', 'total_score' => 2120, 'level' => 8],
            ['name' => 'محمود علي', 'email' => 'mahmoud@lammah.app', 'total_score' => 1980, 'level' => 7],
            ['name' => 'منة عادل', 'email' => 'menna@lammah.app', 'total_score' => 1760, 'level' => 6],
            ['name' => 'كريم نبيل', 'email' => 'karim@lammah.app', 'total_score' => 1520, 'level' => 5],
        ];

        foreach ($demoUsers as $du) {
            User::updateOrCreate(
                ['email' => $du['email']],
                [
                    'name' => $du['name'],
                    'password' => Hash::make('password'),
                    'is_admin' => false,
                    'total_score' => $du['total_score'],
                    'level' => $du['level'],
                ]
            );
        }

        // 2. بذر ألعاب الـ MVP الستة المعتمدة في الوثيقة والتصميم
        $gamesData = [
            [
                'name' => 'أمثال شعبية',
                'slug' => 'amthal-shaabiya',
                'subtitle' => 'كمّل المثل الشعبي',
                'description' => 'يظهر صدر مثل شعبي مصري أو عربي وعلى اللاعبين أو الفرق إكماله باختيار الإجابة الصحيحة أو قولها.',
                'instructions' => 'اختر التكملة الصحيحة قبل انتهاء العداد (20 ثانية). 3 نقاط للإجابة المباشرة ونقطتان بعد استخدام التلميح.',
                'icon' => 'format_quote_rounded',
                'category' => 'أمثال',
                'template_type' => 'choice',
                'game_mode' => 'hybrid',
                'min_players' => 2,
                'max_players' => 10,
                'default_rounds' => 10,
                'default_duration_seconds' => 20,
                'difficulty_levels' => ['سهل', 'متوسط', 'حريف'],
                'rules_config' => ['correct_points' => 3, 'hint_points' => 2, 'skip_penalty' => 0],
                'is_active' => true,
                'is_featured' => true,
                'sort_order' => 1,
            ],
            [
                'name' => 'جمل مشهورة',
                'slug' => 'famous-quotes',
                'subtitle' => 'إفيهات من الأفلام والمسلسلات',
                'description' => 'إكمال أشهر الإفيهات والجمل الأيقونية من السينما والدراما المصرية والعربية.',
                'instructions' => 'اقرأ بداية الإفيه وخمّن الجملة الناقصة أو اسم الشخصية والعمل.',
                'icon' => 'movie_filter_rounded',
                'category' => 'إفيهات',
                'template_type' => 'choice',
                'game_mode' => 'hybrid',
                'min_players' => 2,
                'max_players' => 12,
                'default_rounds' => 10,
                'default_duration_seconds' => 20,
                'difficulty_levels' => ['شائع', 'متوسط', 'عشاق السينما'],
                'rules_config' => ['correct_points' => 3, 'close_points' => 2, 'skip_penalty' => 0],
                'is_active' => true,
                'is_featured' => true,
                'sort_order' => 2,
            ],
            [
                'name' => 'مين أنا؟',
                'slug' => 'who-am-i',
                'subtitle' => 'شخصيات وأشياء بأسئلة نعم/لا',
                'description' => 'لاعب يخمن شخصية تاريخية، فنية أو شيئاً عبر طرح أسئلة إجابتها نعم أو لا فقط.',
                'instructions' => 'الفريق يجيب بنعم أو لا فقط. 5 نقاط إذا حزرت قبل 10 أسئلة.',
                'icon' => 'help_outline_rounded',
                'category' => 'تخمين',
                'template_type' => 'who_am_i',
                'game_mode' => 'hybrid',
                'min_players' => 3,
                'max_players' => 12,
                'default_rounds' => 6,
                'default_duration_seconds' => 60,
                'difficulty_levels' => ['سهل', 'متوسط', 'صعب'],
                'rules_config' => ['before_10_points' => 5, 'before_20_points' => 3, 'after_hint' => 1],
                'is_active' => true,
                'is_featured' => true,
                'sort_order' => 3,
            ],
            [
                'name' => 'ممنوع تقول',
                'slug' => 'forbidden-words',
                'subtitle' => 'اشرح الكلمة بدون المحظورات',
                'description' => 'اشرح الكلمة المستهدفة لفريقك بدون ذكر الكلمات المحظورة الثلاث أو مشتقاتها.',
                'instructions' => 'لديك 45 ثانية لشرح أكبر عدد من الكلمات، انتبه للكلمات الممنوعة في البطاقة!',
                'icon' => 'block_rounded',
                'category' => 'ذكاء وسرعة',
                'template_type' => 'forbidden_words',
                'game_mode' => 'local_only',
                'min_players' => 4,
                'max_players' => 12,
                'default_rounds' => 6,
                'default_duration_seconds' => 45,
                'difficulty_levels' => ['متوسط', 'حريف'],
                'rules_config' => ['word_point' => 1, 'forbidden_penalty' => -1],
                'is_active' => true,
                'is_featured' => false,
                'sort_order' => 4,
            ],
            [
                'name' => 'حقيقتان وكذبة',
                'slug' => 'two-truths-and-lie',
                'subtitle' => 'اكتشف الكذبة بين الحقائق',
                'description' => 'يقدم كل لاعب 3 عبارات عن نفسه أو عن معلومة عامة، وعلى الآخرين كشف الكذبة.',
                'instructions' => 'صوّت على الجملة التي تعتقد أنها الكذبة، نقطة لكل من كشفها ونقطة لصاحب العبارة لكل من أخطأ.',
                'icon' => 'psychology_rounded',
                'category' => 'تواصل وضحك',
                'template_type' => 'two_truths_one_lie',
                'game_mode' => 'hybrid',
                'min_players' => 3,
                'max_players' => 8,
                'default_rounds' => 6,
                'default_duration_seconds' => 30,
                'difficulty_levels' => ['عائلي', 'أصدقاء'],
                'rules_config' => ['guesser_correct' => 1, 'teller_bluff' => 1],
                'is_active' => true,
                'is_featured' => false,
                'sort_order' => 5,
            ],
            [
                'name' => 'سؤال على السريع',
                'slug' => 'speed-trivia',
                'subtitle' => 'معلومات عامة وتحدي السرعة',
                'description' => 'أسئلة خفيفة وسريعة في الفن والرياضة والتاريخ والعلوم، الفوز للأسرع والأدق.',
                'instructions' => 'أجب قبل انتهاء العداد؛ الأسرع يحصد أعلى النقاط.',
                'icon' => 'bolt_rounded',
                'category' => 'معلومات عامة',
                'template_type' => 'choice',
                'game_mode' => 'hybrid',
                'min_players' => 2,
                'max_players' => 12,
                'default_rounds' => 10,
                'default_duration_seconds' => 15,
                'difficulty_levels' => ['سهل', 'متوسط', 'تحدي'],
                'rules_config' => ['first_correct' => 3, 'second_correct' => 2, 'others_correct' => 1],
                'is_active' => true,
                'is_featured' => true,
                'sort_order' => 6,
            ],
        ];

        foreach ($gamesData as $g) {
            $game = Game::updateOrCreate(['slug' => $g['slug']], $g);

            // إنشاء الحزمة الافتراضية للعبة
            $pack = Pack::updateOrCreate(
                ['slug' => $g['slug'] . '-starter-pack'],
                [
                    'game_id' => $game->id,
                    'name' => 'الحزمة التأسيسية - ' . $game->name,
                    'description' => 'مجموعة البطاقات الأساسية الجاهزة للعب الفوري مجاناً',
                    'dialect' => 'egyptian',
                    'age_rating' => 'all',
                    'is_free' => true,
                    'cards_count' => 10,
                    'is_active' => true,
                ]
            );

            // بذر بطاقات ومحتوى فعلي لكل لعبة
            $this->seedGameContent($game, $pack);
        }
    }

    private function seedGameContent(Game $game, Pack $pack): void
    {
        if ($game->slug === 'amthal-shaabiya') {
            $items = [
                [
                    'prompt' => 'اللي اختشوا ...',
                    'answer' => 'ماتوا',
                    'distractors' => ['في حظهم', 'من الجوع', 'من الخوف'],
                    'explanation' => 'يُضرب لمن فقد الحياء وأصبح لا يبالي بعواقب أفعاله.',
                    'difficulty' => 'easy',
                ],
                [
                    'prompt' => 'القرد في عين أمه ...',
                    'answer' => 'غزال',
                    'distractors' => ['سلطان', 'جميل', 'أمير'],
                    'explanation' => 'يُضرب في حب الأم الفطري الذي يجعلها ترى ابنها الأجمل دائماً.',
                    'difficulty' => 'easy',
                ],
                [
                    'prompt' => 'على قد لحافك ...',
                    'answer' => 'مد رجليك',
                    'distractors' => ['نام وارتاح', 'غطي نفسك', 'عيش حياتك'],
                    'explanation' => 'يُضرب في تدبير المعيشة والإنفاق حسب القدرة.',
                    'difficulty' => 'easy',
                ],
                [
                    'prompt' => 'باب النجار ...',
                    'answer' => 'مخلّع',
                    'distractors' => ['مكسور', 'مفتوح', 'حديدي'],
                    'explanation' => 'يُضرب لمن ينفع الناس ويهمل شؤونه الخاصة.',
                    'difficulty' => 'easy',
                ],
                [
                    'prompt' => 'اطبخ يا جارية كلف يا ...',
                    'answer' => 'سيدي',
                    'distractors' => ['مولاي', 'باشا', 'معلم'],
                    'explanation' => 'يُضرب في أن إنجاز العمل المتقن يتطلب توفير موارده.',
                    'difficulty' => 'medium',
                ],
            ];
        } elseif ($game->slug === 'famous-quotes') {
            $items = [
                [
                    'prompt' => 'يا بابا .. أنا مش زعلان ...',
                    'answer' => 'أنا متضايق بس',
                    'distractors' => ['أنا مش باطل', 'أنا زعلان قوي', 'أنا مصدوم وخلاص'],
                    'explanation' => 'فيلم الكيف - الفنان محمود عبد العزيز (مزاجنجي).',
                    'difficulty' => 'easy',
                ],
                [
                    'prompt' => 'هو كله ضرب ضرب ...',
                    'answer' => 'مفيش شتيمة؟',
                    'distractors' => ['مفيش راحة؟', 'مفيش كلام؟', 'مفيش طيبة؟'],
                    'explanation' => 'فيلم بوحة - الفنان محمد سعد.',
                    'difficulty' => 'easy',
                ],
                [
                    'prompt' => 'أنا مش كريم أنا ...',
                    'answer' => 'أنا شحاتة يا عمري',
                    'distractors' => ['أنا حمادة', 'أنا غلبان', 'أنا مخلص'],
                    'explanation' => 'فيلم كركر - الفنان محمد سعد والفنان حسن حسني.',
                    'difficulty' => 'medium',
                ],
                [
                    'prompt' => 'منك لله يا فخري ..',
                    'answer' => 'ضيعت مستقبلي',
                    'distractors' => ['خربت بيتي', 'بهدلت العيلة', 'نسيت الهدية'],
                    'explanation' => 'مسرحية العيال كبرت - الفنان سعيد صالح.',
                    'difficulty' => 'medium',
                ],
            ];
        } elseif ($game->slug === 'forbidden-words') {
            $items = [
                [
                    'prompt' => 'أهرامات الجيزة',
                    'answer' => 'الأهرامات',
                    'forbidden_words' => ['فراعنة', 'مصر', 'أبو الهول', 'خوفو'],
                    'explanation' => 'اشرح لفريقك بدون نطق هذه الكلمات!',
                    'difficulty' => 'medium',
                ],
                [
                    'prompt' => 'فنجان قهوة',
                    'answer' => 'قهوة',
                    'forbidden_words' => ['شرب', 'كافيين', 'بن', 'سكر'],
                    'explanation' => 'اشرح لفريقك بدون ذكر المكونات الممنوعة.',
                    'difficulty' => 'medium',
                ],
            ];
        } else {
            $items = [
                [
                    'prompt' => 'ما هي أطول قارات العالم من حيث المساحة؟',
                    'answer' => 'آسيا',
                    'distractors' => ['أفريقيا', 'أمريكا الشمالية', 'أوروبا'],
                    'explanation' => 'قارة آسيا هي الأكبر مساحة وسكاناً على كوكب الأرض.',
                    'difficulty' => 'easy',
                ],
                [
                    'prompt' => 'كم عدد لاعبي فريق كرة القدم داخل الملعب؟',
                    'answer' => '11 لاعب',
                    'distractors' => ['10 لاعبين', '12 لاعب', '9 لاعبين'],
                    'explanation' => 'يتكون الفريق من 11 لاعباً متضمناً حارس المرمى.',
                    'difficulty' => 'easy',
                ],
            ];
        }

        foreach ($items as $item) {
            ContentItem::updateOrCreate(
                [
                    'game_id' => $game->id,
                    'prompt' => $item['prompt'],
                ],
                array_merge($item, [
                    'pack_id' => $pack->id,
                    'type' => $game->template_type,
                    'dialect' => 'egyptian',
                    'status' => 'published',
                    'is_active' => true,
                ])
            );
        }

        // بذر ميزات الإنتاج وبيانات موقع فرفشة الجديد ووسائل التواصل وباقة الإفيهات
        $this->call([
            ProductionFeaturesSeeder::class,
            FarfashaWebSeeder::class,
            SocialProvidersSeeder::class,
            FamousQuotesPackSeeder::class,
        ]);
    }
}
