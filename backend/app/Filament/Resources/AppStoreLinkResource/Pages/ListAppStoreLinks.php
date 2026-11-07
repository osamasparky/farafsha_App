<?php

namespace App\Filament\Resources\AppStoreLinkResource\Pages;

use App\Filament\Resources\AppStoreLinkResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListAppStoreLinks extends ListRecords
{
    protected static string $resource = AppStoreLinkResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()->label('إضافة رابط متجر جديد'),
        ];
    }
}

