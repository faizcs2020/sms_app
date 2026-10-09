const jwt = require('jsonwebtoken');
const config = require('../config/env');
const User = require('../models/User');
const Device = require('../models/Device');

/**
 * Handles device/user login
 * POST /api/auth/login
 * Body: { deviceId, username, password }
 */
const login = async (req, res, next) => {
  try {
    const { deviceId, username, password } = req.body;

    if (!deviceId || !username || !password) {
      return res.status(400).json({
        success: false,
        message: 'deviceId, username, and password are required',
        errorCode: 'VALIDATION_ERROR',
      });
    }

    let user = await User.findOne({ username: username.toLowerCase() });

    // Seed default gateway user on first run if database is fresh
    if (!user) {
      user = await User.create({
        username: username.toLowerCase(),
        password: password,
        role: 'device',
      });
      console.log(`[Auth] Created initial device user '${username}'`);
    } else {
      const isMatch = await user.matchPassword(password);
      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials',
          errorCode: 'INVALID_CREDENTIALS',
        });
      }
    }

    // Register or update device
    let device = await Device.findOne({ deviceId });
    if (device) {
      if (device.status === 'blocked') {
        return res.status(403).json({
          success: false,
          message: 'Device has been blocked by administrator',
          errorCode: 'DEVICE_BLOCKED',
        });
      }
      device.lastSeenAt = new Date();
      await device.save();
    } else {
      device = await Device.create({
        deviceId,
        deviceName: `Device-${deviceId}`,
        status: 'active',
        lastSeenAt: new Date(),
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        id: user._id,
        username: user.username,
        deviceId: device.deviceId,
        role: user.role,
      },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn }
    );

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      token,
      expiresIn: 86400, // 24 hours in seconds
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  login,
};
