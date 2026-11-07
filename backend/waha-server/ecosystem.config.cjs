module.exports = {
  apps: [
    {
      name: 'waha-server',
      script: 'server.js',
      cwd: '/var/www/vhosts/farafsha.com/backend/waha-server',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: '3000',
        WAHA_API_KEY: 'farfasha_waha_api_key_secure_2026_random_token_xyz',
        WAHA_WEBHOOK_TOKEN: 'farfasha_waha_webhook_token_secure_2026_secret',
        WAHA_WEBHOOK_URL: 'https://farafsha.com/api/webhooks/waha',
      },
    },
  ],
};

