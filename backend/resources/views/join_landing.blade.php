@extends('layouts.app')

@section('title', 'انضمام إلى غرفة اللعب الجماعي | فرفشة')
@section('meta_description', 'تمت دعوتك للعب أونلاين في فرفشة! انقر للانضمام مباشرة أو استخدام رمز الغرفة.')

@section('content')
<div class="py-12 md:py-20 relative overflow-hidden" x-data="{ copied: false }">
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 space-y-8 text-center">
        
        {{-- أيقونة التطبيق وشعار اللعبة --}}
        <div class="flex flex-col items-center space-y-4">
            <div class="w-20 h-20 md:w-24 md:h-24 rounded-3xl bg-gradient-to-br from-[#FFB25E] via-[#FF8A4C] to-[#F2569A] p-1 shadow-[0_10px_35px_rgba(242,86,154,0.5)] transition-transform hover:scale-105">
                <img src="{{ asset('assets/app_icon.png') }}" alt="أيقونة تطبيق فرفشة" class="w-full h-full object-cover rounded-[22px]">
            </div>

            <span class="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-black bg-gradient-to-r from-[#25D366]/20 to-[#A35BFF]/20 text-[#25D366] border border-[#25D366]/40 shadow-lg">
                <span class="w-2 h-2 rounded-full bg-[#25D366] animate-pulse"></span>
                دعوة نشطة للعب المباشر أونلاين
            </span>

            <h1 class="text-3xl sm:text-4xl md:text-5xl font-black text-white leading-tight">
                يلا نلعب سوا في فرفشة! 🎉
            </h1>
            
            <p class="text-base text-purple-200/90 leading-relaxed max-w-lg mx-auto">
                @if($game)
                    تم إنشاء الغرفة لـ <strong class="text-[#FFD27A]">{{ $game->name }}</strong>
                    @if($playersCount > 0)
                        • متواجد حالياً <span class="text-[#25D366] font-bold">{{ $playersCount }} لاعبين</span>
                    @endif
                @else
                    تمت دعوتك للانضمام إلى جلسة لعب جماعية ممتعة!
                @endif
            </p>
        </div>

        {{-- بطاقة رمز الغرفة الفعلي --}}
        <div class="glass-card p-6 md:p-10 border-[#A35BFF]/50 text-center relative overflow-hidden shadow-2xl space-y-6">
            <div class="space-y-2">
                <span class="text-xs uppercase font-bold text-purple-300 tracking-widest block">رمز الغرفة السري</span>
                <div class="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-[#1E0E3D]/80 border-2 border-dashed border-[#FFB25E]/60 shadow-[0_0_30px_rgba(255,178,94,0.2)]">
                    <span class="font-mono text-4xl sm:text-5xl font-black tracking-widest text-[#FFD27A]">
                        {{ $code }}
                    </span>
                    <button 
                        type="button" 
                        @click="navigator.clipboard.writeText('{{ $code }}'); copied = true; setTimeout(() => copied = false, 2500)"
                        class="p-2.5 rounded-xl bg-white/10 hover:bg-white/20 text-white transition-all">
                        <svg x-show="!copied" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path></svg>
                        <svg x-show="copied" class="w-6 h-6 text-[#25D366]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                    </button>
                </div>
                <div x-show="copied" x-transition class="text-xs font-bold text-[#25D366] pt-1">
                    تم نسخ رمز الغرفة إلى الحافظة بنجاح! 📋
                </div>
            </div>

            {{-- أزرار الإجراءات الرئيسية --}}
            <div class="flex flex-col sm:flex-row items-center justify-center gap-4 pt-2">
                {{-- زر فتح التطبيق عبر Custom Scheme --}}
                <a href="{{ $deepLink }}" 
                   class="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-gradient-to-r from-[#25D366] to-[#128C7E] hover:from-[#20BA5C] hover:to-[#0F7569] text-white font-black text-lg shadow-[0_10px_25px_rgba(37,211,102,0.4)] transition-all hover:scale-105">
                    <span>🚀</span>
                    <span>فتح في تطبيق فرفشة مباشرة</span>
                </a>

                {{-- زر تحميل التطبيق في حال عدم التثبيت --}}
                <a href="{{ url('/download') }}" 
                   class="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-bold text-base border border-white/20 transition-all hover:scale-105">
                    <span>📲</span>
                    <span>تحميل التطبيق (Android / iOS)</span>
                </a>
            </div>

            <div class="pt-2 text-xs text-purple-300/80">
                لو التطبيق مثبت على موبايلك، اضغط على الزر الأخضر وسيتم فتح شاشة الغرفة وتعبئة الكود تلقائياً!
            </div>
        </div>

    </div>
</div>

{{-- محاولة فتح التطبيق تلقائياً عند الدخول من الهاتف --}}
<script>
    document.addEventListener("DOMContentLoaded", function () {
        var userAgent = navigator.userAgent || navigator.vendor || window.opera;
        var isMobile = /android|iphone|ipad|ipod/i.test(userAgent);
        
        if (isMobile) {
            // محاولة توجيه خفيفة للرابط المباشر
            setTimeout(function () {
                window.location.href = "{{ $deepLink }}";
            }, 600);
        }
    });
</script>
@endsection
