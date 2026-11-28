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
     * لوحة الترتيب والمتصدرين (مبنية ديناميكياً من المستخدمين الحقيقيين)
     */
    public function leaderboard(Request $request): JsonResponse
    {
        $period = $request->query('period', 'weekly');
        if (!in_array($period, ['weekly', 'monthly', 'all_time'])) {
            $period = 'weekly';
        }

        $authUser = $request->user('sanctum');

        $users = User::where('status', 'active')
            ->orderByDesc('total_score')
            ->orderByDesc('wins_count')
            ->orderBy('id')
            ->limit(50)
            ->get();

        $badges = [
            1 => 'بطل الترتيب 👑',
            2 => 'الوصيف 🥈',
            3 => 'المتحدي 🥉',
        ];

        $entries = $users->values()->map(function (User $user, int $index) use ($authUser, $badges) {
            $rank = $index + 1;
            $isCurrent = $authUser && $authUser->id === $user->id;

            return [
                'id' => $user->id,
                'player_name' => $user->name,
                'avatar' => $user->avatar ?: 'assets/images/av-karim.webp',
                'score' => (int) ($user->total_score ?? 0),
                'wins' => (int) ($user->wins_count ?? 0),
                'rank' => $rank,
                'badge' => $badges[$rank] ?? null,
                'is_current_user' => $isCurrent,
            ];
        });

        // المراكز الثلاثة الأولى (المنصة)
        $podium = $entries->take(3)->values();

        // باقي قائمة الترتيب
        $rankings = $entries->skip(3)->values();

        // حساب اللاعب الحالي (أنت)
        $currentUser = $entries->firstWhere('is_current_user', true);
        if (!$currentUser && $authUser) {
            $higherCount = User::where('status', 'active')
                ->where('total_score', '>', (int) ($authUser->total_score ?? 0))
                ->count();

            $currentUser = [
                'id' => $authUser->id,
                'player_name' => $authUser->name,
                'avatar' => $authUser->avatar ?: 'assets/images/av-karim.webp',
                'score' => (int) ($authUser->total_score ?? 0),
                'wins' => (int) ($authUser->wins_count ?? 0),
                'rank' => $higherCount + 1,
                'badge' => null,
                'is_current_user' => true,
            ];
        }

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
     * تسجيل نقاط اللعب المحلي / اللمة للمستخدم المسجل في لوحة المتصدرين
     */
    public function recordScore(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 'error', 'message' => 'غير مصرح'], 401);
        }

        $validated = $request->validate([
            'score' => 'required|integer|min:0|max:5000',
            'is_win' => 'nullable|boolean',
        ]);

        $score = (int) $validated['score'];
        $user->increment('games_played');
        if ($score > 0) {
            $user->increment('total_score', $score);
            $user->increment('weekly_score', $score);
            \App\Models\CrewMember::where('user_id', $user->id)->increment('weekly_score', $score);
            $crewIds = \App\Models\CrewMember::where('user_id', $user->id)->pluck('crew_id');
            if ($crewIds->isNotEmpty()) {
                \App\Models\Crew::whereIn('id', $crewIds)->increment('total_score', $score);
            }
        }
        if (!empty($validated['is_win']) && $score > 0) {
            $user->increment('wins_count');
        }

        $user->refresh();
        $calculatedLevel = Level::where('min_points', '<=', $user->total_score)
            ->orderByDesc('level_number')
            ->value('level_number') ?? 1;
        if ($calculatedLevel != $user->level) {
            $user->update(['level' => $calculatedLevel]);
        }

        return response()->json([
            'status' => 'success',
            'total_score' => (int) $user->total_score,
            'wins_count' => (int) $user->wins_count,
            'level' => (int) $user->level,
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
        $user = $request->user('sanctum') ?? auth('sanctum')->user();
        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'غير مصرح بتعديل الملف الشخصي، يرجى تسجيل الدخول أولاً.',
            ], 401);
        }

        $validated = $request->validate([
            'name' => 'nullable|string|max:100',
            'avatar' => 'nullable|string|max:500',
            'phone' => 'nullable|string|max:50|unique:users,phone,' . $user->id,
            'email' => 'nullable|email|max:150|unique:users,email,' . $user->id,
            'photo' => 'nullable|image|max:10240', // يدعم حتى 10 ميجا
        ]);

        if (!empty($validated['name'])) {
            $user->name = $validated['name'];
        }
        if (!empty($validated['avatar'])) {
            $user->avatar = $validated['avatar'];
        }
        if (!empty($validated['phone']) && $validated['phone'] !== $user->phone) {
            $user->phone = $validated['phone'];
            $user->phone_verified_at = null;
        }
        if (!empty($validated['email']) && strtolower($validated['email']) !== strtolower((string) $user->email)) {
            $user->email = strtolower(trim($validated['email']));
            $user->email_verified_at = null;
        }
        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('avatars', 'public');
            $user->avatar = '/storage/' . $path;
        }
        $user->save();

        return $this->profile($request);
    }

    /**
     * بيانات البروفايل وحساب المستوى والأوسمة بناءً على نقاط التحكم
     */
    public function profile(Request $request): JsonResponse
    {
        $isGuest = $request->query('guest') === 'true' || $request->query('guest') === '1';
        $user = $request->user('sanctum') ?? auth('sanctum')->user();

        // في حال كان زائراً
        if ($isGuest || (!$user && $request->has('guest'))) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'name' => 'زائر فرفشة',
                    'avatar' => 'assets/images/farfasha_logo.png',
                    'email' => '',
                    'phone' => '',
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

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'غير مصرح بالدخول، يرجى تسجيل الدخول أولاً.',
            ], 401);
        }

        $userName = $user->name;
        $userAvatar = !empty($user->avatar) ? $user->avatar : 'assets/images/av-ahmed.png';
        $userPhone = $user->phone ?? '';
        $userEmail = $user->email ?? '';
        $userPoints = (int) ($user->total_score ?? 0);
        $wins = (int) ($user->wins_count ?? 0);
        $gamesPlayed = (int) ($user->games_played ?? 0);

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
                    'is_max_level' => $nextLevel === null,
                    'progress_percent' => $nextLevel === null ? 100.0 : round($progress * 100, 1),
                ],
                'badges' => $badges,
            ],
        ]);
    }

    /**
     * فحص إصدار التطبيق والتحقق من التحديث الإجباري
     */
    public function checkVersion(Request $request): JsonResponse
    {
        $platform = strtolower($request->query('platform', 'android'));
        $currentBuildNumber = (int) $request->query('build_number', 0);
        $currentVersion = (string) $request->query('version', '1.0.0');

        $settings = SiteSetting::get('app_update_settings', [
            'force_update_enabled' => true,
            'min_android_build' => 8,
            'latest_android_version' => '1.0.0+8',
            'min_ios_build' => 1,
            'latest_ios_version' => '1.0.0+1',
            'title' => 'تحديث إجباري جديد متوفر 🚀',
            'message' => 'يتوفر إصدار جديد من تطبيق فرفشة بميزات وتحسينات جديدة لأداء أفضل للألعاب والصوت الجماعي. يرجى التحديث الآن للمتابعة!',
            'play_store_url' => 'https://play.google.com/store/apps/details?id=com.farafsha.app',
            'app_store_url' => 'https://apps.apple.com/app/id6738933221',
            'direct_download_url' => 'https://farafsha.com/farafsha.aab',
        ]);

        $forceEnabled = (bool) ($settings['force_update_enabled'] ?? true);
        $isIos = $platform === 'ios';

        $minBuild = $isIos
            ? (int) ($settings['min_ios_build'] ?? 1)
            : (int) ($settings['min_android_build'] ?? 8);

        $latestVersion = $isIos
            ? ($settings['latest_ios_version'] ?? '1.0.0+1')
            : ($settings['latest_android_version'] ?? '1.0.0+8');

        $storeUrl = $isIos
            ? ($settings['app_store_url'] ?? 'https://apps.apple.com/app/id6738933221')
            : ($settings['play_store_url'] ?? 'https://play.google.com/store/apps/details?id=com.farafsha.app');

        $isUpdateAvailable = $currentBuildNumber > 0 && $currentBuildNumber < $minBuild;
        $isForceUpdate = $forceEnabled && $isUpdateAvailable;

        return response()->json([
            'status' => 'success',
            'data' => [
                'is_update_available' => $isUpdateAvailable,
                'is_force_update' => $isForceUpdate,
                'current_build_number' => $currentBuildNumber,
                'min_build_number' => $minBuild,
                'latest_version' => $latestVersion,
                'title' => $settings['title'] ?? 'تحديث إجباري جديد متوفر 🚀',
                'message' => $settings['message'] ?? 'يتوفر إصدار جديد من تطبيق فرفشة بميزات وتحسينات جديدة لأداء أفضل للألعاب والصوت الجماعي. يرجى التحديث الآن للمتابعة!',
                'store_url' => $storeUrl,
                'direct_download_url' => $settings['direct_download_url'] ?? 'https://farafsha.com/farafsha.aab',
            ],
        ]);
    }
}


