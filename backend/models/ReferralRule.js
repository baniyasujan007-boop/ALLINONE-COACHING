const mongoose = require('mongoose');

const referralRuleSchema = new mongoose.Schema(
  {
    key: {
      type: String,
      required: true,
      unique: true,
      default: 'default',
      trim: true,
    },
    enabled: {
      type: Boolean,
      default: true,
    },
    refereeRewardType: {
      type: String,
      enum: ['flat', 'percent'],
      default: 'flat',
    },
    refereeRewardValue: {
      type: Number,
      default: 0,
      min: 0,
    },
    referrerRewardType: {
      type: String,
      enum: ['flat', 'percent'],
      default: 'flat',
    },
    referrerRewardValue: {
      type: Number,
      default: 0,
      min: 0,
    },
    minOrderAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    firstPurchaseOnly: {
      type: Boolean,
      default: true,
    },
    maxSuccessfulReferralsPerUser: {
      type: Number,
      default: 50,
      min: 0,
    },
    maxUsesPerCode: {
      type: Number,
      default: 50,
      min: 0,
    },
    maxRewardsPerIp: {
      type: Number,
      default: 3,
      min: 0,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('ReferralRule', referralRuleSchema);
