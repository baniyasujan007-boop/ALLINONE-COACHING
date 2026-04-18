import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/course_model.dart';
import '../services/link_service.dart';
import '../widgets/gradient_button.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    required this.courseTitle,
    required this.lesson,
    super.key,
  });

  final String courseTitle;
  final LessonItem lesson;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.lesson.videoUrl),
    );
    _init();
  }

  Future<void> _init() async {
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: false,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF6C63FF),
        handleColor: const Color(0xFFFF6EC7),
        backgroundColor: Colors.grey.withValues(alpha: 0.35),
        bufferedColor: const Color(0xFF4DA6FF),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _chewieController == null
                ? Container(
                    height: 220,
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.lesson.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lesson.description,
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Download Notes (PDF)',
            icon: Icons.download_rounded,
            onPressed: () async {
              final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                context,
              );
              try {
                await LinkService.instance.openExternal(widget.lesson.notesUrl);
              } catch (_) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Unable to open/download notes'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Next Lesson'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
