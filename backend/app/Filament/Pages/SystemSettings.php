<?php

namespace App\Filament\Pages;

use App\Models\SiteSetting;
use App\Models\WahaSession;
use App\Services\WahaClient;
use App\Services\WahaMessageService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Mail;

class SystemSettings extends Page implements Forms\Contracts\HasForms
{
    use Forms\Concerns\InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-cog-8-tooth';
    protected static ?string $navigationGroup = 'الإعدادات والنظام';
    protected static ?string $navigationLabel = 'إعدادات البريد والواتساب والـ OTP';
    protected static ?string $title = 'إعدادات البريد الإلكتروني (SMTP) والواتساب ورموز التحقق (OTP)';
    protected static ?int $navigationSort = 1;

    protected static string $view = 'filament.pages.system-settings';

    public ?array $data = [];

    public function mount(): void
    {
        $mailSettings = SiteSetting::get('mail_settings', []);
        $otpSettings = SiteSetting::get('otp_settings', []);

        $activeWahaSession = SiteSetting::get('whatsapp_otp_session')
            ?: WahaSession::where('status', 'WORKING')->value('name')
            ?: 'UAE';

        $this->form->fill([
            // إعدادات الواتساب والـ OTP
            'whatsapp_otp_session' => $activeWahaSession,
            'whatsapp_otp_enabled' => $otpSettings['whatsapp_enabled'] ?? true,
            'email_otp_enabled' => $otpSettings['email_enabled'] ?? true,
            'otp_expiry_minutes' => $otpSettings['expiry_minutes'] ?? 5,
            'otp_template' => $otpSettings['template'] ?? "مرحباً بك في منصة وتطبيق فرفشة! 🎮🥳\nرمز التحقق الخاص بك هو: *{otp}*\nصالح لمدة {minutes} دقائق. لا تشارك هذا الرمز مع أحد.",

            // إعدادات البريد الإلكتروني (SMTP)
            'mail_mailer' => $mailSettings['mailer'] ?? config('mail.default', 'smtp'),
            'mail_host' => $mailSettings['host'] ?? env('MAIL_HOST', 'smtp.gmail.com'),
            'mail_port' => $mailSettings['port'] ?? env('MAIL_PORT', 587),
            'mail_encryption' => $mailSettings['encryption'] ?? env('MAIL_ENCRYPTION', 'tls'),
            'mail_username' => $mailSettings['username'] ?? env('MAIL_USERNAME', ''),
            'mail_password' => $mailSettings['password'] ?? env('MAIL_PASSWORD', ''),
            'mail_from_address' => $mailSettings['from_address'] ?? env('MAIL_FROM_ADDRESS', 'noreply@farfasha.app'),
            'mail_from_name' => $mailSettings['from_name'] ?? env('MAIL_FROM_NAME', 'منصة وتطبيق فرفشة'),

            // حقول الفحص التجريبي
            'test_phone' => '01008158177',
            'test_email' => 'osamasabry@msn.com',
        ]);
    }

    public function form(Form $form): Form
    {
        // تجهيز قائمة خيارات جلسات الواتساب المتصلة
        $sessions = WahaSession::all();
        $sessionOptions = [];
        foreach ($sessions as $s) {
            $statusEmoji = $s->status === 'WORKING' ? '🟢 متصل' : ($s->status === 'SCAN_QR_CODE' ? '🟡 في انتظار المسح' : '🔴 متوقف');
            $phoneStr = $s->phone ? " ({$s->phone})" : '';
            $sessionOptions[$s->name] = "جلسة: {$s->name}{$phoneStr} - {$statusEmoji}";
        }
        if (empty($sessionOptions)) {
            $sessionOptions['UAE'] = 'جلسة: UAE (الافتراضية)';
            $sessionOptions['default'] = 'جلسة: default';
        }

        return $form
            ->schema([
                Forms\Components\Tabs::make('إعدادات النظام')
                    ->tabs([
                        // تبويب الواتساب والـ OTP
                        Forms\Components\Tabs\Tab::make('إعدادات الواتساب والـ OTP')
                            ->icon('heroicon-o-chat-bubble-left-right')
                            ->schema([
                                Forms\Components\Section::make('الجلسة المعتمدة لإرسال رموز التحقق (OTP)')
                                    ->description('اختر من هنا رقم الواتساب المفعل والمتصل الذي سيقوم بإرسال رسائل كود التحقق للاعبين فور التسجيل.')
                                    ->schema([
                                        Forms\Components\Select::make('whatsapp_otp_session')
                                            ->label('رقم/جلسة الواتساب المعتمدة للإرسال')
                                            ->options($sessionOptions)
                                            ->required()
                                            ->helperText('النظام سيستخدم هذه الجلسة كأولوية أولى لإرسال أكواد الـ OTP ورسائل الإشعارات.')
                                            ->columnSpanFull(),

                                        Forms\Components\Grid::make(3)
                                            ->schema([
                                                Forms\Components\Toggle::make('whatsapp_otp_enabled')
                                                    ->label('تفعيل إرسال OTP عبر واتساب')
                                                    ->default(true),

                                                Forms\Components\Toggle::make('email_otp_enabled')
                                                    ->label('تفعيل إرسال OTP عبر البريد')
                                                    ->default(true),

                                                Forms\Components\TextInput::make('otp_expiry_minutes')
                                                    ->label('مدة الصلاحية (بالدقائق)')
                                                    ->numeric()
                                                    ->default(5)
                                                    ->required(),
                                            ]),

                                        Forms\Components\Textarea::make('otp_template')
                                            ->label('قالب نص رسالة الـ OTP')
                                            ->rows(3)
                                            ->helperText('استخدم {otp} لكتابة الكود تلقائياً، و {minutes} لمدة الصلاحية.')
                                            ->columnSpanFull(),
                                    ]),

                                Forms\Components\Section::make('فحص وتجربة إرسال رسالة واتساب حية')
                                    ->schema([
                                        Forms\Components\TextInput::make('test_phone')
                                            ->label('رقم الهاتف للتجربة')
                                            ->placeholder('مثال: 01008158177 أو +971503803917'),
                                    ]),
                            ]),

                        // تبويب إعدادات البريد الإلكتروني SMTP
                        Forms\Components\Tabs\Tab::make('إعدادات البريد الإلكتروني (SMTP)')
                            ->icon('heroicon-o-envelope')
                            ->schema([
                                Forms\Components\Section::make('بيانات الاتصال بخادم البريد (SMTP Server)')
                                    ->description('اضبط إعدادات الـ SMTP الخاصة ببريدك لإرسال رسائل التحقق والإشعارات للاعبين بسلاسة.')
                                    ->schema([
                                        Forms\Components\Grid::make(3)
                                            ->schema([
                                                Forms\Components\Select::make('mail_mailer')
                                                    ->label('بروتوكول الإرسال')
                                                    ->options([
                                                        'smtp' => 'SMTP (خادم مخصص / Gmail / Outlook)',
                                                        'sendmail' => 'Sendmail (خادم النظام الداخلي)',
                                                        'log' => 'Log (للتطوير المحلي في السجلات فقط)',
                                                    ])
                                                    ->default('smtp')
                                                    ->required(),

                                                Forms\Components\TextInput::make('mail_host')
                                                    ->label('خادم الـ SMTP (Host)')
                                                    ->placeholder('مثال: smtp.gmail.com أو mail.farfasha.app')
                                                    ->required(),

                                                Forms\Components\TextInput::make('mail_port')
                                                    ->label('المنفذ (Port)')
                                                    ->numeric()
                                                    ->placeholder('587 أو 465 أو 25')
                                                    ->default(587)
                                                    ->required(),
                                            ]),

                                        Forms\Components\Grid::make(3)
                                            ->schema([
                                                Forms\Components\Select::make('mail_encryption')
                                                    ->label('نوع التشفير (Encryption)')
                                                    ->options([
                                                        'tls' => 'TLS (مستحسن لمنفذ 587)',
                                                        'ssl' => 'SSL (مستحسن لمنفذ 465)',
                                                        'none' => 'بدون تشفير (None)',
                                                    ])
                                                    ->default('tls'),

                                                Forms\Components\TextInput::make('mail_username')
                                                    ->label('اسم المستخدم / البريد (Username)')
                                                    ->placeholder('your-email@gmail.com أو info@farfasha.app'),

                                                Forms\Components\TextInput::make('mail_password')
                                                    ->label('كلمة المرور (Password / App Password)')
                                                    ->password()
                                                    ->revealable(),
                                            ]),

                                        Forms\Components\Grid::make(2)
                                            ->schema([
                                                Forms\Components\TextInput::make('mail_from_address')
                                                    ->label('عنوان بريد المرسل (From Address)')
                                                    ->email()
                                                    ->placeholder('noreply@farfasha.app')
                                                    ->required(),

                                                Forms\Components\TextInput::make('mail_from_name')
                                                    ->label('اسم المرسل الظاهر (From Name)')
                                                    ->placeholder('منصة وتطبيق فرفشة')
                                                    ->required(),
                                            ]),
                                    ]),

                                Forms\Components\Section::make('فحص وتجربة إرسال بريد إلكتروني حي')
                                    ->schema([
                                        Forms\Components\TextInput::make('test_email')
                                            ->label('البريد الإلكتروني للتجربة')
                                            ->email()
                                            ->placeholder('مثال: osamasabry@msn.com'),
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),
            ])
            ->statePath('data');
    }

    /**
     * حفظ كافة الإعدادات
     */
    public function save(): void
    {
        $state = $this->form->getState();

        // 1. حفظ جلسة الواتساب المعتمدة وإعدادات الـ OTP
        SiteSetting::set('whatsapp_otp_session', $state['whatsapp_otp_session'] ?? 'UAE', 'otp');
        SiteSetting::set('otp_settings', [
            'whatsapp_enabled' => (bool) ($state['whatsapp_otp_enabled'] ?? true),
            'email_enabled' => (bool) ($state['email_otp_enabled'] ?? true),
            'expiry_minutes' => (int) ($state['otp_expiry_minutes'] ?? 5),
            'template' => $state['otp_template'] ?? '',
        ], 'otp');

        // 2. حفظ إعدادات خادم البريد SMTP
        $mailSettings = [
            'mailer' => $state['mail_mailer'] ?? 'smtp',
            'host' => $state['mail_host'] ?? '',
            'port' => (int) ($state['mail_port'] ?? 587),
            'encryption' => $state['mail_encryption'] ?? 'tls',
            'username' => $state['mail_username'] ?? '',
            'password' => $state['mail_password'] ?? '',
            'from_address' => $state['mail_from_address'] ?? 'noreply@farfasha.app',
            'from_name' => $state['mail_from_name'] ?? 'منصة وتطبيق فرفشة',
        ];
        SiteSetting::set('mail_settings', $mailSettings, 'mail');

        // تطبيق الإعدادات حياً على لارافيل فورياً
        config([
            'mail.default' => $mailSettings['mailer'],
            'mail.mailers.smtp.host' => $mailSettings['host'],
            'mail.mailers.smtp.port' => $mailSettings['port'],
            'mail.mailers.smtp.encryption' => $mailSettings['encryption'] === 'none' ? null : $mailSettings['encryption'],
            'mail.mailers.smtp.username' => $mailSettings['username'],
            'mail.mailers.smtp.password' => $mailSettings['password'],
            'mail.from.address' => $mailSettings['from_address'],
            'mail.from.name' => $mailSettings['from_name'],
        ]);

        Notification::make()
            ->title('تم حفظ وتطبيق الإعدادات بنجاح 🟢')
            ->body('تم تحديث إعدادات البريد والواتساب فورياً على كامل المنصة.')
            ->success()
            ->send();
    }

    /**
     * إرسال رسالة واتساب تجريبية حية
     */
    public function sendTestWhatsApp(): void
    {
        $state = $this->form->getState();
        $phone = $state['test_phone'] ?? '';
        $session = $state['whatsapp_otp_session'] ?? 'UAE';

        if (empty($phone)) {
            Notification::make()->title('يرجى إدخال رقم الهاتف أولاً')->warning()->send();
            return;
        }

        try {
            $service = app(WahaMessageService::class);
            $service->sendTextSync($phone, "مرحباً! هذه رسالة فحص تجريبية من منصة فرفشة عبر جلسة الواتساب المعتمدة ({$session}) 🚀", $session);

            Notification::make()
                ->title('تم إرسال رسالة الواتساب بنجاح! 📲')
                ->body("وصلت الرسالة بنجاح إلى الرقم: {$phone}")
                ->success()
                ->send();
        } catch (\Throwable $e) {
            Notification::make()
                ->title('فشل إرسال رسالة الواتساب')
                ->body($e->getMessage())
                ->danger()
                ->send();
        }
    }

    /**
     * إرسال بريد إلكتروني تجريبي حي
     */
    public function sendTestEmail(): void
    {
        $state = $this->form->getState();
        $email = $state['test_email'] ?? '';

        if (empty($email)) {
            Notification::make()->title('يرجى إدخال البريد الإلكتروني للتجربة')->warning()->send();
            return;
        }

        // تطبيق إعدادات الـ SMTP حياً قبل الفحص
        $this->save();

        try {
            Mail::raw("مرحباً بك! هذه رسالة بريد إلكتروني تجريبية للتأكد من ربط خادم الـ SMTP بنجاح مع منصة فرفشة 🎮\n\nتاريخ الإرسال: " . now()->toDateTimeString(), function ($m) use ($email, $state) {
                $m->to($email)
                    ->subject('تجربة ربط خادم البريد SMTP - منصة فرفشة ✉️')
                    ->from($state['mail_from_address'], $state['mail_from_name']);
            });

            Notification::make()
                ->title('تم إرسال البريد التجريبي بنجاح! ✉️')
                ->body("تم إرسال الرسالة إلى: {$email}. يرجى التحقق من صندوق الوارد أو البريد غير الهام (Spam).")
                ->success()
                ->send();
        } catch (\Throwable $e) {
            Notification::make()
                ->title('تعذر إرسال البريد الإلكتروني عبر خادم الـ SMTP')
                ->body('تفاصيل الخطأ: ' . $e->getMessage())
                ->danger()
                ->persistent()
                ->send();
        }
    }
}

