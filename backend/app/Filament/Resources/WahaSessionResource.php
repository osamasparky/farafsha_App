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
    protected static ?string $navigationGroup = 'التواصل والتسويق';
    protected static ?string $modelLabel = 'جلسة واتساب';
    protected static ?string $pluralModelLabel = 'جلسات الواتساب';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('بيانات الجلسة')
                    ->description('تنبيه: لا حاجة لإدخال رقم الهاتف يدوياً، سيتم التعرف على رقمك تلقائياً عند مسح رمز QR من هاتفك.')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->label('اسم الجلسة (Session Name)')
                            ->required()
                            ->maxLength(100)
                            ->regex('/^[a-zA-Z0-9_-]+$/')
                            ->default('UAE')
                            ->helperText('اختر اسماً للجلسة بالأحرف الإنجليزية (مثل: default أو UAE أو WhatsApp-Main)')
                            ->unique(ignoreRecord: true),

                        Forms\Components\TextInput::make('status')
                            ->label('الحالة الحالية')
                            ->default('STOPPED')
                            ->disabled(),

                        Forms\Components\TextInput::make('phone')
                            ->label('رقم الهاتف المتصل')
                            ->disabled()
                            ->helperText('يُملأ تلقائياً بمجرد مسح رمز QR من واتساب في هاتفك'),
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
                        'success' => fn ($state) => in_array($state, ['WORKING', 'CONNECTED']),
                        'warning' => fn ($state) => in_array($state, ['SCAN_QR_CODE', 'STARTING']),
                        'danger' => fn ($state) => in_array($state, ['STOPPED', 'FAILED']),
                    ]),

                Tables\Columns\TextColumn::make('phone')
                    ->label('رقم الحساب المتصل')
                    ->icon('heroicon-m-phone')
                    ->default('غير متصل بعد (اضغط مسح QR)'),

                Tables\Columns\TextColumn::make('messages_count')
                    ->counts('messages')
                    ->label('الرسائل المسجلة')
                    ->badge()
                    ->color('info')
                    ->sortable(),

                Tables\Columns\TextColumn::make('last_seen_at')
                    ->label('آخر اتصال')
                    ->dateTime('d/m/Y H:i'),
            ])
            ->headerActions([
                Tables\Actions\Action::make('sync_all')
                    ->label('تحديث ومزامنة فورية 🔄')
                    ->icon('heroicon-o-arrow-path')
                    ->color('primary')
                    ->action(function (WahaClient $client) {
                        try {
                            $remoteSessions = $client->sessions();
                            foreach ($remoteSessions as $s) {
                                $rawPhone = data_get($s, 'me.id');
                                WahaSession::updateOrCreate(['name' => $s['name']], [
                                    'status' => $s['status'] ?? 'STOPPED',
                                    'phone' => $rawPhone ? preg_replace('/\D+/', '', $rawPhone) : null,
                                    'last_seen_at' => ($s['status'] ?? '') === 'WORKING' ? now() : null,
                                ]);
                            }
                            Notification::make()->title('تمت المزامنة بنجاح مع خادم الواتساب 🟢')->success()->send();
                        } catch (\Throwable $e) {
                            Notification::make()->title('تعذر الاتصال بخادم WAHA')->body($e->getMessage())->danger()->send();
                        }
                    }),

                Tables\Actions\Action::make('clear_all_system_messages')
                    ->label('تفريغ كافة الرسائل 🗑️')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->modalHeading('تفريغ كافة رسائل الواتساب')
                    ->modalDescription('هل أنت متأكد من حذف جميع رسائل الواتساب الصادرة والواردة لجميع الجلسات نهائياً من قاعدة البيانات؟')
                    ->modalSubmitActionLabel('نعم، تفريغ كافة الرسائل 🗑️')
                    ->action(function () {
                        $count = \App\Models\WahaMessage::count();
                        \App\Models\WahaMessage::truncate();
                        Notification::make()
                            ->title('تم تفريغ كافة الرسائل بنجاح')
                            ->body("تم حذف {$count} رسالة من قاعدة البيانات.")
                            ->success()
                            ->send();
                    }),
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

                Tables\Actions\Action::make('refresh_status')
                    ->label('تحديث')
                    ->icon('heroicon-o-arrow-path')
                    ->color('gray')
                    ->action(function (WahaSession $record, WahaClient $client) {
                        try {
                            $remote = $client->session($record->name);
                            $rawPhone = data_get($remote, 'me.id');
                            $record->update([
                                'status' => $remote['status'] ?? 'UNKNOWN',
                                'phone' => $rawPhone ? preg_replace('/\D+/', '', $rawPhone) : $record->phone,
                                'last_seen_at' => ($remote['status'] ?? '') === 'WORKING' ? now() : $record->last_seen_at,
                            ]);
                            Notification::make()->title("تم تحديث حالة الجلسة '{$record->name}' إلى: {$record->status}")->success()->send();
                        } catch (\Throwable $e) {
                            Notification::make()->title('خطأ في الاتصال')->body($e->getMessage())->danger()->send();
                        }
                    }),

                Tables\Actions\Action::make('clear_messages')
                    ->label('مسح الرسائل')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->modalHeading(fn (WahaSession $record) => "مسح رسائل جلسة: {$record->name}")
                    ->modalDescription(fn (WahaSession $record) => "هل أنت متأكد من مسح جميع الرسائل المسجلة لجلسة '{$record->name}'؟ سيتم حذف " . $record->messages()->count() . " رسالة من السجل نهائياً.")
                    ->modalSubmitActionLabel('نعم، مسح الرسائل 🗑️')
                    ->action(function (WahaSession $record) {
                        $count = $record->messages()->count();
                        $record->messages()->delete();
                        Notification::make()
                            ->title('تم مسح الرسائل بنجاح')
                            ->body("تم حذف {$count} رسالة تابعة لجلسة '{$record->name}'.")
                            ->success()
                            ->send();
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

                Tables\Actions\Action::make('clear_all_system_messages')
                    ->label('تفريغ كافة الرسائل 🗑️')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->modalHeading('تفريغ كافة رسائل الواتساب')
                    ->modalDescription('هل أنت متأكد من حذف جميع رسائل الواتساب الصادرة والواردة لجميع الجلسات نهائياً من قاعدة البيانات؟')
                    ->modalSubmitActionLabel('نعم، تفريغ كافة الرسائل 🗑️')
                    ->action(function () {
                        $count = \App\Models\WahaMessage::count();
                        \App\Models\WahaMessage::truncate();
                        Notification::make()
                            ->title('تم تفريغ كافة الرسائل بنجاح')
                            ->body("تم حذف {$count} رسالة من قاعدة البيانات.")
                            ->success()
                            ->send();
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
