<?php

namespace Database\Seeders;

use App\Models\ContentItem;
use App\Models\Game;
use App\Models\Pack;
use Illuminate\Database\Seeder;

class ForbiddenWordsCompleteSeeder extends Seeder
{
    public function run(): void
    {
        $game = Game::where('slug', 'forbidden-words')->first();
        if (!$game) {
            return;
        }

        $pack = Pack::firstOrCreate(
            ['slug' => 'forbidden-words-100-cards'],
            [
                'game_id' => $game->id,
                'name' => 'موسوعة التحديات الكبرى - 100 كارت ممنوع تقول',
                'description' => '100 كارت مميز وممتع من أقوى مصطلحات وأكلات وأماكن وشخصيات الثقافة المصرية والعربية لتحدي اللمة.',
                'is_free' => true,
                'is_active' => true,
            ]
        );

        $challenges = [
            // 1. أكلات ومشروبات مصرية
            [
                'prompt' => 'كشري',
                'answer' => 'كشري',
                'forbidden_words' => ['رز', 'عدس', 'مكرونة', 'صلصة', 'دقة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'طعمية (فلافل)',
                'answer' => 'طعمية',
                'forbidden_words' => ['فول', 'زيت', 'خضرة', 'سمسم', 'ساندوتش'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'ملوخية',
                'answer' => 'ملوخية',
                'forbidden_words' => ['شوربة', 'طشة', 'توم', 'أرانب', 'خضرا'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'حواوشي',
                'answer' => 'حواوشي',
                'forbidden_words' => ['عيش', 'لحمة', 'فرن', 'بصل', 'رغيف'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'كبدة إسكندراني',
                'answer' => 'كبدة',
                'forbidden_words' => ['فينو', 'فلفل حامي', 'توم', 'ليمون', 'عربة'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'حمام محشي',
                'answer' => 'حمام',
                'forbidden_words' => ['فريكة', 'رز', 'طيور', 'زغاليل', 'أكل'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'فسيخ',
                'answer' => 'فسيخ',
                'forbidden_words' => ['شم النسيم', 'سمك', 'ملح', 'بصل', 'رائحة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'رنجة',
                'answer' => 'رنجة',
                'forbidden_words' => ['سمك', 'مدخن', 'شوك', 'بطارخ', 'ليمون'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'كوارع',
                'answer' => 'كوارع',
                'forbidden_words' => ['رجلين', 'شوربة', 'فتة', 'عجل', 'جيلاتين'],
                'difficulty' => 'hard',
            ],
            [
                'prompt' => 'محشي كرنب',
                'answer' => 'محشي',
                'forbidden_words' => ['رز', 'حلة', 'ورق', 'صلصة', 'شتاء'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'عصير قصب',
                'answer' => 'قصب',
                'forbidden_words' => ['عصارة', 'سكر', 'كوز', 'أخضر', 'ثلج'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'سحلب',
                'answer' => 'سحلب',
                'forbidden_words' => ['شتاء', 'لبن', 'سمسم', 'مكسرات', 'سخن'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'أم علي',
                'answer' => 'أم علي',
                'forbidden_words' => ['رقاق', 'لبن', 'مكسرات', 'فرن', 'حلو'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'بسبوسة',
                'answer' => 'بسبوسة',
                'forbidden_words' => ['سميد', 'شربات', 'قشطة', 'صينية', 'حلويات'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'كنافة بالمانجو',
                'answer' => 'كنافة',
                'forbidden_words' => ['رمضان', 'شعر', 'فاكهة', 'كريمة', 'صينية'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'سوبيا',
                'answer' => 'سوبيا',
                'forbidden_words' => ['رمضان', 'جوز هند', 'لبن', 'أبيض', 'مشروب'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'عرقسوس',
                'answer' => 'عرقسوس',
                'forbidden_words' => ['رمضان', 'أسود', 'إبريق', 'صاجات', 'مشروب'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'بلح الشام',
                'answer' => 'بلح الشام',
                'forbidden_words' => ['قلي', 'زيت', 'شربات', 'مقرمش', 'حلويات'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'بابا غنوج',
                'answer' => 'بابا غنوج',
                'forbidden_words' => ['بتنجان', 'طحينة', 'شوي', 'توم', 'سلطة'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'ترمس',
                'answer' => 'ترمس',
                'forbidden_words' => ['ملح', 'ليمون', 'شاطئ', 'تسالي', 'كمون'],
                'difficulty' => 'easy',
            ],

            // 2. معالم وأماكن ومواصلات
            [
                'prompt' => 'أهرامات الجيزة',
                'answer' => 'الأهرامات',
                'forbidden_words' => ['خوفو', 'فراعنة', 'أبو الهول', 'حجر', 'مصر'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'برج القاهرة',
                'answer' => 'برج القاهرة',
                'forbidden_words' => ['الجزيرة', 'لوتس', 'تلسكوب', 'طويل', 'مطعم دوار'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'خان الخليلي',
                'answer' => 'خان الخليلي',
                'forbidden_words' => ['سياح', 'فضيات', 'الحسين', 'توابل', 'أنتيكات'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'كوبري قصر النيل',
                'answer' => 'كوبري قصر النيل',
                'forbidden_words' => ['أسود', 'نيل', 'تمشية', 'وسط البلد', 'جسر'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'مترو الأنفاق',
                'answer' => 'المترو',
                'forbidden_words' => ['محطة', 'تذكرة', 'نفق', 'قطار', 'زحمة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'توك توك',
                'answer' => 'توك توك',
                'forbidden_words' => ['تلات عجلات', 'مهرجانات', 'شارع', 'سائق', 'صغير'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'ميكروباص',
                'answer' => 'ميكروباص',
                'forbidden_words' => ['أجرة', 'سواق', 'كنبة', 'جنيه', 'محطة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'قلعة صلاح الدين',
                'answer' => 'القلعة',
                'forbidden_words' => ['محمد علي', 'مئذنة', 'مسجد', 'جبل', 'آثار'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'حديقة الحيوان',
                'answer' => 'حديقة الحيوان',
                'forbidden_words' => ['الجيزة', 'قرد', 'أسد', 'أقفاص', 'خروجة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'شاطئ ستانلي',
                'answer' => 'ستانلي',
                'forbidden_words' => ['إسكندرية', 'كوبري', 'بحر', 'كباين', 'موج'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'السد العالي',
                'answer' => 'السد العالي',
                'forbidden_words' => ['أسوان', 'كهرباء', 'نيل', 'بحيرة ناصر', 'طاقة'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'ميدان التحرير',
                'answer' => 'التحرير',
                'forbidden_words' => ['مجمع', 'مسلة', 'وسط البلد', 'ثورة', 'وسط'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'شارع المعز',
                'answer' => 'شارع المعز',
                'forbidden_words' => ['فاطمي', 'آثار', 'مساجد', 'حجارة', 'باب الفتوح'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'مطار القاهرة',
                'answer' => 'المطار',
                'forbidden_words' => ['طيارة', 'شنط', 'جواز سفر', 'سفر', 'صالة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'سوق الجمعة',
                'answer' => 'سوق الجمعة',
                'forbidden_words' => ['السيدة عائشة', 'كلاب', 'عصافير', 'حمام', 'رخيص'],
                'difficulty' => 'hard',
            ],

            // 3. أدوات وأشياء منزلية وشخصية
            [
                'prompt' => 'الشبشب الطاير',
                'answer' => 'شبشب',
                'forbidden_words' => ['أم', 'رجل', 'ضرب', 'بلاستيك', 'نيشان'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'ريموت التلفزيون',
                'answer' => 'ريموت',
                'forbidden_words' => ['قنوات', 'حجارة', 'زرار', 'شاشة', 'كنبة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'شاحن الموبايل',
                'answer' => 'شاحن',
                'forbidden_words' => ['سلك', 'بطارية', 'فيشة', 'كهرباء', 'نسبة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'كولمان المية',
                'answer' => 'كولمان',
                'forbidden_words' => ['ثلج', 'حنفية', 'ساقع', 'بلاستيك', 'صيف'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'مروحة سقف',
                'answer' => 'مروحة',
                'forbidden_words' => ['هواء', 'ريش', 'تدور', 'حر', 'صيف'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'طاسة تيفال',
                'answer' => 'طاسة',
                'forbidden_words' => ['قلي', 'بيض', 'زيت', 'مطبخ', 'سواد'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'منبه الساعة',
                'answer' => 'منبه',
                'forbidden_words' => ['نوم', 'استيقاظ', 'صوت', 'رنين', 'تأخير'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'اللب الأبيض (أو السوري)',
                'answer' => 'لب',
                'forbidden_words' => ['محمصة', 'قشر', 'تسالي', 'ماتش', 'سهرة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'الشيشة',
                'answer' => 'شيشة',
                'forbidden_words' => ['معسل', 'فحم', 'قهوة', 'ليّ', 'دخان'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'كوتشينة',
                'answer' => 'كوتشينة',
                'forbidden_words' => ['ورق', 'لعب', 'شايب', 'بنت', 'ولد'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'دومينو',
                'answer' => 'دومينو',
                'forbidden_words' => ['بلاط', 'نقط', 'قهوة', 'دوشة', 'شيش'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'طاولة زهر',
                'answer' => 'طاولة',
                'forbidden_words' => ['نرد', 'خشب', 'قواشيط', 'دوجي', 'قهوة'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'مكواة هدوم',
                'answer' => 'مكواة',
                'forbidden_words' => ['بخار', 'سخونة', 'قميص', 'مكرمش', 'ترابيزة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'بطانية شتوية',
                'answer' => 'بطانية',
                'forbidden_words' => ['دفا', 'سرير', 'برد', 'نوم', 'ثقيلة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'مظلة (شمسية)',
                'answer' => 'شمسية',
                'forbidden_words' => ['مطر', 'شمس', 'بحر', 'قماش', 'فتح'],
                'difficulty' => 'easy',
            ],

            // 4. شخصيات ومشاهير وسينما
            [
                'prompt' => 'عادل إمام',
                'answer' => 'عادل إمام',
                'forbidden_words' => ['زعيم', 'كوميديا', 'مسرحية', 'مدرسة المشاغبين', 'ممثل'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'محمد صلاح',
                'answer' => 'محمد صلاح',
                'forbidden_words' => ['ليفربول', 'كورة', 'فخر العرب', 'هدف', 'منتخب'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'اللمبي (محمد سعد)',
                'answer' => 'اللمبي',
                'forbidden_words' => ['فيلم', 'صوت معوج', 'درية', 'أطاطا', 'رقص'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'إسماعيل يس',
                'answer' => 'إسماعيل يس',
                'forbidden_words' => ['ضحكة', 'بؤ', 'كوميديان', 'جيش', 'أبيض وأسود'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'أم كلثوم',
                'answer' => 'أم كلثوم',
                'forbidden_words' => ['كوكب الشرق', 'منديل', 'نظارة', 'غناء', 'خميس'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'الكبير أوي',
                'answer' => 'الكبير أوي',
                'forbidden_words' => ['المزاريطة', 'أحمد مكي', 'جوني', 'عمدة', 'مربوحة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'شمس الزناتي',
                'answer' => 'شمس الزناتي',
                'forbidden_words' => ['عادل إمام', 'واحة', 'مارشال برعي', 'سلاح', 'سبعة'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'مدرسة المشاغبين',
                'answer' => 'مدرسة المشاغبين',
                'forbidden_words' => ['بهجت الأباصيري', 'مرسي الزناتي', 'مسرحية', 'مستر حسن', 'فصل'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'بكيزة وزغلول',
                'answer' => 'بكيزة وزغلول',
                'forbidden_words' => ['سهير البابلي', 'إسعاد يونس', 'فقر', 'قصر', 'مسلسل'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'فطوطة (سمير غانم)',
                'answer' => 'فطوطة',
                'forbidden_words' => ['بدلة خضرا', 'جزمة كبيرة', 'فوازير', 'سمورة', 'قصير'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'بوجي وطمطم',
                'answer' => 'بوجي وطمطم',
                'forbidden_words' => ['عرائس', 'قرد', 'أرنبة', 'رمضان', 'أطفال'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'بكار',
                'answer' => 'بكار',
                'forbidden_words' => ['نوبة', 'رشيدة', 'معزة', 'كرتون', 'رمضان'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'عم شكشك',
                'answer' => 'عم شكشك',
                'forbidden_words' => ['شباك', 'شارع', 'عجوز', 'مسرح مصر', 'طاقية'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'أبو تريكة',
                'answer' => 'أبو تريكة',
                'forbidden_words' => ['أهلي', 'رقم 22', 'ماجيكو', 'كورة', 'منتخب'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'نجيب محفوظ',
                'answer' => 'نجيب محفوظ',
                'forbidden_words' => ['نوبل', 'روايات', 'الثلاثية', 'خان الخليلي', 'كاتب'],
                'difficulty' => 'medium',
            ],

            // 5. عادات ومناسبات ومواقف اجتماعية
            [
                'prompt' => 'العيدية',
                'answer' => 'العيدية',
                'forbidden_words' => ['فلوس', 'عيد', 'أطفال', 'فلوس جديدة', 'أهل'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'فانوس رمضان',
                'answer' => 'فانوس',
                'forbidden_words' => ['صيام', 'شمعة', 'صاج', 'إضاءة', 'وحوي'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'السبوع',
                'answer' => 'السبوع',
                'forbidden_words' => ['مولود', 'غربال', 'هون', 'شمعة', 'حمص'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'الزفة الاسكندراني',
                'answer' => 'الزفة',
                'forbidden_words' => ['عروسة', 'عريس', 'زمامير', 'عربيات', 'طبلة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'الحنّة',
                'answer' => 'الحنة',
                'forbidden_words' => ['قبل الفرح', 'رسم', 'صواني', 'رقص', 'بنات'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'كحك العيد',
                'answer' => 'كحك',
                'forbidden_words' => ['سكر بودرة', 'منقاش', 'سمنة', 'صاجات', 'فرن'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'طابور العيش',
                'answer' => 'طابور العيش',
                'forbidden_words' => ['فرن', 'بطاقة تموين', 'رغيف', 'زحمة', 'فكة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'فصال في المحل',
                'answer' => 'فصال',
                'forbidden_words' => ['سعر', 'رخيص', 'بائع', 'تخفيض', 'اشتريت'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'قعدة القهوة البلدي',
                'answer' => 'القهوة',
                'forbidden_words' => ['كراسي خيزران', 'شاي', 'شيشة', 'طاولة', 'شارع'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'عزومة رمضان',
                'answer' => 'عزومة',
                'forbidden_words' => ['أكل', 'إفطار', 'أقارب', 'سفرة', 'مغرب'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'الثانوية العامة',
                'answer' => 'ثانوية عامة',
                'forbidden_words' => ['امتحان', 'تنسيق', 'مذاكرة', 'مجموع', 'دروس خصوصية'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'مدفع الإفطار',
                'answer' => 'مدفع الإفطار',
                'forbidden_words' => ['رمضان', 'مغرب', 'صوت', 'قلعة', 'اضرب'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'مسحراتي',
                'answer' => 'مسحراتي',
                'forbidden_words' => ['طبلة', 'سحور', 'اصحى يا نايم', 'شارع', 'رمضان'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'خناقة في الشارع',
                'answer' => 'خناقة',
                'forbidden_words' => ['شومة', 'صوت عالي', 'تسليك', 'ضرب', 'ناس'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'كتب الكتاب',
                'answer' => 'كتب كتاب',
                'forbidden_words' => ['مأذون', 'منديل', 'دفتر', 'شهود', 'مبروك'],
                'difficulty' => 'easy',
            ],

            // 6. مهن وحرف وأشخاص
            [
                'prompt' => 'السايس',
                'answer' => 'السايس',
                'forbidden_words' => ['ركنة', 'عربية', 'شارع', 'إرجع إرجع', 'فلوس'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'الحلاق',
                'answer' => 'الحلاق',
                'forbidden_words' => ['مقص', 'شعر', 'موس', 'كرسي', 'استشوار'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'السباك',
                'answer' => 'السباك',
                'forbidden_words' => ['ماسورة', 'حنفية', 'مفتاح إنجليزي', 'تسريب', 'مية'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'المكوجي',
                'answer' => 'المكوجي',
                'forbidden_words' => ['رجل', 'بخار', 'هدوم', 'مغسلة', 'شماعة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'البواب',
                'answer' => 'البواب',
                'forbidden_words' => ['عمارة', 'مدخل', 'غسيل عربيات', 'جلابية', 'مصعد'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'الجرسون',
                'answer' => 'الجرسون',
                'forbidden_words' => ['مطعم', 'مينيو', 'صينية', 'شيك', 'تبس'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'مصلح الموبايلات',
                'answer' => 'مصلح موبايلات',
                'forbidden_words' => ['شاشة', 'سوفت وير', 'باغة', 'فلاتة', 'مكسورة'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'الكمسري',
                'answer' => 'الكمسري',
                'forbidden_words' => ['تذكرة', 'أتوبيس', 'قطار', 'خرامة', 'غرامة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'المأذون',
                'answer' => 'المأذون',
                'forbidden_words' => ['زواج', 'طلاق', 'دفتر', 'منديل', 'ألف مبروك'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'طبيب الأسنان',
                'answer' => 'طبيب أسنان',
                'forbidden_words' => ['ضرس', 'بنج', 'شنيور', 'خلع', 'وجع'],
                'difficulty' => 'easy',
            ],

            // 7. ألعاب ومصطلحات ترفيهية ورياضية
            [
                'prompt' => 'استغماية',
                'answer' => 'استغماية',
                'forbidden_words' => ['عد', 'خلاويص', 'حائط', 'لسا', 'اختباء'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'بنك الحظ',
                'answer' => 'بنك الحظ',
                'forbidden_words' => ['فلوس', 'سجن', 'نرد', 'محطة', 'شراء مدن'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'السلم والتعبان',
                'answer' => 'السلم والتعبان',
                'forbidden_words' => ['نزول', 'طلوع', 'رقم 100', 'نرد', 'مربعات'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'كرسي الاعتراف (الصراحة والجرأة)',
                'answer' => 'صراحة أو جرأة',
                'forbidden_words' => ['إزازة', 'لف', 'سؤال', 'تحدي', 'اعتراف'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'ضربة جزاء',
                'answer' => 'ضربة جزاء',
                'forbidden_words' => ['جون', 'حارس', 'نقطة جزاء', 'فار', 'كورة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'كارت أحمر',
                'answer' => 'كارت أحمر',
                'forbidden_words' => ['حكم', 'طرد', 'فاول', 'جيب', 'إنذار'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'صياد السمك',
                'answer' => 'صياد سمك',
                'forbidden_words' => ['سنارة', 'طعم', 'بحر', 'مركب', 'شبكة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'مسدس مية',
                'answer' => 'مسدس مية',
                'forbidden_words' => ['بلاستيك', 'رش', 'عيد', 'لعب', 'بلل'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'الأتاري القديم',
                'answer' => 'أتاري',
                'forbidden_words' => ['شريط', 'ذراع', 'ماريو', 'تلفزيون', 'زمان'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'بلياردو',
                'answer' => 'بلياردو',
                'forbidden_words' => ['عصاية', 'كور', 'مثلث', 'بوكيت', 'طاولة خضرا'],
                'difficulty' => 'medium',
            ],

            // 8. مفاهيم وكلمات شائعة وذكية
            [
                'prompt' => 'إشارة المرور',
                'answer' => 'إشارة المرور',
                'forbidden_words' => ['أحمر', 'أخضر', 'أصفر', 'عربيات', 'شارع'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'المراية',
                'answer' => 'المراية',
                'forbidden_words' => ['انعكاس', 'وش', 'إزاز', 'تسريح', 'نظرة'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'المظروف المقفول',
                'answer' => 'مظروف',
                'forbidden_words' => ['جواب', 'ورقة', 'طابع', 'بوستة', 'ختم'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'البصمة الصوتية أو الإبهام',
                'answer' => 'البصمة',
                'forbidden_words' => ['صابع', 'حبر', 'موبايل', 'قفل', 'فتح'],
                'difficulty' => 'medium',
            ],
            [
                'prompt' => 'الواي فاي (Wi-Fi)',
                'answer' => 'واي فاي',
                'forbidden_words' => ['راوتر', 'إنترنت', 'باسورد', 'شبكة', 'سلك'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'سماعات البلوتوث',
                'answer' => 'سماعة بلوتوث',
                'forbidden_words' => ['ودن', 'وايرلس', 'صوت', 'شحن', 'موسيقى'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'بطاقة الرقم القومي',
                'answer' => 'البطاقة',
                'forbidden_words' => ['14 رقم', 'صورة', 'سجل مدني', 'محفظة', 'تجديد'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'طفاية الحريق',
                'answer' => 'طفاية حريق',
                'forbidden_words' => ['نار', 'أحمر', 'خرطوم', 'بودرة', 'دخان'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'النضارة الشمسية',
                'answer' => 'نضارة شمس',
                'forbidden_words' => ['عين', 'عدسات', 'صيف', 'ماركة', 'حماية'],
                'difficulty' => 'easy',
            ],
            [
                'prompt' => 'ماكينة الصراف الآلي (ATM)',
                'answer' => 'ATM',
                'forbidden_words' => ['فيزا', 'فلوس', 'سحب', 'باسورد', 'بنك'],
                'difficulty' => 'easy',
            ],
        ];

        $now = now();
        $count = 0;

        foreach ($challenges as $item) {
            ContentItem::updateOrCreate(
                [
                    'game_id' => $game->id,
                    'prompt' => $item['prompt'],
                ],
                [
                    'pack_id' => $pack->id,
                    'type' => 'forbidden_words',
                    'answer' => $item['answer'],
                    'distractors' => null,
                    'forbidden_words' => $item['forbidden_words'],
                    'hints' => null,
                    'acceptable_alternatives' => null,
                    'explanation' => 'اشرح لفريقك الكلمة دون ذكر أي من الكلمات المحظورة!',
                    'media_type' => null,
                    'media_url' => null,
                    'source_reference' => 'فرفشة - بنك أسئلة ممنوع تقول',
                    'dialect' => 'egyptian',
                    'difficulty' => $item['difficulty'],
                    'age_rating' => 'all',
                    'is_sensitive' => false,
                    'status' => 'published',
                    'report_count' => 0,
                    'is_active' => true,
                    'updated_at' => $now,
                ]
            );
            $count++;
        }

        $this->command->info("تم بنجاح إضافة وتحديث $count كارت تحدي جديد للعبة ممنوع تقول في لوحة التحكم!");
    }
}

