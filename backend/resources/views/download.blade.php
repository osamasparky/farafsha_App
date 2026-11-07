@extends('layouts.app')

@section('title', 'تحميل تطبيق فرفشة | متوفر على App Store و Google Play')
@section('meta_description', 'حمّل تطبيق فرفشة مجاناً على جهاز الآيفون أو الأندرويد واستمتع بأفضل ألعاب اللمة العربية مع أصحابك وعيلتك.')

@section('content')
<div class="py-12 md:py-20 relative overflow-hidden" x-data="{ waitlistSent: false, waitlistLoading: false, waitlistError: null, waitlistSuccess: null }">
    
    <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 space-y-12">
        
        {{-- الترويسة الرئيسية --}}
        <div class="text-center max-w-3xl mx-auto space-y-4 flex flex-col items-center">
            <div class="w-20 h-20 md:w-24 md:h-24 rounded-3xl bg-gradient-to-br from-[#FFB25E] via-[#FF8A4C] to-[#F2569A] p-1 shadow-[0_10px_35px_rgba(242,86,154,0.5)] transition-transform hover:scale-105 mb-2">
                <img src="{{ asset('assets/app_icon.png') }}" alt="أيقونة تطبيق فرفشة" class="w-full h-full object-cover rounded-[22px]">
            </div>

            <span class="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full text-xs font-black bg-gradient-to-r from-[#FFB25E]/20 to-[#F2569A]/20 text-[#FFD27A] border border-[#FF8A4C]/30">
                📲 احصل على فرفشة لجهازك
            </span>
            <h1 class="text-3xl sm:text-4xl md:text-5xl font-black text-white leading-tight">
                اللمّة في جيبك.. حمّل فرفشة الآن مجاناً!
            </h1>
            <p class="text-base text-purple-200/90 leading-relaxed max-w-xl mx-auto">
                لو التطبيق مثبت على جهازك هيفتح فوراً، ولو لأ هتروح لصفحة المتجر الرسمية بضغطة زر.
            </p>
        </div>

        @if($isAvailableInCountry)
            {{-- حالة التوفر في البلد --}}
            <div class="glass-card p-8 md:p-14 border-[#A35BFF]/40 text-center relative overflow-hidden shadow-2xl">
                
                {{-- المنصة المكتشفة تلقائياً أولاً --}}
                <div class="mb-10">
                    <span class="text-xs font-bold text-purple-300 block mb-3 uppercase tracking-wider">
                        @if($os === 'ios')
                            تم اكتشاف جهازك: Apple (iPhone / iPad) 🍏
                        @elseif($os === 'android')
                            تم اكتشاف جهازك: Android 🤖
                        @else
                            أجهزة الكمبيوتر وسطح المكتب 💻
                        @endif
                    </span>

                    {{-- الزر الموصى به أولاً ومميزاً --}}
                    <div class="flex items-center justify-center">
                        @if($os === 'ios')
                            <x-game-button href="{{ url('/go/ios') }}" variant="primary" class="!py-4 !px-10 !text-xl shadow-[0_15px_35px_rgba(242,86,154,0.5)]">
                                <span>🍏</span>
                                <span>تحميل من App Store (آيفون)</span>
                            </x-game-button>
                        @elseif($os === 'android')
                            <x-game-button href="{{ url('/go/android') }}" variant="primary" class="!py-4 !px-10 !text-xl shadow-[0_15px_35px_rgba(242,86,154,0.5)]">
                                <span>🤖</span>
                                <span>تحميل من Google Play (أندرويد)</span>
                            </x-game-button>
                        @else
                            {{-- كود QR لأجهزة الديسكتوب --}}
                            <div class="p-6 rounded-3xl bg-white/5 border border-white/10 inline-flex flex-col items-center">
                                <div class="p-4 bg-white rounded-2xl shadow-xl mb-3">
                                    <svg class="w-36 h-36 text-black" viewBox="0 0 100 100" fill="currentColor">
                                        <path d="M10 10h30v30h-30zM15 15h20v20h-20zM22 22h6v6h-6zM60 10h30v30h-30zM65 15h20v20h-20zM72 22h6v6h-6zM10 60h30v30h-30zM15 65h20v20h-20zM22 72h6v6h-6zM50 20h6v6h-6zM50 35h6v6h-6zM60 60h6v6h-6zM70 60h10v6h-10zM60 70h6v10h-6zM75 75h15v15h-15z"/>
                                    </svg>
                                </div>
                                <span class="text-xs font-bold text-white">امسح الكود بكاميرا الجوال للتحميل الفوري</span>
                            </div>
                        @endif
                    </div>
                </div>

                {{-- باقي المنصات تظهر دائماً في الأسفل بأناقة --}}
                <div class="pt-8 border-t border-white/10">
                    <span class="text-xs text-purple-300 block mb-4 font-semibold">
                        أو اختر المنصة التي تفضلها يدوياً:
                    </span>

                    <div class="flex flex-wrap items-center justify-center gap-4">
                        @if($os !== 'ios')
                            <a href="{{ url('/go/ios') }}" class="py-2.5 px-5 rounded-xl bg-white/10 hover:bg-white/20 border border-white/15 text-white font-bold text-sm transition-all flex items-center gap-2">
                                <span>🍏</span>
                                <span>Apple App Store</span>
                            </a>
                        @endif

                        @if($os !== 'android')
                            <a href="{{ url('/go/android') }}" class="py-2.5 px-5 rounded-xl bg-white/10 hover:bg-white/20 border border-white/15 text-white font-bold text-sm transition-all flex items-center gap-2">
                                <span>🤖</span>
                                <span>Google Play Store</span>
                            </a>
                        @endif

                        {{-- نسخة الويب تظهر فقط لو رابطها موجود في الـ CMS --}}
                        @if($webLink && $webLink->is_available && !empty($webLink->store_url))
                            <a href="{{ url('/go/web') }}" class="py-2.5 px-5 rounded-xl bg-[#A35BFF]/30 hover:bg-[#A35BFF]/50 border border-[#A35BFF] text-white font-bold text-sm transition-all flex items-center gap-2">
                                <span>🌐</span>
                                <span>العب عبر المتصفح (Web App)</span>
                            </a>
                        @endif
                    </div>
                </div>

                <div class="mt-8 text-xs text-purple-300/80">
                    💡 التوافر الجغرافي: متاح رسمياً في بلدك الحالي 
                    <span class="font-bold text-[#FFD27A]">({{ $currentCountry }})</span>
                </div>

            </div>
        @else
            {{-- حالة عدم التوفر في البلد: رسالة واضحة ونموذج "بلّغني لما يتاح" --}}
            <div class="glass-card p-8 md:p-12 border-[#FF8A4C]/50 text-center max-w-2xl mx-auto shadow-2xl space-y-6">
                
                <x-farfoush expression="confused_sad" speech="للأسف فرفشة لسه موصلش متجرك في {{ $currentCountry }}.. بس مش هنسيبك! سجل بريدك وهنبلغك أول ما ينزل فوراً!" size="lg" />

                <div class="space-y-2">
                    <h2 class="text-2xl font-black text-white">التطبيق قادم قريباً لدولتك!</h2>
                    <p class="text-sm text-purple-200/80 leading-relaxed">
                        نحن نعمل على توسيع التغطية لجميع المتاجر العربية والعالمية. اترك بريدك الإلكتروني وسنرسل لك إشعاراً فور التوفر مع هدية ترحيبية!
                    </p>
                </div>

                <form @submit.prevent="
                    waitlistLoading = true;
                    waitlistError = null;
                    fetch('{{ url('/api/web/notify-me') }}', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name=\'csrf-token\']').content,
                            'Accept': 'application/json'
                        },
                        body: JSON.stringify({
                            email: $refs.waitlistEmail.value,
                            country_code: '{{ $currentCountry }}',
                            consent: $refs.waitlistConsent.checked,
                            website_hp: $refs.waitlistHp.value
                        })
                    })
                    .then(r => r.json().then(d => ({ status: r.status, data: d })))
                    .then(res => {
                        waitlistLoading = false;
                        if (res.status === 200) {
                            waitlistSent = true;
                            waitlistSuccess = res.data.message;
                            window.trackEvent('notify_signup', { country: '{{ $currentCountry }}' });
                        } else {
                            waitlistError = res.data.error || res.data.message || 'حدث خطأ، يرجى المحاولة لاحقاً.';
                        }
                    })
                    .catch(() => {
                        waitlistLoading = false;
                        waitlistError = 'تعذر الاتصال بالسيرفر، تأكد من اتصالك بالإنترنت.';
                    });
                " class="space-y-4 pt-2">
                    
                    {{-- حقل الـ Honeypot ضد روبوتات السبام --}}
                    <input type="text" x-ref="waitlistHp" name="website_hp" class="hidden" tabindex="-1" autocomplete="off">

                    <div x-show="!waitlistSent" class="space-y-4">
                        <div class="flex flex-col sm:flex-row gap-3">
                            <input type="email" 
                                   x-ref="waitlistEmail"
                                   required 
                                   placeholder="أدخل بريدك الإلكتروني..." 
                                   class="w-full bg-[#150A2E] border-2 border-purple-800 rounded-2xl px-5 py-3 text-white placeholder-purple-300/50 text-sm focus:border-[#FF8A4C] focus:outline-none">

                            <button type="submit" 
                                    :disabled="waitlistLoading"
                                    class="btn-game-primary !py-3 !px-7 !text-sm whitespace-nowrap">
                                <span x-show="!waitlistLoading">بلّغني أول ما يتاح 🔔</span>
                                <span x-show="waitlistLoading">جارٍ التسجيل...</span>
                            </button>
                        </div>

                        {{-- الموافقة الصريحة وفقاً لقوانين الخصوصية (PDPL) --}}
                        <label class="flex items-start gap-2 text-start text-xs text-purple-200/80 cursor-pointer">
                            <input type="checkbox" x-ref="waitlistConsent" required class="mt-0.5 rounded text-[#F2569A] focus:ring-0">
                            <span>أوافق على استخدام بريدي الإلكتروني لإشعاري بتوفر التطبيق وفقاً لـ <a href="{{ url('/privacy') }}" class="text-[#FFD27A] underline">سياسة الخصوصية</a>.</span>
                        </label>
                    </div>

                    {{-- رسائل النجاح أو الخطأ --}}
                    <div x-show="waitlistSent" x-transition class="p-4 rounded-2xl bg-emerald-500/20 border border-emerald-500/50 text-emerald-200 text-sm font-bold">
                        <span x-text="waitlistSuccess"></span>
                    </div>

                    <div x-show="waitlistError" x-transition class="p-3 rounded-xl bg-red-500/20 border border-red-500/50 text-red-200 text-xs">
                        <span x-text="waitlistError"></span>
                    </div>

                </form>

            </div>
        @endif

        {{-- تميمة فرفوش الترحيبية --}}
        <div class="text-center pt-4">
            <x-farfoush expression="welcome" speech="فرفوش مستنيك في اللعبة! حمّل دلوقتي وسجل رقمك في لوحة الشرف!" size="md" />
        </div>

    </div>
</div>
@endsection

