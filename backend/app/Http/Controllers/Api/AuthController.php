<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SocialProvider;
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
     * جلب قائمة مزودي تسجيل الدخول والتواصل المعروضين في التطبيق
     */
    public function getSocialProviders(): JsonResponse
    {
        $providers = SocialProvider::orderBy('sort_order', 'asc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $providers->map(function ($p) {
                return [
                    'id' => $p->id,
                    'provider' => $p->provider,
                    'name' => $p->name,
                    'is_enabled' => (bool) $p->is_enabled,
                    'client_id' => $p->client_id,
                    'icon' => $p->icon,
                ];
            }),
        ]);
    }

    /**
     * تسجيل الدخول بواسطة (البريد الإلكتروني أو رقم الهاتف) وكلمة المرور
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'identifier' => 'required|string',
            'password' => 'required|string',
        ]);

        $identifier = trim($validated['identifier']);
        $password = $validated['password'];

        // البحث إما بالبريد الإلكتروني أو برقم الهاتف
        $user = User::where('email', $identifier)
            ->orWhere('phone', $identifier)
            ->first();

        if (!$user || !Hash::check($password, $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => 'بيانات الدخول غير صحيحة، يرجى التأكد من البريد أو رقم الهاتف وكلمة المرور.',
            ], 422);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'تم تسجيل الدخول بنجاح! 🎉',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'avatar' => $user->avatar ?? 'assets/images/av-ahmed.png',
                'total_points' => $user->total_score ?? 100,
                'wins' => $user->wins_count ?? 0,
                'games_played' => $user->games_played ?? 0,
            ],
        ]);
    }

    /**
     * إنشاء حساب جديد (الاسم، رقم الهاتف، البريد الإلكتروني، كلمة المرور)
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|min:2|max:100',
            'email' => 'required|email|max:150|unique:users,email',
            'phone' => 'required|string|min:8|max:20',
            'password' => 'required|string|min:6',
            'avatar' => 'nullable|string|max:255',
        ], [
            'email.unique' => 'البريد الإلكتروني مسجل بالفعل بحساب آخر.',
            'password.min' => 'يجب ألا تقل كلمة المرور عن 6 أحرف.',
            'name.required' => 'الاسم مطلوب.',
            'phone.required' => 'رقم الهاتف مطلوب.',
        ]);

        // التحقق من تكرار الهاتف
        if (User::where('phone', $validated['phone'])->exists()) {
            return response()->json([
                'status' => 'error',
                'message' => 'رقم الهاتف مسجل بالفعل بحساب آخر.',
            ], 422);
        }

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'phone' => $validated['phone'],
            'password' => Hash::make($validated['password']),
            'avatar' => $validated['avatar'] ?? 'assets/images/av-ahmed.png',
            'level' => 1,
            'total_score' => 100,
            'wins_count' => 0,
            'games_played' => 0,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'تم إنشاء حسابك بنجاح! مرحباً بك في فرفشة 🎉',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'avatar' => $user->avatar,
                'total_points' => $user->total_score,
                'wins' => $user->wins_count,
                'games_played' => $user->games_played,
            ],
        ]);
    }

    /**
     * تسجيل الدخول عبر وسائل التواصل الاجتماعي (Google, Apple, Facebook) مع التحقق من الاسم والهاتف والإيميل
     */
    public function socialLogin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'provider' => 'required|string|in:google,apple,facebook',
            'provider_id' => 'nullable|string',
            'name' => 'required|string|max:100',
            'email' => 'required|email',
            'phone' => 'nullable|string|max:20',
            'avatar' => 'nullable|string',
        ]);

        $provider = SocialProvider::where('provider', $validated['provider'])->first();
        if ($provider && !$provider->is_enabled) {
            return response()->json([
                'status' => 'error',
                'message' => 'تسجيل الدخول عبر ' . $provider->name . ' غير مفعل حالياً من لوحة التحكم.',
            ], 403);
        }

        $user = User::where('email', $validated['email'])->first();

        if ($user) {
            if (!empty($validated['phone']) && empty($user->phone)) {
                $user->phone = $validated['phone'];
            }
            if (!empty($validated['name'])) {
                $user->name = $validated['name'];
            }
            $user->save();
        } else {
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'avatar' => $validated['avatar'] ?? 'assets/images/av-ahmed.png',
                'password' => Hash::make(Str::random(24)),
                'level' => 1,
                'total_score' => 100,
                'wins_count' => 0,
                'games_played' => 0,
            ]);
        }

        $token = $user->createToken('social_user_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'تم تسجيل الدخول بنجاح عبر ' . ucfirst($validated['provider']),
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'avatar' => $user->avatar,
                'total_points' => $user->total_score ?? 100,
                'wins' => $user->wins_count ?? 0,
                'games_played' => $user->games_played ?? 0,
            ],
        ]);
    }

    /**
     * تسجيل الخروج وإبطال التوكن
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user) {
            $user->tokens()->delete();
        }

        return response()->json([
            'status' => 'success',
            'message' => 'تم تسجيل الخروج بنجاح.',
        ]);
    }

    /**
     * تسجيل الدخول المباشر بالبريد الإلكتروني
     */
    public function loginByEmail(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'name' => 'nullable|string|max:100',
        ]);

        $user = User::firstOrCreate(
            ['email' => $validated['email']],
            [
                'name' => $validated['name'] ?? explode('@', $validated['email'])[0],
                'avatar' => 'assets/images/av-ahmed.png',
                'password' => Hash::make(Str::random(16)),
                'level' => 1,
                'total_score' => 100,
            ]
        );

        $token = $user->createToken('email_user_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'تم تسجيل الدخول بنجاح',
            'token' => $token,
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
