<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LeaderboardResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class LeaderboardResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-trophy';
    protected static ?string $navigationGroup = 'اللعب والمنافسات';
    protected static ?string $modelLabel = 'متصدر';
    protected static ?string $pluralModelLabel = 'لوحة الصدارة والمتصدرين';
    protected static ?int $navigationSort = 2;

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->where('status', 'active')
            ->where('is_admin', false);
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('بيانات المتصدر')
                    ->schema([
                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('name')
                                    ->label('اسم اللاعب')
                                    ->disabled(),

                                Forms\Components\TextInput::make('total_score')
                                    ->label('مجموع النقاط')
                                    ->numeric()
                                    ->required(),

                                Forms\Components\TextInput::make('wins_count')
                                    ->label('عدد مرات الفوز')
                                    ->numeric()
                                    ->default(0),

                                Forms\Components\TextInput::make('games_played')
                                    ->label('عدد المباريات')
                                    ->numeric()
                                    ->default(0),

                                Forms\Components\TextInput::make('level')
                                    ->label('المستوى')
                                    ->numeric()
                                    ->default(1),
                            ]),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('rank')
                    ->label('المركز')
                    ->rowIndex()
                    ->alignCenter()
                    ->badge()
                    ->color('warning'),

                Tables\Columns\TextColumn::make('name')
                    ->label('اللاعب')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('total_score')
                    ->label('النقاط')
                    ->numeric()
                    ->sortable()
                    ->color('warning')
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('wins_count')
                    ->label('الفوز')
                    ->numeric()
                    ->sortable()
                    ->color('success'),

                Tables\Columns\TextColumn::make('games_played')
                    ->label('المباريات')
                    ->numeric()
                    ->sortable(),

                Tables\Columns\TextColumn::make('level')
                    ->label('المستوى')
                    ->badge()
                    ->color('info')
                    ->sortable(),
            ])
            ->defaultSort('total_score', 'desc')
            ->actions([
                Tables\Actions\EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListLeaderboards::route('/'),
            'edit' => Pages\EditLeaderboard::route('/{record}/edit'),
        ];
    }
}

