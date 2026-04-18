import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/admin_user.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/glass_card.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = false;
  String? _error;
  List<AdminUser> _users = <AdminUser>[];
  List<Course> _courses = <Course>[];

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
      await CourseService.instance.refreshCourses();
      final List<AdminUser> users = await AuthService.instance
          .getUsersForAdmin();
      if (!mounted) {
        return;
      }
      setState(() {
        _users = users;
        _courses = CourseService.instance.getCourses();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _editUser(AdminUser user) async {
    final TextEditingController name = TextEditingController(text: user.name);
    final TextEditingController email = TextEditingController(text: user.email);
    final TextEditingController phone = TextEditingController(text: user.phone);
    final TextEditingController address = TextEditingController(
      text: user.address,
    );
    final TextEditingController profileImage = TextEditingController(
      text: user.profileImage,
    );
    String role = user.role;
    final Set<String> enrolledCourseIds = user.purchasedPackages
        .map((AdminPurchasedPackage pkg) => pkg.id)
        .toSet();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Edit User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('student'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('admin')),
                      ],
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() => role = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: address,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: profileImage,
                      decoration: const InputDecoration(
                        labelText: 'Profile image URL',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Course Access',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_courses.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No courses available yet.'),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _courses.map((Course course) {
                          final bool selected = enrolledCourseIds.contains(
                            course.id,
                          );
                          final double displayPrice = course.offer.isActive
                              ? (course.offer.pricing.lowest > 0
                                    ? course.offer.pricing.lowest
                                    : course.price)
                              : (course.pricing.lowest > 0
                                    ? course.pricing.lowest
                                    : course.price);
                          final String priceLabel = displayPrice <= 0
                              ? 'Free'
                              : 'Rs ${displayPrice.toStringAsFixed(0)}';
                          final String label = course.isLocked
                              ? '${course.title} • $priceLabel • Locked'
                              : '${course.title} • $priceLabel • Open';
                          return FilterChip(
                            selected: selected,
                            label: Text(label),
                            onSelected: (bool value) {
                              setModalState(() {
                                if (value) {
                                  enrolledCourseIds.add(course.id);
                                } else {
                                  enrolledCourseIds.remove(course.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      await AuthService.instance.updateUserByAdmin(
                        userId: user.id,
                        name: name.text,
                        email: email.text,
                        role: role,
                        phone: phone.text,
                        address: address.text,
                        profileImage: profileImage.text,
                        enrolledCourseIds: enrolledCourseIds.toList(),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      await _loadUsers();
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    name.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    profileImage.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: AnimatedGradientBackground(
        dark: dark,
        child: RefreshIndicator(
          onRefresh: _loadUsers,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ListView(
                  children: <Widget>[
                    const SizedBox(height: 180),
                    Center(child: Text(_error!)),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (BuildContext context, int index) {
                    final AdminUser user = _users[index];
                    final String avatar = user.profileImage.isEmpty
                        ? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=400&auto=format&fit=crop'
                        : user.profileImage;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(avatar),
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
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(user.email),
                                    ],
                                  ),
                                ),
                                FilledButton.tonal(
                                  onPressed: () => _editUser(user),
                                  child: const Text('Edit'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                Chip(label: Text('Role: ${user.role}')),
                                Chip(
                                  label: Text(
                                    'Packages: ${user.purchasedPackages.length}',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    'Spent: ${user.totalSpent.toStringAsFixed(2)}',
                                  ),
                                ),
                              ],
                            ),
                            if (user.phone.isNotEmpty ||
                                user.address.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  [
                                    if (user.phone.isNotEmpty)
                                      'Phone: ${user.phone}',
                                    if (user.address.isNotEmpty)
                                      'Address: ${user.address}',
                                  ].join('  •  '),
                                ),
                              ),
                            if (user.purchasedPackages.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'Packages Bought',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...user.purchasedPackages.map(
                                      (pkg) => Text(
                                        '• ${pkg.title} (₹${pkg.price.toStringAsFixed(2)})',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
