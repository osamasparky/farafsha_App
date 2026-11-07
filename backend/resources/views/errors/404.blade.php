@extends('layouts.app')

@section('title', '404 - الصفحة غير موجودة | فرفشة')
@section('meta_description', 'الصفحة التي تبحث عنها غير موجودة أو تم نقلها.')

@section('content')
<div class="py-20 md:py-32 flex items-center justify-center">
    <div class="max-w-md mx-auto px-4 text-center space-y-6">
        
        <x-farfoush expression="confused_sad" speech="يا خبر! دوّرت في كل حارة وملقتش الصفحة دي خالص! 🙈" size="lg" />

        <div class="space-y-2">
            <span class="text-xs font-mono font-bold text-[#FF8A4C] tracking-widest uppercase">خطأ 404</span>
            <h1 class="text-3xl md:text-4xl font-black text-white">الصفحة تاهت في الحارة!</h1>
            <p class="text-sm text-purple-200/80 leading-relaxed">
                الرابط الذي تحاول الوصول إليه غير موجود، ربما تم حذفه أو كتابة الرابط بشكل خاطئ.
            </p>
        </div>

        <div class="pt-4 flex flex-col sm:flex-row items-center justify-center gap-3">
            <x-game-button href="{{ url('/') }}" variant="primary" class="w-full sm:w-auto !py-2.5 !px-6 !text-sm">
                <span>🏠 العودة للرئيسية</span>
            </x-game-button>

            <x-game-button href="{{ url('/games') }}" variant="secondary" class="w-full sm:w-auto !py-2.5 !px-6 !text-sm">
                <span>🎲 اكتشف الألعاب</span>
            </x-game-button>
        </div>

    </div>
</div>
@endsection

