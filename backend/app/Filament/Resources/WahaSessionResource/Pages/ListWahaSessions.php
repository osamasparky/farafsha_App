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
        $isOnline = false;
        try {
            $fp = @fsockopen('127.0.0.1', 3000, $errno, $errstr, 0.5);
            if ($fp) {
                $isOnline = true;
                fclose($fp);
            }
        } catch (\Throwable $e) {}

        return [
            Actions\Action::make('status_info')
                ->label($isOnline ? '🟢 خادم WAHA الداخلي يعمل (Port 3000)' : '⚠️ خادم WAHA غير مشغل (شغله بـ: php artisan waha:serve)')
                ->color($isOnline ? 'success' : 'warning')
                ->disabled(),
            Actions\CreateAction::make()->label('إنشاء جلسة جديدة'),
        ];
    }
}

