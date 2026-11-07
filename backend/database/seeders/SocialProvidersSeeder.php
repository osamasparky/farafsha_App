<?php

namespace Database\Seeders;

use App\Models\SiteSetting;
use App\Models\SocialProvider;
use Illuminate\Database\Seeder;

class SocialProvidersSeeder extends Seeder
{
    public function run(): void
    {
        // 1. مزودي تسجيل الدخول والتواصل الاجتماعي
        SocialProvider::updateOrCreate(
            ['provider' => 'google'],
            [
                'name' => 'تسجيل الدخول بحساب Google',
                'is_enabled' => true,
                'client_id' => 'farfasha-google-client-id.apps.googleusercontent.com',
                'client_secret' => 'GOCSPX-farfashaGoogleSecret2026',
                'redirect_url' => 'https://farfasha.app/auth/google/callback',
                'icon' => 'google',
                'sort_order' => 1,
                'notes' => 'يُستخدم للدخول السريع بحسابات Google و Gmail على أندرويد و iOS والموقع.',
            ]
        );

        SocialProvider::updateOrCreate(
            ['provider' => 'apple'],
            [
                'name' => 'تسجيل الدخول بحساب Apple',
                'is_enabled' => true,
                'client_id' => 'com.farfasha.app.client',
                'client_secret' => 'farfashaAppleSecretKey2026',
                'redirect_url' => 'https://farfasha.app/auth/apple/callback',
                'icon' => 'apple',
                'sort_order' => 2,
                'notes' => 'مطلوب في متجر آبل App Store للدخول بحسابات Apple ID.',
            ]
        );

        SocialProvider::updateOrCreate(
            ['provider' => 'facebook'],
            [
                'name' => 'تسجيل الدخول بحساب Facebook',
                'is_enabled' => false,
                'client_id' => '102938475610293',
                'client_secret' => 'fb_secret_farfasha_2026',
                'redirect_url' => 'https://farfasha.app/auth/facebook/callback',
                'icon' => 'facebook',
                'sort_order' => 3,
                'notes' => 'يمكنك تفعيله أو إيقافه في أي وقت ليظهر في التطبيق.',
            ]
        );

        // 2. إيقاف اللهجات الافتراضي كما طلب المستخدم من لوحة التحكم
        SiteSetting::set('dialects_enabled', false, 'general');
    }
}

