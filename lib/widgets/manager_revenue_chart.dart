import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme_mode.dart';
import '../core/business_analytics.dart';

class ManagerRevenueChart extends StatelessWidget {
  const ManagerRevenueChart({
    super.key,
    required this.buckets,
    required this.accentColor,
  });

  final List<RevenueBucket> buckets;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.fold<double>(0, (m, b) => math.max(m, b.amount));
    final top = maxVal <= 0 ? 1.0 : maxVal * 1.15;

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(
        painter: _RevenueBarPainter(
          buckets: buckets,
          maxValue: top,
          accent: accentColor,
          labelColor: BakeryTheme.muted(context),
          gridColor: BakeryTheme.border(context).withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _RevenueBarPainter extends CustomPainter {
  _RevenueBarPainter({
    required this.buckets,
    required this.maxValue,
    required this.accent,
    required this.labelColor,
    required this.gridColor,
  });

  final List<RevenueBucket> buckets;
  final double maxValue;
  final Color accent;
  final Color labelColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;

    const bottomPad = 28.0;
    const topPad = 12.0;
    final chartH = size.height - bottomPad - topPad;
    final barW = size.width / buckets.length;
    final gap = barW * 0.22;
    final usableW = barW - gap;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + chartH * (1 - i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      final h = maxValue <= 0 ? 0.0 : (b.amount / maxValue) * chartH;
      final x = i * barW + gap / 2;
      final y = topPad + chartH - h;

      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, usableW, math.max(h, b.amount > 0 ? 6 : 0)),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [accent.withValues(alpha: 0.55), accent],
          ).createShader(r.outerRect),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: b.label,
          style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barW);
      tp.paint(canvas, Offset(x + (usableW - tp.width) / 2, size.height - bottomPad + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueBarPainter old) =>
      old.buckets != buckets || old.maxValue != maxValue || old.accent != accent;
}
