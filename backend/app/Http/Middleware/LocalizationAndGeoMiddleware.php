<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\View;
use Symfony\Component\HttpFoundation\Response;

class LocalizationAndGeoMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        // 1. تحديد اللغة: الافتراضي عربي (بدون بادئة)، والإنجليزي ببادئة /en
        $locale = 'ar';
        if ($request->segment(1) === 'en') {
            $locale = 'en';
        } elseif ($request->cookie('farfasha_locale') === 'en') {
            // تفضيل محفوظ بالكوكي إذا طلب المستخدم ذلك
        }

        App::setLocale($locale);

        // 2. تحديد البلد التقريبي: هيدر Cloudflare CF-IPCountry ثم الكوكي ثم الافتراضي
        $country = $request->cookie('farfasha_country') 
            ?: $request->header('CF-IPCountry') 
            ?: 'EG';

        $country = strtoupper(substr($country, 0, 2));

        // مشاركة المتغيرات مع كافة واجهات Blade
        View::share('currentLocale', $locale);
        View::share('isRtl', $locale === 'ar');
        View::share('currentCountry', $country);

        $response = $next($request);

        // وضع كوكي البلد إذا لم تكن موجودة
        if (!$request->hasCookie('farfasha_country')) {
            $response->cookie('farfasha_country', $country, 60 * 24 * 30); // 30 days
        }

        return $response;
    }
}
