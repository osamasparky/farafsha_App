<?php

namespace App\Services;

use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;

class WahaClient
{
    private function http(): PendingRequest
    {
        return Http::baseUrl(rtrim(config('waha.base_url'), '/'))
            ->withHeaders(['X-Api-Key' => config('waha.api_key')])
            ->acceptJson()->asJson()
            ->connectTimeout(config('waha.connect_timeout'))
            ->timeout(config('waha.timeout'));
    }

    private function request(string $method, string $path, array $data = []): array
    {
        $response = $this->http()->send($method, $path, $data ? ['json' => $data] : []);
        $response->throw();
        return $response->json() ?? [];
    }

    public function sessions(bool $all = true): array { return $this->request('GET', '/api/sessions'.($all ? '?all=true' : '')); }
    public function session(string $name): array { return $this->request('GET', '/api/sessions/'.rawurlencode($name)); }
    public function createSession(string $name, string $webhookUrl, string $token): array
    {
        return $this->request('POST', '/api/sessions', ['name' => $name, 'config' => ['webhooks' => [[
            'url' => $webhookUrl, 'events' => ['message', 'message.any', 'message.ack', 'session.status'],
            'customHeaders' => [['name' => 'X-Waha-Webhook-Token', 'value' => $token]],
        ]]]]);
    }
    public function start(string $name): array { return $this->request('POST', '/api/sessions/'.rawurlencode($name).'/start'); }
    public function stop(string $name): array { return $this->request('POST', '/api/sessions/'.rawurlencode($name).'/stop'); }
    public function qr(string $name): string
    {
        $response = $this->http()->withHeaders(['Accept' => 'image/png'])->get('/api/'.rawurlencode($name).'/auth/qr');
        $response->throw();
        return $response->body();
    }
    public function sendText(string $session, string $chatId, string $text): array
    {
        return $this->request('POST', '/api/sendText', ['session' => $session, 'chatId' => $chatId, 'text' => $text]);
    }
}
