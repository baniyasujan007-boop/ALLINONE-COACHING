const fs = require('fs');
const path = require('path');
const multer = require('multer');

const ensureDir = (dirPath) => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
};

const makeUploader = ({
  folder,
  allowedMimeTypes,
  allowedExtensions = null,
  allowImageWildcard = false,
}) => {
  const absoluteUploadDir = path.join(__dirname, '..', 'uploads', folder);
  ensureDir(absoluteUploadDir);

  const storage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, absoluteUploadDir),
    filename: (_req, file, cb) => {
      const safeName = file.originalname.replace(/\s+/g, '_');
      cb(null, `${Date.now()}-${safeName}`);
    },
  });

  const fileFilter = (_req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    const mimeAllowed = allowedMimeTypes.includes(file.mimetype);
    const extAllowed =
      Array.isArray(allowedExtensions) &&
      allowedExtensions.includes(ext.replace('.', ''));
    const wildcardAllowed =
      allowImageWildcard && typeof file.mimetype === 'string'
        ? file.mimetype.startsWith('image/')
        : false;

    if (mimeAllowed || extAllowed || wildcardAllowed) {
      return cb(null, true);
    }
    return cb(
      new Error(
        `Unsupported file type: ${file.mimetype || 'unknown'} (${ext || 'no extension'})`
      )
    );
  };

  return multer({
    storage,
    fileFilter,
    limits: { fileSize: 25 * 1024 * 1024 },
  });
};

const imageUpload = makeUploader({
  folder: 'thumbnails',
  allowedMimeTypes: [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'image/pjpeg',
  ],
  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
  allowImageWildcard: true,
});

const pdfUpload = makeUploader({
  folder: 'notes',
  allowedMimeTypes: ['application/pdf'],
});

const fileUpload = makeUploader({
  folder: 'files',
  allowedMimeTypes: [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
    'application/zip',
    'application/x-zip-compressed',
    'video/mp4',
    'video/quicktime',
    'video/x-msvideo',
    'video/x-matroska',
    'video/webm',
    'application/octet-stream',
  ],
});

module.exports = {
  imageUpload,
  pdfUpload,
  fileUpload,
};
