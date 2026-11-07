<?php

namespace App\Filament\Resources\GameplayModeResource\Pages;

use App\Filament\Resources\GameplayModeResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditGameplayMode extends EditRecord
{
    protected static string $resource = GameplayModeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}

