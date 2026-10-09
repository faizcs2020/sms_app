const SmsMobile = require('../models/SmsMobile');
const deviceService = require('../services/deviceService');

/**
 * Handles incoming mobile SMS from Flutter Android device
 * POST /api/sms/mobile
 * Body: { deviceId, sender, message, receivedAt, simSlot, smsId }
 */
const receiveMobileSms = async (req, res, next) => {
  try {
    const { deviceId, sender, message, receivedAt, simSlot, smsId } = req.body;

    if (!deviceId || !sender || !message) {
      return res.status(400).json({
        success: false,
        message: 'deviceId, sender, and message are required',
        errorCode: 'VALIDATION_ERROR',
      });
    }

    const timestamp = receivedAt ? new Date(receivedAt) : new Date();

    try {
      const sms = await SmsMobile.create({
        deviceId,
        sender,
        message,
        receivedAt: timestamp,
        simSlot: simSlot || 1,
        smsId: smsId || null,
      });

      // Update device heartbeat in background
      deviceService.updateHeartbeat({ deviceId }).catch(() => {});

      return res.status(201).json({
        success: true,
        message: 'Incoming SMS saved successfully',
        data: {
          id: sms._id.toString(),
          deviceId: sms.deviceId,
          sender: sms.sender,
          receivedAt: sms.receivedAt,
          createdAt: sms.createdAt,
        },
      });
    } catch (dbErr) {
      // Duplicate key error handler (code 11000)
      if (dbErr.code === 11000) {
        return res.status(200).json({
          success: true,
          message: 'SMS already stored (duplicate ignored)',
          data: {
            duplicate: true,
          },
        });
      }
      throw dbErr;
    }
  } catch (error) {
    next(error);
  }
};

/**
 * Gets list of received mobile SMS records
 * GET /api/sms/mobile
 */
const getMobileSmsList = async (req, res, next) => {
  try {
    const { deviceId, limit = 50, page = 1 } = req.query;
    const filter = {};
    if (deviceId) filter.deviceId = deviceId;

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const smsList = await SmsMobile.find(filter)
      .sort({ receivedAt: -1 })
      .limit(parseInt(limit, 10))
      .skip(skip);

    const total = await SmsMobile.countDocuments(filter);

    return res.status(200).json({
      success: true,
      message: 'Mobile SMS list retrieved',
      data: smsList,
      meta: {
        total,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  receiveMobileSms,
  getMobileSmsList,
};
