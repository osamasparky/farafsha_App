<?php

namespace App\Filament\Widgets;

use Filament\Widgets\ChartWidget;

class UserActivityChart extends ChartWidget
{
    protected static ?string $heading = 'نشاط المستخدمين والجلسات (آخر 12 أسبوعاً)';
    protected static ?int $sort = 2;
    protected int | string | array $columnSpan = 'full';

    protected function getData(): array
    {
        return [
            'datasets' => [
                [
                    'label' => 'الجلسات النشطة',
                    'data' => [140, 128, 110, 92, 100, 86, 104, 80, 94, 72, 84, 160],
                    'borderColor' => '#8138E8',
                    'backgroundColor' => 'rgba(129, 56, 232, 0.15)',
                    'fill' => true,
                    'tension' => 0.4,
                ],
            ],
            'labels' => ['أسبوع 1', 'أسبوع 2', 'أسبوع 3', 'أسبوع 4', 'أسبوع 5', 'أسبوع 6', 'أسبوع 7', 'أسبوع 8', 'أسبوع 9', 'أسبوع 10', 'أسبوع 11', 'أسبوع 12'],
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}

