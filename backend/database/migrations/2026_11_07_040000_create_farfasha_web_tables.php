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
        // 1. إضافة حقول الموقع والـ CMS لجدول الألعاب المشترك
        Schema::table('games', function (Blueprint $table) {
            $table->boolean('is_offline_capable')->default(true)->after('game_mode');
            $table->string('age_group')->default('جميع الأعمار')->after('is_offline_capable');
            $table->json('how_to_play_steps')->nullable()->after('instructions');
            $table->json('scoring_guide')->nullable()->after('rules_config');
            $table->json('example_round')->nullable()->after('scoring_guide');
            $table->json('faqs')->nullable()->after('example_round');
            $table->string('seo_title')->nullable()->after('sort_order');
            $table->text('seo_description')->nullable()->after('seo_title');
            $table->string('og_image')->nullable()->after('seo_description');
            $table->string('trailer_video_url')->nullable()->after('og_image');
        });

        // 2. جدول صفحات الموقع المبنية بالـ Blocks الديناميكية
        Schema::create('site_pages', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique(); // home, about, privacy, terms, cookies, faq, etc.
            $table->json('title'); // ترجمة متعددة اللغات {"ar": "...", "en": "..."}
            $table->json('subtitle')->nullable();
            $table->string('seo_title')->nullable();
            $table->text('seo_description')->nullable();
            $table->string('og_image')->nullable();
            $table->enum('status', ['draft', 'published', 'scheduled'])->default('published');
            $table->timestamp('published_at')->nullable();
            $table->json('blocks')->nullable(); // Filament Page Builder Blocks
            $table->timestamps();
        });

        // 3. جدول آراء وتقييمات المستخدمين الحقيقية
        Schema::create('testimonials', function (Blueprint $table) {
            $table->id();
            $table->string('author_name');
            $table->string('avatar')->nullable();
            $table->string('source')->default('App Store'); // App Store, Google Play, Direct, Twitter
            $table->unsignedTinyInteger('rating')->default(5); // 1 to 5
            $table->json('content'); // نص المراجعة باللغات
            $table->string('country_code', 5)->default('EG');
            $table->boolean('is_approved')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        // 4. جدول روابط المتاجر والتوافر بحسب البلد
        Schema::create('app_store_links', function (Blueprint $table) {
            $table->id();
            $table->enum('platform', ['ios', 'android', 'web']);
            $table->string('country_code', 5)->default('ALL'); // EG, SA, AE, ALL
            $table->string('store_url');
            $table->boolean('is_available')->default(true);
            $table->string('message')->nullable();
            $table->timestamps();
        });

        // 5. جدول طلبات التنبيه الجغرافي «بلّغني لما يتاح»
        Schema::create('country_waitlists', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->string('country_code', 5)->default('ALL');
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->boolean('consent_given')->default(true);
            $table->timestamps();
        });

        // 6. جدول رسائل نموذج تواصل معنا
        Schema::create('contact_messages', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email');
            $table->string('subject')->nullable();
            $table->text('message');
            $table->string('ip_address', 45)->nullable();
            $table->enum('status', ['new', 'read', 'replied', 'archived'])->default('new');
            $table->timestamps();
        });

        // 7. جدول إعدادات الموقع وأصول فرفوش
        Schema::create('site_settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->json('value')->nullable();
            $table->string('group')->default('general'); // general, mascot, analytics, legal, links
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('site_settings');
        Schema::dropIfExists('contact_messages');
        Schema::dropIfExists('country_waitlists');
        Schema::dropIfExists('app_store_links');
        Schema::dropIfExists('testimonials');
        Schema::dropIfExists('site_pages');

        Schema::table('games', function (Blueprint $table) {
            $table->dropColumn([
                'is_offline_capable',
                'age_group',
                'how_to_play_steps',
                'scoring_guide',
                'example_round',
                'faqs',
                'seo_title',
                'seo_description',
                'og_image',
                'trailer_video_url',
            ]);
        });
    }
};

