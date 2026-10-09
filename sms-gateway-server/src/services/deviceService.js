const Device = require('../models/Device');

/**
 * Updates device heartbeat or registers new device if missing
 */
const updateHeartbeat = async ({ deviceId, appVersion, androidVersion, batteryLevel, networkType, deviceName }) => {
  if (!deviceId) {
    const err = new Error('deviceId is required');
    err.errorCode = 'VALIDATION_ERROR';
    throw err;
  }

  let device = await Device.findOne({ deviceId });

  if (device) {
    if (device.status === 'blocked') {
      const err = new Error('Device has been blocked');
      err.errorCode = 'DEVICE_BLOCKED';
      throw err;
    }

    device.lastSeenAt = new Date();
    if (appVersion) device.appVersion = appVersion;
    if (androidVersion) device.androidVersion = androidVersion;
    if (batteryLevel !== undefined) device.batteryLevel = batteryLevel;
    if (networkType) device.networkType = networkType;
    if (deviceName) device.deviceName = deviceName;

    await device.save();
  } else {
    device = await Device.create({
      deviceId,
      deviceName: deviceName || `Device-${deviceId}`,
      appVersion: appVersion || '1.0.0',
      androidVersion: androidVersion || '14',
      batteryLevel: batteryLevel !== undefined ? batteryLevel : 100,
      networkType: networkType || 'wifi',
      status: 'active',
      lastSeenAt: new Date(),
    });
  }

  return device;
};

const getDevices = async () => {
  return await Device.find({}).sort({ lastSeenAt: -1 });
};

const getDeviceById = async (deviceId) => {
  return await Device.findOne({ deviceId });
};

module.exports = {
  updateHeartbeat,
  getDevices,
  getDeviceById,
};
