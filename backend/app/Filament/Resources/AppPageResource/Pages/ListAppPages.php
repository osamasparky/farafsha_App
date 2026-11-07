<?php

namespace App\Filament\Resources\AppPageResource\Pages;

use App\Filament\Resources\AppPageResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListAppPages extends ListRecords
{
    protected static string $resource = AppPageResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}

