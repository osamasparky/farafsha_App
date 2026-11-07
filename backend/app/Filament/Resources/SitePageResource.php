<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SitePageResource\Pages;
use App\Models\Game;
use App\Models\SitePage;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SitePageResource extends Resource
{
    protected static ?string $model = SitePage::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-duplicate';
    protected static ?string $navigationGroup = 'موقع فرفشة والمحتوى';
    protected static ?string $modelLabel = 'صفحة موقع';
    protected static ?string $pluralModelLabel = 'صفحات الموقع (Pages)';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Tabs::make('تفاصيل الصفحة')
                    ->tabs([
                        Forms\Components\Tabs\Tab::make('بيانات الصفحة والـ SEO')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                Forms\Components\Grid::make(2)
                                    ->schema([
                                        Forms\Components\TextInput::make('title.ar')
                                            ->label('عنوان الصفحة (بالعربية)')
                                            ->required()
                                            ->maxLength(150),

                                        Forms\Components\TextInput::make('title.en')
                                            ->label('عنوان الصفحة (بالإنجليزية)')
                                            ->maxLength(150),

                                        Forms\Components\TextInput::make('slug')
                                            ->label('الرابط اللطيف (Slug)')
                                            ->placeholder('home, about, faq, contact, etc.')
                                            ->required()
                                            ->unique(ignoreRecord: true),

                                        Forms\Components\Select::make('status')
                                            ->label('حالة النشر')
                                            ->options([
                                                'published' => 'منشور فوري (Published)',
                                                'draft' => 'مسودة (Draft)',
                                                'scheduled' => 'مجدول لتاريخ محدد (Scheduled)',
                                            ])
                                            ->default('published')
                                            ->required(),

                                        Forms\Components\DateTimePicker::make('published_at')
                                            ->label('تاريخ ووقت النشر')
                                            ->default(now()),

                                        Forms\Components\TextInput::make('seo_title')
                                            ->label('عنوان الـ SEO (Meta Title)'),

                                        Forms\Components\Textarea::make('seo_description')
                                            ->label('وصف الـ SEO (Meta Description)')
                                            ->columnSpanFull(),

                                        Forms\Components\FileUpload::make('og_image')
                                            ->label('صورة المشاركة بشبكات التواصل (OG Image)')
                                            ->image()
                                            ->disk('public')
                                            ->directory('pages-og')
                                            ->visibility('public')
                                            ->fetchFileInformation(false)
                                            ->columnSpanFull(),
                                    ]),
                            ]),

                        Forms\Components\Tabs\Tab::make('محرر المكوّنات (Blocks Builder)')
                            ->icon('heroicon-o-squares-plus')
                            ->schema([
                                Forms\Components\Builder::make('blocks')
                                    ->label('مكوّنات وأقسام الصفحة')
                                    ->blocks([
                                        // 1. Hero Block
                                        Forms\Components\Builder\Block::make('hero')
                                            ->label('قسم البطل والترحيب (Hero Section)')
                                            ->icon('heroicon-o-sparkles')
                                            ->schema([
                                                Forms\Components\TextInput::make('headline')->label('العنوان الرئيسي')->required(),
                                                Forms\Components\Textarea::make('subheadline')->label('النص الفرعي')->required(),
                                                Forms\Components\TextInput::make('badge_text')->label('شارة أعلى العنوان')->default('المنصة العربية الأولى للألعاب الجماعية'),
                                                Forms\Components\TextInput::make('primary_cta_text')->label('نص زر التحميل الرئيسي')->default('حمّل التطبيق الآن'),
                                                Forms\Components\TextInput::make('primary_cta_link')->label('رابط زر التحميل')->default('/download'),
                                                Forms\Components\TextInput::make('secondary_cta_text')->label('نص الزر الثانوي')->default('اكتشف الألعاب'),
                                                Forms\Components\TextInput::make('secondary_cta_link')->label('رابط الزر الثانوي')->default('/games'),
                                                Forms\Components\TextInput::make('mascot_speech')->label('فقاعة كلام فرفوش')->default('منوّر يا فرفوش! جاهز للضحك؟'),
                                            ]),

                                        // 2. Value Props (3 points)
                                        Forms\Components\Builder\Block::make('value_props')
                                            ->label('فكرة فرفشة في 3 نقاط (Value Props)')
                                            ->icon('heroicon-o-star')
                                            ->schema([
                                                Forms\Components\TextInput::make('section_title')->label('عنوان القسم')->default('ليه تختار فرفشة في قعدتك؟'),
                                                Forms\Components\Repeater::make('items')
                                                    ->label('النقاط الثلاث')
                                                    ->schema([
                                                        Forms\Components\TextInput::make('title')->label('العنوان')->required(),
                                                        Forms\Components\Textarea::make('description')->label('الوصف')->required(),
                                                        Forms\Components\TextInput::make('icon')->label('رمز الأيقونة')->default('device_phone'),
                                                    ])
                                                    ->maxItems(3)
                                                    ->columns(3),
                                            ]),

                                        // 3. Featured Games
                                        Forms\Components\Builder\Block::make('featured_games')
                                            ->label('شبكة الألعاب المميزة (Featured Games)')
                                            ->icon('heroicon-o-puzzle-piece')
                                            ->schema([
                                                Forms\Components\TextInput::make('section_title')->label('عنوان القسم')->default('ألعاب تخلي القعدة ولعة!'),
                                                Forms\Components\TextInput::make('section_subtitle')->label('سطر فرعي')->default('منوعات تناسب كل الأعمار والأذواق بدون إنترنت أو أونلاين'),
                                                Forms\Components\Select::make('games')
                                                    ->label('اختر ألعاب محددة (اتركه فارغاً لعرض كل الألعاب المميزة)')
                                                    ->options(fn () => Game::pluck('name', 'id')->toArray())
                                                    ->multiple(),
                                            ]),

                                        // 4. How It Works
                                        Forms\Components\Builder\Block::make('how_it_works')
                                            ->label('خطوات اللعب البسيطة (How It Works)')
                                            ->icon('heroicon-o-numbered-list')
                                            ->schema([
                                                Forms\Components\TextInput::make('section_title')->label('عنوان القسم')->default('طريقة اللعب أسهل مما تتخيل'),
                                                Forms\Components\Repeater::make('steps')
                                                    ->label('الخطوات')
                                                    ->schema([
                                                        Forms\Components\TextInput::make('step_number')->label('الرقم')->numeric()->required(),
                                                        Forms\Components\TextInput::make('title')->label('العنوان')->required(),
                                                        Forms\Components\Textarea::make('description')->label('الوصف')->required(),
                                                    ])
                                                    ->columns(3),
                                            ]),

                                        // 5. Features
                                        Forms\Components\Builder\Block::make('features')
                                            ->label('مميزات المنصة (Platform Features)')
                                            ->icon('heroicon-o-check-badge')
                                            ->schema([
                                                Forms\Components\TextInput::make('section_title')->label('عنوان القسم')->default('مصممة خصيصاً للماتنا العربية'),
                                                Forms\Components\Repeater::make('features_list')
                                                    ->label('المميزات')
                                                    ->schema([
                                                        Forms\Components\TextInput::make('title')->label('الميزة')->required(),
                                                        Forms\Components\Textarea::make('description')->label('الشرح')->required(),
                                                        Forms\Components\TextInput::make('badge')->label('شارة إضافية'),
                                                    ])
                                                    ->columns(3),
                                            ]),

                                        // 6. Interactive Amthal Teaser
                                        Forms\Components\Builder\Block::make('interactive_amthal')
                                            ->label('مربع تجربة مثل شعبي تفاعلي (Amthal Mini Demo)')
                                            ->icon('heroicon-o-play-circle')
                                            ->schema([
                                                Forms\Components\TextInput::make('section_title')->label('عنوان القسم')->default('جرّب حظك في مثل شعبي سريع!'),
                                                Forms\Components\TextInput::make('cta_button_text')->label('نص زر المزيد من التحديات')->default('العب المزيد في صفحة الأمثال'),
                                                Forms\Components\TextInput::make('cta_link')->label('الرابط')->default('/games/amthal'),
                                            ]),

                                        // 7. Testimonials
                                        Forms\Components\Builder\Block::make('testimonials')
                                            ->label('آراء المستخدمين الحقيقية (Testimonials)')
                                            ->icon('heroicon-o-chat-bubble-bottom-center-text')
                                            ->schema([
                                                Forms\Components\TextInput::make('section_title')->label('عنوان القسم')->default('قالوا إيه عن فرفشة؟'),
                                                Forms\Components\TextInput::make('section_subtitle')->label('سطر فرعي')->default('مراجعات حقيقية من متجر التطبيقات والمستخدمين'),
                                                Forms\Components\Toggle::make('hide_if_empty')
                                                    ->label('إخفاء تلقائي إذا لم تتوفر مراجعات معتمدة')
                                                    ->default(true),
                                            ]),

                                        // 8. FAQ
                                        Forms\Components\Builder\Block::make('faq')
                                            ->label('الأسئلة الشائعة (FAQ Accordion)')
                                            ->icon('heroicon-o-question-mark-circle')
                                            ->schema([
                                                Forms\Components\TextInput::make('section_title')->label('عنوان القسم')->default('أسئلة متكررة وإجابات سريعة'),
                                                Forms\Components\Repeater::make('faqs_list')
                                                    ->label('الأسئلة والأجوبة')
                                                    ->schema([
                                                        Forms\Components\TextInput::make('question')->label('السؤال')->required(),
                                                        Forms\Components\Textarea::make('answer')->label('الإجابة')->required(),
                                                    ]),
                                            ]),

                                        // 9. Download CTA
                                        Forms\Components\Builder\Block::make('download_cta')
                                            ->label('قسم دعوة التحميل الختامي (Download Banner)')
                                            ->icon('heroicon-o-arrow-down-tray')
                                            ->schema([
                                                Forms\Components\TextInput::make('headline')->label('العنوان')->default('جاهز تبدأ اللمّة والضحك؟'),
                                                Forms\Components\Textarea::make('subheadline')->label('الوصف')->default('حمّل تطبيق فرفشة مجاناً وخلّي القعدة ماتتنسيش!'),
                                                Forms\Components\Toggle::make('show_qr')->label('إظهار كود QR لأجهزة الديسكتوب')->default(true),
                                            ]),

                                        // 10. Rich Text & Media
                                        Forms\Components\Builder\Block::make('rich_text')
                                            ->label('نص منسق ووسائط (Rich Content)')
                                            ->icon('heroicon-o-document-text')
                                            ->schema([
                                                Forms\Components\RichEditor::make('body')->label('المحتوى')->required(),
                                            ]),
                                    ])
                                    ->collapsible()
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('title')
                    ->label('عنوان الصفحة')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('slug')
                    ->label('الرابط اللطيف')
                    ->badge()
                    ->color('primary')
                    ->searchable(),

                Tables\Columns\BadgeColumn::make('status')
                    ->label('الحالة')
                    ->colors([
                        'success' => 'published',
                        'warning' => 'draft',
                        'info' => 'scheduled',
                    ])
                    ->formatStateUsing(fn ($state) => match ($state) {
                        'published' => 'منشور',
                        'draft' => 'مسودة',
                        'scheduled' => 'مجدول',
                        default => $state,
                    }),

                Tables\Columns\TextColumn::make('published_at')
                    ->label('تاريخ النشر')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->defaultSort('published_at', 'desc')
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

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSitePages::route('/'),
            'create' => Pages\CreateSitePage::route('/create'),
            'edit' => Pages\EditSitePage::route('/{record}/edit'),
        ];
    }
}

