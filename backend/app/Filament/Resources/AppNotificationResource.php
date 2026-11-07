<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AppNotificationResource\Pages;
use App\Models\AppNotification;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class AppNotificationResource extends Resource
{
    protected static ?string $model = AppNotification::class;

    protected static ?string $navigationIcon = 'heroicon-o-bell';
    protected static ?string $navigationGroup = 'التنبيهات والإشعارات';
    protected static ?string $modelLabel = 'إشعار';
    protected static ?string $pluralModelLabel = 'الإشعارات والتنبيهات';
    protected static ?int $navigationSort = 6;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('محتوى الإشعار')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('عنوان الإشعار')
                            ->placeholder('مثال: بطولة لمّة الأسبوعية بدأت!')
                            ->required()
                            ->maxLength(100),

                        Forms\Components\Textarea::make('message')
                            ->label('نص الرسالة')
                            ->placeholder('اكتب نص الإشعار الذي سيظهر للاعبين...')
                            ->required()
                            ->rows(3),

                        Forms\Components\Grid::make(3)
                            ->schema([
                                Forms\Components\Select::make('type')
                                    ->label('نوع الإشعار')
                                    ->options([
                                        'info' => 'إشعار عام (Info)',
                                        'reward' => 'مكافآت ونقاط (Reward)',
                                        'update' => 'تحديثات ومحتوى (Update)',
                                        'game' => 'ألعاب وغرف (Game)',
                                    ])
                                    ->default('info')
                                    ->required(),

                                Forms\Components\Select::make('icon')
                                    ->label('رمز الأيقونة')
                                    ->options(AppNotification::getAvailableIcons())
                                    ->searchable()
                                    ->preload()
                                    ->default('notifications')
                                    ->required(),

                                Forms\Components\Toggle::make('is_active')
                                    ->label('مفعّل في التطبيق')
                                    ->default(true),
                            ]),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('message')
                    ->label('الرسالة')
                    ->limit(50),

                Tables\Columns\TextColumn::make('type')
                    ->label('النوع')
                    ->badge()
                    ->color(fn ($state) => match ($state) {
                        'info' => 'info',
                        'reward' => 'warning',
                        'update' => 'success',
                        'game' => 'primary',
                        default => 'gray',
                    }),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعّل')
                    ->boolean(),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإرسال')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
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
            'index' => Pages\ListAppNotifications::route('/'),
            'create' => Pages\CreateAppNotification::route('/create'),
            'edit' => Pages\EditAppNotification::route('/{record}/edit'),
        ];
    }
}

