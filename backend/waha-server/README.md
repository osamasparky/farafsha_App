# WAHA Embedded Module (خادم واتساب المدمج)

موديول واتساب المدمج داخل نظام فرفشة / لمّة لتشغيل خادم WhatsApp HTTP API المتوافق بالكامل مع مواصفات WAHA دون الحاجة لأي خادم خارجي أو Docker أو اشتراكات مدفوعة.

## التقنيات المستخدمة
- **Node.js (ESM)**
- **@whiskeysockets/baileys** (محرك واتساب متعدد الأجهزة الأصلي)
- **Express + CORS + Pino**
- **qrcode** (توليد الباركود الحي لربط الرقم)

## كيف يتم تشغيله؟
يمكنك تشغيله بإحدى طريقتين:

### الطريقة الأولى (عبر Laravel Artisan):
```bash
php artisan waha:serve
# أو لتحديد بورت مخصص:
php artisan waha:serve --port=3000
```

### الطريقة الثانية (عبر Node/NPM):
```bash
cd backend/waha-server
npm install
node server.js
```
أو من مجلد `backend`:
```bash
npm run waha
```

## التوافق مع لوحة التحكم (Filament Admin):
1. افتح لوحة التحكم: `http://127.0.0.1:8000/admin/waha-sessions`
2. اضغط على زر `بدء الجلسة / مسح QR Code`.
3. امسح الباركود بهاتفك من تطبيق واتساب (الأجهزة المرتبطة).
4. بمجرد المسح تصبح الحالة `🟢 متصل / WORKING` وتُحفظ الجلسة تلقائياً في `storage/app/waha_sessions/default/`.
