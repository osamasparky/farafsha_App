<?php

namespace App\Http\Controllers;

use App\Jobs\ProcessWahaWebhook;
use App\Models\WahaWebhookEvent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class WahaWebhookController
{
    public function __invoke(Request $request)
    {
        $expected = (string) config('waha.webhook_token');
        $provided = (string) $request->header('X-Waha-Webhook-Token');
        abort_if($expected === '' || !hash_equals($expected, $provided), 401);
        $data = $request->all();
        abort_unless(isset($data['event']) && is_array($data['payload'] ?? null), 422);
        $eventId = $data['id'] ?? 'sha256:'.hash('sha256', json_encode([$data['event'], $data['session'] ?? null, $data['payload']]));

        $row = DB::transaction(function () use ($data, $eventId) {
            return WahaWebhookEvent::firstOrCreate(['event_id' => $eventId], [
                'event_name' => Str::limit((string) $data['event'], 100, ''), 'session' => $data['session'] ?? null,
                'payload' => $data, 'received_at' => now(),
            ]);
        });
        if ($row->wasRecentlyCreated && !$row->processed_at) {
            try {
                ProcessWahaWebhook::dispatchSync($row->id);
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('WAHA Webhook sync processing notice: ' . $e->getMessage());
            }
        }
        return response()->json(['accepted' => true], 202);
    }
}
