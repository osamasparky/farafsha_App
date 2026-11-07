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
        // 1. إضافة حقل الهاتف لجدول المستخدمين إذا لم يكن موجوداً
        if (!Schema::hasColumn('users', 'phone')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('phone', 50)->nullable()->after('email');
            });
        }

        // 2. جدول وسائل تسجيل الدخول والتواصل الاجتماعي
        Schema::create('social_providers', function (Blueprint $table) {
            $table->id();
            $table->string('provider', 40)->unique(); // google, apple, facebook
            $table->string('name', 80); // تسجيل الدخول بحساب Google
            $table->boolean('is_enabled')->default(true);
            $table->string('client_id')->nullable(); // Client ID / App ID
            $table->string('client_secret')->nullable(); // Client Secret
            $table->string('redirect_url')->nullable(); // Redirect / Callback URL
            $table->string('icon', 40)->default('google');
            $table->integer('sort_order')->default(0);
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('social_providers');
        if (Schema::hasColumn('users', 'phone')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('phone');
            });
        }
    }
};

