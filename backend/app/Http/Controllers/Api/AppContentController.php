<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use App\Models\Dialect;
use App\Models\LeaderboardEntry;
use App\Models\AppNotification;
use App\Models\AppPage;
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
     * قائمة اللهجات المدعومة
     */
    public function dialects(): JsonResponse
    {
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
     * معلومات التواصل والدعم الفني
     */
    public function contactInfo(): JsonResponse
    {
        $contactPage = AppPage::where('slug', 'contact-us')->first();

        $meta = $contactPage?->meta ?? [
            'email' => 'support@lammah.app',
            'whatsapp' => '+201000000000',
            'phone' => '+201200000000',
            'website' => 'https://lammah.app',
        ];

        return response()->json([
            'status' => 'success',
            'data' => [
                'title' => $contactPage?->title ?? 'التواصل والدعم الفني',
                'description' => $contactPage?->content ?? 'فريق الدعم الفني متاح لمساعدتك على مدار الساعة.',
                'meta' => $meta,
            ],
        ]);
    }
}

