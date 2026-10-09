const mongoose = require('mongoose');

const smsMobileSchema = new mongoose.Schema(
  {
    deviceId: {
      type: String,
      required: [true, 'deviceId is required'],
      trim: true,
      index: true,
    },
    sender: {
      type: String,
      required: [true, 'sender mobile number is required'],
      trim: true,
      index: true,
    },
    message: {
      type: String,
      required: [true, 'message content is required'],
    },
    receivedAt: {
      type: Date,
      required: [true, 'receivedAt timestamp is required'],
      index: true,
    },
    simSlot: {
      type: Number,
      default: 1,
    },
    smsId: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'sms_mobile',
  }
);

// Indexing strategies
smsMobileSchema.index({ createdAt: 1 });
// Compound index to prevent duplicate mobile SMS uploads
smsMobileSchema.index({ deviceId: 1, sender: 1, message: 1, receivedAt: 1 }, { unique: true });

module.exports = mongoose.model('SmsMobile', smsMobileSchema);
