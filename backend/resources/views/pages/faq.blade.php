@extends('layouts.app')

@section('title', 'الأسئلة الشائعة | فرفشة للألعاب الجماعية')
@section('meta_description', 'إجابات شاملة عن كافة الأسئلة المتكررة حول تحميل وتشغيل وتكوين غرف فرفشة ونظام اللعب بدون إنترنت.')

@section('structured_data')
<script type="application/ld+json">
{!! json_encode([
  '@context' => 'https://schema.org',
  '@type' => 'FAQPage',
  'mainEntity' => [
    [
      '@type' => 'Question',
      'name' => 'هل تطبيق فرفشة مجاني بالكامل؟',
      'acceptedAnswer' => [
        '@type' => 'Answer',
        'text' => 'نعم! التطبيق مجاني بالكامل مع إمكانية الوصول إلى جميع الألعاب الستة الأساسية ومئات الأمثال والتحديات.',
      ],
    ],
    [
      '@type' => 'Question',
      'name' => 'هل نحتاج اتصالاً بالإنترنت للعب؟',
      'acceptedAnswer' => [
        '@type' => 'Answer',
        'text' => 'لا، اللعب المحلي بنظام Pass & Play يعمل 100% بدون إنترنت. الإنترنت مطلوب فقط لغرف اللعب أونلاين.',
      ],
    ],
    [
      '@type' => 'Question',
      'name' => 'كيف أنشئ غرفة أونلاين وأشاركها مع أصدقائي؟',
      'acceptedAnswer' => [
        '@type' => 'Answer',
        'text' => 'اختر نمط اللعب أونلاين ثم اضغط إنشاء غرفة، سيظهر لك رمز من 6 أرقام ورابط مباشر يمكنك إرساله لأصدقائك عبر واتساب.',
      ],
    ],
  ],
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) !!}
</script>
@endsection

@section('content')
<div class="py-12 md:py-20" x-data="{ activeFaq: 1, activeCategory: 'all' }">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        
        <div class="text-center space-y-3">
            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#A35BFF]/20 text-[#FFD27A] border border-[#A35BFF]/30">
                ❓ مركز المساعدة والدعم
            </span>
            <h1 class="text-3xl md:text-5xl font-black text-white">الأسئلة الشائعة</h1>
            <p class="text-sm md:text-base text-purple-200/80">كل ما تحتاج معرفته عن فرفشة وطريقة اللعب والغرف والتحميل.</p>
        </div>

        {{-- قائمة الأسئلة والأجوبة مع الأكورديون --}}
        <div class="space-y-4">
            
            <div class="glass-card overflow-hidden">
                <button type="button" @click="activeFaq = activeFaq === 1 ? null : 1" class="w-full p-5 text-start font-black text-base md:text-lg text-white flex items-center justify-between gap-4 cursor-pointer">
                    <span>هل تطبيق فرفشة مجاني بالكامل؟</span>
                    <span :class="activeFaq === 1 ? 'rotate-180 text-[#FFD27A]' : 'text-[#A35BFF]'" class="transition-transform">▼</span>
                </button>
                <div x-show="activeFaq === 1" x-collapse class="px-5 pb-5 text-sm text-purple-200/90 leading-relaxed border-t border-white/5 pt-3">
                    نعم! التطبيق مجاني بالكامل ويمنحك الوصول لجميع ألعاب الإطلاق الستة مع مئات الأسئلة والأمثال الشعبية بدون أي اشتراكات إجبارية.
                </div>
            </div>

            <div class="glass-card overflow-hidden">
                <button type="button" @click="activeFaq = activeFaq === 2 ? null : 2" class="w-full p-5 text-start font-black text-base md:text-lg text-white flex items-center justify-between gap-4 cursor-pointer">
                    <span>هل نحتاج اتصالاً بالإنترنت للعب في التجمعات؟</span>
                    <span :class="activeFaq === 2 ? 'rotate-180 text-[#FFD27A]' : 'text-[#A35BFF]'" class="transition-transform">▼</span>
                </button>
                <div x-show="activeFaq === 2" x-collapse class="px-5 pb-5 text-sm text-purple-200/90 leading-relaxed border-t border-white/5 pt-3">
                    لا! وضع اللعب المحلي على جهاز واحد (Pass & Play) يعمل بالكامل أوفلاين دون الحاجة لأي اتصال بالشبكة أو باقة الإنترنت.
                </div>
            </div>

            <div class="glass-card overflow-hidden">
                <button type="button" @click="activeFaq = activeFaq === 3 ? null : 3" class="w-full p-5 text-start font-black text-base md:text-lg text-white flex items-center justify-between gap-4 cursor-pointer">
                    <span>كيف أنشئ غرفة أونلاين مع أصدقائي؟</span>
                    <span :class="activeFaq === 3 ? 'rotate-180 text-[#FFD27A]' : 'text-[#A35BFF]'" class="transition-transform">▼</span>
                </button>
                <div x-show="activeFaq === 3" x-collapse class="px-5 pb-5 text-sm text-purple-200/90 leading-relaxed border-t border-white/5 pt-3">
                    من الشاشة الرئيسية اختر "أونلاين"، ثم أنشئ غرفة جديدة؛ سيظهر لك رمز غرفة مكون من 6 خانات ورابط مباشر يمكنك إرساله لأصدقائك لينضموا فوراً.
                </div>
            </div>

            <div class="glass-card overflow-hidden">
                <button type="button" @click="activeFaq = activeFaq === 4 ? null : 4" class="w-full p-5 text-start font-black text-base md:text-lg text-white flex items-center justify-between gap-4 cursor-pointer">
                    <span>ما هي الأجهزة المدعومة؟</span>
                    <span :class="activeFaq === 4 ? 'rotate-180 text-[#FFD27A]' : 'text-[#A35BFF]'" class="transition-transform">▼</span>
                </button>
                <div x-show="activeFaq === 4" x-collapse class="px-5 pb-5 text-sm text-purple-200/90 leading-relaxed border-t border-white/5 pt-3">
                    يدعم فرفشة كافة أجهزة iPhone و iPad بنظام iOS 14 فما فوق، وكافة هواتف وأجهزة أندرويد بنظام Android 8 فما فوق، بالإضافة لتجربة المتصفح التفاعلية.
                </div>
            </div>

            <div class="glass-card overflow-hidden">
                <button type="button" @click="activeFaq = activeFaq === 5 ? null : 5" class="w-full p-5 text-start font-black text-base md:text-lg text-white flex items-center justify-between gap-4 cursor-pointer">
                    <span>هل المحتوى مناسب للعائلات والأطفال؟</span>
                    <span :class="activeFaq === 5 ? 'rotate-180 text-[#FFD27A]' : 'text-[#A35BFF]'" class="transition-transform">▼</span>
                </button>
                <div x-show="activeFaq === 5" x-collapse class="px-5 pb-5 text-sm text-purple-200/90 leading-relaxed border-t border-white/5 pt-3">
                    نعم 100%! كل الأسئلة والمحتوى منقى بعناية فائقة ليلائم جلسات العائلات والأصدقاء من مختلف الأعمار دون أي محتوى محرج.
                </div>
            </div>

        </div>

        <div class="text-center pt-6">
            <x-farfoush expression="explaining" speech="لسه عندك سؤال محيرك؟ تواصل معنا مباشرة وفريق فرفشة هيرد عليك!" size="md" />
            <div class="mt-4">
                <a href="{{ url('/contact') }}" class="btn-game-secondary !py-2.5 !px-6 !text-sm inline-flex">
                    <span>راسلنا عبر صفحة تواصل معنا</span>
                </a>
            </div>
        </div>

    </div>
</div>
@endsection
