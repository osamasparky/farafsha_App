<?php

return [
    'base_url' => env('WAHA_BASE_URL', 'http://waha:3000'),
    'api_key' => env('WAHA_API_KEY'),
    'webhook_token' => env('WAHA_WEBHOOK_TOKEN'),
    'webhook_url' => env('WAHA_WEBHOOK_URL', 'http://app:8000/api/webhooks/waha'),
    'default_session' => env('WAHA_DEFAULT_SESSION', 'default'),
    'timeout' => (int) env('WAHA_HTTP_TIMEOUT', 20),
    'connect_timeout' => (int) env('WAHA_CONNECT_TIMEOUT', 3),
    'queue' => env('WAHA_QUEUE', 'whatsapp'),
    'webhook_queue' => env('WAHA_WEBHOOK_QUEUE', 'whatsapp-webhooks'),
    'max_attempts' => (int) env('WAHA_MAX_ATTEMPTS', 3),
];
