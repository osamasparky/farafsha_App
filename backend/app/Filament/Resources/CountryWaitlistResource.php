<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CountryWaitlistResource\Pages;
use App\Models\CountryWaitlist;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CountryWaitlistResource extends Resource
{
    protected static ?string $model = CountryWaitlist::class;

    protected static ?string $navigationIcon = 'heroicon-o-envelope';
    protected static ?string $navigationGroup = 'موقع فرفشة والمحتوى';
    protected static ?string $modelLabel = 'طلب تنبيه التوفر';
    protected static ?string $pluralModelLabel = 'قائمة الانتظار (Waitlist)';
    protected static ?int $navigationSort = 4;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('email')
                    ->label('البريد الإلكتروني')
                    ->email()
                    ->required(),

                Forms\Components\TextInput::make('country_code')
                    ->label('رمز الدولة')
                    ->required(),

                Forms\Components\TextInput::make('ip_address')
                    ->label('عنوان الـ IP')
                    ->disabled(),

                Forms\Components\Toggle::make('consent_given')
                    ->label('الموافقة على سياسة الخصوصية والتنبيه')
                    ->disabled(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('email')
                    ->label('البريد الإلكتروني')
                    ->searchable()
                    ->copyable(),

                Tables\Columns\TextColumn::make('country_code')
                    ->label('الدولة')
                    ->badge()
                    ->color('warning')
                    ->sortable(),

                Tables\Columns\TextColumn::make('ip_address')
                    ->label('IP'),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ التسجيل')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->actions([
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCountryWaitlists::route('/'),
        ];
    }
}

