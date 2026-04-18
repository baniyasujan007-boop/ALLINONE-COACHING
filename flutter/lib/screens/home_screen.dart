import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../providers/app_state.dart';
import '../services/progress_service.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/app_logo.dart';
import '../widgets/course_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/user_avatar_button.dart';
import '../theme.dart';
import 'admin_dashboard_screen.dart';
import 'ai_doubt_solver_screen.dart';
import 'community_screen.dart';
import 'course_details_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final AppState appState = context.read<AppState>();
      if (appState.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const AdminDashboardScreen()),
        );
        return;
      }
      await appState.refreshProfile();
      if (!mounted) {
        return;
      }
      await appState.loadCourses(withDetails: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CourseItem> _filteredCourses(List<CourseItem> courses) {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return courses;
    }

    return courses.where((CourseItem course) {
      final String haystack =
          '${course.title} ${course.instructor} ${course.category} ${course.description}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

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
                    (LessonItem lesson) => completedLessonIds.contains(lesson.id),
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
    context.watch<ProgressService>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<CourseItem> filteredCourses = _coursesWithProgress(
      _filteredCourses(appState.courses),
      appState,
    );

    return Scaffold(
      appBar: GlassAppBar(
        title: 'All in One Coaching',
        titleWidget: const _BrandAppBarTitle(),
        actions: <Widget>[
          UserAvatarButton(
            user: appState.currentUser,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        dark: dark,
        child: RefreshIndicator(
          onRefresh: () async {
            await appState.refreshProfile();
            await appState.loadCourses(withDetails: true);
          },
          child: appState.coursesLoading
              ? const Center(child: CircularProgressIndicator())
              : appState.coursesError != null
              ? ListView(
                  children: <Widget>[
                    const SizedBox(height: 160),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: <Widget>[
                            Text(
                              appState.coursesError!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () =>
                                  appState.loadCourses(withDetails: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : _HomeContent(
                  appState: appState,
                  filteredCourses: filteredCourses,
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (String value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.quiz_rounded), label: 'Quiz'),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            label: 'AI Doubts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (int idx) {
          if (idx == 1) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const QuizScreen()));
          }
          if (idx == 2) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CommunityScreen(),
              ),
            );
          }
          if (idx == 3) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AiDoubtSolverScreen(),
              ),
            );
          }
          if (idx == 4) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }
}

class _BrandAppBarTitle extends StatelessWidget {
  const _BrandAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppLogo(size: 42, heroTag: 'home-brand-logo'),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: <Color>[
                    Color(0xFF6C63FF),
                    Color(0xFF4DA6FF),
                    Color(0xFFFF6EC7),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'All in One',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            Text(
              'COACHING',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.appState,
    required this.filteredCourses,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final AppState appState;
  final List<CourseItem> filteredCourses;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Hello, ${appState.userName}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What do you want to learn today?',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 18),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search courses, topics, instructors',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Need Help Fast?'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.softNeu(context),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.smart_toy_outlined, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ask AI, attach screenshot, get explanation + practice.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AiDoubtSolverScreen(),
                          ),
                        ),
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Limited-Time Offers'),
                const SizedBox(height: 12),
                _OffersSection(courses: filteredCourses),
                const SizedBox(height: 24),
                _sectionTitle('Featured Courses'),
                const SizedBox(height: 12),
                if (filteredCourses.isEmpty)
                  _EmptyState(
                    message: searchQuery.isEmpty
                        ? 'No courses available yet'
                        : 'No courses matched "$searchQuery"',
                  )
                else
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.88),
                      itemCount: filteredCourses.length,
                      itemBuilder: (BuildContext context, int index) {
                        final CourseItem course = filteredCourses[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: CourseCard(
                            course: course,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CourseDetailsScreen(course: course),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                _sectionTitle('Categories'),
                const SizedBox(height: 12),
                _CategoriesSection(courses: filteredCourses),
                const SizedBox(height: 24),
                _sectionTitle('Popular Courses'),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: filteredCourses.length,
          itemBuilder: (BuildContext context, int index) {
            final CourseItem course = filteredCourses[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: CourseCard(
                compact: true,
                course: course,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CourseDetailsScreen(course: course),
                  ),
                ),
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: AppDecorations.softNeu(context),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.insights_rounded, color: AppColors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Overall progress: ${(filteredCourses.isEmpty ? 0 : filteredCourses.map((c) => c.progress).reduce((a, b) => a + b) / filteredCourses.length * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const QuizScreen(),
                      ),
                    ),
                    child: const Text('Take Quiz'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: SizedBox(
        height: 140,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 64,
              child: Lottie.network(
                'https://assets1.lottiefiles.com/packages/lf20_mcxpx6bp.json',
                fit: BoxFit.contain,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const Icon(
                        Icons.hourglass_empty_rounded,
                        size: 34,
                      );
                    },
              ),
            ),
            const SizedBox(height: 6),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({required this.courses});

  final List<CourseItem> courses;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<CourseItem>> coursesByCategory =
        <String, List<CourseItem>>{};
    for (final CourseItem course in courses) {
      coursesByCategory.putIfAbsent(course.category, () => <CourseItem>[]).add(
        course,
      );
    }

    final List<MapEntry<String, List<CourseItem>>> categories =
        coursesByCategory.entries.toList()
          ..sort(
            (
              MapEntry<String, List<CourseItem>> a,
              MapEntry<String, List<CourseItem>> b,
            ) => b.value.length.compareTo(a.value.length),
          );

    if (categories.isEmpty) {
      return const _EmptyState(message: 'Categories will appear with courses');
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final MapEntry<String, List<CourseItem>> entry = categories[index];
          final List<CourseItem> categoryCourses = entry.value;
          final String preview = categoryCourses
              .take(2)
              .map((CourseItem course) => course.title)
              .join(' • ');

          return SizedBox(
            width: 220,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _CategoryCoursesScreen(
                      category: entry.key,
                      courses: categoryCourses,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.softNeu(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _categoryIcon(entry.key),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Theme.of(context).hintColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${categoryCourses.length} course${categoryCourses.length == 1 ? '' : 's'}',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Text(
                          preview.isEmpty
                              ? 'Fresh learning paths coming soon'
                              : preview,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Development':
        return Icons.code_rounded;
      case 'Design':
        return Icons.palette_rounded;
      case 'Marketing':
        return Icons.campaign_rounded;
      case 'Business':
        return Icons.business_center_rounded;
      case 'AI':
        return Icons.auto_awesome_rounded;
      case 'Productivity':
        return Icons.timer_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

class _OffersSection extends StatelessWidget {
  const _OffersSection({required this.courses});

  final List<CourseItem> courses;

  @override
  Widget build(BuildContext context) {
    final List<CourseItem> offerCourses =
        courses.where((CourseItem course) => course.offer.isActive).toList()
          ..sort(
            (CourseItem a, CourseItem b) =>
                a.offer.expiresAt!.compareTo(b.offer.expiresAt!),
          );

    if (offerCourses.isEmpty) {
      return const _EmptyState(message: 'No live offers right now');
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: offerCourses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final CourseItem course = offerCourses[index];
          return SizedBox(
            width: 280,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CourseDetailsScreen(course: course),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFFFFB648),
                        Color(0xFFFF7A59),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'OFFER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          course.offer.title.isEmpty
                              ? course.title
                              : course.offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Starts at Rs ${course.offer.pricing.lowest.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Was Rs ${(course.pricing.lowest > 0 ? course.pricing.lowest : course.price).toStringAsFixed(0)} • ${_offerCountdown(course.offer.expiresAt!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _offerCountdown(DateTime expiresAt) {
    final Duration remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Expired';
    }
    if (remaining.inDays >= 1) {
      return '${remaining.inDays}d ${remaining.inHours.remainder(24)}h left';
    }
    if (remaining.inHours >= 1) {
      return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left';
    }
    return '${remaining.inMinutes}m left';
  }
}

class _CategoryCoursesScreen extends StatelessWidget {
  const _CategoryCoursesScreen({
    required this.category,
    required this.courses,
  });

  final String category;
  final List<CourseItem> courses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: courses.isEmpty
          ? const Center(child: Text('No courses in this category yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: courses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (BuildContext context, int index) {
                final CourseItem course = courses[index];
                return CourseCard(
                  compact: true,
                  course: course,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CourseDetailsScreen(course: course),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
