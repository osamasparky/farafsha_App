<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DialectResource\Pages;
use App\Models\Dialect;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class DialectResource extends Resource
{
    protected static ?string $model = Dialect::class;

    protected static ?string $navigationIcon = 'heroicon-o-language';
    protected static ?string $navigationGroup = 'إدارة المحتوى والألعاب';
    protected static ?string $modelLabel = 'لهجة محتوى';
    protected static ?string $pluralModelLabel = 'اللهجات المدعومة (Dialects)';
    protected static ?int $navigationSort = 4;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('معلومات اللهجة')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->label('اسم اللهجة')
                            ->placeholder('مثال: لهجة مصرية')
                            ->required()
                            ->maxLength(60),

                        Forms\Components\TextInput::make('code')
                            ->label('كود اللهجة (Code)')
                            ->placeholder('egyptian')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(40),

                        Forms\Components\Select::make('icon')
                            ->label('رمز / علم اللهجة')
                            ->options(\App\Models\Dialect::getAvailableIcons())
                            ->searchable()
                            ->preload()
                            ->default('🇪🇬'),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\Toggle::make('is_active')
                                    ->label('مفعّلة في التطبيق')
                                    ->default(true),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('الترتيب')
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
                Tables\Columns\TextColumn::make('icon')
                    ->label('الرمز')
                    ->alignCenter(),

                Tables\Columns\TextColumn::make('name')
                    ->label('اسم اللهجة')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('code')
                    ->label('الكود')
                    ->badge(),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعّلة')
                    ->boolean(),

                Tables\Columns\TextColumn::make('sort_order')
                    ->label('الترتيب')
                    ->sortable(),
            ])
            ->defaultSort('sort_order')
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDialects::route('/'),
            'create' => Pages\CreateDialect::route('/create'),
            'edit' => Pages\EditDialect::route('/{record}/edit'),
        ];
    }
}

