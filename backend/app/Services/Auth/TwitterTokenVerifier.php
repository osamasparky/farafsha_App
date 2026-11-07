<?php

namespace App\Services\Auth;

use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class TwitterTokenVerifier
{
    public function verify(string $code, string $codeVerifier, string $redirectUri): array
    {
        $clientId = config('services.twitter.client_id', env('TWITTER_CLIENT_ID', ''));
        $clientSecret = config('services.twitter.client_secret', env('TWITTER_CLIENT_SECRET', ''));

        $request = Http::asForm()->timeout(12);
        if (!empty($clientSecret)) {
            $request = $request->withBasicAuth($clientId, $clientSecret);
        }

        $tokenResponse = $request->post('https://api.twitter.com/2/oauth2/token', [
            'code' => $code,
            'grant_type' => 'authorization_code',
            'client_id' => $clientId,
            'redirect_uri' => $redirectUri,
            'code_verifier' => $codeVerifier,
        ]);

        if (!$tokenResponse->successful()) {
            throw ValidationException::withMessages([
                'authorization_code' => ['فشل التحقق من رمز تفويض X (Twitter): ' . ($tokenResponse->json()['error_description'] ?? 'رمز غير صالح.')],
            ]);
        }

        $accessToken = $tokenResponse->json()['access_token'] ?? null;
        if (!$accessToken) {
            throw ValidationException::withMessages([
                'authorization_code' => ['تعذر استلام رمز الوصول من منصة X.'],
            ]);
        }

        // جلب ملف العضو
        $userResponse = Http::withToken($accessToken)
            ->timeout(10)
            ->get('https://api.twitter.com/2/users/me', [
                'user.fields' => 'profile_image_url,name,username',
            ]);

        if (!$userResponse->successful()) {
            throw ValidationException::withMessages([
                'authorization_code' => ['تعذر قراءة بيانات المستخدم من X.'],
            ]);
        }

        $userData = $userResponse->json()['data'] ?? [];
        $id = $userData['id'] ?? null;

        if (!$id) {
            throw ValidationException::withMessages([
                'authorization_code' => ['معرف المستخدم غير متوفر في رد X.'],
            ]);
        }

        return [
            'provider_user_id' => (string)$id,
            'email' => null, // X OAuth 2.0 لا يُرجع البريد إلا بتصريح خاص
            'name' => $userData['name'] ?? ($userData['username'] ?? 'مستخدم X'),
            'avatar' => $userData['profile_image_url'] ?? null,
            'metadata' => [
                'username' => $userData['username'] ?? null,
            ],
        ];
    }
}
