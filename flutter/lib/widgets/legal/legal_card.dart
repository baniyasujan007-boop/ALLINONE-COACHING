import 'package:flutter/material.dart';

/// A consistently styled surface for legal page content.
class LegalCard extends StatelessWidget {
  const LegalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: .65),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }
}
