@extends('layouts.app')

@section('title', $game->seo_title ?? ($game->name . ' | فرفشة للألعاب الجماعية'))
@section('meta_description', $game->seo_description ?? ($game->subtitle ?? $game->description))
@section('og_image', $game->og_image ? asset('storage/' . $game->og_image) : ($game->cover_image ? $game->cover_image_url : asset('assets/proverb.png')))

@section('structured_data')
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [{
    "@type": "ListItem",
    "position": 1,
    "name": "الرئيسية",
    "item": "{{ url('/') }}"
  },{
    "@type": "ListItem",
    "position": 2,
    "name": "الألعاب",
    "item": "{{ url('/games') }}"
  },{
    "@type": "ListItem",
    "position": 3,
    "name": "{{ $game->name }}",
    "item": "{{ url('/games/' . $game->slug) }}"
  }]
}
</script>
@if($game->faqs && count($game->faqs) > 0)
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    @foreach($game->faqs as $index => $faq)
    {
      "@type": "Question",
      "name": "{{ $faq['question'] }}",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "{{ $faq['answer'] }}"
      }
    }{{ $loop->last ? '' : ',' }}
    @endforeach
  ]
}
</script>
@endif
@endsection

@section('content')
<div class="py-10 md:py-16">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        
        {{-- شريط مسار التنقل (Breadcrumb) --}}
        <nav class="flex items-center gap-2 text-xs text-purple-300 font-medium">
            <a href="{{ url('/') }}" class="hover:text-white transition-colors">الرئيسية</a>
            <span class="rtl:rotate-180">➔</span>
            <a href="{{ url('/games') }}" class="hover:text-white transition-colors">دليل الألعاب</a>
            <span class="rtl:rotate-180">➔</span>
            <span class="text-[#FFD27A] font-bold">{{ $game->name }}</span>
        </nav>

        {{-- قسم البطل التعريفي للعبة --}}
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center">
            
            <div class="lg:col-span-7 space-y-6">
                <div class="flex flex-wrap items-center gap-2">
                    <span class="px-3 py-1 rounded-full text-xs font-bold bg-[#A35BFF]/30 text-purple-200 border border-[#A35BFF]/40">
                        {{ $game->category }}
                    </span>

                    @if($game->is_offline_capable)
                        <span class="px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 flex items-center gap-1">
                            <span>✈️ تعمل بدون إنترنت أوفلاين</span>
                        </span>
                    @endif

                    @if($game->age_group)
                        <span class="px-3 py-1 rounded-full text-xs font-bold bg-white/10 text-purple-200 border border-white/10">
                            {{ $game->age_group }}
                        </span>
                    @endif
                </div>

                <h1 class="text-3xl sm:text-4xl md:text-5xl font-black text-white leading-tight">
                    {{ $game->name }}
                </h1>

                @if($game->subtitle)
                    <div class="text-lg md:text-xl font-bold text-[#FFD27A]">
                        {{ $game->subtitle }}
                    </div>
                @endif

                <p class="text-base text-purple-200/90 leading-relaxed max-w-2xl">
                    {{ $game->description }}
                </p>

                {{-- إحصائيات اللعبة السريعة --}}
                <div class="grid grid-cols-3 gap-3 pt-2 text-center max-w-lg">
                    <div class="glass-card p-3 rounded-2xl border-white/10">
                        <div class="text-xs text-purple-300 mb-1">اللاعبين</div>
                        <div class="text-sm md:text-base font-black text-white">{{ $game->min_players }} - {{ $game->max_players }}</div>
                    </div>
                    <div class="glass-card p-3 rounded-2xl border-white/10">
                        <div class="text-xs text-purple-300 mb-1">وقت الدور</div>
                        <div class="text-sm md:text-base font-black text-white">{{ $game->default_duration_seconds }} ثانية</div>
                    </div>
                    <div class="glass-card p-3 rounded-2xl border-white/10">
                        <div class="text-xs text-purple-300 mb-1">الجولات</div>
                        <div class="text-sm md:text-base font-black text-white">{{ $game->default_rounds }} جولات</div>
                    </div>
                </div>

                {{-- أزرار الإجراء --}}
                <div class="pt-4 flex flex-wrap items-center gap-4">
                    <x-game-button href="{{ url('/download') }}" variant="primary" class="!py-3 !px-7">
                        <span>📱 افتح في التطبيق / حمّل</span>
                    </x-game-button>

                    @if($game->slug === 'amthal-shaabiya')
                        <x-game-button href="{{ url('/games/amthal') }}" variant="secondary" class="!py-3 !px-6">
                            <span>⚡ جرّب اللعبة تفاعلياً أونلاين</span>
                        </x-game-button>
                    @endif
                </div>
            </div>

            {{-- جانب صورة اللعبة وفرفوش يشرح --}}
            <div class="lg:col-span-5 flex flex-col items-center">
                <div class="relative w-full max-w-md rounded-3xl overflow-hidden glass-card p-4 border-[#A35BFF]/40 text-center">
                    
                    @if($game->cover_image)
                        <img src="{{ $game->cover_image_url }}" 
                             alt="{{ $game->name }}" 
                             class="w-full h-64 object-cover rounded-2xl mb-4 shadow-lg"
                             loading="lazy">
                    @else
                        <div class="w-full h-64 bg-gradient-to-tr from-[#1F0E3D] via-[#2A1850] to-[#150A2E] rounded-2xl flex flex-col items-center justify-center p-6 mb-4 border border-white/5">
                            <span class="text-6xl mb-3">🎮</span>
                            <span class="text-lg font-black text-[#FFD27A]">{{ $game->name }}</span>
                        </div>
                    @endif

                    <x-farfoush expression="explaining" speech="لعبة حماسية جداً! اقرأ القواعد تحت وشوف المثال قبل ما تبدأوا!" size="md" />
                </div>
            </div>

        </div>

        {{-- خطوات اللعب خطوة بخطوة --}}
        @if($game->how_to_play_steps && count($game->how_to_play_steps) > 0)
        <div class="glass-card p-8 md:p-12 border-[#A35BFF]/30 space-y-8">
            <div class="text-center max-w-2xl mx-auto space-y-2">
                <span class="text-xs font-black text-[#FFC24B] uppercase tracking-wider">القواعد والخطوات</span>
                <h2 class="text-2xl md:text-3xl font-black text-white">طريقة اللعب خطوة بخطوة</h2>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                @foreach($game->how_to_play_steps as $step)
                    <div class="p-6 rounded-2xl bg-white/5 border border-white/10 relative hover:border-[#A35BFF]/50 transition-colors">
                        <div class="w-10 h-10 rounded-full bg-gradient-to-tr from-[#FF8A4C] to-[#F2569A] text-[#2A0E35] font-black text-lg flex items-center justify-center mb-4 shadow">
                            {{ $step['step_number'] ?? $loop->iteration }}
                        </div>
                        <h3 class="text-lg font-bold text-white mb-2">{{ $step['title'] ?? '' }}</h3>
                        <p class="text-sm text-purple-200/80 leading-relaxed">{{ $step['description'] ?? '' }}</p>
                    </div>
                @endforeach
            </div>
        </div>
        @endif

        {{-- نظام احتساب النقاط ومثال الجولة الحية --}}
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            
            {{-- نظام احتساب النقاط --}}
            @if($game->scoring_guide && count($game->scoring_guide) > 0)
            <div class="glass-card p-6 md:p-8 space-y-6 border-white/15">
                <div class="flex items-center gap-3">
                    <span class="text-2xl">🏆</span>
                    <div>
                        <h3 class="text-xl font-black text-white">نظام احتساب النقاط</h3>
                        <p class="text-xs text-purple-300">كيف تجمع النقاط وتكسب الجولة؟</p>
                    </div>
                </div>

                <div class="space-y-3">
                    @foreach($game->scoring_guide as $rule)
                        <div class="p-4 rounded-xl bg-white/5 border border-white/5 flex items-center justify-between gap-4">
                            <div>
                                <div class="text-sm font-bold text-white">{{ $rule['condition'] ?? '' }}</div>
                                @if(!empty($rule['note']))
                                    <div class="text-xs text-purple-300/80 mt-0.5">{{ $rule['note'] }}</div>
                                @endif
                            </div>
                            <span class="px-3 py-1.5 rounded-full font-black text-sm bg-gradient-to-r from-[#FFB25E] to-[#FF8A4C] text-[#2A0E35] whitespace-nowrap shadow-sm">
                                {{ $rule['points'] ?? '' }}
                            </span>
                        </div>
                    @endforeach
                </div>
            </div>
            @endif

            {{-- مثال توضيحي لجولة حية --}}
            @if($game->example_round && !empty($game->example_round['prompt']))
            <div class="parchment-card p-6 md:p-8 space-y-5 text-center flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between mb-4">
                        <span class="px-3 py-1 rounded-full text-xs font-black bg-[#3E2410] text-[#F6E3B8]">
                            💡 مثال توضيحي لجولة حية
                        </span>
                        <span class="text-xs font-bold text-[#7A4B1A]">جولة سريعة</span>
                    </div>

                    <h4 class="text-lg md:text-2xl font-kufi font-black text-[#3E2410] my-4 leading-relaxed">
                        «{{ $game->example_round['prompt'] }}»
                    </h4>

                    @if(!empty($game->example_round['options']))
                        <div class="grid grid-cols-1 sm:grid-cols-3 gap-2 my-4">
                            @foreach($game->example_round['options'] as $opt)
                                <div class="py-2.5 px-3 rounded-xl bg-white/80 text-[#3E2410] font-bold text-xs border border-[#B88746]">
                                    {{ $opt }}
                                </div>
                            @endforeach
                        </div>
                    @endif

                    <div class="p-3 rounded-xl bg-[#3E2410]/10 border border-[#B88746]/40 text-xs text-[#3E2410] text-start">
                        <strong>الإجابة الصحيحة:</strong> {{ $game->example_round['correct'] ?? '' }}
                        @if(!empty($game->example_round['hint']))
                            <div class="mt-1 text-[#7A4B1A]"><strong>التلميح:</strong> {{ $game->example_round['hint'] }}</div>
                        @endif
                    </div>
                </div>

                @if($game->slug === 'amthal-shaabiya')
                    <div class="pt-4">
                        <a href="{{ url('/games/amthal') }}" class="btn-game-primary !py-2.5 !px-6 !text-xs inline-flex">
                            <span>جرّب المثل بنفسك في التحدي التفاعلي</span>
                        </a>
                    </div>
                @endif
            </div>
            @endif

        </div>

        {{-- أسئلة شائعة خاصة باللعبة إن وُجدت --}}
        @if($game->faqs && count($game->faqs) > 0)
        <div class="glass-card p-8 border-white/10 space-y-6">
            <h3 class="text-xl font-black text-white flex items-center gap-2">
                <span>❓</span>
                <span>أسئلة شائعة خاصة بـ {{ $game->name }}</span>
            </h3>

            <div class="space-y-4">
                @foreach($game->faqs as $faq)
                    <div class="p-4 rounded-xl bg-white/5 border border-white/5 space-y-1.5">
                        <h4 class="text-base font-bold text-[#FFD27A]">{{ $faq['question'] }}</h4>
                        <p class="text-sm text-purple-200/90 leading-relaxed">{{ $faq['answer'] }}</p>
                    </div>
                @endforeach
            </div>
        </div>
        @endif

        {{-- قسم ألعاب مشابهة --}}
        @if($similarGames->isNotEmpty())
        <div class="pt-8 space-y-6">
            <div class="flex items-center justify-between">
                <h3 class="text-2xl font-black text-white">ألعاب مشابهة قد تعجبك</h3>
                <a href="{{ url('/games') }}" class="text-sm text-[#FFD27A] hover:underline font-bold">
                    عرض كل الألعاب ➔
                </a>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
                @foreach($similarGames as $simGame)
                    <x-game-card :game="$simGame" />
                @endforeach
            </div>
        </div>
        @endif

    </div>
</div>
@endsection
