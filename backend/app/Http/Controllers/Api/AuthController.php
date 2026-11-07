<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SocialProvider;
use App\Models\User;
use App\Services\WahaMessageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
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
     * توحيد صيغة رقم الهاتف للأرقام الدولية (E.164 digits)
     */
    protected function normalizePhone(string $phone, ?string $countryCode = '+20'): string
    {
        $digits = preg_replace('/\D+/', '', $phone);
        if (str_starts_with($digits, '01') && strlen($digits) === 11) {
            return '20' . substr($digits, 1);
        }
        if (str_starts_with($digits, '05') && strlen($digits) === 10) {
            return '966' . substr($digits, 1);
        }
        return $digits;
    }

    /**
     * إرسال رمز التحقق OTP لرقم الهاتف عبر واتساب (WAHA)
     */
    public function sendOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => 'required|string',
            'country_code' => 'nullable|string',
        ]);

        $normalized = $this->normalizePhone($validated['phone'], $validated['country_code'] ?? '+20');
        if (strlen($normalized) < 8 || strlen($normalized) > 15) {
            return response()->json([
                'status' => 'error',
                'message' => 'رقم الهاتف غير صالح، يرجى كتابة الرقم بالصيغة الدولية المعتمدة.',
            ], 422);
        }

        // توليد رمز تحقق عشوائي آمن مكون من 4 أرقام
        $otp = (string) random_int(1000, 9999);
        Cache::put("otp:phone:{$normalized}", $otp, 300); // صالح لمدة 5 دقائق

        // تجهيز نص رسالة الواتساب
        $messageText = "مرحباً بك في منصة وتطبيق فرفشة! 🎮🥳\nرمز التحقق الخاص بك هو: *{$otp}*\nصالح لمدة 5 دقائق. لا تشارك هذا الرمز مع أحد.";

        // إرسال الرسالة عبر خادم WAHA لواتساب
        try {
            $wahaService = app(WahaMessageService::class);
            $wahaService->queueText(
                config('waha.default_session', 'default'),
                $normalized,
                $messageText,
                (string) Str::uuid()
            );
        } catch (\Throwable $e) {
            Log::warning('WAHA sendOtp queue notice: ' . $e->getMessage());
        }

        $res = [
            'status' => 'success',
            'message' => 'تم إرسال رمز التحقق لهاتفك عبر واتساب بنجاح 📲',
            'expires_in_seconds' => 300,
        ];

        // في بيئة التطوير والاختبار المحلي، نقوم بإرفاق الكود لتسهيل الفحص
        if (app()->environment('local', 'testing')) {
            $res['debug_otp'] = $otp;
        }

        return response()->json($res);
    }

    /**
     * التحقق من كود الـ OTP المكون من 4 أرقام وتأكيد ملكية الهاتف
     */
    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => 'required|string',
            'otp' => 'required|string|size:4',
            'country_code' => 'nullable|string',
        ]);

        $normalized = $this->normalizePhone($validated['phone'], $validated['country_code'] ?? '+20');
        $cachedOtp = Cache::get("otp:phone:{$normalized}");

        $isValid = ($cachedOtp && $cachedOtp === $validated['otp'])
            || ($validated['otp'] === '1234' && app()->environment('local', 'testing'));

        if (!$isValid) {
            return response()->json([
                'status' => 'error',
                'message' => 'رمز التحقق غير صحيح أو انتهت صلاحيته، يرجى طلب رمز جديد.',
            ], 422);
        }

        // تم التحقق بنجاح
        Cache::forget("otp:phone:{$normalized}");
        Cache::put("verified_phone:{$normalized}", true, 3600); // موثق لمدة ساعة لإتمام التسجيل
        Cache::put("verified_phone:{$validated['phone']}", true, 3600);

        // هل المستخدم مسجل مسبقاً بهذا الهاتف؟
        $user = User::where('phone', $normalized)
            ->orWhere('phone', $validated['phone'])
            ->orWhere('email', $normalized . '@phone.lammah.app')
            ->first();

        if ($user) {
            $user->update([
                'phone' => $normalized,
                'phone_verified_at' => now(),
            ]);
            $token = $user->createToken('mobile_user_token')->plainTextToken;

            return response()->json([
                'status' => 'success',
                'message' => 'تم التحقق من هاتفك بنجاح، مرحباً بك مجدداً! 🎉',
                'token' => $token,
                'user' => $user,
                'is_new_user' => false,
            ]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'تم التحقق من هاتفك بنجاح! يمكنك الآن إكمال إنشاء حسابك.',
            'phone' => $normalized,
            'is_verified' => true,
            'is_new_user' => true,
        ]);
    }

    /**
     * إرسال رمز التحقق OTP للبريد الإلكتروني
     */
    public function sendEmailOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email|max:150',
        ]);

        $email = strtolower(trim($validated['email']));
        $otp = (string) random_int(1000, 9999);
        Cache::put("otp:email:{$email}", $otp, 300);

        // محاولة إرسال بريد
        try {
            \Illuminate\Support\Facades\Mail::raw(
                "رمز التحقق الخاص بك في منصة فرفشة هو: {$otp}\nصالح لمدة 5 دقائق.",
                function ($m) use ($email) {
                    $m->to($email)->subject('رمز التحقق في فرفشة 🎮');
                }
            );
        } catch (\Throwable $e) {
            Log::warning('sendEmailOtp notice: ' . $e->getMessage());
        }

        $res = [
            'status' => 'success',
            'message' => 'تم إرسال رمز التحقق إلى بريدك الإلكتروني بنجاح ✉️',
            'expires_in_seconds' => 300,
        ];

        if (app()->environment('local', 'testing')) {
            $res['debug_otp'] = $otp;
        }

        return response()->json($res);
    }

    /**
     * التحقق من رمز الـ OTP للبريد الإلكتروني
     */
    public function verifyEmailOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email|max:150',
            'otp' => 'required|string|size:4',
        ]);

        $email = strtolower(trim($validated['email']));
        $cachedOtp = Cache::get("otp:email:{$email}");

        $isValid = ($cachedOtp && $cachedOtp === $validated['otp'])
            || ($validated['otp'] === '1234' && app()->environment('local', 'testing'));

        if (!$isValid) {
            return response()->json([
                'status' => 'error',
                'message' => 'رمز التحقق للبريد غير صحيح أو انتهت صلاحيته.',
            ], 422);
        }

        Cache::forget("otp:email:{$email}");
        Cache::put("verified_email:{$email}", true, 3600);

        return response()->json([
            'status' => 'success',
            'message' => 'تم التحقق من بريدك الإلكتروني بنجاح!',
            'email' => $email,
            'is_verified' => true,
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

        $normalizedPhone = $this->normalizePhone($validated['phone']);
        $normalizedEmail = strtolower(trim($validated['email']));

        // التحقق من تكرار الهاتف
        if (User::where('phone', $normalizedPhone)->orWhere('phone', $validated['phone'])->exists()) {
            return response()->json([
                'status' => 'error',
                'message' => 'رقم الهاتف مسجل بالفعل بحساب آخر.',
            ], 422);
        }

        // التحقق الإلزامي: التأكد من توثيق رقم الهاتف أو البريد الإلكتروني عبر OTP
        $phoneVerified = (bool) (Cache::get("verified_phone:{$normalizedPhone}") || Cache::get("verified_phone:{$validated['phone']}"));
        $emailVerified = (bool) Cache::get("verified_email:{$normalizedEmail}");

        // إذا تم إرسال كود OTP مع طلب التسجيل مباشرة، نتحقق منه فوراً
        if (!$phoneVerified && !empty($request->otp)) {
            $cachedPhoneOtp = Cache::get("otp:phone:{$normalizedPhone}");
            if (($cachedPhoneOtp && $cachedPhoneOtp === (string)$request->otp) || ((string)$request->otp === '1234' && app()->environment('local', 'testing'))) {
                $phoneVerified = true;
                Cache::forget("otp:phone:{$normalizedPhone}");
            }
        }

        // لن يُنشأ أي حساب بدون التحقق المسبق
        if (!$phoneVerified && !$emailVerified) {
            return response()->json([
                'status' => 'error',
                'verification_required' => true,
                'message' => 'عذراً، يجب التحقق من رقم هاتفك أو بريدك الإلكتروني عبر رمز OTP أولاً قبل إتمام إنشاء الحساب.',
            ], 422);
        }

        $user = User::create([
            'name' => $validated['name'],
            'email' => $normalizedEmail,
            'phone' => $normalizedPhone,
            'phone_verified_at' => $phoneVerified ? now() : null,
            'email_verified_at' => $emailVerified ? now() : null,
            'password' => Hash::make($validated['password']),
            'avatar' => $validated['avatar'] ?? 'assets/images/av-ahmed.png',
            'level' => 1,
            'total_score' => 100,
            'wins_count' => 0,
            'games_played' => 0,
        ]);

        Cache::forget("verified_phone:{$normalizedPhone}");
        Cache::forget("verified_phone:{$validated['phone']}");
        Cache::forget("verified_email:{$normalizedEmail}");

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
