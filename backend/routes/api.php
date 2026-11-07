<?php

use App\Http\Controllers\Api\AppContentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GameController;
use App\Http\Controllers\Api\RoomController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// مسارات المصادقة والهاتف واللعب كضيف ووسائل التواصل
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
    Route::get('/social-providers', [AuthController::class, 'getSocialProviders']);
    Route::post('/social-login', [AuthController::class, 'socialLogin']);
    Route::post('/social-register', [AuthController::class, 'socialRegister']);
    Route::post('/guest', [AuthController::class, 'guestLogin']);
    Route::post('/send-otp', [AuthController::class, 'sendOtp']);
    Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
    Route::post('/send-email-otp', [AuthController::class, 'sendEmailOtp']);
    Route::post('/verify-email-otp', [AuthController::class, 'verifyEmailOtp']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/verify-reset-otp', [AuthController::class, 'verifyResetOtp']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('/change-password', [AuthController::class, 'changePassword'])->middleware('auth:sanctum');
    Route::post('/request-deletion', [AuthController::class, 'requestAccountDeletion'])->middleware('auth:sanctum');
    Route::post('/login-by-email', [AuthController::class, 'loginByEmail']);
    Route::post('/register-profile', [AuthController::class, 'registerProfile'])->middleware('auth:sanctum');
    Route::get('/me', [AuthController::class, 'me'])->middleware('auth:sanctum');
});

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/user/request-deletion', [AuthController::class, 'requestAccountDeletion'])->middleware('auth:sanctum');

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
    Route::get('/{code}/state', [RoomController::class, 'state']);
    Route::post('/{code}/join', [RoomController::class, 'join']);
    Route::post('/{code}/start', [RoomController::class, 'start']);
    Route::post('/{code}/answer', [RoomController::class, 'answer']);
    Route::post('/{code}/next-round', [RoomController::class, 'nextRound']);
    Route::post('/{code}/timeout', [RoomController::class, 'timeout']);
    Route::post('/{code}/finish', [RoomController::class, 'finish']);
    Route::post('/{code}/leave', [RoomController::class, 'leave']);
});

// مسارات المحتوى والإنتاجية الجديدة
Route::get('/banners', [AppContentController::class, 'banners']);
Route::get('/dialects', [AppContentController::class, 'dialects']);
Route::get('/leaderboard', [AppContentController::class, 'leaderboard']);
Route::get('/notifications', [AppContentController::class, 'notifications']);
Route::get('/pages/{slug}', [AppContentController::class, 'page']);
Route::get('/contact-info', [AppContentController::class, 'contactInfo']);
Route::get('/badges', [AppContentController::class, 'badges']);
Route::get('/levels', [AppContentController::class, 'levels']);
Route::get('/profile', [AppContentController::class, 'profile']);
Route::post('/profile/update', [AppContentController::class, 'updateProfile']);

// Social Authentication Architecture (v1 API)
Route::prefix('v1/auth')->group(function () {
    Route::get('/social-providers', [AuthController::class, 'getSocialProviders']);
    Route::post('/social/{provider}', [\App\Http\Controllers\Api\V1\SocialAuthController::class, 'authenticate']);
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [\App\Http\Controllers\Api\V1\SocialAuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\Api\V1\SocialAuthController::class, 'logout']);
        Route::post('/logout-all', [\App\Http\Controllers\Api\V1\SocialAuthController::class, 'logoutAll']);
        Route::post('/unlink/{provider}', [\App\Http\Controllers\Api\V1\SocialAuthController::class, 'unlink']);
    });
});

// مسارات تكامل واتساب عبر WAHA (جلسات، رسائل، ويب هوك)
require __DIR__ . '/waha.php';
