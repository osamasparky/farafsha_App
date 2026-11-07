<?php

namespace App\Filament\Resources;

use App\Filament\Resources\GameResource\Pages;
use App\Models\Game;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class GameResource extends Resource
{
    protected static ?string $model = Game::class;

    protected static ?string $navigationIcon = 'heroicon-o-puzzle-piece';
    protected static ?string $navigationGroup = 'الألعاب والمحتوى';
    protected static ?string $modelLabel = 'لعبة';
    protected static ?string $pluralModelLabel = 'دليل الألعاب';
    protected static ?int $navigationSort = 1;

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::count();
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'primary';
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Tabs::make('تفاصيل اللعبة')
                    ->tabs([
                        Forms\Components\Tabs\Tab::make('المعلومات الأساسية')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                Forms\Components\Grid::make(2)
                                    ->schema([
                                        Forms\Components\TextInput::make('name')
                                            ->label('اسم اللعبة')
                                            ->placeholder('مثال: أمثال شعبية')
                                            ->required()
                                            ->maxLength(100),

                                        Forms\Components\TextInput::make('slug')
                                            ->label('المعرّف اللطيف (Slug)')
                                            ->placeholder('amthal-shaabiya')
                                            ->required()
                                            ->unique(ignoreRecord: true),

                                        Forms\Components\TextInput::make('subtitle')
                                            ->label('عنوان فرعي')
                                            ->placeholder('مثال: كمّل المثل الشعبي')
                                            ->maxLength(150),

                                        Forms\Components\Select::make('category')
                                            ->label('التصنيف')
                                            ->options([
                                                'أمثال' => 'أمثال شعبية',
                                                'إفيهات' => 'أفلام ومسلسلات',
                                                'تخمين' => 'تخمين وشخصيات',
                                                'ذكاء وسرعة' => 'ذكاء وسرعة',
                                                'معلومات عامة' => 'معلومات وثقافة',
                                                'تواصل وضحك' => 'تواصل وضحك',
                                            ])
                                            ->required(),

                                        Forms\Components\TextInput::make('badge_text')
                                            ->label('شارة مميزة (Badge)')
                                            ->placeholder('الأكثر طلباً / جديد'),

                                        Forms\Components\Select::make('template_type')
                                            ->label('نوع قالب اللعبة')
                                            ->options([
                                                'choice' => 'اختيار من متعدد (أمثال / إفيهات / ثقافة)',
                                                'who_am_i' => 'تخمين شخصيات (أسئلة نعم/لا)',
                                                'forbidden_words' => 'كلمات ممنوعة (Taboo)',
                                                'two_truths_one_lie' => 'حقيقتان وكذبة',
                                                'speed_trivia' => 'سؤال على السريع',
                                                'acting_drawing' => 'تمثيل ورسم صامت',
                                            ])
                                            ->default('choice')
                                            ->required(),

                                        Forms\Components\Select::make('game_mode')
                                            ->label('نمط اللعب المتاح')
                                            ->options([
                                                'local_only' => 'لعب محلي فقط (جهاز واحد)',
                                                'online_only' => 'أونلاين فقط (غرف متعددة الأجهزة)',
                                                'hybrid' => 'هجين (يدعم المحلي والأونلاين)',
                                            ])
                                            ->default('hybrid')
                                            ->required(),

                                        Forms\Components\TextInput::make('age_group')
                                            ->label('الفئة العمرية')
                                            ->default('جميع الأعمار')
                                            ->placeholder('مثال: جميع الأعمار، +12، +16'),
                                    ]),

                                Forms\Components\Grid::make(4)
                                    ->schema([
                                        Forms\Components\TextInput::make('min_players')
                                            ->label('الحد الأدنى للاعبين')
                                            ->numeric()
                                            ->default(2)
                                            ->required(),

                                        Forms\Components\TextInput::make('max_players')
                                            ->label('الحد الأقصى للاعبين')
                                            ->numeric()
                                            ->default(12)
                                            ->required(),

                                        Forms\Components\TextInput::make('default_rounds')
                                            ->label('عدد الجولات الافتراضي')
                                            ->numeric()
                                            ->default(10)
                                            ->required(),

                                        Forms\Components\TextInput::make('default_duration_seconds')
                                            ->label('مدة الدور (بالثواني)')
                                            ->numeric()
                                            ->default(20)
                                            ->required(),
                                    ]),

                                Forms\Components\Grid::make(3)
                                    ->schema([
                                        Forms\Components\Toggle::make('is_offline_capable')
                                            ->label('تعمل بدون إنترنت (Offline)')
                                            ->default(true),

                                        Forms\Components\Toggle::make('is_active')
                                            ->label('مفعلة وتظهر بالمنصة')
                                            ->default(true),

                                        Forms\Components\Toggle::make('is_featured')
                                            ->label('لعبة مميزة بالرئيسية')
                                            ->default(false),
                                    ]),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('ترتيب الظهور')
                                    ->numeric()
                                    ->default(0),

                                Forms\Components\Textarea::make('description')
                                    ->label('نبذة عن اللعبة (تظهر بالبطاقات وصفحة اللعبة)')
                                    ->rows(3)
                                    ->columnSpanFull(),

                                Forms\Components\Textarea::make('instructions')
                                    ->label('تعليمات وقواعد اللعب السريعة')
                                    ->rows(3)
                                    ->columnSpanFull(),
                            ]),

                        Forms\Components\Tabs\Tab::make('الهوية والصور')
                            ->icon('heroicon-o-photo')
                            ->schema([
                                Forms\Components\FileUpload::make('cover_image')
                                    ->label('صورة كارت اللعبة (Cover Image)')
                                    ->image()
                                    ->disk('public')
                                    ->directory('games')
                                    ->visibility('public')
                                    ->fetchFileInformation(false)
                                    ->columnSpanFull(),

                                Forms\Components\Select::make('icon')
                                    ->label('رمز الأيقونة (Material Icon)')
                                    ->options(Game::getAvailableIcons())
                                    ->searchable()
                                    ->preload()
                                    ->placeholder('اختر رمز الأيقونة المعتمد للعبة...')
                                    ->helperText('الرمز البرمجي للأيقونة المتوافق مع شاشات تطبيق الهاتف والويب'),

                                Forms\Components\TextInput::make('trailer_video_url')
                                    ->label('رابط فيديو توضيحي (YouTube / Vimeo / MP4)')
                                    ->url()
                                    ->placeholder('https://www.youtube.com/watch?v=...'),
                            ]),

                        Forms\Components\Tabs\Tab::make('خطوات اللعب وقواعد النقاط')
                            ->icon('heroicon-o-list-bullet')
                            ->schema([
                                Forms\Components\Repeater::make('how_to_play_steps')
                                    ->label('خطوات اللعب بالتفصيل (Step-by-Step)')
                                    ->schema([
                                        Forms\Components\TextInput::make('step_number')->label('رقم الخطوة')->numeric()->required(),
                                        Forms\Components\TextInput::make('title')->label('عنوان الخطوة')->required(),
                                        Forms\Components\Textarea::make('description')->label('شرح الخطوة')->required(),
                                    ])
                                    ->columns(3)
                                    ->collapsible()
                                    ->defaultItems(3),

                                Forms\Components\Repeater::make('scoring_guide')
                                    ->label('دليل احتساب النقاط (Scoring System)')
                                    ->schema([
                                        Forms\Components\TextInput::make('condition')->label('الحالة / الإنجاز')->required(),
                                        Forms\Components\TextInput::make('points')->label('النقاط (+/-)')->required(),
                                        Forms\Components\TextInput::make('note')->label('ملاحظة إضافية'),
                                    ])
                                    ->columns(3)
                                    ->collapsible()
                                    ->defaultItems(2),

                                Forms\Components\Section::make('مثال توضيحي لجولة حية')
                                    ->schema([
                                        Forms\Components\TextInput::make('example_round.prompt')->label('نص السؤال أو البداية'),
                                        Forms\Components\TagsInput::make('example_round.options')->label('الخيارات المتاحة'),
                                        Forms\Components\TextInput::make('example_round.correct')->label('الإجابة الصحيحة'),
                                        Forms\Components\TextInput::make('example_round.hint')->label('التلميح التوضيحي'),
                                    ]),
                            ]),

                        Forms\Components\Tabs\Tab::make('الأسئلة الشائعة')
                            ->icon('heroicon-o-question-mark-circle')
                            ->schema([
                                Forms\Components\Placeholder::make('faqs_notice')
                                    ->label('التحكم في قسم الأسئلة الشائعة')
                                    ->content('إذا كانت هذه القائمة فارغة، فلن يظهر قسم الأسئلة الشائعة نهائياً في صفحة اللعبة. يمكنك إضافة أي عدد من الأسئلة أو تعديلها أو حذفها بالكامل في أي وقت.')
                                    ->columnSpanFull(),

                                Forms\Components\Repeater::make('faqs')
                                    ->label('الأسئلة الشائعة الخاصة بهذه اللعبة')
                                    ->schema([
                                        Forms\Components\TextInput::make('question')
                                            ->label('السؤال')
                                            ->placeholder('مثال: هل تحتاج اللعبة إلى إنترنت؟')
                                            ->required(),
                                        Forms\Components\Textarea::make('answer')
                                            ->label('الإجابة')
                                            ->placeholder('اكتب إجابة السؤال...')
                                            ->rows(2)
                                            ->required(),
                                    ])
                                    ->itemLabel(fn (array $state): ?string => $state['question'] ?? 'سؤال جديد')
                                    ->collapsible()
                                    ->collapsed(false)
                                    ->addActionLabel('إضافة سؤال شائع جديد')
                                    ->reorderable()
                                    ->columnSpanFull(),
                            ]),

                        Forms\Components\Tabs\Tab::make('محركات البحث (SEO)')
                            ->icon('heroicon-o-magnifying-glass')
                            ->schema([
                                Forms\Components\TextInput::make('seo_title')
                                    ->label('عنوان الـ SEO (Meta Title)')
                                    ->maxLength(70),

                                Forms\Components\Textarea::make('seo_description')
                                    ->label('وصف الـ SEO (Meta Description)')
                                    ->maxLength(160),

                                Forms\Components\FileUpload::make('og_image')
                                    ->label('صورة المشاركة بشبكات التواصل (OG Image)')
                                    ->image()
                                    ->disk('public')
                                    ->directory('seo')
                                    ->visibility('public')
                                    ->fetchFileInformation(false),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('cover_image')
                    ->label('الصورة')
                    ->disk('public')
                    ->square(),

                Tables\Columns\TextColumn::make('name')
                    ->label('اسم اللعبة')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('category')
                    ->label('التصنيف')
                    ->badge()
                    ->color('primary'),

                Tables\Columns\TextColumn::make('min_players')
                    ->label('اللاعبين')
                    ->formatStateUsing(fn ($record) => "{$record->min_players} - {$record->max_players}"),

                Tables\Columns\IconColumn::make('is_offline_capable')
                    ->label('بدون نت')
                    ->boolean(),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعلة')
                    ->boolean(),

                Tables\Columns\IconColumn::make('is_featured')
                    ->label('مميزة')
                    ->boolean(),

                Tables\Columns\TextColumn::make('sort_order')
                    ->label('الترتيب')
                    ->sortable(),
            ])
            ->defaultSort('sort_order', 'asc')
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
            'index' => Pages\ListGames::route('/'),
            'create' => Pages\CreateGame::route('/create'),
            'edit' => Pages\EditGame::route('/{record}/edit'),
        ];
    }
}
