<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\ContentItem;
use App\Models\Game;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InteractiveAmthalController extends Controller
{
    /**
     * جلب مثل عشوائي للعبة التفاعلية دون إرسال الإجابة الصحيحة للواجهة
     */
    public function getRandomProverb(Request $request): JsonResponse
    {
        $amthalGame = Game::where('slug', 'amthal-shaabiya')->first();
        if (!$amthalGame) {
            return response()->json(['error' => 'Game not found'], 404);
        }

        $excludeId = $request->query('exclude_id');

        $query = ContentItem::where('game_id', $amthalGame->id)
            ->where('status', 'published');

        if ($excludeId) {
            $query->where('id', '!=', $excludeId);
        }

        $item = $query->inRandomOrder()->first();

        if (!$item) {
            $item = ContentItem::where('game_id', $amthalGame->id)
                ->where('status', 'published')
                ->inRandomOrder()
                ->first();
        }

        if (!$item) {
            return response()->json(['error' => 'No proverbs found'], 404);
        }

        // خلط الإجابة مع الاختيارات المضللة دون كشف الإجابة الصحيحة للعميل
        $options = array_merge([$item->answer], $item->distractors ?? []);
        shuffle($options);

        return response()->json([
            'id' => $item->id,
            'prompt' => $item->prompt,
            'options' => $options,
            'has_hint' => !empty($item->hints),
        ]);
    }

    /**
     * جلب تلميح المثل من السيرفر
     */
    public function getHint(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id' => 'required|exists:content_items,id',
        ]);

        $item = ContentItem::findOrFail($validated['id']);
        $hints = $item->hints ?? [];
        $hintText = is_array($hints) ? ($hints[0] ?? 'فكر في سياق المثل ومناسبته!') : $hints;

        return response()->json([
            'hint' => $hintText,
        ]);
    }

    /**
     * التحقق من إجابة المتسابق بأمان تام على السيرفر
     */
    public function verifyAnswer(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id' => 'required|exists:content_items,id',
            'chosen_answer' => 'required|string',
            'used_hint' => 'boolean',
        ]);

        $item = ContentItem::findOrFail($validated['id']);
        
        $isCorrect = trim($validated['chosen_answer']) === trim($item->answer);
        $usedHint = (bool) ($validated['used_hint'] ?? false);

        // احتساب النقاط: 3 بدون تلميح، 2 مع تلميح، 0 للخطأ
        $pointsEarned = 0;
        if ($isCorrect) {
            $pointsEarned = $usedHint ? 2 : 3;
        }

        return response()->json([
            'is_correct' => $isCorrect,
            'correct_answer' => $item->answer,
            'points_earned' => $pointsEarned,
            'explanation' => $item->explanation ?? 'مثل شعبي تراثي شهير يتداوله الناس في المواقف المشابهة.',
            'mascot_message' => $isCorrect 
                ? 'يا لعيب! إجابة صحيحة وفي الجون! فرفوش مبسوط منك 🎉' 
                : 'قريبة بس مش بالظبط! متقلقش، فرفوش بيشجعك تجرّب مثل تاني 💪',
        ]);
    }
}
