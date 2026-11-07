<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RoomResource\Pages;
use App\Models\Room;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class RoomResource extends Resource
{
    protected static ?string $model = Room::class;

    protected static ?string $navigationIcon = 'heroicon-o-play-circle';
    protected static ?string $navigationGroup = 'اللعب والمنافسات';
    protected static ?string $modelLabel = 'غرفة لعب مباشر';
    protected static ?string $pluralModelLabel = 'غرف اللعب المباشر';
    protected static ?int $navigationSort = 1;

    public static function getNavigationBadge(): ?string
    {
        $count = static::getModel()::where('status', 'active')->count();
        return $count > 0 ? (string) $count : null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'success';
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('معلومات الغرفة الحية')
                    ->schema([
                        Forms\Components\TextInput::make('code')
                            ->label('رمز الغرفة')
                            ->disabled()
                            ->required(),

                        Forms\Components\TextInput::make('host_name')
                            ->label('اسم المضيف')
                            ->required(),

                        Forms\Components\Select::make('game_id')
                            ->label('اللعبة الحالية')
                            ->relationship('game', 'name')
                            ->required(),

                        Forms\Components\Select::make('status')
                            ->label('حالة الغرفة')
                            ->options([
                                'waiting' => 'في انتظار اللاعبين',
                                'playing' => 'جارية حالياً',
                                'paused' => 'موقوفة مؤقتاً',
                                'finished' => 'انتهت',
                                'closed' => 'مغلقة',
                            ])
                            ->required(),

                        Forms\Components\TextInput::make('current_round')
                            ->label('الجولة الحالية')
                            ->numeric()
                            ->default(0),

                        Forms\Components\TextInput::make('total_rounds')
                            ->label('إجمالي الجولات')
                            ->numeric()
                            ->default(10),

                        Forms\Components\TextInput::make('max_players')
                            ->label('الحد الأقصى للاعبين')
                            ->numeric()
                            ->default(8),

                        Forms\Components\DateTimePicker::make('last_active_at')
                            ->label('آخر نشاط'),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('code')
                    ->label('كود الغرفة')
                    ->searchable()
                    ->weight('bold')
                    ->copyable()
                    ->color('primary'),

                Tables\Columns\TextColumn::make('host_name')
                    ->label('المضيف')
                    ->searchable(),

                Tables\Columns\TextColumn::make('game.name')
                    ->label('اللعبة')
                    ->badge(),

                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'waiting' => 'warning',
                        'playing' => 'success',
                        'finished' => 'gray',
                        default => 'danger',
                    }),

                Tables\Columns\TextColumn::make('players_count')
                    ->label('اللاعبون')
                    ->counts('players'),

                Tables\Columns\TextColumn::make('current_round')
                    ->label('الجولة')
                    ->formatStateUsing(fn ($record) => "{$record->current_round} من {$record->total_rounds}"),

                Tables\Columns\TextColumn::make('last_active_at')
                    ->label('آخر تفاعل')
                    ->since()
                    ->sortable(),
            ])
            ->defaultSort('id', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('تصفية حسب الحالة')
                    ->options([
                        'waiting' => 'في الانتظار',
                        'playing' => 'جارية',
                        'finished' => 'منتهية',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
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
            'index' => Pages\ListRooms::route('/'),
            'create' => Pages\CreateRoom::route('/create'),
            'edit' => Pages\EditRoom::route('/{record}/edit'),
        ];
    }
}
