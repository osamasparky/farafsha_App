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
        Schema::create('content_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('game_id')->constrained()->cascadeOnDelete();
            $table->foreignId('pack_id')->nullable()->constrained()->nullOnDelete();
            
            // نوع البطاقة / السؤال
            $table->string('type')->default('card'); // card, multiple_choice, open_guess, forbidden_words
            
            // النص المعروض للمتسابقين
            $table->text('prompt'); // مثلاً: "اللي اختشوا ..." أو "يا بابا .. أنا مش زعلان ..."
            
            // الإجابة الصحيحة أو الهدف
            $table->string('answer'); // مثلاً: "ماتوا" أو "أنا متضايق بس"
            
            // الاختيارات المضللة للأسئلة متعددة الاختيارات
            $table->json('distractors')->nullable(); // ["في حظهم", "من الجوع", "من الخوف"]
            
            // الكلمات الممنوع ذكرها في لعبة "ممنوع تقول"
            $table->json('forbidden_words')->nullable(); // ["مسرح", "فنان", "ضحك"]
            
            // تلميحات متدرجة
            $table->json('hints')->nullable(); // تلميحات
            
            // بدائل إجابة مقبولة
            $table->json('acceptable_alternatives')->nullable();
            
            // شرح أو تفاصيل إضافية عن العمل أو الأصل
            $table->text('explanation')->nullable(); // مثلاً: "فيلم كذا - شخصية كذا - سنة 2005"
            $table->string('media_type')->nullable(); // image, audio, video
            $table->string('media_url')->nullable(); // مسار صورة المشهد أو الصوت
            $table->string('source_reference')->nullable(); // مصدر الحقوق والمرجع
            
            // خصائص التصنيف
            $table->string('dialect')->default('egyptian'); // egyptian, gulf, modern_standard
            $table->string('difficulty')->default('medium'); // easy, medium, hard
            $table->string('age_rating')->default('all'); // all, family, 16+
            $table->boolean('is_sensitive')->default(false);
            
            // حالة النشر والإشراف
            $table->enum('status', ['draft', 'in_review', 'approved', 'published', 'archived'])->default('published');
            $table->unsignedInteger('report_count')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('content_items');
    }
};
