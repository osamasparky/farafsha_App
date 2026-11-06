<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PackResource\Pages;
use App\Models\Pack;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class PackResource extends Resource
{
    protected static ?string $model = Pack::class;

    protected static ?string $navigationIcon = 'heroicon-o-archive-box';
    protected static ?string $navigationGroup = 'إدارة المحتوى والألعاب';
    protected static ?string $modelLabel = 'حزمة بطاقات';
    protected static ?string $pluralModelLabel = 'حزم البطاقات والتوسعات';
    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('معلومات الحزمة')
                    ->schema([
                        Forms\Components\Select::make('game_id')
                            ->label('اللعبة التابعة لها')
                            ->relationship('game', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),

                        Forms\Components\TextInput::make('name')
                            ->label('اسم الحزمة')
                            ->placeholder('مثال: حزمة مسرح مصر')
                            ->required(),

                        Forms\Components\TextInput::make('slug')
                            ->label('المعرّف اللطيف (Slug)')
                            ->required()
                            ->unique(ignoreRecord: true),

                        Forms\Components\Select::make('dialect')
                            ->label('اللهجة')
                            ->options([
                                'egyptian' => 'مصرية عامية',
                                'standard' => 'عربية فصحى',
                                'gulf' => 'خليجية',
                                'levantine' => 'شامية',
                            ])
                            ->default('egyptian')
                            ->required(),

                        Forms\Components\Select::make('age_rating')
                            ->label('التصنيف العمري')
                            ->options([
                                'all' => 'لجميع الأعمار',
                                'family' => 'عائلي',
                                '16+' => 'شبابي 16+',
                            ])
                            ->default('all')
                            ->required(),

                        Forms\Components\Textarea::make('description')
                            ->label('وصف الحزمة ومحتواها')
                            ->rows(3)
                            ->columnSpanFull(),
                    ])->columns(2),

                Forms\Components\Section::make('التسعير والتفعيل')
                    ->schema([
                        Forms\Components\Toggle::make('is_free')
                            ->label('حزمة مجانية متاحة للجميع')
                            ->default(true),

                        Forms\Components\TextInput::make('price')
                            ->label('السعر (إذا كانت مدفوعة)')
                            ->numeric()
                            ->default(0)
                            ->prefix('EGP'),

                        Forms\Components\Toggle::make('is_active')
                            ->label('مفعلة وتظهر في المتجر')
                            ->default(true),

                        Forms\Components\TextInput::make('version')
                            ->label('إصدار الحزمة')
                            ->default('1.0.0'),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('اسم الحزمة')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('game.name')
                    ->label('اللعبة')
                    ->badge()
                    ->sortable(),

                Tables\Columns\IconColumn::make('is_free')
                    ->label('مجانية')
                    ->boolean(),

                Tables\Columns\TextColumn::make('price')
                    ->label('السعر')
                    ->money('EGP'),

                Tables\Columns\TextColumn::make('content_items_count')
                    ->label('عدد البطاقات')
                    ->counts('contentItems')
                    ->sortable(),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعلة')
                    ->boolean(),
            ])
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
            'index' => Pages\ListPacks::route('/'),
            'create' => Pages\CreatePack::route('/create'),
            'edit' => Pages\EditPack::route('/{record}/edit'),
        ];
    }
}
