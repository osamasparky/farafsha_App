<?php

namespace App\Services\Auth;

use App\Models\SocialAccount;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class SocialAuthService
{
    public function __construct(
        protected GoogleTokenVerifier $googleVerifier,
        protected AppleTokenVerifier $appleVerifier,
        protected FacebookTokenVerifier $facebookVerifier,
        protected TwitterTokenVerifier $twitterVerifier,
        protected LinkedInTokenVerifier $linkedInVerifier,
    ) {}

    /**
     * التحقق من الرمز وتنفيذ تسجيل الدخول أو إنشاء الحساب
     */
    public function authenticate(string $provider, array $payload, ?User $authenticatedUser = null): array
    {
        $verifiedData = $this->verifyProviderCredential($provider, $payload);

        $providerUserId = $verifiedData['provider_user_id'];
        $providerEmail = $verifiedData['email'] ?? null;
        $name = $verifiedData['name'] ?? 'مستخدم فرفشة';
        $avatar = $verifiedData['avatar'] ?? null;
        $metadata = $verifiedData['metadata'] ?? [];

        return DB::transaction(function () use ($provider, $providerUserId, $providerEmail, $name, $avatar, $metadata, $authenticatedUser) {
            // البحث عن حساب وسيلة التواصل
            $socialAccount = SocialAccount::where('provider', $provider)
                ->where('provider_user_id', $providerUserId)
                ->first();

            // سيناريو 1: المستخدم مسجل دخول بالفعل ويريد ربط الحساب (Account Linking)
            if ($authenticatedUser) {
                if ($socialAccount && $socialAccount->user_id !== $authenticatedUser->id) {
                    throw ValidationException::withMessages([
                        'provider' => ['هذا الحساب مرتبط بالفعل بمستخدم آخر في فرفشة.'],
                    ]);
                }

                if (!$socialAccount) {
                    $socialAccount = SocialAccount::create([
                        'user_id' => $authenticatedUser->id,
                        'provider' => $provider,
                        'provider_user_id' => $providerUserId,
                        'provider_email' => $providerEmail,
                        'provider_metadata' => $metadata,
                    ]);
                }

                return [
                    'user' => $authenticatedUser,
                    'token' => $authenticatedUser->createToken('social-link')->plainTextToken,
                    'is_new_user' => false,
                    'linked' => true,
                ];
            }

            // سيناريو 2: الحساب موجود مسبقاً -> تسجيل دخول مباشر
            if ($socialAccount) {
                $user = $socialAccount->user;
                if (!$user) {
                    // في حال حذف المستخدم، نعيد ربطه
                    $user = $this->findOrCreateUser($providerEmail, $name, $avatar);
                    $socialAccount->update(['user_id' => $user->id]);
                } else {
                    // تحديث الميتاداتا
                    $socialAccount->update([
                        'provider_email' => $providerEmail ?? $socialAccount->provider_email,
                        'provider_metadata' => array_merge($socialAccount->provider_metadata ?? [], $metadata),
                    ]);
                }

                $token = $user->createToken('social-login')->plainTextToken;

                return [
                    'user' => $user,
                    'token' => $token,
                    'is_new_user' => false,
                ];
            }

            // سيناريو 3: حساب جديد غير مسجل -> ربطه بالبريد الإلكتروني الموثق أو إنشاء حساب جديد
            $user = null;
            $isNew = false;

            if (!empty($providerEmail)) {
                $user = User::where('email', $providerEmail)->first();
            }

            if (!$user) {
                // توليد بريد احتياطي موثق في حال عدم توفره من المزود (مثل Twitter)
                $safeEmail = !empty($providerEmail) ? $providerEmail : "{$provider}_{$providerUserId}@farfasha.app";

                $user = User::create([
                    'name' => $name,
                    'email' => $safeEmail,
                    'phone' => null,
                    'password' => Hash::make(Str::random(32)),
                    'avatar' => $avatar ?? 'assets/images/farfasha_logo.png',
                    'level' => 1,
                    'total_score' => 0,
                    'wins_count' => 0,
                    'games_played' => 0,
                ]);
                $isNew = true;
            }

            // إنشاء سجل SocialAccount
            SocialAccount::create([
                'user_id' => $user->id,
                'provider' => $provider,
                'provider_user_id' => $providerUserId,
                'provider_email' => $providerEmail,
                'provider_metadata' => $metadata,
            ]);

            $token = $user->createToken('social-login')->plainTextToken;

            return [
                'user' => $user,
                'token' => $token,
                'is_new_user' => $isNew,
            ];
        });
    }

    /**
     * فك ارتباط حساب وسيلة تواصل بأمان
     */
    public function unlink(User $user, string $provider): void
    {
        $count = $user->socialAccounts()->count();
        $hasPassword = !empty($user->password);

        if ($count <= 1 && !$hasPassword) {
            throw ValidationException::withMessages([
                'provider' => ['لا يمكنك إلغاء ربط وسيلة الدخول الوحيدة لحسابك قبل تعيين كلمة مرور أو ربط وسيلة أخرى.'],
            ]);
        }

        $user->socialAccounts()->where('provider', $provider)->delete();
    }

    /**
     * التحقق من بيانات الاعتماد المستلمة عبر كل مزود
     */
    protected function verifyProviderCredential(string $provider, array $payload): array
    {
        return match ($provider) {
            'google' => $this->googleVerifier->verify(
                $payload['id_token'] ?? throw ValidationException::withMessages(['id_token' => ['رمز Google ID مطلوب.']])
            ),
            'apple' => $this->appleVerifier->verify(
                $payload['id_token'] ?? throw ValidationException::withMessages(['id_token' => ['رمز Apple ID مطلوب.']]),
                $payload['name'] ?? null
            ),
            'facebook' => $this->facebookVerifier->verify(
                $payload['access_token'] ?? throw ValidationException::withMessages(['access_token' => ['رمز وصول Facebook مطلوب.']])
            ),
            'twitter' => $this->twitterVerifier->verify(
                $payload['authorization_code'] ?? throw ValidationException::withMessages(['authorization_code' => ['رمز تفويض X مطلوب.']]),
                $payload['code_verifier'] ?? throw ValidationException::withMessages(['code_verifier' => ['مُحقق رمز PKCE مطلوب.']]),
                $payload['redirect_uri'] ?? throw ValidationException::withMessages(['redirect_uri' => ['رابط إعادة التوجيه مطلوب.']])
            ),
            'linkedin' => $this->linkedInVerifier->verify(
                $payload['authorization_code'] ?? throw ValidationException::withMessages(['authorization_code' => ['رمز تفويض LinkedIn مطلوب.']]),
                $payload['redirect_uri'] ?? throw ValidationException::withMessages(['redirect_uri' => ['رابط إعادة التوجيه مطلوب.']])
            ),
            default => throw ValidationException::withMessages(['provider' => ["مزود تسجيل الدخول '{$provider}' غير مدعوم."]]),
        };
    }

    protected function findOrCreateUser(?string $email, string $name, ?string $avatar): User
    {
        if ($email && ($existing = User::where('email', $email)->first())) {
            return $existing;
        }

        return User::create([
            'name' => $name,
            'email' => $email ?? ('user_' . Str::random(10) . '@farfasha.app'),
            'password' => Hash::make(Str::random(32)),
            'avatar' => $avatar ?? 'assets/images/farfasha_logo.png',
            'level' => 1,
            'total_score' => 0,
            'wins_count' => 0,
            'games_played' => 0,
        ]);
    }
}
