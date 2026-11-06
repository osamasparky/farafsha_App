<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ContentItemResource\Pages;
use App\Models\ContentItem;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ContentItemResource extends Resource
{
    protected static ?string $model = ContentItem::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-duplicate';
    protected static ?string $navigationGroup = 'إدارة المحتوى والألعاب';
    protected static ?string $modelLabel = 'بطاقة / سؤال';
    protected static ?string $pluralModelLabel = 'بنك الأسئلة والبطاقات';
    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('ربط اللعبة والمحتوى')
                    ->schema([
                        Forms\Components\Select::make('game_id')
                            ->label('اللعبة التابعة لها')
                            ->relationship('game', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),

                        Forms\Components\Select::make('pack_id')
                            ->label('الحزمة التابعة لها')
                            ->relationship('pack', 'name')
                            ->searchable()
                            ->preload(),

                        Forms\Components\Select::make('type')
                            ->label('نوع المحتوى')
                            ->options([
                                'choice' => 'اختيار من متعدد',
                                'who_am_i' => 'شخصية / شيء للتخمين',
                                'forbidden_words' => 'كلمات ممنوعة',
                                'quote_completion' => 'إكمال شطر أو إفيه',
                            ])
                            ->default('choice')
                            ->required(),

                        Forms\Components\Select::make('difficulty')
                            ->label('مستوى الصعوبة')
                            ->options([
                                'easy' => 'سهل / شائع',
                                'medium' => 'متوسط',
                                'hard' => 'حريف / متقدم',
                            ])
                            ->default('medium')
                            ->required(),
                    ])->columns(2),

                Forms\Components\Section::make('نص البطاقة والإجابات')
                    ->schema([
                        Forms\Components\Textarea::make('prompt')
                            ->label('السؤال أو بداية الشطر / الكلمة')
                            ->placeholder('مثال: اللي اختشوا ... أو يا بابا .. أنا مش زعلان ...')
                            ->rows(3)
                            ->required()
                            ->columnSpanFull(),

                        Forms\Components\TextInput::make('answer')
                            ->label('الإجابة الصحيحة أو الهدف')
                            ->placeholder('مثال: ماتوا')
                            ->required()
                            ->columnSpanFull(),

                        Forms\Components\TagsInput::make('distractors')
                            ->label('الاختيارات المضللة (لأسئلة الاختيار من متعدد)')
                            ->placeholder('أدخل اختيار واضغط Enter')
                            ->columnSpanFull(),

                        Forms\Components\TagsInput::make('forbidden_words')
                            ->label('الكلمات الممنوعة (للعبة ممنوع تقول)')
                            ->placeholder('الكلمات المحظورة التي يُعاقب المتسابق بذكرها')
                            ->columnSpanFull(),

                        Forms\Components\TagsInput::make('hints')
                            ->label('تلميحات متدرجة (للعبة مين أنا أو خمن الأغنية)')
                            ->placeholder('تلميحات تساعد اللاعب عند التعثر')
                            ->columnSpanFull(),

                        Forms\Components\Textarea::make('explanation')
                            ->label('الشرح أو المرجع (اسم الفيلم / سنة الإنتاج / القصة)')
                            ->rows(2)
                            ->columnSpanFull(),
                    ]),

                Forms\Components\Section::make('التصنيف والاعتماد')
                    ->schema([
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

                        Forms\Components\Select::make('status')
                            ->label('حالة النشر')
                            ->options([
                                'draft' => 'مسودة',
                                'in_review' => 'قيد المراجعة',
                                'approved' => 'معتمد',
                                'published' => 'منشور في التطبيق',
                                'archived' => 'مؤرشف',
                            ])
                            ->default('published')
                            ->required(),

                        Forms\Components\Toggle::make('is_active')
                            ->label('نشطة في سحب الجولات')
                            ->default(true),

                        Forms\Components\Toggle::make('is_sensitive')
                            ->label('محتوى حساس / للكبار فقط')
                            ->default(false),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('game.name')
                    ->label('اللعبة')
                    ->badge()
                    ->sortable(),

                Tables\Columns\TextColumn::make('prompt')
                    ->label('السؤال / الشطر')
                    ->searchable()
                    ->limit(40),

                Tables\Columns\TextColumn::make('answer')
                    ->label('الإجابة الصحيحة')
                    ->searchable()
                    ->weight('bold')
                    ->color('success'),

                Tables\Columns\TextColumn::make('difficulty')
                    ->label('الصعوبة')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'easy' => 'success',
                        'medium' => 'warning',
                        'hard' => 'danger',
                        default => 'gray',
                    }),

                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'published' => 'success',
                        'approved' => 'primary',
                        'in_review' => 'warning',
                        default => 'gray',
                    }),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('نشطة')
                    ->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('game_id')
                    ->label('تصفية حسب اللعبة')
                    ->relationship('game', 'name'),
                Tables\Filters\SelectFilter::make('status')
                    ->label('تصفية حسب الحالة')
                    ->options([
                        'published' => 'منشور',
                        'draft' => 'مسودة',
                        'approved' => 'معتمد',
                    ]),
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
            'index' => Pages\ListContentItems::route('/'),
            'create' => Pages\CreateContentItem::route('/create'),
            'edit' => Pages\EditContentItem::route('/{record}/edit'),
        ];
    }
}
