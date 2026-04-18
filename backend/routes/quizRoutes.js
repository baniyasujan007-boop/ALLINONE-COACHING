const express = require('express');
const { body, param } = require('express-validator');
const {
  getQuizByCourse,
  createQuiz,
  updateQuizQuestion,
  deleteQuizQuestion,
} = require('../controllers/quizController');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/validationMiddleware');

const router = express.Router();

router.get(
  '/:courseId',
  [
    param('courseId').isMongoId().withMessage('Invalid course id'),
    handleValidation,
  ],
  getQuizByCourse
);
router.post(
  '/',
  protect,
  adminOnly,
  [
    body('courseId').isMongoId().withMessage('courseId must be a valid id'),
    body('questions')
      .isArray({ min: 1 })
      .withMessage('questions must be a non-empty array'),
    body('options').isArray({ min: 1 }).withMessage('options must be an array'),
    body('correctAnswer')
      .isArray({ min: 1 })
      .withMessage('correctAnswer must be an array'),
    body('options').custom((options, { req }) => {
      if (!Array.isArray(options)) {
        throw new Error('options must be an array');
      }
      const { questions } = req.body;
      if (!Array.isArray(questions) || options.length !== questions.length) {
        throw new Error('options length must match questions length');
      }
      if (!options.every((o) => Array.isArray(o) && o.length >= 2)) {
        throw new Error('each question must have at least 2 options');
      }
      return true;
    }),
    body('correctAnswer').custom((answers, { req }) => {
      const { questions } = req.body;
      if (!Array.isArray(questions) || answers.length !== questions.length) {
        throw new Error('correctAnswer length must match questions length');
      }
      return true;
    }),
    handleValidation,
  ],
  createQuiz
);

router.put(
  '/:quizId/questions/:questionIndex',
  protect,
  adminOnly,
  [
    param('quizId').isMongoId().withMessage('Invalid quiz id'),
    param('questionIndex')
      .isInt({ min: 0 })
      .withMessage('Invalid question index'),
    body('question').trim().notEmpty().withMessage('Question is required'),
    body('options')
      .isArray({ min: 2 })
      .withMessage('At least 2 options are required'),
    body('options.*')
      .trim()
      .notEmpty()
      .withMessage('Option cannot be empty'),
    body('correctIndex')
      .isInt({ min: 0 })
      .withMessage('correctIndex must be >= 0'),
    handleValidation,
  ],
  updateQuizQuestion
);

router.delete(
  '/:quizId/questions/:questionIndex',
  protect,
  adminOnly,
  [
    param('quizId').isMongoId().withMessage('Invalid quiz id'),
    param('questionIndex')
      .isInt({ min: 0 })
      .withMessage('Invalid question index'),
    handleValidation,
  ],
  deleteQuizQuestion
);

module.exports = router;
