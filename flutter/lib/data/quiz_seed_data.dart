import '../models/course.dart';

class _SeedQuestion {
  const _SeedQuestion(this.question, this.options, this.correctIndex);

  final String question;
  final List<String> options;
  final int correctIndex;
}

const List<_SeedQuestion> _genericQuizSeed = <_SeedQuestion>[
  _SeedQuestion(
    'Which language is primarily used to write Flutter apps?',
    <String>['Swift', 'Kotlin', 'Dart', 'JavaScript'],
    2,
  ),
  _SeedQuestion(
    'What is the main purpose of a widget in Flutter?',
    <String>[
      'Store database records',
      'Build and describe UI',
      'Handle server deployment',
      'Compress assets',
    ],
    1,
  ),
  _SeedQuestion(
    'Which widget should you use for scrollable vertical content?',
    <String>['Row', 'Stack', 'ListView', 'Icon'],
    2,
  ),
  _SeedQuestion(
    'What does `setState()` do in a `StatefulWidget`?',
    <String>[
      'Deletes the widget',
      'Rebuilds the UI with updated state',
      'Navigates to another page',
      'Creates an API request',
    ],
    1,
  ),
  _SeedQuestion(
    'Which keyword creates a variable whose value cannot be changed?',
    <String>['var', 'final', 'late', 'dynamic'],
    1,
  ),
  _SeedQuestion(
    'What is the entry point of every Dart application?',
    <String>['start()', 'build()', 'main()', 'run()'],
    2,
  ),
  _SeedQuestion(
    'Which widget is best for adding empty space between widgets?',
    <String>['Padding', 'SizedBox', 'AspectRatio', 'Placeholder'],
    1,
  ),
  _SeedQuestion(
    'What is the role of `Scaffold` in Flutter?',
    <String>[
      'Compile the project',
      'Store app settings',
      'Provide a basic material page layout',
      'Format text fields',
    ],
    2,
  ),
  _SeedQuestion(
    'Which collection type stores unique values only?',
    <String>['List', 'Map', 'Set', 'Queue'],
    2,
  ),
  _SeedQuestion(
    'What is null safety mainly designed to reduce?',
    <String>[
      'Animation jank',
      'Runtime null reference errors',
      'APK size',
      'Internet latency',
    ],
    1,
  ),
  _SeedQuestion(
    'Which widget arranges children horizontally?',
    <String>['Column', 'Row', 'Wrap', 'Center'],
    1,
  ),
  _SeedQuestion(
    'Which widget arranges children vertically?',
    <String>['Column', 'Stack', 'Table', 'Expanded'],
    0,
  ),
  _SeedQuestion(
    'What is the purpose of `Expanded` inside a `Row` or `Column`?',
    <String>[
      'Fix a child to 40 pixels',
      'Make a child take available space',
      'Clip the child',
      'Rotate the child',
    ],
    1,
  ),
  _SeedQuestion(
    'Which widget is commonly used to capture user text input?',
    <String>['Text', 'TextFormField', 'Tooltip', 'Card'],
    1,
  ),
  _SeedQuestion(
    'Which Flutter package is commonly used here for app-wide state?',
    <String>['provider', 'path', 'intl', 'archive'],
    0,
  ),
  _SeedQuestion(
    'What does `Navigator.push()` do?',
    <String>[
      'Removes the current route permanently',
      'Adds a new route onto the navigation stack',
      'Refreshes the app theme',
      'Downloads a file',
    ],
    1,
  ),
  _SeedQuestion(
    'Which widget lets the UI react to values from a provider?',
    <String>['Consumer', 'ClipRRect', 'Hero', 'Theme'],
    0,
  ),
  _SeedQuestion(
    'What is a common use of `Future` in Dart?',
    <String>[
      'Represent asynchronous work',
      'Store widget themes',
      'Define enums',
      'Render images',
    ],
    0,
  ),
  _SeedQuestion(
    'What does `await` do inside an async function?',
    <String>[
      'Repeats a loop forever',
      'Pauses until the future completes',
      'Converts a string to JSON',
      'Makes code synchronous globally',
    ],
    1,
  ),
  _SeedQuestion(
    'Which widget is useful for showing content inside a material card?',
    <String>['Card', 'Spacer', 'Positioned', 'Opacity'],
    0,
  ),
  _SeedQuestion(
    'Which widget overlays children on top of one another?',
    <String>['Stack', 'Column', 'ListTile', 'Wrap'],
    0,
  ),
  _SeedQuestion(
    'What is `initState()` mainly used for?',
    <String>[
      'Build every frame',
      'Initialize logic when a state object is created',
      'Store routes globally',
      'Dispose controllers',
    ],
    1,
  ),
  _SeedQuestion(
    'Why should a `TextEditingController` usually be disposed?',
    <String>[
      'To avoid memory leaks',
      'To enable hot reload',
      'To speed up images',
      'To reset theme mode',
    ],
    0,
  ),
  _SeedQuestion(
    'What does `const` help with in Flutter widgets?',
    <String>[
      'Force network caching',
      'Allow compile-time constants and fewer rebuild costs',
      'Create animations automatically',
      'Bypass null safety',
    ],
    1,
  ),
  _SeedQuestion(
    'Which widget is best for styling a box with color, border, and radius?',
    <String>['Container', 'TextButton', 'AppBar', 'Divider'],
    0,
  ),
  _SeedQuestion(
    'Which statement about `StatelessWidget` is true?',
    <String>[
      'It stores mutable local UI state',
      'It rebuilds based on immutable configuration',
      'It can never contain buttons',
      'It replaces MaterialApp',
    ],
    1,
  ),
  _SeedQuestion(
    'What is the purpose of `MediaQuery`?',
    <String>[
      'Read screen and device information',
      'Write backend APIs',
      'Manage routes',
      'Encrypt data',
    ],
    0,
  ),
  _SeedQuestion(
    'Which widget is useful when a child should center itself?',
    <String>['Center', 'Align', 'Padding', 'Both A and B'],
    3,
  ),
  _SeedQuestion(
    'What is JSON commonly used for in Flutter apps?',
    <String>[
      'Describing API data payloads',
      'Playing videos',
      'Building gradients',
      'Generating icons',
    ],
    0,
  ),
  _SeedQuestion(
    'Which method converts a Dart object to a string representation for logs?',
    <String>['dispose()', 'toString()', 'copyWith()', 'compareTo()'],
    1,
  ),
  _SeedQuestion(
    'Which widget allows pull-to-refresh behavior in a list?',
    <String>['RefreshIndicator', 'Hero', 'Ink', 'IntrinsicHeight'],
    0,
  ),
  _SeedQuestion(
    'What is a `Map` in Dart?',
    <String>[
      'An ordered group of duplicate values only',
      'A key-value collection',
      'A UI widget for routing',
      'A type of image asset',
    ],
    1,
  ),
  _SeedQuestion(
    'Which operator is often used for null-aware fallback values?',
    <String>['??', '=>', '&&', '~/'],
    0,
  ),
  _SeedQuestion(
    'What is the purpose of `copyWith()` in models?',
    <String>[
      'Delete a model',
      'Create a modified copy of an object',
      'Upload files',
      'Lock a widget tree',
    ],
    1,
  ),
  _SeedQuestion(
    'Which widget clips its child using rounded corners?',
    <String>['ClipRRect', 'SafeArea', 'Expanded', 'Theme'],
    0,
  ),
  _SeedQuestion(
    'Why is `mounted` checked after async work in a State object?',
    <String>[
      'To ensure the widget is still in the tree before using context',
      'To verify an internet connection exists',
      'To enable dark mode',
      'To sort list items',
    ],
    0,
  ),
  _SeedQuestion(
    'Which service layer responsibility is a good practice?',
    <String>[
      'Mixing UI widgets with HTTP parsing',
      'Keeping API calls away from screen widgets',
      'Placing all state in main.dart',
      'Using only global variables',
    ],
    1,
  ),
  _SeedQuestion(
    'What is a benefit of separating models from screens?',
    <String>[
      'Cleaner architecture and easier maintenance',
      'Automatic animations',
      'No need for testing',
      'Faster internet access',
    ],
    0,
  ),
  _SeedQuestion(
    'Which widget helps animate property changes over time without a controller?',
    <String>[
      'AnimatedContainer',
      'RawKeyboardListener',
      'FractionallySizedBox',
      'Visibility',
    ],
    0,
  ),
  _SeedQuestion(
    'What is the role of `SafeArea`?',
    <String>[
      'Encrypt app data',
      'Keep UI away from system intrusions like notches',
      'Persist local storage',
      'Lazy load images',
    ],
    1,
  ),
  _SeedQuestion(
    'What is the main purpose of a repository or service method like `refreshCourses()`?',
    <String>[
      'Fetch and update course data from a source',
      'Create widgets only',
      'Render custom fonts',
      'Toggle airplane mode',
    ],
    0,
  ),
  _SeedQuestion(
    'Which statement about `List.generate()` is correct?',
    <String>[
      'It creates list items from a builder callback',
      'It deletes list entries',
      'It is used only for networking',
      'It works only with strings',
    ],
    0,
  ),
  _SeedQuestion(
    'When should you use a `StatefulWidget` instead of a `StatelessWidget`?',
    <String>[
      'When the UI changes based on mutable state',
      'Only when using icons',
      'Only on Android',
      'Whenever there is text',
    ],
    0,
  ),
  _SeedQuestion(
    'What does a `CircularProgressIndicator` communicate to the user?',
    <String>[
      'A completed purchase',
      'Loading or ongoing work',
      'A navigation error',
      'A successful logout',
    ],
    1,
  ),
  _SeedQuestion(
    'What is a practical use of `SnackBar`?',
    <String>[
      'Show short feedback messages',
      'Persist files to disk',
      'Draw charts',
      'Define routes',
    ],
    0,
  ),
  _SeedQuestion(
    'Why is trimming email input before login helpful?',
    <String>[
      'It removes accidental spaces',
      'It encrypts the password',
      'It improves frame rate',
      'It downloads avatars',
    ],
    0,
  ),
  _SeedQuestion(
    'Which widget is commonly used to make only part of a screen rebuild from provider state?',
    <String>['Consumer', 'Spacer', 'Transform', 'Divider'],
    0,
  ),
  _SeedQuestion(
    'What is the purpose of an `errorBuilder` on `Image.network` or Lottie widgets?',
    <String>[
      'Handle failed asset or network rendering gracefully',
      'Upload crash reports',
      'Restart the app',
      'Prevent all rebuilds',
    ],
    0,
  ),
  _SeedQuestion(
    'What does `pushReplacement()` do compared with `push()`?',
    <String>[
      'Adds two routes instead of one',
      'Replaces the current route with a new one',
      'Refreshes provider state only',
      'Works only on iOS',
    ],
    1,
  ),
  _SeedQuestion(
    'Which is the best description of app state in this project?',
    <String>[
      'Shared values like auth loading, theme, and courses',
      'Only the app icon',
      'The backend database schema',
      'Compiler settings',
    ],
    0,
  ),
  _SeedQuestion(
    'What makes quiz questions easier to manage over time?',
    <String>[
      'Keeping them in a reusable data source with consistent structure',
      'Hardcoding them in every screen separately',
      'Removing question IDs',
      'Avoiding models',
    ],
    0,
  ),
];

List<QuizQuestion> buildSeedQuizQuestions({
  required String courseId,
  String? topic,
}) {
  final String quizId = 'seed_quiz_$courseId';
  final String prefix = (topic == null || topic.trim().isEmpty)
      ? 'Practice'
      : topic.trim();

  return _genericQuizSeed.asMap().entries.map((entry) {
    final int index = entry.key;
    final _SeedQuestion question = entry.value;
    return QuizQuestion(
      id: '${quizId}_$index',
      quizId: quizId,
      questionIndex: index,
      question: '$prefix: ${question.question}',
      options: question.options,
      correctIndex: question.correctIndex,
    );
  }).toList();
}
