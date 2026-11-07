<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\AppStoreLink;
use App\Models\CountryWaitlist;
use App\Models\SiteSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\View\View;

class DownloadController extends Controller
{
    /**
     * صفحة التحميل الرئيسية مع كشف نظام التشغيل والتحقق من توافر التطبيق بالبلد
     */
    public function index(Request $request): View
    {
        $userAgent = strtolower($request->header('User-Agent', ''));
        
        // 1. اكتشاف نظام التشغيل
        $os = 'desktop';
        if (str_contains($userAgent, 'iphone') || str_contains($userAgent, 'ipad') || str_contains($userAgent, 'ipod')) {
            $os = 'ios';
        } elseif (str_contains($userAgent, 'android')) {
            $os = 'android';
        }

        // 2. البلد الحالي للزائر
        $country = $request->cookie('farfasha_country') 
            ?: $request->header('CF-IPCountry') 
            ?: 'EG';
        $country = strtoupper(substr($country, 0, 2));

        // 3. جلب الروابط وتوافرها
        $iosLink = AppStoreLink::getLinkFor('ios', $country);
        $androidLink = AppStoreLink::getLinkFor('android', $country);
        $webLink = AppStoreLink::getLinkFor('web', $country);

        // هل الخدمة متاحة في بلد الزائر؟
        $isAvailableInCountry = true;
        if ($os === 'ios' && $iosLink && !$iosLink->is_available) {
            $isAvailableInCountry = false;
        } elseif ($os === 'android' && $androidLink && !$androidLink->is_available) {
            $isAvailableInCountry = false;
        }

        return view('download', [
            'os' => $os,
            'currentCountry' => $country,
            'isAvailableInCountry' => $isAvailableInCountry,
            'iosLink' => $iosLink,
            'androidLink' => $androidLink,
            'webLink' => $webLink,
        ]);
    }

    /**
     * مسارات التحويل الذكي الآمنة (/go/ios, /go/android, /go/web, /go/app)
     * محصنة بالكامل ضد ثغرة الـ Open Redirect، وتقبل فقط روابط المتاجر المعتمدة بالـ CMS
     */
    public function redirect(Request $request, string $platform): RedirectResponse
    {
        $platform = strtolower($platform);
        $country = $request->cookie('farfasha_country') 
            ?: $request->header('CF-IPCountry') 
            ?: 'EG';
        $country = strtoupper(substr($country, 0, 2));

        // التحويل الذكي العام /go/app يكتشف المنصة تلقائياً
        if ($platform === 'app') {
            $ua = strtolower($request->header('User-Agent', ''));
            if (str_contains($ua, 'iphone') || str_contains($ua, 'ipad')) {
                $platform = 'ios';
            } elseif (str_contains($ua, 'android')) {
                $platform = 'android';
            } else {
                return redirect()->to(url('/download'));
            }
        }

        // السماح بالمنصات المعتمدة فقط
        if (!in_array($platform, ['ios', 'android', 'web'])) {
            return redirect()->to(url('/download'));
        }

        $linkRecord = AppStoreLink::getLinkFor($platform, $country);

        if ($linkRecord && $linkRecord->is_available && !empty($linkRecord->store_url)) {
            $targetUrl = $linkRecord->store_url;

            // التحقق من أمان الرابط وأنه يبدأ بـ https://
            if (str_starts_with($targetUrl, 'https://')) {
                return redirect()->away($targetUrl);
            }
        }

        return redirect()->to(url('/download?unavailable=1'));
    }

    /**
     * نموذج "بلّغني لما يتاح في بلدي" مع حماية كاملة (Rate Limit + Honeypot)
     */
    public function notifyMe(Request $request): JsonResponse
    {
        // 1. حماية الـ Honeypot ضد روبوتات السبام
        if ($request->filled('website_hp')) {
            return response()->json(['message' => 'تم التسجيل بنجاح!'], 200);
        }

        // 2. تطبيق Rate Limiting لمنع التكرار (3 محاولات كل 10 دقائق لكل IP)
        $key = 'waitlist:' . $request->ip();
        if (RateLimiter::tooManyAttempts($key, 3)) {
            $seconds = RateLimiter::availableIn($key);
            return response()->json([
                'error' => "لقد قمت بمحاولات عديدة، يرجى الانتظار {$seconds} ثانية قبل المحاولة مجدداً."
            ], 429);
        }
        RateLimiter::hit($key, 600);

        // 3. التحقق من صحة المدخلات
        $validated = $request->validate([
            'email' => 'required|email|max:150',
            'country_code' => 'required|string|max:5',
            'consent' => 'required|accepted',
        ]);

        CountryWaitlist::updateOrCreate(
            ['email' => strtolower($validated['email'])],
            [
                'country_code' => strtoupper($validated['country_code']),
                'ip_address' => $request->ip(),
                'user_agent' => substr($request->userAgent() ?? '', 0, 500),
                'consent_given' => true,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'شكراً لك! سجلنا رغبتك وسنرسل لك إشعاراً فور إتاحة التطبيق في دولتك.',
        ]);
    }

    /**
     * ملف ربط تطبيق أبل الذكي (Universal Links)
     */
    public function appleAppSiteAssociation(): JsonResponse
    {
        $teamId = SiteSetting::get('apple_team_id', 'TEAMID');
        $bundleId = SiteSetting::get('apple_bundle_id', 'com.farfasha.app');
        $appId = "{$teamId}.{$bundleId}";

        return response()->json([
            'applinks' => [
                'apps' => [],
                'details' => [
                    [
                        'appID' => $appId,
                        'paths' => ['/rooms/*', '/games/*', '/join/*'],
                    ],
                ],
            ],
        ], 200, ['Content-Type' => 'application/json']);
    }

    /**
     * ملف ربط تطبيق أندرويد الذكي (App Links)
     */
    public function assetLinks(): JsonResponse
    {
        $packageName = SiteSetting::get('android_package_name', 'com.farfasha.app');
        $sha256 = SiteSetting::get('android_sha256', '00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00');

        return response()->json([
            [
                'relation' => ['delegate_permission/common.handle_all_urls'],
                'target' => [
                    'namespace' => 'android_app',
                    'package_name' => $packageName,
                    'sha256_cert_fingerprints' => [$sha256],
                ],
            ],
        ], 200, ['Content-Type' => 'application/json']);
    }

    /**
     * صفحة هبوط الانضمام الذكي للغرفة المباشرة (Deep Link & Web Join Landing)
     */
    public function joinRoomLanding(Request $request, string $code): View
    {
        $cleanCode = preg_replace('/\D/', '', $code);
        
        $room = \App\Models\Room::where('code', $cleanCode)->first();
        $game = $room ? \App\Models\Game::find($room->game_id) : null;
        $playersCount = $room ? \App\Models\RoomPlayer::where('room_id', $room->id)->where('connection_status', 'online')->count() : 0;
        
        return view('join_landing', [
            'code' => $cleanCode,
            'room' => $room,
            'game' => $game,
            'playersCount' => $playersCount,
            'deepLink' => "farafsha://join/{$cleanCode}",
            'universalLink' => url("/join/{$cleanCode}"),
        ]);
    }
}

