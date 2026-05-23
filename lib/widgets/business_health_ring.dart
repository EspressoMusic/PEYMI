import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme_mode.dart';

class HealthRingBadge {
  const HealthRingBadge({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
}

/// Natural flowing-water health tank — fill level + animated surface waves.
class BusinessHealthRing extends StatefulWidget {
  const BusinessHealthRing({
    super.key,
    required this.level,
    this.size = 240,
    this.onTapWhenBelowPerfect,
    this.issueBadges = const [],
    this.animateWaves = true,
  });

  final double level;
  final double size;
  final VoidCallback? onTapWhenBelowPerfect;
  final List<HealthRingBadge> issueBadges;
  /// When false, wave animation pauses (saves GPU on hidden tabs).
  final bool animateWaves;

  @override
  State<BusinessHealthRing> createState() => _BusinessHealthRingState();
}

class _BusinessHealthRingState extends State<BusinessHealthRing> with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _syncWaveAnimation();
  }

  @override
  void didUpdateWidget(BusinessHealthRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animateWaves != widget.animateWaves) {
      _syncWaveAnimation();
    }
  }

  void _syncWaveAnimation() {
    if (!mounted) return;
    if (widget.animateWaves) {
      if (!_waveController.isAnimating) _waveController.repeat();
    } else {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.level.clamp(0.0, 1.0);
    final percent = (fill * 100).round();
    final isDark = AppThemeController.instance.mode == AppThemeMode.dark;
    final percentColor = isDark || fill > 0.38 ? Colors.white : const Color(0xFF0D4F6C);
    final inner = widget.size - 12;
    final canTapRing = percent < 100 && widget.onTapWhenBelowPerfect != null;
    final badgeSize = (widget.size * 0.16).clamp(26.0, 36.0);
    final percentFont = (widget.size * 0.16).clamp(28.0, 40.0);

    final ring = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F6FA).withValues(alpha: isDark ? 0.12 : 0.55),
              border: Border.all(
                color: const Color(0xFF7EC8E3).withValues(alpha: isDark ? 0.65 : 0.85),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF48CAE4).withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          ClipOval(
            child: RepaintBoundary(
              child: SizedBox(
                width: inner,
                height: inner,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _FlowingWaterPainter(
                        fillLevel: fill,
                        phase: _waveController.value * math.pi * 2,
                        secondaryPhase: _waveController.value * math.pi * 2 * 1.35 + 0.8,
                      ),
                      size: Size(inner, inner),
                    );
                  },
                ),
              ),
            ),
          ),
          Text(
            '$percent%',
            style: BakeryTheme.text(
              context,
              fontSize: percentFont,
              fontWeight: FontWeight.w900,
              height: 1,
            ).copyWith(
              color: percentColor,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: fill > 0.25 ? 0.45 : 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          if (canTapRing && widget.issueBadges.isEmpty)
            Positioned(
              bottom: 8,
              child: Icon(
                Icons.touch_app_rounded,
                size: 20,
                color: BakeryTheme.muted(context).withValues(alpha: 0.85),
              ),
            ),
          ..._badgeWidgets(context, badgeSize),
        ],
      ),
    );

    if (!canTapRing) return ring;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTapWhenBelowPerfect,
        child: ring,
      ),
    );
  }

  List<Widget> _badgeWidgets(BuildContext context, double badgeSize) {
    if (widget.issueBadges.isEmpty) return const [];

    final n = widget.issueBadges.length;
    final radius = widget.size / 2 + badgeSize * 0.12;
    final start = -math.pi / 2;

    return List.generate(n, (i) {
      final angle = start + (2 * math.pi * i / n);
      final dx = radius * math.cos(angle);
      final dy = radius * math.sin(angle);
      final badge = widget.issueBadges[i];

      Widget dot = Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: badge.onTap,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE53935),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(badge.icon, size: badgeSize * 0.48, color: Colors.white),
          ),
        ),
      );

      if (badge.tooltip != null && badge.tooltip!.isNotEmpty) {
        dot = Tooltip(message: badge.tooltip!, child: dot);
      }

      return Positioned(
        left: widget.size / 2 + dx - badgeSize / 2,
        top: widget.size / 2 + dy - badgeSize / 2,
        child: dot,
      );
    });
  }
}

/// Animated water fill with dual sine waves and natural blue-teal palette.
class _FlowingWaterPainter extends CustomPainter {
  _FlowingWaterPainter({
    required this.fillLevel,
    required this.phase,
    required this.secondaryPhase,
  });

  final double fillLevel;
  final double phase;
  final double secondaryPhase;

  static Color _waterDeep(double fill) =>
      Color.lerp(const Color(0xFF0A6C8A), const Color(0xFF168FA8), fill)!;

  static Color _waterMid(double fill) =>
      Color.lerp(const Color(0xFF1D9DBF), const Color(0xFF3AB5D4), fill)!;

  static const _waterSurface = Color(0xFF6EC8E8);
  static const _waterHighlight = Color(0xFFB8EBFA);

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel <= 0) {
      _paintEmptyTank(canvas, size);
      return;
    }

    final amplitude = size.height * 0.028;
    final amplitude2 = amplitude * 0.55;
    final baseY = size.height * (1 - fillLevel);

    final surfacePath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, baseY);

    const steps = 28;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final nx = x / size.width * math.pi * 2;
      final wave = math.sin(nx + phase) * amplitude + math.sin(nx * 1.7 + secondaryPhase) * amplitude2;
      surfacePath.lineTo(x, baseY + wave);
    }

    surfacePath
      ..lineTo(size.width, size.height)
      ..close();

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          _waterDeep(fillLevel),
          _waterMid(fillLevel),
          _waterSurface,
          _waterHighlight.withValues(alpha: 0.85),
        ],
        stops: const [0.0, 0.45, 0.78, 1.0],
      ).createShader(Rect.fromLTWH(0, baseY - amplitude * 2, size.width, size.height - baseY + amplitude * 2));

    canvas.drawPath(surfacePath, waterPaint);

    final shimmerPath = Path();
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final nx = x / size.width * math.pi * 2;
      final wave = math.sin(nx + phase) * amplitude + math.sin(nx * 1.7 + secondaryPhase) * amplitude2;
      if (i == 0) {
        shimmerPath.moveTo(x, baseY + wave - 2);
      } else {
        shimmerPath.lineTo(x, baseY + wave - 2);
      }
    }
    canvas.drawPath(
      shimmerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.42),
    );

    _paintBubbles(canvas, size, baseY, phase);
  }

  void _paintEmptyTank(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF4FBFD),
            const Color(0xFFD8EEF5),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _paintBubbles(Canvas canvas, Size size, double baseY, double phase) {
    if (fillLevel < 0.12) return;
    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    final waterHeight = size.height - baseY;
    final count = (fillLevel * 5).round().clamp(2, 6);
    for (var i = 0; i < count; i++) {
      final t = (phase / (math.pi * 2) + i * 0.31) % 1.0;
      final bx = size.width * (0.2 + (i * 0.17) % 0.6);
      final by = baseY + waterHeight * (0.25 + t * 0.55);
      final r = 2.0 + (i % 3);
      canvas.drawCircle(Offset(bx, by), r, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlowingWaterPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.phase != phase ||
        oldDelegate.secondaryPhase != secondaryPhase;
  }
}
