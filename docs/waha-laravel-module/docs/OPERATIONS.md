# Deployment and operations

## Network and secrets

- For app and WAHA containers, attach the PHP app, queue worker, and WAHA to the same user-defined bridge `waha_internal` network. The sample deliberately has no WAHA host port mapping; the normal bridge allows WAHA outbound internet access while keeping inbound host access unpublished. Do not mark this network `internal: true`, because WAHA must reach WhatsApp.
- For Laravel running on the host, bind `127.0.0.1:3000:3000` and use loopback. Never expose port 3000 on a public interface. Keep dashboard and Swagger off in production, or put behind VPN/basic auth and IP allow-list if needed for pairing diagnostics.
- Keep the WAHA API key and webhook token independently generated, long, and out of source control. WAHA's `X-Api-Key` authenticates API requests; `X-Waha-Webhook-Token` on each session webhook authenticates callbacks. If custom headers differ in your pinned WAHA release, configure a secret path or HMAC supported by that exact release and update the verifier.
- Session volume contains linked-device credentials: encrypt volume/backups, restrict host permissions, and never include QR or session files in logs/support bundles. A QR grants account access until it expires.

## First pairing

1. Start the app and WAHA, then apply DB migrations and run a worker for both configured queues (e.g. `whatsapp,whatsapp-webhooks`).
2. With a Sanctum-authenticated admin, `POST /api/wa/sessions` body `{"name":"sales_1"}`, then `POST /api/wa/sessions/sales_1/start`. Session creation starts by default in current WAHA docs; start is idempotent and ensures it's running.
3. Poll WAHA session status or receive `session.status`. On `SCAN_QR_CODE`, retrieve `GET /api/wa/sessions/sales_1/qr` from the authenticated app and scan promptly from WhatsApp > Linked devices. QR rotates; fetch a fresh one each time status indicates scanning.
4. Wait for `WORKING`. Confirm using test opt-in recipient before enabling normal traffic. Repeat for each authorized account.

## Events and state

Configured event set:

- `session.status`: persist `payload.status` (`STOPPED`, `STARTING`, `SCAN_QR_CODE`, `WORKING`, `FAILED`, and newer states); do not assume the enum is closed.
- `message`: inbound message event; `message.any`: all created messages, including own sends. Store by WAHA payload ID to collapse duplicate `message`/`message.any` echoes. `message.any` often exposes `source` (`app` or `api`).
- `message.ack`: message acknowledgement: -1 error, 0 pending, 1 server, 2 device, 3 read, 4 played. Delivery semantics and field availability depend on engine. Here 1/2 map to `delivered`, 3/4 to `read`.

Webhook event IDs are documented as `evt_...` ULID-like identifiers. The controller stores the full payload; apply a retention job to delete/obfuscate event rows after an agreed period, and avoid retaining sensitive message content longer than needed. Restrict DB/log access.

## Sending and risk controls

- The module requires caller confirmation of opt-in but does not prove it. Connect this to your CRM consent record and enforce per-tenant policy before release.
- Send only expected, consented conversations. Avoid purchased lists, cold outreach, repetitive templates, unsolicited groups, and rapid bursts. Let recipients opt out and suppress them immediately. Ramp slowly and monitor complaints/restrictions.
- 100–500 sends/day across personal accounts is not a safe limit promised by WhatsApp or WAHA; account history, recipient feedback, content, and patterns matter. WAHA is unofficial and accounts can be limited/blocked without warning. Never use this design where uninterrupted delivery or compliance guarantees are required.
- Add per-session queue rate limiting and a send window before production. Suggested starting point: serialize per session, one message every 8–15 seconds with jitter, and a daily ceiling chosen below observed account tolerance; stop on errors, opt-outs, or any restriction signal. These are conservative engineering defaults, not a guarantee of safety.
- Reconcile `unknown` messages before manually retrying. A timeout can occur after WAHA accepted the send. Match `message.any`/`message.ack` by WAHA ID; where IDs are not returned, reconcile session/chat/time/body carefully.

## Recovery, backup, upgrades

- Back up database and the WAHA sessions volume together. Test restores on an isolated host; do not run two active copies of the same account credentials at once.
- Queue recovery: run the included `php artisan waha:webhooks:recover` every few minutes. Register `Schedule::command('waha:webhooks:recover')->everyFiveMinutes()->withoutOverlapping()` in Laravel 11/12 `routes/console.php` (or your existing scheduler). This closes the DB-commit/queue-dispatch crash window; the processor is idempotent.
- Outbound retry is limited to explicit HTTP 429 rejection with backoff. Connection timeouts and 5xx responses are marked `unknown` because the send may have succeeded; reconcile them before any manual retry.
- Prune old webhook events and outbound/inbound messages per retention policy; retain consent/opt-out audit data according to your business requirements.
- Pin WAHA image to a tested version or digest. Before upgrades, inspect its generated Swagger and official release notes; test session restore, QR refresh, webhook signature/header, event payloads, acknowledgements, and outbound behavior on a spare account.
- Verify official WAHA health via `GET /api/sessions` (authorized request); use container health/logs plus app queue depth, failed jobs, webhook backlog, and counts of `unknown`/`failed` messages. Alert on stale `WORKING`, repeated `FAILED`, backlog growth, and unexpected send failure spikes.

## Suggested production additions

- Tenant authorization around session and message ownership; admin-only session creation/QR.
- Per-session Redis lock and rate limiter, daily quota table, consent ledger, opt-out suppression, content templates, audit trail, retention command, and an authenticated reconciliation screen for `unknown` results.
- Webhook replay protection beyond unique event IDs when using public routes; rate limiting, body size limits, TLS termination, and restrict network ingress to WAHA's internal network.
- Alerting, queue worker supervisor, graceful deploy/restart, and database/volume restore drills.
