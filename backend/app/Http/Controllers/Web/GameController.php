<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\ContentItem;
use App\Models\Game;
use Illuminate\Http\Request;
use Illuminate\View\View;

class GameController extends Controller
{
    public function index(Request $request): View
    {
        $query = Game::where('is_active', true);

        // بحث بالاسم أو الوصف
        if ($search = $request->input('q')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('subtitle', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // فلترة التصنيف
        if ($category = $request->input('category')) {
            $query->where('category', $category);
        }

        // فلترة نمط اللعب (جهاز واحد / أونلاين / هجين)
        if ($mode = $request->input('mode')) {
            if ($mode === 'local') {
                $query->whereIn('game_mode', ['local_only', 'hybrid']);
            } elseif ($mode === 'online') {
                $query->whereIn('game_mode', ['online_only', 'hybrid']);
            }
        }

        // فلترة عدد اللاعبين
        if ($players = $request->input('players')) {
            $players = (int) $players;
            $query->where('min_players', '<=', $players)
                  ->where('max_players', '>=', $players);
        }

        // فلترة إمكانية اللعب بدون إنترنت
        if ($request->has('offline') && $request->input('offline') !== '') {
            $query->where('is_offline_capable', (bool) $request->input('offline'));
        }

        // فلترة الفئة العمرية
        if ($age = $request->input('age_group')) {
            $query->where('age_group', 'like', "%{$age}%");
        }

        $games = $query->orderBy('sort_order')->get();
        $categories = Game::where('is_active', true)->distinct()->pluck('category')->filter()->values();

        return view('games.index', [
            'games' => $games,
            'categories' => $categories,
            'filters' => $request->all(),
            'totalCount' => Game::where('is_active', true)->count(),
        ]);
    }

    public function show(string $slug): View
    {
        $game = Game::where('slug', $slug)->where('is_active', true)->firstOrFail();
        
        $similarGames = Game::where('is_active', true)
            ->where('id', '!=', $game->id)
            ->where(function ($q) use ($game) {
                $q->where('category', $game->category)
                  ->orWhere('template_type', $game->template_type);
            })
            ->take(3)
            ->get();

        if ($similarGames->isEmpty()) {
            $similarGames = Game::where('is_active', true)
                ->where('id', '!=', $game->id)
                ->take(3)
                ->get();
        }

        return view('games.show', [
            'game' => $game,
            'similarGames' => $similarGames,
        ]);
    }

    public function amthalDemo(): View
    {
        $game = Game::where('slug', 'amthal-shaabiya')->firstOrFail();
        
        // جلب مثل عشوائي مبدئي بدون كشف الإجابة في الواجهة
        $item = ContentItem::where('game_id', $game->id)
            ->where('status', 'published')
            ->inRandomOrder()
            ->first();

        $initialProverb = null;
        if ($item) {
            // تجميع الخيارات بشكل عشوائي دون تحديد الصحيح منها في كود الصفحة
            $options = array_merge([$item->answer], $item->distractors ?? []);
            shuffle($options);

            $initialProverb = [
                'id' => $item->id,
                'prompt' => $item->prompt,
                'options' => $options,
            ];
        }

        return view('games.amthal', [
            'game' => $game,
            'initialProverb' => $initialProverb,
        ]);
    }
}
