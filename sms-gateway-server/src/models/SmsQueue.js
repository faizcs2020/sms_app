const mongoose = require('mongoose');

const smsQueueSchema = new mongoose.Schema(
  {
    deviceId: {
      type: String,
      required: [true, 'deviceId is required'],
      trim: true,
      index: true,
    },
    mobile: {
      type: String,
      required: [true, 'mobile number is required'],
      trim: true,
    },
    message: {
      type: String,
      required: [true, 'message body is required'],
      maxlength: [1000, 'message text exceeds maximum allowed length of 1000 characters'],
    },
    status: {
      type: String,
      enum: ['pending', 'processing', 'sent', 'failed', 'cancelled'],
      default: 'pending',
      index: true,
    },
    priority: {
      type: Number,
      default: 1,
    },
    attempts: {
      type: Number,
      default: 0,
    },
    maxAttempts: {
      type: Number,
      default: 3,
    },
    simSlot: {
      type: Number,
      default: null,
    },
    sentAt: {
      type: Date,
      default: null,
    },
    processingAt: {
      type: Date,
      default: null,
      index: true,
    },
    lastError: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'sms_queue',
  }
);

smsQueueSchema.index({ createdAt: 1 });
smsQueueSchema.index({ deviceId: 1, status: 1 });

module.exports = mongoose.model('SmsQueue', smsQueueSchema);
