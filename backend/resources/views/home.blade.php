@extends('layouts.app')

@section('title', 'فرفشة | منصة الألعاب الجماعية العربية الأولى - اللمّة تحلى والضحك مضمون')
@section('meta_description', 'اجمع أصحابك وعيلتك والعبوا على موبايل واحد في القعدة أو أونلاين. أمثال شعبية، إفيهات، مين أنا، وممنوع تقول، بدون إنترنت ومحتوى متجدد.')

@section('structured_data')
<script type="application/ld+json">
{!! json_encode([
    '@context' => 'https://schema.org',
    '@type' => 'MobileApplication',
    'name' => 'فرفشة (Farfasha)',
    'operatingSystem' => 'iOS, Android',
    'applicationCategory' => 'GameApplication',
    'offers' => [
        '@type' => 'Offer',
        'price' => '0',
        'priceCurrency' => 'USD',
    ],
    'description' => 'منصة الألعاب الجماعية العربية الأولى للمات الأهل والأصدقاء على جهاز واحد أو أونلاين.',
    'inLanguage' => ['ar', 'en'],
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT) !!}
</script>
@endsection

@section('content')

{{-- 1. قسم البطل (Hero Section) --}}
<section class="relative pt-12 pb-20 md:pt-20 md:pb-28 overflow-hidden">
    {{-- هالات ضوئية خلفية متوهجة --}}
    <div class="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-gradient-to-tr from-[#F2569A]/20 via-[#A35BFF]/25 to-transparent blur-3xl pointer-events-none rounded-full"></div>

    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            
            {{-- الجانب النصي ودعوة الإجراء --}}
            <div class="lg:col-span-7 text-center lg:text-start space-y-6">
                
                {{-- شارة أعلى العنوان --}}
                <div class="inline-flex items-center gap-2.5 px-3.5 py-1 rounded-full bg-white/5 border border-[#A35BFF]/40 text-purple-200 text-xs md:text-sm font-bold backdrop-blur-md shadow-sm">
                    <img src="{{ asset('assets/app_icon.png') }}" alt="أيقونة فرفشة" class="w-5 h-5 rounded-md object-cover">
                    <span>المنصة العربية الأولى لألعاب اللمّة والتحدي</span>
                </div>

                {{-- العنوان الرئيسي البارز --}}
                <h1 class="text-4xl sm:text-5xl lg:text-6xl font-black text-white leading-[1.2] tracking-tight">
                    اللمّة تحلى.. والضحك مضمون مع 
                    <span class="bg-gradient-to-r from-[#FFB25E] via-[#FF8A4C] to-[#F2569A] bg-clip-text text-transparent drop-shadow-sm">
                        «فرفشة»!
                    </span>
                </h1>

                {{-- النص التعريفي --}}
                <p class="text-lg md:text-xl text-purple-200/90 leading-relaxed max-w-2xl mx-auto lg:mx-0">
                    انسَ الشاشات الفردية ورجّع الدفء والضحك لقعدتك. العبوا على موبايل واحد بيلف بينكم، أو ادخلوا غرفة أونلاين مع أصحابكم في أي بلد بلمسة زر وبدون إنترنت في معظم الألعاب!
                </p>

                {{-- أزرار الإجراء الأساسية ثلاثية الأبعاد --}}
                <div class="pt-4 flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
                    <x-game-button href="{{ url('/download') }}" variant="primary" class="w-full sm:w-auto text-lg !py-3.5 !px-8">
                        <span>🚀</span>
                        <span>حمّل التطبيق مجاناً</span>
                    </x-game-button>

                    <x-game-button href="{{ url('/games') }}" variant="secondary" class="w-full sm:w-auto text-base !py-3.5 !px-6">
                        <span>🎲</span>
                        <span>اكتشف الألعاب الستة</span>
                    </x-game-button>
                </div>

                {{-- مؤشرات التوفر --}}
                <div class="pt-3 flex flex-wrap items-center justify-center lg:justify-start gap-6 text-xs text-purple-300 font-semibold">
                    <div class="flex items-center gap-1.5">
                        <span class="text-emerald-400">✓</span>
                        <span>متوفر على App Store & Google Play</span>
                    </div>
                    <div class="flex items-center gap-1.5">
                        <span class="text-emerald-400">✓</span>
                        <span>يعمل أوفلاين بدون إنترنت</span>
                    </div>
                    <div class="flex items-center gap-1.5">
                        <span class="text-emerald-400">✓</span>
                        <span>وضع عائلي آمن 100%</span>
                    </div>
                </div>

            </div>

            {{-- جانب فرفوش والمشهد المرح --}}
            <div class="lg:col-span-5 flex flex-col items-center justify-center relative">
                <div class="relative w-full max-w-md p-6 glass-card border-[#A35BFF]/40 text-center">
                    
                    {{-- تميمة فرفوش الترحيبية --}}
                    <x-farfoush expression="welcome" 
                                speech="منوّر يا فرفوش! جاهز تولّع القعدة ضحك وتحدي مع صحابك؟ 🥳" 
                                size="lg" />

                    <div class="mt-6 pt-5 border-t border-white/10 space-y-2">
                        <div class="text-sm font-bold text-white">
                            ألعاب عربية مصممة لقعداتنا
                        </div>
                        <p class="text-xs text-purple-200/70">
                            أمثال شعبية، إفيهات أفلام، شخصيات، وممنوع تقول!
                        </p>
                    </div>

                    {{-- زر تجربة مثل سريع --}}
                    <div class="mt-4">
                        <a href="{{ url('/games/amthal') }}" class="inline-flex items-center gap-2 text-xs font-black text-[#FFD27A] hover:text-white transition-colors bg-white/5 hover:bg-white/10 px-4 py-2 rounded-full border border-[#FFC24B]/30">
                            <span>⚡ جرّب لعبة الأمثال التفاعلية أونلاين الآن</span>
                            <span class="rtl:rotate-180">➔</span>
                        </a>
                    </div>
                </div>
            </div>

        </div>
    </div>
</section>

{{-- 2. فكرة فرفشة في 3 نقاط (Value Props) --}}
<section class="py-16 relative">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="text-center max-w-3xl mx-auto mb-14 space-y-3">
            <span class="text-xs md:text-sm font-black text-[#FFC24B] tracking-wider uppercase">
                ليه فرفشة في كل قعدة؟
            </span>
            <h2 class="text-3xl md:text-4xl font-black text-white">
                فكرة فرفشة.. بسيطة ومفيهاش وجع دماغ
            </h2>
            <p class="text-base text-purple-200/80">
                مش محتاجين تنزيلات معقدة ولا كل واحد يفضل عينه في شاشته؛ الهدف هو القعدة نفسها!
            </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            
            {{-- بطاقة 1: موبايل واحد --}}
            <div class="glass-card p-8 text-center relative group hover:-translate-y-2">
                <div class="w-16 h-16 rounded-2xl bg-gradient-to-tr from-[#FFB25E] to-[#FF8A4C] mx-auto flex items-center justify-center text-3xl shadow-lg mb-6 group-hover:scale-110 transition-transform">
                    📱
                </div>
                <h3 class="text-xl font-black text-white mb-3">العب على موبايل واحد</h3>
                <p class="text-sm text-purple-200/80 leading-relaxed">
                    لفة واحدة تكفي القعدة كلها. وضع Pass & Play يخلي الموبايل يدور بين اللاعبين مع شاشة أمان سرية عشان محدش يبص في دور غيره.
                </p>
            </div>

            {{-- بطاقة 2: أونلاين مع أصحابك --}}
            <div class="glass-card p-8 text-center relative group hover:-translate-y-2 border-[#A35BFF]/50 shadow-[0_10px_30px_rgba(163,91,255,0.2)]">
                <div class="w-16 h-16 rounded-2xl bg-gradient-to-tr from-[#A35BFF] to-[#7A2FE0] mx-auto flex items-center justify-center text-3xl shadow-lg mb-6 group-hover:scale-110 transition-transform">
                    🌐
                </div>
                <h3 class="text-xl font-black text-white mb-3">أونلاين مع صحابك البعيدين</h3>
                <p class="text-sm text-purple-200/80 leading-relaxed">
                    رمز غرفة من 6 أرقام كفيل يجمع شملك مع أصحابك حتى لو كل واحد في قارة مختلفة؛ مزامنة فورية بالثانية وشات وتحدي حقيقي.
                </p>
            </div>

            {{-- بطاقة 3: محتوى بيتجدد --}}
            <div class="glass-card p-8 text-center relative group hover:-translate-y-2">
                <div class="w-16 h-16 rounded-2xl bg-gradient-to-tr from-[#F2569A] to-[#B83A72] mx-auto flex items-center justify-center text-3xl shadow-lg mb-6 group-hover:scale-110 transition-transform">
                    🔄
                </div>
                <h3 class="text-xl font-black text-white mb-3">محتوى بيتجدد دايماً</h3>
                <p class="text-sm text-purple-200/80 leading-relaxed">
                    حزم أسئلة وإفيهات وأمثال جديدة بتنزل كل أسبوع بدون الحاجة لتحديث التطبيق من المتجر، يعني القعدة عمرها ما هتبقى مكررة.
                </p>
            </div>

        </div>

    </div>
</section>

{{-- 3. شبكة ألعاب الإطلاق الستة (Featured Games) --}}
<section class="py-16 relative">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-12">
            <div>
                <span class="text-xs md:text-sm font-black text-[#F2569A] tracking-wider uppercase">
                    ألعاب الإطلاق الرسمية
                </span>
                <h2 class="text-3xl md:text-4xl font-black text-white mt-1">
                    ألعاب الإطلاق الستة.. ولّع التحدي!
                </h2>
                <p class="text-sm md:text-base text-purple-200/80 mt-2">
                    كل لعبة بنكهة مختلفة تناسب مود قعدتكم، من سرعة البديهة للضحك والذكاء.
                </p>
            </div>

            <a href="{{ url('/games') }}" class="inline-flex items-center gap-2 text-sm font-bold text-[#FFD27A] hover:text-white transition-colors bg-white/5 hover:bg-white/10 px-5 py-2.5 rounded-xl border border-white/10 self-start md:self-auto">
                <span>تصفح كل الألعاب والفلاتر</span>
                <span class="rtl:rotate-180">➔</span>
            </a>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            @foreach($games as $game)
                <x-game-card :game="$game" />
            @endforeach
        </div>

    </div>
</section>

{{-- 4. كيف تبدأ اللعب؟ في 3 خطوات (How It Works) --}}
<section class="py-16 relative">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="glass-card p-8 md:p-14 border-[#A35BFF]/30 relative overflow-hidden">
            <div class="text-center max-w-2xl mx-auto mb-12 space-y-2">
                <span class="text-xs font-black text-[#FFC24B] uppercase tracking-wider">سهلة وبسيطة</span>
                <h2 class="text-3xl font-black text-white">كيف تبدأ اللعب في 3 خطوات؟</h2>
                <p class="text-sm text-purple-200/80">بدون تسجيل حساب وبدون أي خطوات معقدة، اللعبة تبدأ في دقيقة واحدة!</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
                
                {{-- خطوة 1 --}}
                <div class="flex flex-col items-center text-center space-y-3 relative z-10">
                    <div class="w-14 h-14 rounded-full bg-gradient-to-tr from-[#FFB25E] to-[#FF8A4C] text-[#2A0E35] font-black text-2xl flex items-center justify-center shadow-lg border-2 border-white/40">
                        1
                    </div>
                    <h3 class="text-lg font-black text-white">حمّل التطبيق وافتحه</h3>
                    <p class="text-xs md:text-sm text-purple-200/80 leading-relaxed">
                        اختر «العب كضيف» للدخول فوراً بدون أي شاشات تسجيل دخول أو كلمات مرور.
                    </p>
                </div>

                {{-- خطوة 2 --}}
                <div class="flex flex-col items-center text-center space-y-3 relative z-10">
                    <div class="w-14 h-14 rounded-full bg-gradient-to-tr from-[#A35BFF] to-[#7A2FE0] text-white font-black text-2xl flex items-center justify-center shadow-lg border-2 border-white/40">
                        2
                    </div>
                    <h3 class="text-lg font-black text-white">اختر اللعبة وقسّم الفرق</h3>
                    <p class="text-xs md:text-sm text-purple-200/80 leading-relaxed">
                        اختاروا اللعبة واقسموا أنفسكم فريقين (فريق البنفسج وفريق البرتقال) وحددوا الوقت.
                    </p>
                </div>

                {{-- خطوة 3 --}}
                <div class="flex flex-col items-center text-center space-y-3 relative z-10">
                    <div class="w-14 h-14 rounded-full bg-gradient-to-tr from-[#F2569A] to-[#B83A72] text-white font-black text-2xl flex items-center justify-center shadow-lg border-2 border-white/40">
                        3
                    </div>
                    <h3 class="text-lg font-black text-white">احسب النقاط واحتفل!</h3>
                    <p class="text-xs md:text-sm text-purple-200/80 leading-relaxed">
                        فرفوش بيحسب النقاط تلقائياً ويعلن الفريق الفائز مع كؤوس واحتفالات صاخبة!
                    </p>
                </div>

            </div>

            <div class="mt-12 text-center">
                <x-game-button href="{{ url('/download') }}" variant="primary" class="!text-sm !py-3 !px-8">
                    <span>حمّل التطبيق وابدأ جولتك الأولى</span>
                </x-game-button>
            </div>
        </div>

    </div>
</section>

{{-- 5. تجربة تفاعلية مصغرة من مثل شعبي (Interactive Mini Demo) --}}
<section class="py-16 relative">
    <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="parchment-card p-6 md:p-10 relative overflow-hidden shadow-2xl text-center">
            
            <div class="flex items-center justify-between mb-6">
                <span class="px-3 py-1 rounded-full text-xs font-black bg-[#3E2410] text-[#F6E3B8]">
                    ⚡ تجربة حية أونلاين
                </span>
                <span class="text-xs font-bold text-[#3E2410]">
                    لعبة أمثال شعبية
                </span>
            </div>

            <div class="max-w-xl mx-auto space-y-4">
                <span class="text-xs font-bold uppercase tracking-wider text-[#7A4B1A]">
                    كمّل المثل الشعبي الآتي:
                </span>

                <h3 class="text-2xl md:text-4xl font-kufi font-black text-[#3E2410] leading-snug">
                    «اللي اختشوا...»
                </h3>

                <p class="text-xs md:text-sm text-[#5C3916] font-medium">
                    جرّب معلوماتك الشعبية الآن! اختر التكملة الصحيحة:
                </p>

                <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-3">
                    <a href="{{ url('/games/amthal') }}" class="py-3 px-4 rounded-xl bg-white/80 hover:bg-white text-[#3E2410] font-bold text-sm border-2 border-[#B88746] shadow-sm transition-transform hover:-translate-y-1">
                        ماتوا
                    </a>
                    <a href="{{ url('/games/amthal') }}" class="py-3 px-4 rounded-xl bg-white/80 hover:bg-white text-[#3E2410] font-bold text-sm border-2 border-[#B88746] shadow-sm transition-transform hover:-translate-y-1">
                        عاشوا
                    </a>
                    <a href="{{ url('/games/amthal') }}" class="py-3 px-4 rounded-xl bg-white/80 hover:bg-white text-[#3E2410] font-bold text-sm border-2 border-[#B88746] shadow-sm transition-transform hover:-translate-y-1">
                        ناموا بدري
                    </a>
                </div>

                <div class="pt-6">
                    <a href="{{ url('/games/amthal') }}" class="inline-flex items-center gap-2 text-sm font-black text-[#8E2A4E] hover:underline">
                        <span>انتقل لصفحة تحدي الأمثال الكاملة مع المؤقت والعداد والنقاط ➔</span>
                    </a>
                </div>
            </div>

        </div>

    </div>
</section>

{{-- 6. مميزات حصرية تفرفشك (Platform Highlights) --}}
<section class="py-16 relative">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="text-center max-w-2xl mx-auto mb-14 space-y-2">
            <span class="text-xs font-black text-[#FFC24B] uppercase tracking-wider">مميزات خاصة</span>
            <h2 class="text-3xl md:text-4xl font-black text-white">مصممة خصيصاً للماتنا العربية</h2>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            
            <div class="glass-card p-6 border-white/10 hover:border-emerald-500/50">
                <div class="text-3xl mb-4">✈️</div>
                <h4 class="text-lg font-black text-white mb-2">أوفلاين 100% بدون إنترنت</h4>
                <p class="text-xs md:text-sm text-purple-200/80 leading-relaxed">
                    في السفر، الشاليه، أو في الصحراء، التطبيق يشتغل بكفاءة تامة بدون باقة ولا واي فاي.
                </p>
            </div>

            <div class="glass-card p-6 border-white/10 hover:border-[#FFC24B]/50">
                <div class="text-3xl mb-4">🛡️</div>
                <h4 class="text-lg font-black text-white mb-2">وضع عائلي منقح 100%</h4>
                <p class="text-xs md:text-sm text-purple-200/80 leading-relaxed">
                    كل سؤال ومثل خاضع لفلترة دقيقة تناسب جمعة العائلات مع الأطفال والأجداد بكل راحة واحترام.
                </p>
            </div>

            <div class="glass-card p-6 border-white/10 hover:border-[#A35BFF]/50">
                <div class="text-3xl mb-4">🗣️</div>
                <h4 class="text-lg font-black text-white mb-2">لهجات عربية متعددة</h4>
                <p class="text-xs md:text-sm text-purple-200/80 leading-relaxed">
                    محتوى مخصص باللهجة المصرية، والخليجية، والشامية، والعربية العامة؛ اختار لهجتك واستمتع!
                </p>
            </div>

        </div>

    </div>
</section>

{{-- 7. آراء المستخدمين الحقيقية (Testimonials - تظهر فقط إن وُجدت) --}}
@if($testimonials->isNotEmpty())
<section class="py-16 relative">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="text-center max-w-2xl mx-auto mb-12 space-y-2">
            <span class="text-xs font-black text-[#F2569A] uppercase tracking-wider">تجارب حقيقية</span>
            <h2 class="text-3xl font-black text-white">قالوا إيه عن فرفشة؟</h2>
            <p class="text-sm text-purple-200/80">مراجعات حقيقية موثقة من متاجر التطبيقات</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            @foreach($testimonials as $t)
                <div class="glass-card p-6 relative flex flex-col justify-between">
                    <div>
                        <div class="flex items-center justify-between mb-4">
                            <div class="text-[#FFC24B] text-sm tracking-widest">
                                {{ str_repeat('⭐', $t->rating) }}
                            </div>
                            <span class="text-[11px] px-2 py-0.5 rounded-full bg-white/5 text-purple-300 font-bold border border-white/10">
                                {{ $t->source }}
                            </span>
                        </div>
                        <p class="text-sm text-purple-100 leading-relaxed mb-6 font-medium">
                            «{{ $t->getTranslation('content', $currentLocale ?? 'ar') }}»
                        </p>
                    </div>

                    <div class="flex items-center gap-3 pt-3 border-t border-white/10">
                        <div class="w-9 h-9 rounded-full bg-gradient-to-tr from-[#A35BFF] to-[#F2569A] flex items-center justify-center text-xs font-black text-white">
                            {{ mb_substr($t->author_name, 0, 1) }}
                        </div>
                        <div>
                            <div class="text-xs font-bold text-white">{{ $t->author_name }}</div>
                            <div class="text-[10px] text-purple-300">{{ $t->country_code }}</div>
                        </div>
                    </div>
                </div>
            @endforeach
        </div>

    </div>
</section>
@endif

{{-- 8. الأسئلة الشائعة الأكثر تكراراً (FAQ Accordion) --}}
<section class="py-16 relative">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="text-center mb-12 space-y-2">
            <span class="text-xs font-black text-[#FFC24B] uppercase tracking-wider">عندك استفسار؟</span>
            <h2 class="text-3xl font-black text-white">الأسئلة الشائعة</h2>
        </div>

        <div class="space-y-4" x-data="{ activeAccordion: null }">
            
            <div class="glass-card overflow-hidden">
                <button type="button" 
                        @click="activeAccordion = activeAccordion === 1 ? null : 1" 
                        class="w-full p-5 text-start font-black text-base text-white flex items-center justify-between gap-4 cursor-pointer">
                    <span>هل تطبيق فرفشة مجاني بالكامل؟</span>
                    <span :class="activeAccordion === 1 ? 'rotate-180' : ''" class="transition-transform text-[#A35BFF]">▼</span>
                </button>
                <div x-show="activeAccordion === 1" x-collapse class="px-5 pb-5 text-sm text-purple-200/90 leading-relaxed border-t border-white/5 pt-3">
                    نعم! التطبيق مجاني بالكامل ويمنحك الوصول لجميع الألعاب الأساسية الستة مع مئات الأسئلة والأمثال، بدون أي رسوم اشتراك إجبارية.
                </div>
            </div>

            <div class="glass-card overflow-hidden">
                <button type="button" 
                        @click="activeAccordion = activeAccordion === 2 ? null : 2" 
                        class="w-full p-5 text-start font-black text-base text-white flex items-center justify-between gap-4 cursor-pointer">
                    <span>هل نحتاج اتصالاً بالإنترنت للعب في القعدة؟</span>
                    <span :class="activeAccordion === 2 ? 'rotate-180' : ''" class="transition-transform text-[#A35BFF]">▼</span>
                </button>
                <div x-show="activeAccordion === 2" x-collapse class="px-5 pb-5 text-sm text-purple-200/90 leading-relaxed border-t border-white/5 pt-3">
                    لا إطلاقاً! بمجرد تحميل التطبيق يمكنك اللعب في أي مكان بدون اتصال بالإنترنت (وضع Pass & Play). الاتصال مطلوب فقط إذا رغبتم في اللعب أونلاين عبر الغرف الافتراضية.
                </div>
            </div>

            <div class="glass-card overflow-hidden">
                <button type="button" 
                        @click="activeAccordion = activeAccordion === 3 ? null : 3" 
                        class="w-full p-5 text-start font-black text-base text-white flex items-center justify-between gap-4 cursor-pointer">
                    <span>هل يمكن اللعب كضيوف بدون تسجيل حساب؟</span>
                    <span :class="activeAccordion === 3 ? 'rotate-180' : ''" class="transition-transform text-[#A35BFF]">▼</span>
                </button>
                <div x-show="activeAccordion === 3" x-collapse class="px-5 pb-5 text-sm text-purple-200/90 leading-relaxed border-t border-white/5 pt-3">
                    بالتأكيد! نحترم خصوصيتكم وسرعة وقتكم؛ التطبيق يوفر زر «العب كضيف» بضغطة واحدة، ولا نشترط تسجيل بريد أو رقم هاتف لبدء اللعب المحلي.
                </div>
            </div>

            <div class="glass-card overflow-hidden">
                <button type="button" 
                        @click="activeAccordion = activeAccordion === 4 ? null : 4" 
                        class="w-full p-5 text-start font-black text-base text-white flex items-center justify-between gap-4 cursor-pointer">
                    <span>كيف تعمل الغرف الأونلاين؟</span>
                    <span :class="activeAccordion === 4 ? 'rotate-180' : ''" class="transition-transform text-[#A35BFF]">▼</span>
                </button>
                <div x-show="activeAccordion === 4" x-collapse class="px-5 pb-5 text-sm text-purple-200/90 leading-relaxed border-t border-white/5 pt-3">
                    يقوم أحد اللاعبين باختيار نمط أونلاين وإنشاء غرفة ليحصل على رمز مكون من 6 أرقام ورابط مباشر؛ يشاركه مع أصدقائه فيدخلون الغرفة فوراً وتبدأ الجولة بينهم بمزامنة حية ومثيرة.
                </div>
            </div>

        </div>

    </div>
</section>

{{-- 9. دعوة التحميل الكبرى (Final Download Banner) --}}
<section class="py-20 relative overflow-hidden">
    <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        
        <div class="rounded-[32px] bg-gradient-to-br from-[#2A1458] via-[#1F0E3D] to-[#150A2E] border-2 border-[#A35BFF]/50 p-8 md:p-16 relative overflow-hidden shadow-[0_20px_50px_rgba(0,0,0,0.6)]">
            
            <div class="absolute -top-24 -right-24 w-72 h-72 bg-[#F2569A]/30 rounded-full blur-3xl pointer-events-none"></div>
            <div class="absolute -bottom-24 -left-24 w-72 h-72 bg-[#A35BFF]/30 rounded-full blur-3xl pointer-events-none"></div>

            <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center relative z-10">
                
                <div class="lg:col-span-8 text-center lg:text-start space-y-5">
                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-black bg-[#FF8A4C]/20 text-[#FFD27A] border border-[#FF8A4C]/30">
                        🎉 جاهز تفرفش؟
                    </span>
                    <h2 class="text-3xl sm:text-4xl md:text-5xl font-black text-white leading-tight">
                        حمّل فرفشة الآن مجاناً وخلّي القعدة ماتتنسيش!
                    </h2>
                    <p class="text-base text-purple-200/90 leading-relaxed max-w-xl mx-auto lg:mx-0">
                        متوفر على أنظمة iOS وأندرويد. شارك الرابط مع شلتك وعيلتك وابدأوا التحدي والضحك اليوم!
                    </p>

                    <div class="pt-3 flex flex-wrap items-center justify-center lg:justify-start gap-4">
                        <x-game-button href="{{ url('/go/ios') }}" variant="primary" class="!text-base !py-3 !px-6">
                            <span>🍏</span>
                            <span>App Store (آيفون)</span>
                        </x-game-button>

                        <x-game-button href="{{ url('/go/android') }}" variant="secondary" class="!text-base !py-3 !px-6">
                            <span>🤖</span>
                            <span>Google Play (أندرويد)</span>
                        </x-game-button>
                    </div>
                </div>

                {{-- تميمة فرفوش وكود QR لسطح المكتب --}}
                <div class="lg:col-span-4 flex flex-col items-center justify-center">
                    <div class="glass-card p-6 text-center border-white/20 max-w-xs">
                        <x-farfoush expression="celebrating" size="md" />
                        <div class="mt-4 text-xs font-bold text-white">امسح الكود بالموبايل للتحميل المباشر</div>
                        
                        {{-- كود QR ذكي مبسط SVG --}}
                        <div class="mt-3 p-3 bg-white rounded-2xl inline-block shadow-md">
                            <svg class="w-24 h-24 text-black" viewBox="0 0 100 100" fill="currentColor">
                                <path d="M10 10h30v30h-30zM15 15h20v20h-20zM22 22h6v6h-6zM60 10h30v30h-30zM65 15h20v20h-20zM72 22h6v6h-6zM10 60h30v30h-30zM15 65h20v20h-20zM22 72h6v6h-6zM50 20h6v6h-6zM50 35h6v6h-6zM60 60h6v6h-6zM70 60h10v6h-10zM60 70h6v10h-6zM75 75h15v15h-15z"/>
                            </svg>
                        </div>
                        <div class="mt-2 text-[10px] text-purple-300">يفتح المتجر المخصص لجهازك مباشرة</div>
                    </div>
                </div>

            </div>

        </div>

    </div>
</section>

@endsection
