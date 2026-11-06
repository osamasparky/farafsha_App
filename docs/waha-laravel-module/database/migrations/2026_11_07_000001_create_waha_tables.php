<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('waha_sessions', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('status')->default('STOPPED')->index();
            $table->string('phone')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();
        });

        Schema::create('waha_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('waha_session_id')->constrained('waha_sessions')->cascadeOnDelete();
            $table->string('direction', 8)->index();
            $table->string('chat_id');
            $table->text('body');
            $table->string('status')->default('queued')->index();
            $table->string('waha_message_id')->nullable()->index();
            $table->string('idempotency_key')->nullable()->unique();
            $table->json('metadata')->nullable();
            $table->text('last_error')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();
            $table->index(['waha_session_id', 'chat_id']);
        });

        Schema::create('waha_webhook_events', function (Blueprint $table) {
            $table->id();
            $table->string('event_id')->unique();
            $table->string('event_name')->index();
            $table->string('session')->nullable()->index();
            $table->json('payload');
            $table->timestamp('received_at')->useCurrent();
            $table->timestamp('processed_at')->nullable()->index();
            $table->text('processing_error')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('waha_webhook_events');
        Schema::dropIfExists('waha_messages');
        Schema::dropIfExists('waha_sessions');
    }
};
