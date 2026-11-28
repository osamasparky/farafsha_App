<?php

namespace App\Filament\Resources;

use App\Filament\Resources\WahaMessageResource\Pages;
use App\Models\WahaMessage;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class WahaMessageResource extends Resource
{
    protected static ?string $model = WahaMessage::class;

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-left-right';
    protected static ?string $navigationGroup = 'التواصل والتسويق';
    protected static ?string $modelLabel = 'رسالة واتساب';
    protected static ?string $pluralModelLabel = 'سجل رسائل الواتساب';
    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form;
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('session.name')
                    ->label('الجلسة')
                    ->badge()
                    ->color('primary'),

                Tables\Columns\TextColumn::make('chat_id')
                    ->label('المستلم / الرقم')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\BadgeColumn::make('direction')
                    ->label('الاتجاه')
                    ->colors([
                        'info' => 'out',
                        'success' => 'in',
                    ])
                    ->formatStateUsing(fn ($state) => $state === 'out' ? 'صادر ↗' : 'وارد ↙'),

                Tables\Columns\TextColumn::make('body')
                    ->label('نص الرسالة')
                    ->limit(60)
                    ->searchable(),

                Tables\Columns\BadgeColumn::make('status')
                    ->label('حالة الإرسال')
                    ->colors([
                        'warning' => 'queued',
                        'primary' => 'sending',
                        'info' => 'sent',
                        'success' => fn ($state) => in_array($state, ['delivered', 'read']),
                        'danger' => fn ($state) => in_array($state, ['failed', 'unknown']),
                    ]),

                Tables\Columns\TextColumn::make('sent_at')
                    ->label('وقت الإرسال')
                    ->dateTime('d/m/Y H:i'),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->headerActions([
                Tables\Actions\Action::make('purge_messages')
                    ->label('تفريغ كافة الرسائل 🗑️')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->modalHeading('تفريغ كافة رسائل الواتساب')
                    ->modalDescription('هل أنت متأكد من رغبتك في حذف جميع رسائل الواتساب نهائياً من قاعدة البيانات؟')
                    ->modalSubmitActionLabel('نعم، تفريغ كافة الرسائل 🗑️')
                    ->action(function () {
                        $count = WahaMessage::count();
                        WahaMessage::truncate();
                        \Filament\Notifications\Notification::make()
                            ->title('تم تفريغ سجل الرسائل بنجاح')
                            ->body("تم حذف {$count} رسالة من قاعدة البيانات.")
                            ->success()
                            ->send();
                    }),
            ])
            ->actions([
                Tables\Actions\Action::make('view_details')
                    ->label('عرض التفاصيل')
                    ->icon('heroicon-o-eye')
                    ->modalHeading('تفاصيل رسالة الواتساب')
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel('إغلاق')
                    ->modalContent(fn (WahaMessage $record) => new \Illuminate\Support\HtmlString("
                        <div class='space-y-4 p-2 text-sm'>
                            <div><strong class='text-gray-400'>الرقم:</strong> " . e($record->chat_id) . "</div>
                            <div><strong class='text-gray-400'>الحالة:</strong> " . e($record->status) . "</div>
                            " . ($record->last_error ? "<div class='text-rose-400'><strong class='text-gray-400'>الخطأ:</strong> " . e($record->last_error) . "</div>" : '') . "
                            <div><strong class='text-gray-400'>نص الرسالة:</strong></div>
                            <div class='p-3 bg-white/5 rounded-xl border border-white/10 whitespace-pre-wrap'>" . e($record->body) . "</div>
                        </div>
                    ")),

                Tables\Actions\DeleteAction::make()
                    ->label('حذف')
                    ->modalHeading('حذف هذه الرسالة')
                    ->modalDescription('هل أنت متأكد من حذف هذه الرسالة من السجل؟')
                    ->modalSubmitActionLabel('نعم، احذف 🗑️'),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make()
                        ->label('حذف الرسائل المحددة 🗑️')
                        ->modalHeading('حذف الرسائل المحددة')
                        ->modalSubmitActionLabel('نعم، احذف المحدد'),
                ]),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('direction')
                    ->label('الاتجاه')
                    ->options([
                        'out' => 'صادر ↗',
                        'in' => 'وارد ↙',
                    ]),

                Tables\Filters\SelectFilter::make('status')
                    ->label('الحالة')
                    ->options([
                        'queued' => 'في الانتظار (Queued)',
                        'sent' => 'أُرسلت (Sent)',
                        'delivered' => 'تم التسليم (Delivered)',
                        'read' => 'تمت القراءة (Read)',
                        'failed' => 'فشل (Failed)',
                    ]),
            ]);
    }

    public static function getEloquentQuery(): \Illuminate\Database\Eloquent\Builder
    {
        return parent::getEloquentQuery()
            ->where('chat_id', 'not like', '%broadcast%');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListWahaMessages::route('/'),
        ];
    }
}

