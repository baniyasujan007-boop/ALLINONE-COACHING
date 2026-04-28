const crypto = require('crypto');
const Coupon = require('../models/Coupon');
const CouponRedemption = require('../models/CouponRedemption');
const ReferralEvent = require('../models/ReferralEvent');
const ReferralRule = require('../models/ReferralRule');
const User = require('../models/User');

const rewardTypes = ['flat', 'percent'];

const normalizeCode = (value) =>
  typeof value === 'string' ? value.trim().toUpperCase() : '';

const clampCurrency = (value) => Number(Math.max(0, Number(value || 0)).toFixed(2));

const normalizePricing = (pricing = {}, fallbackPrice = 0) => {
  const safe = {
    monthly: Number(pricing.monthly || 0),
    quarterly: Number(pricing.quarterly || 0),
    semiAnnual: Number(pricing.semiAnnual || 0),
    yearly: Number(pricing.yearly || 0),
  };
  const basePrice = Number(fallbackPrice || 0);
  if (
    safe.monthly <= 0 &&
    safe.quarterly <= 0 &&
    safe.semiAnnual <= 0 &&
    safe.yearly <= 0 &&
    basePrice > 0
  ) {
    safe.monthly = basePrice;
    safe.quarterly = Number((basePrice * 2.7).toFixed(2));
    safe.semiAnnual = Number((basePrice * 5).toFixed(2));
    safe.yearly = Number((basePrice * 9).toFixed(2));
  }
  return safe;
};

const offerIsActive = (offer) => {
  if (!offer?.expiresAt) {
    return false;
  }
  const expiresAt = new Date(offer.expiresAt);
  if (Number.isNaN(expiresAt.getTime()) || expiresAt <= new Date()) {
    return false;
  }
  return Object.values(offer.pricing || {}).some((value) => Number(value) > 0);
};

const activePricingForCourse = (course) => {
  const basePricing = normalizePricing(course.pricing, course.price);
  if (!offerIsActive(course.offer)) {
    return basePricing;
  }
  return {
    monthly: Number(course.offer.pricing?.monthly || 0) || basePricing.monthly,
    quarterly:
      Number(course.offer.pricing?.quarterly || 0) || basePricing.quarterly,
    semiAnnual:
      Number(course.offer.pricing?.semiAnnual || 0) || basePricing.semiAnnual,
    yearly: Number(course.offer.pricing?.yearly || 0) || basePricing.yearly,
  };
};

const priceForBillingCycle = (course, billingCycle) => {
  const pricing = activePricingForCourse(course);
  const value = Number(pricing[billingCycle] || 0);
  if (value > 0) {
    return value;
  }
  const values = Object.values(pricing)
    .map((entry) => Number(entry || 0))
    .filter((entry) => entry > 0);
  if (values.length > 0) {
    return Math.min(...values);
  }
  return Number(course.price || 0);
};

const computeRewardAmount = (type, value, amount) => {
  const safeAmount = Number(amount || 0);
  if (!rewardTypes.includes(type) || safeAmount <= 0) {
    return 0;
  }
  const raw =
    type === 'percent'
      ? (safeAmount * Number(value || 0)) / 100
      : Number(value || 0);
  return clampCurrency(Math.min(safeAmount, raw));
};

const getClientIp = (req) => {
  const rawForwarded = req.headers['x-forwarded-for'];
  const forwarded = Array.isArray(rawForwarded)
    ? rawForwarded[0]
    : typeof rawForwarded === 'string'
    ? rawForwarded.split(',')[0]
    : '';
  return String(forwarded || req.ip || '').trim();
};

const hashValue = (value) =>
  value ? crypto.createHash('sha256').update(value).digest('hex') : '';

const buildValidationError = (message) => {
  const error = new Error(message);
  error.status = 400;
  return error;
};

const getReferralSettings = async () => {
  let settings = await ReferralRule.findOne({ key: 'default' });
  if (!settings) {
    settings = await ReferralRule.create({ key: 'default' });
  }
  return settings;
};

const generateCandidateCode = (seed) => {
  const normalizedSeed = String(seed || '')
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '')
    .slice(0, 6);
  const suffix = crypto.randomBytes(2).toString('hex').toUpperCase();
  return `${normalizedSeed || 'LEARN'}${suffix}`.slice(0, 10);
};

const ensureUserReferralCode = async (user) => {
  if (!user) {
    return '';
  }
  const existingCode = normalizeCode(user.referralCode);
  if (existingCode) {
    if (existingCode !== user.referralCode) {
      user.referralCode = existingCode;
      await user.save();
    }
    return existingCode;
  }

  for (let attempt = 0; attempt < 10; attempt += 1) {
    const candidate = generateCandidateCode(user.name || user.email || user._id);
    const duplicate = await User.exists({
      referralCode: candidate,
      _id: { $ne: user._id },
    });
    if (!duplicate) {
      user.referralCode = candidate;
      await user.save();
      return candidate;
    }
  }

  throw new Error('Failed to generate a unique referral code');
};

const buildUserReferralSummary = async (user) => {
  if (!user?._id) {
    return {
      code: '',
      successfulReferrals: 0,
      earnedRewards: 0,
      hasUsedReferral: false,
    };
  }

  const code = await ensureUserReferralCode(user);
  const [events, hasUsedReferral] = await Promise.all([
    ReferralEvent.find({
      referrerUserId: user._id,
      status: 'completed',
    }).select('referrerRewardAmount'),
    ReferralEvent.exists({
      referredUserId: user._id,
      status: 'completed',
    }),
  ]);

  const earnedRewards = clampCurrency(
    events.reduce(
      (total, event) => total + Number(event.referrerRewardAmount || 0),
      0
    )
  );

  return {
    code,
    successfulReferrals: events.length,
    earnedRewards,
    hasUsedReferral: Boolean(hasUsedReferral),
  };
};

const validateCoupon = async ({ userId, courseId, originalAmount, couponCode }) => {
  const normalizedCode = normalizeCode(couponCode);
  if (!normalizedCode) {
    return {
      coupon: null,
      code: '',
      discountAmount: 0,
      message: '',
    };
  }

  const coupon = await Coupon.findOne({ code: normalizedCode });
  if (!coupon || !coupon.isActive) {
    throw buildValidationError('Coupon code is invalid or inactive');
  }
  if (coupon.expiresAt && new Date(coupon.expiresAt) <= new Date()) {
    throw buildValidationError('Coupon code has expired');
  }
  if (coupon.minOrderAmount > 0 && Number(originalAmount) < coupon.minOrderAmount) {
    throw buildValidationError(
      `Coupon requires a minimum order of Rs ${coupon.minOrderAmount.toFixed(0)}`
    );
  }
  if (coupon.maxRedemptions > 0 && coupon.usageCount >= coupon.maxRedemptions) {
    throw buildValidationError('Coupon redemption limit has been reached');
  }

  if (coupon.perUserLimit > 0) {
    const usedCount = await CouponRedemption.countDocuments({
      couponId: coupon._id,
      userId,
      status: 'success',
    });
    if (usedCount >= coupon.perUserLimit) {
      throw buildValidationError('You have already used this coupon the maximum number of times');
    }
  }

  const discountAmount = computeRewardAmount(coupon.type, coupon.value, originalAmount);
  return {
    coupon,
    code: normalizedCode,
    discountAmount,
    message:
      discountAmount > 0
        ? `Coupon applied. You saved Rs ${discountAmount.toFixed(0)}.`
        : '',
  };
};

const validateReferral = async ({
  user,
  course,
  billingCycle,
  subtotalAfterCoupon,
  referralCode,
  purchaseIpHash,
}) => {
  const normalizedCode = normalizeCode(referralCode);
  if (!normalizedCode) {
    return {
      referralCode: '',
      referrerUser: null,
      refereeDiscountAmount: 0,
      referrerRewardAmount: 0,
      message: '',
    };
  }

  const settings = await getReferralSettings();
  if (!settings.enabled) {
    throw buildValidationError('Referral rewards are currently disabled');
  }

  if (
    settings.minOrderAmount > 0 &&
    Number(subtotalAfterCoupon) < settings.minOrderAmount
  ) {
    throw buildValidationError(
      `Referral rewards require a minimum order of Rs ${settings.minOrderAmount.toFixed(0)}`
    );
  }

  const referrerUser = await User.findOne({ referralCode: normalizedCode });
  if (!referrerUser) {
    throw buildValidationError('Referral code was not found');
  }

  if (String(referrerUser._id) === String(user._id)) {
    throw buildValidationError('You cannot use your own referral code');
  }

  if (
    typeof referrerUser.email === 'string' &&
    typeof user.email === 'string' &&
    referrerUser.email.toLowerCase() === user.email.toLowerCase()
  ) {
    throw buildValidationError('Referral code cannot be used on the same account');
  }

  if (settings.firstPurchaseOnly) {
    const hasPaidBefore = Array.isArray(user.paymentHistory)
      ? user.paymentHistory.some(
          (payment) =>
            payment &&
            payment.status !== 'failed' &&
            Number(payment.amount || 0) > 0
        )
      : false;
    if (hasPaidBefore || user.firstPaidPurchaseAt) {
      throw buildValidationError('Referral reward is only available on the first paid purchase');
    }
  }

  const existingReferral = await ReferralEvent.exists({
    referredUserId: user._id,
    status: 'completed',
  });
  if (existingReferral) {
    throw buildValidationError('A referral has already been used on this account');
  }

  const [successfulByReferrer, successfulByCode, successfulByIp] = await Promise.all([
    ReferralEvent.countDocuments({
      referrerUserId: referrerUser._id,
      status: 'completed',
    }),
    ReferralEvent.countDocuments({
      referralCode: normalizedCode,
      status: 'completed',
    }),
    purchaseIpHash
      ? ReferralEvent.countDocuments({
          purchaseIpHash,
          referralCode: normalizedCode,
          status: 'completed',
        })
      : 0,
  ]);

  if (
    settings.maxSuccessfulReferralsPerUser > 0 &&
    successfulByReferrer >= settings.maxSuccessfulReferralsPerUser
  ) {
    throw buildValidationError('This referrer has reached the referral reward limit');
  }
  if (settings.maxUsesPerCode > 0 && successfulByCode >= settings.maxUsesPerCode) {
    throw buildValidationError('This referral code has reached its usage limit');
  }
  if (settings.maxRewardsPerIp > 0 && successfulByIp >= settings.maxRewardsPerIp) {
    throw buildValidationError('Referral usage from this network has reached the safety limit');
  }

  const refereeDiscountAmount = computeRewardAmount(
    settings.refereeRewardType,
    settings.refereeRewardValue,
    subtotalAfterCoupon
  );
  const referrerRewardAmount = computeRewardAmount(
    settings.referrerRewardType,
    settings.referrerRewardValue,
    subtotalAfterCoupon
  );

  return {
    settings,
    referralCode: normalizedCode,
    referrerUser,
    billingCycle,
    courseId: course._id,
    courseTitle: course.title || '',
    refereeDiscountAmount,
    referrerRewardAmount,
    message:
      refereeDiscountAmount > 0
        ? `Referral applied. You saved Rs ${refereeDiscountAmount.toFixed(0)}.`
        : 'Referral linked successfully.',
  };
};

const buildCheckoutPreview = async ({
  course,
  billingCycle,
  couponCode,
  referralCode,
  user,
  req,
}) => {
  const originalAmount = clampCurrency(priceForBillingCycle(course, billingCycle));
  const purchaseIpHash = hashValue(getClientIp(req));
  const couponResult = await validateCoupon({
    userId: user._id,
    courseId: course._id,
    originalAmount,
    couponCode,
  });
  const subtotalAfterCoupon = clampCurrency(originalAmount - couponResult.discountAmount);
  const referralResult = await validateReferral({
    user,
    course,
    billingCycle,
    subtotalAfterCoupon,
    referralCode,
    purchaseIpHash,
  });
  const finalAmount = clampCurrency(
    subtotalAfterCoupon - referralResult.refereeDiscountAmount
  );

  return {
    originalAmount,
    finalAmount,
    couponCode: couponResult.code,
    couponDiscount: couponResult.discountAmount,
    referralCode: referralResult.referralCode,
    referralDiscount: referralResult.refereeDiscountAmount,
    referrerRewardAmount: referralResult.referrerRewardAmount,
    couponMeta: couponResult.coupon
      ? {
          id: couponResult.coupon._id,
          code: couponResult.coupon.code,
          type: couponResult.coupon.type,
          value: couponResult.coupon.value,
        }
      : null,
    referralMeta: referralResult.referrerUser
      ? {
          referrerUserId: referralResult.referrerUser._id,
          referrerName: referralResult.referrerUser.name || '',
        }
      : null,
    purchaseIpHash,
    messages: [couponResult.message, referralResult.message].filter(Boolean),
  };
};

const recordSuccessfulPromotionUsage = async ({
  user,
  course,
  billingCycle,
  preview,
}) => {
  const tasks = [];

  if (preview.couponMeta?.id && preview.couponDiscount > 0) {
    tasks.push(
      Coupon.findByIdAndUpdate(preview.couponMeta.id, {
        $inc: { usageCount: 1 },
      })
    );
    tasks.push(
      CouponRedemption.create({
        couponId: preview.couponMeta.id,
        couponCode: preview.couponMeta.code,
        userId: user._id,
        courseId: course._id,
        discountAmount: preview.couponDiscount,
        originalAmount: preview.originalAmount,
        finalAmount: preview.finalAmount,
      })
    );
  }

  if (preview.referralMeta?.referrerUserId && preview.referralCode) {
    tasks.push(
      ReferralEvent.create({
        referralCode: preview.referralCode,
        referrerUserId: preview.referralMeta.referrerUserId,
        referredUserId: user._id,
        courseId: course._id,
        courseTitle: course.title || '',
        billingCycle,
        originalAmount: preview.originalAmount,
        finalAmount: preview.finalAmount,
        refereeDiscountAmount: preview.referralDiscount,
        referrerRewardAmount: preview.referrerRewardAmount,
        purchaseIpHash: preview.purchaseIpHash,
        status: 'completed',
      })
    );
  }

  if (preview.finalAmount > 0 && !user.firstPaidPurchaseAt) {
    user.firstPaidPurchaseAt = new Date();
  }

  await Promise.all(tasks);
};

module.exports = {
  activePricingForCourse,
  buildCheckoutPreview,
  buildUserReferralSummary,
  ensureUserReferralCode,
  getReferralSettings,
  normalizeCode,
  normalizePricing,
  offerIsActive,
  priceForBillingCycle,
  recordSuccessfulPromotionUsage,
};
