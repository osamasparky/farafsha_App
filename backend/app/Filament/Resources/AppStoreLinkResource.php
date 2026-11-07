<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AppStoreLinkResource\Pages;
use App\Models\AppStoreLink;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class AppStoreLinkResource extends Resource
{
    protected static ?string $model = AppStoreLink::class;

    protected static ?string $navigationIcon = 'heroicon-o-arrow-down-tray';
    protected static ?string $navigationGroup = 'موقع فرفشة والمحتوى';
    protected static ?string $modelLabel = 'رابط متجر';
    protected static ?string $pluralModelLabel = 'روابط تحميل التطبيق';
    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('تفاصيل الرابط والمنصة الجغرافية')
                    ->schema([
                        Forms\Components\Grid::make(3)
                            ->schema([
                                Forms\Components\Select::make('platform')
                                    ->label('المنصة')
                                    ->options([
                                        'ios' => 'Apple App Store (iOS)',
                                        'android' => 'Google Play (Android)',
                                        'web' => 'إصدار الويب (Web App)',
                                    ])
                                    ->required(),

                                Forms\Components\TextInput::make('country_code')
                                    ->label('رمز الدولة (ISO) أو ALL للجميع')
                                    ->default('ALL')
                                    ->placeholder('EG, SA, AE, ALL')
                                    ->required()
                                    ->maxLength(5),

                                Forms\Components\Toggle::make('is_available')
                                    ->label('متاح في هذه الدولة')
                                    ->default(true),
                            ]),

                        Forms\Components\TextInput::make('store_url')
                            ->label('رابط المتجر أو الرابط المباشر')
                            ->url()
                            ->required()
                            ->placeholder('https://apps.apple.com/... أو https://play.google.com/...')
                            ->columnSpanFull(),

                        Forms\Components\TextInput::make('message')
                            ->label('رسالة مخصصة تظهر عند عدم التوفر (اختياري)')
                            ->placeholder('قريباً في متجرك! يمكنك التسجيل للتنبيه فور توفره.')
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\BadgeColumn::make('platform')
                    ->label('المنصة')
                    ->colors([
                        'primary' => 'ios',
                        'success' => 'android',
                        'warning' => 'web',
                    ]),

                Tables\Columns\TextColumn::make('country_code')
                    ->label('الدولة')
                    ->badge(),

                Tables\Columns\TextColumn::make('store_url')
                    ->label('الرابط')
                    ->limit(40),

                Tables\Columns\IconColumn::make('is_available')
                    ->label('متاح')
                    ->boolean(),

                Tables\Columns\TextColumn::make('updated_at')
                    ->label('آخر تحديث')
                    ->dateTime('d/m/Y H:i'),
            ])
            ->defaultSort('platform')
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAppStoreLinks::route('/'),
            'create' => Pages\CreateAppStoreLink::route('/create'),
            'edit' => Pages\EditAppStoreLink::route('/{record}/edit'),
        ];
    }
}

