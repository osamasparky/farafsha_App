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
        Schema::table('social_providers', function (Blueprint $table) {
            if (!Schema::hasColumn('social_providers', 'client_token')) {
                $table->string('client_token', 255)->nullable()->after('client_secret');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('social_providers', function (Blueprint $table) {
            if (Schema::hasColumn('social_providers', 'client_token')) {
                $table->dropColumn('client_token');
            }
        });
    }
};
