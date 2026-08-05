import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/legal/legal_header.dart';
import '../../widgets/legal/legal_section.dart';

/// Public privacy notice for AllInOne Coaching.
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  static const String routeName = '/privacy-policy';

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final Map<String, GlobalKey> _sections = <String, GlobalKey>{
    for (final String name in _sectionNames) name: GlobalKey(),
  };

  static const List<String> _sectionNames = <String>[
    'Introduction',
    'Information we collect',
    'How we use information',
    'Google Sign-In',
    'AI feature',
    'Advertising',
    'File access',
    'Data sharing',
    "Children's privacy",
    'Data security',
    'Data retention',
    'Account deletion',
    'Your rights',
    'Changes to this policy',
    'Contact',
  ];

  void _scrollTo(String title) {
    final BuildContext? target = _sections[title]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool desktop = MediaQuery.sizeOf(context).width >= 1040;
    final List<Widget> content = <Widget>[
      LegalHeader(
        title: 'Privacy Policy',
        description:
            'How AllInOne Coaching collects, uses, stores, and protects your personal information.',
        icon: Icons.privacy_tip_outlined,
        lastUpdated: 'August 5, 2026',
      ),
      const SizedBox(height: 22),
      _section(
        'Introduction',
        Icons.waving_hand_outlined,
        const Text(
          'Welcome to AllInOne Coaching, developed by SoftwareBhatti. This Privacy Policy explains how we handle information when you use our learning platform.',
        ),
      ),
      _section(
        'Information we collect',
        Icons.inventory_2_outlined,
        const _CollectionDetails(),
      ),
      _section(
        'How we use information',
        Icons.lightbulb_outline,
        const Text(
          'We use information to authenticate your account, deliver courses, track learning progress, improve the user experience, provide customer support, and protect the security of our service.',
        ),
        items: const <String>[
          'Authentication and account management',
          'Course delivery and learning progress',
          'Product improvement and customer support',
          'Security, fraud prevention, and service reliability',
        ],
      ),
      _section(
        'Google Sign-In',
        Icons.login_outlined,
        const Text(
          'Google authentication is used only to help you sign in to your account. We use the information provided through Google solely to create or access your AllInOne Coaching account.',
        ),
      ),
      _section(
        'AI feature',
        Icons.auto_awesome_outlined,
        const Text(
          'AI conversations are not permanently stored. Questions are processed only to generate answers and provide learning support.',
        ),
      ),
      _section(
        'Advertising',
        Icons.ads_click_outlined,
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              const TextSpan(
                text:
                    'AllInOne Coaching uses Google AdMob. Google may collect advertising ID, device information, IP address, and ad performance data. Review Google’s privacy practices at ',
              ),
              WidgetSpan(
                child: _InlineLink(
                  label: 'policies.google.com/privacy',
                  onTap: () => _openUrl('https://policies.google.com/privacy'),
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        items: const <String>[
          'Advertising ID',
          'Device information',
          'IP address',
          'Ad performance data',
        ],
      ),
      _section(
        'File access',
        Icons.photo_library_outlined,
        const Text(
          'Gallery access is requested only when you choose to upload a profile picture. We do not access your gallery for any other purpose.',
        ),
      ),
      _section(
        'Data sharing',
        Icons.share_outlined,
        const Text(
          'We never sell your personal information. Information may be shared only with trusted service providers needed to operate the app.',
        ),
        items: const <String>[
          'Google Authentication',
          'Google AdMob',
          'Cloud hosting providers',
          'Database providers',
        ],
      ),
      _section(
        "Children's privacy",
        Icons.child_care_outlined,
        const Text(
          'AllInOne Coaching is intended for everyone. If you believe a child has provided personal information without appropriate consent, please contact us so we can review and address the request.',
        ),
      ),
      _section(
        'Data security',
        Icons.shield_outlined,
        const Text(
          'We use reasonable administrative, technical, and organizational safeguards to protect information. No method of transmission or storage is completely secure, so we cannot guarantee absolute security.',
        ),
      ),
      _section(
        'Data retention',
        Icons.history_outlined,
        const Text(
          'We retain information only for as long as needed to provide the service, meet the purposes described here, and comply with legal obligations.',
        ),
      ),
      _section(
        'Account deletion',
        Icons.delete_outline,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'You may request deletion of your account and associated personal information at any time.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/account-deletion'),
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Delete My Account'),
            ),
          ],
        ),
      ),
      _section(
        'Your rights',
        Icons.gpp_good_outlined,
        const Text(
          'Subject to applicable law, you may access your data, correct inaccurate data, and request deletion of your account or personal information.',
        ),
      ),
      _section(
        'Changes to this policy',
        Icons.update_outlined,
        const Text(
          'We may update this Privacy Policy from time to time. We will post the updated version here and revise the last updated date when material changes are made.',
        ),
      ),
      _section(
        'Contact',
        Icons.contact_mail_outlined,
        _ContactDetails(onOpenUrl: _openUrl),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AllInOne Coaching'),
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Breadcrumbs(current: 'Privacy Policy'),
                  const SizedBox(height: 18),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _ContentList(children: content)),
                        const SizedBox(width: 32),
                        SizedBox(
                          width: 250,
                          child: _TableOfContents(
                            items: _sectionNames,
                            onSelected: _scrollTo,
                          ),
                        ),
                      ],
                    )
                  else
                    _ContentList(children: content),
                ],
              ),
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
      sectionKey: _sections[title]!,
      title: title,
      icon: icon,
      items: items,
      child: child,
    ),
  );
}

class _ContentList extends StatelessWidget {
  const _ContentList({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.current});
  final String current;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Breadcrumb',
    child: Text(
      'Home  /  Legal  /  $current',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _TableOfContents extends StatelessWidget {
  const _TableOfContents({required this.items, required this.onSelected});
  final List<String> items;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'On this page',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (String item) => TextButton(
              onPressed: () => onSelected(item),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 5),
                alignment: Alignment.centerLeft,
              ),
              child: Text(item, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InlineLink extends StatelessWidget {
  const _InlineLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}

class _CollectionDetails extends StatelessWidget {
  const _CollectionDetails();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        'Depending on how you use the app, we may collect the following information.',
      ),
      SizedBox(height: 14),
      _CollectionGroup(
        title: 'Personal information',
        items: <String>[
          'Full name',
          'Email address',
          'Phone number',
          'Profile picture',
          'Address',
        ],
      ),
      _CollectionGroup(
        title: 'Account information',
        items: <String>['Email and password', 'Google Sign-In'],
      ),
      _CollectionGroup(
        title: 'Learning information',
        items: <String>[
          'Course progress',
          'Completed lessons',
          'Quiz scores',
          'Purchased courses',
        ],
      ),
      _CollectionGroup(
        title: 'Community information',
        items: <String>[
          'Posts',
          'Comments',
          'Likes',
          'Uploaded images',
          'Uploaded videos',
        ],
      ),
    ],
  );
}

class _CollectionGroup extends StatelessWidget {
  const _CollectionGroup({required this.title, required this.items});
  final String title;
  final List<String> items;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(items.join(' • ')),
      ],
    ),
  );
}

class _ContactDetails extends StatelessWidget {
  const _ContactDetails({required this.onOpenUrl});
  final ValueChanged<String> onOpenUrl;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text('Developer\nSoftwareBhatti'),
      const SizedBox(height: 10),
      _InlineLink(
        label: 'https://softwarebhatti.vercel.app',
        onTap: () => onOpenUrl('https://softwarebhatti.vercel.app'),
      ),
      const SizedBox(height: 8),
      _InlineLink(
        label: 'softwarebhatti1@gmail.com',
        onTap: () => onOpenUrl('mailto:softwarebhatti1@gmail.com'),
      ),
    ],
  );
}
