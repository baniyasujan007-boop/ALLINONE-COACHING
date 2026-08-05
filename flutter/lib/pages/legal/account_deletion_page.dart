import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/legal/legal_header.dart';
import '../../widgets/legal/legal_section.dart';

/// Instructions for requesting permanent account deletion.
class AccountDeletionPage extends StatelessWidget {
  const AccountDeletionPage({super.key});

  static const String routeName = '/account-deletion';

  Future<void> _emailSupport(BuildContext context) async {
    final Uri email = Uri(
      scheme: 'mailto',
      path: 'softwarebhatti1@gmail.com',
      queryParameters: <String, String>{'subject': 'Account Deletion Request'},
    );
    if (!await launchUrl(email) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open your email app.')),
      );
    }
  }

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
                        'Email softwarebhatti1@gmail.com with the subject “Account Deletion Request”. Please include the following details so we can verify your identity:',
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
                        onPressed: () => _emailSupport(context),
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Email Deletion Request'),
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
