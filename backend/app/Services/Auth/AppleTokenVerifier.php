<?php

namespace App\Services\Auth;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class AppleTokenVerifier
{
    public function verify(string $idToken, ?string $clientProvidedName = null): array
    {
        $parts = explode('.', $idToken);
        if (count($parts) !== 3) {
            throw ValidationException::withMessages([
                'id_token' => ['صيغة رمز Apple غير صالحة.'],
            ]);
        }

        $headerJson = base64_decode(strtr($parts[0], '-_', '+/'), true);
        $payloadJson = base64_decode(strtr($parts[1], '-_', '+/'), true);
        $signature = base64_decode(strtr($parts[2], '-_', '+/'), true);

        $header = is_string($headerJson) ? json_decode($headerJson, true) : null;
        $data = is_string($payloadJson) ? json_decode($payloadJson, true) : null;

        if (!is_array($header) || !is_array($data) || !is_string($signature) || $signature === '') {
            throw ValidationException::withMessages([
                'id_token' => ['فشل قراءة بيانات رمز Apple.'],
            ]);
        }

        if (($header['alg'] ?? '') !== 'RS256' || empty($header['kid'])) {
            throw ValidationException::withMessages([
                'id_token' => ['خوارزمية توقيع رمز Apple غير معتمدة.'],
            ]);
        }

        // التحقق من التوقيع التشفيري باستخدام مفاتيح Apple العامة (JWKS)
        $jwks = Cache::remember('apple_jwks_keys', 3600, function () {
            $res = Http::timeout(10)->get('https://appleid.apple.com/auth/keys');
            return $res->successful() ? ($res->json('keys') ?? []) : [];
        });

        $matchedKey = null;
        foreach ($jwks as $key) {
            if (($key['kid'] ?? '') === $header['kid']) {
                $matchedKey = $key;
                break;
            }
        }

        if (!$matchedKey || empty($matchedKey['n']) || empty($matchedKey['e'])) {
            throw ValidationException::withMessages([
                'id_token' => ['تعذر مطابقة مفتاح التوقيع العام من Apple.'],
            ]);
        }

        $pem = $this->jwkToPem($matchedKey['n'], $matchedKey['e']);
        $signedInput = $parts[0] . '.' . $parts[1];
        $verified = openssl_verify($signedInput, $signature, $pem, OPENSSL_ALGO_SHA256);
        if ($verified !== 1) {
            throw ValidationException::withMessages([
                'id_token' => ['توقيع رمز Apple غير صحيح أو تم التلاعب به.'],
            ]);
        }

        $iss = $data['iss'] ?? '';
        if ($iss !== 'https://appleid.apple.com') {
            throw ValidationException::withMessages([
                'id_token' => ['جهة إصدار الرمز غير معتمدة من Apple.'],
            ]);
        }

        $expectedAud = config('services.apple.client_id');
        if (!empty($expectedAud) && ($data['aud'] ?? '') !== $expectedAud) {
            throw ValidationException::withMessages([
                'id_token' => ['الرمز غير مخصص لهذا التطبيق (aud mismatch).'],
            ]);
        }

        $exp = (int) ($data['exp'] ?? 0);
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

        $name = !empty($clientProvidedName) ? trim($clientProvidedName) : 'مستخدم Apple';

        return [
            'provider_user_id' => (string) $sub,
            'email' => $data['email'] ?? null,
            'name' => $name,
            'avatar' => null,
            'metadata' => [
                'email_verified' => filter_var($data['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'is_private_email' => filter_var($data['is_private_email'] ?? false, FILTER_VALIDATE_BOOLEAN),
            ],
        ];
    }

    private function jwkToPem(string $nB64, string $eB64): string
    {
        $n = $this->base64UrlDecode($nB64);
        $e = $this->base64UrlDecode($eB64);
        if (ord($n[0]) > 0x7f) {
            $n = "\x00" . $n;
        }
        if (ord($e[0]) > 0x7f) {
            $e = "\x00" . $e;
        }
        $nDer = "\x02" . $this->encodeLength(strlen($n)) . $n;
        $eDer = "\x02" . $this->encodeLength(strlen($e)) . $e;
        $seq = "\x30" . $this->encodeLength(strlen($nDer . $eDer)) . $nDer . $eDer;
        $bitString = "\x03" . $this->encodeLength(strlen($seq) + 1) . "\x00" . $seq;
        $algId = "\x30\x0d\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x01\x05\x00";
        $spki = "\x30" . $this->encodeLength(strlen($algId . $bitString)) . $algId . $bitString;

        return "-----BEGIN PUBLIC KEY-----\n" . chunk_split(base64_encode($spki), 64, "\n") . "-----END PUBLIC KEY-----\n";
    }

    private function base64UrlDecode(string $input): string
    {
        $rem = strlen($input) % 4;
        if ($rem > 0) {
            $input .= str_repeat('=', 4 - $rem);
        }
        return (string) base64_decode(strtr($input, '-_', '+/'));
    }

    private function encodeLength(int $len): string
    {
        if ($len <= 0x7f) {
            return chr($len);
        }
        $temp = ltrim(pack('N', $len), "\x00");
        return chr(0x80 | strlen($temp)) . $temp;
    }
}
