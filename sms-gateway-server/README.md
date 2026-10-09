# Express.js + MongoDB SMS Gateway Backend

Express.js REST API server connected to MongoDB (`sms_web`).

## Features
- **Atomic Queue Claiming**: Atomically transitions queue items `pending` -> `processing` using MongoDB `findOneAndUpdate`.
- **Duplicate Prevention**: Compound unique indexing on incoming mobile SMS.
- **Crash Recovery**: Resets stale `processing` messages back to `pending` after timeout.
- **Security**: JWT Authentication, Helmet headers, CORS, express-rate-limit, structured Morgan logging.

## Setup & Running
```bash
npm install
npm run dev
npm test
```
