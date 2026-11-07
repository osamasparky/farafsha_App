<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LeaderboardResource\Pages;
use App\Models\LeaderboardEntry;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class LeaderboardResource extends Resource
{
    protected static ?string $model = LeaderboardEntry::class;

    protected static ?string $navigationIcon = 'heroicon-o-trophy';
    protected static ?string $navigationGroup = 'المتصدرين والنتائج';
    protected static ?string $modelLabel = 'لاعب متصدر';
    protected static ?string $pluralModelLabel = 'لوحة الترتيب (Leaderboard)';
    protected static ?int $navigationSort = 5;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('بيانات المتصدر')
                    ->schema([
                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('player_name')
                                    ->label('اسم اللاعب')
                                    ->required()
                                    ->maxLength(60),

                                Forms\Components\Select::make('period_type')
                                    ->label('فترة الترتيب')
                                    ->options([
                                        'weekly' => 'هذا الأسبوع (Weekly)',
                                        'monthly' => 'هذا الشهر (Monthly)',
                                        'all_time' => 'كل الوقت (All-Time)',
                                    ])
                                    ->required(),

                                Forms\Components\TextInput::make('rank')
                                    ->label('المركز في الترتيب')
                                    ->numeric()
                                    ->required(),

                                Forms\Components\TextInput::make('score')
                                    ->label('مجموع النقاط')
                                    ->numeric()
                                    ->required(),

                                Forms\Components\TextInput::make('wins')
                                    ->label('عدد مرات الفوز')
                                    ->numeric()
                                    ->default(0),

                                Forms\Components\TextInput::make('badge')
                                    ->label('اللقب / الشارة')
                                    ->placeholder('مثال: بطل الأسبوع 👑')
                                    ->maxLength(60),

                                Forms\Components\TextInput::make('avatar')
                                    ->label('مسار صورة الأفاتار')
                                    ->default('assets/images/av-ahmed.png'),

                                Forms\Components\Toggle::make('is_current_user')
                                    ->label('حساب اللاعب الحالي (أنت)'),
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
                    ->sortable()
                    ->alignCenter(),

                Tables\Columns\TextColumn::make('player_name')
                    ->label('اللاعب')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('period_type')
                    ->label('الفترة')
                    ->formatStateUsing(fn ($state) => match ($state) {
                        'weekly' => 'هذا الأسبوع',
                        'monthly' => 'هذا الشهر',
                        'all_time' => 'كل الوقت',
                        default => $state,
                    })
                    ->badge()
                    ->color(fn ($state) => match ($state) {
                        'weekly' => 'info',
                        'monthly' => 'warning',
                        'all_time' => 'success',
                        default => 'gray',
                    }),

                Tables\Columns\TextColumn::make('score')
                    ->label('النقاط')
                    ->numeric()
                    ->sortable()
                    ->color('warning')
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('wins')
                    ->label('الفوز')
                    ->sortable(),

                Tables\Columns\TextColumn::make('badge')
                    ->label('الشارة')
                    ->placeholder('-'),
            ])
            ->defaultSort('score', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('period_type')
                    ->label('تصفية حسب الفترة')
                    ->options([
                        'weekly' => 'هذا الأسبوع',
                        'monthly' => 'هذا الشهر',
                        'all_time' => 'كل الوقت',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListLeaderboards::route('/'),
            'create' => Pages\CreateLeaderboard::route('/create'),
            'edit' => Pages\EditLeaderboard::route('/{record}/edit'),
        ];
    }
}

