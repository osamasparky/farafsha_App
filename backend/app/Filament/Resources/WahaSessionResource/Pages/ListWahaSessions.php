<?php

namespace App\Filament\Resources\WahaSessionResource\Pages;

use App\Filament\Resources\WahaSessionResource;
use App\Models\WahaSession;
use App\Services\WahaClient;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListWahaSessions extends ListRecords
{
    protected static string $resource = WahaSessionResource::class;

    public function mount(): void
    {
        parent::mount();

        // مزامنة تلقائية فورية مع خادم WAHA عند فتح شاشة الجلسات
        try {
            $client = app(WahaClient::class);
            $remoteSessions = $client->sessions();
            foreach ($remoteSessions as $s) {
                $rawPhone = data_get($s, 'me.id');
                WahaSession::updateOrCreate(['name' => $s['name']], [
                    'status' => $s['status'] ?? 'STOPPED',
                    'phone' => $rawPhone ? preg_replace('/\D+/', '', $rawPhone) : null,
                    'last_seen_at' => ($s['status'] ?? '') === 'WORKING' ? now() : null,
                ]);
            }
        } catch (\Throwable $e) {}
    }

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
