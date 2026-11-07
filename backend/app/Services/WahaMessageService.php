<?php

namespace App\Services;

use App\Jobs\SendWahaMessage;
use App\Models\WahaMessage;
use App\Models\WahaSession;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WahaMessageService
{
    /**
     * تحسين وتوحيد أرقام الهواتف للصيغة الدولية المتوافقة مع واتساب
     */
    public static function normalizePhone(string $phone, string $defaultCountry = '20'): string
    {
        $digits = preg_replace('/\D+/', '', $phone);

        // إذا بدأ بصفر محلي مصري (مثل 010, 011, 012, 015) وكان 11 رقم -> أضف 20
        if (str_starts_with($digits, '01') && strlen($digits) === 11) {
            $digits = '20' . substr($digits, 1);
        }
        // إذا بدأ بصفر محلي خليجي (مثل 050, 055, 056) وكان 10 أرقام -> أضف 971 أو 966
        elseif (str_starts_with($digits, '05') && strlen($digits) === 10) {
            // افتراضياً للإمارات أو السعودية حسب الرقم
            $digits = '971' . substr($digits, 1);
        }
        // إذا بدأ بـ 00 -> احذف 00
        elseif (str_starts_with($digits, '00')) {
            $digits = substr($digits, 2);
        }

        return $digits;
    }

    /**
     * اكتشاف اسم جلسة واتساب المتصلة والنشطة تلقائياً (مع احترام الجلسة المحددة في الإعدادات)
     */
    public function getActiveSessionName(): string
    {
        // 1. فحص إذا تم تحديد جلسة مخصصة لـ OTP في لوحة التحكم
        $designated = \App\Models\SiteSetting::get('whatsapp_otp_session');
        if (!empty($designated)) {
            $session = WahaSession::where('name', $designated)->first();
            if ($session && $session->status === 'WORKING') {
                return $session->name;
            }
        }

        // 2. البحث عن أي جلسة بحالة WORKING في قاعدة البيانات المحلية
        $activeInDb = WahaSession::where('status', 'WORKING')->latest()->first();
        if ($activeInDb) {
            return $activeInDb->name;
        }

        // 2. الاستعلام المباشر من خادم WAHA عن أي جلسة متصلة
        try {
            $wahaClient = app(WahaClient::class);
            $sessions = $wahaClient->sessions();
            foreach ($sessions as $s) {
                if (($s['status'] ?? '') === 'WORKING') {
                    WahaSession::updateOrCreate(['name' => $s['name']], [
                        'status' => 'WORKING',
                        'phone' => data_get($s, 'me.id'),
                        'last_seen_at' => now(),
                    ]);
                    return $s['name'];
                }
            }
        } catch (\Throwable $e) {
            Log::debug('WAHA active session probe notice: ' . $e->getMessage());
        }

        return config('waha.default_session', 'default');
    }

    /**
     * إرسال رسالة واتساب فورياً بشكل متزامن وتسجيلها بقاعدة البيانات
     */
    public function sendTextSync(string $phone, string $text, ?string $sessionName = null): WahaMessage
    {
        $sessionName = $sessionName ?: $this->getActiveSessionName();
        $digits = self::normalizePhone($phone);

        if (strlen($digits) < 8 || strlen($digits) > 15) {
            throw new \InvalidArgumentException("رقم الهاتف غير صالح للإرسال عبر واتساب ({$phone}). يرجى التأكد من كتابته بالصيغة الدولية.");
        }

        if (empty(trim($text))) {
            throw new \InvalidArgumentException("نص الرسالة فارغ.");
        }

        $session = WahaSession::firstOrCreate(['name' => $sessionName]);
        $chatId = $digits . '@c.us';

        $wahaClient = app(WahaClient::class);

        try {
            $result = $wahaClient->sendText($sessionName, $chatId, $text);

            return WahaMessage::create([
                'waha_session_id' => $session->id,
                'direction' => 'out',
                'chat_id' => $chatId,
                'body' => $text,
                'status' => 'sent',
                'waha_message_id' => $result['id'] ?? null,
                'sent_at' => now(),
                'metadata' => $result,
            ]);
        } catch (\Throwable $e) {
            WahaMessage::create([
                'waha_session_id' => $session->id,
                'direction' => 'out',
                'chat_id' => $chatId,
                'body' => $text,
                'status' => 'failed',
                'last_error' => $e->getMessage(),
            ]);

            throw new \RuntimeException("تعذر إرسال رسالة الواتساب عبر جلسة '{$sessionName}': " . $e->getMessage());
        }
    }

    /**
     * جدولة إرسال رسالة عبر الطابور (Queue)
     */
    public function queueText(string $sessionName, string $phone, string $text, string $idempotencyKey): WahaMessage
    {
        $digits = self::normalizePhone($phone);
        abort_unless(strlen($digits) >= 8 && strlen($digits) <= 15, 422, 'Phone must be in international format.');
        abort_unless(mb_strlen($text) > 0 && mb_strlen($text) <= 4096, 422, 'Text length must be 1–4096 characters.');

        return DB::transaction(function () use ($sessionName, $digits, $text, $idempotencyKey) {
            $session = WahaSession::firstOrCreate(['name' => $sessionName]);
            $message = WahaMessage::firstOrCreate(['idempotency_key' => $idempotencyKey], [
                'waha_session_id' => $session->id,
                'direction' => 'out',
                'chat_id' => $digits . '@c.us',
                'body' => $text,
                'status' => 'queued',
            ]);

            if ($message->wasRecentlyCreated) {
                // إذا كان الاتصال متزامناً يتم الإرسال فوراً
                if (config('queue.default') === 'sync') {
                    SendWahaMessage::dispatchSync($message->id);
                } else {
                    DB::afterCommit(fn () => SendWahaMessage::dispatch($message->id)->onQueue(config('waha.queue')));
                }
            }

            return $message;
        });
    }
}
