<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AppPageResource\Pages;
use App\Models\AppPage;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class AppPageResource extends Resource
{
    protected static ?string $model = AppPage::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-text';
    protected static ?string $navigationGroup = 'إعدادات التطبيق والدعم';
    protected static ?string $modelLabel = 'صفحة محتوى';
    protected static ?string $pluralModelLabel = 'صفحات الدعم والسياسات (Pages)';
    protected static ?int $navigationSort = 7;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('معلومات الصفحة')
                    ->schema([
                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\TextInput::make('title')
                                    ->label('عنوان الصفحة')
                                    ->required()
                                    ->maxLength(100),

                                Forms\Components\TextInput::make('slug')
                                    ->label('المعرّف (Slug)')
                                    ->placeholder('مثال: privacy-policy أو contact-us')
                                    ->required()
                                    ->unique(ignoreRecord: true),
                            ]),

                        Forms\Components\MarkdownEditor::make('content')
                            ->label('محتوى الصفحة (يدعم التنسيق وماركداون)')
                            ->required()
                            ->columnSpanFull(),

                        Forms\Components\KeyValue::make('meta')
                            ->label('بيانات إضافية (مثل email, whatsapp, phone)')
                            ->keyLabel('المفتاح (Key)')
                            ->valueLabel('القيمة (Value)')
                            ->columnSpanFull(),

                        Forms\Components\Toggle::make('is_active')
                            ->label('مفعّلة في التطبيق')
                            ->default(true),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('title')
                    ->label('عنوان الصفحة')
                    ->weight('bold')
                    ->searchable(),

                Tables\Columns\TextColumn::make('slug')
                    ->label('المعرّف')
                    ->badge(),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعّلة')
                    ->boolean(),

                Tables\Columns\TextColumn::make('updated_at')
                    ->label('آخر تحديث')
                    ->dateTime('d/m/Y H:i'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAppPages::route('/'),
            'create' => Pages\CreateAppPage::route('/create'),
            'edit' => Pages\EditAppPage::route('/{record}/edit'),
        ];
    }
}

