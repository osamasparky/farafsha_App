<x-filament-panels::page>
    <form wire:submit="save" class="space-y-6">
        {{ $this->form }}

        <div class="flex flex-wrap items-center justify-between gap-4 pt-4 border-t border-white/10">
            <div class="flex items-center gap-3">
                <x-filament::button type="submit" size="lg" color="primary" icon="heroicon-o-check">
                    حفظ وتطبيق الإعدادات الآن 💾
                </x-filament::button>
            </div>

            <div class="flex items-center gap-3">
                <x-filament::button type="button" wire:click="sendTestWhatsApp" color="success" icon="heroicon-o-chat-bubble-left-ellipsis">
                    تجربة إرسال واتساب 📲
                </x-filament::button>

                <x-filament::button type="button" wire:click="sendTestEmail" color="info" icon="heroicon-o-envelope">
                    تجربة إرسال بريد SMTP ✉️
                </x-filament::button>
            </div>
        </div>
    </form>
</x-filament-panels::page>

