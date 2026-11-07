<?php

namespace Tests\Feature;

use App\Models\AccountDeletionRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AccountDeletionTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_request_account_deletion_and_is_blocked_from_login(): void
    {
        $user = User::factory()->create([
            'email' => 'user_delete@farfasha.app',
            'phone' => '01011112222',
            'password' => Hash::make('password123'),
            'status' => 'active',
        ]);

        $token = $user->createToken('test_token')->plainTextToken;

        // 1. تقديم طلب حذف الحساب
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/auth/request-deletion', [
                'reason' => 'أرغب بحذف حسابي لظروف خاصة',
            ]);

        $response->assertStatus(200);
        $response->assertJson([
            'status' => 'success',
        ]);

        // تأكد من إنشاء الطلب في قاعدة البيانات
        $this->assertDatabaseHas('account_deletion_requests', [
            'user_id' => $user->id,
            'status' => 'pending',
            'reason' => 'أرغب بحذف حسابي لظروف خاصة',
        ]);

        // تأكد من تحديث حالة المستخدم إلى deletion_pending
        $user->refresh();
        $this->assertEquals('deletion_pending', $user->status);
        $this->assertNotNull($user->deletion_requested_at);

        // 2. محاولة تسجيل الدخول بعد طلب الحذف يجب أن تُرفض برمز 403
        $loginResponse = $this->postJson('/api/auth/login', [
            'identifier' => 'user_delete@farfasha.app',
            'password' => 'password123',
        ]);

        $loginResponse->assertStatus(403);
        $loginResponse->assertJson([
            'status' => 'error',
        ]);
    }
}

