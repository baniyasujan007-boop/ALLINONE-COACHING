const express = require('express');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const { imageUpload, pdfUpload, fileUpload } = require('../middleware/uploadMiddleware');
const {
  uploadThumbnail,
  uploadPdf,
  uploadFile,
  uploadProfileImage,
  uploadCommunityImage,
} = require('../controllers/uploadController');

const router = express.Router();

router.post(
  '/thumbnail',
  protect,
  adminOnly,
  imageUpload.single('file'),
  uploadThumbnail
);

router.post('/pdf', protect, adminOnly, pdfUpload.single('file'), uploadPdf);

router.post('/file', protect, adminOnly, fileUpload.single('file'), uploadFile);
router.post(
  '/community-image',
  protect,
  imageUpload.single('file'),
  uploadCommunityImage
);
router.post(
  '/profile-image',
  protect,
  imageUpload.single('file'),
  uploadProfileImage
);

module.exports = router;
