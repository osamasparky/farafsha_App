<?php

use App\Http\Controllers\Api\AppContentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\SocialController;
use App\Http\Controllers\Api\GameController;
use App\Http\Controllers\Api\RoomController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// مسارات المصادقة والهاتف واللعب كضيف ووسائل التواصل
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
    Route::get('/social-providers', [AuthController::class, 'getSocialProviders']);
    Route::post('/social-login', [AuthController::class, 'socialLogin'])->middleware('throttle:15,1');
    Route::post('/social-register', [AuthController::class, 'socialRegister'])->middleware('throttle:15,1');
    Route::post('/guest', [AuthController::class, 'guestLogin'])->middleware('throttle:20,1');
    Route::post('/send-otp', [AuthController::class, 'sendOtp'])->middleware('throttle:6,1');
    Route::post('/verify-otp', [AuthController::class, 'verifyOtp'])->middleware('throttle:10,1');
    Route::post('/send-email-otp', [AuthController::class, 'sendEmailOtp'])->middleware('throttle:6,1');
    Route::post('/verify-email-otp', [AuthController::class, 'verifyEmailOtp'])->middleware('throttle:10,1');
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:6,1');
    Route::post('/verify-reset-otp', [AuthController::class, 'verifyResetOtp'])->middleware('throttle:10,1');
    Route::post('/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:6,1');
    Route::post('/change-password', [AuthController::class, 'changePassword'])->middleware('auth:sanctum');
    Route::post('/request-deletion', [AuthController::class, 'requestAccountDeletion'])->middleware('auth:sanctum');
    Route::post('/login-by-email', [AuthController::class, 'loginByEmail'])->middleware('throttle:10,1');
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
    Route::post('/matchmake', [RoomController::class, 'matchmake']);
    Route::get('/{code}', [RoomController::class, 'show']);
    Route::get('/{code}/state', [RoomController::class, 'state']);
    Route::post('/{code}/join', [RoomController::class, 'join']);
    Route::post('/{code}/add-bot', [RoomController::class, 'addBot']);
    Route::post('/{code}/start', [RoomController::class, 'start']);
    Route::post('/{code}/answer', [RoomController::class, 'answer']);
    Route::get('/{code}/voice-token', [RoomController::class, 'getVoiceToken']);
    Route::post('/{code}/next-round', [RoomController::class, 'nextRound']);
    Route::post('/{code}/timeout', [RoomController::class, 'timeout']);
    Route::post('/{code}/finish', [RoomController::class, 'finish']);
    Route::post('/{code}/leave', [RoomController::class, 'leave']);

    // مسارات لعبة الدومينو الأونلاين
    Route::post('/{code}/domino/play', [\App\Http\Controllers\Api\DominoController::class, 'play']);
    Route::post('/{code}/domino/draw', [\App\Http\Controllers\Api\DominoController::class, 'draw']);
    Route::post('/{code}/domino/pass', [\App\Http\Controllers\Api\DominoController::class, 'pass']);
    Route::post('/{code}/domino/timeout', [\App\Http\Controllers\Api\DominoController::class, 'timeout']);
    Route::post('/{code}/domino/next-round', [\App\Http\Controllers\Api\DominoController::class, 'nextRound']);
});

// مسارات المحتوى والإنتاجية الجديدة
Route::get('/gameplay-modes', function () {
    $modes = \App\Models\GameplayMode::where('is_active', true)
        ->orderBy('sort_order', 'asc')
        ->get();
    return response()->json($modes);
});
Route::get('/banners', [AppContentController::class, 'banners']);
Route::get('/dialects', [AppContentController::class, 'dialects']);
Route::get('/leaderboard', [AppContentController::class, 'leaderboard']);
Route::post('/leaderboard/record', [AppContentController::class, 'recordScore'])->middleware('auth:sanctum');
Route::get('/notifications', [AppContentController::class, 'notifications']);
Route::get('/pages/{slug}', [AppContentController::class, 'page']);
Route::get('/contact-info', [AppContentController::class, 'contactInfo']);
Route::get('/badges', [AppContentController::class, 'badges']);
Route::get('/levels', [AppContentController::class, 'levels']);
Route::get('/profile', [AppContentController::class, 'profile']);
Route::post('/profile/update', [AppContentController::class, 'updateProfile']);
Route::get('/app-version', [AppContentController::class, 'checkVersion']);

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

// مسارات الأصدقاء والشلل والمنافسة الاجتماعية
Route::middleware('auth:sanctum')->prefix('social')->group(function () {
    Route::post('/presence', [SocialController::class, 'presence']);
    Route::post('/username', [SocialController::class, 'updateUsername']);
    Route::get('/users/search', [SocialController::class, 'searchUsers']);
    Route::get('/friends', [SocialController::class, 'friends']);
    Route::post('/friends/request', [SocialController::class, 'sendFriendRequest']);
    Route::post('/friends/respond', [SocialController::class, 'respondFriendRequest']);
    Route::get('/friends/leaderboard', [SocialController::class, 'friendsLeaderboard']);
    Route::get('/crews', [SocialController::class, 'crews']);
    Route::post('/crews', [SocialController::class, 'createCrew']);
    Route::post('/crews/join', [SocialController::class, 'joinCrew']);
    Route::get('/crews/{id}', [SocialController::class, 'crewDetails']);
    Route::post('/crews/{id}/invite', [SocialController::class, 'inviteFriendToCrew']);
});

// مسارات تكامل واتساب عبر WAHA (جلسات، رسائل، ويب هوك)
require __DIR__ . '/waha.php';
