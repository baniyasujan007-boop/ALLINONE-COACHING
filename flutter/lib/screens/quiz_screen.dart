import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../providers/app_state.dart';
import '../services/progress_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/quiz_card.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  String? _selected;
  bool _answered = false;

  String _userId(AppState appState) {
    return appState.currentUser?.id ?? 'local_user';
  }

  String _questionKey(QuizQuestion question) {
    return question.question.trim();
  }

  int _scoreForQuiz(AppState appState, List<QuizQuestion> quiz) {
    final Map<String, int> saved = ProgressService.instance.getChallengeQuizAnswers(
      userId: _userId(appState),
    );
    int score = 0;
    for (final QuizQuestion question in quiz) {
      final int? selectedIndex = saved[_questionKey(question)];
      if (selectedIndex != null &&
          selectedIndex >= 0 &&
          selectedIndex < question.options.length &&
          question.options[selectedIndex] == question.answer) {
        score++;
      }
    }
    return score;
  }

  void _restoreProgress(AppState appState, List<QuizQuestion> quiz) {
    if (quiz.isEmpty) {
      return;
    }
    final String userId = _userId(appState);
    final Map<String, int> savedAnswers =
        ProgressService.instance.getChallengeQuizAnswers(userId: userId);
    final int savedIndex = ProgressService.instance.getChallengeQuizIndex(
      userId: userId,
    );
    _index = savedIndex.clamp(0, quiz.length - 1);
    final QuizQuestion current = quiz[_index];
    final int? selectedIndex = savedAnswers[_questionKey(current)];
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < current.options.length) {
      _selected = current.options[selectedIndex];
      _answered = true;
    } else {
      _selected = null;
      _answered = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AppState appState = context.read<AppState>();
      if (appState.quiz.isEmpty) {
        appState.loadCourses(withDetails: true);
      }
    });
  }

  void _answer(String value) {
    final AppState appState = context.read<AppState>();
    final QuizQuestion question = appState.quiz[_index];
    final int selectedIndex = question.options.indexOf(value);
    final String userId = _userId(appState);
    if (selectedIndex >= 0) {
      ProgressService.instance.saveChallengeQuizAnswer(
        userId: userId,
        questionKey: _questionKey(question),
        selectedIndex: selectedIndex,
      );
    }
    setState(() {
      _selected = value;
      _answered = true;
    });
  }

  void _next() {
    final AppState appState = context.read<AppState>();
    final List<QuizQuestion> quiz = appState.quiz;
    final int total = quiz.length;
    final String userId = _userId(appState);
    if (_index == total - 1) {
      final int score = _scoreForQuiz(appState, quiz);
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Quiz Completed'),
          content: Text('Your score: $score / $total'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
      return;
    }
    ProgressService.instance.saveChallengeQuizIndex(
      userId: userId,
      index: _index + 1,
    );
    setState(() {
      _index++;
      final QuizQuestion nextQuestion = quiz[_index];
      final int? selectedIndex =
          ProgressService.instance.getChallengeQuizAnswers(userId: userId)[
            _questionKey(nextQuestion)
          ];
      if (selectedIndex != null &&
          selectedIndex >= 0 &&
          selectedIndex < nextQuestion.options.length) {
        _selected = nextQuestion.options[selectedIndex];
        _answered = true;
      } else {
        _selected = null;
        _answered = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    final List<QuizQuestion> quiz = appState.quiz;

    if (appState.coursesLoading && quiz.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (quiz.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Challenge')),
        body: const Center(child: Text('No quiz available yet.')),
      );
    }

    if (_index >= quiz.length) {
      _index = quiz.length - 1;
    }

    _restoreProgress(appState, quiz);

    final QuizQuestion current = quiz[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Challenge')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: (_index + 1) / quiz.length,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_index + 1}/${quiz.length}'),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: QuizCard(
                question: current.question,
                options: current.options,
                selected: _selected,
                correct: current.answer,
                answered: _answered,
                onTap: _answer,
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              opacity: _answered ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GradientButton(label: 'Next', onPressed: _next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
