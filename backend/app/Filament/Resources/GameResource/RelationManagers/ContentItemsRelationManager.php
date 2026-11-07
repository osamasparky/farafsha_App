<?php

namespace App\Filament\Resources\GameResource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class ContentItemsRelationManager extends RelationManager
{
    protected static string $relationship = 'contentItems';
    protected static ?string $title = 'بنك أسئلة وبطاقات اللعبة';
    protected static ?string $modelLabel = 'سؤال / بطاقة';
    protected static ?string $pluralModelLabel = 'أسئلة وبطاقات هذه اللعبة';
    protected static ?string $icon = 'heroicon-o-queue-list';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Grid::make(2)
                    ->schema([
                        Forms\Components\TextInput::make('prompt')
                            ->label('نص السؤال أو الشطر أو التلميح')
                            ->placeholder('مثال: اللي اختشوا...')
                            ->required()
                            ->maxLength(255),

                        Forms\Components\TextInput::make('answer')
                            ->label('الإجابة الصحيحة المعتمدة')
                            ->placeholder('مثال: ماتوا')
                            ->required()
                            ->maxLength(255),
                    ]),

                Forms\Components\TagsInput::make('distractors')
                    ->label('الخيارات الخاطئة (Distractors)')
                    ->placeholder('اكتب خياراً ثم اضغط Enter')
                    ->helperText('تظهر للمستخدم كخيارات مضللة في ألعاب الاختيار من متعدد'),

                Forms\Components\TagsInput::make('hints')
                    ->label('التلميحات المساعدة')
                    ->placeholder('أضف تلميحاً واضغط Enter'),

                Forms\Components\Grid::make(3)
                    ->schema([
                        Forms\Components\Select::make('difficulty')
                            ->label('مستوى الصعوبة')
                            ->options([
                                'easy' => 'سهل',
                                'medium' => 'متوسط',
                                'hard' => 'حريف وصعب',
                            ])
                            ->default('medium')
                            ->required(),

                        Forms\Components\Select::make('status')
                            ->label('حالة النشر')
                            ->options([
                                'published' => 'منشور',
                                'draft' => 'مسودة',
                                'approved' => 'معتمد',
                            ])
                            ->default('published')
                            ->required(),

                        Forms\Components\Toggle::make('is_active')
                            ->label('سؤال مفعّل ويظهر في اللعبة')
                            ->default(true),
                    ]),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('prompt')
            ->columns([
                Tables\Columns\TextColumn::make('prompt')
                    ->label('السؤال / الشطر')
                    ->searchable()
                    ->weight('bold')
                    ->limit(50),

                Tables\Columns\TextColumn::make('answer')
                    ->label('الإجابة الصحيحة')
                    ->color('success')
                    ->weight('bold')
                    ->searchable(),

                Tables\Columns\TextColumn::make('difficulty')
                    ->label('الصعوبة')
                    ->badge()
                    ->colors([
                        'success' => 'easy',
                        'warning' => 'medium',
                        'danger' => 'hard',
                    ])
                    ->formatStateUsing(fn ($state) => match ($state) {
                        'easy' => 'سهل 🌱',
                        'medium' => 'متوسط ⚖️',
                        'hard' => 'حريف 🔥',
                        default => $state ?? 'عادي',
                    }),

                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'published' => 'success',
                        'approved' => 'primary',
                        'draft' => 'gray',
                        default => 'warning',
                    })
                    ->formatStateUsing(fn ($state) => match ($state) {
                        'published' => 'منشور ✅',
                        'approved' => 'معتمد 🌟',
                        'draft' => 'مسودة 📝',
                        default => $state,
                    }),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعّل')
                    ->boolean(),
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make()
                    ->label('إضافة سؤال جديد للعبة ➕'),
            ])
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
}
