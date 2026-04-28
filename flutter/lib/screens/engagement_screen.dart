import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../models/course_model.dart';
import '../providers/app_state.dart';
import '../services/community_service.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/glass_card.dart';
import 'community_screen.dart';
import 'revision_tools_screen.dart';

class EngagementScreen extends StatelessWidget {
  const EngagementScreen({super.key});

  List<CourseItem> _coursesWithProgress(
    List<CourseItem> courses,
    AppState appState,
  ) {
    final String? userId = appState.currentUser?.id;
    if (userId == null) {
      return courses;
    }
    final Set<String> completedLessonIds = ProgressService.instance
        .getProgress(userId)
        .completedLessonIds;

    return courses.map((CourseItem course) {
      final double progress = course.lessons.isEmpty
          ? 0
          : course.lessons
                    .where(
                      (LessonItem lesson) =>
                          completedLessonIds.contains(lesson.id),
                    )
                    .length /
                course.lessons.length;
      return CourseItem(
        id: course.id,
        title: course.title,
        instructor: course.instructor,
        thumbnail: course.thumbnail,
        price: course.price,
        pricing: course.pricing,
        offer: course.offer,
        isLocked: course.isLocked,
        rating: course.rating,
        lessons: course.lessons,
        progress: progress,
        description: course.description,
        category: course.category,
        quiz: course.quiz,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<CourseItem> courses = _coursesWithProgress(
      appState.courses,
      appState,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Engagement')),
      body: AnimatedGradientBackground(
        dark: dark,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _EngagementFeaturesSection(appState: appState, courses: courses),
          ],
        ),
      ),
    );
  }
}

class _EngagementFeaturesSection extends StatelessWidget {
  const _EngagementFeaturesSection({
    required this.appState,
    required this.courses,
  });

  final AppState appState;
  final List<CourseItem> courses;

  @override
  Widget build(BuildContext context) {
    final CommunityService community = context.watch<CommunityService>();
    final int completedLessons = courses.fold<int>(
      0,
      (int sum, CourseItem course) =>
          sum + (course.progress * course.lessons.length).round(),
    );
    final int completedCourses = courses.where((CourseItem c) {
      return c.lessons.isNotEmpty && c.progress >= 0.999;
    }).length;
    final int totalPoints =
        (completedLessons * 15) +
        (completedCourses * 120) +
        (appState.streakCount * 20);
    final int totalReplies = community.posts.fold<int>(
      0,
      (int total, CommunityPost post) => total + post.answers.length,
    );
    final List<String> badges = <String>[
      if (completedLessons >= 3) 'Fast Starter',
      if (completedLessons >= 10) 'Lesson Finisher',
      if (completedCourses >= 1) 'Course Climber',
      if (appState.streakCount >= 3) '3-Day Streak',
      if (appState.streakCount >= 7) 'Consistency Star',
    ];
    final List<_EngagementAction> actions = <_EngagementAction>[
      _EngagementAction(
        icon: Icons.notifications_active_outlined,
        title: 'Daily reminders',
        subtitle: appState.dailyRemindersEnabled
            ? 'Daily notification scheduled for ${_formatReminderHour(appState.reminderHour)}'
            : 'Turn reminders on to build a daily study habit',
        accent: AppColors.orange,
        trailing: Switch.adaptive(
          value: appState.dailyRemindersEnabled,
          onChanged: (bool value) async {
            try {
              await appState.toggleDailyReminders(value);
            } catch (error) {
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error.toString())));
            }
          },
        ),
        onTap: () async {
          final int? hour = await _pickReminderHour(
            context,
            appState.reminderHour,
          );
          if (hour != null) {
            try {
              await appState.updateReminderHour(hour);
            } catch (error) {
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error.toString())));
            }
          }
        },
      ),
      _EngagementAction(
        icon: Icons.forum_rounded,
        title: 'Discussion forum',
        subtitle: community.loading
            ? 'Loading real community activity...'
            : community.error != null
            ? 'Forum available, but activity could not be refreshed right now'
            : community.posts.isEmpty
            ? 'No live discussions yet. Start the first real conversation.'
            : '${community.posts.length} live discussions and $totalReplies real replies from students',
        accent: AppColors.cyan,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CommunityScreen()),
          );
        },
      ),
      _EngagementAction(
        icon: Icons.auto_stories_rounded,
        title: 'Flashcards and short notes',
        subtitle: 'Revise course concepts quickly before quizzes',
        accent: AppColors.green,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RevisionToolsScreen(
                courses: courses,
                userId: appState.currentUser?.id,
              ),
            ),
          );
        },
      ),
    ];

    return Column(
      children: <Widget>[
        GlassCard(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  _StatChip(
                    label: 'Points',
                    value: '$totalPoints',
                    color: AppColors.orange,
                    icon: Icons.bolt_rounded,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Badges',
                    value: '${badges.length}',
                    color: AppColors.cyan,
                    icon: Icons.workspace_premium_rounded,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Streak',
                    value: '${appState.streakCount}d',
                    color: AppColors.green,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  badges.isEmpty
                      ? 'Complete lessons, keep your streak alive, and unlock badges.'
                      : 'Unlocked: ${badges.join(' • ')}',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...actions.map((_EngagementAction action) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: action.onTap,
              borderRadius: BorderRadius.circular(20),
              child: GlassCard(
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: action.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(action.icon, color: action.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            action.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action.subtitle,
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    action.trailing ??
                        const Icon(Icons.chevron_right_rounded, size: 28),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  static String _formatReminderHour(int hour) {
    final int normalized = hour % 24;
    final bool isPm = normalized >= 12;
    final int displayHour = normalized == 0
        ? 12
        : normalized > 12
        ? normalized - 12
        : normalized;
    final String suffix = isPm ? 'PM' : 'AM';
    return '$displayHour:00 $suffix';
  }

  static Future<int?> _pickReminderHour(BuildContext context, int current) {
    return showModalBottomSheet<int>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 24,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                selected: index == current,
                leading: const Icon(Icons.schedule_rounded),
                title: Text(_formatReminderHour(index)),
                onTap: () => Navigator.of(context).pop(index),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EngagementAction {
  const _EngagementAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;
  final Widget? trailing;
}
