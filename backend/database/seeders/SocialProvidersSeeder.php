<?php

namespace Database\Seeders;

use App\Models\SiteSetting;
use App\Models\SocialProvider;
use Illuminate\Database\Seeder;

class SocialProvidersSeeder extends Seeder
{
    public function run(): void
    {
        $providers = [
            [
                'provider' => 'google',
                'name' => 'تسجيل الدخول بحساب Google',
                'is_enabled' => true,
                'client_id' => 'farfasha-google-client-id.apps.googleusercontent.com',
                'client_secret' => 'GOCSPX-farfashaGoogleSecret2026',
                'team_id' => null,
                'key_id' => null,
                'redirect_url' => 'https://farfasha.app/api/v1/auth/social/google/callback',
                'scopes' => 'email,profile,openid',
                'icon' => 'google',
                'sort_order' => 1,
                'notes' => 'يُستخدم للدخول السريع بحسابات Google و Gmail على أندرويد و iOS والموقع. يتطلب إضافة SHA-1 في Google Cloud Console.',
            ],
            [
                'provider' => 'apple',
                'name' => 'تسجيل الدخول بحساب Apple',
                'is_enabled' => true,
                'client_id' => 'com.lammah.app.client',
                'client_secret' => 'farfashaAppleSecretKey2026',
                'team_id' => 'APPLE_TEAM_ID',
                'key_id' => 'APPLE_KEY_ID',
                'redirect_url' => 'https://farfasha.app/api/v1/auth/social/apple/callback',
                'scopes' => 'name,email',
                'icon' => 'apple',
                'sort_order' => 2,
                'notes' => 'مطلوب في متجر آبل App Store للدخول بحسابات Apple ID. يتطلب Service ID و Team ID و Key ID.',
            ],
            [
                'provider' => 'facebook',
                'name' => 'تسجيل الدخول بحساب Facebook',
                'is_enabled' => true,
                'client_id' => '102938475610293',
                'client_secret' => 'fb_secret_farfasha_2026',
                'client_token' => 'fb_client_token_farfasha_2026',
                'team_id' => null,
                'key_id' => null,
                'redirect_url' => 'https://farfasha.app/api/v1/auth/social/facebook/callback',
                'scopes' => 'public_profile,email',
                'icon' => 'facebook',
                'sort_order' => 3,
                'notes' => 'يتطلب App ID و App Secret و Client Token من Meta for Developers مع تفعيل Facebook Login.',
            ],
            [
                'provider' => 'twitter',
                'name' => 'تسجيل الدخول بحساب X (Twitter)',
                'is_enabled' => true,
                'client_id' => 'TWITTER_CLIENT_ID',
                'client_secret' => 'TWITTER_CLIENT_SECRET',
                'team_id' => null,
                'key_id' => null,
                'redirect_url' => 'farfasha://oauth-callback',
                'scopes' => 'tweet.read,users.read,offline.access',
                'icon' => 'twitter',
                'sort_order' => 4,
                'notes' => 'يعتمد على بروتوكول OAuth 2.0 الآمن مع PKCE. يتم تبادل الرمز على السيرفر مباشرة دون كشف السري في التطبيق.',
            ],
            [
                'provider' => 'linkedin',
                'name' => 'تسجيل الدخول بحساب LinkedIn',
                'is_enabled' => true,
                'client_id' => 'LINKEDIN_CLIENT_ID',
                'client_secret' => 'LINKEDIN_CLIENT_SECRET',
                'team_id' => null,
                'key_id' => null,
                'redirect_url' => 'farfasha://oauth-callback',
                'scopes' => 'openid,profile,email',
                'icon' => 'linkedin',
                'sort_order' => 5,
                'notes' => 'يتطلب منتج Sign In with LinkedIn using OpenID Connect في LinkedIn Developer Portal.',
            ],
        ];

        foreach ($providers as $p) {
            SocialProvider::updateOrCreate(['provider' => $p['provider']], $p);
        }

        // إيقاف اللهجات الافتراضي كما طلب المستخدم من لوحة التحكم
        SiteSetting::set('dialects_enabled', false, 'general');
    }
}
