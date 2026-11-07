<?php

namespace App\Filament\Resources\AppStoreLinkResource\Pages;

use App\Filament\Resources\AppStoreLinkResource;
use Filament\Resources\Pages\CreateRecord;

class CreateAppStoreLink extends CreateRecord
{
    protected static string $resource = AppStoreLinkResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}

