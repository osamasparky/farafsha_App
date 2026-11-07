<?php

use App\Http\Controllers\Api\WahaMessageController;
use App\Http\Controllers\Api\WahaSessionController;
use App\Http\Controllers\WahaWebhookController;
use Illuminate\Support\Facades\Route;

Route::post('/webhooks/waha', WahaWebhookController::class)->middleware('throttle:120,1');

Route::middleware(['auth:sanctum', 'throttle:60,1'])->prefix('wa')->group(function () {
    Route::get('/sessions', [WahaSessionController::class, 'index']);
    Route::post('/sessions', [WahaSessionController::class, 'store']);
    Route::get('/sessions/{name}', [WahaSessionController::class, 'show']);
    Route::post('/sessions/{name}/start', [WahaSessionController::class, 'start']);
    Route::post('/sessions/{name}/stop', [WahaSessionController::class, 'stop']);
    Route::get('/sessions/{name}/qr', [WahaSessionController::class, 'qr']);
    Route::post('/messages', [WahaMessageController::class, 'store'])->middleware('throttle:30,1');
    Route::post('/messages/send-to-users', [WahaMessageController::class, 'sendToUsers'])->middleware('throttle:30,1');
    Route::get('/messages/{message}', [WahaMessageController::class, 'show']);
});
