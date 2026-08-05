import 'package:flutter/material.dart';

import 'privacy_policy_page.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget paragraph(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, height: 1.6));
  }

  Widget bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms & Conditions")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Terms & Conditions",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Please read these Terms & Conditions carefully before using AllInOne Coaching.",
                  style: TextStyle(fontSize: 17),
                ),

                const SizedBox(height: 8),

                Text(
                  "Last Updated: August 5, 2026",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),

                const SizedBox(height: 35),

                sectionTitle("1. Introduction"),

                paragraph(
                  "Welcome to AllInOne Coaching developed by SoftwareBhatti. "
                  "These Terms & Conditions govern your access to and use of the application. "
                  "By creating an account or using the application, you agree to comply with these terms.",
                ),

                sectionTitle("2. User Accounts"),

                paragraph(
                  "Users are responsible for maintaining the security of their account and keeping their information accurate.",
                ),

                const SizedBox(height: 12),

                bullet("Keep login credentials secure."),
                bullet("Provide accurate personal information."),
                bullet("Update profile information when necessary."),
                bullet("Do not share your account with others."),

                sectionTitle("3. Acceptable Use"),

                paragraph("While using AllInOne Coaching you agree not to:"),

                const SizedBox(height: 12),

                bullet("Violate any applicable laws."),
                bullet("Upload malicious software."),
                bullet("Attempt unauthorized access."),
                bullet("Abuse community features."),
                bullet("Harass or threaten other users."),
                bullet("Post illegal or offensive content."),

                sectionTitle("4. Courses & Learning"),

                paragraph(
                  "Purchased courses are intended solely for your personal educational use.",
                ),

                const SizedBox(height: 12),

                bullet("Access enrolled courses."),
                bullet("Track learning progress."),
                bullet("Complete lessons."),
                bullet("Take quizzes."),
                bullet("Download only where permitted."),

                paragraph(
                  "Redistribution, copying, recording or resale of course content is strictly prohibited.",
                ),
                sectionTitle("5. Community Guidelines"),

                paragraph(
                  "All users are expected to maintain a respectful and positive learning environment while participating in the community.",
                ),

                const SizedBox(height: 12),

                bullet("Respect other members."),
                bullet("Do not upload illegal or offensive content."),
                bullet("Do not spam or advertise unauthorized services."),
                bullet("Do not impersonate another person."),
                bullet(
                  "Do not upload copyrighted material without permission.",
                ),

                paragraph(
                  "SoftwareBhatti reserves the right to remove content or suspend accounts that violate these community guidelines.",
                ),

                sectionTitle("6. AI Feature"),

                paragraph(
                  "The AI feature within AllInOne Coaching is designed solely to assist learning by answering educational questions and explaining concepts.",
                ),

                const SizedBox(height: 12),

                bullet("AI responses may not always be accurate."),
                bullet("Responses should be independently verified."),
                bullet("AI should not replace professional advice."),
                bullet("Conversations are not permanently stored."),

                sectionTitle("7. Payments"),

                paragraph(
                  "The current version of AllInOne Coaching uses a demo payment system for testing purposes. Future versions may integrate secure third-party payment providers.",
                ),

                sectionTitle("8. Intellectual Property"),

                paragraph(
                  "Unless otherwise stated, all content available in AllInOne Coaching is owned by SoftwareBhatti.",
                ),

                const SizedBox(height: 12),

                bullet("Application design"),
                bullet("Logos"),
                bullet("Graphics"),
                bullet("Icons"),
                bullet("Course materials"),
                bullet("Videos"),
                bullet("Quizzes"),
                bullet("Source code"),
                bullet("Brand assets"),

                paragraph(
                  "Users may not reproduce, modify, distribute or sell any part of the application without prior written permission.",
                ),

                sectionTitle("9. Limitation of Liability"),

                paragraph(
                  "SoftwareBhatti shall not be responsible for any direct, indirect, incidental or consequential damages arising from the use or inability to use the application.",
                ),

                const SizedBox(height: 12),

                bullet("Loss of data"),
                bullet("Service interruptions"),
                bullet("Internet connectivity issues"),
                bullet("Device compatibility issues"),
                bullet("Decisions made based on AI-generated responses"),

                sectionTitle("10. Account Suspension & Termination"),

                paragraph(
                  "SoftwareBhatti reserves the right to suspend or permanently terminate user accounts that violate these Terms & Conditions.",
                ),

                const SizedBox(height: 12),

                bullet("Fraudulent activity"),
                bullet("Policy violations"),
                bullet("Illegal activities"),
                bullet("Community abuse"),
                bullet("Unauthorized access attempts"),
                bullet("Repeated misconduct"),
                sectionTitle("11. Privacy"),

                paragraph(
                  "Your use of AllInOne Coaching is also governed by our Privacy Policy. "
                  "The Privacy Policy explains how we collect, use, store and protect your personal information.",
                ),

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text("View Privacy Policy"),
                ),

                sectionTitle("12. Changes to These Terms"),

                paragraph(
                  "SoftwareBhatti reserves the right to modify or update these Terms & Conditions at any time. "
                  "Changes become effective immediately after they are published within the application. "
                  "Continued use of the application after any changes constitutes acceptance of the revised Terms.",
                ),

                sectionTitle("13. Governing Law"),

                paragraph(
                  "These Terms & Conditions shall be governed and interpreted in accordance with the applicable laws "
                  "of the country in which SoftwareBhatti operates.",
                ),

                sectionTitle("14. Contact Us"),

                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.business),
                            SizedBox(width: 10),
                            Text(
                              "Developer",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        SelectableText(
                          "SoftwareBhatti",
                          style: TextStyle(fontSize: 16),
                        ),

                        SizedBox(height: 10),

                        SelectableText(
                          "https://softwarebhatti.vercel.app",
                          style: TextStyle(fontSize: 16),
                        ),

                        SizedBox(height: 10),

                        SelectableText(
                          "softwarebhatti1@gmail.com",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                const Divider(),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    "© 2026 SoftwareBhatti\nAll Rights Reserved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
