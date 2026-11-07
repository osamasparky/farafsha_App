@props([
    'game',
    'class' => '',
])

@php
    $gradients = [
        'amthal-shaabiya' => 'from-[#D2566A]/30 to-[#8E2A4E]/30 border-[#D2566A]/40 hover:border-[#D2566A]',
        'famous-quotes' => 'from-[#8F3BD0]/30 to-[#561C94]/30 border-[#8F3BD0]/40 hover:border-[#8F3BD0]',
        'who-am-i' => 'from-[#7A6A3A]/30 to-[#3F3420]/30 border-[#FFC24B]/40 hover:border-[#FFC24B]',
        'forbidden-words' => 'from-[#4846BE]/30 to-[#2B2580]/30 border-[#6B68FF]/40 hover:border-[#6B68FF]',
        'two-truths-and-lie' => 'from-[#8C3468]/30 to-[#531B44]/30 border-[#F2569A]/40 hover:border-[#F2569A]',
        'speed-trivia' => 'from-[#2F6E7A]/30 to-[#1B3F52]/30 border-[#35B88E]/40 hover:border-[#35B88E]',
    ];

    $gradientClass = $gradients[$game->slug] ?? 'from-[#2A1850] to-[#1F0E3D] border-[#A35BFF]/30 hover:border-[#A35BFF]';
@endphp

<div class="group relative rounded-[24px] bg-gradient-to-b {{ $gradientClass }} border backdrop-blur-xl p-5 transition-all duration-300 hover:-translate-y-1.5 hover:shadow-[0_15px_35px_rgba(0,0,0,0.5)] flex flex-col justify-between {{ $class }}">
    <div>
        {{-- شارات أعلى البطاقة --}}
        <div class="flex items-center justify-between gap-2 mb-4">
            <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-[#A35BFF]/25 text-[#EADFFF] border border-[#A35BFF]/40">
                {{ $game->category }}
            </span>

            <div class="flex items-center gap-1.5">
                @if($game->is_offline_capable)
                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/40" title="تعمل بدون إنترنت">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.829m2.829 2.829L21 21M15.536 8.464a5 5 0 010 7.072m0 0l-2.829-2.829m-4.243 4.243a9 9 0 01-12.728 0m0 0l2.829-2.829m-2.829 2.829L3 21m2.829-15.536a9 9 0 0112.728 0M3 3l18 18"/></svg>
                        <span>بدون نت</span>
                    </span>
                @endif

                @if($game->badge_text)
                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-black bg-gradient-to-r from-[#FFB25E] to-[#FF8A4C] text-[#2A0E35] shadow-sm">
                        {{ $game->badge_text }}
                    </span>
                @endif
            </div>
        </div>

        {{-- صورة أو أيقونة اللعبة --}}
        <div class="relative h-40 rounded-2xl overflow-hidden mb-4 bg-[#150A2E]/60 flex items-center justify-center border border-white/5">
            @if($game->cover_image)
                <img src="{{ $game->cover_image_url }}" 
                     alt="{{ $game->name }}" 
                     class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                     loading="lazy">
            @else
                <div class="flex flex-col items-center justify-center text-center p-4">
                    <div class="w-16 h-16 rounded-2xl bg-gradient-to-tr from-[#A35BFF] to-[#F2569A] flex items-center justify-center shadow-lg mb-2 group-hover:scale-110 transition-transform">
                        <span class="text-3xl">🎮</span>
                    </div>
                    <span class="text-xs text-purple-200/80 font-semibold">{{ $game->name }}</span>
                </div>
            @endif
        </div>

        {{-- تفاصيل الاسم والوصف --}}
        <h3 class="text-xl font-black text-white group-hover:text-[#FFD27A] transition-colors mb-1">
            <a href="{{ url('/games/' . $game->slug) }}" class="focus:outline-none">
                {{ $game->name }}
            </a>
        </h3>
        
        <p class="text-sm text-purple-200/90 line-clamp-2 mb-4 leading-relaxed">
            {{ $game->subtitle ?? $game->description }}
        </p>
    </div>

    {{-- معلومات عدد اللاعبين والوقت وزر الاستكشاف --}}
    <div>
        <div class="grid grid-cols-2 gap-2 py-3 border-t border-white/10 text-xs text-purple-200/80 mb-4 font-medium">
            <div class="flex items-center gap-1.5">
                <span class="text-[#FFC24B]">👥</span>
                <span>{{ $game->min_players }} - {{ $game->max_players }} لاعبين</span>
            </div>
            <div class="flex items-center gap-1.5 justify-end">
                <span class="text-[#F2569A]">⏱️</span>
                <span>{{ $game->default_duration_seconds }} ثانية/دور</span>
            </div>
        </div>

        <div class="flex items-center gap-2">
            <a href="{{ url('/games/' . $game->slug) }}" 
               class="w-full py-2.5 px-4 rounded-xl bg-white/10 hover:bg-[#A35BFF]/30 border border-white/15 hover:border-[#A35BFF] text-center text-sm font-bold text-white transition-all flex items-center justify-center gap-2">
                <span>اكتشف القواعد</span>
                <span class="rtl:rotate-180">➔</span>
            </a>

            @if($game->slug === 'amthal-shaabiya')
                <a href="{{ url('/games/amthal') }}" 
                   class="py-2.5 px-3.5 rounded-xl bg-gradient-to-r from-[#FF8A4C] to-[#F2569A] text-[#2A0E35] font-black text-xs transition-transform hover:scale-105 shrink-0 shadow-md"
                   title="العب تجربة تفاعلية مباشرة الآن!">
                    ⚡ جرّبها
                </a>
            @endif
        </div>
    </div>
</div>
