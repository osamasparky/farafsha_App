<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Auth\SocialAuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class SocialAuthController extends Controller
{
    public function __construct(
        protected SocialAuthService $socialAuthService
    ) {}

    /**
     * POST /api/v1/auth/social/{provider}
     */
    public function authenticate(Request $request, string $provider): JsonResponse
    {
        $provider = strtolower($provider);
        if (!in_array($provider, ['google', 'apple', 'facebook', 'twitter', 'linkedin'])) {
            return response()->json([
                'success' => false,
                'message' => "مزود الخدمة '{$provider}' غير مدعوم.",
            ], 422);
        }

        $validator = Validator::make($request->all(), [
            'id_token' => 'nullable|string',
            'access_token' => 'nullable|string',
            'authorization_code' => 'nullable|string',
            'code_verifier' => 'nullable|string',
            'redirect_uri' => 'nullable|string',
            'name' => 'nullable|string|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'بيانات الاعتماد غير مكتملة.',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $currentUser = $request->user('sanctum');
            $result = $this->socialAuthService->authenticate($provider, $request->all(), $currentUser);
            $user = $result['user'];

            return response()->json([
                'success' => true,
                'message' => 'تم تسجيل الدخول بنجاح 🎉',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->name,
                        'email' => $user->email,
                        'phone' => $user->phone,
                        'avatar' => $user->avatar,
                        'level' => $user->level ?? 1,
                        'total_score' => $user->total_score ?? 0,
                        'wins_count' => $user->wins_count ?? 0,
                        'games_played' => $user->games_played ?? 0,
                    ],
                    'token' => $result['token'],
                    'token_type' => 'Bearer',
                    'is_new_user' => $result['is_new_user'] ?? false,
                    'linked' => $result['linked'] ?? false,
                ],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => collect($e->errors())->flatten()->first() ?? 'فشل التحقق من صحة بيانات الدخول.',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Throwable $e) {
            report($e);
            return response()->json([
                'success' => false,
                'message' => 'حدث خطأ أثناء معالجة تسجيل الدخول: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/v1/auth/me
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'avatar' => $user->avatar,
                    'level' => $user->level ?? 1,
                    'total_score' => $user->total_score ?? 0,
                    'wins_count' => $user->wins_count ?? 0,
                    'games_played' => $user->games_played ?? 0,
                    'linked_providers' => $user->socialAccounts()->pluck('provider'),
                ],
            ],
        ]);
    }

    /**
     * POST /api/v1/auth/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user && $user->currentAccessToken()) {
            $user->currentAccessToken()->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'تم تسجيل الخروج بنجاح.',
        ]);
    }

    /**
     * POST /api/v1/auth/logout-all
     */
    public function logoutAll(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user) {
            $user->tokens()->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'تم تسجيل الخروج من كافة الأجهزة بنجاح.',
        ]);
    }

    /**
     * POST /api/v1/auth/unlink/{provider}
     */
    public function unlink(Request $request, string $provider): JsonResponse
    {
        try {
            $this->socialAuthService->unlink($request->user(), strtolower($provider));

            return response()->json([
                'success' => true,
                'message' => "تم إلغاء ربط حساب {$provider} بنجاح.",
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => collect($e->errors())->flatten()->first(),
            ], 422);
        }
    }
}

