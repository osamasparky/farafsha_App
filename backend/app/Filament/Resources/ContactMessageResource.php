<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ContactMessageResource\Pages;
use App\Models\ContactMessage;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ContactMessageResource extends Resource
{
    protected static ?string $model = ContactMessage::class;

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-bottom-center-text';
    protected static ?string $navigationGroup = 'موقع فرفشة والمحتوى';
    protected static ?string $modelLabel = 'رسالة تواصل';
    protected static ?string $pluralModelLabel = 'رسائل تواصل معنا';
    protected static ?int $navigationSort = 5;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('name')->label('الاسم')->disabled(),
                Forms\Components\TextInput::make('email')->label('البريد')->disabled(),
                Forms\Components\TextInput::make('subject')->label('الموضوع')->disabled(),
                Forms\Components\Textarea::make('message')->label('الرسالة')->disabled()->columnSpanFull(),
                Forms\Components\Select::make('status')
                    ->label('حالة الرسالة')
                    ->options([
                        'new' => 'جديدة',
                        'read' => 'تمت القراءة',
                        'replied' => 'تم الرد',
                        'archived' => 'مؤرشفة',
                    ])
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')->label('الاسم')->searchable(),
                Tables\Columns\TextColumn::make('email')->label('البريد')->searchable()->copyable(),
                Tables\Columns\TextColumn::make('subject')->label('الموضوع')->limit(30),
                Tables\Columns\BadgeColumn::make('status')
                    ->label('الحالة')
                    ->colors([
                        'danger' => 'new',
                        'warning' => 'read',
                        'success' => 'replied',
                        'gray' => 'archived',
                    ]),
                Tables\Columns\TextColumn::make('created_at')->label('تاريخ الإرسال')->dateTime('d/m/Y H:i')->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListContactMessages::route('/'),
            'edit' => Pages\EditContactMessage::route('/{record}/edit'),
        ];
    }
}

