<?php

namespace App\Services;

use App\Jobs\SendWahaMessage;
use App\Models\WahaMessage;
use App\Models\WahaSession;
use Illuminate\Support\Facades\DB;

class WahaMessageService
{
    public function queueText(string $sessionName, string $phone, string $text, string $idempotencyKey): WahaMessage
    {
        // Accept E.164 digits; normalize to WAHA's documented phone@c.us form.
        $digits = preg_replace('/\D+/', '', $phone);
        abort_unless(strlen($digits) >= 8 && strlen($digits) <= 15, 422, 'Phone must be in international format.');
        abort_unless(mb_strlen($text) > 0 && mb_strlen($text) <= 4096, 422, 'Text length must be 1–4096 characters.');

        return DB::transaction(function () use ($sessionName, $digits, $text, $idempotencyKey) {
            $session = WahaSession::firstOrCreate(['name' => $sessionName]);
            $message = WahaMessage::firstOrCreate(['idempotency_key' => $idempotencyKey], [
                'waha_session_id' => $session->id, 'direction' => 'out', 'chat_id' => $digits.'@c.us',
                'body' => $text, 'status' => 'queued',
            ]);
            if ($message->wasRecentlyCreated) {
                DB::afterCommit(fn () => SendWahaMessage::dispatch($message->id)->onQueue(config('waha.queue')));
            }
            return $message;
        });
    }
}
