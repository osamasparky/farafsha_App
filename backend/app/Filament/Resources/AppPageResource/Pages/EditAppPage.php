<?php

namespace App\Filament\Resources\AppPageResource\Pages;

use App\Filament\Resources\AppPageResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditAppPage extends EditRecord
{
    protected static string $resource = AppPageResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}

