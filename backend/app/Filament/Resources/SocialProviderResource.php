<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SocialProviderResource\Pages;
use App\Models\SocialProvider;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SocialProviderResource extends Resource
{
    protected static ?string $model = SocialProvider::class;

    protected static ?string $navigationIcon = 'heroicon-o-finger-print';
    protected static ?string $navigationGroup = 'الإعدادات والنظام';
    protected static ?string $modelLabel = 'وسيلة تسجيل';
    protected static ?string $pluralModelLabel = 'طرق تسجيل الدخول';
    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('معلومات وسيلة تسجيل الدخول')
                    ->description('تحكم في ظهور أو إخفاء زر تسجيل الدخول في تطبيق الموبايل والموقع')
                    ->schema([
                        Forms\Components\Grid::make(3)
                            ->schema([
                                Forms\Components\TextInput::make('name')
                                    ->label('اسم الوسيلة')
                                    ->required()
                                    ->placeholder('مثال: تسجيل الدخول بحساب Google')
                                    ->maxLength(80),

                                Forms\Components\TextInput::make('provider')
                                    ->label('كود الوسيلة (Provider)')
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->placeholder('google / apple / facebook')
                                    ->maxLength(40),

                                Forms\Components\TextInput::make('icon')
                                    ->label('رمز الأيقونة')
                                    ->default('google')
                                    ->placeholder('google / apple / facebook'),
                            ]),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\Toggle::make('is_enabled')
                                    ->label('إظهار في التطبيق (مفعّلة)')
                                    ->helperText('عند إيقاف هذا الخيار، سيختفي زر تسجيل الدخول فوراً من التطبيق.')
                                    ->default(true),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('ترتيب العرض')
                                    ->numeric()
                                    ->default(0),
                            ]),
                    ]),

                Forms\Components\Section::make('بيانات الربط مع وسائل التواصل (API Credentials)')
                    ->description('أدخل هنا معرّفات العميل والمفاتيح الخاصة بكل منصة لربط التطبيق بها')
                    ->schema([
                        Forms\Components\TextInput::make('client_id')
                            ->label('معرف العميل (Client ID / App ID)')
                            ->placeholder('أدخل Google Client ID أو Apple Service ID أو Facebook App ID')
                            ->maxLength(255),

                        Forms\Components\TextInput::make('client_secret')
                            ->label('المفتاح السري (Client Secret / App Secret)')
                            ->password()
                            ->revealable()
                            ->maxLength(255),

                        Forms\Components\TextInput::make('redirect_url')
                            ->label('رابط إعادة التوجيه (Callback / Redirect URL)')
                            ->placeholder('https://farfasha.app/auth/callback')
                            ->maxLength(255),

                        Forms\Components\Textarea::make('notes')
                            ->label('ملاحظات وإرشادات الربط للمشرفين')
                            ->placeholder('أي تعليمات خاصة بالـ SHA-1 أو الـ Bundle ID أو الـ OAuth scopes...')
                            ->rows(3),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('الوسيلة')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('provider')
                    ->label('الكود')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'google' => 'danger',
                        'apple' => 'gray',
                        'facebook' => 'info',
                        default => 'primary',
                    }),

                Tables\Columns\ToggleColumn::make('is_enabled')
                    ->label('مفعّلة في التطبيق')
                    ->alignCenter(),

                Tables\Columns\TextColumn::make('client_id')
                    ->label('معرف العميل (Client ID)')
                    ->limit(25)
                    ->color('gray'),

                Tables\Columns\TextColumn::make('sort_order')
                    ->label('الترتيب')
                    ->sortable()
                    ->alignCenter(),

                Tables\Columns\TextColumn::make('updated_at')
                    ->label('آخر تحديث')
                    ->dateTime('d/m/Y H:i')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('sort_order')
            ->actions([
                Tables\Actions\EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSocialProviders::route('/'),
            'create' => Pages\CreateSocialProvider::route('/create'),
            'edit' => Pages\EditSocialProvider::route('/{record}/edit'),
        ];
    }
}

