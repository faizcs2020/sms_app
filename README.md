# SMS Gateway - Express.js + MongoDB Backend & Flutter Android App

A production-ready Android SMS Gateway system bridging physical Android mobile devices with an Express.js & MongoDB backend server.

---

## 🏗️ System Architecture

```
 ┌───────────────────────────┐
 │   External Web / Client   │
 └─────────────┬─────────────┘
               │
               │ POST /api/sms_queue
               ▼
 ┌───────────────────────────┐
 │   Express.js REST API     │
 │  - JWT Authentication     │
 │  - Atomic Queue Claiming  │
 │  - Centralized Errors     │
 └─────────────┬─────────────┘
               │
               ▼
 ┌───────────────────────────┐
 │     MongoDB Atlas         │
 │     Database: sms_web     │
 │  - Collections:           │
 │    sms_queue, sms_mobile  │
 │    users, devices         │
 └─────────────▲─────────────┘
               │
          REST API / HTTPS
               │
 ┌─────────────┴─────────────┐
 │    Flutter Android App    │
 │  - SMS Send Service       │
 │  - SMS Receive Listener   │
 │  - Background Execution   │
 └─────────────┬─────────────┘
               │
 ┌─────────────┴─────────────┐
 │   Android Physical Device │
 │  - SIM 1 / SIM 2 Slots    │
 └───────────────────────────┘
```

---

## 📦 Project Structure

- `sms-gateway-server/`: Node.js / Express backend API connected to MongoDB (`sms_web`).
- `sms_gateway_app/`: Material 3 Flutter Android client application (`SMS Gateway`).
- `SMS Gateway API.postman_collection.json`: Pre-configured Postman API testing collection.

---

## 🚀 Express.js Backend Setup

### 1. Prerequisites & Installation
- **Node.js**: v18+
- **MongoDB Atlas Connection URI**: Configured in `.env`

```bash
cd sms-gateway-server
npm install
```

### 2. Environment Configuration (`.env`)

Create or update `.env` inside `sms-gateway-server/`:

```env
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb+srv://tripinbdcom_db_user:NQHXvdYAWzgiXyH9@cluster0.ayukwby.mongodb.net/sms_web?retryWrites=true&w=majority
JWT_SECRET=super_secret_jwt_key_smsgateway_2026_prod
JWT_EXPIRES_IN=1d
SMS_QUEUE_BATCH_SIZE=10
SMS_PROCESSING_TIMEOUT_MINUTES=10
LOG_LEVEL=info
```

### 3. Running Backend Server & Tests

```bash
# Run in development mode
npm run dev

# Run automated Jest test suite
npm test
```

---

## 📱 Flutter Android App Setup

### 1. Installation

```bash
cd sms_gateway_app
flutter pub get
```

### 2. Android Configuration & Package Name

- **Application Name**: `SMS Gateway`
- **Package Name**: `com.example.smsgateway` (configured in `android/app/build.gradle.kts` & `lib/config/app_config.dart`)

### 3. Running the App

```bash
# Run in debug mode on connected Android device/emulator
flutter run

# Build Release APK
flutter build apk --release

# Build App Bundle (AAB) for Google Play
flutter build appbundle --release
```

The compiled APK will be located at:
`sms_gateway_app/build/app/outputs/flutter-apk/app-release.apk`

---

## 🔐 Android Permissions & Background Processing

### Required Permissions
The app requests the following Android permissions:
- `READ_SMS` & `RECEIVE_SMS`: To read and listen for incoming SMS messages.
- `SEND_SMS`: To send outgoing SMS via Android device SIM cards.
- `READ_PHONE_STATE`: To detect dual-SIM slot states (SIM 1 / SIM 2).
- `FOREGROUND_SERVICE` & `RECEIVE_BOOT_COMPLETED`: Keeps background polling active after device reboots and prevents OS kill.

### Battery Optimization
For production deployment, users should disable battery optimization for `SMS Gateway` in Android settings (**Settings > Apps > SMS Gateway > Battery > Unrestricted**) to prevent Android Doze mode from killing queue polling.

---

## 🛡️ Atomic Queue Claiming & Duplicate SMS Prevention

### Outgoing Queue Claiming (Atomic `pending` -> `processing`)
To prevent two devices or polling cycles from sending the same SMS twice, the backend uses MongoDB's atomic `findOneAndUpdate` operation:
1. `GET /api/sms_queue?deviceId=DEVICE-001` atomically transitions records from `status: "pending"` to `status: "processing"` and sets `processingAt: new Date()`.
2. The Android client receives the claimed item, sends it via SIM, and calls `POST /api/sms_queue/:id/sent` (transitioning `processing` -> `sent`).
3. If an Android app crashes while processing, a background timer resets stale items back to `pending` after 10 minutes (`SMS_PROCESSING_TIMEOUT_MINUTES`).

### Incoming SMS Duplicate Prevention
Incoming mobile SMS uploads (`POST /api/sms/mobile`) use a unique compound database index on `{ deviceId: 1, sender: 1, message: 1, receivedAt: 1 }`. Duplicate uploads are automatically caught and ignored safely.

---

## 🧪 Postman API Testing

Import `SMS Gateway API.postman_collection.json` into Postman.

Set collection variables:
- `baseUrl`: `http://localhost:3000`
- `username`: `gateway001`
- `password`: `password123`
- `deviceId`: `DEVICE-001`

Execute requests in the following order:
1. **Login Device / User**: `POST /api/auth/login` (copies `token` to collection variable).
2. **Health Check**: `GET /api/health`
3. **Queue Outgoing SMS**: `POST /api/sms_queue`
4. **Get / Claim Pending Queue**: `GET /api/sms_queue?deviceId=DEVICE-001`
5. **Mark SMS Sent**: `POST /api/sms_queue/:id/sent`
6. **Receive Mobile SMS**: `POST /api/sms/mobile`
