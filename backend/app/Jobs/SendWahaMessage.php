<?php

namespace App\Jobs;

use App\Models\WahaMessage;
use App\Services\WahaClient;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;

class SendWahaMessage implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
    public int $tries = 5;
    public int $timeout = 35;

    public function __construct(public int $messageId) {}

    public function handle(WahaClient $client): void
    {
        $message = WahaMessage::with('session')->findOrFail($this->messageId);
        if (in_array($message->status, ['sent', 'delivered', 'read'], true)) return;
        $message->update(['status' => 'sending', 'last_error' => null]);
        try {
            $result = $client->sendText($message->session->name, $message->chat_id, $message->body);
            $message->update(['status' => 'sent', 'waha_message_id' => $result['id'] ?? null, 'sent_at' => now(), 'metadata' => $result]);
        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            // Could have reached WhatsApp despite the timeout; require reconciliation.
            $message->update(['status' => 'unknown', 'last_error' => 'Transport outcome ambiguous; reconcile before retry.']);
            report($e);
        } catch (\Illuminate\Http\Client\RequestException $e) {
            $status = $e->response?->status();
            $message->update(['status' => 'failed', 'last_error' => mb_substr($e->getMessage(), 0, 2000)]);
            // 429 is a definite rejection and safe to retry. A 5xx may follow a successful send.
            if ($status === 429 && $this->attempts() < config('waha.max_attempts')) {
                $message->update(['status' => 'queued']);
                $this->release(min(300, 15 * (2 ** ($this->attempts() - 1))));
            }
        }
    }
}
