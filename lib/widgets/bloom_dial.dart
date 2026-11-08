import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Bloom's brand mark, drawn rather than shipped as a raster: the white
/// cherry blossom on its luminous rose disc.
class BloomMark extends StatelessWidget {
  final double size;

  const BloomMark({super.key, this.size = 128});

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarkPainter(
          disc: p.period,
          discDeep: p == BloomPalette.dark
              ? const Color(0xFF7A2438)
              : BloomColors.rose700,
          discLight: p == BloomPalette.dark
              ? const Color(0xFFE88BA2)
              : BloomColors.rose300,
          petal: Colors.white,
          core: p == BloomPalette.dark
              ? const Color(0xFFB03558)
              : BloomColors.rose400,
          coreDeep: p == BloomPalette.dark
              ? const Color(0xFF6E1E33)
              : BloomColors.rose600,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final Color disc;
  final Color discDeep;
  final Color discLight;
  final Color petal;
  final Color core;
  final Color coreDeep;

  _MarkPainter({
    required this.disc,
    required this.discDeep,
    required this.discLight,
    required this.petal,
    required this.core,
    required this.coreDeep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // The luminous disc.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.1,
          colors: [discLight, disc, discDeep],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    final petalPaint = Paint()..color = petal;

    // Outer whorl.
    for (var i = 0; i < 5; i++) {
      _petal(
        canvas,
        center,
        radius * 0.50,
        -math.pi / 2 + i * 2 * math.pi / 5,
        radius * 0.40,
        radius * 0.155,
        petalPaint,
      );
    }

    // Inner whorl, offset by half a turn.
    for (var i = 0; i < 5; i++) {
      _petal(
        canvas,
        center,
        radius * 0.27,
        -math.pi / 2 + math.pi / 5 + i * 2 * math.pi / 5,
        radius * 0.27,
        radius * 0.105,
        petalPaint,
      );
    }

    // The glossy heart.
    final coreRadius = radius * 0.145;
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: [discLight, core, coreDeep],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );
    canvas.drawCircle(
      center + Offset(-coreRadius * 0.3, -coreRadius * 0.34),
      coreRadius * 0.26,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreRadius * 0.12),
    );
  }

  void _petal(
    Canvas canvas,
    Offset center,
    double baseRadius,
    double angle,
    double length,
    double halfWidth,
    Paint paint,
  ) {
    final direction = Offset(math.cos(angle), math.sin(angle));
    final base = center + direction * baseRadius;

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle + math.pi / 2);

    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        -halfWidth,
        -length * 0.30,
        -halfWidth * 0.82,
        -length * 0.80,
        0,
        -length,
      )
      ..cubicTo(
        halfWidth * 0.82,
        -length * 0.80,
        halfWidth,
        -length * 0.30,
        0,
        0,
      )
      ..close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) =>
      old.disc != disc || old.petal != petal || old.core != core;
}

/// Bloom's dial.
///
/// The cycle position is drawn as the app's own blossom: twelve petals open
/// around the cycle as it advances, and the cycle day sits in the glossy heart
/// of the flower. The mark and the mechanism are one object.
class BloomDial extends StatelessWidget {
  final int? day;
  final int cycleLength;
  final bool isOnPeriod;
  final double maxSize;

  const BloomDial({
    super.key,
    required this.day,
    required this.cycleLength,
    required this.isOnPeriod,
    this.maxSize = 268,
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final progress = day == null ? 0.0 : (day! / cycleLength).clamp(0.0, 1.0);

    final caption = day == null
        ? 'no cycle logged'
        : (isOnPeriod ? 'period day' : 'of $cycleLength day cycle');

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: day == null
          ? 'No cycle logged'
          : 'Cycle day $day of $cycleLength${isOnPeriod ? ', period active' : ''}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, maxSize);
          return SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: size,
                      child: CustomPaint(
                        painter: _BlossomPainter(
                          progress: value,
                          track: p.periodContainer,
                          fill: p.period,
                          core: p.period,
                          coreEdge: isDark(p)
                              ? const Color(0xFF7A2438)
                              : BloomColors.rose700,
                          highlight: isDark(p)
                              ? const Color(0xFFF0A0B4)
                              : BloomColors.rose300,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day?.toString() ?? '--',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontSize: size * (day == null ? 0.19 : 0.30),
                                fontWeight: FontWeight.w700,
                                fontVariations: [
                                  FontVariation(
                                    'wght',
                                    day == null ? 500 : 700,
                                  ),
                                ],
                                height: 1.0,
                                letterSpacing: day == null ? 0 : -1.5,
                                color: Colors.white.withValues(
                                  alpha: day == null ? 0.62 : 1,
                                ),
                              ),
                        ),
                        SizedBox(height: size * 0.018),
                        Text(
                          caption,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontSize: size * 0.042,
                                fontWeight: FontWeight.w500,
                                fontVariations: const [
                                  FontVariation('wght', 500),
                                ],
                                height: 1.2,
                                letterSpacing: 0.2,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  static bool isDark(BloomPalette p) => p == BloomPalette.dark;
}

class _BlossomPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color fill;
  final Color core;
  final Color coreEdge;
  final Color highlight;

  static const int _petals = 12;

  _BlossomPainter({
    required this.progress,
    required this.track,
    required this.fill,
    required this.core,
    required this.coreEdge,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final baseRadius = radius * 0.60;
    final petalLength = radius * 0.355;
    final halfWidth = radius * 0.150;
    final coreRadius = radius * 0.455;

    // The one soft light in the app.
    canvas.drawCircle(
      center,
      radius * 0.82,
      Paint()
        ..color = fill.withValues(alpha: 0.13)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.14),
    );

    // Track: every petal, unfilled.
    final trackPaint = Paint()..color = track;
    for (var i = 0; i < _petals; i++) {
      _drawPetal(
        canvas,
        center,
        baseRadius,
        _angleFor(i),
        petalLength,
        halfWidth,
        trackPaint,
      );
    }

    // Fill: the same petals, clipped to the swept arc, so the bloom opens
    // continuously rather than in visible steps.
    if (progress > 0.001) {
      final fillPaint = Paint()..color = fill;
      if (progress >= 0.999) {
        for (var i = 0; i < _petals; i++) {
          _drawPetal(
            canvas,
            center,
            baseRadius,
            _angleFor(i),
            petalLength,
            halfWidth,
            fillPaint,
          );
        }
      } else {
        canvas.save();
        final wedge = Path()..moveTo(center.dx, center.dy);
        wedge.arcTo(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          2 * math.pi * progress,
          true,
        );
        wedge.close();
        canvas.clipPath(wedge);
        for (var i = 0; i < _petals; i++) {
          _drawPetal(
            canvas,
            center,
            baseRadius,
            _angleFor(i),
            petalLength,
            halfWidth,
            fillPaint,
          );
        }
        canvas.restore();
      }

      // Leading edge: where the bloom currently stands.
      final markerAngle = -math.pi / 2 + 2 * math.pi * progress;
      final markerRadius = baseRadius + petalLength * 0.52;
      final marker =
          center +
          Offset(math.cos(markerAngle), math.sin(markerAngle)) * markerRadius;
      canvas.drawCircle(marker, 5.5, Paint()..color = fill);
      canvas.drawCircle(marker, 2.2, Paint()..color = Colors.white);
    }

    // The heart of the blossom — the app's mark, with its glossy centre.
    final coreRect = Rect.fromCircle(center: center, radius: coreRadius);
    final corePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.42),
        radius: 1.05,
        colors: [highlight, core, coreEdge],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(coreRect);
    canvas.drawCircle(center, coreRadius, corePaint);

    canvas.drawCircle(
      center + Offset(-coreRadius * 0.30, -coreRadius * 0.36),
      coreRadius * 0.20,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreRadius * 0.10),
    );
  }

  double _angleFor(int index) => -math.pi / 2 + index * 2 * math.pi / _petals;

  void _drawPetal(
    Canvas canvas,
    Offset center,
    double baseRadius,
    double angle,
    double length,
    double halfWidth,
    Paint paint,
  ) {
    final direction = Offset(math.cos(angle), math.sin(angle));
    final base = center + direction * baseRadius;

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle + math.pi / 2);

    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        -halfWidth * 0.95,
        -length * 0.22,
        -halfWidth * 0.86,
        -length * 0.70,
        0,
        -length,
      )
      ..cubicTo(
        halfWidth * 0.86,
        -length * 0.70,
        halfWidth * 0.95,
        -length * 0.22,
        0,
        0,
      )
      ..close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlossomPainter old) =>
      old.progress != progress ||
      old.fill != fill ||
      old.track != track ||
      old.coreEdge != coreEdge;
}
