const smsQueueService = require('../services/smsQueueService');
const SmsQueue = require('../models/SmsQueue');

/**
 * Queues a new outgoing SMS
 * POST /api/sms_queue
 * Body: { deviceId, mobile, message, priority, simSlot }
 */
const createQueueItem = async (req, res, next) => {
  try {
    const { deviceId, mobile, message, priority, simSlot } = req.body;

    if (!deviceId || !mobile || !message) {
      return res.status(400).json({
        success: false,
        message: 'deviceId, mobile, and message are required',
        errorCode: 'VALIDATION_ERROR',
      });
    }

    const sms = await smsQueueService.createOutgoingSms({
      deviceId,
      mobile,
      message,
      priority,
      simSlot,
    });

    return res.status(201).json({
      success: true,
      message: 'SMS queued successfully',
      data: {
        id: sms._id.toString(),
        deviceId: sms.deviceId,
        mobile: sms.mobile,
        message: sms.message,
        status: sms.status,
        createdAt: sms.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Atomically retrieves and claims pending SMS queue items for a device
 * GET /api/sms_queue?deviceId=DEVICE-001&limit=10
 */
const getPendingQueue = async (req, res, next) => {
  try {
    // Identify deviceId from query parameter or authenticated JWT device context
    const deviceId = req.query.deviceId || (req.user && req.user.deviceId);
    const limit = req.query.limit ? parseInt(req.query.limit, 10) : undefined;

    if (!deviceId) {
      return res.status(400).json({
        success: false,
        message: 'deviceId query parameter is required',
        errorCode: 'VALIDATION_ERROR',
      });
    }

    // Atomic claim pending messages
    const items = await smsQueueService.claimPendingSms(deviceId, limit);

    return res.status(200).json({
      success: true,
      data: items,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Marks an SMS as sent by device
 * POST /api/sms_queue/:id/sent
 * Body: { deviceId, sentAt }
 */
const markSent = async (req, res, next) => {
  try {
    const smsId = req.params.id;
    const { deviceId, sentAt } = req.body;

    const targetDeviceId = deviceId || (req.user && req.user.deviceId);

    if (!targetDeviceId) {
      return res.status(400).json({
        success: false,
        message: 'deviceId is required',
        errorCode: 'VALIDATION_ERROR',
      });
    }

    const updatedSms = await smsQueueService.markSmsSent(smsId, targetDeviceId, sentAt);

    return res.status(200).json({
      success: true,
      message: 'SMS marked as sent',
      data: {
        id: updatedSms._id.toString(),
        status: updatedSms.status,
        sentAt: updatedSms.sentAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Marks an SMS as failed by device
 * POST /api/sms_queue/:id/failed
 * Body: { deviceId, error, retry }
 */
const markFailed = async (req, res, next) => {
  try {
    const smsId = req.params.id;
    const { deviceId, error, retry = true } = req.body;

    const targetDeviceId = deviceId || (req.user && req.user.deviceId);

    if (!targetDeviceId) {
      return res.status(400).json({
        success: false,
        message: 'deviceId is required',
        errorCode: 'VALIDATION_ERROR',
      });
    }

    const updatedSms = await smsQueueService.markSmsFailed(smsId, targetDeviceId, error, retry);

    return res.status(200).json({
      success: true,
      message: updatedSms.status === 'pending' ? 'SMS returned to pending for retry' : 'SMS marked as failed',
      data: {
        id: updatedSms._id.toString(),
        status: updatedSms.status,
        attempts: updatedSms.attempts,
        maxAttempts: updatedSms.maxAttempts,
        lastError: updatedSms.lastError,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Gets details of a specific queue item
 * GET /api/sms_queue/:id
 */
const getQueueItemById = async (req, res, next) => {
  try {
    const sms = await SmsQueue.findById(req.params.id);

    if (!sms) {
      return res.status(404).json({
        success: false,
        message: 'SMS record not found',
        errorCode: 'NOT_FOUND',
      });
    }

    return res.status(200).json({
      success: true,
      data: sms,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createQueueItem,
  getPendingQueue,
  markSent,
  markFailed,
  getQueueItemById,
};
