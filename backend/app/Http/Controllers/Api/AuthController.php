<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * تسجيل الدخول الفوري كضيف (Guest Play) بدون اشتراط حساب
     */
    public function guestLogin(Request $request): JsonResponse
    {
        $guestId = Str::random(8);
        $user = User::create([
            'name' => 'ضيف ' . substr($guestId, 0, 4),
            'email' => "guest_{$guestId}@lammah.app",
            'password' => Hash::make(Str::random(16)),
            'avatar' => 'av-ahmed',
            'level' => 1,
            'total_score' => 0,
            'is_admin' => false,
        ]);

        $token = $user->createToken('mobile_guest_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'تم الدخول كضيف بنجاح',
            'token' => $token,
            'user' => $user,
        ]);
    }

    /**
     * إرسال رمز التحقق OTP لرقم الهاتف
     */
    public function sendOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => 'required|string',
            'country_code' => 'nullable|string|default:+20',
        ]);

        // رمز تجريبي للتطوير المحلي 1234
        $otp = '1234';

        return response()->json([
            'status' => 'success',
            'message' => 'تم إرسال رمز التحقق لهاتفك بنجاح',
            'debug_otp' => $otp,
            'expires_in_seconds' => 60,
        ]);
    }

    /**
     * التحقق من كود الـ OTP المكون من 4 أرقام
     */
    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => 'required|string',
            'otp' => 'required|string|size:4',
        ]);

        if ($validated['otp'] !== '1234') {
            return response()->json([
                'status' => 'error',
                'message' => 'رمز التحقق غير صحيح، يرجى المحاولة مرة أخرى.',
            ], 422);
        }

        $email = $validated['phone'] . '@phone.lammah.app';
        $user = User::firstOrCreate(
            ['email' => $email],
            [
                'name' => 'لاعب جديد',
                'password' => Hash::make(Str::random(16)),
                'avatar' => 'av-ahmed',
                'level' => 1,
                'total_score' => 0,
            ]
        );

        $token = $user->createToken('mobile_user_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'تم التحقق بنجاح',
            'token' => $token,
            'user' => $user,
            'is_new_user' => $user->wasRecentlyCreated,
        ]);
    }

    /**
     * إكمال ملف التسجيل (اختيار الأفاتار، الاسم المستعار، اللهجة)
     */
    public function registerProfile(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:40',
            'avatar' => 'required|string',
            'preferred_dialect' => 'nullable|string',
        ]);

        $user = $request->user();
        if ($user) {
            $user->update([
                'name' => $validated['name'],
                'avatar' => $validated['avatar'],
            ]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'تم تحديث بياناتك بنجاح',
            'user' => $user,
        ]);
    }

    /**
     * جلب بيانات الملف الشخصي وإحصائيات اللاعب
     */
    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'status' => 'success',
            'user' => $request->user(),
        ]);
    }
}
