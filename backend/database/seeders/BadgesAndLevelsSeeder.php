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

        // 1. الأوسمة
        $badges = [
            [
                'title' => 'ملك الأمثال',
                'description' => 'أجب على 10 أمثال شعبية بنجاح دون ارتكاب أي خطأ.',
                'game_id' => $amthalGame?->id,
                'required_points' => 300,
                'icon' => 'quote',
                'color' => '#D2566A',
                'sort_order' => 1,
                'is_active' => true,
            ],
            [
                'title' => 'العبقري',
                'description' => 'أجب بسرعة فائقة في أول 5 ثوانٍ من السؤال.',
                'game_id' => null,
                'required_points' => 600,
                'icon' => 'bulb',
                'color' => '#2F6E7A',
                'sort_order' => 2,
                'is_active' => true,
            ],
            [
                'title' => 'سمّيع',
                'description' => 'تفوّق في جولات التحديات الموسيقية والغنائية.',
                'game_id' => null,
                'required_points' => 900,
                'icon' => 'music',
                'color' => '#B23A72',
                'sort_order' => 3,
                'is_active' => true,
            ],
            [
                'title' => 'عاشق السينما',
                'description' => 'خمّن أكثر من 15 إيفيه سينمائي بدقة تامة.',
                'game_id' => $quotesGame?->id,
                'required_points' => 1200,
                'icon' => 'film',
                'color' => '#F59E0B',
                'sort_order' => 4,
                'is_active' => true,
            ],
            [
                'title' => 'حاوي اللمّة',
                'description' => 'حقّق المركز الأول في 10 ألعاب جماعية مختلفة.',
                'game_id' => null,
                'required_points' => 2000,
                'icon' => 'trophy',
                'color' => '#A35BFF',
                'sort_order' => 5,
                'is_active' => true,
            ],
            [
                'title' => 'أسطورة التحدي',
                'description' => 'تجاوز حاجز 3,000 نقطة واعتلِ صدارة لوحة الترتيب.',
                'game_id' => null,
                'required_points' => 3500,
                'icon' => 'star',
                'color' => '#FFD27A',
                'sort_order' => 6,
                'is_active' => true,
            ],
        ];

        foreach ($badges as $badge) {
            Badge::updateOrCreate(
                ['title' => $badge['title']],
                $badge
            );
        }

        // 2. المستويات والرتب
        $levels = [
            ['level_number' => 1, 'title' => 'مبتدئ اللمّة', 'min_points' => 0, 'color' => '#94A3B8', 'sort_order' => 1],
            ['level_number' => 2, 'title' => 'لاعب نشط', 'min_points' => 300, 'color' => '#38BDF8', 'sort_order' => 2],
            ['level_number' => 3, 'title' => 'صائد النقاط', 'min_points' => 700, 'color' => '#34D399', 'sort_order' => 3],
            ['level_number' => 4, 'title' => 'متحمس الجلسات', 'min_points' => 1200, 'color' => '#A78BFA', 'sort_order' => 4],
            ['level_number' => 5, 'title' => 'خبير الألعاب', 'min_points' => 1800, 'color' => '#F472B6', 'sort_order' => 5],
            ['level_number' => 6, 'title' => 'نجم السهرة', 'min_points' => 2500, 'color' => '#FB923C', 'sort_order' => 6],
            ['level_number' => 7, 'title' => 'حريف الأمثال', 'min_points' => 3300, 'color' => '#FBBF24', 'sort_order' => 7],
            ['level_number' => 8, 'title' => 'زعيم القعدة', 'min_points' => 4200, 'color' => '#E879F9', 'sort_order' => 8],
            ['level_number' => 9, 'title' => 'أسطورة اللمّة', 'min_points' => 5200, 'color' => '#60A5FA', 'sort_order' => 9],
            ['level_number' => 10, 'title' => 'سلطان الألعاب', 'min_points' => 6500, 'color' => '#FFD700', 'sort_order' => 10],
            ['level_number' => 11, 'title' => 'عميد التحديات', 'min_points' => 8000, 'color' => '#FFB800', 'sort_order' => 11],
            ['level_number' => 12, 'title' => 'الملك المتوج', 'min_points' => 10000, 'color' => '#FFD27A', 'sort_order' => 12],
        ];

        foreach ($levels as $lvl) {
            Level::updateOrCreate(
                ['level_number' => $lvl['level_number']],
                $lvl
            );
        }
    }
}

