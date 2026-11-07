<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SiteSettingResource\Pages;
use App\Models\SiteSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SiteSettingResource extends Resource
{
    protected static ?string $model = SiteSetting::class;

    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';
    protected static ?string $navigationGroup = 'موقع فرفشة والمحتوى';
    protected static ?string $modelLabel = 'إعداد للموقع';
    protected static ?string $pluralModelLabel = 'إعدادات وأصول فرفوش (Settings)';
    protected static ?int $navigationSort = 6;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('قيمة الإعداد')
                    ->schema([
                        Forms\Components\TextInput::make('key')
                            ->label('مفتاح الإعداد (Key)')
                            ->required()
                            ->disabled(fn ($record) => $record !== null),

                        Forms\Components\Select::make('group')
                            ->label('المجموعة')
                            ->options([
                                'general' => 'عام وهيدر وتذييل',
                                'mascot' => 'أصول وتعبيرات فرفوش',
                                'analytics' => 'التحليلات والإحصائيات (Plausible/Umami)',
                                'links' => 'المتاجر والروابط الذكية',
                                'social' => 'شبكات التواصل والدعم',
                            ])
                            ->required(),

                        Forms\Components\Textarea::make('value')
                            ->label('القيمة (JSON أو نص مباشر)')
                            ->rows(6)
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('key')
                    ->label('المفتاح')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\BadgeColumn::make('group')
                    ->label('المجموعة')
                    ->colors([
                        'primary' => 'general',
                        'warning' => 'mascot',
                        'info' => 'analytics',
                        'success' => 'links',
                        'gray' => 'social',
                    ]),

                Tables\Columns\TextColumn::make('value')
                    ->label('القيمة')
                    ->limit(60),

                Tables\Columns\TextColumn::make('updated_at')
                    ->label('آخر تعديل')
                    ->dateTime('d/m/Y H:i'),
            ])
            ->defaultSort('group')
            ->actions([
                Tables\Actions\EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSiteSettings::route('/'),
            'create' => Pages\CreateSiteSetting::route('/create'),
            'edit' => Pages\EditSiteSetting::route('/{record}/edit'),
        ];
    }
}

