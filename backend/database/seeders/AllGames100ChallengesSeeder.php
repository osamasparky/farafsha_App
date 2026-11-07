<?php

namespace Database\Seeders;

use App\Models\ContentItem;
use App\Models\Game;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;

class AllGames100ChallengesSeeder extends Seeder
{
    /**
     * Run the database seeds to ensure every game has 100+ challenges.
     */
    public function run(): void
    {
        $jsonPath = base_path('../mobile/assets/data/seed_games.json');
        if (!File::exists($jsonPath)) {
            $this->command?->warn("Seed JSON not found at: {$jsonPath}");
            return;
        }

        $gamesData = json_decode(File::get($jsonPath), true);
        if (!is_array($gamesData)) {
            return;
        }

        foreach ($gamesData as $gData) {
            $slug = $gData['slug'] ?? null;
            if (!$slug) {
                continue;
            }

            $game = Game::where('slug', $slug)->first();
            if (!$game) {
                continue;
            }

            $cards = $gData['cards'] ?? [];
            foreach ($cards as $c) {
                ContentItem::updateOrCreate(
                    [
                        'game_id' => $game->id,
                        'prompt' => $c['prompt'],
                    ],
                    [
                        'type' => $game->template_type,
                        'answer' => $c['answer'] ?? '',
                        'distractors' => isset($c['distractors']) ? $c['distractors'] : null,
                        'forbidden_words' => isset($c['forbidden_words']) ? $c['forbidden_words'] : null,
                        'hints' => isset($c['hints']) ? $c['hints'] : null,
                        'acceptable_alternatives' => isset($c['acceptable_alternatives']) ? $c['acceptable_alternatives'] : null,
                        'explanation' => $c['explanation'] ?? '',
                        'status' => 'published',
                        'is_active' => true,
                    ]
                );
            }
        }
    }
}
