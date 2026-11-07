import express from 'express';
import cors from 'cors';
import qrcode from 'qrcode';
import pino from 'pino';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import {
    makeWASocket,
    useMultiFileAuthState,
    DisconnectReason,
    fetchLatestBaileysVersion,
} from '@whiskeysockets/baileys';

// Process-level uncaught exception handlers to prevent Baileys/network crashes from killing the daemon
process.on('uncaughtException', (err) => {
    console.error('[WAHA UncaughtException]', err?.message || err);
});
process.on('unhandledRejection', (reason, promise) => {
    console.error('[WAHA UnhandledRejection]', reason?.message || reason);
});

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;
const API_KEY = process.env.WAHA_API_KEY || 'farfasha_waha_api_key_secure_2026_random_token_xyz';
const WEBHOOK_TOKEN = process.env.WAHA_WEBHOOK_TOKEN || 'farfasha_waha_webhook_token_secure_2026_secret';
const WEBHOOK_URL = process.env.WAHA_WEBHOOK_URL || 'http://127.0.0.1:8000/api/webhooks/waha';

// Sessions storage directory
const SESSIONS_DIR = path.resolve(__dirname, '../storage/app/waha_sessions');
if (!fs.existsSync(SESSIONS_DIR)) {
    fs.mkdirSync(SESSIONS_DIR, { recursive: true });
}

app.use(cors());
app.use(express.json());

// In-memory active sessions map
const activeSessions = new Map();

/**
 * Dispatch webhook to Laravel backend
 */
async function sendWebhook(event, sessionName, payload, extra = {}) {
    if (!WEBHOOK_URL) return;
    try {
        const body = {
            id: `wh_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
            event,
            session: sessionName,
            payload,
            ...extra,
        };

        await fetch(WEBHOOK_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Waha-Webhook-Token': WEBHOOK_TOKEN,
            },
            body: JSON.stringify(body),
        });
    } catch (err) {
        // Silently log in development
        console.warn(`[WAHA] Webhook delivery failed for ${event}:`, err.message);
    }
}

/**
 * Initialize / Start a Baileys session
 */
async function startSession(sessionName, forceClean = false) {
    if (activeSessions.has(sessionName) && !forceClean) {
        const current = activeSessions.get(sessionName);
        if (current.status === 'WORKING' || (current.status === 'STARTING' && current.sock)) {
            return current;
        }
    }

    const sessionPath = path.join(SESSIONS_DIR, sessionName);
    if (forceClean) {
        try {
            fs.rmSync(sessionPath, { recursive: true, force: true });
        } catch (e) {}
    }
    if (!fs.existsSync(sessionPath)) {
        fs.mkdirSync(sessionPath, { recursive: true });
    }

    let state, saveCreds;
    try {
        const auth = await useMultiFileAuthState(sessionPath);
        state = auth.state;
        saveCreds = auth.saveCreds;
    } catch (e) {
        console.error(`[WAHA] Auth state error for ${sessionName}, cleaning...`, e.message);
        fs.rmSync(sessionPath, { recursive: true, force: true });
        fs.mkdirSync(sessionPath, { recursive: true });
        const auth = await useMultiFileAuthState(sessionPath);
        state = auth.state;
        saveCreds = auth.saveCreds;
    }

    let version = [2, 3000, 1017531287];
    try {
        const v = await fetchLatestBaileysVersion();
        if (v?.version) version = v.version;
    } catch (e) {}

    const sessionData = {
        name: sessionName,
        status: 'STARTING',
        qr: null,
        phone: null,
        sock: null,
    };
    activeSessions.set(sessionName, sessionData);

    const logger = pino({ level: 'silent' });

    const sock = makeWASocket({
        version,
        logger,
        printQRInTerminal: false,
        auth: state,
        browser: ['Farfasha Platform', 'Chrome', '124.0.0.0'],
        syncFullHistory: false,
        connectTimeoutMs: 60000,
        defaultQueryTimeoutMs: 60000,
    });

    sessionData.sock = sock;

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', async (update) => {
        const { connection, lastDisconnect, qr } = update;

        if (qr) {
            sessionData.qr = qr;
            sessionData.status = 'SCAN_QR_CODE';
            console.log(`[WAHA] Session ${sessionName}: QR Code generated. Scan to link.`);
            sendWebhook('session.status', sessionName, { status: 'SCAN_QR_CODE' });
        }

        if (connection === 'close') {
            const statusCode = lastDisconnect?.error?.output?.statusCode;
            const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
            sessionData.status = 'STOPPED';
            sessionData.qr = null;
            console.log(`[WAHA] Session ${sessionName} connection closed (Code: ${statusCode}, Reconnect: ${shouldReconnect})`);
            sendWebhook('session.status', sessionName, { status: 'STOPPED' });

            if (shouldReconnect) {
                setTimeout(() => startSession(sessionName), 5000);
            } else {
                console.log(`[WAHA] Session ${sessionName} logged out permanently. Cleaning stale credentials.`);
                try {
                    fs.rmSync(sessionPath, { recursive: true, force: true });
                } catch (e) {}
                activeSessions.delete(sessionName);
            }
        } else if (connection === 'open') {
            sessionData.status = 'WORKING';
            sessionData.qr = null;
            const phone = sock.user?.id ? sock.user.id.split(':')[0] : 'unknown';
            sessionData.phone = phone;
            console.log(`[WAHA] Session ${sessionName} CONNECTED! Phone: ${phone}`);
            sendWebhook('session.status', sessionName, { status: 'WORKING' }, { me: { id: `${phone}@c.us` } });
        }
    });

    // Handle incoming messages
    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify') return;
        for (const msg of messages) {
            if (!msg.message) continue;
            const text =
                msg.message.conversation ||
                msg.message.extendedTextMessage?.text ||
                '';
            const senderJid = msg.key.remoteJid || '';
            const cleanPhone = senderJid.replace(/@.+/, '');

            sendWebhook('message', sessionName, {
                id: msg.key.id,
                from: `${cleanPhone}@c.us`,
                to: `${sessionData.phone}@c.us`,
                body: text,
                fromMe: msg.key.fromMe,
                timestamp: msg.messageTimestamp,
            });
        }
    });

    return sessionData;
}

/**
 * Stop a Baileys session
 */
async function stopSession(sessionName) {
    if (!activeSessions.has(sessionName)) return;
    const session = activeSessions.get(sessionName);
    try {
        if (session.sock) {
            session.sock.end(undefined);
        }
    } catch (e) {
        console.error('Error stopping session:', e);
    }
    session.status = 'STOPPED';
    session.qr = null;
    sendWebhook('session.status', sessionName, { status: 'STOPPED' });
}

// -------------------------------------------------------------
// WAHA REST API Endpoints
// -------------------------------------------------------------

// API Key check middleware
app.use('/api', (req, res, next) => {
    const providedKey = req.headers['x-api-key'];
    if (API_KEY && providedKey && providedKey !== API_KEY) {
        return res.status(401).json({ error: 'Unauthorized: Invalid X-Api-Key' });
    }
    next();
});

// GET /api/sessions
app.get('/api/sessions', (req, res) => {
    const list = [];
    for (const [name, s] of activeSessions.entries()) {
        list.push({
            name,
            status: s.status,
            me: s.phone ? { id: `${s.phone}@c.us` } : null,
        });
    }
    // Also include default if empty
    if (list.length === 0) {
        list.push({ name: 'default', status: 'STOPPED', me: null });
    }
    res.json(list);
});

// GET /api/sessions/:name
app.get('/api/sessions/:name', (req, res) => {
    const name = req.params.name;
    const s = activeSessions.get(name);
    if (!s) {
        return res.json({ name, status: 'STOPPED', me: null });
    }
    res.json({
        name,
        status: s.status,
        me: s.phone ? { id: `${s.phone}@c.us` } : null,
    });
});

// POST /api/sessions
app.post('/api/sessions', async (req, res) => {
    const { name } = req.body;
    const sessionName = name || 'default';
    if (!activeSessions.has(sessionName)) {
        activeSessions.set(sessionName, {
            name: sessionName,
            status: 'STOPPED',
            qr: null,
            phone: null,
            sock: null,
        });
    }
    res.status(201).json({ name: sessionName, status: 'STOPPED' });
});

// POST /api/sessions/:name/start
app.post('/api/sessions/:name/start', async (req, res) => {
    const name = req.params.name;
    try {
        startSession(name);
        res.json({ name, status: 'STARTING' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /api/sessions/:name/stop
app.post('/api/sessions/:name/stop', async (req, res) => {
    const name = req.params.name;
    try {
        await stopSession(name);
        res.json({ name, status: 'STOPPED' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /api/:name/auth/qr
app.get('/api/:name/auth/qr', async (req, res) => {
    const name = req.params.name;
    let session = activeSessions.get(name);

    if (session && session.status === 'WORKING') {
        return res.status(200).send('Session already connected and authenticated.');
    }

    if (!session || session.status === 'STOPPED' || !session.qr) {
        if (!session || session.status === 'STOPPED') {
            session = await startSession(name, false);
        }
    }

    // Wait up to 5 seconds for QR or connection
    let attempts = 0;
    while ((!session || (!session.qr && session.status !== 'WORKING')) && attempts < 25) {
        await new Promise((r) => setTimeout(r, 200));
        session = activeSessions.get(name) || session;
        attempts++;
    }

    // If still no QR and not connected, force clean stale credentials and restart to obtain QR
    if ((!session || !session.qr) && session?.status !== 'WORKING') {
        console.log(`[WAHA] Forcing clean start for session ${name} to generate fresh QR code...`);
        session = await startSession(name, true);
        attempts = 0;
        while ((!session || (!session.qr && session.status !== 'WORKING')) && attempts < 25) {
            await new Promise((r) => setTimeout(r, 200));
            session = activeSessions.get(name) || session;
            attempts++;
        }
    }

    if (session && session.status === 'WORKING') {
        return res.status(200).send('Session already connected and authenticated.');
    }

    if (!session || !session.qr) {
        return res.status(404).json({ error: 'QR Code not available yet, please try again in a moment.' });
    }

    try {
        res.setHeader('Content-Type', 'image/png');
        res.setHeader('Cache-Control', 'no-store, private');
        await qrcode.toFileStream(res, session.qr, {
            type: 'png',
            width: 350,
            margin: 2,
            color: {
                dark: '#1C0D38',
                light: '#FFFFFF',
            },
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to generate QR PNG: ' + err.message });
    }
});

// POST /api/sendText
app.post('/api/sendText', async (req, res) => {
    const { session, chatId, text } = req.body;
    const sessionName = session || 'default';
    const s = activeSessions.get(sessionName);

    if (!s || s.status !== 'WORKING' || !s.sock) {
        return res.status(503).json({
            error: `WhatsApp session '${sessionName}' is not connected (current status: ${s?.status || 'STOPPED'}). Please scan QR in admin panel to connect.`,
        });
    }

    try {
        // Convert chatId (e.g. 201012345678@c.us or 201012345678) to Baileys jid: 201012345678@s.whatsapp.net
        const digits = chatId.replace(/\D+/g, '');
        const jid = `${digits}@s.whatsapp.net`;

        const result = await s.sock.sendMessage(jid, { text });

        const messageId = result.key.id;
        console.log(`[WAHA] Message sent successfully to ${digits}. ID: ${messageId}`);

        res.json({
            id: messageId,
            timestamp: Date.now(),
        });
    } catch (err) {
        console.error(`[WAHA] Error sending text to ${chatId}:`, err);
        res.status(500).json({ error: 'Failed to send WhatsApp message: ' + err.message });
    }
});

// POST /api/deleteMessage (Delete / unsend message from WhatsApp)
app.post('/api/deleteMessage', async (req, res) => {
    const { session, chatId, messageId, fromMe = true } = req.body;
    const sessionName = session || 'default';
    const s = activeSessions.get(sessionName);

    if (!s || s.status !== 'WORKING' || !s.sock) {
        return res.status(503).json({
            error: `WhatsApp session '${sessionName}' is not connected.`,
        });
    }

    try {
        const digits = (chatId || '').replace(/\D+/g, '');
        const jid = digits ? `${digits}@s.whatsapp.net` : chatId;

        await s.sock.sendMessage(jid, {
            delete: {
                remoteJid: jid,
                fromMe: fromMe !== false,
                id: messageId,
            },
        });

        console.log(`[WAHA] Deleted message ${messageId} in ${jid}`);
        res.json({ success: true, messageId });
    } catch (err) {
        console.error(`[WAHA] Error deleting message ${messageId}:`, err);
        res.status(500).json({ error: 'Failed to delete WhatsApp message: ' + err.message });
    }
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'UP',
        engine: 'BAILEYS_EMBEDDED',
        activeSessions: activeSessions.size,
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`[Farfasha WAHA Embedded Server] Listening on http://0.0.0.0:${PORT}`);
    console.log(`[Farfasha WAHA Embedded Server] Webhook target: ${WEBHOOK_URL}`);

    // Auto-start all saved sessions if existing auth credentials exist
    try {
        const dirs = fs.readdirSync(SESSIONS_DIR);
        for (const dir of dirs) {
            const dirPath = path.join(SESSIONS_DIR, dir);
            if (fs.statSync(dirPath).isDirectory()) {
                const credsFile = path.join(dirPath, 'creds.json');
                if (fs.existsSync(credsFile)) {
                    console.log(`[Farfasha WAHA] Restoring saved session: ${dir}`);
                    startSession(dir).catch(err => {
                        console.error(`[Farfasha WAHA] Failed to restore session ${dir}:`, err.message);
                    });
                }
            }
        }
    } catch (err) {
        console.error('[Farfasha WAHA] Error reading sessions directory:', err.message);
    }
});
