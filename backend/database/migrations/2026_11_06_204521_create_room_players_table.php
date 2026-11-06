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
        Schema::create('room_players', function (Blueprint $table) {
            $table->id();
            $table->foreignId('room_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('player_name'); // اسم اللاعب سواء مسجل أو ضيف
            $table->string('avatar')->nullable(); // أفاتار أو صورة اللاعب
            $table->integer('score')->default(0);
            $table->boolean('is_host')->default(false);
            $table->boolean('is_ready')->default(true);
            $table->enum('connection_status', ['online', 'disconnected', 'left'])->default('online');
            $table->string('session_token')->nullable(); // توكن الجلسة للتحقق من اللاعب
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('room_players');
    }
};
