import 'package:flutter/material.dart';

import 'legal_card.dart';

/// An accessible, reusable legal-document section with an optional list.
class LegalSection extends StatelessWidget {
  const LegalSection({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.icon,
    required this.child,
    this.items = const <String>[],
  });

  final GlobalKey sectionKey;
  final String title;
  final IconData icon;
  final Widget child;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Semantics(
      container: true,
      header: true,
      label: title,
      child: LegalCard(
        child: Column(
          key: sectionKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: colors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DefaultTextStyle.merge(
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
              child: child,
            ),
            if (items.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              ...items.map(
                (String item) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 17,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
