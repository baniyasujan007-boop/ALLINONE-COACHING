# Coaching App (Flutter + Node + MongoDB)

This repository includes:

- Complete Flutter mobile app (student + admin flows)
- Complete Node.js backend (Express + JWT + validation + file uploads)
- MongoDB models (User, Course, Lesson, Quiz)
- API integration from Flutter to backend

## Project Structure

- `flutter/` Flutter app
- `backend/` Node.js API server

## Backend Setup (Node.js + MongoDB)

1. Go to backend folder:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create environment file:
```bash
cp .env.example .env
```

4. Update `.env` as needed:
```env
PORT=5001
MONGO_URI=mongodb://127.0.0.1:27017/coaching_app
JWT_SECRET=change_this_secret
GOOGLE_CLIENT_IDS=your_android_or_ios_client_id.apps.googleusercontent.com,your_web_client_id.apps.googleusercontent.com
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-2.5-flash
```

For ChatGPT (recommended), set OpenAI values in `backend/.env`:
```env
OPENAI_API_KEY=your_openai_api_key
OPENAI_MODEL=gpt-4o-mini
```

Notes:
- If `OPENAI_API_KEY` is present, backend AI routes use ChatGPT via OpenAI.
- If `OPENAI_API_KEY` is absent but `GEMINI_API_KEY` is present, backend falls back to Gemini.

5. Start backend:
```bash
npm run dev
```

Backend base URL:
- `http://localhost:5001/api`

If MongoDB is not running, start it first (macOS + Homebrew):
```bash
brew services start mongodb-community
```

## Flutter Setup

1. From project root:
```bash
cd flutter
flutter pub get
```

2. Run app with API URL override (recommended):

Android emulator:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5001/api --dart-define=GOOGLE_SERVER_CLIENT_ID=<YOUR_WEB_CLIENT_ID>
```

Physical Android device (same Wi-Fi, use your machine LAN IP):
```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:5001/api --dart-define=GOOGLE_SERVER_CLIENT_ID=<YOUR_WEB_CLIENT_ID>
```

Chrome/web:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5001/api --dart-define=GOOGLE_SERVER_CLIENT_ID=<YOUR_WEB_CLIENT_ID>
```

Google sign-in setup notes:
- Add your Android package name and SHA certificate to a Google OAuth client before testing on Android. The current Android application ID is `com.example.coaching_app`.
- Set `GOOGLE_CLIENT_IDS` in `backend/.env` to every OAuth client ID that should be accepted by the backend.
- Pass `GOOGLE_SERVER_CLIENT_ID` to Flutter so the Google SDK returns an ID token for backend verification.
- If you launch from VS Code, set shell environment variables first so `.vscode/launch.json` can pass them through:
```bash
export GOOGLE_SERVER_CLIENT_ID=<YOUR_WEB_CLIENT_ID>
export GOOGLE_CLIENT_ID=<YOUR_WEB_OR_PLATFORM_CLIENT_ID>
```
- This repo does not include `google-services.json` or `GoogleService-Info.plist`. Add the correct file(s) from your Google/Firebase console for the Android/iOS app before testing Google sign-in on device.

## Implemented Backend APIs

Authentication:
- `POST /api/auth/register`
- `POST /api/auth/login`

Courses:
- `GET /api/courses`
- `GET /api/courses/:id`
- `POST /api/courses` (admin)
- `PUT /api/courses/:id` (admin)
- `DELETE /api/courses/:id` (admin)

Lessons:
- `POST /api/lessons` (admin)
- `GET /api/lessons/:courseId`

Quiz:
- `POST /api/quiz` (admin)
- `GET /api/quiz/:courseId`

Uploads:
- `POST /api/upload/thumbnail` (admin, form-data field: `file`)
- `POST /api/upload/pdf` (admin, form-data field: `file`)

AI:
- `POST /api/ai/doubt-solve` (auth required)

`/api/ai/doubt-solve` now supports ChatGPT (OpenAI) and can also accept an image with the doubt.

Static files:
- `/uploads/...`

## Security Features

- JWT authentication
- Password hashing with bcrypt
- Protected routes (`protect`, `adminOnly`)
- Input validation with `express-validator`
- Centralized error handling middleware

## Notes

- If backend fails with `EADDRINUSE: 5001`, another process is already using port `5001`.
  Change `PORT` in `backend/.env` or stop the existing process.
- Flutter currently keeps progress tracking client-side in-memory.
