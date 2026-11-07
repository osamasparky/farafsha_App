<?php

namespace App\Filament\Resources\AppStoreLinkResource\Pages;

use App\Filament\Resources\AppStoreLinkResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditAppStoreLink extends EditRecord
{
    protected static string $resource = AppStoreLinkResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}

