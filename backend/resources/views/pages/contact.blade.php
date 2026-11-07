@extends('layouts.app')

@section('title', 'تواصل معنا | فريق منصة فرفشة')
@section('meta_description', 'تواصل مع فريق منصة فرفشة للاقتراحات والاستفسارات والشراكات والدعم الفني.')

@section('content')
<div class="py-12 md:py-20" x-data="{ sent: false, loading: false, error: null, successMessage: null }">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        
        <div class="text-center space-y-3">
            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#FF8A4C]/20 text-[#FFD27A] border border-[#FF8A4C]/30">
                📬 نحن هنا لمساعدتك
            </span>
            <h1 class="text-3xl md:text-5xl font-black text-white">تواصل معنا</h1>
            <p class="text-sm md:text-base text-purple-200/80 max-w-xl mx-auto">
                عندك فكرة لعبة جديدة؟ واجهتك مشكلة؟ أو حابب تقترح أمثال وإفيهات جديدة؟ اكتب لنا!
            </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            
            {{-- الجانب التعريفي ومعلومات التواصل --}}
            <div class="lg:col-span-5 space-y-6">
                <div class="glass-card p-6 border-white/10 space-y-4">
                    <h3 class="text-lg font-black text-white">معلومات الدعم السريع</h3>
                    
                    <div class="space-y-3 text-xs md:text-sm text-purple-200">
                        <div class="flex items-center gap-3">
                            <span class="w-8 h-8 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center text-base">✉️</span>
                            <div>
                                <div class="text-[11px] text-purple-300">البريد الإلكتروني للدعم</div>
                                <a href="mailto:support@farfasha.app" class="font-bold text-white hover:text-[#FFD27A]">support@farfasha.app</a>
                            </div>
                        </div>

                        <div class="flex items-center gap-3">
                            <span class="w-8 h-8 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center text-base">⚡</span>
                            <div>
                                <div class="text-[11px] text-purple-300">وقت الرد المتوقع</div>
                                <div class="font-bold text-white">خلال 24 ساعة كحد أقصى</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="text-center pt-2">
                    <x-farfoush expression="welcome" speech="فرفوش بيقرأ كل رسايلكم وبيفرح باقتراحاتكم لألعاب جديدة!" size="md" />
                </div>
            </div>

            {{-- نموذج التواصل المباشر --}}
            <div class="lg:col-span-7">
                <div class="glass-card p-6 md:p-10 border-[#A35BFF]/30 shadow-xl">
                    
                    <form @submit.prevent="
                        loading = true;
                        error = null;
                        fetch('{{ url('/api/web/contact') }}', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-TOKEN': document.querySelector('meta[name=\'csrf-token\']').content,
                                'Accept': 'application/json'
                            },
                            body: JSON.stringify({
                                name: $refs.cName.value,
                                email: $refs.cEmail.value,
                                subject: $refs.cSubject.value,
                                message: $refs.cMessage.value,
                                subject_hp: $refs.cHp.value
                            })
                        })
                        .then(r => r.json().then(d => ({ status: r.status, data: d })))
                        .then(res => {
                            loading = false;
                            if (res.status === 200) {
                                sent = true;
                                successMessage = res.data.message;
                            } else {
                                error = res.data.error || res.data.message || 'حدث خطأ في الإرسال، تأكد من صحة البيانات.';
                            }
                        })
                        .catch(() => {
                            loading = false;
                            error = 'تعذر الاتصال بالخادم، يرجى المحاولة لاحقاً.';
                        });
                    " class="space-y-4">
                        
                        {{-- حقل الـ Honeypot المخفي ضد السبام --}}
                        <input type="text" x-ref="cHp" name="subject_hp" class="hidden" tabindex="-1" autocomplete="off">

                        <div x-show="!sent" class="space-y-4">
                            <div>
                                <label class="block text-xs font-bold text-purple-200 mb-1.5">الاسم الكريم</label>
                                <input type="text" x-ref="cName" required placeholder="أدخل اسمك..." class="w-full bg-[#150A2E] border border-purple-800 rounded-xl px-4 py-2.5 text-white text-sm focus:border-[#A35BFF] focus:outline-none">
                            </div>

                            <div>
                                <label class="block text-xs font-bold text-purple-200 mb-1.5">البريد الإلكتروني</label>
                                <input type="email" x-ref="cEmail" required placeholder="name@example.com" class="w-full bg-[#150A2E] border border-purple-800 rounded-xl px-4 py-2.5 text-white text-sm focus:border-[#A35BFF] focus:outline-none">
                            </div>

                            <div>
                                <label class="block text-xs font-bold text-purple-200 mb-1.5">موضوع الرسالة</label>
                                <input type="text" x-ref="cSubject" placeholder="اقتراح لعبة، استفسار، مشكلة تقنية..." class="w-full bg-[#150A2E] border border-purple-800 rounded-xl px-4 py-2.5 text-white text-sm focus:border-[#A35BFF] focus:outline-none">
                            </div>

                            <div>
                                <label class="block text-xs font-bold text-purple-200 mb-1.5">الرسالة</label>
                                <textarea x-ref="cMessage" required rows="4" placeholder="اكتب رسالتك هنا بالتفصيل..." class="w-full bg-[#150A2E] border border-purple-800 rounded-xl px-4 py-2.5 text-white text-sm focus:border-[#A35BFF] focus:outline-none"></textarea>
                            </div>

                            <button type="submit" :disabled="loading" class="btn-game-primary w-full !py-3 !text-base">
                                <span x-show="!loading">إرسال الرسالة ➔</span>
                                <span x-show="loading">جارٍ الإرسال...</span>
                            </button>
                        </div>

                        {{-- إشعار النجاح --}}
                        <div x-show="sent" x-transition class="p-6 rounded-2xl bg-emerald-500/20 border border-emerald-500 text-center space-y-2">
                            <span class="text-3xl">🎉</span>
                            <h4 class="text-lg font-black text-white">تم إرسال رسالتك بنجاح!</h4>
                            <p class="text-xs text-emerald-200" x-text="successMessage"></p>
                        </div>

                        {{-- إشعار الخطأ --}}
                        <div x-show="error" x-transition class="p-3 rounded-xl bg-red-500/20 border border-red-500/50 text-red-200 text-xs">
                            <span x-text="error"></span>
                        </div>

                    </form>

                </div>
            </div>

        </div>

    </div>
</div>
@endsection

