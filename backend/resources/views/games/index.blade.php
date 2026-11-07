@extends('layouts.app')

@section('title', 'دليل ألعاب فرفشة | تصفح وفلتر ألعاب اللمة الجماعية')
@section('meta_description', 'استكشف ألعاب فرفشة المتنوعة: أمثال شعبية، إفيهات أفلام، شخصيات، وممنوع تقول. فلاتر سريعة للبحث حسب عدد اللاعبين ونمط اللعب وبدون إنترنت.')

@section('content')
<div class="py-12 md:py-16">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {{-- ترويسة الصفحة --}}
        <div class="text-center max-w-3xl mx-auto mb-12 space-y-3">
            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#A35BFF]/20 text-[#FFD27A] border border-[#A35BFF]/30">
                🎮 مكتبة الألعاب الكاملة
            </span>
            <h1 class="text-3xl md:text-5xl font-black text-white">
                اختر لعبتك وولّع القعدة!
            </h1>
            <p class="text-base text-purple-200/80 leading-relaxed">
                استخدم الفلاتر السريعة لاختيار اللعبة المناسبة لعدد لاعبيكم ونمط اللعب المفضل.
            </p>
        </div>

        {{-- صندوق البحث والفلاتر (يعمل بنموذج GET لتوافق الـ URL والعمل بدون JS) --}}
        <div class="glass-card p-6 md:p-8 mb-12 border-[#A35BFF]/40 shadow-xl">
            <form action="{{ url('/games') }}" method="GET" class="space-y-6">
                
                {{-- شريط البحث بالاسم --}}
                <div class="flex flex-col sm:flex-row gap-3">
                    <div class="relative flex-grow">
                        <input type="text" 
                               name="q" 
                               value="{{ request('q') }}" 
                               placeholder="ابحث باسم اللعبة أو الفكرة..." 
                               class="w-full bg-[#150A2E]/80 border-2 border-purple-800/60 focus:border-[#A35BFF] focus:outline-none rounded-2xl px-5 py-3 text-white placeholder-purple-300/50 text-sm md:text-base font-medium transition-colors">
                        @if(request('q'))
                            <a href="{{ url('/games') }}" class="absolute left-4 rtl:left-auto rtl:right-auto rtl:left-4 top-1/2 -translate-y-1/2 text-xs text-purple-400 hover:text-white">
                                ✕ مسح
                            </a>
                        @endif
                    </div>

                    <button type="submit" class="btn-game-primary !py-3 !px-7 !text-sm whitespace-nowrap">
                        <span>🔍 بحث</span>
                    </button>
                </div>

                {{-- الفلاتر السريعة --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4 border-t border-white/10 text-xs md:text-sm font-semibold">
                    
                    {{-- فلتر التصنيف --}}
                    <div>
                        <label class="block text-purple-300 mb-2">التصنيف</label>
                        <select name="category" onchange="this.form.submit()" class="w-full bg-[#1A0E38] border border-purple-800/60 rounded-xl px-3 py-2.5 text-white text-xs md:text-sm focus:border-[#A35BFF] focus:outline-none">
                            <option value="">جميع التصنيفات</option>
                            @foreach($categories as $cat)
                                <option value="{{ $cat }}" {{ request('category') === $cat ? 'selected' : '' }}>
                                    {{ $cat }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    {{-- فلتر نمط اللعب --}}
                    <div>
                        <label class="block text-purple-300 mb-2">نمط اللعب</label>
                        <select name="mode" onchange="this.form.submit()" class="w-full bg-[#1A0E38] border border-purple-800/60 rounded-xl px-3 py-2.5 text-white text-xs md:text-sm focus:border-[#A35BFF] focus:outline-none">
                            <option value="">جميع الأنماط</option>
                            <option value="local" {{ request('mode') === 'local' ? 'selected' : '' }}>جهاز واحد في القعدة (Local)</option>
                            <option value="online" {{ request('mode') === 'online' ? 'selected' : '' }}>أونلاين مع أصدقاء بعيدين</option>
                        </select>
                    </div>

                    {{-- فلتر عدد اللاعبين --}}
                    <div>
                        <label class="block text-purple-300 mb-2">عدد اللاعبين في قعدتكم</label>
                        <select name="players" onchange="this.form.submit()" class="w-full bg-[#1A0E38] border border-purple-800/60 rounded-xl px-3 py-2.5 text-white text-xs md:text-sm focus:border-[#A35BFF] focus:outline-none">
                            <option value="">أي عدد</option>
                            <option value="2" {{ request('players') == '2' ? 'selected' : '' }}>لاعبان (2)</option>
                            <option value="4" {{ request('players') == '4' ? 'selected' : '' }}>4 لاعبين (شائع)</option>
                            <option value="6" {{ request('players') == '6' ? 'selected' : '' }}>6 لاعبين</option>
                            <option value="8" {{ request('players') == '8' ? 'selected' : '' }}>8 لاعبين وأكثر (لمّة كبيرة)</option>
                        </select>
                    </div>

                    {{-- فلتر التوفر أوفلاين بدون إنترنت --}}
                    <div>
                        <label class="block text-purple-300 mb-2">الاتصال بالإنترنت</label>
                        <select name="offline" onchange="this.form.submit()" class="w-full bg-[#1A0E38] border border-purple-800/60 rounded-xl px-3 py-2.5 text-white text-xs md:text-sm focus:border-[#A35BFF] focus:outline-none">
                            <option value="">الكل</option>
                            <option value="1" {{ request('offline') === '1' ? 'selected' : '' }}>✈️ بدون إنترنت فقط (Offline)</option>
                        </select>
                    </div>

                </div>

                {{-- الفلاتر النشطة وزر مسح الكل --}}
                @if(request()->hasAny(['q', 'category', 'mode', 'players', 'offline']))
                    <div class="flex items-center justify-between pt-4 border-t border-white/5 text-xs">
                        <span class="text-purple-300">
                            تم العثور على <strong>{{ $games->count() }}</strong> لعبة مطابقة
                        </span>
                        <a href="{{ url('/games') }}" class="text-[#FF8A4C] hover:text-white font-bold transition-colors underline">
                            امسح كل الفلاتر ✕
                        </a>
                    </div>
                @endif

            </form>
        </div>

        {{-- شبكة عرض بطاقات الألعاب أو حالة عدم وجود نتائج --}}
        @if($games->isNotEmpty())
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                @foreach($games as $game)
                    <x-game-card :game="$game" />
                @endforeach
            </div>
        @else
            {{-- حالة عدم وجود نتائج: فرفوش محتار مع زر مسح الفلاتر --}}
            <div class="glass-card p-12 text-center max-w-lg mx-auto border-[#A35BFF]/30 my-8 space-y-6">
                <x-farfoush expression="confused_sad" speech="ملقتش أي لعبة مطابقة للفلاتر دي يا بطل! 🤔" size="lg" />
                
                <div class="space-y-2">
                    <h3 class="text-2xl font-black text-white">مفيش نتائج مطابقة</h3>
                    <p class="text-sm text-purple-200/80">
                        جرّب تعديل خيارات البحث أو امسح الفلاتر عشان تشوف كل ألعاب فرفشة.
                    </p>
                </div>

                <a href="{{ url('/games') }}" class="btn-game-primary !py-3 !px-8 !text-sm inline-flex">
                    <span>امسح كل الفلاتر واعرض الألعاب</span>
                </a>
            </div>
        @endif

    </div>
</div>
@endsection

