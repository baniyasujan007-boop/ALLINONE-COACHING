const express = require('express');
const { body, param } = require('express-validator');
const {
  getCourses,
  getCourseById,
  createCourse,
  updateCourse,
  deleteCourse,
  purchaseCourse,
} = require('../controllers/courseController');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/validationMiddleware');
const { imageUpload } = require('../middleware/uploadMiddleware');

const router = express.Router();
const billingCycles = ['monthly', 'quarterly', 'semiAnnual', 'yearly'];

router.get('/', getCourses);
router.get(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid course id'), handleValidation],
  getCourseById
);
router.post(
  '/',
  protect,
  adminOnly,
  imageUpload.single('thumbnailFile'),
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('description').trim().notEmpty().withMessage('Description is required'),
    body('instructor')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Instructor cannot be empty'),
    body('price').optional().isFloat({ min: 0 }).withMessage('Price must be >= 0'),
    body('pricing').optional().isObject().withMessage('pricing must be an object'),
    body('pricing.monthly').optional().isFloat({ min: 0 }),
    body('pricing.quarterly').optional().isFloat({ min: 0 }),
    body('pricing.semiAnnual').optional().isFloat({ min: 0 }),
    body('pricing.yearly').optional().isFloat({ min: 0 }),
    body('offer').optional().isObject().withMessage('offer must be an object'),
    body('offer.title').optional().isString(),
    body('offer.pricing').optional().isObject(),
    body('offer.pricing.monthly').optional().isFloat({ min: 0 }),
    body('offer.pricing.quarterly').optional().isFloat({ min: 0 }),
    body('offer.pricing.semiAnnual').optional().isFloat({ min: 0 }),
    body('offer.pricing.yearly').optional().isFloat({ min: 0 }),
    body('offer.expiresAt').optional().isISO8601(),
    body('isLocked')
      .optional()
      .isBoolean()
      .withMessage('isLocked must be true or false'),
    body('thumbnail').optional().isString().withMessage('Thumbnail must be a string'),
    handleValidation,
  ],
  createCourse
);
router.put(
  '/:id',
  protect,
  adminOnly,
  imageUpload.single('thumbnailFile'),
  [
    param('id').isMongoId().withMessage('Invalid course id'),
    body('title').optional().trim().notEmpty().withMessage('Title cannot be empty'),
    body('description')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Description cannot be empty'),
    body('instructor')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Instructor cannot be empty'),
    body('price').optional().isFloat({ min: 0 }).withMessage('Price must be >= 0'),
    body('pricing').optional().isObject().withMessage('pricing must be an object'),
    body('pricing.monthly').optional().isFloat({ min: 0 }),
    body('pricing.quarterly').optional().isFloat({ min: 0 }),
    body('pricing.semiAnnual').optional().isFloat({ min: 0 }),
    body('pricing.yearly').optional().isFloat({ min: 0 }),
    body('offer').optional().isObject().withMessage('offer must be an object'),
    body('offer.title').optional().isString(),
    body('offer.pricing').optional().isObject(),
    body('offer.pricing.monthly').optional().isFloat({ min: 0 }),
    body('offer.pricing.quarterly').optional().isFloat({ min: 0 }),
    body('offer.pricing.semiAnnual').optional().isFloat({ min: 0 }),
    body('offer.pricing.yearly').optional().isFloat({ min: 0 }),
    body('offer.expiresAt').optional().isISO8601(),
    body('isLocked')
      .optional()
      .isBoolean()
      .withMessage('isLocked must be true or false'),
    body('thumbnail').optional().isString().withMessage('Thumbnail must be a string'),
    handleValidation,
  ],
  updateCourse
);
router.delete(
  '/:id',
  protect,
  adminOnly,
  [param('id').isMongoId().withMessage('Invalid course id'), handleValidation],
  deleteCourse
);
router.post(
  '/:id/purchase',
  protect,
  [
    param('id').isMongoId().withMessage('Invalid course id'),
    body('billingCycle')
      .optional()
      .isIn(billingCycles)
      .withMessage('Invalid billing cycle'),
    handleValidation,
  ],
  purchaseCourse
);

module.exports = router;
