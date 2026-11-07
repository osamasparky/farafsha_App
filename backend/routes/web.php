<?php

use App\Http\Controllers\Web\DownloadController;
use App\Http\Controllers\Web\GameController;
use App\Http\Controllers\Web\HomeController;
use App\Http\Controllers\Web\InteractiveAmthalController;
use App\Http\Controllers\Web\PageController;
use Illuminate\Support\Facades\Route;

// الروابط العامة باللغة العربية (بدون بادئة)
Route::get('/', [HomeController::class, 'index'])->name('home');
Route::get('/games', [GameController::class, 'index'])->name('games.index');
Route::get('/games/amthal', [GameController::class, 'amthalDemo'])->name('games.amthal');
Route::get('/games/{slug}', [GameController::class, 'show'])->name('games.show');
Route::get('/download', [DownloadController::class, 'index'])->name('download');

// الصفحات التعريفية والمعلوماتية
Route::get('/about', [PageController::class, 'about'])->name('about');
Route::get('/faq', [PageController::class, 'faq'])->name('faq');
Route::get('/contact', [PageController::class, 'contact'])->name('contact');
Route::get('/privacy', [PageController::class, 'privacy'])->name('privacy');
Route::get('/terms', [PageController::class, 'terms'])->name('terms');
Route::get('/cookies', [PageController::class, 'cookies'])->name('cookies');

// النسخة الإنجليزية ببادئة /en
Route::prefix('en')->group(function () {
    Route::get('/', [HomeController::class, 'index'])->name('en.home');
    Route::get('/games', [GameController::class, 'index'])->name('en.games.index');
    Route::get('/games/amthal', [GameController::class, 'amthalDemo'])->name('en.games.amthal');
    Route::get('/games/{slug}', [GameController::class, 'show'])->name('en.games.show');
    Route::get('/download', [DownloadController::class, 'index'])->name('en.download');
    Route::get('/about', [PageController::class, 'about'])->name('en.about');
    Route::get('/faq', [PageController::class, 'faq'])->name('en.faq');
    Route::get('/contact', [PageController::class, 'contact'])->name('en.contact');
    Route::get('/privacy', [PageController::class, 'privacy'])->name('en.privacy');
    Route::get('/terms', [PageController::class, 'terms'])->name('en.terms');
    Route::get('/cookies', [PageController::class, 'cookies'])->name('en.cookies');
});

// روابط التحويل الذكي السريع المحمية (/go/ios, /go/android, /go/web, /go/app)
Route::get('/go/{platform}', [DownloadController::class, 'redirect'])
    ->where('platform', '.*')
    ->name('go.redirect');

// ملفات الربط الذكي للتطبيقات (Universal Links & App Links)
Route::get('/.well-known/apple-app-site-association', [DownloadController::class, 'appleAppSiteAssociation']);
Route::get('/.well-known/assetlinks.json', [DownloadController::class, 'assetLinks']);

// محركات البحث والـ SEO
Route::get('/sitemap.xml', [PageController::class, 'sitemap'])->name('sitemap');
Route::get('/robots.txt', [PageController::class, 'robots'])->name('robots');

// مسارات Web APIs التفاعلية (أمثال، تنبيه التوفر، تواصل)
Route::prefix('api/web')->group(function () {
    Route::get('/amthal/random', [InteractiveAmthalController::class, 'getRandomProverb']);
    Route::post('/amthal/hint', [InteractiveAmthalController::class, 'getHint']);
    Route::post('/amthal/verify', [InteractiveAmthalController::class, 'verifyAnswer']);
    Route::post('/notify-me', [DownloadController::class, 'notifyMe']);
    Route::post('/contact', [PageController::class, 'submitContact']);
});
