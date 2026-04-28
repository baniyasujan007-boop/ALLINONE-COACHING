const mongoose = require('mongoose');

const couponRedemptionSchema = new mongoose.Schema(
  {
    couponId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Coupon',
      required: true,
      index: true,
    },
    couponCode: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },
    userId: {
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
    discountAmount: {
      type: Number,
      default: 0,
      min: 0,
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
    status: {
      type: String,
      enum: ['success'],
      default: 'success',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('CouponRedemption', couponRedemptionSchema);
