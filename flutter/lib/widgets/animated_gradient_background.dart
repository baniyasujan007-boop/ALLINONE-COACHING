import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    required this.child,
    this.dark = false,
    super.key,
  });

  final Widget child;
  final bool dark;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> get _a => widget.dark
      ? const <Color>[Color(0xFF121225), Color(0xFF211B46), Color(0xFF301F4F)]
      : const <Color>[Color(0xFFF4F7FF), Color(0xFFF8F1FF), Color(0xFFFFF2FB)];

  List<Color> get _b => widget.dark
      ? const <Color>[Color(0xFF171739), Color(0xFF2C1F54), Color(0xFF1B1A3D)]
      : const <Color>[Color(0xFFEFF4FF), Color(0xFFF2F8FF), Color(0xFFFFEFF8)];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final Widget content = child ?? const SizedBox.shrink();
        final double t = Curves.easeInOut.transform(_controller.value);
        final List<Color> colors = List<Color>.generate(3, (int i) {
          return Color.lerp(_a[i], _b[i], t) ?? AppColors.primaryGradient[i];
        });

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + (t * 0.8), -1),
              end: Alignment(1, 1 - (t * 0.8)),
              colors: colors,
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -80,
                right: -40,
                child: _GlowOrb(
                  color: AppColors.purple.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -60,
                child: _GlowOrb(color: AppColors.pink.withValues(alpha: 0.14)),
              ),
              content,
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 220,
          width: 220,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
