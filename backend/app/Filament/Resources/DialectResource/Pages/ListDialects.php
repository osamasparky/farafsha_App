<?php

namespace App\Filament\Resources\DialectResource\Pages;

use App\Filament\Resources\DialectResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListDialects extends ListRecords
{
    protected static string $resource = DialectResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}

