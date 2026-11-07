<?php

namespace App\Filament\Resources;

use App\Filament\Resources\WahaSessionResource\Pages;
use App\Models\WahaSession;
use App\Services\WahaClient;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\HtmlString;

class WahaSessionResource extends Resource
{
    protected static ?string $model = WahaSession::class;

    protected static ?string $navigationIcon = 'heroicon-o-signal';
    protected static ?string $navigationGroup = 'خدمات واتساب (WhatsApp)';
    protected static ?string $modelLabel = 'جلسة واتساب';
    protected static ?string $pluralModelLabel = 'جلسات الواتساب (Sessions)';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('بيانات الجلسة')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->label('اسم الجلسة (Session Name)')
                            ->required()
                            ->maxLength(100)
                            ->regex('/^[a-zA-Z0-9_-]+$/')
                            ->default(config('waha.default_session', 'default'))
                            ->unique(ignoreRecord: true),

                        Forms\Components\TextInput::make('status')
                            ->label('الحالة الحالية')
                            ->default('STOPPED')
                            ->disabled(),

                        Forms\Components\TextInput::make('phone')
                            ->label('رقم الهاتف المتصل')
                            ->disabled(),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('اسم الجلسة')
                    ->weight('bold')
                    ->searchable(),

                Tables\Columns\BadgeColumn::make('status')
                    ->label('حالة الاتصال')
                    ->colors([
                        'success' => fn ($state) => in_array($state, ['WORKING', 'CONNECTED', 'STARTING']),
                        'warning' => fn ($state) => in_array($state, ['SCAN_QR_CODE']),
                        'danger' => fn ($state) => in_array($state, ['STOPPED', 'FAILED']),
                    ]),

                Tables\Columns\TextColumn::make('phone')
                    ->label('رقم الحساب المتصل')
                    ->default('غير متصل بعد'),

                Tables\Columns\TextColumn::make('last_seen_at')
                    ->label('آخر ظهور')
                    ->dateTime('d/m/Y H:i'),
            ])
            ->actions([
                Tables\Actions\Action::make('start')
                    ->label('تشغيل')
                    ->icon('heroicon-o-play')
                    ->color('success')
                    ->action(function (WahaSession $record, WahaClient $client) {
                        try {
                            $client->start($record->name);
                            $record->update(['status' => 'STARTING']);
                            Notification::make()->title('تم إرسال أمر التشغيل بنجاح')->success()->send();
                        } catch (\Throwable $e) {
                            Notification::make()->title('خطأ في الاتصال بخادم WAHA')->body($e->getMessage())->danger()->send();
                        }
                    }),

                Tables\Actions\Action::make('qr')
                    ->label('مسح QR')
                    ->icon('heroicon-o-qr-code')
                    ->color('warning')
                    ->modalHeading(fn (WahaSession $record) => "ربط واتساب - جلسة: {$record->name}")
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel('إغلاق')
                    ->modalContent(function (WahaSession $record, WahaClient $client) {
                        try {
                            $png = $client->qr($record->name);
                            $base64 = base64_encode($png);
                            return new HtmlString("
                                <div class='text-center p-4 space-y-4'>
                                    <p class='text-sm text-gray-400'>افتح واتساب في هاتفك > الأجهزة المرتبطة > ربط جهاز، ثم امسح الكود التالي:</p>
                                    <div class='inline-block p-4 bg-white rounded-2xl shadow-xl'>
                                        <img src='data:image/png;base64,{$base64}' alt='WhatsApp QR Code' class='w-64 h-64 mx-auto'>
                                    </div>
                                </div>
                            ");
                        } catch (\Throwable $e) {
                            return new HtmlString("
                                <div class='p-4 text-center text-amber-400'>
                                    <p>تعذر جلب رمز QR حالياً. تأكد من تشغيل الجلسة أو التحقق من خادم WAHA.</p>
                                    <p class='text-xs mt-2 text-gray-500'>{$e->getMessage()}</p>
                                </div>
                            ");
                        }
                    }),

                Tables\Actions\Action::make('stop')
                    ->label('إيقاف')
                    ->icon('heroicon-o-stop')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->action(function (WahaSession $record, WahaClient $client) {
                        try {
                            $client->stop($record->name);
                            $record->update(['status' => 'STOPPED']);
                            Notification::make()->title('تم إيقاف الجلسة بنجاح')->success()->send();
                        } catch (\Throwable $e) {
                            Notification::make()->title('خطأ أثناء إيقاف الجلسة')->body($e->getMessage())->danger()->send();
                        }
                    }),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListWahaSessions::route('/'),
        ];
    }
}
