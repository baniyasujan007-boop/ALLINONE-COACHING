import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/course.dart';
import '../../providers/app_state.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/link_service.dart';
import '../../services/progress_service.dart';
import 'lesson_video_page.dart';

class CourseDetailsPage extends StatefulWidget {
  const CourseDetailsPage({
    super.key,
    required this.userId,
    required this.courseId,
  });

  final String userId;
  final String courseId;

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await CourseService.instance.hydrateCourseDetails(widget.courseId);
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  bool _canAccessCourse(Course course) {
    final AppUser? user = AuthService.instance.currentSession?.user;
    if (user == null) {
      return false;
    }
    if (user.role == UserRole.admin) {
      return true;
    }
    if (!course.isLocked) {
      return true;
    }
    return user.enrolledCourses.any(
      (PurchasedCourse c) => c.id == course.id && c.hasActiveAccess,
    );
  }

  Future<void> _purchaseCourse(Course course) async {
    final AppState appState = context.read<AppState>();
    final bool ok = await appState.purchaseCourse(
      course.id,
      paymentMethod: 'upi',
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Payment successful. Course unlocked for 1 month.'
              : appState.authError ?? 'Payment failed',
        ),
      ),
    );
    if (ok) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    final Course? course = CourseService.instance.getCourseById(
      widget.courseId,
    );
    if (_loading && course == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && course == null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: const Center(child: Text('Course not found')),
      );
    }
    final progress = ProgressService.instance.getProgress(widget.userId);
    final bool canAccess = _canAccessCourse(course);
    final bool needsRenewal = appState.hasExpiredCourseAccess(course.id);
    final int doneLessons = course.lessons
        .where((VideoLesson l) => progress.completedLessonIds.contains(l.id))
        .length;
    final double progressValue = course.lessons.isEmpty
        ? 0
        : doneLessons / course.lessons.length;

    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            /// COURSE IMAGE + PROGRESS
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            child: Image.network(
                              course.thumbnailUrl,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              width: double.infinity,
                              errorBuilder: (_, _, _) => Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Progress",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),

                        const SizedBox(height: 8),

                        LinearProgressIndicator(value: progressValue),

                        const SizedBox(height: 6),

                        Text(
                          "$doneLessons / ${course.lessons.length} lessons completed",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  /// DESCRIPTION
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(course.description),
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// VIDEO LECTURES
                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Text("Video Lectures (${course.lessons.length})"),
                      children: course.lessons.map((lesson) {
                        final completed = progress.completedLessonIds.contains(
                          lesson.id,
                        );

                        final bookmarked = progress.bookmarkedLessonIds
                            .contains(lesson.id);

                        final noteCount = ProgressService.instance
                            .getLessonNotes(
                              userId: widget.userId,
                              lessonId: lesson.id,
                            )
                            .length;

                        final timestampCount = ProgressService.instance
                            .getVideoTimestamps(
                              userId: widget.userId,
                              lessonId: lesson.id,
                            )
                            .length;

                        return ListTile(
                          enabled: canAccess,
                          title: Text(lesson.title),
                          subtitle: Text(
                            "${lesson.durationMinutes} min • $noteCount notes • $timestampCount timestamps",
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              IconButton(
                                icon: Icon(
                                  bookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                ),
                                onPressed: !canAccess
                                    ? null
                                    : () {
                                        ProgressService.instance
                                            .toggleLessonBookmark(
                                              userId: widget.userId,
                                              lessonId: lesson.id,
                                            );
                                        setState(() {});
                                      },
                              ),

                              TextButton(
                                onPressed: !canAccess
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LessonVideoPage(
                                              userId: widget.userId,
                                              lessonId: lesson.id,
                                              title: lesson.title,
                                              videoUrl: lesson.videoUrl,
                                            ),
                                          ),
                                        ).then((_) => setState(() {}));
                                      },
                                child: const Text("Watch"),
                              ),

                              TextButton(
                                onPressed: !canAccess
                                    ? null
                                    : () {
                                        ProgressService.instance
                                            .markLessonComplete(
                                              userId: widget.userId,
                                              lessonId: lesson.id,
                                            );
                                        setState(() {});
                                      },
                                child: Text(completed ? "Done" : "Complete"),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// PDF NOTES
                  Card(
                    child: ExpansionTile(
                      title: Text(
                        "PDF Notes (${course.studyMaterials.length})",
                      ),
                      children: course.studyMaterials.map((material) {
                        return ListTile(
                          enabled: canAccess,
                          title: Text(material.title),
                          subtitle: Text(material.pdfUrl),
                          trailing: TextButton(
                            onPressed: !canAccess
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );

                                    try {
                                      await LinkService.instance.openExternal(
                                        material.pdfUrl,
                                      );
                                    } catch (_) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Unable to open/download this PDF",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: const Text("Download"),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!canAccess)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              needsRenewal
                                  ? 'Your access has expired'
                                  : 'Pay first to unlock this course',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              needsRenewal
                                  ? 'Renew your plan to continue watching lessons and downloading PDF notes.'
                                  : 'After payment, you can watch all lessons and download all PDF notes.',
                            ),
                            if (course.price > 0) ...<Widget>[
                              const SizedBox(height: 8),
                              const Text(
                                'Monthly payment unlocks this course for 1 month. Renew after expiry to keep access.',
                              ),
                            ],
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: appState.authLoading
                                  ? null
                                  : () => _purchaseCourse(course),
                              icon: const Icon(Icons.payments_rounded),
                              label: Text(
                                course.price > 0
                                    ? '${needsRenewal ? 'Renew' : 'Pay'} Rs ${course.price.toStringAsFixed(0)}'
                                    : 'Unlock Course',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
