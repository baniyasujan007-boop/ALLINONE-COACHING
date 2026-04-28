const mongoose = require('mongoose');

const referralEventSchema = new mongoose.Schema(
  {
    referralCode: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },
    referrerUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    referredUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    courseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Course',
      required: true,
    },
    courseTitle: {
      type: String,
      default: '',
      trim: true,
    },
    billingCycle: {
      type: String,
      default: '',
      trim: true,
    },
    originalAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    finalAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    refereeDiscountAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    referrerRewardAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    purchaseIpHash: {
      type: String,
      default: '',
      trim: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['completed', 'rejected'],
      default: 'completed',
    },
    rejectionReason: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('ReferralEvent', referralEventSchema);
