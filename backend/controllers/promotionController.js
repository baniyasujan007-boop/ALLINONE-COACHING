const Coupon = require('../models/Coupon');
const ReferralEvent = require('../models/ReferralEvent');
const ReferralRule = require('../models/ReferralRule');
const Course = require('../models/Course');
const {
  buildCheckoutPreview,
  getReferralSettings,
} = require('../services/promotionService');

const mapCoupon = (coupon) => ({
  id: coupon._id,
  code: coupon.code,
  type: coupon.type,
  value: coupon.value,
  expiresAt: coupon.expiresAt,
  maxRedemptions: coupon.maxRedemptions || 0,
  perUserLimit: coupon.perUserLimit || 0,
  minOrderAmount: coupon.minOrderAmount || 0,
  usageCount: coupon.usageCount || 0,
  isActive: coupon.isActive !== false,
  createdAt: coupon.createdAt,
  updatedAt: coupon.updatedAt,
});

const mapReferralSettings = (settings) => ({
  id: settings._id,
  enabled: settings.enabled !== false,
  refereeRewardType: settings.refereeRewardType || 'flat',
  refereeRewardValue: settings.refereeRewardValue || 0,
  referrerRewardType: settings.referrerRewardType || 'flat',
  referrerRewardValue: settings.referrerRewardValue || 0,
  minOrderAmount: settings.minOrderAmount || 0,
  firstPurchaseOnly: settings.firstPurchaseOnly !== false,
  maxSuccessfulReferralsPerUser: settings.maxSuccessfulReferralsPerUser || 0,
  maxUsesPerCode: settings.maxUsesPerCode || 0,
  maxRewardsPerIp: settings.maxRewardsPerIp || 0,
  updatedAt: settings.updatedAt,
});

const mapReferralEvent = (event) => ({
  id: event._id,
  referralCode: event.referralCode,
  courseTitle: event.courseTitle || '',
  billingCycle: event.billingCycle || '',
  originalAmount: event.originalAmount || 0,
  finalAmount: event.finalAmount || 0,
  refereeDiscountAmount: event.refereeDiscountAmount || 0,
  referrerRewardAmount: event.referrerRewardAmount || 0,
  status: event.status || 'completed',
  rejectionReason: event.rejectionReason || '',
  createdAt: event.createdAt,
  referrer: event.referrerUserId
    ? {
        id: event.referrerUserId._id || event.referrerUserId,
        name: event.referrerUserId.name || '',
        email: event.referrerUserId.email || '',
      }
    : null,
  referredUser: event.referredUserId
    ? {
        id: event.referredUserId._id || event.referredUserId,
        name: event.referredUserId.name || '',
        email: event.referredUserId.email || '',
      }
    : null,
});

exports.previewCheckout = async (req, res, next) => {
  try {
    const { courseId, billingCycle, couponCode, referralCode } = req.body;
    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }

    const preview = await buildCheckoutPreview({
      course,
      billingCycle,
      couponCode,
      referralCode,
      user: req.user,
      req,
    });

    return res.json({
      originalAmount: preview.originalAmount,
      finalAmount: preview.finalAmount,
      couponCode: preview.couponCode,
      couponDiscount: preview.couponDiscount,
      referralCode: preview.referralCode,
      referralDiscount: preview.referralDiscount,
      referrerRewardAmount: preview.referrerRewardAmount,
      messages: preview.messages,
      referralOwnerName: preview.referralMeta?.referrerName || '',
    });
  } catch (error) {
    return next(error);
  }
};

exports.getPromotionAdminOverview = async (req, res, next) => {
  try {
    const [coupons, settings, events] = await Promise.all([
      Coupon.find().sort({ createdAt: -1 }),
      getReferralSettings(),
      ReferralEvent.find()
        .populate('referrerUserId', 'name email')
        .populate('referredUserId', 'name email')
        .sort({ createdAt: -1 })
        .limit(100),
    ]);

    return res.json({
      coupons: coupons.map(mapCoupon),
      referralSettings: mapReferralSettings(settings),
      referralEvents: events.map(mapReferralEvent),
    });
  } catch (error) {
    return next(error);
  }
};

exports.createCoupon = async (req, res, next) => {
  try {
    const coupon = await Coupon.create({
      code: req.body.code,
      type: req.body.type,
      value: req.body.value,
      expiresAt: req.body.expiresAt || null,
      maxRedemptions: req.body.maxRedemptions || 0,
      perUserLimit: req.body.perUserLimit ?? 1,
      minOrderAmount: req.body.minOrderAmount || 0,
      isActive: req.body.isActive !== false,
    });
    return res.status(201).json(mapCoupon(coupon));
  } catch (error) {
    return next(error);
  }
};

exports.updateCoupon = async (req, res, next) => {
  try {
    const coupon = await Coupon.findById(req.params.id);
    if (!coupon) {
      return res.status(404).json({ message: 'Coupon not found' });
    }

    const fields = [
      'code',
      'type',
      'value',
      'expiresAt',
      'maxRedemptions',
      'perUserLimit',
      'minOrderAmount',
      'isActive',
    ];
    for (const field of fields) {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        coupon[field] = req.body[field];
      }
    }

    await coupon.save();
    return res.json(mapCoupon(coupon));
  } catch (error) {
    return next(error);
  }
};

exports.deleteCoupon = async (req, res, next) => {
  try {
    const coupon = await Coupon.findById(req.params.id);
    if (!coupon) {
      return res.status(404).json({ message: 'Coupon not found' });
    }
    await coupon.deleteOne();
    return res.json({ message: 'Coupon deleted successfully' });
  } catch (error) {
    return next(error);
  }
};

exports.getReferralSettings = async (req, res, next) => {
  try {
    const settings = await getReferralSettings();
    return res.json(mapReferralSettings(settings));
  } catch (error) {
    return next(error);
  }
};

exports.updateReferralSettings = async (req, res, next) => {
  try {
    let settings = await ReferralRule.findOne({ key: 'default' });
    if (!settings) {
      settings = await ReferralRule.create({ key: 'default' });
    }

    const fields = [
      'enabled',
      'refereeRewardType',
      'refereeRewardValue',
      'referrerRewardType',
      'referrerRewardValue',
      'minOrderAmount',
      'firstPurchaseOnly',
      'maxSuccessfulReferralsPerUser',
      'maxUsesPerCode',
      'maxRewardsPerIp',
    ];
    for (const field of fields) {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        settings[field] = req.body[field];
      }
    }

    await settings.save();
    return res.json(mapReferralSettings(settings));
  } catch (error) {
    return next(error);
  }
};
