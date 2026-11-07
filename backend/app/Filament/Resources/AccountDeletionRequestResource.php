<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AccountDeletionRequestResource\Pages;
use App\Models\AccountDeletionRequest;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class AccountDeletionRequestResource extends Resource
{
    protected static ?string $model = AccountDeletionRequest::class;

    protected static ?string $navigationIcon = 'heroicon-o-user-minus';
    protected static ?string $navigationGroup = 'اللاعبون والمجتمع';
    protected static ?string $modelLabel = 'طلب حذف حساب';
    protected static ?string $pluralModelLabel = 'طلبات حذف الحسابات';
    protected static ?int $navigationSort = 2;

    public static function getNavigationBadge(): ?string
    {
        $count = static::getModel()::where('status', 'pending')->count();
        return $count > 0 ? (string) $count : null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'danger';
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('تفاصيل طلب حذف الحساب')
                    ->schema([
                        Forms\Components\TextInput::make('user.name')
                            ->label('اسم المستخدم')
                            ->disabled(),

                        Forms\Components\TextInput::make('user.email')
                            ->label('البريد الإلكتروني')
                            ->disabled(),

                        Forms\Components\TextInput::make('user.phone')
                            ->label('رقم الهاتف')
                            ->disabled(),

                        Forms\Components\Select::make('status')
                            ->label('حالة الطلب')
                            ->options([
                                'pending' => 'معلق (قيد المراجعة)',
                                'approved' => 'تمت الموافقة وتم حذف الحساب',
                                'rejected' => 'مرفوض وتم إعادة تفعيل الحساب',
                            ])
                            ->required(),

                        Forms\Components\Textarea::make('reason')
                            ->label('سبب الحذف المذكور من المستخدم')
                            ->disabled()
                            ->columnSpanFull(),

                        Forms\Components\Textarea::make('admin_notes')
                            ->label('ملاحظات المسؤول')
                            ->placeholder('اكتب أي ملاحظات إدارية هنا...')
                            ->columnSpanFull(),

                        Forms\Components\DateTimePicker::make('requested_at')
                            ->label('تاريخ تقديم الطلب')
                            ->disabled(),

                        Forms\Components\DateTimePicker::make('reviewed_at')
                            ->label('تاريخ اتخاذ القرار')
                            ->disabled(),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('اللاعب / المستخدم')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->description(fn (AccountDeletionRequest $record) => $record->user?->email ?? $record->user?->phone ?? 'لا يوجد بيانات'),

                Tables\Columns\TextColumn::make('user.phone')
                    ->label('رقم الهاتف')
                    ->searchable()
                    ->color('gray'),

                Tables\Columns\TextColumn::make('reason')
                    ->label('سبب الطلب')
                    ->limit(40)
                    ->color('gray'),

                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending' => 'قيد المراجعة ⏳',
                        'approved' => 'تم الحذف 🗑️',
                        'rejected' => 'مرفوض / مفعّل ✅',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'approved' => 'danger',
                        'rejected' => 'success',
                        default => 'secondary',
                    }),

                Tables\Columns\TextColumn::make('requested_at')
                    ->label('تاريخ الطلب')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),

                Tables\Columns\TextColumn::make('reviewed_at')
                    ->label('تاريخ المراجعة')
                    ->dateTime('d/m/Y H:i')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('requested_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('تصفية حسب الحالة')
                    ->options([
                        'pending' => 'قيد المراجعة',
                        'approved' => 'تمت الموافقة',
                        'rejected' => 'مرفوض',
                    ]),
            ])
            ->actions([
                Tables\Actions\Action::make('approve_delete')
                    ->label('حذف الحساب نهائياً')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->visible(fn (AccountDeletionRequest $record) => $record->status === 'pending')
                    ->requiresConfirmation()
                    ->modalHeading('تأكيد قرار حذف حساب اللاعب نهائياً')
                    ->modalDescription('هل أنت متأكد من قرارك بحذف هذا الحساب نهائياً؟ سيتم حذف بيانات المستخدم ولا يمكن التراجع.')
                    ->modalSubmitActionLabel('نعم، احذف الحساب نهائياً')
                    ->action(function (AccountDeletionRequest $record) {
                        $user = $record->user;
                        $record->update([
                            'status' => 'approved',
                            'reviewed_at' => now(),
                            'reviewed_by' => auth()->id(),
                        ]);

                        if ($user) {
                            $user->tokens()->delete();
                            $user->delete();
                        }

                        Notification::make()
                            ->title('تمت الموافقة وحذف الحساب بنجاح')
                            ->danger()
                            ->send();
                    }),

                Tables\Actions\Action::make('reject_reactivate')
                    ->label('رفض وإعادة تفعيل')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->visible(fn (AccountDeletionRequest $record) => $record->status === 'pending')
                    ->requiresConfirmation()
                    ->modalHeading('رفض طلب الحذف وإعادة تفعيل الحساب')
                    ->modalDescription('سيتم إلغاء تعليق الحساب والسماح للاعب بالدخول إلى فرفشة مرة أخرى.')
                    ->modalSubmitActionLabel('نعم، أعد التفعيل')
                    ->action(function (AccountDeletionRequest $record) {
                        $record->update([
                            'status' => 'rejected',
                            'reviewed_at' => now(),
                            'reviewed_by' => auth()->id(),
                        ]);

                        if ($record->user) {
                            $record->user->update([
                                'status' => 'active',
                                'deletion_requested_at' => null,
                            ]);
                        }

                        Notification::make()
                            ->title('تم رفض الطلب وإعادة تفعيل الحساب بنجاح')
                            ->success()
                            ->send();
                    }),

                Tables\Actions\ViewAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAccountDeletionRequests::route('/'),
            'view' => Pages\ViewAccountDeletionRequest::route('/{record}'),
        ];
    }
}

