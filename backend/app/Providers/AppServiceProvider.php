<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        try {
            if (\Illuminate\Support\Facades\Schema::hasTable('site_settings')) {
                $mailSettings = \App\Models\SiteSetting::get('mail_settings');
                if (is_array($mailSettings) && !empty($mailSettings['host'])) {
                    config([
                        'mail.default' => $mailSettings['mailer'] ?? 'smtp',
                        'mail.mailers.smtp.host' => $mailSettings['host'],
                        'mail.mailers.smtp.port' => (int) ($mailSettings['port'] ?? 587),
                        'mail.mailers.smtp.encryption' => ($mailSettings['encryption'] ?? 'tls') === 'none' ? null : ($mailSettings['encryption'] ?? 'tls'),
                        'mail.mailers.smtp.username' => $mailSettings['username'] ?? null,
                        'mail.mailers.smtp.password' => $mailSettings['password'] ?? null,
                        'mail.from.address' => $mailSettings['from_address'] ?? config('mail.from.address'),
                        'mail.from.name' => $mailSettings['from_name'] ?? config('mail.from.name'),
                    ]);
                }
            }
        } catch (\Throwable) {}
    }
}
