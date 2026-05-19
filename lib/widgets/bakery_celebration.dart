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

class BakeryEmojiConfetti extends StatefulWidget {
  const BakeryEmojiConfetti({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<BakeryEmojiConfetti> createState() => _BakeryEmojiConfettiState();
}

class _BakeryEmojiConfettiState extends State<BakeryEmojiConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  final List<String> _emojis = const ['🥐', '🧁', '🍰', '🍪', '🍩', '🎉', '✨'];

  @override
  void initState() {
    super.initState();
    final random = Random();
    _particles = List.generate(22, (index) {
      return _ConfettiParticle(
        x: random.nextDouble(),
        drift: (random.nextDouble() - 0.5) * 0.20,
        size: 22 + random.nextDouble() * 12,
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

class _ConfettiParticle {
  const _ConfettiParticle({
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
