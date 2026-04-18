import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/student_progress.dart';
import '../../services/link_service.dart';
import '../../services/progress_service.dart';

class LessonVideoPage extends StatefulWidget {
  const LessonVideoPage({
    super.key,
    required this.userId,
    required this.lessonId,
    required this.title,
    required this.videoUrl,
  });

  final String userId;
  final String lessonId;
  final String title;
  final String videoUrl;

  @override
  State<LessonVideoPage> createState() => _LessonVideoPageState();
}

class _LessonVideoPageState extends State<LessonVideoPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initializing = true;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final Uri? uri = Uri.tryParse(widget.videoUrl);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() {
        _initializing = false;
        _videoError = 'This lesson video link is invalid.';
      });
      return;
    }

    final VideoPlayerController controller = VideoPlayerController.networkUrl(
      uri,
    );

    try {
      await controller.initialize();
      final ChewieController chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: colorScheme.primary,
          handleColor: colorScheme.tertiary,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          bufferedColor: colorScheme.secondary,
        ),
      );
      if (!mounted) {
        await controller.dispose();
        chewieController.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _chewieController = chewieController;
        _initializing = false;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _videoError = 'Unable to load this lesson video in the app.';
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _showAddNoteDialog() async {
    final TextEditingController highlightController = TextEditingController();
    final TextEditingController commentController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Add Note • ${widget.title}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: highlightController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Highlight text',
                    hintText: 'Key idea or quote from the lesson',
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: commentController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Comment',
                    hintText: 'Your takeaway or reminder',
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                ProgressService.instance.addLessonNote(
                  userId: widget.userId,
                  lessonId: widget.lessonId,
                  highlightText: highlightController.text.trim(),
                  comment: commentController.text.trim(),
                );
                Navigator.of(dialogContext).pop();
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTimestampDialog() async {
    final TextEditingController labelController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final int seconds = _videoController?.value.position.inSeconds ?? 0;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Save Timestamp • ${_formatDuration(seconds)}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'What happens at this point?',
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                ProgressService.instance.addVideoTimestamp(
                  userId: widget.userId,
                  lessonId: widget.lessonId,
                  seconds: seconds,
                  label: labelController.text.trim(),
                );
                Navigator.of(dialogContext).pop();
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openVideoExternally() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await LinkService.instance.openExternal(widget.videoUrl);
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open this lesson video')),
      );
    }
  }

  String _formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${_twoDigits(duration.inHours)}:${_twoDigits(duration.inMinutes.remainder(60))}:${_twoDigits(duration.inSeconds.remainder(60))}';
    }
    return '${_twoDigits(duration.inMinutes)}:${_twoDigits(duration.inSeconds.remainder(60))}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final ProgressService progressService = ProgressService.instance;
    final bool completed = progressService.getProgress(
      widget.userId,
    ).completedLessonIds.contains(widget.lessonId);
    final bool bookmarked = progressService.isLessonBookmarked(
      userId: widget.userId,
      lessonId: widget.lessonId,
    );
    final List<LessonNote> notes = progressService.getLessonNotes(
      userId: widget.userId,
      lessonId: widget.lessonId,
    );
    final List<VideoTimestamp> timestamps = progressService.getVideoTimestamps(
      userId: widget.userId,
      lessonId: widget.lessonId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark lesson',
            onPressed: () {
              progressService.toggleLessonBookmark(
                userId: widget.userId,
                lessonId: widget.lessonId,
              );
              setState(() {});
            },
            icon: Icon(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: Colors.black,
              child: _buildVideoPanel(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () {
                  progressService.toggleLessonComplete(
                    userId: widget.userId,
                    lessonId: widget.lessonId,
                  );
                  setState(() {});
                },
                icon: Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.play_circle_fill_rounded,
                ),
                label: Text(completed ? 'Completed' : 'Mark Complete'),
              ),
              OutlinedButton.icon(
                onPressed: _showAddNoteDialog,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Add Note'),
              ),
              OutlinedButton.icon(
                onPressed: _showAddTimestampDialog,
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Save Timestamp'),
              ),
              TextButton.icon(
                onPressed: _openVideoExternally,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Externally'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Saved Timestamps',
            emptyText: 'No timestamps saved yet.',
            child: Column(
              children: timestamps.map((VideoTimestamp item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(_formatDuration(item.seconds)),
                  ),
                  title: Text(item.label),
                  subtitle: Text(item.createdAt.toLocal().toString()),
                  trailing: IconButton(
                    onPressed: () {
                      progressService.removeVideoTimestamp(
                        userId: widget.userId,
                        lessonId: widget.lessonId,
                        timestampId: item.id,
                      );
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Lesson Notes',
            emptyText: 'No notes added yet.',
            child: Column(
              children: notes.map((LessonNote note) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(note.highlightText),
                  subtitle: Text(note.comment),
                  trailing: IconButton(
                    onPressed: () {
                      progressService.removeLessonNote(
                        userId: widget.userId,
                        lessonId: widget.lessonId,
                        noteId: note.id,
                      );
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPanel() {
    if (_initializing) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_chewieController != null && _videoController != null) {
      final double aspectRatio = _videoController!.value.aspectRatio == 0
          ? 16 / 9
          : _videoController!.value.aspectRatio;
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white70,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                _videoError ?? 'Video unavailable',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.emptyText,
    required this.child,
  });

  final String title;
  final String emptyText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Column? column = child as Column?;
    final bool isEmpty = column != null && column.children.isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (isEmpty)
              Text(
                emptyText,
                style: TextStyle(color: Theme.of(context).hintColor),
              )
            else
              child,
          ],
        ),
      ),
    );
  }
}
