<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GameController;
use App\Http\Controllers\Api\LeaderboardController;
use App\Http\Controllers\Api\RoomController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// مسارات المصادقة والهاتف واللعب كضيف
Route::prefix('auth')->group(function () {
    Route::post('/guest', [AuthController::class, 'guestLogin']);
    Route::post('/send-otp', [AuthController::class, 'sendOtp']);
    Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
    Route::post('/register', [AuthController::class, 'registerProfile'])->middleware('auth:sanctum');
    Route::get('/me', [AuthController::class, 'me'])->middleware('auth:sanctum');
});

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// مسارات الألعاب والمحتوى
Route::prefix('games')->group(function () {
    Route::get('/', [GameController::class, 'index']);
    Route::get('/{slug}', [GameController::class, 'show']);
    Route::get('/{slug}/cards', [GameController::class, 'getCards']);
});

// مسارات غرف اللعب أونلاين
Route::prefix('rooms')->group(function () {
    Route::post('/', [RoomController::class, 'store']);
    Route::get('/{code}', [RoomController::class, 'show']);
    Route::post('/{code}/join', [RoomController::class, 'join']);
    Route::post('/{code}/start', [RoomController::class, 'start']);
    Route::post('/{code}/answer', [RoomController::class, 'answer']);
});

// مسارات لوحة الشرف
Route::get('/leaderboard', [LeaderboardController::class, 'index']);
