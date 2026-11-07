<!DOCTYPE html>
<html lang="{{ $currentLocale ?? 'ar' }}" dir="{{ ($currentLocale ?? 'ar') === 'ar' ? 'rtl' : 'ltr' }}" class="dark scroll-smooth">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>@yield('title', 'فرفشة | منصة الألعاب الجماعية العربية الأولى')</title>
    <meta name="description" content="@yield('meta_description', 'منصة فرفشة لألعاب اللمة العربية. العبوا على موبايل واحد في القعدة أو أونلاين مع أصحابك في أي مكان. أمثال، إفيهات، مين أنا، وممنوع تقول.')">
    
    {{-- وسوم Open Graph & Twitter Card --}}
    <meta property="og:title" content="@yield('title', 'فرفشة | اللمّة تحلى والضحك مضمون')">
    <meta property="og:description" content="@yield('meta_description', 'ألعاب جماعية بنكهة عربية ومحتوى متجدد. العب بدون إنترنت أو أونلاين!')">
    <meta property="og:image" content="@yield('og_image', asset('assets/proverb.png'))">
    <meta property="og:type" content="website">
    <meta property="og:locale" content="{{ ($currentLocale ?? 'ar') === 'ar' ? 'ar_AR' : 'en_US' }}">
    <meta name="twitter:card" content="summary_large_image">
    
    {{-- وسوم hreflang للغات --}}
    <link rel="alternate" hreflang="ar" href="{{ url(request()->path() === '/' || request()->path() === 'en' ? '/' : preg_replace('#^en/?#', '', request()->path())) }}">
    <link rel="alternate" hreflang="en" href="{{ url('/en/' . ltrim(preg_replace('#^en/?#', '', request()->path()), '/')) }}">
    <link rel="alternate" hreflang="x-default" href="{{ url('/') }}">

    {{-- الخطوط والأنماط --}}
    <link rel="preload" href="{{ asset('fonts/cairo-arabic-700-normal.woff2') }}" as="font" type="font/woff2" crossorigin>
    <link rel="preload" href="{{ asset('fonts/cairo-arabic-900-normal.woff2') }}" as="font" type="font/woff2" crossorigin>
    
    @vite(['resources/css/app.css', 'resources/js/app.js'])

    {{-- تحليلات Plausible أو Umami بدون كوكيز (إن وُجدت) --}}
    @php
        $plausibleDomain = \App\Models\SiteSetting::get('plausible_domain');
        $umamiId = \App\Models\SiteSetting::get('umami_website_id');
    @endphp
    @if($plausibleDomain)
        <script defer data-domain="{{ $plausibleDomain }}" src="https://plausible.io/js/script.js"></script>
    @endif
    @if($umamiId)
        <script defer src="https://cloud.umami.is/script.js" data-website-id="{{ $umamiId }}"></script>
    @endif

    {{-- Schema.org Structured Data --}}
    @yield('structured_data')
</head>
<body class="min-h-screen flex flex-col font-cairo antialiased selection:bg-[#F2569A] selection:text-white"
      x-data="{ mobileMenuOpen: false }">

    {{-- رأس الصفحة (Header) --}}
    <header class="sticky top-0 z-50 w-full backdrop-blur-xl bg-[#170B30]/85 border-b border-purple-900/40 transition-colors">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-20">
                
                {{-- الشعار والعلامة التجارية --}}
                <div class="flex items-center gap-3">
                    <a href="{{ url('/') }}" class="flex items-center gap-2.5 group">
                        <div class="relative w-10 h-10 rounded-2xl bg-gradient-to-br from-[#FFB25E] via-[#FF8A4C] to-[#F2569A] p-0.5 shadow-[0_0_15px_rgba(242,86,154,0.5)] transition-transform group-hover:scale-105">
                            <div class="w-full h-full bg-[#1F0E3D] rounded-[14px] flex items-center justify-center">
                                <span class="text-xl filter drop-shadow">👑</span>
                            </div>
                        </div>
                        <div class="flex flex-col">
                            <span class="text-2xl md:text-3xl font-black tracking-tight bg-gradient-to-r from-white via-[#FFD27A] to-[#F2569A] bg-clip-text text-transparent">
                                فرفشة
                            </span>
                            <span class="text-[10px] text-purple-300 font-semibold tracking-wider -mt-1">
                                ألعاب اللمّة العربية
                            </span>
                        </div>
                    </a>
                </div>

                {{-- روابط التنقل لسطح المكتب --}}
                <nav class="hidden md:flex items-center gap-1 lg:gap-2">
                    <a href="{{ url('/') }}" 
                       class="px-3.5 py-2 rounded-xl text-sm font-bold transition-colors {{ request()->is('/') ? 'text-[#FFD27A] bg-white/10' : 'text-purple-200 hover:text-white hover:bg-white/5' }}">
                        الرئيسية
                    </a>
                    <a href="{{ url('/games') }}" 
                       class="px-3.5 py-2 rounded-xl text-sm font-bold transition-colors {{ request()->is('games') ? 'text-[#FFD27A] bg-white/10' : 'text-purple-200 hover:text-white hover:bg-white/5' }}">
                        دليل الألعاب
                    </a>
                    <a href="{{ url('/games/amthal') }}" 
                       class="px-3.5 py-2 rounded-xl text-sm font-bold transition-colors flex items-center gap-1.5 {{ request()->is('games/amthal') ? 'text-[#FFD27A] bg-white/10' : 'text-purple-200 hover:text-white hover:bg-white/5' }}">
                        <span class="text-[#FF8A4C]">⚡</span>
                        <span>تحدي الأمثال</span>
                    </a>
                    <a href="{{ url('/faq') }}" 
                       class="px-3.5 py-2 rounded-xl text-sm font-bold transition-colors {{ request()->is('faq') ? 'text-[#FFD27A] bg-white/10' : 'text-purple-200 hover:text-white hover:bg-white/5' }}">
                        الأسئلة الشائعة
                    </a>
                    <a href="{{ url('/about') }}" 
                       class="px-3.5 py-2 rounded-xl text-sm font-bold transition-colors {{ request()->is('about') ? 'text-[#FFD27A] bg-white/10' : 'text-purple-200 hover:text-white hover:bg-white/5' }}">
                        من نحن
                    </a>
                    <a href="{{ url('/contact') }}" 
                       class="px-3.5 py-2 rounded-xl text-sm font-bold transition-colors {{ request()->is('contact') ? 'text-[#FFD27A] bg-white/10' : 'text-purple-200 hover:text-white hover:bg-white/5' }}">
                        تواصل معنا
                    </a>
                </nav>

                {{-- أدوات التفضيلات والـ CTA --}}
                <div class="hidden sm:flex items-center gap-3">
                    {{-- زر تقليل الحركة المخصص --}}
                    <button type="button" 
                            @click="$store.motion.toggle()"
                            :class="$store.motion.reduced ? 'bg-[#A35BFF]/30 text-[#FFD27A] border-[#A35BFF]' : 'bg-white/5 text-purple-300 border-white/10 hover:bg-white/10'"
                            class="p-2.5 rounded-xl border text-xs font-bold transition-colors flex items-center gap-1.5 cursor-pointer"
                            title="تبديل وضع تقليل الحركة (Reduce Motion)"
                            aria-label="تبديل وضع تقليل الحركة">
                        <span>🎬</span>
                        <span class="hidden xl:inline text-[11px]" x-text="$store.motion.reduced ? 'حركة خفيفة' : 'حركة كاملة'"></span>
                    </button>

                    {{-- محدد البلد السريع --}}
                    <div x-data="{ open: false }" class="relative">
                        <button type="button" 
                                @click="open = !open" 
                                class="px-2.5 py-2 rounded-xl bg-white/5 hover:bg-white/10 border border-white/10 text-xs font-bold text-purple-200 flex items-center gap-1.5 transition-colors cursor-pointer">
                            <span class="text-sm">
                                @if($currentCountry === 'EG') 🇪🇬 @elseif($currentCountry === 'SA') 🇸🇦 @elseif($currentCountry === 'AE') 🇦🇪 @elseif($currentCountry === 'KW') 🇰🇼 @else 🌍 @endif
                            </span>
                            <span class="uppercase font-mono">{{ $currentCountry }}</span>
                            <span class="text-[10px]">▼</span>
                        </button>
                        <div x-show="open" 
                             @click.outside="open = false" 
                             x-transition
                             class="absolute left-0 rtl:left-auto rtl:right-0 mt-2 w-36 bg-[#241050] border border-purple-700/50 rounded-xl shadow-2xl py-1 z-50 text-xs">
                            <a href="?country=EG" class="flex items-center gap-2 px-3 py-2 hover:bg-white/10 text-white font-medium">
                                <span>🇪🇬</span> مصر (EG)
                            </a>
                            <a href="?country=SA" class="flex items-center gap-2 px-3 py-2 hover:bg-white/10 text-white font-medium">
                                <span>🇸🇦</span> السعودية (SA)
                            </a>
                            <a href="?country=AE" class="flex items-center gap-2 px-3 py-2 hover:bg-white/10 text-white font-medium">
                                <span>🇦🇪</span> الإمارات (AE)
                            </a>
                            <a href="?country=KW" class="flex items-center gap-2 px-3 py-2 hover:bg-white/10 text-white font-medium">
                                <span>🇰🇼</span> الكويت (KW)
                            </a>
                            <a href="?country=ALL" class="flex items-center gap-2 px-3 py-2 hover:bg-white/10 text-white font-medium">
                                <span>🌍</span> دول أخرى (ALL)
                            </a>
                        </div>
                    </div>

                    {{-- زر التحميل البارز ثلاثي الأبعاد --}}
                    <x-game-button href="{{ url('/download') }}" variant="primary" class="!py-2 !px-5 !text-sm !min-h-[44px]">
                        <span>🚀</span>
                        <span>حمّل التطبيق</span>
                    </x-game-button>
                </div>

                {{-- زر القائمة للموبايل --}}
                <div class="flex items-center gap-2 md:hidden">
                    <x-game-button href="{{ url('/download') }}" variant="primary" class="!py-1.5 !px-3.5 !text-xs !min-h-[38px]">
                        <span>🚀 حمّل</span>
                    </x-game-button>

                    <button type="button" 
                            @click="mobileMenuOpen = !mobileMenuOpen" 
                            class="p-2.5 rounded-xl bg-white/5 border border-white/10 text-purple-200 hover:text-white"
                            aria-label="فتح القائمة الرئيسية">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path x-show="!mobileMenuOpen" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16m-7 6h7"/>
                            <path x-show="mobileMenuOpen" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>

            </div>
        </div>

        {{-- القائمة المنسدلة لشاشات الجوال --}}
        <div x-show="mobileMenuOpen" 
             x-transition 
             class="md:hidden border-t border-purple-900/40 bg-[#170B30]/95 px-4 pt-3 pb-6 space-y-2">
            <a href="{{ url('/') }}" class="block px-3 py-2 rounded-lg text-base font-bold text-white hover:bg-white/10">الرئيسية</a>
            <a href="{{ url('/games') }}" class="block px-3 py-2 rounded-lg text-base font-bold text-white hover:bg-white/10">دليل الألعاب</a>
            <a href="{{ url('/games/amthal') }}" class="block px-3 py-2 rounded-lg text-base font-bold text-[#FFD27A] hover:bg-white/10">⚡ تحدي الأمثال التفاعلي</a>
            <a href="{{ url('/faq') }}" class="block px-3 py-2 rounded-lg text-base font-bold text-white hover:bg-white/10">الأسئلة الشائعة</a>
            <a href="{{ url('/about') }}" class="block px-3 py-2 rounded-lg text-base font-bold text-white hover:bg-white/10">من نحن</a>
            <a href="{{ url('/contact') }}" class="block px-3 py-2 rounded-lg text-base font-bold text-white hover:bg-white/10">تواصل معنا</a>
            <div class="pt-4 border-t border-white/10 flex items-center justify-between">
                <button type="button" @click="$store.motion.toggle()" class="text-xs font-bold text-purple-300">
                    🎬 وضع تقليل الحركة
                </button>
                <a href="{{ url('/download') }}" class="text-xs font-bold text-[#FF8A4C]">
                    📱 صفحة التحميل
                </a>
            </div>
        </div>
    </header>

    {{-- المحتوى الرئيسي للصفحة --}}
    <main class="flex-grow">
        @yield('content')
    </main>

    {{-- تذييل الصفحة الشامل (Comprehensive Footer) --}}
    <footer class="mt-20 border-t border-purple-900/40 bg-[#120826]/90 relative overflow-hidden">
        {{-- لمعة خلفية خفيفة --}}
        <div class="absolute top-0 left-1/2 -translate-x-1/2 w-3/4 h-24 bg-gradient-to-b from-[#A35BFF]/10 to-transparent blur-3xl pointer-events-none"></div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-14">
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10">
                
                {{-- النبذة والعلامة التجارية --}}
                <div class="lg:col-span-2 space-y-4">
                    <div class="flex items-center gap-2.5">
                        <span class="text-2xl font-black bg-gradient-to-r from-white via-[#FFD27A] to-[#F2569A] bg-clip-text text-transparent">
                            فرفشة
                        </span>
                        <span class="text-xs px-2.5 py-0.5 rounded-full bg-[#A35BFF]/30 text-purple-200 font-bold border border-[#A35BFF]/40">
                            Party Games
                        </span>
                    </div>
                    <p class="text-sm text-purple-200/80 leading-relaxed max-w-sm">
                        منصة الألعاب الجماعية العربية الأولى. صُممت خصيصاً لإعادة الدفء والضحك والتحدي الحقيقي لجلسات العائلات والأصدقاء بدون تعقيد.
                    </p>
                    <div class="flex items-center gap-3 pt-2">
                        <a href="https://twitter.com" target="_blank" rel="noopener noreferrer" class="w-9 h-9 rounded-xl bg-white/5 hover:bg-[#A35BFF]/30 border border-white/10 flex items-center justify-center text-sm transition-all hover:scale-105" aria-label="X Twitter">
                            𝕏
                        </a>
                        <a href="https://instagram.com" target="_blank" rel="noopener noreferrer" class="w-9 h-9 rounded-xl bg-white/5 hover:bg-[#F2569A]/30 border border-white/10 flex items-center justify-center text-sm transition-all hover:scale-105" aria-label="Instagram">
                            📸
                        </a>
                        <a href="https://tiktok.com" target="_blank" rel="noopener noreferrer" class="w-9 h-9 rounded-xl bg-white/5 hover:bg-[#FF8A4C]/30 border border-white/10 flex items-center justify-center text-sm transition-all hover:scale-105" aria-label="TikTok">
                            🎵
                        </a>
                        <a href="mailto:support@farfasha.app" class="w-9 h-9 rounded-xl bg-white/5 hover:bg-[#FFC24B]/30 border border-white/10 flex items-center justify-center text-sm transition-all hover:scale-105" aria-label="Email Support">
                            ✉️
                        </a>
                    </div>
                </div>

                {{-- العمود 1: استكشف الألعاب --}}
                <div>
                    <h4 class="text-sm font-black text-white uppercase tracking-wider mb-4 border-b border-white/10 pb-2">
                        استكشف
                    </h4>
                    <ul class="space-y-2.5 text-sm text-purple-200/80">
                        <li><a href="{{ url('/games') }}" class="hover:text-white transition-colors">كل الألعاب</a></li>
                        <li><a href="{{ url('/games/amthal') }}" class="hover:text-white transition-colors text-[#FFD27A] font-bold">⚡ لعبة الأمثال التفاعلية</a></li>
                        <li><a href="{{ url('/games/famous-quotes') }}" class="hover:text-white transition-colors">جمل مشهورة وإفيهات</a></li>
                        <li><a href="{{ url('/games/who-am-i') }}" class="hover:text-white transition-colors">مين أنا؟</a></li>
                        <li><a href="{{ url('/games/forbidden-words') }}" class="hover:text-white transition-colors">ممنوع تقول (تابو)</a></li>
                    </ul>
                </div>

                {{-- العمود 2: التحميل والمتاجر --}}
                <div>
                    <h4 class="text-sm font-black text-white uppercase tracking-wider mb-4 border-b border-white/10 pb-2">
                        التطبيقات والمتاجر
                    </h4>
                    <ul class="space-y-2.5 text-sm text-purple-200/80">
                        <li><a href="{{ url('/download') }}" class="hover:text-white transition-colors">صفحة التحميل الرئيسية</a></li>
                        <li><a href="{{ url('/go/ios') }}" class="hover:text-white transition-colors">تحميل لـ iPhone / iPad</a></li>
                        <li><a href="{{ url('/go/android') }}" class="hover:text-white transition-colors">تحميل لـ أندرويد</a></li>
                        <li><a href="{{ url('/go/web') }}" class="hover:text-white transition-colors">إصدار المتصفح (الويب)</a></li>
                    </ul>
                </div>

                {{-- العمود 3: الدعم والقانونية --}}
                <div>
                    <h4 class="text-sm font-black text-white uppercase tracking-wider mb-4 border-b border-white/10 pb-2">
                        عن فرفشة
                    </h4>
                    <ul class="space-y-2.5 text-sm text-purple-200/80">
                        <li><a href="{{ url('/about') }}" class="hover:text-white transition-colors">من نحن</a></li>
                        <li><a href="{{ url('/faq') }}" class="hover:text-white transition-colors">الأسئلة الشائعة</a></li>
                        <li><a href="{{ url('/contact') }}" class="hover:text-white transition-colors">تواصل معنا</a></li>
                        <li><a href="{{ url('/privacy') }}" class="hover:text-white transition-colors">سياسة الخصوصية</a></li>
                        <li><a href="{{ url('/terms') }}" class="hover:text-white transition-colors">الشروط والأحكام</a></li>
                        <li><a href="{{ url('/cookies') }}" class="hover:text-white transition-colors">سياسة الكوكيز</a></li>
                    </ul>
                </div>

            </div>

            {{-- الشريط السفلي والحقوق --}}
            <div class="mt-12 pt-8 border-t border-purple-900/30 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-purple-300/70">
                <p>© {{ date('Y') }} فرفشة (Farfasha). جميع الحقوق محفوظة لجمعات الأهل والأصدقاء.</p>
                <div class="flex items-center gap-4">
                    <span>صُنعت بكل ❤️ في مصر والعالم العربي</span>
                    <a href="{{ url('/sitemap.xml') }}" class="hover:text-white">خريطة الموقع</a>
                </div>
            </div>
        </div>
    </footer>

</body>
</html>
