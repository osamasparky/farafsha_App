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

    protected static ?string $navigationIcon = 'heroicon-o-paint-brush';
    protected static ?string $navigationGroup = 'الإعدادات والنظام';
    protected static ?string $modelLabel = 'إعداد';
    protected static ?string $pluralModelLabel = 'الهوية وأصول فرفوش';
    protected static ?int $navigationSort = 1;

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
                            ->required()
                            ->live(),

                        // حقل رفع صورة فرفوش المباشر (يظهر لمجموعة أصول وتعبيرات فرفوش)
                        Forms\Components\FileUpload::make('value')
                            ->label('رفع صورة شخصية فرفوش 🎭')
                            ->disk('public')
                            ->directory('mascot')
                            ->visibility('public')
                            ->image()
                            ->acceptedFileTypes(['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml'])
                            ->imageEditor()
                            ->openable()
                            ->downloadable()
                            ->maxSize(10240)
                            ->helperText('ارفع صورة كرتونية لفرفوش (يفضل PNG بخلفية شفافة). سيتم حفظها وتطبيقها تلقائياً على الموقع.')
                            ->afterStateHydrated(function ($component, $state) {
                                if (is_string($state) && str_contains($state, 'مطلوب من العميل')) {
                                    $component->state(null);
                                }
                            })
                            ->visible(fn (Forms\Get $get, ?SiteSetting $record) => 
                                $get('group') === 'mascot' || str_starts_with($record?->key ?? '', 'mascot_')
                            ),

                        // حقل القيمة النصية العادية لباقي الإعدادات
                        Forms\Components\Textarea::make('value')
                            ->label('القيمة (JSON أو نص مباشر)')
                            ->rows(6)
                            ->columnSpanFull()
                            ->visible(fn (Forms\Get $get, ?SiteSetting $record) => 
                                $get('group') !== 'mascot' && !str_starts_with($record?->key ?? '', 'mascot_')
                            ),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('mascot_preview')
                    ->label('صورة فرفوش')
                    ->disk('public')
                    ->getStateUsing(function (SiteSetting $record) {
                        if ($record->group !== 'mascot' || str_contains($record->value, 'مطلوب من العميل')) {
                            return null;
                        }
                        return $record->value;
                    })
                    ->circular(),

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
                Tables\Actions\Action::make('upload_mascot')
                    ->label('رفع صورة')
                    ->icon('heroicon-o-arrow-up-tray')
                    ->color('warning')
                    ->visible(fn (SiteSetting $record) => $record->group === 'mascot' || str_starts_with($record->key, 'mascot_'))
                    ->form([
                        Forms\Components\FileUpload::make('image')
                            ->label('اختر صورة شخصية فرفوش (PNG شفاف)')
                            ->disk('public')
                            ->directory('mascot')
                            ->visibility('public')
                            ->image()
                            ->acceptedFileTypes(['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml'])
                            ->imageEditor()
                            ->required(),
                    ])
                    ->action(function (SiteSetting $record, array $data) {
                        $record->update(['value' => $data['image']]);
                        \Filament\Notifications\Notification::make()
                            ->title('تم رفع وتحديث صورة فرفوش بنجاح 🎭')
                            ->success()
                            ->send();
                    }),
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

