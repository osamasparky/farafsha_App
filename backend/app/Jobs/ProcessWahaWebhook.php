<?php

namespace App\Jobs;

use App\Models\WahaMessage;
use App\Models\WahaSession;
use App\Models\WahaWebhookEvent;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;

class ProcessWahaWebhook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
    public int $tries = 8;
    public array $backoff = [5, 15, 45, 120, 300];
    public function __construct(public int $eventRowId) {}

    public function handle(): void
    {
        $event = WahaWebhookEvent::findOrFail($this->eventRowId);
        if ($event->processed_at) return;
        $data = $event->payload;
        $p = $data['payload'] ?? [];
        DB::transaction(function () use ($event, $data, $p) {
            if ($event->event_name === 'session.status' && $event->session) {
                $name = $event->session;
                WahaSession::updateOrCreate(['name' => $name], [
                    'status' => $p['status'] ?? 'UNKNOWN', 'phone' => data_get($data, 'me.id'), 'last_seen_at' => now(),
                ]);
            }
            if (in_array($event->event_name, ['message', 'message.any'], true) && !empty($p['id'])) {
                $chatId = (string) ($p['from'] ?? $p['to'] ?? 'unknown');

                // تجاهل حالات الواتساب والرسائل الجماعية الدعائية (WhatsApp Status / Broadcasts)
                $isBroadcast = str_contains($chatId, 'broadcast') || !empty($p['broadcast']);
                if (! $isBroadcast) {
                    $session = WahaSession::firstOrCreate(['name' => $event->session ?? config('waha.default_session')]);
                    // Preserve message.any for sent-state reconciliation; ignore duplicate engine echoes.
                    WahaMessage::firstOrCreate(['waha_message_id' => $p['id']], [
                        'waha_session_id' => $session->id, 'direction' => !empty($p['fromMe']) ? 'out' : 'in',
                        'chat_id' => $chatId, 'body' => $p['body'] ?? '',
                        'status' => !empty($p['fromMe']) ? 'sent' : 'received', 'metadata' => $p,
                        'sent_at' => isset($p['timestamp']) ? now()->setTimestamp((int) $p['timestamp']) : null,
                    ]);
                }
            }
            if ($event->event_name === 'message.ack' && !empty($p['id'])) {
                $state = match ((int) ($p['ack'] ?? 0)) { -1 => 'failed', 1, 2 => 'delivered', 3, 4 => 'read', default => null };
                if ($state) WahaMessage::where('waha_message_id', $p['id'])->update(['status' => $state]);
            }
            $event->update(['processed_at' => now(), 'processing_error' => null]);
        });
    }

    public function failed(\Throwable $e): void
    {
        WahaWebhookEvent::whereKey($this->eventRowId)->update(['processing_error' => mb_substr($e->getMessage(), 0, 2000)]);
    }
}
