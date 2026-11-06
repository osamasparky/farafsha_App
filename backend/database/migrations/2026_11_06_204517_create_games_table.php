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
        Schema::create('games', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // اسم اللعبة مثلاً "أمثال شعبية"
            $table->string('slug')->unique(); // e.g. "amthal-shaabiya"
            $table->string('subtitle')->nullable(); // "كمل المثل الشعبي"
            $table->text('description')->nullable();
            $table->text('instructions')->nullable(); // القواعد والشرح
            $table->string('icon')->nullable(); // أيقونة اللعبة أو مسارها
            $table->string('cover_image')->nullable();
            $table->string('badge_text')->nullable(); // "جديد" أو "الأكثر لعباً"
            $table->string('category')->default('party'); // أمثال، إفيهات، معلومات، تمثيل، ثقافة
            $table->string('template_type')->default('choice'); // choice, quote_completion, open_guess, forbidden_words, two_truths_one_lie, speed_trivia
            $table->enum('game_mode', ['local_only', 'online_only', 'hybrid'])->default('hybrid');
            $table->unsignedInteger('min_players')->default(2);
            $table->unsignedInteger('max_players')->default(12);
            $table->unsignedInteger('default_rounds')->default(10);
            $table->unsignedInteger('default_duration_seconds')->default(30);
            $table->json('difficulty_levels')->nullable(); // ["سهل", "متوسط", "صعب"]
            $table->json('rules_config')->nullable(); // نقاط الصواب، البونص، الخصم
            $table->boolean('is_active')->default(true);
            $table->boolean('is_featured')->default(false);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('games');
    }
};
