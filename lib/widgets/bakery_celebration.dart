import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Plays the same success sound used when adding items to the cart.
Future<void> playBakeryCelebrationSound([AudioPlayer? player]) async {
  final p = player ?? AudioPlayer();
  final owned = player == null;
  try {
    await p.stop();
    await p.play(AssetSource('sounds/cart_add.mp3'));
  } finally {
    if (owned) {
      await p.dispose();
    }
  }
}

/// Falling colored paper confetti (no bakery / food emojis).
class BakeryShapeConfetti extends StatefulWidget {
  const BakeryShapeConfetti({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<BakeryShapeConfetti> createState() => _BakeryShapeConfettiState();
}

class _BakeryShapeConfettiState extends State<BakeryShapeConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ShapeParticle> _particles;

  static const _palette = [
    Color(0xFF48CAE4),
    Color(0xFF2A9D8F),
    Color(0xFFFFB703),
    Color(0xFFE76F51),
    Color(0xFF9B5DE5),
    Color(0xFF4CC9F0),
    Color(0xFF06D6A0),
    Color(0xFFF72585),
  ];

  @override
  void initState() {
    super.initState();
    final random = Random();
    _particles = List.generate(28, (index) {
      return _ShapeParticle(
        x: random.nextDouble(),
        drift: (random.nextDouble() - 0.5) * 0.22,
        size: 7 + random.nextDouble() * 9,
        delay: random.nextDouble() * 0.3,
        color: _palette[random.nextInt(_palette.length)],
        isCircle: random.nextBool(),
        spin: (random.nextDouble() - 0.5) * pi * 4,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeIn.transform(_controller.value);
            return Stack(
              children: _particles.map((p) {
                final localT = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
                final y = lerpDouble(-30, constraints.maxHeight + 30, localT)!;
                final x = ((p.x + (sin(localT * pi * 3) * p.drift)) * constraints.maxWidth)
                    .clamp(0.0, constraints.maxWidth - p.size);
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: 1 - localT,
                    child: Transform.rotate(
                      angle: p.spin * localT,
                      child: Container(
                        width: p.size,
                        height: p.isCircle ? p.size : p.size * 0.55,
                        decoration: BoxDecoration(
                          color: p.color,
                          borderRadius: BorderRadius.circular(p.isCircle ? p.size : 2),
                          boxShadow: [
                            BoxShadow(
                              color: p.color.withValues(alpha: 0.35),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _ShapeParticle {
  const _ShapeParticle({
    required this.x,
    required this.drift,
    required this.size,
    required this.delay,
    required this.color,
    required this.isCircle,
    required this.spin,
  });

  final double x;
  final double drift;
  final double size;
  final double delay;
  final Color color;
  final bool isCircle;
  final double spin;
}

/// Sparkle / party emojis only (no food).
class BakeryEmojiConfetti extends StatefulWidget {
  const BakeryEmojiConfetti({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<BakeryEmojiConfetti> createState() => _BakeryEmojiConfettiState();
}

class _BakeryEmojiConfettiState extends State<BakeryEmojiConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_EmojiParticle> _particles;
  static const _emojis = ['🎉', '✨', '🎊', '⭐', '💫'];

  @override
  void initState() {
    super.initState();
    final random = Random();
    _particles = List.generate(20, (index) {
      return _EmojiParticle(
        x: random.nextDouble(),
        drift: (random.nextDouble() - 0.5) * 0.20,
        size: 22 + random.nextDouble() * 10,
        delay: random.nextDouble() * 0.35,
        emoji: _emojis[random.nextInt(_emojis.length)],
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeIn.transform(_controller.value);
            return Stack(
              children: _particles.map((p) {
                final localT = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
                final y = lerpDouble(-40, constraints.maxHeight + 40, localT)!;
                final x = ((p.x + (sin(localT * pi * 3) * p.drift)) * constraints.maxWidth)
                    .clamp(0.0, constraints.maxWidth - 24);
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: 1 - localT,
                    child: Transform.rotate(
                      angle: localT * pi * 2,
                      child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _EmojiParticle {
  const _EmojiParticle({
    required this.x,
    required this.drift,
    required this.size,
    required this.delay,
    required this.emoji,
  });

  final double x;
  final double drift;
  final double size;
  final double delay;
  final String emoji;
}
