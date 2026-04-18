import 'dart:ui';

import 'package:flutter/material.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    required this.title,
    this.actions,
    this.titleWidget,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? titleWidget;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          title:
              titleWidget ??
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          elevation: 0,
          centerTitle: false,
          backgroundColor: dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.75),
          actions: actions,
        ),
      ),
    );
  }
}
