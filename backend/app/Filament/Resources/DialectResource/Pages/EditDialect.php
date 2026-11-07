<?php

namespace App\Filament\Resources\DialectResource\Pages;

use App\Filament\Resources\DialectResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditDialect extends EditRecord
{
    protected static string $resource = DialectResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}

