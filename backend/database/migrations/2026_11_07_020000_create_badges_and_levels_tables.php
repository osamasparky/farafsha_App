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
        // 1. جدول الأوسمة والإنجازات (Badges)
        Schema::create('badges', function (Blueprint $table) {
            $table->id();
            $table->string('title'); // عنوان الوسام (مثال: ملك الأمثال، العبقري، صائد النقاط)
            $table->text('description')->nullable(); // شرح الوسام وكيفية الحصول عليه
            $table->foreignId('game_id')->nullable()->constrained('games')->nullOnDelete(); // تابع للعبة معينة أو عام
            $table->integer('required_points')->default(0); // عدد النقاط المطلوب لفتحه
            $table->string('icon')->nullable(); // اسم الأيقونة (quote, bulb, trophy, star, film, music)
            $table->string('image')->nullable(); // مسار صورة مخصصة في التخزين
            $table->string('color')->default('#FFC24B'); // لون الوسام المميز
            $table->integer('sort_order')->default(0); // ترتيب الظهور في البروفايل
            $table->boolean('is_active')->default(true); // مفعل أم معطل
            $table->timestamps();
        });

        // 2. جدول المستويات والرتب (Level Tiers)
        Schema::create('levels', function (Blueprint $table) {
            $table->id();
            $table->integer('level_number')->unique(); // رقم المستوى: 1، 2، 3 ...
            $table->string('title'); // مسمى المستوى (مثال: مبتدئ، محترف، خبير اللمّة، أسطورة)
            $table->integer('min_points')->default(0); // الحد الأدنى للنقاط المطلوبة
            $table->string('icon')->nullable(); // أيقونة أو رمز المستوى
            $table->string('color')->default('#FFC24B'); // لون المستوى
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('levels');
        Schema::dropIfExists('badges');
    }
};
