@props([
    'expression' => 'welcome',
    'speech' => null,
    'size' => 'md', // sm, md, lg
    'dismissable' => true,
    'class' => '',
])

@php
    $expressionTitles = [
        'welcome' => 'فرفوش يرحب بك!',
        'explaining' => 'فرفوش يشرح اللعبة',
        'thinking' => 'فرفوش يفكّر...',
        'celebrating' => 'فرفوش يحتفل!',
        'confused_sad' => 'فرفوش محتار..',
        'loading' => 'فرفوش يحمّل..',
        'error' => 'أوبس! فرفوش واجه خطأ',
    ];

    $expressionEmojis = [
        'welcome' => '👋✨',
        'explaining' => '💡🎙️',
        'thinking' => '🤔💭',
        'celebrating' => '🎉🥳',
        'confused_sad' => '🧐❓',
        'loading' => '⏳🌀',
        'error' => '⚠️🙈',
    ];

    $settingKey = 'mascot_' . $expression;
    $customImage = \App\Models\SiteSetting::get($settingKey);
    $hasImage = $customImage && !str_contains($customImage, 'مطلوب من العميل') && (str_starts_with($customImage, 'http') || str_starts_with($customImage, '/'));

    $sizeClasses = match($size) {
        'sm' => 'w-16 h-16 text-xs',
        'lg' => 'w-36 h-36 md:w-44 md:h-44 text-base',
        default => 'w-24 h-24 md:w-28 md:h-28 text-sm',
    };
@endphp

<div x-data="{ showSpeech: true }" class="relative inline-flex flex-col items-center select-none {{ $class }}">
    {{-- فقاعة كلام فرفوش إن وجدت --}}
    @if($speech)
        <div x-show="showSpeech" 
             x-transition:enter="transition ease-out duration-200"
             x-transition:enter-start="opacity-0 translate-y-2 scale-95"
             x-transition:enter-end="opacity-100 translate-y-0 scale-100"
             x-transition:leave="transition ease-in duration-150"
             x-transition:leave-start="opacity-100 scale-100"
             x-transition:leave-end="opacity-0 scale-90"
             class="speech-bubble mb-3 max-w-xs md:max-w-sm text-center text-sm md:text-base border-2 border-[#A35BFF]/30 shadow-lg relative z-20">
            <span>{{ $speech }}</span>
            @if($dismissable)
                <button type="button" 
                        @click="showSpeech = false" 
                        class="absolute -top-2 -left-2 rtl:-left-auto rtl:-right-2 bg-purple-900/80 hover:bg-purple-800 text-white w-5 h-5 rounded-full flex items-center justify-center text-xs shadow cursor-pointer"
                        title="إغلاق الفقاعة"
                        aria-label="إغلاق فقاعة المحادثة">
                    ✕
                </button>
            @endif
        </div>
    @endif

    {{-- مجسم فرفوش (صورة أو Placeholder مرح بهوية اللعبة) --}}
    <div class="relative group animate-farfoush">
        @if($hasImage)
            <img src="{{ $customImage }}" 
                 alt="{{ $expressionTitles[$expression] ?? 'فرفوش' }}" 
                 class="{{ $sizeClasses }} object-contain drop-shadow-[0_10px_20px_rgba(242,86,154,0.4)]"
                 loading="lazy">
        @else
            <div class="{{ $sizeClasses }} rounded-3xl bg-gradient-to-br from-[#FFB25E] via-[#F2569A] to-[#A35BFF] p-[2.5px] shadow-[0_10px_30px_rgba(242,86,154,0.4)] transition-transform hover:scale-105">
                <div class="w-full h-full bg-[#1F0E3D] rounded-[22px] flex flex-col items-center justify-center p-2 text-center border border-white/20">
                    <span class="text-2xl md:text-3xl filter drop-shadow">{{ $expressionEmojis[$expression] ?? '🎭' }}</span>
                    <span class="font-black text-[#FFD27A] mt-1 tracking-tight leading-tight">فرفوش</span>
                    <span class="text-[10px] text-purple-200/90 leading-none truncate max-w-full px-1 mt-0.5">
                        {{ $expressionTitles[$expression] ?? $expression }}
                    </span>
                </div>
            </div>
        @endif

        {{-- هالة توهج خفيفة خلف فرفوش --}}
        <div class="absolute inset-0 bg-[#F2569A]/20 blur-xl rounded-full -z-10 group-hover:bg-[#FF8A4C]/30 transition-all"></div>
    </div>
</div>

