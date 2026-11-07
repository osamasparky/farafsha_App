import Alpine from 'alpinejs';
import './echo';

window.Alpine = Alpine;

// تهيئة تفضيلات تقليل الحركة ومزامنتها
document.addEventListener('alpine:init', () => {
    Alpine.store('motion', {
        reduced: localStorage.getItem('farfasha_reduce_motion') === 'true' || 
                 window.matchMedia('(prefers-reduced-motion: reduce)').matches,
        toggle() {
            this.reduced = !this.reduced;
            localStorage.setItem('farfasha_reduce_motion', this.reduced);
            document.documentElement.classList.toggle('reduce-motion', this.reduced);
        }
    });

    if (localStorage.getItem('farfasha_reduce_motion') === 'true') {
        document.documentElement.classList.add('reduce-motion');
    }
});

// دالة تتبع الأحداث المتوافقة مع الخصوصية (Plausible / Umami)
window.trackEvent = function(eventName, props = {}) {
    try {
        if (window.plausible) {
            window.plausible(eventName, { props });
        } else if (window.umami) {
            window.umami.track(eventName, props);
        }
        console.debug(`[Farfasha Event] ${eventName}:`, props);
    } catch (e) {
        // ignore
    }
};

Alpine.start();
