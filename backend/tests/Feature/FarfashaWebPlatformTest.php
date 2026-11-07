<?php

namespace Tests\Feature;

use App\Models\AppStoreLink;
use App\Models\ContactMessage;
use App\Models\ContentItem;
use App\Models\CountryWaitlist;
use App\Models\Game;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FarfashaWebPlatformTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    public function test_home_page_renders_successfully(): void
    {
        $response = $this->get('/');
        $response->assertStatus(200);
        $response->assertSee('فرفشة');
        $response->assertSee('أمثال شعبية');
        $response->assertSee('فرفوش');
        $response->assertSee('العب على موبايل واحد');
    }

    public function test_english_home_page_renders_successfully(): void
    {
        $response = $this->get('/en');
        $response->assertStatus(200);
        $response->assertSee('Farfasha');
    }

    public function test_games_index_renders_and_filters_work(): void
    {
        // 1. عرض كل الألعاب
        $response = $this->get('/games');
        $response->assertStatus(200);
        $response->assertSee('أمثال شعبية');
        $response->assertSee('ممنوع تقول');

        // 2. فلترة بالأوفلاين
        $responseOffline = $this->get('/games?offline=1');
        $responseOffline->assertStatus(200);
        $responseOffline->assertSee('أمثال شعبية');

        // 3. فلترة بتصنيف معين
        $responseCategory = $this->get('/games?category=' . urlencode('أمثال'));
        $responseCategory->assertStatus(200);
        $responseCategory->assertSee('أمثال شعبية');

        // 4. بحث غير مطابق يظهر حالة عدم وجود نتائج مع فرفوش
        $responseEmpty = $this->get('/games?q=لعبة_غير_موجودة_نهائيا_123');
        $responseEmpty->assertStatus(200);
        $responseEmpty->assertSee('مفيش نتائج مطابقة');
    }

    public function test_single_game_page_renders_with_rules_and_steps(): void
    {
        $game = Game::where('slug', 'amthal-shaabiya')->firstOrFail();
        $response = $this->get('/games/' . $game->slug);

        $response->assertStatus(200);
        $response->assertSee($game->name);
        $response->assertSee('طريقة اللعب خطوة بخطوة');
        $response->assertSee('نظام احتساب النقاط');
        $response->assertSee('+3 نقاط');
    }

    public function test_interactive_amthal_demo_page_and_api(): void
    {
        // 1. صفحة التحدي التفاعلي
        $response = $this->get('/games/amthal');
        $response->assertStatus(200);
        $response->assertSee('تحدي الأمثال الشعبية');

        // 2. API جلب مثل عشوائي (يجب ألا يحتوي على حقل answer المباشر)
        $apiRand = $this->getJson('/api/web/amthal/random');
        $apiRand->assertStatus(200);
        $apiRand->assertJsonStructure(['id', 'prompt', 'options', 'has_hint']);
        $this->assertArrayNotHasKey('answer', $apiRand->json(), 'يجب ألا تكون الإجابة مكشوفة في الـ API');

        $proverbId = $apiRand->json('id');
        $item = ContentItem::findOrFail($proverbId);

        // 3. طلب تلميح
        $hintRes = $this->postJson('/api/web/amthal/hint', ['id' => $proverbId]);
        $hintRes->assertStatus(200);
        $hintRes->assertJsonStructure(['hint']);

        // 4. التحقق من إجابة صحيحة مباشرة (3 نقاط)
        $verifyCorrect = $this->postJson('/api/web/amthal/verify', [
            'id' => $proverbId,
            'chosen_answer' => $item->answer,
            'used_hint' => false,
        ]);
        $verifyCorrect->assertStatus(200);
        $verifyCorrect->assertJson([
            'is_correct' => true,
            'points_earned' => 3,
        ]);

        // 5. التحقق من إجابة صحيحة بعد طلب تلميح (نقطتان)
        $verifyWithHint = $this->postJson('/api/web/amthal/verify', [
            'id' => $proverbId,
            'chosen_answer' => $item->answer,
            'used_hint' => true,
        ]);
        $verifyWithHint->assertStatus(200);
        $verifyWithHint->assertJson([
            'is_correct' => true,
            'points_earned' => 2,
        ]);

        // 6. التحقق من إجابة خاطئة (0 نقطة)
        $verifyWrong = $this->postJson('/api/web/amthal/verify', [
            'id' => $proverbId,
            'chosen_answer' => 'إجابة خاطئة مؤكدة',
            'used_hint' => false,
        ]);
        $verifyWrong->assertStatus(200);
        $verifyWrong->assertJson([
            'is_correct' => false,
            'points_earned' => 0,
        ]);
    }

    public function test_download_page_and_smart_redirects(): void
    {
        // 1. صفحة التحميل
        $response = $this->get('/download');
        $response->assertStatus(200);
        $response->assertSee('حمّل فرفشة');

        // 2. تحويل آبل الذكي
        $iosRedirect = $this->get('/go/ios');
        $iosRedirect->assertStatus(302);
        $this->assertStringContainsString('apps.apple.com', $iosRedirect->headers->get('Location'));

        // 3. تحويل أندرويد الذكي
        $androidRedirect = $this->get('/go/android');
        $androidRedirect->assertStatus(302);
        $this->assertStringContainsString('play.google.com', $androidRedirect->headers->get('Location'));

        // 4. الحماية من Open Redirect: منصة غير مسموحة لا تحول خارج الموقع
        $malicious = $this->get('/go/https://attacker.com');
        $malicious->assertStatus(302);
        $this->assertEquals(url('/download'), $malicious->headers->get('Location'));
    }

    public function test_notify_me_form_validation_and_honeypot(): void
    {
        // 1. تسجيل ناجح بموافقة صريحة
        $res = $this->postJson('/api/web/notify-me', [
            'email' => 'player@example.com',
            'country_code' => 'SA',
            'consent' => true,
            'website_hp' => '', // Honeypot فارغ
        ]);

        $res->assertStatus(200);
        $res->assertJson(['success' => true]);
        $this->assertDatabaseHas('country_waitlists', [
            'email' => 'player@example.com',
            'country_code' => 'SA',
        ]);

        // 2. روبوت يملأ حقل Honeypot يتم خداعه دون حفظ في قاعدة البيانات
        $botRes = $this->postJson('/api/web/notify-me', [
            'email' => 'spambot@example.com',
            'country_code' => 'US',
            'consent' => true,
            'website_hp' => 'I am a spam bot',
        ]);
        $botRes->assertStatus(200);
        $this->assertDatabaseMissing('country_waitlists', [
            'email' => 'spambot@example.com',
        ]);
    }

    public function test_informational_pages_render_and_legal_badges(): void
    {
        // من نحن
        $this->get('/about')->assertStatus(200)->assertSee('من نحن');

        // الأسئلة الشائعة
        $this->get('/faq')->assertStatus(200)->assertSee('الأسئلة الشائعة');

        // سياسة الخصوصية موسومة بمسودة تحتاج مراجعة قانونية
        $privacy = $this->get('/privacy');
        $privacy->assertStatus(200);
        $privacy->assertSee('تحتاج مراجعة');

        // الشروط والأحكام
        $this->get('/terms')->assertStatus(200)->assertSee('تحتاج مراجعة');

        // سياسة الكوكيز
        $this->get('/cookies')->assertStatus(200)->assertSee('ملفات تعريف الارتباط');

        // تواصل معنا
        $this->get('/contact')->assertStatus(200)->assertSee('تواصل معنا');

        // إرسال رسالة تواصل
        $contactRes = $this->postJson('/api/web/contact', [
            'name' => 'محمد سعيد',
            'email' => 'mohamed@example.com',
            'subject' => 'اقتراح لعبة جديدة',
            'message' => 'عندي فكرة ممتازة للعبة أمثال خليجية!',
            'subject_hp' => '',
        ]);
        $contactRes->assertStatus(200);
        $this->assertDatabaseHas('contact_messages', [
            'email' => 'mohamed@example.com',
        ]);
    }

    public function test_app_association_files_and_seo_files(): void
    {
        // Apple Universal Links
        $appleRes = $this->get('/.well-known/apple-app-site-association');
        $appleRes->assertStatus(200);
        $appleRes->assertJsonStructure(['applinks' => ['details']]);

        // Android App Links
        $androidRes = $this->get('/.well-known/assetlinks.json');
        $androidRes->assertStatus(200);

        // Sitemap XML
        $sitemapRes = $this->get('/sitemap.xml');
        $sitemapRes->assertStatus(200);
        $sitemapRes->assertHeader('Content-Type', 'text/xml; charset=UTF-8');
        $this->assertStringContainsString('<urlset', $sitemapRes->getContent());

        // Robots.txt
        $robotsRes = $this->get('/robots.txt');
        $robotsRes->assertStatus(200);
        $this->assertStringContainsString('User-agent:', $robotsRes->getContent());

        // 404 صفحة غير موجودة تظهر مع فرفوش
        $notFound = $this->get('/some-non-existent-page-slug');
        $notFound->assertStatus(404);
        $notFound->assertSee('فرفوش');
    }
}

