<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use App\Models\Dialect;
use App\Models\LeaderboardEntry;
use App\Models\AppNotification;
use App\Models\AppPage;
use App\Models\Badge;
use App\Models\Level;
use App\Models\SiteSetting;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AppContentController extends Controller
{
    /**
     * البنرات الإعلانية والترويجية النشطة
     */
    public function banners(): JsonResponse
    {
        $banners = Banner::where('is_active', true)
            ->orderBy('sort_order', 'asc')
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $banners,
        ]);
    }

    /**
     * قائمة اللهجات المدعومة (تعتمد على تفعيل الإدارة وحالة النشاط)
     */
    public function dialects(): JsonResponse
    {
        $dialectsEnabled = (bool) SiteSetting::get('dialects_enabled', false);
        if (!$dialectsEnabled) {
            return response()->json([
                'status' => 'success',
                'data' => [],
            ]);
        }

        $dialects = Dialect::where('is_active', true)
            ->orderBy('sort_order', 'asc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $dialects,
        ]);
    }

    /**
     * لوحة الترتيب والمتصدرين (مفصولة حسب الفترة)
     */
    public function leaderboard(Request $request): JsonResponse
    {
        $period = $request->query('period', 'weekly');
        if (!in_array($period, ['weekly', 'monthly', 'all_time'])) {
            $period = 'weekly';
        }

        $entries = LeaderboardEntry::where('period_type', $period)
            ->orderBy('score', 'desc')
            ->get();

        // المراكز الثلاثة الأولى (المنصة)
        $podium = $entries->take(3)->values();

        // باقي قائمة الترتيب
        $rankings = $entries->skip(3)->values();

        // حساب اللاعب الحالي (أنت)
        $currentUser = $entries->firstWhere('is_current_user', true);

        return response()->json([
            'status' => 'success',
            'period' => $period,
            'data' => [
                'podium' => $podium,
                'rankings' => $rankings,
                'current_user' => $currentUser,
                'all' => $entries,
            ],
        ]);
    }

    /**
     * قائمة الإشعارات
     */
    public function notifications(): JsonResponse
    {
        $notifications = AppNotification::where('is_active', true)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $notifications,
        ]);
    }

    /**
     * جلب صفحة محتوى ثابتة (سياسة الخصوصية، الشروط، المساعدة)
     */
    public function page(string $slug): JsonResponse
    {
        $page = AppPage::where('slug', $slug)
            ->where('is_active', true)
            ->first();

        if (!$page) {
            return response()->json([
                'status' => 'error',
                'message' => 'الصفحة غير موجودة',
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $page,
        ]);
    }

    /**
     * قائمة الأوسمة والإنجازات النشطة مرتبة
     */
    public function badges(Request $request): JsonResponse
    {
        $badges = Badge::with('game:id,name,slug')
            ->where('is_active', true)
            ->orderBy('sort_order', 'asc')
            ->get();

        $userPoints = (int) $request->query('user_points', 4320);

        $mapped = $badges->map(function ($badge) use ($userPoints) {
            $data = $badge->toArray();
            $data['is_unlocked'] = $userPoints >= $badge->required_points;
            $data['progress'] = min(1.0, $badge->required_points > 0 ? ($userPoints / $badge->required_points) : 1.0);
            return $data;
        });

        return response()->json([
            'status' => 'success',
            'data' => $mapped,
        ]);
    }

    /**
     * قائمة المستويات والرتب
     */
    public function levels(): JsonResponse
    {
        $levels = Level::orderBy('level_number', 'asc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $levels,
        ]);
    }

    /**
     * تحديث بيانات البروفايل (الاسم، الأفاتار، الهاتف، البريد، والصورة المرفوعة)
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'nullable|string|max:100',
            'avatar' => 'nullable|string|max:500',
            'phone' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:150',
            'photo' => 'nullable|image|max:10240', // يدعم حتى 10 ميجا
        ]);

        $user = $request->user() ?? User::find(1);
        if ($user) {
            if (!empty($validated['name'])) {
                $user->name = $validated['name'];
            }
            if (!empty($validated['avatar'])) {
                $user->avatar = $validated['avatar'];
            }
            if (!empty($validated['phone'])) {
                $user->phone = $validated['phone'];
            }
            if (!empty($validated['email'])) {
                $user->email = $validated['email'];
            }
            if ($request->hasFile('photo')) {
                $path = $request->file('photo')->store('avatars', 'public');
                $user->avatar = '/storage/' . $path;
            }
            $user->save();
        }

        return $this->profile($request);
    }

    /**
     * بيانات البروفايل وحساب المستوى والأوسمة بناءً على نقاط التحكم
     */
    public function profile(Request $request): JsonResponse
    {
        $isGuest = $request->query('guest') === 'true' || $request->query('guest') === '1';
        if ($isGuest) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'name' => 'زائر فرفشة',
                    'avatar' => 'assets/images/farfasha_logo.png',
                    'is_guest' => true,
                    'total_points' => 0,
                    'wins' => 0,
                    'games_played' => 0,
                    'level' => [
                        'level_number' => 1,
                        'title' => 'ضيف جديد',
                        'color' => '#A35BFF',
                        'icon' => 'person',
                        'current_points' => 0,
                        'points_in_level' => 0,
                        'needed_for_next' => 100,
                        'next_level_min' => 100,
                        'progress_percent' => 0.0,
                    ],
                    'badges' => [],
                ],
            ]);
        }

        $user = $request->user() ?? User::find(1);
        $userName = $user?->name ?? 'أسامة صبري';
        $userAvatar = !empty($user?->avatar) ? $user->avatar : 'assets/images/av-ahmed.png';
        $userPhone = $user?->phone ?? '01012345678';
        $userEmail = $user?->email ?? 'osama@farfasha.app';
        $userPoints = $user?->total_score ?? 4320;
        $wins = $user?->wins_count ?? 32;
        $gamesPlayed = $user?->games_played ?? 148;

        // حساب المستوى بناءً على جدول المستويات في قاعدة البيانات
        $levels = Level::orderBy('level_number', 'asc')->get();
        $currentLevel = $levels->where('min_points', '<=', $userPoints)->last() ?? $levels->first();
        $nextLevel = $levels->where('level_number', '>', $currentLevel?->level_number ?? 1)->first();

        $currentMin = $currentLevel?->min_points ?? 0;
        $nextMin = $nextLevel?->min_points ?? ($currentMin + 1000);
        $pointsInLevel = max(0, $userPoints - $currentMin);
        $neededForNext = max(1, $nextMin - $currentMin);
        $progress = min(1.0, $pointsInLevel / $neededForNext);

        // جلب الأوسمة مع حالة الفتح
        $badges = Badge::with('game:id,name,slug')
            ->where('is_active', true)
            ->orderBy('sort_order', 'asc')
            ->get()
            ->map(function ($b) use ($userPoints) {
                $arr = $b->toArray();
                $arr['is_unlocked'] = $userPoints >= $b->required_points;
                return $arr;
            });

        return response()->json([
            'status' => 'success',
            'data' => [
                'name' => $userName,
                'avatar' => $userAvatar,
                'email' => $userEmail,
                'phone' => $userPhone,
                'is_guest' => false,
                'total_points' => $userPoints,
                'wins' => $wins,
                'games_played' => $gamesPlayed,
                'level' => [
                    'level_number' => $currentLevel?->level_number ?? 1,
                    'title' => $currentLevel?->title ?? 'مبتدئ اللمّة',
                    'color' => $currentLevel?->color ?? '#FFD27A',
                    'icon' => $currentLevel?->icon ?? 'star',
                    'current_points' => $userPoints,
                    'points_in_level' => $pointsInLevel,
                    'needed_for_next' => $neededForNext,
                    'next_level_min' => $nextMin,
                    'progress_percent' => round($progress * 100, 1),
                ],
                'badges' => $badges,
            ],
        ]);
    }
}


