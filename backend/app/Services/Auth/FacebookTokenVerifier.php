<?php

namespace App\Services\Auth;

use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class FacebookTokenVerifier
{
    public function verify(string $accessToken): array
    {
        $response = Http::timeout(10)->get('https://graph.facebook.com/me', [
            'fields' => 'id,name,email,picture.width(500).height(500)',
            'access_token' => $accessToken,
        ]);

        if (!$response->successful()) {
            throw ValidationException::withMessages([
                'access_token' => ['رمز وصول Facebook غير صالح أو تم إلغاؤه.'],
            ]);
        }

        $data = $response->json();
        $id = $data['id'] ?? null;

        if (!$id) {
            throw ValidationException::withMessages([
                'access_token' => ['تعذر التحقق من معرف حساب Facebook.'],
            ]);
        }

        $avatar = null;
        if (isset($data['picture']['data']['url'])) {
            $avatar = $data['picture']['data']['url'];
        }

        return [
            'provider_user_id' => (string)$id,
            'email' => $data['email'] ?? null,
            'name' => $data['name'] ?? 'مستخدم Facebook',
            'avatar' => $avatar,
            'metadata' => [
                'facebook_id' => $id,
            ],
        ];
    }
}

