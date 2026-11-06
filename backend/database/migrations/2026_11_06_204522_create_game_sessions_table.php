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
        Schema::create('game_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('game_id')->constrained()->cascadeOnDelete();
            $table->foreignId('room_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('mode', ['local', 'online'])->default('local');
            $table->unsignedInteger('players_count')->default(2);
            $table->unsignedInteger('rounds_completed')->default(0);
            $table->json('final_scores')->nullable(); // [{"name": "أحمد", "score": 25}]
            $table->string('winner_name')->nullable();
            $table->unsignedInteger('duration_seconds')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('game_sessions');
    }
};
