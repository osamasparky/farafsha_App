<?php

namespace App\Filament\Resources\SocialProviderResource\Pages;

use App\Filament\Resources\SocialProviderResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditSocialProvider extends EditRecord
{
    protected static string $resource = SocialProviderResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}

