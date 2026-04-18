const express = require('express');
const { body } = require('express-validator');
const { solveDoubt } = require('../controllers/aiController');
const { protect } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/validationMiddleware');

const router = express.Router();

router.post(
  '/doubt-solve',
  protect,
  [
    body('question')
      .optional()
      .isString()
      .isLength({ min: 1, max: 4000 })
      .withMessage('question must be 1 to 4000 characters'),
    body('imageBase64')
      .optional()
      .isString()
      .isLength({ min: 16, max: 12 * 1024 * 1024 })
      .withMessage('imageBase64 is too large or invalid'),
    body('imageMimeType')
      .optional()
      .isString()
      .isIn(['image/jpeg', 'image/png', 'image/webp'])
      .withMessage('imageMimeType must be image/jpeg, image/png, or image/webp'),
    body().custom((value) => {
      const hasQuestion =
        value &&
        typeof value.question === 'string' &&
        value.question.trim().length > 0;
      const hasImage =
        value &&
        typeof value.imageBase64 === 'string' &&
        value.imageBase64.trim().length > 0;
      if (!hasQuestion && !hasImage) {
        throw new Error('Provide question text or an image');
      }
      return true;
    }),
    handleValidation,
  ],
  solveDoubt
);

module.exports = router;
