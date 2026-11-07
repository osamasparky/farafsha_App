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
            ->actions([
                Tables\Actions\Action::make('view_details')
                    ->label('عرض التفاصيل')
                    ->icon('heroicon-o-eye')
                    ->modalHeading('تفاصيل رسالة الواتساب')
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel('إغلاق')
                    ->modalContent(fn (WahaMessage $record) => new \Illuminate\Support\HtmlString("
                        <div class='space-y-4 p-2 text-sm'>
                            <div><strong class='text-gray-400'>الرقم:</strong> {$record->chat_id}</div>
                            <div><strong class='text-gray-400'>الحالة:</strong> {$record->status}</div>
                            " . ($record->last_error ? "<div class='text-rose-400'><strong class='text-gray-400'>الخطأ:</strong> {$record->last_error}</div>" : '') . "
                            <div><strong class='text-gray-400'>نص الرسالة:</strong></div>
                            <div class='p-3 bg-white/5 rounded-xl border border-white/10 whitespace-pre-wrap'>" . e($record->body) . "</div>
                        </div>
                    ")),
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

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListWahaMessages::route('/'),
        ];
    }
}

