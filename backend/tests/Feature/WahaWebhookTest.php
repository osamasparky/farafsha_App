<?php

namespace Tests\Feature;

use App\Jobs\ProcessWahaWebhook;
use App\Models\WahaWebhookEvent;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class WahaWebhookTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticates_and_deduplicates_waha_events(): void
    {
        config(['waha.webhook_token' => 'test-secret']);
        Queue::fake();
        $payload = ['id' => 'evt_abc', 'event' => 'session.status', 'session' => 'default', 'payload' => ['status' => 'WORKING']];
        $this->postJson('/api/webhooks/waha', $payload)->assertUnauthorized();
        $this->withHeader('X-Waha-Webhook-Token', 'test-secret')->postJson('/api/webhooks/waha', $payload)->assertAccepted();
        $this->withHeader('X-Waha-Webhook-Token', 'test-secret')->postJson('/api/webhooks/waha', $payload)->assertAccepted();
        $this->assertSame(1, WahaWebhookEvent::count());
        Queue::assertPushed(ProcessWahaWebhook::class, 1);
    }
}
