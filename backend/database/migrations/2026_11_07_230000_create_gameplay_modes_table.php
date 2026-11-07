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
        Schema::create('gameplay_modes', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique(); // local, lammah, online
            $table->string('title');
            $table->text('subtitle')->nullable();
            $table->string('badge')->nullable();
            $table->string('image')->nullable();
            $table->string('highlight_color')->default('#A35BFF');
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('gameplay_modes');
    }
};

