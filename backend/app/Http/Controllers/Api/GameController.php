<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Game;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GameController extends Controller
{
    /**
     * قائمة بجميع الألعاب المتاحة والنشطة مع تصنيفاتها
     */
    public function index(Request $request): JsonResponse
    {
        $category = $request->query('category');
        $mode = $request->query('mode'); // local_only, online_only, hybrid

        $query = Game::where('is_active', true)
            ->withCount(['contentItems', 'packs'])
            ->orderBy('sort_order', 'asc');

        if ($category && $category !== 'all') {
            $query->where('category', $category);
        }

        if ($mode) {
            $query->whereIn('game_mode', [$mode, 'hybrid']);
        }

        $games = $query->get();

        return response()->json([
            'status' => 'success',
            'data' => $games,
            'categories' => [
                ['id' => 'all', 'name' => 'الكل'],
                ['id' => 'أمثال', 'name' => 'أمثال شعبية'],
                ['id' => 'إفيهات', 'name' => 'أفلام ومسلسلات'],
                ['id' => 'تخمين', 'name' => 'تخمين وشخصيات'],
                ['id' => 'ذكاء وسرعة', 'name' => 'ذكاء وتحدي'],
                ['id' => 'معلومات عامة', 'name' => 'معلومات وثقافة'],
            ],
        ]);
    }

    /**
     * تفاصيل لعبة معينة
     */
    public function show(string $slug): JsonResponse
    {
        $game = Game::where('slug', $slug)
            ->where('is_active', true)
            ->with(['packs' => function ($q) {
                $q->where('is_active', true);
            }])
            ->firstOrFail();

        return response()->json([
            'status' => 'success',
            'data' => $game,
        ]);
    }

    /**
     * جلب بطاقات اللعبة لجولة لعب محلية أو لتخزينها أوفلاين
     */
    public function getCards(Request $request, string $slug): JsonResponse
    {
        $normalizedSlug = match ($slug) {
            'taboo' => 'forbidden-words',
            'quotes' => 'famous-quotes',
            'amthal' => 'amthal-shaabiya',
            default => $slug,
        };
        $game = Game::where('slug', $normalizedSlug)->firstOrFail();
        
        $limit = max(1, min($request->integer('limit', 50), 100));
        $difficulty = $request->query('difficulty');
        $packId = $request->query('pack_id');

        $query = $game->contentItems()
            ->where('status', 'published')
            ->where('is_active', true);

        if ($difficulty && $difficulty !== 'all') {
            $query->where('difficulty', $difficulty);
        }

        if ($packId) {
            $query->where('pack_id', $packId);
        }

        $cards = $query->inRandomOrder()->limit($limit)->get();

        return response()->json([
            'status' => 'success',
            'game' => [
                'id' => $game->id,
                'name' => $game->name,
                'slug' => $game->slug,
                'template_type' => $game->template_type,
                'rules_config' => $game->rules_config,
            ],
            'cards' => $cards,
        ]);
    }
}
