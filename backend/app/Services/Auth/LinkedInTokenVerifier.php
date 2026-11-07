<?php

namespace App\Services\Auth;

use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class LinkedInTokenVerifier
{
    public function verify(string $code, string $redirectUri): array
    {
        $clientId = config('services.linkedin.client_id', env('LINKEDIN_CLIENT_ID', ''));
        $clientSecret = config('services.linkedin.client_secret', env('LINKEDIN_CLIENT_SECRET', ''));

        $tokenResponse = Http::asForm()->timeout(12)->post('https://www.linkedin.com/oauth/v2/accessToken', [
            'grant_type' => 'authorization_code',
            'code' => $code,
            'client_id' => $clientId,
            'client_secret' => $clientSecret,
            'redirect_uri' => $redirectUri,
        ]);

        if (!$tokenResponse->successful()) {
            throw ValidationException::withMessages([
                'authorization_code' => ['فشل استبدال رمز تفويض LinkedIn: ' . ($tokenResponse->json()['error_description'] ?? 'رمز غير صالح.')],
            ]);
        }

        $accessToken = $tokenResponse->json()['access_token'] ?? null;
        if (!$accessToken) {
            throw ValidationException::withMessages([
                'authorization_code' => ['تعذر الحصول على رمز الوصول من LinkedIn.'],
            ]);
        }

        // جلب بيانات العضو عبر OpenID Connect UserInfo
        $userInfoResponse = Http::withToken($accessToken)
            ->timeout(10)
            ->get('https://api.linkedin.com/v2/userinfo');

        if (!$userInfoResponse->successful()) {
            throw ValidationException::withMessages([
                'authorization_code' => ['تعذر جلب ملف المستخدم من LinkedIn.'],
            ]);
        }

        $data = $userInfoResponse->json();
        $sub = $data['sub'] ?? null;

        if (!$sub) {
            throw ValidationException::withMessages([
                'authorization_code' => ['معرف العضو غير موجود في بيانات LinkedIn.'],
            ]);
        }

        return [
            'provider_user_id' => (string)$sub,
            'email' => $data['email'] ?? null,
            'name' => $data['name'] ?? 'مستخدم LinkedIn',
            'avatar' => $data['picture'] ?? null,
            'metadata' => [
                'email_verified' => filter_var($data['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'given_name' => $data['given_name'] ?? null,
                'family_name' => $data['family_name'] ?? null,
            ],
        ];
    }
}
