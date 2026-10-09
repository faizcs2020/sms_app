const SmsQueue = require('../models/SmsQueue');
const config = require('../config/env');

/**
 * Resets stale SMS processing items back to 'pending' if processingAt exceeds timeout
 */
const resetStaleProcessingItems = async () => {
  const timeoutMs = config.smsProcessingTimeoutMinutes * 60 * 1000;
  const cutoffTime = new Date(Date.now() - timeoutMs);

  const result = await SmsQueue.updateMany(
    {
      status: 'processing',
      processingAt: { $lt: cutoffTime },
    },
    {
      $set: {
        status: 'pending',
        processingAt: null,
        lastError: `Processing timeout (${config.smsProcessingTimeoutMinutes}m) exceeded, reset to pending`,
      },
    }
  );

  if (result.modifiedCount > 0) {
    console.log(`[SmsQueueService] Reset ${result.modifiedCount} stale processing SMS items back to pending`);
  }
};

/**
 * Atomically claims pending SMS for a specific device
 */
const claimPendingSms = async (deviceId, batchSize = config.smsQueueBatchSize) => {
  // Step 1: Clean up any stale processing items
  await resetStaleProcessingItems();

  const claimedList = [];

  for (let i = 0; i < batchSize; i++) {
    // Atomic findOneAndUpdate ensures no double claim across concurrent requests
    const claimedItem = await SmsQueue.findOneAndUpdate(
      {
        deviceId,
        status: 'pending',
      },
      {
        $set: {
          status: 'processing',
          processingAt: new Date(),
        },
      },
      {
        new: true,
        sort: { priority: -1, createdAt: 1 },
      }
    );

    if (!claimedItem) {
      break; // No more pending items for this device
    }

    claimedList.push({
      id: claimedItem._id.toString(),
      deviceId: claimedItem.deviceId,
      mobile: claimedItem.mobile,
      message: claimedItem.message,
      status: claimedItem.status,
      simSlot: claimedItem.simSlot,
    });
  }

  return claimedList;
};

/**
 * Creates a new outgoing SMS queue item
 */
const createOutgoingSms = async ({ deviceId, mobile, message, priority, simSlot }) => {
  if (!deviceId || !mobile || !message) {
    const err = new Error('deviceId, mobile, and message are required');
    err.errorCode = 'VALIDATION_ERROR';
    throw err;
  }

  const sms = await SmsQueue.create({
    deviceId,
    mobile,
    message,
    status: 'pending',
    priority: priority || 1,
    simSlot: simSlot || null,
  });

  return sms;
};

/**
 * Marks SMS queue item as sent
 */
const markSmsSent = async (smsId, deviceId, sentAt) => {
  const sms = await SmsQueue.findById(smsId);

  if (!sms) {
    const err = new Error('SMS record not found');
    err.errorCode = 'NOT_FOUND';
    throw err;
  }

  if (sms.deviceId !== deviceId) {
    const err = new Error('SMS record does not belong to this device');
    err.errorCode = 'FORBIDDEN';
    throw err;
  }

  if (sms.status !== 'processing') {
    const err = new Error(`Cannot mark as sent: current SMS status is '${sms.status}', expected 'processing'`);
    err.errorCode = 'INVALID_STATE';
    throw err;
  }

  sms.status = 'sent';
  sms.sentAt = sentAt ? new Date(sentAt) : new Date();
  sms.updatedAt = new Date();

  await sms.save();
  return sms;
};

/**
 * Marks SMS queue item as failed with attempt counter handling
 */
const markSmsFailed = async (smsId, deviceId, error, retry = true) => {
  const sms = await SmsQueue.findById(smsId);

  if (!sms) {
    const err = new Error('SMS record not found');
    err.errorCode = 'NOT_FOUND';
    throw err;
  }

  if (sms.deviceId !== deviceId) {
    const err = new Error('SMS record does not belong to this device');
    err.errorCode = 'FORBIDDEN';
    throw err;
  }

  sms.attempts += 1;
  sms.lastError = error || 'Failed to send SMS via mobile network';
  sms.processingAt = null;

  if (retry && sms.attempts < sms.maxAttempts) {
    sms.status = 'pending';
  } else {
    sms.status = 'failed';
  }

  sms.updatedAt = new Date();
  await sms.save();
  return sms;
};

module.exports = {
  claimPendingSms,
  createOutgoingSms,
  markSmsSent,
  markSmsFailed,
  resetStaleProcessingItems,
};
