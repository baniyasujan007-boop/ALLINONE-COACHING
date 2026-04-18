import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/user_avatar_button.dart';
import '../pages/admin/admin_course_management_page.dart';
import 'admin_payments_screen.dart';
import 'admin_users_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadCourses(withDetails: false);
    });
  }

  Future<void> _openCourseManager() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdminCourseManagementPage(),
      ),
    );
    if (!mounted) return;
    await context.read<AppState>().loadCourses(withDetails: false);
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Admin Dashboard',
        titleWidget: const _AdminAppBarTitle(),
        actions: <Widget>[
          UserAvatarButton(
            user: appState.currentUser,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
          PopupMenuButton<_AdminMenuAction>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (_AdminMenuAction action) async {
              switch (action) {
                case _AdminMenuAction.users:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminUsersScreen(),
                    ),
                  );
                case _AdminMenuAction.courses:
                  _openCourseManager();
                case _AdminMenuAction.payments:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminPaymentsScreen(),
                    ),
                  );
                case _AdminMenuAction.logout:
                  await context.read<AppState>().logout();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                    (_) => false,
                  );
              }
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<_AdminMenuAction>>[
                  PopupMenuItem<_AdminMenuAction>(
                    value: _AdminMenuAction.users,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.groups_rounded),
                      title: Text('Users'),
                    ),
                  ),
                  PopupMenuItem<_AdminMenuAction>(
                    value: _AdminMenuAction.courses,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.add_box_rounded),
                      title: Text('Manage Courses'),
                    ),
                  ),
                  PopupMenuItem<_AdminMenuAction>(
                    value: _AdminMenuAction.payments,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.payments_rounded),
                      title: Text('Payments'),
                    ),
                  ),
                  PopupMenuItem<_AdminMenuAction>(
                    value: _AdminMenuAction.logout,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout_rounded),
                      title: Text('Logout'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Container(
        decoration: AppDecorations.gradientBg(dark: dark),
        child: RefreshIndicator(
          onRefresh: () => appState.loadCourses(withDetails: false),
          child: appState.coursesLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.softNeu(context),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Admin Controls',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text('Create and manage courses from this panel.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.softNeu(context),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.payments_rounded, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Track payments and purchased courses from one place.',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AdminPaymentsScreen(),
                              ),
                            ),
                            child: const Text('Open'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...appState.courses.map(
                      (course) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          minLeadingWidth: 50,
                          horizontalTitleGap: 12,
                          leading: Builder(
                            builder: (BuildContext context) {
                              final Uri? uri = Uri.tryParse(course.thumbnail);
                              final bool valid =
                                  uri != null &&
                                  uri.hasScheme &&
                                  uri.host.isNotEmpty;
                              return CircleAvatar(
                                radius: 22,
                                backgroundImage: valid
                                    ? NetworkImage(course.thumbnail)
                                    : null,
                                child: valid
                                    ? null
                                    : const Icon(
                                        Icons.image_not_supported,
                                        size: 20,
                                      ),
                              );
                            },
                          ),
                          title: Text(
                            course.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(course.instructor),
                          trailing: Text('${course.lessons.length} lessons'),
                        ),
                      ),
                    ),
                    if (appState.courses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No courses found.')),
                      ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCourseManager,
        icon: const Icon(Icons.add),
        label: const Text('Manage Courses'),
      ),
    );
  }
}

enum _AdminMenuAction { users, courses, payments, logout }

class _AdminAppBarTitle extends StatelessWidget {
  const _AdminAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppLogo(size: 34, heroTag: 'admin-brand-logo'),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Admin Panel',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
