const jwt = require('jsonwebtoken');
const config = require('../config/env');
const Device = require('../models/Device');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, config.jwtSecret);

      req.user = decoded;

      // Validate device authorization if deviceId is present
      const deviceId = req.headers['x-device-id'] || req.query.deviceId || req.body.deviceId || decoded.deviceId;
      if (deviceId) {
        const device = await Device.findOne({ deviceId });
        if (device && device.status === 'blocked') {
          return res.status(403).json({
            success: false,
            message: 'Device is blocked',
            errorCode: 'DEVICE_BLOCKED',
          });
        }
        req.device = device;
      }

      return next();
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized, token failed',
        errorCode: 'INVALID_TOKEN',
      });
    }
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized, no token provided',
      errorCode: 'NO_TOKEN',
    });
  }
};

module.exports = { protect };
