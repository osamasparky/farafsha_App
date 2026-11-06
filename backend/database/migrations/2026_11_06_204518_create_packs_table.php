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
        Schema::create('packs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('game_id')->constrained()->cascadeOnDelete();
            $table->string('name'); // اسم الحزمة e.g. "حزمة مسرح مصر" أو "أمثال زمان"
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->string('cover_image')->nullable();
            $table->string('dialect')->default('egyptian'); // egyptian, gulf, standard, levantine
            $table->string('age_rating')->default('all'); // all, family, 16+
            $table->boolean('is_free')->default(true);
            $table->decimal('price', 8, 2)->default(0.00);
            $table->string('currency')->default('EGP');
            $table->unsignedInteger('cards_count')->default(0);
            $table->boolean('is_active')->default(true);
            $table->string('version')->default('1.0.0');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('packs');
    }
};
