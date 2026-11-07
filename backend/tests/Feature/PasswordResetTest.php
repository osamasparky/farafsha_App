<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    public function test_forgot_password_sends_otp_for_registered_user(): void
    {
        $user = User::factory()->create([
            'email' => 'test_reset@farfasha.app',
            'phone' => '01099887766',
        ]);

        // طلب استعادة عبر الإيميل
        $res = $this->postJson('/api/auth/forgot-password', [
            'identifier' => 'test_reset@farfasha.app',
        ]);

        $res->assertStatus(200)
            ->assertJson(['status' => 'success']);

        // التحقق من كود الـ OTP
        $verifyRes = $this->postJson('/api/auth/verify-reset-otp', [
            'identifier' => 'test_reset@farfasha.app',
            'otp' => '1234', // Local test fallback
        ]);

        $verifyRes->assertStatus(200)
            ->assertJsonStructure(['status', 'reset_token']);

        $resetToken = $verifyRes->json('reset_token');

        // تعيين كلمة المرور الجديدة
        $resetRes = $this->postJson('/api/auth/reset-password', [
            'reset_token' => $resetToken,
            'password' => 'newSecretPass123',
            'password_confirmation' => 'newSecretPass123',
        ]);

        $resetRes->assertStatus(200)
            ->assertJson(['status' => 'success']);

        $user->refresh();
        $this->assertTrue(Hash::check('newSecretPass123', $user->password));
    }

    public function test_change_password_for_authenticated_user(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('oldPass1234'),
        ]);

        // محاولة كلمة مرور حالية خاطئة
        $failRes = $this->actingAs($user, 'sanctum')->postJson('/api/auth/change-password', [
            'current_password' => 'wrongPass',
            'new_password' => 'superSecret999',
            'new_password_confirmation' => 'superSecret999',
        ]);
        $failRes->assertStatus(422);

        // محاولة صحيحة
        $successRes = $this->actingAs($user, 'sanctum')->postJson('/api/auth/change-password', [
            'current_password' => 'oldPass1234',
            'new_password' => 'superSecret999',
            'new_password_confirmation' => 'superSecret999',
        ]);
        $successRes->assertStatus(200);

        $user->refresh();
        $this->assertTrue(Hash::check('superSecret999', $user->password));
    }
}
