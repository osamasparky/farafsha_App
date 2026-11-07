<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TestimonialResource\Pages;
use App\Models\Testimonial;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class TestimonialResource extends Resource
{
    protected static ?string $model = Testimonial::class;

    protected static ?string $navigationIcon = 'heroicon-o-heart';
    protected static ?string $navigationGroup = 'موقع فرفشة والمحتوى';
    protected static ?string $modelLabel = 'رأي لاعب';
    protected static ?string $pluralModelLabel = 'آراء وتقييمات اللاعبين';
    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('بيانات المراجعة الحقيقية')
                    ->description('تنبيه: لا تُضف إلا مراجعات حقيقية موثقة من المتاجر أو المستخدمين مباشرة')
                    ->schema([
                        Forms\Components\Grid::make(3)
                            ->schema([
                                Forms\Components\TextInput::make('author_name')
                                    ->label('اسم صاحب المراجعة')
                                    ->required()
                                    ->maxLength(100),

                                Forms\Components\Select::make('source')
                                    ->label('المصدر الموثق')
                                    ->options([
                                        'App Store' => 'Apple App Store',
                                        'Google Play' => 'Google Play Store',
                                        'Twitter / X' => 'منصة X (تويتر سابقاً)',
                                        'Direct' => 'استبيان مستخدمين مباشر',
                                    ])
                                    ->required(),

                                Forms\Components\Select::make('rating')
                                    ->label('التقييم بالنجوم')
                                    ->options([
                                        5 => '⭐⭐⭐⭐⭐ (5/5)',
                                        4 => '⭐⭐⭐⭐ (4/5)',
                                        3 => '⭐⭐⭐ (3/5)',
                                    ])
                                    ->default(5)
                                    ->required(),
                            ]),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('country_code')
                                    ->label('رمز الدولة (ISO)')
                                    ->default('EG')
                                    ->placeholder('EG, SA, AE, etc.')
                                    ->maxLength(5),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('ترتيب الظهور')
                                    ->numeric()
                                    ->default(0),
                            ]),

                        Forms\Components\Textarea::make('content.ar')
                            ->label('نص المراجعة (بالعربية)')
                            ->required()
                            ->rows(3)
                            ->columnSpanFull(),

                        Forms\Components\Textarea::make('content.en')
                            ->label('نص المراجعة (بالإنجليزية - اختياري)')
                            ->rows(3)
                            ->columnSpanFull(),

                        Forms\Components\FileUpload::make('avatar')
                            ->label('صورة أو صورة الحساب (Avatar)')
                            ->image()
                            ->disk('public')
                            ->directory('testimonials')
                            ->visibility('public')
                            ->fetchFileInformation(false),

                        Forms\Components\Toggle::make('is_approved')
                            ->label('مراجعة معتمدة ومفعلة للعرض بالموقع')
                            ->default(true),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('avatar')
                    ->label('الصورة')
                    ->circular(),

                Tables\Columns\TextColumn::make('author_name')
                    ->label('صاحب المراجعة')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('source')
                    ->label('المصدر')
                    ->badge()
                    ->color('info'),

                Tables\Columns\TextColumn::make('rating')
                    ->label('التقييم')
                    ->formatStateUsing(fn ($state) => str_repeat('⭐', $state)),

                Tables\Columns\TextColumn::make('country_code')
                    ->label('الدولة')
                    ->badge(),

                Tables\Columns\IconColumn::make('is_approved')
                    ->label('معتمدة')
                    ->boolean(),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('التاريخ')
                    ->date('d/m/Y'),
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
            'index' => Pages\ListTestimonials::route('/'),
            'create' => Pages\CreateTestimonial::route('/create'),
            'edit' => Pages\EditTestimonial::route('/{record}/edit'),
        ];
    }
}

