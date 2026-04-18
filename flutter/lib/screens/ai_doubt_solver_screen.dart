import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../providers/app_state.dart';
import '../services/ai_doubt_service.dart';
import '../services/api_client.dart';
import 'video_player_screen.dart';

class AiDoubtSolverScreen extends StatefulWidget {
  const AiDoubtSolverScreen({super.key});

  @override
  State<AiDoubtSolverScreen> createState() => _AiDoubtSolverScreenState();
}

class _AiDoubtSolverScreenState extends State<AiDoubtSolverScreen> {
  final TextEditingController _doubtController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _attachedImageBytes;
  String? _attachedImageName;
  bool _loading = false;
  String? _explanation;
  List<_VideoSuggestion> _relatedVideos = <_VideoSuggestion>[];
  List<String> _practiceQuestions = <String>[];

  @override
  void dispose() {
    _doubtController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot(ImageSource source) async {
    final XFile? picked = await _imagePicker.pickImage(source: source);
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _attachedImageBytes = bytes;
      _attachedImageName = picked.name;
    });
  }

  String _focusTopic(String doubt) {
    final List<String> tokens = doubt
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((String t) => t.length > 3)
        .toList();
    if (tokens.isEmpty) {
      return 'this topic';
    }
    return tokens.take(3).join(' ');
  }

  List<String> _buildPracticeQuestions(String doubt) {
    final String focus = _focusTopic(doubt);
    return <String>[
      'Explain $focus in your own words with one practical example.',
      'What is one common mistake in $focus and how would you debug it?',
      'Implement a small exercise using $focus and describe expected output.',
    ];
  }

  List<_VideoSuggestion> _findRelatedVideos(
    String doubt,
    List<CourseItem> courses,
  ) {
    final List<String> terms = doubt
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((String t) => t.length > 2)
        .toList();

    final List<_VideoSuggestion> suggestions = <_VideoSuggestion>[];
    for (final CourseItem course in courses) {
      for (final LessonItem lesson in course.lessons) {
        if (lesson.videoUrl.trim().isEmpty) continue;
        final String haystack =
            '${course.title} ${lesson.title} ${lesson.description}'
                .toLowerCase();
        int score = 0;
        for (final String term in terms) {
          if (haystack.contains(term)) {
            score += 1;
          }
        }
        suggestions.add(
          _VideoSuggestion(
            courseTitle: course.title,
            lesson: lesson,
            score: score,
          ),
        );
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    if (suggestions.isEmpty) return <_VideoSuggestion>[];

    final List<_VideoSuggestion> matched = suggestions
        .where((s) => s.score > 0)
        .take(3)
        .toList();
    if (matched.isNotEmpty) return matched;
    return suggestions.take(3).toList();
  }

  String _guessImageMimeType() {
    final String name = (_attachedImageName ?? '').toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _solveDoubt() async {
    final String doubt = _doubtController.text.trim();
    if (doubt.isEmpty && _attachedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a doubt or attach a screenshot')),
      );
      return;
    }

    final List<CourseItem> courses = context.read<AppState>().courses;
    setState(() {
      _loading = true;
    });

    final String effectiveDoubt = doubt.isEmpty
        ? 'Please explain the question in this screenshot.'
        : doubt;
    try {
      final String explanation = await AiDoubtService.instance.solveDoubt(
        question: doubt.isEmpty ? null : doubt,
        imageBytes: _attachedImageBytes,
        imageMimeType: _guessImageMimeType(),
      );
      if (!mounted) return;
      setState(() {
        _explanation = explanation;
        _practiceQuestions = _buildPracticeQuestions(effectiveDoubt);
        _relatedVideos = _findRelatedVideos(effectiveDoubt, courses);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to solve doubt. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Doubt Solver')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Ask your doubt',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _doubtController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Type your question...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => _pickScreenshot(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Attach Screenshot'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickScreenshot(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Use Camera'),
              ),
              if (_attachedImageBytes != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _attachedImageBytes = null;
                      _attachedImageName = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Remove'),
                ),
            ],
          ),
          if (_attachedImageBytes != null) ...<Widget>[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _attachedImageBytes!,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            if (_attachedImageName != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _attachedImageName!,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loading ? null : _solveDoubt,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Solving...' : 'Solve Doubt'),
          ),
          if (_explanation != null) ...<Widget>[
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'AI Explanation',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_explanation!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Related Videos',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_relatedVideos.isEmpty)
                      const Text('No related videos available yet.')
                    else
                      ..._relatedVideos.map((v) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.play_circle_outline),
                          title: Text(v.lesson.title),
                          subtitle: Text(v.courseTitle),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => VideoPlayerScreen(
                                  courseTitle: v.courseTitle,
                                  lesson: v.lesson,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Practice Questions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._practiceQuestions.map(
                      (q) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.help_outline),
                        title: Text(q),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoSuggestion {
  const _VideoSuggestion({
    required this.courseTitle,
    required this.lesson,
    required this.score,
  });

  final String courseTitle;
  final LessonItem lesson;
  final int score;
}
