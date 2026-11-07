<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BannerResource\Pages;
use App\Models\Banner;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class BannerResource extends Resource
{
    protected static ?string $model = Banner::class;

    protected static ?string $navigationIcon = 'heroicon-o-megaphone';
    protected static ?string $navigationGroup = 'التواصل والتسويق';
    protected static ?string $modelLabel = 'بنر ترويجي';
    protected static ?string $pluralModelLabel = 'البنرات الترويجية';
    protected static ?int $navigationSort = 4;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('تفاصيل البنر الإعلاني')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('عنوان البنر (اختياري)')
                            ->placeholder('مثال: بطولة لمّة الأسبوعية')
                            ->maxLength(120),

                        Forms\Components\FileUpload::make('image')
                            ->label('صورة البنر')
                            ->disk('public')
                            ->directory('banners')
                            ->visibility('public')
                            ->image()
                            ->imageEditor()
                            ->openable()
                            ->downloadable()
                            ->maxSize(10240)
                            ->required(),

                        Forms\Components\TextInput::make('external_url')
                            ->label('رابط خارجي (اختياري - افتحه بالمتصفح عند النقر)')
                            ->placeholder('https://example.com أو اتركه فارغاً')
                            ->url()
                            ->maxLength(255),

                        Forms\Components\TextInput::make('video_url')
                            ->label('رابط فيديو ترويجي (اختياري - MP4 / رابط مباشر)')
                            ->placeholder('https://assets.example.com/promo.mp4 أو اتركه فارغاً')
                            ->url()
                            ->maxLength(255)
                            ->helperText('إذا أضفت رابط فيديو، سيتم تشغيله تلقائياً في ستارة العرض عند نقر البنر!'),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\Toggle::make('is_active')
                                    ->label('مفعّل ويظهر في التطبيق')
                                    ->default(true),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('ترتيب الظهور')
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
                Tables\Columns\ImageColumn::make('image')
                    ->label('الصورة')
                    ->circular(false)
                    ->height(55),

                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->default('بدون عنوان'),

                Tables\Columns\TextColumn::make('external_url')
                    ->label('الرابط الخارجي')
                    ->limit(35)
                    ->placeholder('لا يوجد رابط'),

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
            'index' => Pages\ListBanners::route('/'),
            'create' => Pages\CreateBanner::route('/create'),
            'edit' => Pages\EditBanner::route('/{record}/edit'),
        ];
    }
}

