import 'package:flutter/material.dart';

import '../../widgets/legal/legal_header.dart';
import '../../widgets/legal/legal_section.dart';
import '../../services/auth_service.dart';
import '../../screens/login_screen.dart';

/// Instructions for requesting permanent account deletion.
class AccountDeletionPage extends StatelessWidget {
  const AccountDeletionPage({super.key});

  static const String routeName = '/account-deletion';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AllInOne Coaching')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Home  /  Legal  /  Delete Your Account',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                const LegalHeader(
                  title: 'Delete Your Account',
                  description:
                      'How to request permanent deletion of your AllInOne Coaching account and personal information.',
                  icon: Icons.person_remove_outlined,
                ),
                const SizedBox(height: 22),
                _section(
                  'Overview',
                  Icons.info_outline,
                  const Text(
                    'You can request permanent deletion of your AllInOne Coaching account at any time. After your request is verified and processed, you will no longer be able to access the deleted account.',
                  ),
                ),
                _section(
                  'Data that will be deleted',
                  Icons.delete_sweep_outlined,
                  const Text(
                    'When your deletion request is completed, we will delete the following information from active systems where applicable.',
                  ),
                  items: const <String>[
                    'Name',
                    'Email address',
                    'Phone number',
                    'Address',
                    'Profile picture',
                    'Course progress',
                    'Quiz scores',
                    'Community posts and comments',
                    'Uploaded images',
                    'Purchased course records, where legally permitted',
                  ],
                ),
                _section(
                  'Data that may be retained',
                  Icons.history_outlined,
                  const Text(
                    'Some information may be retained where necessary for legal obligations, fraud prevention, dispute resolution, enforcement of our agreements, or other legal compliance requirements. Retained information is handled securely and only for the required purpose.',
                  ),
                ),
                _section(
                  'How to request deletion',
                  Icons.mark_email_read_outlined,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Press the Delete My Account button below to permanently remove your account and associated data. This action cannot be undone.',
                      ),
                      const SizedBox(height: 14),
                      const _BulletList(
                        items: <String>[
                          'Registered email address',
                          'Full name',
                          'Reason (optional)',
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 55),
                        ),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text("Delete My Account"),
                        onPressed: () async {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Account"),
                              content: const Text(
                                "This action is permanent.\n\n"
                                "Your account, profile, learning progress, community posts, quiz scores and other personal data will be permanently deleted.\n\n"
                                "This action cannot be undone.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true || !context.mounted) return;

                          // Show loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // Delete account
                          final String? error = await AuthService.instance
                              .deleteAccount();

                          if (!context.mounted) return;

                          // Close loading dialog
                          Navigator.pop(context);

                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                            return;
                          }

                          // Success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Your account has been deleted successfully.",
                              ),
                            ),
                          );

                          // Go back to login
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _section(
                  'Processing time',
                  Icons.schedule_outlined,
                  const Text(
                    'Deletion requests are normally processed within 7 business days after identity verification. We may contact you if we need additional information to verify the request.',
                  ),
                ),
                _section(
                  'Contact',
                  Icons.contact_mail_outlined,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Developer\nSoftwareBhatti'),
                      const SizedBox(height: 10),
                      SelectableText(
                        'https://softwarebhatti.vercel.app',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        'softwarebhatti1@gmail.com',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(
    String title,
    IconData icon,
    Widget child, {
    List<String> items = const <String>[],
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: LegalSection(
      sectionKey: GlobalKey(),
      title: title,
      icon: icon,
      items: items,
      child: child,
    ),
  );
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map(
          (String item) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('•  '),
                Expanded(child: Text(item)),
              ],
            ),
          ),
        )
        .toList(),
  );
}
