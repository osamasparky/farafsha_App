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
    public function show(WahaMessage $message) { return response()->json($message); }
}
