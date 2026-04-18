const { solveDoubt } = require('../services/aiService');

exports.solveDoubt = async (req, res, next) => {
  try {
    const { question, imageBase64, imageMimeType } = req.body;
    const explanation = await solveDoubt({
      question:
        typeof question === 'string' && question.trim()
          ? question.trim()
          : null,
      imageBase64:
        typeof imageBase64 === 'string' && imageBase64.trim()
          ? imageBase64.trim()
          : null,
      imageMimeType:
        typeof imageMimeType === 'string' && imageMimeType.trim()
          ? imageMimeType.trim()
          : null,
    });
    return res.json({ explanation });
  } catch (error) {
    return next(error);
  }
};
