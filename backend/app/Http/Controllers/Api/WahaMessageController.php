<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WahaMessage;
use App\Services\WahaMessageService;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class WahaMessageController extends Controller
{
    public function store(Request $request, WahaMessageService $service)
    {
        $data = $request->validate([
            'session' => ['nullable','string','max:100'], 'phone' => ['required','string','max:30'],
            'text' => ['required','string','max:4096'], 'idempotency_key' => ['nullable','string','max:100'],
            'opt_in_confirmed' => ['required','accepted'],
        ]);
        $message = $service->queueText($data['session'] ?? config('waha.default_session'), $data['phone'], $data['text'],
            $data['idempotency_key'] ?? (string) Str::uuid());
        return response()->json($message, 202);
    }

    /**
     * إرسال رسالة واتساب للاعبين المسجلين في التطبيق
     */
    public function sendToUsers(Request $request, WahaMessageService $service)
    {
        $validated = $request->validate([
            'user_ids' => 'nullable|array',
            'user_ids.*' => 'integer|exists:users,id',
            'text' => 'required|string|max:4096',
            'session' => 'nullable|string|max:100',
        ]);

        $query = \App\Models\User::query()->whereNotNull('phone')->where('phone', '!=', '');
        if (!empty($validated['user_ids'])) {
            $query->whereIn('id', $validated['user_ids']);
        }

        $users = $query->get();
        $session = $validated['session'] ?? config('waha.default_session', 'default');
        $queuedCount = 0;

        foreach ($users as $user) {
            $cleanPhone = preg_replace('/\D+/', '', $user->phone);
            if (strlen($cleanPhone) >= 8) {
                $personalizedText = str_replace('{name}', $user->name, $validated['text']);
                $service->queueText($session, $cleanPhone, $personalizedText, (string) Str::uuid());
                $queuedCount++;
            }
        }

        return response()->json([
            'status' => 'success',
            'message' => "تمت جدولة إرسال رسالة الواتساب إلى {$queuedCount} لاعب مسجل بنجاح.",
            'queued_count' => $queuedCount,
        ]);
    }

    public function show(WahaMessage $message) { return response()->json($message); }
}
