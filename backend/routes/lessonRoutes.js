const express = require('express');
const { body, param } = require('express-validator');
const {
  getLessonsByCourse,
  createLesson,
  updateLesson,
  deleteLesson,
} = require('../controllers/lessonController');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/validationMiddleware');
const { fileUpload } = require('../middleware/uploadMiddleware');

const router = express.Router();

router.get(
  '/:courseId',
  [
    param('courseId').isMongoId().withMessage('Invalid course id'),
    handleValidation,
  ],
  getLessonsByCourse
);
router.post(
  '/',
  protect,
  adminOnly,
  fileUpload.single('notesFile'),
  [
    body('courseId').isMongoId().withMessage('courseId must be a valid id'),
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('videoUrl')
      .optional({ checkFalsy: true })
      .trim()
      .isURL()
      .withMessage('videoUrl must be a valid URL'),
    body('notesPdf')
      .optional()
      .isURL()
      .withMessage('notesPdf must be a valid URL'),
    body('duration').isFloat({ min: 0 }).withMessage('Duration must be >= 0'),
    body().custom((value, { req }) => {
      if (!value.videoUrl && !value.notesPdf && !req.file) {
        throw new Error('Either videoUrl or notesPdf is required');
      }
      return true;
    }),
    handleValidation,
  ],
  createLesson
);

router.put(
  '/item/:lessonId',
  protect,
  adminOnly,
  fileUpload.single('notesFile'),
  [
    param('lessonId').isMongoId().withMessage('Invalid lesson id'),
    body('title')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Title cannot be empty'),
    body('videoUrl')
      .optional({ checkFalsy: true })
      .trim()
      .isURL()
      .withMessage('videoUrl must be a valid URL'),
    body('notesPdf')
      .optional({ checkFalsy: true })
      .trim()
      .isURL()
      .withMessage('notesPdf must be a valid URL'),
    body('notesTitle')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('notesTitle cannot be empty'),
    body('duration')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Duration must be >= 0'),
    handleValidation,
  ],
  updateLesson
);

router.delete(
  '/item/:lessonId',
  protect,
  adminOnly,
  [
    param('lessonId').isMongoId().withMessage('Invalid lesson id'),
    handleValidation,
  ],
  deleteLesson
);

module.exports = router;
