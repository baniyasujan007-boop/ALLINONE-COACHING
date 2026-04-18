import 'package:flutter/material.dart';

import '../../models/admin_user.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_gradient_background.dart';
import '../../widgets/glass_card.dart';

class AdminCourseAccessPage extends StatefulWidget {
  const AdminCourseAccessPage({super.key, required this.course});

  final Course course;

  @override
  State<AdminCourseAccessPage> createState() => _AdminCourseAccessPageState();
}

class _AdminCourseAccessPageState extends State<AdminCourseAccessPage> {
  bool _loading = false;
  String? _error;
  List<AdminUser> _users = <AdminUser>[];
  final Set<String> _savingUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<AdminUser> users = await AuthService.instance
          .getUsersForAdmin();
      if (!mounted) {
        return;
      }
      setState(() {
        _users = users
            .where((AdminUser user) => user.role == 'student')
            .toList();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  bool _hasAccess(AdminUser user) {
    return user.purchasedPackages.any(
      (AdminPurchasedPackage pkg) => pkg.id == widget.course.id,
    );
  }

  Future<void> _toggleAccess(AdminUser user, bool allow) async {
    setState(() {
      _savingUserIds.add(user.id);
    });

    final Set<String> enrolledCourseIds = user.purchasedPackages
        .map((AdminPurchasedPackage pkg) => pkg.id)
        .toSet();
    if (allow) {
      enrolledCourseIds.add(widget.course.id);
    } else {
      enrolledCourseIds.remove(widget.course.id);
    }

    try {
      final AdminUser updated = await AuthService.instance.updateUserByAdmin(
        userId: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        address: user.address,
        profileImage: user.profileImage,
        enrolledCourseIds: enrolledCourseIds.toList(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final int index = _users.indexWhere(
          (AdminUser item) => item.id == user.id,
        );
        if (index >= 0) {
          _users[index] = updated;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allow
                ? 'Access granted to ${user.name}'
                : 'Access removed from ${user.name}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _savingUserIds.remove(user.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Course Access')),
      body: AnimatedGradientBackground(
        dark: dark,
        child: RefreshIndicator(
          onRefresh: _loadUsers,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ListView(
                  children: <Widget>[
                    const SizedBox(height: 160),
                    Center(child: Text(_error!)),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.course.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.course.isLocked
                                ? 'This course is locked. Grant access to subscribed students below.'
                                : 'This course is open, but you can still pre-assign student access here.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_users.isEmpty)
                      const GlassCard(child: Text('No students found.'))
                    else
                      ..._users.map((AdminUser user) {
                        final bool hasAccess = _hasAccess(user);
                        final bool saving = _savingUserIds.contains(user.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: Row(
                              children: <Widget>[
                                CircleAvatar(
                                  backgroundImage:
                                      user.profileImage.trim().isNotEmpty
                                      ? NetworkImage(user.profileImage)
                                      : null,
                                  child: user.profileImage.trim().isEmpty
                                      ? Text(
                                          user.name.isEmpty
                                              ? 'U'
                                              : user.name
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(user.email),
                                    ],
                                  ),
                                ),
                                if (saving)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Switch(
                                    value: hasAccess,
                                    onChanged: (bool value) {
                                      _toggleAccess(user, value);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}
