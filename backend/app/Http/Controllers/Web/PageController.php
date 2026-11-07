<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\ContactMessage;
use App\Models\Game;
use App\Models\SitePage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\View\View;

class PageController extends Controller
{
    public function about(): View
    {
        $page = SitePage::where('slug', 'about')->first();
        return view('pages.show', ['page' => $page, 'slug' => 'about']);
    }

    public function faq(): View
    {
        $page = SitePage::where('slug', 'faq')->first();
        return view('pages.faq', ['page' => $page]);
    }

    public function privacy(): View
    {
        $page = SitePage::where('slug', 'privacy')->first();
        return view('pages.show', ['page' => $page, 'slug' => 'privacy', 'isLegal' => true]);
    }

    public function terms(): View
    {
        $page = SitePage::where('slug', 'terms')->first();
        return view('pages.show', ['page' => $page, 'slug' => 'terms', 'isLegal' => true]);
    }

    public function cookies(): View
    {
        $page = SitePage::where('slug', 'cookies')->first();
        return view('pages.show', ['page' => $page, 'slug' => 'cookies', 'isLegal' => true]);
    }

    public function contact(): View
    {
        return view('pages.contact');
    }

    public function submitContact(Request $request): JsonResponse
    {
        // 1. حماية Honeypot ضد الروبوتات
        if ($request->filled('subject_hp')) {
            return response()->json(['message' => 'تم إرسال رسالتك بنجاح!'], 200);
        }

        // 2. تطبيق Rate Limiter
        $key = 'contact:' . $request->ip();
        if (RateLimiter::tooManyAttempts($key, 3)) {
            $seconds = RateLimiter::availableIn($key);
            return response()->json([
                'error' => "لقد أرسلت عدة رسائل، يرجى الانتظار {$seconds} ثانية قبل المحاولة مجدداً."
            ], 429);
        }
        RateLimiter::hit($key, 300);

        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'email' => 'required|email|max:150',
            'subject' => 'nullable|string|max:150',
            'message' => 'required|string|min:5|max:2000',
        ]);

        ContactMessage::create([
            'name' => $validated['name'],
            'email' => strtolower($validated['email']),
            'subject' => $validated['subject'] ?? 'رسالة استفسار من الموقع',
            'message' => strip_tags($validated['message']),
            'ip_address' => $request->ip(),
            'status' => 'new',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'شكراً لتواصلك معنا! استلمنا رسالتك وسيرد عليك فريق فرفشة قريباً.',
        ]);
    }

    public function sitemap(): Response
    {
        $games = Game::where('is_active', true)->get();
        $pages = SitePage::where('status', 'published')->get();

        $content = view('sitemap', compact('games', 'pages'))->render();
        return response($content, 200)->header('Content-Type', 'text/xml');
    }

    public function robots(): Response
    {
        $content = "User-agent: *\nAllow: /\nDisallow: /admin\nDisallow: /api/\n\nSitemap: " . url('/sitemap.xml');
        return response($content, 200)->header('Content-Type', 'text/plain');
    }
}

