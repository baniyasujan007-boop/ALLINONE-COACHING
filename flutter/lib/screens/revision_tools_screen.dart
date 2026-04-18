import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../models/student_progress.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/glass_card.dart';

class RevisionToolsScreen extends StatefulWidget {
  const RevisionToolsScreen({
    super.key,
    required this.courses,
    required this.userId,
  });

  final List<CourseItem> courses;
  final String? userId;

  @override
  State<RevisionToolsScreen> createState() => _RevisionToolsScreenState();
}

class _RevisionToolsScreenState extends State<RevisionToolsScreen> {
  int _flashcardIndex = 0;
  bool _showAnswer = false;

  List<_RevisionFlashcard> _buildFlashcards() {
    final List<_RevisionFlashcard> cards = <_RevisionFlashcard>[];
    for (final CourseItem course in widget.courses) {
      for (final QuizQuestion question in course.quiz) {
        if (question.question.trim().isEmpty ||
            question.answer.trim().isEmpty) {
          continue;
        }
        cards.add(
          _RevisionFlashcard(
            prompt: question.question,
            answer: question.answer,
            hint: course.title,
            options: question.options,
          ),
        );
      }
    }
    return cards;
  }

  List<_SavedRevisionNote> _buildSavedNotes(StudentProgress progress) {
    final Map<String, _LessonMeta> lessonMeta = <String, _LessonMeta>{};
    for (final CourseItem course in widget.courses) {
      for (final LessonItem lesson in course.lessons) {
        lessonMeta[lesson.id] = _LessonMeta(
          courseTitle: course.title,
          lessonTitle: lesson.title,
          notesUrl: lesson.notesUrl,
        );
      }
    }

    final List<_SavedRevisionNote> items = <_SavedRevisionNote>[];
    for (final MapEntry<String, List<LessonNote>> entry
        in progress.notesByLessonId.entries) {
      final String lessonId = entry.key;
      final List<LessonNote> notes = entry.value;
      final _LessonMeta meta = lessonMeta[lessonId] ?? _LessonMeta.unknown();
      for (final LessonNote note in notes) {
        items.add(
          _SavedRevisionNote(
            courseTitle: meta.courseTitle,
            lessonTitle: meta.lessonTitle,
            highlightText: note.highlightText,
            comment: note.comment,
            createdAt: note.createdAt,
          ),
        );
      }
    }

    for (final String lessonId in progress.bookmarkedLessonIds) {
      final _LessonMeta? meta = lessonMeta[lessonId];
      if (meta == null) {
        continue;
      }
      items.add(
        _SavedRevisionNote(
          courseTitle: meta.courseTitle,
          lessonTitle: meta.lessonTitle,
          highlightText: 'Bookmarked for quick revision',
          comment: meta.notesUrl.isEmpty
              ? 'Return to this lesson from your bookmarks.'
              : 'This lesson includes attached notes for revision.',
          createdAt: DateTime.now(),
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ProgressService>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<_RevisionFlashcard> flashcards = _buildFlashcards();
    final StudentProgress? progress = widget.userId == null
        ? null
        : ProgressService.instance.getProgress(widget.userId!);
    final List<_SavedRevisionNote> savedNotes = progress == null
        ? const <_SavedRevisionNote>[]
        : _buildSavedNotes(progress);

    if (_flashcardIndex >= flashcards.length && flashcards.isNotEmpty) {
      _flashcardIndex = flashcards.length - 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Revision Tools')),
      body: AnimatedGradientBackground(
        dark: dark,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.style_rounded),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Flashcards',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (flashcards.isEmpty)
                    const Text(
                      'No real quiz questions are available yet. Add quizzes to your courses to unlock flashcards.',
                    )
                  else
                    Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showAnswer = !_showAnswer;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                colors: <Color>[
                                  Color(0xFF6558F5),
                                  Color(0xFF2D9CDB),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  flashcards[_flashcardIndex].hint,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (flashcards[_flashcardIndex]
                                    .options
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Options: ${flashcards[_flashcardIndex].options.join(' | ')}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 18),
                                Text(
                                  _showAnswer
                                      ? flashcards[_flashcardIndex].answer
                                      : flashcards[_flashcardIndex].prompt,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _showAnswer
                                      ? 'Tap card to review the question again'
                                      : 'Tap card to reveal the correct answer',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: _flashcardIndex == 0
                                  ? null
                                  : () {
                                      setState(() {
                                        _flashcardIndex -= 1;
                                        _showAnswer = false;
                                      });
                                    },
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Previous'),
                            ),
                            const Spacer(),
                            Text(
                              '${_flashcardIndex + 1}/${flashcards.length}',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed:
                                  _flashcardIndex == flashcards.length - 1
                                  ? null
                                  : () {
                                      setState(() {
                                        _flashcardIndex += 1;
                                        _showAnswer = false;
                                      });
                                    },
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text('Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.sticky_note_2_outlined),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Saved Revision Notes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (widget.userId == null)
                    const Text('Sign in to view your saved revision notes.')
                  else if (savedNotes.isEmpty)
                    const Text(
                      'No real notes or bookmarked lessons yet. Save notes while studying to build this revision space.',
                    )
                  else
                    ...savedNotes.take(8).map((_SavedRevisionNote note) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: AppDecorations.softNeu(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              note.courseTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note.lessonTitle,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note.highlightText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (note.comment.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(note.comment),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevisionFlashcard {
  const _RevisionFlashcard({
    required this.prompt,
    required this.answer,
    required this.hint,
    required this.options,
  });

  final String prompt;
  final String answer;
  final String hint;
  final List<String> options;
}

class _SavedRevisionNote {
  const _SavedRevisionNote({
    required this.courseTitle,
    required this.lessonTitle,
    required this.highlightText,
    required this.comment,
    required this.createdAt,
  });

  final String courseTitle;
  final String lessonTitle;
  final String highlightText;
  final String comment;
  final DateTime createdAt;
}

class _LessonMeta {
  const _LessonMeta({
    required this.courseTitle,
    required this.lessonTitle,
    required this.notesUrl,
  });

  factory _LessonMeta.unknown() {
    return const _LessonMeta(
      courseTitle: 'Course',
      lessonTitle: 'Lesson',
      notesUrl: '',
    );
  }

  final String courseTitle;
  final String lessonTitle;
  final String notesUrl;
}
