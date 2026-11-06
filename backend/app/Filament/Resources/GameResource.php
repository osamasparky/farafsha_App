<?php

namespace App\Filament\Resources;

use App\Filament\Resources\GameResource\Pages;
use App\Models\Game;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class GameResource extends Resource
{
    protected static ?string $model = Game::class;

    protected static ?string $navigationIcon = 'heroicon-o-puzzle-piece';
    protected static ?string $navigationGroup = 'إدارة المحتوى والألعاب';
    protected static ?string $modelLabel = 'لعبة';
    protected static ?string $pluralModelLabel = 'الألعاب';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('المعلومات الأساسية')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->label('اسم اللعبة')
                            ->placeholder('مثال: أمثال شعبية')
                            ->required()
                            ->maxLength(100),

                        Forms\Components\TextInput::make('slug')
                            ->label('المعرّف اللطيف (Slug)')
                            ->placeholder('amthal-shaabiya')
                            ->required()
                            ->unique(ignoreRecord: true),

                        Forms\Components\TextInput::make('subtitle')
                            ->label('عنوان فرعي')
                            ->placeholder('مثال: كمّل المثل الشعبي')
                            ->maxLength(150),

                        Forms\Components\Select::make('category')
                            ->label('التصنيف')
                            ->options([
                                'أمثال' => 'أمثال شعبية',
                                'إفيهات' => 'أفلام ومسلسلات',
                                'تخمين' => 'تخمين وشخصيات',
                                'ذكاء وسرعة' => 'ذكاء وسرعة',
                                'معلومات عامة' => 'معلومات وثقافة',
                                'تواصل وضحك' => 'تواصل وضحك',
                            ])
                            ->required(),

                        Forms\Components\TextInput::make('badge_text')
                            ->label('شارة مميزة (Badge)')
                            ->placeholder('الأكثر طلباً / جديد'),

                        Forms\Components\Select::make('template_type')
                            ->label('نوع قالب اللعبة')
                            ->options([
                                'choice' => 'اختيار من متعدد (أمثال / إفيهات / ثقافة)',
                                'who_am_i' => 'تخمين شخصيات (أسئلة نعم/لا)',
                                'forbidden_words' => 'كلمات ممنوعة (Taboo)',
                                'two_truths_one_lie' => 'حقيقتان وكذبة',
                                'acting_drawing' => 'تمثيل ورسم صامت',
                            ])
                            ->default('choice')
                            ->required(),

                        Forms\Components\Select::make('game_mode')
                            ->label('نمط اللعب المتاح')
                            ->options([
                                'local_only' => 'لعب محلي فقط (جهاز واحد)',
                                'online_only' => 'أونلاين فقط (غرف متعددة الأجهزة)',
                                'hybrid' => 'هجين (يدعم المحلي والأونلاين)',
                            ])
                            ->default('hybrid')
                            ->required(),
                    ])->columns(2),

                Forms\Components\Section::make('شرح وقواعد الجولة')
                    ->schema([
                        Forms\Components\Textarea::make('description')
                            ->label('نبذة عن اللعبة')
                            ->rows(3)
                            ->columnSpanFull(),

                        Forms\Components\Textarea::make('instructions')
                            ->label('تعليمات وقواعد اللعب')
                            ->rows(3)
                            ->columnSpanFull(),

                        Forms\Components\TextInput::make('min_players')
                            ->label('الحد الأدنى للاعبين')
                            ->numeric()
                            ->default(2)
                            ->required(),

                        Forms\Components\TextInput::make('max_players')
                            ->label('الحد الأقصى للاعبين')
                            ->numeric()
                            ->default(12)
                            ->required(),

                        Forms\Components\TextInput::make('default_rounds')
                            ->label('عدد الجولات الافتراضي')
                            ->numeric()
                            ->default(10)
                            ->required(),

                        Forms\Components\TextInput::make('default_duration_seconds')
                            ->label('مدة الدور (بالثواني)')
                            ->numeric()
                            ->default(20)
                            ->required(),
                    ])->columns(2),

                Forms\Components\Section::make('الحالة والظهور')
                    ->schema([
                        Forms\Components\Toggle::make('is_active')
                            ->label('مفعلة وتظهر في التطبيق')
                            ->default(true),

                        Forms\Components\Toggle::make('is_featured')
                            ->label('لعبة مميزة في الصفحة الأولى')
                            ->default(false),

                        Forms\Components\TextInput::make('sort_order')
                            ->label('ترتيب الظهور')
                            ->numeric()
                            ->default(0),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('اسم اللعبة')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('category')
                    ->label('التصنيف')
                    ->badge()
                    ->color('primary'),

                Tables\Columns\TextColumn::make('template_type')
                    ->label('القالب البرمجي')
                    ->badge()
                    ->color('gray'),

                Tables\Columns\TextColumn::make('content_items_count')
                    ->label('عدد البطاقات')
                    ->counts('contentItems')
                    ->sortable(),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعلة')
                    ->boolean(),

                Tables\Columns\IconColumn::make('is_featured')
                    ->label('مميزة')
                    ->boolean(),

                Tables\Columns\TextColumn::make('sort_order')
                    ->label('الترتيب')
                    ->sortable(),
            ])
            ->defaultSort('sort_order', 'asc')
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListGames::route('/'),
            'create' => Pages\CreateGame::route('/create'),
            'edit' => Pages\EditGame::route('/{record}/edit'),
        ];
    }
}
