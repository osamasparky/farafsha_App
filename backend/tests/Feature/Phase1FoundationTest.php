<?php

namespace Tests\Feature;

use App\Models\AppStoreLink;
use App\Models\ContentItem;
use App\Models\Game;
use App\Models\SitePage;
use App\Models\SiteSetting;
use App\Models\Testimonial;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class Phase1FoundationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    public function test_games_have_unified_model_and_web_attributes(): void
    {
        $game = Game::where('slug', 'amthal-shaabiya')->first();
        $this->assertNotNull($game, 'لعبة أمثال شعبية يجب أن تكون موجودة');
        $this->assertTrue($game->is_offline_capable);
        $this->assertIsArray($game->how_to_play_steps);
        $this->assertIsArray($game->scoring_guide);
        $this->assertIsArray($game->example_round);
        $this->assertNotEmpty($game->seo_title);
    }

    public function test_site_pages_blocks_and_translations(): void
    {
        $homePage = SitePage::where('slug', 'home')->first();
        $this->assertNotNull($homePage);
        $this->assertEquals('الرئيسية', $homePage->getTranslation('title', 'ar'));
        $this->assertEquals('Home', $homePage->getTranslation('title', 'en'));
        $this->assertIsArray($homePage->blocks);
        $this->assertTrue($homePage->isPublished());
    }

    public function test_testimonials_approved_scope_and_translations(): void
    {
        $testimonial = Testimonial::create([
            'author_name' => 'أحمد مصطفى',
            'source' => 'App Store',
            'rating' => 5,
            'content' => ['ar' => 'أحسن لعبة لعبناها في لمّة العيلة!', 'en' => 'Best party game ever!'],
            'country_code' => 'EG',
            'is_approved' => true,
        ]);

        $approved = Testimonial::approved()->get();
        $this->assertTrue($approved->contains($testimonial));
    }

    public function test_app_store_links_resolution_by_country(): void
    {
        $link = AppStoreLink::getLinkFor('ios', 'EG');
        $this->assertNotNull($link);
        $this->assertEquals('ios', $link->platform);
    }

    public function test_site_settings_helper_and_caching(): void
    {
        SiteSetting::set('test_key', 'test_value', 'general');
        $this->assertEquals('test_value', SiteSetting::get('test_key'));
    }

    public function test_spatie_roles_and_permissions_assigned(): void
    {
        $this->assertTrue(Role::where('name', 'مدير')->exists());
        $this->assertTrue(Role::where('name', 'محرر')->exists());
        $this->assertTrue(Role::where('name', 'كاتب')->exists());
    }

    public function test_content_items_seeded_for_amthal_demo(): void
    {
        $amthalGame = Game::where('slug', 'amthal-shaabiya')->first();
        $this->assertNotNull($amthalGame);
        $itemsCount = ContentItem::where('game_id', $amthalGame->id)->count();
        $this->assertGreaterThanOrEqual(5, $itemsCount, 'يجب أن يتوفر على الأقل 5 أمثال شعبية');
    }
}
