const express = require('express');
const { body, param } = require('express-validator');
const {
  previewCheckout,
  getPromotionAdminOverview,
  createCoupon,
  updateCoupon,
  deleteCoupon,
  getReferralSettings,
  updateReferralSettings,
} = require('../controllers/promotionController');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/validationMiddleware');

const router = express.Router();
const rewardTypes = ['flat', 'percent'];

router.post(
  '/preview',
  protect,
  [
    body('courseId').isMongoId().withMessage('Invalid course id'),
    body('billingCycle')
      .optional()
      .isIn(['', 'monthly', 'quarterly', 'semiAnnual', 'yearly'])
      .withMessage('Invalid billing cycle'),
    body('couponCode').optional().isString(),
    body('referralCode').optional().isString(),
    handleValidation,
  ],
  previewCheckout
);

router.get('/admin', protect, adminOnly, getPromotionAdminOverview);
router.get('/admin/referral-settings', protect, adminOnly, getReferralSettings);
router.put(
  '/admin/referral-settings',
  protect,
  adminOnly,
  [
    body('enabled').optional().isBoolean(),
    body('refereeRewardType').optional().isIn(rewardTypes),
    body('refereeRewardValue').optional().isFloat({ min: 0 }),
    body('referrerRewardType').optional().isIn(rewardTypes),
    body('referrerRewardValue').optional().isFloat({ min: 0 }),
    body('minOrderAmount').optional().isFloat({ min: 0 }),
    body('firstPurchaseOnly').optional().isBoolean(),
    body('maxSuccessfulReferralsPerUser').optional().isInt({ min: 0 }),
    body('maxUsesPerCode').optional().isInt({ min: 0 }),
    body('maxRewardsPerIp').optional().isInt({ min: 0 }),
    handleValidation,
  ],
  updateReferralSettings
);

router.post(
  '/admin/coupons',
  protect,
  adminOnly,
  [
    body('code').trim().notEmpty().withMessage('Coupon code is required'),
    body('type').isIn(rewardTypes).withMessage('Invalid coupon type'),
    body('value').isFloat({ min: 0 }).withMessage('Coupon value must be >= 0'),
    body('expiresAt').optional({ nullable: true }).isISO8601(),
    body('maxRedemptions').optional().isInt({ min: 0 }),
    body('perUserLimit').optional().isInt({ min: 0 }),
    body('minOrderAmount').optional().isFloat({ min: 0 }),
    body('isActive').optional().isBoolean(),
    handleValidation,
  ],
  createCoupon
);
router.put(
  '/admin/coupons/:id',
  protect,
  adminOnly,
  [
    param('id').isMongoId().withMessage('Invalid coupon id'),
    body('code').optional().trim().notEmpty(),
    body('type').optional().isIn(rewardTypes),
    body('value').optional().isFloat({ min: 0 }),
    body('expiresAt').optional({ nullable: true }).isISO8601(),
    body('maxRedemptions').optional().isInt({ min: 0 }),
    body('perUserLimit').optional().isInt({ min: 0 }),
    body('minOrderAmount').optional().isFloat({ min: 0 }),
    body('isActive').optional().isBoolean(),
    handleValidation,
  ],
  updateCoupon
);
router.delete(
  '/admin/coupons/:id',
  protect,
  adminOnly,
  [param('id').isMongoId().withMessage('Invalid coupon id'), handleValidation],
  deleteCoupon
);

module.exports = router;
