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
        // 1. إضافة حقول حالة الحساب لجدول المستخدمين
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'status')) {
                $table->string('status', 30)->default('active')->after('is_admin');
            }
            if (!Schema::hasColumn('users', 'deletion_requested_at')) {
                $table->timestamp('deletion_requested_at')->nullable()->after('status');
            }
        });

        // 2. إنشاء جدول طلبات حذف الحسابات
        Schema::create('account_deletion_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('status', 30)->default('pending'); // pending, approved, rejected
            $table->text('reason')->nullable();
            $table->text('admin_notes')->nullable();
            $table->timestamp('requested_at');
            $table->timestamp('reviewed_at')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('account_deletion_requests');

        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'deletion_requested_at')) {
                $table->dropColumn('deletion_requested_at');
            }
            if (Schema::hasColumn('users', 'status')) {
                $table->dropColumn('status');
            }
        });
    }
};
