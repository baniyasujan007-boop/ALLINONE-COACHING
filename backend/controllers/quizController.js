const Quiz = require('../models/Quiz');

exports.getQuizByCourse = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    const quizItems = await Quiz.find({ courseId }).sort({ createdAt: -1 });
    return res.json(quizItems);
  } catch (error) {
    return next(error);
  }
};

exports.createQuiz = async (req, res, next) => {
  try {
    const { courseId, questions, options, correctAnswer } = req.body;
    const quiz = await Quiz.create({
      courseId,
      questions,
      options,
      correctAnswer,
    });
    return res.status(201).json(quiz);
  } catch (error) {
    return next(error);
  }
};

exports.updateQuizQuestion = async (req, res, next) => {
  try {
    const { quizId, questionIndex } = req.params;
    const index = Number(questionIndex);
    const { question, options, correctIndex } = req.body;

    const quiz = await Quiz.findById(quizId);
    if (!quiz) {
      return res.status(404).json({ message: 'Quiz not found' });
    }
    if (index < 0 || index >= quiz.questions.length) {
      return res.status(400).json({ message: 'Invalid question index' });
    }
    if (!Array.isArray(options) || options.length < 2) {
      return res
        .status(400)
        .json({ message: 'At least 2 options are required' });
    }
    if (correctIndex < 0 || correctIndex >= options.length) {
      return res.status(400).json({ message: 'Invalid correct option index' });
    }

    quiz.questions[index] = question;
    quiz.options[index] = options;
    quiz.correctAnswer[index] = options[correctIndex];
    await quiz.save();

    return res.json(quiz);
  } catch (error) {
    return next(error);
  }
};

exports.deleteQuizQuestion = async (req, res, next) => {
  try {
    const { quizId, questionIndex } = req.params;
    const index = Number(questionIndex);
    const quiz = await Quiz.findById(quizId);
    if (!quiz) {
      return res.status(404).json({ message: 'Quiz not found' });
    }
    if (index < 0 || index >= quiz.questions.length) {
      return res.status(400).json({ message: 'Invalid question index' });
    }

    quiz.questions.splice(index, 1);
    quiz.options.splice(index, 1);
    quiz.correctAnswer.splice(index, 1);

    if (quiz.questions.length === 0) {
      await Quiz.findByIdAndDelete(quizId);
      return res.json({ message: 'Quiz question deleted successfully' });
    }

    await quiz.save();
    return res.json(quiz);
  } catch (error) {
    return next(error);
  }
};
