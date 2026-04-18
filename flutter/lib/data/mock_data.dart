import '../models/course.dart';

final List<Course> initialCourses = <Course>[
  Course(
    id: 'course_flutter',
    title: 'Flutter Basics',
    description: 'Build cross-platform mobile apps with Flutter.',
    thumbnailUrl: 'https://example.com/images/flutter-basics.jpg',
    lessons: <VideoLesson>[
      const VideoLesson(
        id: 'l1',
        title: 'Widget Fundamentals',
        videoUrl: 'https://example.com/flutter/widgets',
        durationMinutes: 14,
      ),
      const VideoLesson(
        id: 'l2',
        title: 'State Management Intro',
        videoUrl: 'https://example.com/flutter/state',
        durationMinutes: 18,
      ),
    ],
    studyMaterials: <StudyMaterial>[
      const StudyMaterial(
        id: 'm1',
        title: 'Flutter Widget Notes',
        pdfUrl: 'https://example.com/pdfs/flutter-widgets.pdf',
      ),
    ],
    quizQuestions: <QuizQuestion>[
      const QuizQuestion(
        id: 'q1',
        quizId: 'quiz_flutter_basics',
        questionIndex: 0,
        question: 'What is a widget in Flutter?',
        options: <String>[
          'A UI building block',
          'A background service',
          'A database table',
          'A device sensor',
        ],
        correctIndex: 0,
      ),
      const QuizQuestion(
        id: 'q2',
        quizId: 'quiz_flutter_basics',
        questionIndex: 1,
        question: 'Which method is used to redraw a StatefulWidget?',
        options: <String>['render()', 'refresh()', 'setState()', 'updateUI()'],
        correctIndex: 2,
      ),
    ],
  ),
  Course(
    id: 'course_dart',
    title: 'Dart for Beginners',
    description: 'Learn Dart syntax, collections, and OOP.',
    thumbnailUrl: 'https://example.com/images/dart-beginners.jpg',
    lessons: <VideoLesson>[
      const VideoLesson(
        id: 'l3',
        title: 'Variables and Types',
        videoUrl: 'https://example.com/dart/types',
        durationMinutes: 12,
      ),
      const VideoLesson(
        id: 'l4',
        title: 'Classes and Objects',
        videoUrl: 'https://example.com/dart/oop',
        durationMinutes: 20,
      ),
    ],
    studyMaterials: <StudyMaterial>[
      const StudyMaterial(
        id: 'm2',
        title: 'Dart Fundamentals Notes',
        pdfUrl: 'https://example.com/pdfs/dart-fundamentals.pdf',
      ),
    ],
    quizQuestions: <QuizQuestion>[
      const QuizQuestion(
        id: 'q3',
        quizId: 'quiz_dart_beginners',
        questionIndex: 0,
        question: 'Which keyword declares an immutable variable?',
        options: <String>['var', 'dynamic', 'late', 'final'],
        correctIndex: 3,
      ),
      const QuizQuestion(
        id: 'q4',
        quizId: 'quiz_dart_beginners',
        questionIndex: 1,
        question: 'What does null safety prevent?',
        options: <String>[
          'Runtime null errors',
          'All compile errors',
          'Memory leaks',
          'Slow rendering',
        ],
        correctIndex: 0,
      ),
    ],
  ),
];
