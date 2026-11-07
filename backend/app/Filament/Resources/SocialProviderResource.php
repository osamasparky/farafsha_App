<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SocialProviderResource\Pages;
use App\Models\SocialProvider;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Get;
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
                    ->description('تحكم في ظهور أو إخفاء زر تسجيل الدخول في تطبيق الموبايل والموقع والترتيب')
                    ->schema([
                        Forms\Components\Grid::make(3)
                            ->schema([
                                Forms\Components\Select::make('provider')
                                    ->label('المنصة (Provider)')
                                    ->options([
                                        'google' => 'Google (حسابات جوجل)',
                                        'apple' => 'Apple (تسجيل الدخول بآبل)',
                                        'facebook' => 'Facebook (ميتا)',
                                        'twitter' => 'X (تويتر سابقاً - OAuth 2.0 PKCE)',
                                        'linkedin' => 'LinkedIn (لينكد إن - OpenID Connect)',
                                    ])
                                    ->required()
                                    ->live()
                                    ->unique(ignoreRecord: true)
                                    ->afterStateUpdated(function ($state, Forms\Set $set) {
                                        match ($state) {
                                            'google' => [
                                                $set('name', 'تسجيل الدخول بحساب Google'),
                                                $set('scopes', 'email,profile,openid'),
                                                $set('redirect_url', 'https://farfasha.app/api/v1/auth/social/google/callback'),
                                            ],
                                            'apple' => [
                                                $set('name', 'تسجيل الدخول بحساب Apple'),
                                                $set('scopes', 'name,email'),
                                                $set('redirect_url', 'https://farfasha.app/api/v1/auth/social/apple/callback'),
                                            ],
                                            'facebook' => [
                                                $set('name', 'تسجيل الدخول بحساب Facebook'),
                                                $set('scopes', 'public_profile,email'),
                                                $set('redirect_url', 'https://farfasha.app/api/v1/auth/social/facebook/callback'),
                                            ],
                                            'twitter' => [
                                                $set('name', 'تسجيل الدخول بحساب X (Twitter)'),
                                                $set('scopes', 'tweet.read,users.read,offline.access'),
                                                $set('redirect_url', 'farfasha://oauth-callback'),
                                            ],
                                            'linkedin' => [
                                                $set('name', 'تسجيل الدخول بحساب LinkedIn'),
                                                $set('scopes', 'openid,profile,email'),
                                                $set('redirect_url', 'farfasha://oauth-callback'),
                                            ],
                                            default => null,
                                        };
                                        $set('icon', $state);
                                    }),

                                Forms\Components\TextInput::make('name')
                                    ->label('اسم الوسيلة الظاهر للمستخدم')
                                    ->required()
                                    ->placeholder('مثال: تسجيل الدخول بحساب Google')
                                    ->maxLength(80),

                                Forms\Components\TextInput::make('icon')
                                    ->label('رمز الأيقونة')
                                    ->default('google')
                                    ->placeholder('google / apple / facebook / twitter / linkedin'),
                            ]),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\Toggle::make('is_enabled')
                                    ->label('إظهار في التطبيق (مفعّلة)')
                                    ->helperText('عند إيقاف هذا الخيار، سيختفي زر تسجيل الدخول فوراً وبشكل ديناميكي من تطبيق الموبايل والموقع.')
                                    ->default(true),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('ترتيب العرض (1 للأول، 2 للثاني...)')
                                    ->numeric()
                                    ->default(0),
                            ]),
                    ]),

                Forms\Components\Section::make('بيانات الربط مع المنصة (API Credentials)')
                    ->description('أدخل هنا المفاتيح والمعرفات المطلوبة لتفعيل المصادقة مع المنصة بنجاح')
                    ->schema([
                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('client_id')
                                    ->label(fn (Get $get) => match ($get('provider')) {
                                        'google' => 'معرف عميل الويب (Google Web Client ID)',
                                        'apple' => 'معرف خدمة آبل (Apple Services ID / Client ID)',
                                        'facebook' => 'معرف تطبيق فيسبوك (Facebook App ID)',
                                        'twitter' => 'معرف عميل إكس (X OAuth 2.0 Client ID)',
                                        'linkedin' => 'معرف عميل لينكد إن (LinkedIn Client ID)',
                                        default => 'معرف العميل (Client ID / App ID)',
                                    })
                                    ->required()
                                    ->placeholder('أدخل Client ID أو App ID')
                                    ->maxLength(255),

                                Forms\Components\TextInput::make('client_secret')
                                    ->label(fn (Get $get) => match ($get('provider')) {
                                        'google' => 'المفتاح السري (Google Client Secret)',
                                        'apple' => 'المفتاح السري لآبل (Apple Secret Key / Private Key)',
                                        'facebook' => 'المفتاح السري للتطبيق (Facebook App Secret)',
                                        'twitter' => 'المفتاح السري (X OAuth 2.0 Client Secret)',
                                        'linkedin' => 'المفتاح السري (LinkedIn Client Secret)',
                                        default => 'المفتاح السري (Client Secret)',
                                    })
                                    ->password()
                                    ->revealable()
                                    ->maxLength(1000)
                                    ->helperText('يُحفظ بأمان على السيرفر ولا يُكشف لتطبيق الموبايل.'),
                            ]),

                        // حقول خاصة بـ Apple
                        Forms\Components\Grid::make(2)
                            ->visible(fn (Get $get) => $get('provider') === 'apple')
                            ->schema([
                                Forms\Components\TextInput::make('team_id')
                                    ->label('Apple Team ID')
                                    ->helperText('كود الفريق المكون من 10 أحرف وأرقام من صفحة عضوية Apple Developer.')
                                    ->placeholder('مثال: DEF1234567'),

                                Forms\Components\TextInput::make('key_id')
                                    ->label('Apple Key ID')
                                    ->helperText('معرف المفتاح المخصص لـ Sign in with Apple من قسم Certificates & Keys.')
                                    ->placeholder('مثال: ABC1234567'),
                            ]),

                        // حقل خاص بـ Facebook
                        Forms\Components\Grid::make(1)
                            ->visible(fn (Get $get) => $get('provider') === 'facebook')
                            ->schema([
                                Forms\Components\TextInput::make('client_token')
                                    ->label('Facebook Client Token (رمز عميل فيسبوك)')
                                    ->helperText('مطلوب لتشغيل Facebook SDK على الموبايل. تجده في Meta Developer Portal > App Settings > Advanced > Client Token.')
                                    ->placeholder('أدخل Client Token الخاص بفيسبوك'),
                            ]),

                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('redirect_url')
                                    ->label('رابط إعادة التوجيه (Callback / Redirect URL)')
                                    ->helperText('الرابط المعتمد لاستلام استجابة المنصة بعد تسجيل الدخول.')
                                    ->placeholder('مثال: farfasha://oauth-callback أو https://farfasha.app/api/v1/auth/social/google/callback')
                                    ->maxLength(255),

                                Forms\Components\TextInput::make('scopes')
                                    ->label('نطاقات الصلاحيات (Scopes)')
                                    ->helperText('الصلاحيات المطلوبة من المستخدم مفصولة بفواصل.')
                                    ->placeholder('مثال: email,profile,openid')
                                    ->maxLength(255),
                            ]),

                        Forms\Components\KeyValue::make('extra_config')
                            ->label('إعدادات مخصصة إضافية (Custom Configuration)')
                            ->keyLabel('المفتاح (Key)')
                            ->valueLabel('القيمة (Value)')
                            ->helperText('يمكنك إضافة أي مفاتيح إضافية خاصة بالمطور (مثل: android_client_id, ios_client_id, bundle_id).'),

                        Forms\Components\Textarea::make('notes')
                            ->label('ملاحظات وإرشادات الربط للمشرفين')
                            ->placeholder('أي تعليمات خاصة بالـ SHA-1 أو الـ Bundle ID أو الشهادات...')
                            ->rows(3),
                    ]),

                Forms\Components\Section::make('دليل وإرشادات المطور لإعداد المنصة')
                    ->description('بيانات أساسية يلزم إضافتها داخل لوحة تحكم كل منصة')
                    ->collapsible()
                    ->schema([
                        Forms\Components\Placeholder::make('developer_guide')
                            ->label('بيانات تطبيق فرفشة الرسمية:')
                            ->content(fn (Get $get) => match ($get('provider')) {
                                'google' => new \Illuminate\Support\HtmlString('
                                    <div class="space-y-2 text-sm leading-6">
                                        <p><strong>1. لوحة تحكم مطوري جوجل:</strong> <a href="https://console.cloud.google.com/apis/credentials" target="_blank" class="text-primary-500 underline">Google Cloud Console</a></p>
                                        <p><strong>2. اسم الحزمة (Package Name):</strong> <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">com.farfasha.app</code></p>
                                        <p><strong>3. معرف الـ iOS Bundle ID:</strong> <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">com.farfasha.app</code></p>
                                        <p><strong>4. شهادة SHA-1:</strong> استخرجها عبر أمر <code>keytool</code> في الأندرويد وأضفها في عميل Android OAuth Client.</p>
                                        <p><strong>5. Web Client ID:</strong> انسخ الـ Client ID الخاص بالويب وضعه في حقل <strong>معرف عميل الويب</strong> أعلاه.</p>
                                    </div>
                                '),
                                'apple' => new \Illuminate\Support\HtmlString('
                                    <div class="space-y-2 text-sm leading-6">
                                        <p><strong>1. لوحة تحكم مطوري آبل:</strong> <a href="https://developer.apple.com/account/resources" target="_blank" class="text-primary-500 underline">Apple Developer Portal</a></p>
                                        <p><strong>2. Primary App ID:</strong> <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">com.farfasha.app</code> (مع تفعيل Sign in with Apple)</p>
                                        <p><strong>3. Services ID:</strong> أنشئ Service ID جديد مثل <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">com.farfasha.app.service</code> وضعه في حقل معرف الخدمة أعلاه.</p>
                                        <p><strong>4. Return URLs المعتمدة:</strong> أضف الرابط: <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">https://farfasha.app/api/v1/auth/social/apple/callback</code></p>
                                        <p><strong>5. Key (.p8):</strong> أنشئ مفتاحاً جديداً لـ Sign in with Apple واحصل على Key ID وحمّل ملف المفتاح الخاص.</p>
                                    </div>
                                '),
                                'facebook' => new \Illuminate\Support\HtmlString('
                                    <div class="space-y-2 text-sm leading-6">
                                        <p><strong>1. لوحة تحكم مطوري فيسبوك:</strong> <a href="https://developers.facebook.com/apps" target="_blank" class="text-primary-500 underline">Meta for Developers</a></p>
                                        <p><strong>2. تفعيل منتج:</strong> أضف منتج <strong>Facebook Login</strong> للتطبيق.</p>
                                        <p><strong>3. إعدادات Android:</strong> Package Name: <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">com.farfasha.app</code> مع إضافة الـ Key Hashes.</p>
                                        <p><strong>4. إعدادات iOS:</strong> Bundle ID: <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">com.farfasha.app</code>.</p>
                                        <p><strong>5. Client Token:</strong> انسخ الـ Client Token من App Settings > Advanced وضعه في الحقل المخصص أعلاه.</p>
                                    </div>
                                '),
                                'twitter' => new \Illuminate\Support\HtmlString('
                                    <div class="space-y-2 text-sm leading-6">
                                        <p><strong>1. لوحة تحكم مطوري إكس (تويتر):</strong> <a href="https://developer.x.com" target="_blank" class="text-primary-500 underline">X Developer Portal</a></p>
                                        <p><strong>2. نوع التطبيق:</strong> اختر <strong>Confidential Client</strong> أو <strong>Native App</strong> مع تفعيل <strong>OAuth 2.0</strong>.</p>
                                        <p><strong>3. تفعيل PKCE:</strong> التطبيق يستخدم تلقائياً معيار <code>PKCE</code> (Code Challenge S256).</p>
                                        <p><strong>4. Callback URLs:</strong> أضف في لوحة تويتر: <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">farfasha://oauth-callback</code> وأيضاً <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">https://farfasha.app/api/v1/auth/social/twitter/callback</code></p>
                                    </div>
                                '),
                                'linkedin' => new \Illuminate\Support\HtmlString('
                                    <div class="space-y-2 text-sm leading-6">
                                        <p><strong>1. لوحة تحكم مطوري لينكد إن:</strong> <a href="https://www.linkedin.com/developers/apps" target="_blank" class="text-primary-500 underline">LinkedIn Developer Portal</a></p>
                                        <p><strong>2. تفعيل المنتج:</strong> أضف منتج <strong>Sign In with LinkedIn using OpenID Connect</strong> في تبويب Products.</p>
                                        <p><strong>3. Authorized Redirect URLs:</strong> أضف: <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">farfasha://oauth-callback</code> وأيضاً <code class="bg-gray-800 text-yellow-400 px-2 py-0.5 rounded">https://farfasha.app/api/v1/auth/social/linkedin/callback</code></p>
                                        <p><strong>4. النطاقات المعتمدة (Scopes):</strong> تأكد من تفعيل <code>openid</code> و <code>profile</code> و <code>email</code>.</p>
                                    </div>
                                '),
                                default => new \Illuminate\Support\HtmlString('<p class="text-gray-400">اختر منصة من الأعلى لعرض إرشادات الربط المخصصة لها.</p>'),
                            }),
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
                        'twitter' => 'warning',
                        'linkedin' => 'primary',
                        default => 'secondary',
                    }),

                Tables\Columns\ToggleColumn::make('is_enabled')
                    ->label('مفعّلة في التطبيق')
                    ->alignCenter(),

                Tables\Columns\TextColumn::make('status')
                    ->label('حالة الإعداد')
                    ->state(function (SocialProvider $record): string {
                        $id = $record->client_id;
                        if (empty($id) || str_contains((string) $id, 'CLIENT_ID') || str_contains((string) $id, 'generic')) {
                            return 'بحاجة لإدخال المفاتيح ⚠️';
                        }
                        return 'مضبوط وجاهز للربط ✅';
                    })
                    ->badge()
                    ->color(fn (string $state): string => str_contains($state, 'جاهز') ? 'success' : 'warning'),

                Tables\Columns\TextColumn::make('client_id')
                    ->label('معرف العميل (Client ID)')
                    ->limit(35)
                    ->color('gray'),

                Tables\Columns\TextColumn::make('redirect_url')
                    ->label('رابط التوجيه')
                    ->limit(30)
                    ->color('gray')
                    ->toggleable(),

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
            ->reorderable('sort_order')
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
