<?php

namespace App\Services\Auth;

use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class GoogleTokenVerifier
{
    public function verify(string $idToken): array
    {
        $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if (!$response->successful()) {
            throw ValidationException::withMessages([
                'id_token' => ['رمز Google التعريفي غير صالح أو انتهت صلاحيته.'],
            ]);
        }

        $data = $response->json();

        // التحقق من صحة المزود والانتهاء
        $iss = $data['iss'] ?? '';
        if ($iss !== 'accounts.google.com' && $iss !== 'https://accounts.google.com') {
            throw ValidationException::withMessages([
                'id_token' => ['جهة إصدار الرمز غير معتمدة من Google.'],
            ]);
        }

        $exp = (int)($data['exp'] ?? 0);
        if ($exp < time()) {
            throw ValidationException::withMessages([
                'id_token' => ['انتهت صلاحية رمز الدخول، يرجى إعادة المحاولة.'],
            ]);
        }

        $sub = $data['sub'] ?? null;
        if (!$sub) {
            throw ValidationException::withMessages([
                'id_token' => ['تعذر استخراج المعرف الفريد لحساب Google.'],
            ]);
        }

        return [
            'provider_user_id' => (string)$sub,
            'email' => $data['email'] ?? null,
            'name' => $data['name'] ?? ($data['given_name'] ?? 'مستخدم Google'),
            'avatar' => $data['picture'] ?? null,
            'metadata' => [
                'email_verified' => filter_var($data['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'locale' => $data['locale'] ?? null,
            ],
        ];
    }
}
