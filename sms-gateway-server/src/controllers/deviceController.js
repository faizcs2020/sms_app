const deviceService = require('../services/deviceService');
const Device = require('../models/Device');

/**
 * Updates device heartbeat status
 * POST /api/devices/heartbeat
 * Body: { deviceId, appVersion, androidVersion, batteryLevel, networkType }
 */
const heartbeat = async (req, res, next) => {
  try {
    const { deviceId, appVersion, androidVersion, batteryLevel, networkType, deviceName } = req.body;

    if (!deviceId) {
      return res.status(400).json({
        success: false,
        message: 'deviceId is required',
        errorCode: 'VALIDATION_ERROR',
      });
    }

    const device = await deviceService.updateHeartbeat({
      deviceId,
      appVersion,
      androidVersion,
      batteryLevel,
      networkType,
      deviceName,
    });

    return res.status(200).json({
      success: true,
      message: 'Heartbeat recorded successfully',
      data: {
        deviceId: device.deviceId,
        status: device.status,
        lastSeenAt: device.lastSeenAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Gets list of registered gateway devices
 * GET /api/devices
 */
const getDevices = async (req, res, next) => {
  try {
    const devices = await deviceService.getDevices();
    return res.status(200).json({
      success: true,
      data: devices,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Registers or updates a device record
 * POST /api/devices
 */
const registerDevice = async (req, res, next) => {
  try {
    const { deviceId, deviceName, appVersion, androidVersion, batteryLevel, networkType } = req.body;

    if (!deviceId) {
      return res.status(400).json({
        success: false,
        message: 'deviceId is required',
        errorCode: 'VALIDATION_ERROR',
      });
    }

    const device = await deviceService.updateHeartbeat({
      deviceId,
      deviceName,
      appVersion,
      androidVersion,
      batteryLevel,
      networkType,
    });

    return res.status(201).json({
      success: true,
      message: 'Device registered successfully',
      data: device,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  heartbeat,
  getDevices,
  registerDevice,
};
