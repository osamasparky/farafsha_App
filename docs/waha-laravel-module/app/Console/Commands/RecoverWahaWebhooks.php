<?php

namespace App\Console\Commands;

use App\Jobs\ProcessWahaWebhook;
use App\Models\WahaWebhookEvent;
use Illuminate\Console\Command;

class RecoverWahaWebhooks extends Command
{
    protected $signature = 'waha:webhooks:recover {--minutes=5 : Only events older than this many minutes} {--limit=500}';
    protected $description = 'Redispatch stale, unprocessed WAHA webhook inbox rows';

    public function handle(): int
    {
        $count = 0;
        WahaWebhookEvent::query()->whereNull('processed_at')
            ->where('created_at', '<', now()->subMinutes((int) $this->option('minutes')))
            ->orderBy('id')->limit((int) $this->option('limit'))->each(function ($event) use (&$count) {
                ProcessWahaWebhook::dispatch($event->id)->onQueue(config('waha.webhook_queue'));
                $count++;
            });
        $this->info("Redispatched {$count} event(s).");
        return self::SUCCESS;
    }
}
