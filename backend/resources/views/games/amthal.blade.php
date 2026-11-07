@extends('layouts.app')

@section('title', 'تحدي الأمثال الشعبية التفاعلي | العب أونلاين مجاناً مع فرفشة')
@section('meta_description', 'كمّل المثل الشعبي خلال 20 ثانية واجمع النقاط مع فرفوش! تجربة حية تفاعلية بأجواء مصرية مرحة وحارة وفانوس وورق بردي.')

@section('content')
<div class="py-10 md:py-16 relative overflow-hidden" 
     x-data="amthalGame()"
     x-init="initProverb()">

    {{-- أجواء الحارة والفانوس --}}
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 space-y-8">
        
        {{-- شريط العنوان واللمسة المصرية --}}
        <div class="text-center space-y-3">
            <div class="inline-flex items-center gap-2 px-4 py-1 rounded-full bg-[#FF8A4C]/20 border border-[#FF8A4C]/40 text-[#FFD27A] text-xs font-bold">
                <span>🏮</span>
                <span>أجواء حارة فرفشة التراثية</span>
                <span>🏮</span>
            </div>

            <h1 class="text-3xl sm:text-4xl md:text-5xl font-black text-white">
                تحدي الأمثال الشعبية!
            </h1>
            
            <p class="text-sm md:text-base text-purple-200/80 max-w-xl mx-auto">
                قدامك 20 ثانية.. اقرأ أول المثل واختار التكملة الصح من غير تلميح تاخد 3 نقاط، بالتلميح تاخد نقطتين!
            </p>
        </div>

        {{-- لوحة النقاط والعداد الزمني --}}
        <div class="flex items-center justify-between glass-card px-6 py-4 border-white/10">
            <div class="flex items-center gap-3">
                <span class="text-2xl">🏆</span>
                <div>
                    <div class="text-xs text-purple-300">مجموع نقاطك</div>
                    <div class="text-xl font-black text-[#FFD27A]" x-text="totalScore + ' نقطة'">0 نقطة</div>
                </div>
            </div>

            {{-- المؤقت الزمني 20 ثانية --}}
            <div class="flex items-center gap-3">
                <div class="text-end">
                    <div class="text-xs text-purple-300">العداد</div>
                    <div class="text-xl font-black font-mono" 
                         :class="timer <= 5 ? 'text-red-400 animate-pulse' : 'text-white'"
                         x-text="timer + ' ثانية'">20 ثانية</div>
                </div>
                <div class="w-12 h-12 rounded-full border-4 flex items-center justify-center font-black text-sm"
                     :class="timer <= 5 ? 'border-red-500 bg-red-500/20 text-red-300' : 'border-[#FFC24B] bg-[#FFC24B]/20 text-[#FFD27A]'">
                    <span x-text="timer">20</span>
                </div>
            </div>
        </div>

        {{-- بطاقة الورق البردي التفاعلية (Parchment Card) --}}
        <div class="parchment-card p-6 md:p-12 relative shadow-2xl transition-all">
            
            {{-- شارة أعلى البطاقة --}}
            <div class="flex items-center justify-between mb-8">
                <span class="px-3.5 py-1 rounded-full text-xs font-black bg-[#3E2410] text-[#F6E3B8]">
                    📜 مثل رقم <span x-text="roundsPlayed + 1">1</span>
                </span>

                <button type="button" 
                        @click="requestHint()" 
                        :disabled="usedHint || verified || loading"
                        class="px-3.5 py-1.5 rounded-full text-xs font-black border-2 border-[#B88746] transition-all flex items-center gap-1.5 cursor-pointer"
                        :class="usedHint ? 'bg-[#B88746]/20 text-[#7A4B1A]' : 'bg-white hover:bg-[#F6E3B8] text-[#3E2410] shadow-sm'">
                    <span>💡</span>
                    <span x-text="usedHint ? 'تم أخذ تلميح (-1)' : 'طلب تلميح'">طلب تلميح</span>
                </button>
            </div>

            {{-- نص المثل المطلوب إكماله --}}
            <div class="text-center my-6 space-y-4">
                <div class="text-xs font-bold uppercase tracking-wider text-[#7A4B1A]">
                    كمّل صدر المثل الشعبي الآتي:
                </div>

                <div class="text-3xl md:text-5xl font-kufi font-black text-[#3E2410] leading-relaxed min-h-[70px] flex items-center justify-center">
                    <span x-text="currentProverb ? currentProverb.prompt : 'جارٍ تجهيز المثل...'">جارٍ التحميل...</span>
                </div>

                {{-- صندوق التلميح إن طُلب --}}
                <div x-show="hintText" x-transition class="p-3.5 rounded-xl bg-[#3E2410]/10 border border-[#B88746] text-xs md:text-sm text-[#3E2410] font-semibold max-w-lg mx-auto">
                    <span>💡 تلميح فرفوش: </span>
                    <span x-text="hintText"></span>
                </div>
            </div>

            {{-- خيارات الإجابة الثلاثة --}}
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 md:gap-4 mt-8">
                <template x-for="(option, idx) in (currentProverb ? currentProverb.options : [])" :key="idx">
                    <button type="button"
                            @click="submitAnswer(option)"
                            :disabled="verified || loading"
                            class="py-4 px-5 rounded-2xl font-bold text-base md:text-lg border-2 transition-all duration-200 text-center shadow-sm cursor-pointer"
                            :class="{
                                'bg-white hover:bg-[#F6E3B8] text-[#3E2410] border-[#B88746] hover:-translate-y-1': !verified && selectedOption !== option,
                                'bg-[#A35BFF] text-white border-[#7A2FE0]': !verified && selectedOption === option,
                                'bg-emerald-600 text-white border-emerald-700 shadow-md scale-105': verified && option === correctAnswer,
                                'bg-red-500 text-white border-red-700 opacity-80': verified && selectedOption === option && !isCorrect,
                                'opacity-50 pointer-events-none': verified && option !== correctAnswer && selectedOption !== option
                            }">
                        <span x-text="option"></span>
                    </button>
                </template>
            </div>

            {{-- نتيجة الجولة ورسالة فرفوش والشرح --}}
            <div x-show="verified" x-transition class="mt-8 pt-6 border-t-2 border-[#B88746]/40 text-center space-y-4">
                
                <div class="inline-flex items-center gap-2 px-4 py-2 rounded-2xl font-black text-base shadow"
                     :class="isCorrect ? 'bg-emerald-500/20 text-emerald-900 border border-emerald-600' : 'bg-red-500/20 text-red-900 border border-red-600'">
                    <span x-text="isCorrect ? '🎉 إجابة صحيحة!' : '❌ إجابة غير صحيحة!'"></span>
                    <span x-text="'+' + pointsEarned + ' نقطة'" class="font-mono text-sm bg-white/70 px-2 py-0.5 rounded-lg"></span>
                </div>

                <div class="text-sm font-bold text-[#3E2410] max-w-xl mx-auto" x-text="explanation"></div>

                {{-- زر تجربة مثل ثاني --}}
                <div class="pt-4 flex items-center justify-center gap-4">
                    <button type="button" 
                            @click="loadNextProverb()" 
                            class="btn-game-primary !py-3 !px-8 !text-base">
                        <span>جرّب مثل تاني ➔</span>
                    </button>

                    <a href="{{ url('/download') }}" class="btn-game-secondary !py-3 !px-6 !text-sm">
                        <span>حمّل اللعبة للمزيد 📱</span>
                    </a>
                </div>
            </div>

        </div>

        {{-- تميمة فرفوش التفاعلية مع ردة الفعل --}}
        <div class="text-center pt-2">
            <template x-if="!verified">
                <x-farfoush expression="thinking" speech="ركّز يا حريف! الأمثال الشعبية دي أصل الجدعنة!" size="md" />
            </template>
            <template x-if="verified && isCorrect">
                <x-farfoush expression="celebrating" speech="عاش يا بطل! إنت حافظ التراث الشعبي عن ظهر قلب! 🎉" size="md" />
            </template>
            <template x-if="verified && !isCorrect">
                <x-farfoush expression="confused_sad" speech="يلا معلش! الجايات أحسن، فرفوش معاك في المثل الجاي! 💪" size="md" />
            </template>
        </div>

    </div>
</div>

<script>
function amthalGame() {
    return {
        currentProverb: @json($initialProverb),
        selectedOption: null,
        correctAnswer: null,
        isCorrect: false,
        pointsEarned: 0,
        explanation: '',
        hintText: null,
        usedHint: false,
        verified: false,
        loading: false,
        totalScore: 0,
        roundsPlayed: 0,
        timer: 20,
        timerInterval: null,

        initProverb() {
            if (!this.currentProverb) {
                this.loadNextProverb();
            } else {
                this.startTimer();
            }
        },

        startTimer() {
            this.timer = 20;
            clearInterval(this.timerInterval);
            this.timerInterval = setInterval(() => {
                if (this.timer > 0 && !this.verified) {
                    this.timer--;
                } else if (this.timer === 0 && !this.verified) {
                    this.timeOut();
                }
            }, 1000);
        },

        timeOut() {
            clearInterval(this.timerInterval);
            if (!this.verified && this.currentProverb) {
                this.submitAnswer(''); // إجابة فارغة لانتهاء الوقت
            }
        },

        async requestHint() {
            if (this.usedHint || this.verified || !this.currentProverb) return;
            try {
                const res = await fetch('{{ url('/api/web/amthal/hint') }}', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({ id: this.currentProverb.id })
                });
                const data = await res.json();
                this.hintText = data.hint;
                this.usedHint = true;
            } catch (e) {
                console.error(e);
            }
        },

        async submitAnswer(option) {
            if (this.verified || this.loading || !this.currentProverb) return;
            this.loading = true;
            this.selectedOption = option;
            clearInterval(this.timerInterval);

            try {
                const res = await fetch('{{ url('/api/web/amthal/verify') }}', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        id: this.currentProverb.id,
                        chosen_answer: option,
                        used_hint: this.usedHint
                    })
                });

                const data = await res.json();
                this.isCorrect = data.is_correct;
                this.correctAnswer = data.correct_answer;
                this.pointsEarned = data.points_earned;
                this.explanation = data.explanation;
                this.totalScore += data.points_earned;
                this.verified = true;
                this.roundsPlayed++;

                window.trackEvent('amthal_demo_answer', {
                    is_correct: data.is_correct,
                    points: data.points_earned
                });
            } catch (e) {
                console.error(e);
            } finally {
                this.loading = false;
            }
        },

        async loadNextProverb() {
            this.loading = true;
            this.verified = false;
            this.selectedOption = null;
            this.correctAnswer = null;
            this.hintText = null;
            this.usedHint = false;

            try {
                const excludeParam = this.currentProverb ? `?exclude_id=${this.currentProverb.id}` : '';
                const res = await fetch(`{{ url('/api/web/amthal/random') }}${excludeParam}`, {
                    headers: { 'Accept': 'application/json' }
                });
                const data = await res.json();
                this.currentProverb = data;
                this.startTimer();
            } catch (e) {
                console.error(e);
            } finally {
                this.loading = false;
            }
        }
    };
}
</script>
@endsection

