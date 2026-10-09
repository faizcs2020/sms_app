# SMS Gateway Flutter Android Application

Material 3 Android mobile application for bridging phone SIM SMS capabilities with Express.js + MongoDB backend.

## Features
- **Material 3 Dashboard**: Displays connection status, permission status, service state, pending queue count, and SIM info.
- **Android Background Execution**: Runs persistent background service with notification.
- **Configurable Polling Interval**: Support for 15s, 30s, 60s, 5m polling intervals.
- **Offline Sync Queue**: Temporarily queues received incoming SMS locally when offline and uploads upon network restoration.
- **Sequential Queue Lock**: Sequential queue execution preventing double sending.

## Build Commands
```bash
flutter pub get
flutter test
flutter build apk --release
```
