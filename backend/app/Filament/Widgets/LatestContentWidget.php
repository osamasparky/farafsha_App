<?php

namespace App\Filament\Widgets;

use App\Models\Game;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class LatestContentWidget extends BaseWidget
{
    protected static ?int $sort = 3;
    protected int | string | array $columnSpan = 'full';
    protected static ?string $heading = 'إدارة المحتوى والألعاب النشطة';

    public function table(Table $table): Table
    {
        return $table
            ->query(Game::query()->withCount('contentItems'))
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('اللعبة')
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('subtitle')
                    ->label('الوصف المختصر')
                    ->color('gray'),

                Tables\Columns\TextColumn::make('content_items_count')
                    ->label('عدد الأسئلة')
                    ->badge()
                    ->color('warning'),

                Tables\Columns\TextColumn::make('category')
                    ->label('التصنيف')
                    ->badge(),

                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->default('منشور')
                    ->badge()
                    ->color('success'),
            ])
            ->actions([
                Tables\Actions\Action::make('edit')
                    ->label('تعديل')
                    ->icon('heroicon-m-pencil-square')
                    ->url(fn (Game $record): string => "/admin/games/{$record->id}/edit"),
            ]);
    }
}

