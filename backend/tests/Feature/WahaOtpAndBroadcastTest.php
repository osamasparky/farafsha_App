<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\WahaMessage;
use App\Models\WahaSession;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class WahaOtpAndBroadcastTest extends TestCase
{
    use RefreshDatabase;

    public function test_send_otp_queues_waha_whatsapp_message(): void
    {
        \Illuminate\Support\Facades\Queue::fake([\App\Jobs\SendWahaMessage::class]);

        $response = $this->postJson('/api/auth/send-otp', [
            'phone' => '01012345678',
            'country_code' => '+20',
        ]);

        $response->assertStatus(200);
        $response->assertJson([
            'status' => 'success',
        ]);

        $this->assertDatabaseHas('waha_messages', [
            'chat_id' => '201012345678@c.us',
            'status' => 'queued',
        ]);

        \Illuminate\Support\Facades\Queue::assertPushed(\App\Jobs\SendWahaMessage::class);

        $otp = Cache::get('otp:phone:201012345678');
        $this->assertNotNull($otp);
        $this->assertEquals(4, strlen($otp));
    }

    public function test_verify_otp_validates_and_marks_phone_verified(): void
    {
        Cache::put('otp:phone:201099998888', '7788', 300);

        // محاولة برمز خاطئ
        $bad = $this->postJson('/api/auth/verify-otp', [
            'phone' => '201099998888',
            'otp' => '0000',
        ]);
        $bad->assertStatus(422);

        // التحقق بالرمز الصحيح
        $good = $this->postJson('/api/auth/verify-otp', [
            'phone' => '201099998888',
            'otp' => '7788',
        ]);
        $good->assertStatus(200);
        $good->assertJson([
            'status' => 'success',
            'is_verified' => true,
        ]);

        $this->assertTrue(Cache::get('verified_phone:201099998888'));
    }

    public function test_registration_is_blocked_without_phone_or_email_verification(): void
    {
        // محاولة إنشاء حساب برقم هاتف غير موثق
        $response = $this->postJson('/api/auth/register', [
            'name' => 'لاعب غير موثق',
            'email' => 'unverified@example.com',
            'phone' => '201011112222',
            'password' => 'secret1234',
        ]);

        $response->assertStatus(422);
        $response->assertJson([
            'status' => 'error',
            'verification_required' => true,
        ]);
        $this->assertDatabaseMissing('users', ['email' => 'unverified@example.com']);

        // بعد توثيق الهاتف
        Cache::put('verified_phone:201011112222', true, 3600);

        $success = $this->postJson('/api/auth/register', [
            'name' => 'لاعب موثق',
            'email' => 'verified@example.com',
            'phone' => '201011112222',
            'password' => 'secret1234',
        ]);

        $success->assertStatus(200);
        $success->assertJson(['status' => 'success']);
        $this->assertDatabaseHas('users', [
            'email' => 'verified@example.com',
            'phone' => '201011112222',
        ]);

        $user = User::where('email', 'verified@example.com')->first();
        $this->assertNotNull($user->phone_verified_at);
    }

    public function test_send_to_users_broadcast_whatsapp_endpoint(): void
    {
        $user1 = User::create([
            'name' => 'أحمد فتحي',
            'email' => 'ahmed1@farfasha.app',
            'phone' => '201012345671',
            'password' => bcrypt('password'),
        ]);

        $user2 = User::create([
            'name' => 'سارة حسن',
            'email' => 'sara1@farfasha.app',
            'phone' => '201012345672',
            'password' => bcrypt('password'),
        ]);

        $admin = User::create([
            'name' => 'مدير النظام',
            'email' => 'admin_test@farfasha.app',
            'password' => bcrypt('password'),
            'is_admin' => true,
        ]);

        $response = $this->actingAs($admin)->postJson('/api/wa/messages/send-to-users', [
            'user_ids' => [$user1->id, $user2->id],
            'text' => 'أهلاً بك يا {name}! هناك بطولة ألعاب جديدة على فرفشة 🏆',
        ]);

        $response->assertStatus(200);
        $response->assertJson([
            'status' => 'success',
            'queued_count' => 2,
        ]);

        $this->assertDatabaseHas('waha_messages', [
            'chat_id' => '201012345671@c.us',
            'body' => 'أهلاً بك يا أحمد فتحي! هناك بطولة ألعاب جديدة على فرفشة 🏆',
        ]);

        $this->assertDatabaseHas('waha_messages', [
            'chat_id' => '201012345672@c.us',
            'body' => 'أهلاً بك يا سارة حسن! هناك بطولة ألعاب جديدة على فرفشة 🏆',
        ]);
    }
}
