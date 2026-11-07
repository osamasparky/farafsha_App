<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Symfony\Component\Process\Process;

class WahaServeCommand extends Command
{
    protected $signature = 'waha:serve {--port=3000 : Port to run the embedded WAHA server on}';
    protected $description = 'تشغيل خادم واتساب المدمج (Embedded WAHA Server) لربط واتساب وإرسال الـ OTP';

    public function handle(): int
    {
        $port = (int) $this->option('port');
        $serverScript = base_path('waha-server/server.js');

        if (!file_exists($serverScript)) {
            $this->error("الملف غير موجود: {$serverScript}");
            return self::FAILURE;
        }

        $nodeModules = base_path('waha-server/node_modules');
        if (!is_dir($nodeModules)) {
            $this->info("جاري تثبيت اعتمادات خادم واتساب المدمج (npm install)...");
            $installProcess = new Process(['npm', 'install'], base_path('waha-server'));
            $installProcess->setTimeout(300);
            $installProcess->run(function ($type, $buffer) {
                $this->output->write($buffer);
            });
        }

        $this->info("=================================================");
        $this->info("🚀 جاري تشغيل خادم واتساب فرفشة المدمج (Embedded WAHA)");
        $this->info("📍 الرابط: http://127.0.0.1:{$port}");
        $this->info("🔑 مفتاح الـ API: " . config('waha.api_key'));
        $this->info("=================================================");

        $env = array_merge($_ENV, [
            'PORT' => (string) $port,
            'WAHA_API_KEY' => (string) config('waha.api_key'),
            'WAHA_WEBHOOK_TOKEN' => (string) config('waha.webhook_token'),
            'WAHA_WEBHOOK_URL' => (string) config('waha.webhook_url'),
        ]);

        $process = new Process(['node', 'server.js'], base_path('waha-server'), $env);
        $process->setTimeout(null);

        $process->run(function ($type, $buffer) {
            $this->output->write($buffer);
        });

        return self::SUCCESS;
    }
}
