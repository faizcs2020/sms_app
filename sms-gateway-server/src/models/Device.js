const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema(
  {
    deviceId: {
      type: String,
      required: [true, 'deviceId is required'],
      unique: true,
      trim: true,
      index: true,
    },
    deviceName: {
      type: String,
      default: 'Android Device',
    },
    status: {
      type: String,
      enum: ['active', 'inactive', 'blocked'],
      default: 'active',
      index: true,
    },
    appVersion: {
      type: String,
      default: '1.0.0',
    },
    androidVersion: {
      type: String,
      default: '14',
    },
    batteryLevel: {
      type: Number,
      default: 100,
    },
    networkType: {
      type: String,
      default: 'wifi',
    },
    lastSeenAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Device', deviceSchema);
