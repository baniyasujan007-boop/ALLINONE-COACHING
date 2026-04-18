const express = require('express');
const { body, param } = require('express-validator');
const {
  register,
  login,
  googleLogin,
  getProfile,
  updateProfile,
  forgotPassword,
  getUsersForAdmin,
  updateUserByAdmin,
} = require('../controllers/authController');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/validationMiddleware');

const router = express.Router();
const profileImageValidator = body('profileImage')
  .optional()
  .custom((value) => {
    if (value == null || value === '') {
      return true;
    }
    try {
      // eslint-disable-next-line no-new
      new URL(value);
      return true;
    } catch (_) {
      throw new Error('profileImage must be a valid URL');
    }
  });

router.post(
  '/register',
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters'),
    body('role')
      .optional()
      .isIn(['student', 'admin'])
      .withMessage('Role must be student or admin'),
    body('phone').optional().isString().isLength({ max: 30 }),
    body('address').optional().isString().isLength({ max: 300 }),
    profileImageValidator,
    handleValidation,
  ],
  register
);
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
    handleValidation,
  ],
  login
);
router.post(
  '/google',
  [
    body('idToken').optional().isString().withMessage('Google idToken must be a string'),
    body('accessToken')
      .optional()
      .isString()
      .withMessage('Google accessToken must be a string'),
    body().custom((value) => {
      const hasIdToken =
        value && typeof value.idToken === 'string' && value.idToken.trim().length > 0;
      const hasAccessToken =
        value &&
        typeof value.accessToken === 'string' &&
        value.accessToken.trim().length > 0;
      if (!hasIdToken && !hasAccessToken) {
        throw new Error('Google idToken or accessToken is required');
      }
      return true;
    }),
    handleValidation,
  ],
  googleLogin
);
router.get('/me', protect, getProfile);
router.put(
  '/me',
  protect,
  [
    body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
    body('email').optional().isEmail().withMessage('Valid email is required'),
    body('phone').optional().isString().isLength({ max: 30 }),
    body('address').optional().isString().isLength({ max: 300 }),
    profileImageValidator,
    handleValidation,
  ],
  updateProfile
);
router.post(
  '/forgot-password',
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('newPassword')
      .isLength({ min: 8 })
      .withMessage('New password must be at least 8 characters'),
    handleValidation,
  ],
  forgotPassword
);
router.get('/users', protect, adminOnly, getUsersForAdmin);
router.put(
  '/users/:id',
  protect,
  adminOnly,
  [
    param('id').isMongoId().withMessage('Invalid user id'),
    body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
    body('email').optional().isEmail().withMessage('Valid email is required'),
    body('role')
      .optional()
      .isIn(['student', 'admin'])
      .withMessage('Role must be student or admin'),
    body('phone').optional().isString().isLength({ max: 30 }),
    body('address').optional().isString().isLength({ max: 300 }),
    body('enrolledCourseIds')
      .optional()
      .isArray()
      .withMessage('enrolledCourseIds must be an array'),
    body('enrolledCourseIds.*')
      .optional()
      .isMongoId()
      .withMessage('Each enrolled course id must be valid'),
    profileImageValidator,
    handleValidation,
  ],
  updateUserByAdmin
);

module.exports = router;
