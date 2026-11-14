<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BadgeResource\Pages;
use App\Models\Badge;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class BadgeResource extends Resource
{
    protected static ?string $model = Badge::class;

    protected static ?string $navigationIcon = 'heroicon-o-sparkles';
    protected static ?string $navigationGroup = 'اللاعبون والمجتمع';
    protected static ?string $modelLabel = 'وسام';
    protected static ?string $pluralModelLabel = 'الأوسمة والإنجازات';
    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('تفاصيل الوسام')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('عنوان الوسام')
                            ->placeholder('مثال: ملك الأمثال، العبقري، صائد النقاط')
                            ->required()
                            ->maxLength(100),

                        Forms\Components\Textarea::make('description')
                            ->label('شرح الوسام وكيفية الحصول عليه')
                            ->placeholder('مثال: أجب على 10 أمثال شعبية بنجاح دون أي خطأ')
                            ->rows(3),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\Select::make('game_id')
                                    ->label('اللعبة التابع لها الوسام (اختياري)')
                                    ->relationship('game', 'name')
                                    ->placeholder('عام لجميع الألعاب')
                                    ->searchable()
                                    ->preload(),

                                Forms\Components\TextInput::make('required_points')
                                    ->label('النقاط المطلوبة لفتح الوسام')
                                    ->numeric()
                                    ->default(0)
                                    ->helperText('إذا وصل رصيد نقاط المستخدم لهذا الرقم يُفتح الوسام'),
                            ]),

                        Forms\Components\Grid::make(3)
                            ->schema([
                                Forms\Components\ColorPicker::make('color')
                                    ->label('لون الوسام المميز')
                                    ->default('#FFC24B'),

                                Forms\Components\Select::make('icon')
                                    ->label('الأيقونة الافتراضية')
                                    ->options(\App\Models\Badge::getAvailableIcons())
                                    ->searchable()
                                    ->preload()
                                    ->default('trophy'),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('ترتيب الظهور في البروفايل')
                                    ->numeric()
                                    ->default(0),
                            ]),

                        Forms\Components\FileUpload::make('image')
                            ->label('صورة مخصصة للوسام (اختياري)')
                            ->disk('public')
                            ->directory('badges')
                            ->visibility('public')
                            ->image()
                            ->acceptedFileTypes(['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml'])
                            ->imageEditor()
                            ->openable()
                            ->downloadable()
                            ->maxSize(5120)
                            ->helperText('إذا تم رفع صورة ستظهر بدلاً من الأيقونة الافتراضية'),

                        Forms\Components\Toggle::make('is_active')
                            ->label('مفعّل ويظهر في بروفايل اللاعب')
                            ->default(true),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ColorColumn::make('color')
                    ->label('اللون'),

                Tables\Columns\TextColumn::make('title')
                    ->label('اسم الوسام')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('game.name')
                    ->label('اللعبة')
                    ->default('عام لجميع الألعاب')
                    ->badge(),

                Tables\Columns\TextColumn::make('required_points')
                    ->label('النقاط المطلوبة')
                    ->sortable()
                    ->formatStateUsing(fn ($state) => number_format($state) . ' نقطة'),

                Tables\Columns\TextColumn::make('icon')
                    ->label('الأيقونة')
                    ->badge(),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعّل')
                    ->boolean(),

                Tables\Columns\TextColumn::make('sort_order')
                    ->label('الترتيب')
                    ->sortable(),
            ])
            ->defaultSort('sort_order')
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListBadges::route('/'),
            'create' => Pages\CreateBadge::route('/create'),
            'edit' => Pages\EditBadge::route('/{record}/edit'),
        ];
    }
}

