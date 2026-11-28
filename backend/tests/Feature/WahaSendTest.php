<?php

namespace Tests\Feature;

use App\Jobs\SendWahaMessage;
use App\Models\WahaMessage;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class WahaSendTest extends TestCase
{
    use DatabaseMigrations;

    public function test_idempotency_key_prevents_duplicate_outbound_queueing(): void
    {
        Queue::fake();
        $this->actingAs(\App\Models\User::factory()->create(['is_admin' => true, 'status' => 'active']), 'sanctum');
        $payload = ['phone' => '+201001234567', 'text' => 'Hello', 'opt_in_confirmed' => true, 'idempotency_key' => 'order-123'];
        $this->postJson('/api/wa/messages', $payload)->assertAccepted();
        $this->postJson('/api/wa/messages', $payload)->assertAccepted();
        $this->assertSame(1, WahaMessage::count());
        Queue::assertPushed(SendWahaMessage::class, 1);
    }
}
