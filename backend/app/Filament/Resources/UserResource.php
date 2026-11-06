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
    protected static ?string $navigationGroup = 'المستخدمون والإدارة';
    protected static ?string $modelLabel = 'مستخدم';
    protected static ?string $pluralModelLabel = 'المستخدمون واللاعبون';
    protected static ?int $navigationSort = 5;

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
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
