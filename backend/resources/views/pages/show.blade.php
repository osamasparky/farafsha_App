@extends('layouts.app')

@section('title', ($page ? $page->getTranslation('title', $currentLocale ?? 'ar') : 'صفحة') . ' | فرفشة')
@section('meta_description', $page->seo_description ?? ($page ? $page->getTranslation('subtitle', $currentLocale ?? 'ar') : ''))

@section('content')
<div class="py-12 md:py-20">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10">
        
        {{-- شريط المسار --}}
        <nav class="flex items-center gap-2 text-xs text-purple-300 font-medium">
            <a href="{{ url('/') }}" class="hover:text-white">الرئيسية</a>
            <span class="rtl:rotate-180">➔</span>
            <span class="text-[#FFD27A] font-bold">{{ $page ? $page->getTranslation('title', $currentLocale ?? 'ar') : 'صفحة' }}</span>
        </nav>

        {{-- ترويسة الصفحة --}}
        <div class="space-y-3">
            <h1 class="text-3xl md:text-5xl font-black text-white">
                {{ $page ? $page->getTranslation('title', $currentLocale ?? 'ar') : 'فرفشة' }}
            </h1>
            @if($page && $page->getTranslation('subtitle', $currentLocale ?? 'ar'))
                <p class="text-base md:text-lg text-[#FFD27A] font-semibold">
                    {{ $page->getTranslation('subtitle', $currentLocale ?? 'ar') }}
                </p>
            @endif
        </div>

        {{-- تنبيه المسودة القانونية إن كانت صفحة قانونية --}}
        @if(!empty($isLegal))
            <div class="p-4 rounded-2xl bg-[#FFC24B]/15 border-2 border-[#FFC24B] text-[#FFD27A] text-xs md:text-sm font-bold flex items-center gap-3 shadow-md">
                <span class="text-2xl">⚠️</span>
                <span>تنبيه وإخلاء مسؤولية: هذه النصوص مسودة صياغة عامة لأغراض التطوير وتخضع للمراجعة والاعتماد القانوني النهائي.</span>
            </div>
        @endif

        {{-- محتوى الصفحة الزجاجي --}}
        <div class="glass-card p-8 md:p-14 border-[#A35BFF]/30 prose prose-invert prose-purple max-w-none text-purple-100 text-sm md:text-base leading-relaxed">
            @if($page && $page->blocks)
                @foreach($page->blocks as $block)
                    @if(($block['type'] ?? '') === 'rich_text')
                        @php
                            $rawBody = (string) ($block['data']['body'] ?? '');
                            $cleanBody = strip_tags($rawBody, '<p><br><b><strong><i><em><u><s><ul><ol><li><a><h1><h2><h3><h4><h5><h6><blockquote><code><pre><hr><span><div>');
                            $cleanBody = preg_replace('/\s+on[a-z]+\s*=\s*(["\']).*?\1/is', '', $cleanBody);
                            $cleanBody = preg_replace('/\s+on[a-z]+\s*=\s*[^\s>]+/is', '', $cleanBody);
                            $cleanBody = preg_replace('/href\s*=\s*(["\'])\s*javascript:.*?\1/is', 'href="#"', $cleanBody);
                        @endphp
                        {!! $cleanBody !!}
                    @endif
                @endforeach
            @else
                <p>محتوى الصفحة قيد التجهيز والتحديث من لوحة الإدارة.</p>
            @endif
        </div>

        {{-- تميمة فرفوش في أسفل الصفحة --}}
        <div class="text-center pt-4">
            <x-farfoush expression="welcome" size="sm" />
        </div>

    </div>
</div>
@endsection

