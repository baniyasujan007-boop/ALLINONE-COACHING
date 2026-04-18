const express = require('express');
const { body, param } = require('express-validator');

const {
  getCommunityPosts,
  createCommunityPost,
  addCommunityAnswer,
} = require('../controllers/communityController');
const { protect } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/validationMiddleware');

const validUrl = (field) =>
  body(field)
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
        throw new Error(`${field} must be a valid URL`);
      }
    });

const router = express.Router();

router.get('/', protect, getCommunityPosts);

router.post(
  '/posts',
  protect,
  [
    body('topic').trim().notEmpty().withMessage('Topic is required'),
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('message').trim().notEmpty().withMessage('Message is required'),
    body('imageName').optional().isString().withMessage('imageName must be a string'),
    validUrl('imageUrl'),
    handleValidation,
  ],
  createCommunityPost
);

router.post(
  '/posts/:id/answers',
  protect,
  [
    param('id').isMongoId().withMessage('Invalid post id'),
    body('message').trim().notEmpty().withMessage('Message is required'),
    body('imageName').optional().isString().withMessage('imageName must be a string'),
    validUrl('imageUrl'),
    handleValidation,
  ],
  addCommunityAnswer
);

module.exports = router;
