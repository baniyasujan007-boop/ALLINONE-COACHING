const path = require('path');

const toPublicUrl = (req, filePath) => {
  const normalized = filePath.split(path.sep).join('/');
  const marker = '/uploads/';
  const idx = normalized.lastIndexOf(marker);
  const suffix = idx >= 0 ? normalized.substring(idx + 1) : normalized;
  return `${req.protocol}://${req.get('host')}/${suffix}`;
};

exports.uploadThumbnail = (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Thumbnail file is required' });
    }
    return res.status(201).json({
      message: 'Thumbnail uploaded',
      path: req.file.path,
      url: toPublicUrl(req, req.file.path),
    });
  } catch (error) {
    return next(error);
  }
};

exports.uploadPdf = (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'PDF file is required' });
    }
    return res.status(201).json({
      message: 'PDF uploaded',
      path: req.file.path,
      url: toPublicUrl(req, req.file.path),
    });
  } catch (error) {
    return next(error);
  }
};

exports.uploadFile = (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'File is required' });
    }
    return res.status(201).json({
      message: 'File uploaded',
      url: toPublicUrl(req, req.file.path),
      originalName: req.file.originalname,
      mimeType: req.file.mimetype,
    });
  } catch (error) {
    return next(error);
  }
};

exports.uploadProfileImage = (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Profile image file is required' });
    }
    return res.status(201).json({
      message: 'Profile image uploaded',
      path: req.file.path,
      url: toPublicUrl(req, req.file.path),
    });
  } catch (error) {
    return next(error);
  }
};

exports.uploadCommunityImage = (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Community image file is required' });
    }
    return res.status(201).json({
      message: 'Community image uploaded',
      path: req.file.path,
      url: toPublicUrl(req, req.file.path),
      originalName: req.file.originalname,
    });
  } catch (error) {
    return next(error);
  }
};
