import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 96,
    this.heroTag = 'all-in-one-coaching-logo',
  });

  final double size;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: _LogoScene(
        iconSize: size,
        showText: false,
        glow: 1,
        bookReveal: 1,
        bookOpen: 1,
        capDrop: 1,
        sparkles: 1,
        textOpacity: 0,
      ),
    );
  }
}

class AnimatedBrandLogo extends StatefulWidget {
  const AnimatedBrandLogo({
    super.key,
    this.size = 220,
    this.showText = true,
    this.loop = true,
    this.duration = const Duration(seconds: 3),
  });

  final double size;
  final bool showText;
  final bool loop;
  final Duration duration;

  @override
  State<AnimatedBrandLogo> createState() => _AnimatedBrandLogoState();
}

class _AnimatedBrandLogoState extends State<AnimatedBrandLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        return _LogoScene(
          iconSize: widget.size,
          showText: widget.showText,
          glow: _interval(t, 0.00, 0.20, curve: Curves.easeOutCubic),
          bookReveal: _interval(t, 0.00, 0.25, curve: Curves.easeOutBack),
          bookOpen: _interval(t, 0.18, 0.46, curve: Curves.easeInOutCubic),
          capDrop: _interval(t, 0.38, 0.68, curve: Curves.easeOutBack),
          sparkles: _interval(t, 0.60, 0.82, curve: Curves.easeOut),
          textOpacity: _interval(t, 0.72, 0.96, curve: Curves.easeOut),
        );
      },
    );
  }
}

class _LogoScene extends StatelessWidget {
  const _LogoScene({
    required this.iconSize,
    required this.showText,
    required this.glow,
    required this.bookReveal,
    required this.bookOpen,
    required this.capDrop,
    required this.sparkles,
    required this.textOpacity,
  });

  final double iconSize;
  final bool showText;
  final double glow;
  final double bookReveal;
  final double bookOpen;
  final double capDrop;
  final double sparkles;
  final double textOpacity;

  @override
  Widget build(BuildContext context) {
    final double totalHeight = showText ? iconSize * 1.52 : iconSize;

    return SizedBox(
      width: iconSize,
      height: totalHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                Opacity(
                  opacity: glow.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: lerpDouble(0.72, 1.0, glow)!,
                    child: CustomPaint(
                      size: Size.square(iconSize),
                      painter: _BackdropPainter(glow: glow),
                    ),
                  ),
                ),
                Opacity(
                  opacity: bookReveal.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: lerpDouble(0.74, 1.0, bookReveal)!,
                    child: SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          CustomPaint(
                            size: Size.square(iconSize),
                            painter: const _BookBasePainter(),
                          ),
                          Positioned(
                            left: iconSize * 0.17,
                            top: iconSize * 0.48,
                            child: _AnimatedBookHalf(
                              size: Size(iconSize * 0.33, iconSize * 0.22),
                              alignment: Alignment.centerRight,
                              rotationY: lerpDouble(-1.05, 0.0, bookOpen)!,
                              painter: const _BookHalfPainter(
                                side: _BookSide.left,
                              ),
                            ),
                          ),
                          Positioned(
                            right: iconSize * 0.17,
                            top: iconSize * 0.48,
                            child: _AnimatedBookHalf(
                              size: Size(iconSize * 0.33, iconSize * 0.22),
                              alignment: Alignment.centerLeft,
                              rotationY: lerpDouble(1.05, 0.0, bookOpen)!,
                              painter: const _BookHalfPainter(
                                side: _BookSide.right,
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size.square(iconSize),
                              painter: _BookCenterGlowPainter(open: bookOpen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: lerpDouble(-iconSize * 0.16, iconSize * 0.17, capDrop)!,
                  child: Opacity(
                    opacity: capDrop == 0 ? 0 : 1,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        math.sin(capDrop * math.pi * 1.1) * (1 - capDrop) * 10,
                      ),
                      child: SizedBox(
                        width: iconSize * 0.56,
                        height: iconSize * 0.42,
                        child: CustomPaint(painter: const _CapPainter()),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: sparkles.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: lerpDouble(0.65, 1.0, sparkles)!,
                      child: CustomPaint(
                        size: Size.square(iconSize),
                        painter: const _SparklesPainter(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showText) ...<Widget>[
            SizedBox(height: iconSize * 0.08),
            Opacity(
              opacity: textOpacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, lerpDouble(14, 0, textOpacity)!),
                child: _BrandText(iconSize: iconSize),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedBookHalf extends StatelessWidget {
  const _AnimatedBookHalf({
    required this.size,
    required this.alignment,
    required this.rotationY,
    required this.painter,
  });

  final Size size;
  final Alignment alignment;
  final double rotationY;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    final Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateY(rotationY);
    return Transform(
      alignment: alignment,
      transform: transform,
      child: CustomPaint(size: size, painter: painter),
    );
  }
}

class _BrandText extends StatelessWidget {
  const _BrandText({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: <Color>[
                _BrandPalette.purple,
                _BrandPalette.blue,
                _BrandPalette.pink,
              ],
            ).createShader(bounds);
          },
          child: Text(
            'All in One',
            style: TextStyle(
              color: Colors.white,
              fontSize: iconSize * 0.17,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1,
            ),
          ),
        ),
        SizedBox(height: iconSize * 0.04),
        Text(
          'COACHING',
          style: TextStyle(
            color: _BrandPalette.pink,
            fontSize: iconSize * 0.073,
            fontWeight: FontWeight.w700,
            letterSpacing: iconSize * 0.03,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _BrandPalette {
  static const Color purple = Color(0xFF6C63FF);
  static const Color blue = Color(0xFF4DA6FF);
  static const Color pink = Color(0xFFFF6EC7);
  static const Color deepPurple = Color(0xFF3C2AD9);
  static const Color gold = Color(0xFFFFC857);
  static const Color orange = Color(0xFFFFA24C);
  static const Color navy = Color(0xFF2437BA);
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.glow});

  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.78);
    final Paint floorGlow = Paint()
      ..color = _BrandPalette.purple.withValues(alpha: 0.16 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.44,
        height: size.height * 0.05,
      ),
      floorGlow,
    );

    final Paint aura = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              _BrandPalette.blue.withValues(alpha: 0.18 * glow),
              _BrandPalette.pink.withValues(alpha: 0.10 * glow),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.48),
              radius: size.width * 0.38,
            ),
          );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.48),
      size.width * 0.38,
      aura,
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) {
    return oldDelegate.glow != glow;
  }
}

class _BookBasePainter extends CustomPainter {
  const _BookBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path base = Path()
      ..moveTo(w * 0.16, h * 0.72)
      ..quadraticBezierTo(w * 0.19, h * 0.58, w * 0.23, h * 0.50)
      ..lineTo(w * 0.43, h * 0.50)
      ..quadraticBezierTo(w * 0.49, h * 0.50, w * 0.50, h * 0.60)
      ..quadraticBezierTo(w * 0.51, h * 0.50, w * 0.57, h * 0.50)
      ..lineTo(w * 0.77, h * 0.50)
      ..quadraticBezierTo(w * 0.81, h * 0.58, w * 0.84, h * 0.72)
      ..lineTo(w * 0.80, h * 0.78)
      ..quadraticBezierTo(w * 0.64, h * 0.76, w * 0.50, h * 0.86)
      ..quadraticBezierTo(w * 0.36, h * 0.76, w * 0.20, h * 0.78)
      ..close();
    final Paint basePaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          _BrandPalette.blue,
          Color(0xFFF8C25B),
          Color(0xFFFF9488),
          _BrandPalette.pink,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(w * 0.16, h * 0.50, w * 0.68, h * 0.36));
    canvas.drawPath(base, basePaint);

    final Path lowerRim = Path()
      ..moveTo(w * 0.16, h * 0.76)
      ..quadraticBezierTo(w * 0.34, h * 0.74, w * 0.50, h * 0.83)
      ..quadraticBezierTo(w * 0.66, h * 0.74, w * 0.84, h * 0.76)
      ..lineTo(w * 0.84, h * 0.80)
      ..quadraticBezierTo(w * 0.66, h * 0.79, w * 0.50, h * 0.88)
      ..quadraticBezierTo(w * 0.34, h * 0.79, w * 0.16, h * 0.80)
      ..close();
    canvas.drawPath(
      lowerRim,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[_BrandPalette.blue, _BrandPalette.deepPurple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(w * 0.16, h * 0.74, w * 0.68, h * 0.14)),
    );

    final Paint innerStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.024
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path guide = Path()
      ..moveTo(w * 0.22, h * 0.66)
      ..quadraticBezierTo(w * 0.36, h * 0.64, w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.64, h * 0.64, w * 0.78, h * 0.66);
    canvas.drawPath(guide, innerStroke);

    final Paint spineGlow = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          _BrandPalette.orange.withValues(alpha: 0.00),
          _BrandPalette.orange.withValues(alpha: 0.9),
          _BrandPalette.pink.withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTWH(w * 0.44, h * 0.52, w * 0.12, h * 0.16));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.47, h * 0.52, w * 0.06, h * 0.13),
        Radius.circular(w * 0.02),
      ),
      spineGlow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _BookSide { left, right }

class _BookHalfPainter extends CustomPainter {
  const _BookHalfPainter({required this.side});

  final _BookSide side;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final bool left = side == _BookSide.left;

    final Path page = Path()
      ..moveTo(left ? w : 0, h * 0.18)
      ..quadraticBezierTo(w * 0.62, h * 0.02, w * 0.10, h * 0.20)
      ..quadraticBezierTo(w * 0.02, h * 0.28, w * 0.04, h * 0.56)
      ..quadraticBezierTo(w * 0.22, h * 0.48, left ? w : 0, h * 0.72)
      ..close();

    final Rect shaderBounds = Rect.fromLTWH(0, 0, w, h);
    final Paint fill = Paint()
      ..shader = LinearGradient(
        colors: left
            ? const <Color>[
                Color(0xFFFFD96B),
                Color(0xFFFF9A7B),
                _BrandPalette.pink,
              ]
            : const <Color>[
                Color(0xFFFFB46B),
                Color(0xFFFF8D89),
                _BrandPalette.pink,
              ],
        begin: left ? Alignment.topLeft : Alignment.topRight,
        end: left ? Alignment.bottomRight : Alignment.bottomLeft,
      ).createShader(shaderBounds);
    canvas.drawPath(page, fill);

    final Paint stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(left ? w * 0.92 : w * 0.08, h * 0.26)
        ..quadraticBezierTo(w * 0.55, h * 0.18, w * 0.12, h * 0.38)
        ..quadraticBezierTo(
          w * 0.24,
          h * 0.40,
          left ? w * 0.94 : w * 0.06,
          h * 0.60,
        ),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BookCenterGlowPainter extends CustomPainter {
  const _BookCenterGlowPainter({required this.open});

  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint glow = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0.38 * open),
              _BrandPalette.gold.withValues(alpha: 0.18 * open),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.56),
              radius: size.width * 0.14,
            ),
          );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.56),
      size.width * 0.14,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _BookCenterGlowPainter oldDelegate) {
    return oldDelegate.open != open;
  }
}

class _CapPainter extends CustomPainter {
  const _CapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path top = Path()
      ..moveTo(w * 0.08, h * 0.22)
      ..lineTo(w * 0.50, h * 0.04)
      ..lineTo(w * 0.92, h * 0.22)
      ..lineTo(w * 0.50, h * 0.40)
      ..close();
    canvas.drawShadow(top, _BrandPalette.deepPurple, 10, false);
    canvas.drawPath(
      top,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[_BrandPalette.purple, _BrandPalette.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(w * 0.08, h * 0.04, w * 0.84, h * 0.36)),
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.16, h * 0.24)
        ..lineTo(w * 0.50, h * 0.10)
        ..lineTo(w * 0.84, h * 0.24),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round,
    );

    final Path body = Path()
      ..moveTo(w * 0.30, h * 0.36)
      ..lineTo(w * 0.30, h * 0.72)
      ..quadraticBezierTo(w * 0.50, h * 0.92, w * 0.70, h * 0.72)
      ..lineTo(w * 0.70, h * 0.36)
      ..quadraticBezierTo(w * 0.50, h * 0.48, w * 0.30, h * 0.36)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            _BrandPalette.navy,
            _BrandPalette.deepPurple,
            _BrandPalette.purple,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(w * 0.30, h * 0.36, w * 0.40, h * 0.56)),
    );

    canvas.drawRect(
      Rect.fromLTWH(w * 0.30, h * 0.42, w * 0.40, h * 0.09),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );

    final Paint tassel = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          _BrandPalette.gold,
          _BrandPalette.orange,
          _BrandPalette.pink,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.48, h * 0.12, w * 0.24, h * 0.62))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.18),
      w * 0.05,
      Paint()
        ..shader =
            const RadialGradient(
              colors: <Color>[_BrandPalette.gold, _BrandPalette.orange],
            ).createShader(
              Rect.fromCircle(
                center: Offset(w * 0.50, h * 0.18),
                radius: w * 0.05,
              ),
            ),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.54, h * 0.19)
        ..quadraticBezierTo(w * 0.76, h * 0.24, w * 0.76, h * 0.48)
        ..lineTo(w * 0.76, h * 0.60),
      tassel,
    );
    canvas.drawCircle(
      Offset(w * 0.76, h * 0.60),
      w * 0.038,
      Paint()
        ..shader =
            const RadialGradient(
              colors: <Color>[_BrandPalette.gold, _BrandPalette.orange],
            ).createShader(
              Rect.fromCircle(
                center: Offset(w * 0.76, h * 0.60),
                radius: w * 0.038,
              ),
            ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.72, h * 0.60, w * 0.08, h * 0.16),
        Radius.circular(w * 0.03),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            _BrandPalette.gold,
            _BrandPalette.orange,
            _BrandPalette.purple,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(w * 0.72, h * 0.60, w * 0.08, h * 0.16)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparklesPainter extends CustomPainter {
  const _SparklesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _drawSparkle(
      canvas,
      Offset(size.width * 0.22, size.height * 0.50),
      size.width * 0.040,
      _BrandPalette.blue,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.33, size.height * 0.43),
      size.width * 0.022,
      _BrandPalette.purple.withValues(alpha: 0.7),
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.78, size.height * 0.20),
      size.width * 0.034,
      _BrandPalette.blue,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.87, size.height * 0.29),
      size.width * 0.030,
      _BrandPalette.orange,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.82, size.height * 0.44),
      size.width * 0.034,
      _BrandPalette.purple,
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final Path star = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.30, center.dy - radius * 0.30)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + radius * 0.30, center.dy + radius * 0.30)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.30, center.dy + radius * 0.30)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - radius * 0.30, center.dy - radius * 0.30)
      ..close();
    canvas.drawPath(star, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double _interval(
  double t,
  double start,
  double end, {
  Curve curve = Curves.linear,
}) {
  if (t <= start) {
    return 0;
  }
  if (t >= end) {
    return 1;
  }
  return curve.transform((t - start) / (end - start));
}
