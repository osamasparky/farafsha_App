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
            $table->string('team_id', 100)->nullable()->after('client_secret');
            $table->string('key_id', 100)->nullable()->after('team_id');
            $table->string('scopes', 255)->nullable()->after('redirect_url');
            $table->json('extra_config')->nullable()->after('notes');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('social_providers', function (Blueprint $table) {
            $table->dropColumn(['team_id', 'key_id', 'scopes', 'extra_config']);
        });
    }
};
