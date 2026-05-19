import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme_mode.dart';

/// Liquid tank gauge: low level = red, high level = green.
class BusinessHealthGauge extends StatefulWidget {
  const BusinessHealthGauge({
    super.key,
    required this.level,
    this.height = 168,
  });

  final double level;
  final double height;

  @override
  State<BusinessHealthGauge> createState() => _BusinessHealthGaugeState();
}

class _BusinessHealthGaugeState extends State<BusinessHealthGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level.clamp(0.05, 0.98);
    final liquid = BakeryTheme.healthLiquid(context, level);
    final decor = bakeryDecor(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: level),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedLevel, child) {
        return AnimatedBuilder(
          animation: _wave,
          builder: (context, _) {
            return SizedBox(
              width: double.infinity,
              height: widget.height,
              child: CustomPaint(
              painter: _LiquidGaugePainter(
                fillLevel: animatedLevel,
                liquidColor: liquid,
                wavePhase: _wave.value * math.pi * 2,
                borderColor: decor.mutedText,
                glassColor: BakeryTheme.cardSurface(context).withValues(alpha: 0.35),
              ),
            ),
            );
          },
        );
      },
    );
  }
}

class _LiquidGaugePainter extends CustomPainter {
  _LiquidGaugePainter({
    required this.fillLevel,
    required this.liquidColor,
    required this.wavePhase,
    required this.borderColor,
    required this.glassColor,
  });

  final double fillLevel;
  final Color liquidColor;
  final double wavePhase;
  final Color borderColor;
  final Color glassColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = 22.0;
    final tank = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));

    canvas.save();
    canvas.clipRRect(tank);

    canvas.drawRRect(
      tank,
      Paint()..color = glassColor,
    );

    final fillH = size.height * fillLevel;
    final surfaceY = size.height - fillH;

    final path = Path()..moveTo(0, size.height);
    const steps = 28;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final wave = math.sin((x / size.width * math.pi * 2) + wavePhase) * 7;
      final y = surfaceY + wave;
      if (i == 0) {
        path.lineTo(0, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            liquidColor.withValues(alpha: 0.92),
            liquidColor.withValues(alpha: 0.55),
          ],
        ).createShader(Rect.fromLTWH(0, surfaceY - 12, size.width, fillH + 24)),
    );

    canvas.drawRect(
      Rect.fromLTWH(8, 12, size.width * 0.22, size.height * 0.55),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(8, 12, 40, size.height)),
    );

    canvas.restore();

    canvas.drawRRect(
      tank,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = borderColor.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidGaugePainter old) =>
      old.fillLevel != fillLevel ||
      old.liquidColor != liquidColor ||
      old.wavePhase != wavePhase;
}
