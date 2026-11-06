# WAHA Community + Laravel 11/12 integration

Implementation scaffold for an existing Laravel application. It keeps WAHA reachable only on a private Docker network, stores a durable event inbox before acknowledging webhooks, and sends outbound work through Laravel's Redis queue.

## Assumptions

- Existing Laravel 11 or 12 application, PHP 8.2+, MySQL/PostgreSQL, Redis queue, and a reverse proxy already serving Laravel.
- WAHA Community Edition (`devlikeapro/waha`) runs on the same host. Pin a tested image tag/digest before production; `latest` is shown only for initial setup.
- One WAHA container may hold several sessions. Configure one WAHA session per personal WhatsApp account, normally 2–5 sessions.
- This is an unofficial WhatsApp Web integration. A personal account can be restricted or banned; WAHA cannot make 100–500 daily sends safe or guaranteed. Use only opt-in recipients, honor STOP/opt-outs, and throttle conservatively. For business-critical or high-volume messaging, use the official WhatsApp Business Platform.
- No repository was supplied, so these are files to copy/merge, not a drop-in package. Adjust the app's auth/tenant policy and DB engine as appropriate.

## Files

```text
docker-compose.waha.yml
.env.waha.example
config/waha.php
database/migrations/2026_11_07_000001_create_waha_tables.php
app/Models/WahaSession.php
app/Models/WahaMessage.php
app/Models/WahaWebhookEvent.php
app/Services/WahaClient.php
app/Services/WahaMessageService.php
app/Jobs/SendWahaMessage.php
app/Jobs/ProcessWahaWebhook.php
app/Console/Commands/RecoverWahaWebhooks.php
app/Http/Controllers/WahaWebhookController.php
app/Http/Controllers/Api/WahaSessionController.php
app/Http/Controllers/Api/WahaMessageController.php
routes/waha.php
tests/Feature/WahaWebhookTest.php
tests/Feature/WahaSendTest.php
docs/OPERATIONS.md
```

## Install

1. Copy `docker-compose.waha.yml` beside your app's existing `compose.yaml` and merge the `waha` service and `waha_internal` network into that Compose project. Attach the Laravel PHP and queue-worker services to `waha_internal`; do not publish WAHA's port. This private bridge gives app-to-WAHA access and WAHA outbound internet access. If Laravel is hosted directly on the host rather than in Compose, bind WAHA to `127.0.0.1:3000` and use `http://127.0.0.1:3000` in Laravel.
2. Copy `.env.waha.example` entries into Laravel `.env`; generate distinct long random values for `WAHA_API_KEY` and `WAHA_WEBHOOK_TOKEN`. Set `WAHA_BASE_URL=http://waha:3000` and `WAHA_WEBHOOK_URL=http://<laravel-service-name>:<port>/api/webhooks/waha` for containers on the same Compose network; use the actual PHP web service name and port.
3. Copy module files into matching paths. Add `require __DIR__.'/waha.php';` in `routes/api.php` (or include the routes in your route provider). In `bootstrap/app.php` Laravel 11/12 default API middleware is stateless; keep the webhook outside CSRF middleware. Protect management/send endpoints with your app's auth middleware and policy.
4. Run migration, start Redis queue workers, then start WAHA. Create a session with `POST /api/sessions`, start it, fetch QR, and scan from WhatsApp > Linked devices.
5. Use the bundled Feature tests as a starting point; run them in the existing application after adapting auth and database setup.

## API shape

- `GET /api/wa/sessions`; `POST /api/wa/sessions` creates/configures session; `POST /api/wa/sessions/{name}/start`; `POST /api/wa/sessions/{name}/stop`; `GET /api/wa/sessions/{name}/qr` (no-store, authenticated); `GET /api/wa/sessions/{name}`.
- `POST /api/wa/messages` queues an opt-in text message; `GET /api/wa/messages/{message}` reads local state.
- `POST /api/webhooks/waha` accepts WAHA webhook. It checks `X-WAHA-Webhook-Token`, saves the event uniquely, dispatches processing, and promptly returns 202.

All management and send endpoints require `auth:sanctum` by default. Change to the application's existing API guard if needed. The webhook token is separate from the WAHA API key.

## Delivery guarantees

- Webhook `id` is unique and deduplicated. A missing WAHA `id` receives a deterministic hash of event/session/payload. The inbox row is committed before queue dispatch; the included `waha:webhooks:recover` command redispatches stale unprocessed rows.
- Outbound API callers can supply `idempotency_key`; DB uniqueness prevents duplicate enqueue. WAHA `sendText` itself has no documented idempotency key, so if a network timeout occurs after WhatsApp accepted a message, blindly retrying could duplicate it. The job records `sending` before the request and marks ambiguous transport failures `unknown` without automatic retry. Definite HTTP 429/5xx retries use backoff only when configured safe; operator can reconcile unknown outcomes from `message.any`/`message.ack` events.
- Laravel retries webhook processing, not the webhook HTTP response; event storage is the durable boundary.

## WAHA contract checked

The current official docs describe `POST /api/sessions`, `POST /api/sessions/{session}/start|stop`, `GET /api/{session}/auth/qr`, `GET /api/sessions/{session}`, and `POST /api/sendText`. Webhook event names used here are `message`, `message.any`, `message.ack`, and `session.status`. QR is refreshed when `session.status` reports `SCAN_QR_CODE`. Payload formats and engine support vary; confirm the generated Swagger for the pinned Community image before upgrading.

## Architecture

```text
Authenticated Laravel API -> DB outbound row -> Redis queue -> WahaClient -> private WAHA
                                                        <- WAHA webhook <-
                                       webhook inbox DB -> Redis queue -> normalized status/message
```

WAHA and Laravel share a private network; no WAHA `ports:` mapping exists in the Compose example. Only Laravel's public reverse proxy is internet facing. `WAHA_API_KEY` is sent as `X-Api-Key`; the webhook uses its own constant-time checked secret header. QR responses are private, never logged, and marked no-store.

See [operations guide](docs/OPERATIONS.md) for runbook, event mapping, safety, monitoring, backups, and deployment.
