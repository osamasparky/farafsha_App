<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';
    protected static ?string $navigationGroup = 'اللاعبون والمجتمع';
    protected static ?string $modelLabel = 'مستخدم';
    protected static ?string $pluralModelLabel = 'حسابات اللاعبين والمستخدمين';
    protected static ?int $navigationSort = 1;

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::count();
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'info';
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('بيانات الحساب')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->label('الاسم')
                            ->required(),

                        Forms\Components\TextInput::make('email')
                            ->label('البريد الإلكتروني')
                            ->email()
                            ->required()
                            ->unique(ignoreRecord: true),

                        Forms\Components\TextInput::make('phone')
                            ->label('رقم الهاتف (مع كود الدولة)')
                            ->tel()
                            ->placeholder('201012345678'),

                        Forms\Components\DateTimePicker::make('phone_verified_at')
                            ->label('تاريخ توثيق الهاتف (OTP)'),

                        Forms\Components\TextInput::make('password')
                            ->label('كلمة المرور الجديدة')
                            ->password()
                            ->dehydrated(fn ($state) => filled($state))
                            ->required(fn (string $context): bool => $context === 'create'),

                        Forms\Components\Toggle::make('is_admin')
                            ->label('مشرف في لوحة التحكم')
                            ->default(false),
                    ])->columns(2),

                Forms\Components\Section::make('إحصائيات اللعب')
                    ->schema([
                        Forms\Components\TextInput::make('level')
                            ->label('المستوى')
                            ->numeric()
                            ->default(1),

                        Forms\Components\TextInput::make('total_score')
                            ->label('مجموع النقاط')
                            ->numeric()
                            ->default(0),

                        Forms\Components\TextInput::make('wins_count')
                            ->label('مرات الفوز')
                            ->numeric()
                            ->default(0),

                        Forms\Components\TextInput::make('games_played')
                            ->label('إجمالي الألعاب')
                            ->numeric()
                            ->default(0),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('الاسم')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('email')
                    ->label('البريد الإلكتروني')
                    ->searchable(),

                Tables\Columns\TextColumn::make('phone')
                    ->label('رقم الهاتف')
                    ->searchable()
                    ->copyable()
                    ->icon('heroicon-m-phone'),

                Tables\Columns\IconColumn::make('phone_verified_at')
                    ->label('موثق OTP')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-badge')
                    ->falseIcon('heroicon-o-x-circle')
                    ->trueColor('success')
                    ->falseColor('gray'),

                Tables\Columns\TextColumn::make('level')
                    ->label('المستوى')
                    ->badge()
                    ->color('primary'),

                Tables\Columns\TextColumn::make('total_score')
                    ->label('مجموع النقاط')
                    ->numeric()
                    ->sortable()
                    ->color('warning'),

                Tables\Columns\TextColumn::make('wins_count')
                    ->label('مرات الفوز')
                    ->numeric()
                    ->sortable(),

                Tables\Columns\IconColumn::make('is_admin')
                    ->label('مشرف')
                    ->boolean(),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ التسجيل')
                    ->dateTime('d/m/Y')
                    ->sortable(),
            ])
            ->defaultSort('total_score', 'desc')
            ->actions([
                Tables\Actions\Action::make('send_whatsapp')
                    ->label('إرسال واتساب')
                    ->icon('heroicon-o-chat-bubble-left-ellipsis')
                    ->color('success')
                    ->visible(fn ($record) => !empty($record->phone))
                    ->modalHeading(fn ($record) => "إرسال رسالة واتساب إلى: {$record->name}")
                    ->modalSubmitActionLabel('إرسال الرسالة الآن 📲')
                    ->form([
                        Forms\Components\Textarea::make('message')
                            ->label('نص رسالة الواتساب')
                            ->placeholder("اكتب نص الرسالة هنا...\n(يمكنك كتابة {name} ليتم استبدالها باسم اللاعب تلقائياً)")
                            ->required()
                            ->rows(4),
                    ])
                    ->action(function ($record, array $data) {
                        try {
                            $text = str_replace('{name}', $record->name, $data['message']);
                            $wahaService = app(\App\Services\WahaMessageService::class);
                            $wahaService->sendTextSync($record->phone, $text);

                            \Filament\Notifications\Notification::make()
                                ->title('تم الإرسال بنجاح!')
                                ->body("تم تسليم رسالة الواتساب إلى {$record->name} بنجاح 📲")
                                ->success()
                                ->send();
                        } catch (\Throwable $e) {
                            \Filament\Notifications\Notification::make()
                                ->title('تعذر إرسال الرسالة')
                                ->body($e->getMessage())
                                ->danger()
                                ->persistent()
                                ->send();
                        }
                    }),

                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\BulkAction::make('broadcast_whatsapp')
                        ->label('إرسال واتساب للمحددين')
                        ->icon('heroicon-o-chat-bubble-bottom-center-text')
                        ->color('success')
                        ->modalHeading('إرسال رسالة واتساب جماعية للاعبين المحددين')
                        ->modalSubmitActionLabel('إرسال للجميع الآن 📢')
                        ->form([
                            Forms\Components\Textarea::make('message')
                                ->label('نص الرسالة الجماعية')
                                ->placeholder("اكتب الرسالة هنا...\n(يمكنك استخدام {name} ليتم استبدالها باسم كل لاعب شخصياً)")
                                ->required()
                                ->rows(4),
                        ])
                        ->action(function (\Illuminate\Database\Eloquent\Collection $records, array $data) {
                            $count = 0;
                            $failures = 0;
                            $wahaService = app(\App\Services\WahaMessageService::class);

                            foreach ($records as $record) {
                                if (empty($record->phone)) continue;
                                $text = str_replace('{name}', $record->name, $data['message']);
                                try {
                                    $wahaService->sendTextSync($record->phone, $text);
                                    $count++;
                                } catch (\Throwable $e) {
                                    $failures++;
                                    \Illuminate\Support\Facades\Log::warning("WAHA Bulk send error for user {$record->id}: " . $e->getMessage());
                                }
                            }

                            if ($count > 0) {
                                \Filament\Notifications\Notification::make()
                                    ->title('تم إرسال الرسائل الجماعية بنجاح!')
                                    ->body("تم إرسال رسائل الواتساب بنجاح إلى {$count} لاعب." . ($failures > 0 ? " (تعذر الإرسال إلى {$failures} لاعبين)" : ''))
                                    ->success()
                                    ->send();
                            } else {
                                \Filament\Notifications\Notification::make()
                                    ->title('تعذر إرسال الرسائل')
                                    ->body("فشل الإرسال لجميع اللاعبين المحددين ({$failures} أخطاء). تأكد من صحة أرقام الهواتف وجلسة الواتساب.")
                                    ->danger()
                                    ->send();
                            }
                        }),

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
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
