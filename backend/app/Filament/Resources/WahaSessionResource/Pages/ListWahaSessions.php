<?php

namespace App\Filament\Resources\WahaSessionResource\Pages;

use App\Filament\Resources\WahaSessionResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListWahaSessions extends ListRecords
{
    protected static string $resource = WahaSessionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()->label('إنشاء جلسة واتساب جديدة'),
        ];
    }
}
