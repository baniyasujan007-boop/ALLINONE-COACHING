import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'login_screen.dart';
import 'profile_detail_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _profileImage = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _initialized = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _profileImage.dispose();
    super.dispose();
  }

  void _initFromState(AppState appState) {
    if (_initialized) {
      return;
    }
    final user = AuthService.instance.currentSession?.user;
    _name.text = user?.name ?? appState.userName;
    _email.text = user?.email ?? '';
    _phone.text = user?.phone ?? '';
    _address.text = user?.address ?? '';
    _profileImage.text = user?.profileImage ?? '';
    _initialized = true;
  }

  Future<void> _changePicture() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from device'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromDevice();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromDevice() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) {
        return;
      }

      setState(() => _uploadingImage = true);
      final bytes = await file.readAsBytes();
      final String uploadedUrl = await AuthService.instance.uploadProfileImage(
        bytes: bytes,
        filename: file.name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profileImage.text = uploadedUrl;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile image uploaded')));
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image picker plugin is not loaded. Stop app and run again.',
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
        setState(() => _uploadingImage = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final AppState appState = context.read<AppState>();
    final bool ok = await appState.updateProfile(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      address: _address.text,
      profileImage: _profileImage.text,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile updated' : appState.authError ?? 'Update failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    context.watch<ProgressService>();
    _initFromState(appState);

    final String? userId = appState.currentUser?.id;
    final Set<String> completedLessonIds = userId == null
        ? <String>{}
        : ProgressService.instance.getProgress(userId).completedLessonIds;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final int completed = appState.courses.where((course) {
      if (course.lessons.isEmpty) {
        return false;
      }
      final int doneCount = course.lessons
          .where((lesson) => completedLessonIds.contains(lesson.id))
          .length;
      return doneCount == course.lessons.length;
    }).length;
    final List<PaymentRecord> payments =
        appState.currentUser?.paymentHistory ?? <PaymentRecord>[];
    final double totalPaid = payments.fold(
      0,
      (double total, PaymentRecord item) => total + item.amount,
    );
    final String avatarUrl = _profileImage.text.trim().isNotEmpty
        ? _profileImage.text.trim()
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=400&auto=format&fit=crop';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AnimatedGradientBackground(
        dark: dark,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 46,
                          backgroundImage: NetworkImage(avatarUrl),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: AppColors.cyan,
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: _changePicture,
                              icon: const Icon(Icons.edit_rounded),
                            ),
                          ),
                        ),
                        if (_uploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        hintText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (String? value) {
                        if (value == null || !value.contains('@')) {
                          return 'Enter valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Phone number',
                        prefixIcon: Icon(Icons.call_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<AppState>(
                      builder: (BuildContext context, AppState state, _) {
                        return GradientButton(
                          label: state.authLoading
                              ? 'Saving...'
                              : 'Save Profile',
                          onPressed: state.authLoading ? () {} : _save,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _tile(
              context,
              Icons.school_rounded,
              'Completed courses',
              '$completed',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CompletedCoursesScreen(),
                ),
              ),
            ),
            _tile(
              context,
              Icons.workspace_premium_rounded,
              'Total paid',
              'Rs ${totalPaid.toStringAsFixed(0)}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TotalPaidScreen(payments: payments),
                ),
              ),
            ),
            _tile(
              context,
              Icons.receipt_long_rounded,
              'Payment history',
              '${payments.length} record${payments.length == 1 ? '' : 's'}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PaymentHistoryScreen(payments: payments),
                ),
              ),
            ),
            SwitchListTile.adaptive(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              tileColor: Theme.of(context).cardColor,
              title: const Text(
                'Dark mode',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: appState.darkMode,
              onChanged: (bool value) {
                appState.toggleTheme(value);
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                await context.read<AppState>().logout();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    {VoidCallback? onTap}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        tileColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icon, color: AppColors.cyan),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (onTap != null) ...<Widget>[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded),
            ],
          ],
        ),
      ),
    );
  }
}
