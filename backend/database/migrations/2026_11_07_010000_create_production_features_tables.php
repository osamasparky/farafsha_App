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
        // 1. البنرات الإعلانية والترويجية
        Schema::create('banners', function (Blueprint $table) {
            $table->id();
            $table->string('title')->nullable();
            $table->string('image'); // مسار الصورة في storage
            $table->string('external_url')->nullable(); // رابط خارجي اختياري
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        // 2. إدارة اللهجات
        Schema::create('dialects', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // مصري، خليجي، شامي، مغاربي، سعودي
            $table->string('code')->unique(); // egyptian, gulf, levantine, etc.
            $table->string('icon')->nullable(); // علم أو أيقونة
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        // 3. جدول المتصدرين والترتيب (Leaderboard)
        Schema::create('leaderboard_entries', function (Blueprint $table) {
            $table->id();
            $table->string('player_name');
            $table->string('avatar')->default('assets/images/av-ahmed.png');
            $table->integer('score')->default(0);
            $table->integer('wins')->default(0);
            $table->enum('period_type', ['weekly', 'monthly', 'all_time'])->default('weekly');
            $table->integer('rank')->default(1);
            $table->string('badge')->nullable(); // أسطورة، محترف، بطل الأسبوع
            $table->boolean('is_current_user')->default(false);
            $table->timestamps();
        });

        // 4. الإشعارات العامة
        Schema::create('app_notifications', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('message');
            $table->string('type')->default('info'); // info, reward, update, game
            $table->string('icon')->default('notifications');
            $table->boolean('is_read')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 5. الصفحات الثابتة والدعم
        Schema::create('app_pages', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique(); // privacy-policy, terms-conditions, faq-help, contact-us
            $table->string('title');
            $table->longText('content');
            $table->json('meta')->nullable(); // بريد، واتساب، هاتف، روابط
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('app_pages');
        Schema::dropIfExists('app_notifications');
        Schema::dropIfExists('leaderboard_entries');
        Schema::dropIfExists('dialects');
        Schema::dropIfExists('banners');
    }
};

