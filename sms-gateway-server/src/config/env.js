const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 3000,
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/sms_web',
  jwtSecret: process.env.JWT_SECRET || 'fallback_jwt_secret_change_in_prod',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '1d',
  smsQueueBatchSize: parseInt(process.env.SMS_QUEUE_BATCH_SIZE, 10) || 10,
  smsProcessingTimeoutMinutes: parseInt(process.env.SMS_PROCESSING_TIMEOUT_MINUTES, 10) || 10,
  logLevel: process.env.LOG_LEVEL || 'info',
};

module.exports = config;
