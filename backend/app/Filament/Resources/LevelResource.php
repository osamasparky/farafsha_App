<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LevelResource\Pages;
use App\Models\Level;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class LevelResource extends Resource
{
    protected static ?string $model = Level::class;

    protected static ?string $navigationIcon = 'heroicon-o-academic-cap';
    protected static ?string $navigationGroup = 'المستخدمين والملف الشخصي';
    protected static ?string $modelLabel = 'مستوى ورتبة';
    protected static ?string $pluralModelLabel = 'المستويات والرتب (Levels)';
    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('تفاصيل المستوى والرتبة')
                    ->schema([
                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('level_number')
                                    ->label('رقم المستوى')
                                    ->numeric()
                                    ->required()
                                    ->helperText('الترتيب الرقمي للمستوى، مثال: 1، 2، 3 ...'),

                                Forms\Components\TextInput::make('title')
                                    ->label('مسمى المستوى / الرتبة')
                                    ->placeholder('مثال: مبتدئ، خبير اللمّة، أسطورة القعدة')
                                    ->required()
                                    ->maxLength(100),
                            ]),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('min_points')
                                    ->label('الحد الأدنى للنقاط المطلوبة للوصول لهذا المستوى')
                                    ->numeric()
                                    ->required()
                                    ->default(0)
                                    ->helperText('إذا وصل رصيد نقاط المستخدم لهذا الرقم يرتقي لهذا المستوى تلقائياً'),

                                Forms\Components\ColorPicker::make('color')
                                    ->label('لون شارة المستوى')
                                    ->default('#FFC24B'),
                            ]),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('icon')
                                    ->label('رمز أو أيقونة المستوى (اختياري)')
                                    ->placeholder('star, crown, shield, fire, gem')
                                    ->default('star'),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('ترتيب الفرز')
                                    ->numeric()
                                    ->default(0),
                            ]),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('level_number')
                    ->label('المستوى')
                    ->sortable()
                    ->badge()
                    ->color('warning'),

                Tables\Columns\TextColumn::make('title')
                    ->label('مسمى الرتبة')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\ColorColumn::make('color')
                    ->label('اللون'),

                Tables\Columns\TextColumn::make('min_points')
                    ->label('النقاط المطلوبة')
                    ->sortable()
                    ->formatStateUsing(fn ($state) => number_format($state) . ' نقطة'),

                Tables\Columns\TextColumn::make('icon')
                    ->label('الأيقونة')
                    ->badge(),
            ])
            ->defaultSort('level_number')
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
            'index' => Pages\ListLevels::route('/'),
            'create' => Pages\CreateLevel::route('/create'),
            'edit' => Pages\EditLevel::route('/{record}/edit'),
        ];
    }
}
