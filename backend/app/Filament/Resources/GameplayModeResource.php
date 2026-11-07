<?php

namespace App\Filament\Resources;

use App\Filament\Resources\GameplayModeResource\Pages;
use App\Models\GameplayMode;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class GameplayModeResource extends Resource
{
    protected static ?string $model = GameplayMode::class;

    protected static ?string $navigationIcon = 'heroicon-o-puzzle-piece';
    protected static ?string $navigationGroup = 'الألعاب والمحتوى';
    protected static ?string $modelLabel = 'طريقة لعب';
    protected static ?string $pluralModelLabel = 'طرق وأنماط اللعب';
    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('إعدادات طريقة اللعب وصورتها')
                    ->description('تحكم في الصور والنصوص والشارات التي تظهر للمستخدم في شاشة اختيار طريقة اللعب.')
                    ->schema([
                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('title')
                                    ->label('اسم طريقة اللعب')
                                    ->placeholder('مثال: طريقة اللمّة')
                                    ->required()
                                    ->maxLength(100),

                                Forms\Components\Select::make('slug')
                                    ->label('معرف النمط (Slug)')
                                    ->options([
                                        'local' => 'لعبة محلية (Pass & Play) - local',
                                        'lammah' => 'طريقة اللمّة (المذيع والقعدة) - lammah',
                                        'online' => 'لعبة أونلاين (غرفة سريعة وكود) - online',
                                    ])
                                    ->required()
                                    ->unique(ignoreRecord: true),
                            ]),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('badge')
                                    ->label('الشارة التوضيحية (Badge)')
                                    ->placeholder('مثال: الأمتع للقعدة 🎉')
                                    ->maxLength(60),

                                Forms\Components\ColorPicker::make('highlight_color')
                                    ->label('لون التمييز (Highlight Color)')
                                    ->default('#A35BFF'),
                            ]),

                        Forms\Components\Textarea::make('subtitle')
                            ->label('الوصف التوضيحي السريع')
                            ->placeholder('واحد معاه الموبايل والميكروفون ويقرأ الأسئلة للقعدة كلها')
                            ->rows(2)
                            ->columnSpanFull(),

                        Forms\Components\FileUpload::make('image')
                            ->label('صورة كارت طريقة اللعب (Mode Card Image)')
                            ->disk('public')
                            ->directory('modes')
                            ->visibility('public')
                            ->image()
                            ->imagePreviewHeight('240')
                            ->imageEditor()
                            ->acceptedFileTypes(['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml'])
                            ->openable()
                            ->downloadable()
                            ->maxSize(10240)
                            ->columnSpanFull()
                            ->helperText('ارفع صورة واضحة بخلفية مفرغة أو ملونة لتظهر فوراً داخل كارت الطريقة بتطبيق الهاتف والويب.'),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\Toggle::make('is_active')
                                    ->label('مفعّلة وتظهر في تطبيق الهاتف والويب')
                                    ->default(true),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('ترتيب العرض (1، 2، 3...)')
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
                Tables\Columns\ImageColumn::make('image')
                    ->label('الصورة')
                    ->circular(false)
                    ->height(55),

                Tables\Columns\TextColumn::make('title')
                    ->label('اسم الطريقة')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('slug')
                    ->label('المعرّف (Slug)')
                    ->badge()
                    ->color('info'),

                Tables\Columns\TextColumn::make('badge')
                    ->label('الشارة')
                    ->badge()
                    ->color('warning')
                    ->placeholder('بدون شارة'),

                Tables\Columns\ColorColumn::make('highlight_color')
                    ->label('اللون'),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعّل')
                    ->boolean(),

                Tables\Columns\TextColumn::make('sort_order')
                    ->label('الترتيب')
                    ->sortable(),
            ])
            ->defaultSort('sort_order', 'asc')
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

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListGameplayModes::route('/'),
            'create' => Pages\CreateGameplayMode::route('/create'),
            'edit' => Pages\EditGameplayMode::route('/{record}/edit'),
        ];
    }
}

