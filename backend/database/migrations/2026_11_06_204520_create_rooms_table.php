<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('rooms', function (Blueprint $table) {
            $table->id();
            $table->string('code', 6)->unique(); // كود الغرفة المكون من 6 أرقام مثل 784521
            $table->foreignId('host_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('host_name')->default('المضيف');
            $table->foreignId('game_id')->constrained()->cascadeOnDelete();
            $table->enum('status', ['waiting', 'playing', 'paused', 'finished', 'closed'])->default('waiting');
            $table->unsignedInteger('max_players')->default(8);
            $table->unsignedInteger('current_round')->default(0);
            $table->unsignedInteger('total_rounds')->default(10);
            $table->unsignedInteger('round_duration_seconds')->default(20);
            $table->string('difficulty')->default('medium');
            $table->json('game_state')->nullable(); // الحالة الحية للجولة الحالية والتوقيت
            $table->timestamp('last_active_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rooms');
    }
};
