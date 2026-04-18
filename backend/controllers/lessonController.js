const Lesson = require('../models/Lesson');
const Course = require('../models/Course');
const path = require('path');

const toPublicUrl = (req, filePath) => {
  const normalized = filePath.split(path.sep).join('/');
  const marker = '/uploads/';
  const idx = normalized.lastIndexOf(marker);
  const suffix = idx >= 0 ? normalized.substring(idx + 1) : normalized;
  return `${req.protocol}://${req.get('host')}/${suffix}`;
};

exports.getLessonsByCourse = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    const lessons = await Lesson.find({ courseId }).sort({ createdAt: 1 });
    return res.json(lessons);
  } catch (error) {
    return next(error);
  }
};

exports.createLesson = async (req, res, next) => {
  try {
    const { courseId, title, videoUrl, notesPdf, notesTitle, duration } =
      req.body;
    const notesPdfUrl = req.file ? toPublicUrl(req, req.file.path) : notesPdf;
    const lesson = await Lesson.create({
      courseId,
      title,
      videoUrl,
      notesPdf: notesPdfUrl,
      notesTitle: notesTitle || '',
      duration,
    });
    await Course.findByIdAndUpdate(courseId, {
      $addToSet: { lessons: lesson._id },
    });
    return res.status(201).json(lesson);
  } catch (error) {
    return next(error);
  }
};

exports.updateLesson = async (req, res, next) => {
  try {
    const { lessonId } = req.params;
    const lesson = await Lesson.findById(lessonId);
    if (!lesson) {
      return res.status(404).json({ message: 'Lesson not found' });
    }

    const payload = req.body || {};
    if (typeof payload.title === 'string') {
      lesson.title = payload.title.trim();
    }
    if (typeof payload.videoUrl === 'string') {
      lesson.videoUrl = payload.videoUrl.trim();
    }
    if (typeof payload.notesPdf === 'string') {
      lesson.notesPdf = payload.notesPdf.trim();
    }
    if (typeof payload.notesTitle === 'string') {
      lesson.notesTitle = payload.notesTitle.trim();
    }
    if (payload.duration !== undefined) {
      lesson.duration = Number(payload.duration);
    }
    if (req.file) {
      lesson.notesPdf = toPublicUrl(req, req.file.path);
    }

    if (!lesson.videoUrl && !lesson.notesPdf) {
      return res
        .status(400)
        .json({ message: 'Either videoUrl or notesPdf is required' });
    }
    await lesson.save();
    return res.json(lesson);
  } catch (error) {
    return next(error);
  }
};

exports.deleteLesson = async (req, res, next) => {
  try {
    const { lessonId } = req.params;
    const lesson = await Lesson.findById(lessonId);
    if (!lesson) {
      return res.status(404).json({ message: 'Lesson not found' });
    }

    await Course.findByIdAndUpdate(lesson.courseId, {
      $pull: { lessons: lesson._id },
    });
    await Lesson.findByIdAndDelete(lessonId);

    return res.json({ message: 'Lesson deleted successfully' });
  } catch (error) {
    return next(error);
  }
};
