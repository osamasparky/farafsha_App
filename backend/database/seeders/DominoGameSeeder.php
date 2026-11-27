<?php

namespace Database\Seeders;

use App\Models\Game;
use Illuminate\Database\Seeder;

class DominoGameSeeder extends Seeder
{
    public function run(): void
    {
        Game::updateOrCreate(
            ['slug' => 'domino'],
            [
                'name' => 'الدومينو',
                'description' => 'لعبة الدومينو المصرية الكلاسيكية من 2 إلى 4 لاعبين أونلاين مع نظام الفرق (2 ضد 2) أو اللعب الفردي حتى الوصول لـ 100 نقطة.',
                'category' => 'ذكاء وسرعة',
                'game_mode' => 'online_only',
                'is_offline_capable' => false,
                'min_players' => 2,
                'max_players' => 4,
                'default_rounds' => 10,
                'default_duration_seconds' => 25,
                'is_active' => true,
                'is_featured' => true,
                'sort_order' => 8,
                'scoring_guide' => [
                    ['condition' => 'الفوز بمباراة الدومينو (100 نقطة)', 'points' => '+15 نقطة', 'note' => 'يُحتسب في لوحة الصدارة'],
                    ['condition' => 'مكافأة المشاركة وإتمام المباراة', 'points' => '+5 نقاط', 'note' => 'لباقي اللاعبين'],
                ],
                'how_to_play_steps' => [
                    ['step_number' => 1, 'title' => 'اختر النمط والعدد', 'description' => 'العب فردي (2 أو 3 أو 4 لاعبين) أو فرق (2 ضد 2) حتى 100 نقطة.'],
                    ['step_number' => 2, 'title' => 'طابق الأرقام', 'description' => 'ضع بلاطة تطابق أحد طرفي السلسلة، أو اسحب من السوق عند عدم توفر حركة.'],
                    ['step_number' => 3, 'title' => 'تصدّر حتى 100 نقطة', 'description' => 'الفائز بالجولة يحصد نقاط البلاطات المتبقية في أيدي الخصوم!'],
                ],
            ]
        );
    }
}
