<?php

namespace App\Services\Auth;

use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class AppleTokenVerifier
{
    public function verify(string $idToken, ?string $clientProvidedName = null): array
    {
        // تقسيم الـ JWT وقراءة الـ Payload بأمان
        $parts = explode('.', $idToken);
        if (count($parts) < 2) {
            throw ValidationException::withMessages([
                'id_token' => ['صيغة رمز Apple غير صالحة.'],
            ]);
        }

        $payloadJson = base64_decode(strtr($parts[1], '-_', '+/'));
        $data = json_decode($payloadJson, true);

        if (!is_array($data)) {
            throw ValidationException::withMessages([
                'id_token' => ['فشل قراءة بيانات رمز Apple.'],
            ]);
        }

        $iss = $data['iss'] ?? '';
        if ($iss !== 'https://appleid.apple.com') {
            throw ValidationException::withMessages([
                'id_token' => ['جهة إصدار الرمز غير معتمدة من Apple.'],
            ]);
        }

        $exp = (int)($data['exp'] ?? 0);
        if ($exp < time()) {
            throw ValidationException::withMessages([
                'id_token' => ['انتهت صلاحية رمز Apple.'],
            ]);
        }

        $sub = $data['sub'] ?? null;
        if (!$sub) {
            throw ValidationException::withMessages([
                'id_token' => ['تعذر استخراج معرف Apple الفريد.'],
            ]);
        }

        // Apple ترسل الاسم في أول ترخيص فقط من العميل إذا لم يكن في الـ claims
        $name = !empty($clientProvidedName) ? trim($clientProvidedName) : 'مستخدم Apple';

        return [
            'provider_user_id' => (string)$sub,
            'email' => $data['email'] ?? null,
            'name' => $name,
            'avatar' => null,
            'metadata' => [
                'email_verified' => filter_var($data['email_verified'] ?? true, FILTER_VALIDATE_BOOLEAN),
                'is_private_email' => filter_var($data['is_private_email'] ?? false, FILTER_VALIDATE_BOOLEAN),
            ],
        ];
    }
}

