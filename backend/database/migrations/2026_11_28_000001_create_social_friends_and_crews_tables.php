<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'username')) {
                $table->string('username', 32)->nullable()->unique()->after('name');
            }
            if (!Schema::hasColumn('users', 'last_seen_at')) {
                $table->timestamp('last_seen_at')->nullable()->after('avatar');
            }
            if (!Schema::hasColumn('users', 'current_room_code')) {
                $table->string('current_room_code', 12)->nullable()->after('last_seen_at');
            }
            if (!Schema::hasColumn('users', 'weekly_score')) {
                $table->unsignedInteger('weekly_score')->default(0)->after('total_score');
            }
        });

        if (!Schema::hasTable('friendships')) {
            Schema::create('friendships', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('friend_id')->constrained('users')->cascadeOnDelete();
                $table->enum('status', ['pending', 'accepted'])->default('pending');
                $table->timestamps();

                $table->unique(['user_id', 'friend_id']);
                $table->index(['friend_id', 'status']);
            });
        }

        if (!Schema::hasTable('crews')) {
            Schema::create('crews', function (Blueprint $table) {
                $table->id();
                $table->string('name', 60);
                $table->string('code', 10)->unique();
                $table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
                $table->string('badge_color', 20)->default('#A35BFF');
                $table->string('emoji', 16)->default('🔥');
                $table->unsignedInteger('total_score')->default(0);
                $table->unsignedInteger('wins_count')->default(0);
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('crew_members')) {
            Schema::create('crew_members', function (Blueprint $table) {
                $table->id();
                $table->foreignId('crew_id')->constrained('crews')->cascadeOnDelete();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->enum('role', ['owner', 'member'])->default('member');
                $table->unsignedInteger('weekly_score')->default(0);
                $table->timestamps();

                $table->unique(['crew_id', 'user_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('crew_members');
        Schema::dropIfExists('crews');
        Schema::dropIfExists('friendships');

        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'username')) {
                $table->dropUnique(['username']);
            }
            foreach (['username', 'last_seen_at', 'current_room_code', 'weekly_score'] as $col) {
                if (Schema::hasColumn('users', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
