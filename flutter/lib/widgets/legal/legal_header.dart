import 'package:flutter/material.dart';

/// Shared hero area used by every public legal page.
class LegalHeader extends StatelessWidget {
  const LegalHeader({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.lastUpdated,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.primary, colors.primaryContainer],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.onPrimary, size: 28),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onPrimary.withValues(alpha: .9),
              height: 1.55,
            ),
          ),
          if (lastUpdated != null) ...<Widget>[
            const SizedBox(height: 20),
            Text(
              'Last updated: $lastUpdated',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onPrimary.withValues(alpha: .88),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
