import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/app_fonts.dart';
import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/bakery_navigator.dart';
import '../core/bakery_square_palette.dart';

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

/// Centered square notice — replaces bottom [SnackBar]s (errors, info, confirmations).
Future<void> showBakeryNoticeBanner(
  BuildContext context, {
  required String title,
  String? subtitle,
  IconData? icon,
  bool isError = false,
  bool playSound = false,
  Duration autoDismissAfter = const Duration(milliseconds: 3000),
}) {
  final host = bakeryOverlayContext ?? context;
  return showOverlaySafely<void>(
    context: host,
    show: (overlayHost) => showGeneralDialog<void>(
      context: overlayHost,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, _, __) {
        return _CenterSquareBannerOverlay(
          animation: animation,
          title: title,
          subtitle: subtitle,
          icon: icon ?? (isError ? Icons.error_outline_rounded : Icons.info_outline_rounded),
          accent: isError ? const Color(0xFFC62828) : BakeryTheme.buttonFill(ctx),
          showConfetti: false,
          playSound: playSound,
          autoDismissAfter: autoDismissAfter,
        );
      },
    ),
  );
}

/// Compact success tile: centered square + confetti + celebration sound.
Future<void> showBakerySuccessCelebration(
  BuildContext context, {
  required String title,
  String? subtitle,
  AudioPlayer? player,
  IconData icon = Icons.check_circle_rounded,
  bool playSound = true,
  Duration autoDismissAfter = const Duration(milliseconds: 3200),
}) {
  final host = bakeryOverlayContext ?? context;
  return showOverlaySafely<void>(
    context: host,
    show: (overlayHost) => showGeneralDialog<void>(
      context: overlayHost,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, _, __) {
        return _CenterSquareBannerOverlay(
          animation: animation,
          title: title,
          subtitle: subtitle,
          icon: icon,
          accent: const Color(0xFF2A9D8F),
          showConfetti: true,
          playSound: playSound,
          player: player,
          autoDismissAfter: autoDismissAfter,
        );
      },
    ),
  );
}

/// Save / update confirmation — small square popup with confetti (not a bottom SnackBar).
Future<void> showBakeryUpdateBanner(
  BuildContext context, {
  required String title,
  String? subtitle,
  IconData icon = Icons.auto_awesome_rounded,
  bool playSound = true,
}) =>
    showBakerySuccessCelebration(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      playSound: playSound,
      autoDismissAfter: const Duration(milliseconds: 2800),
    );

Future<void> showOrderSuccessCelebration(
  BuildContext context, {
  required String title,
  String? subtitle,
  AudioPlayer? player,
}) =>
    showBakerySuccessCelebration(
      context,
      title: title,
      subtitle: subtitle,
      player: player,
    );

class _CenterSquareBannerOverlay extends StatefulWidget {
  const _CenterSquareBannerOverlay({
    required this.animation,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    this.showConfetti = false,
    this.playSound = false,
    this.player,
    this.autoDismissAfter = const Duration(milliseconds: 3000),
  });

  final Animation<double> animation;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final bool showConfetti;
  final bool playSound;
  final AudioPlayer? player;
  final Duration autoDismissAfter;

  @override
  State<_CenterSquareBannerOverlay> createState() => _CenterSquareBannerOverlayState();
}

class _CenterSquareBannerOverlayState extends State<_CenterSquareBannerOverlay> {
  var _showConfetti = true;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    if (widget.playSound) {
      unawaited(playBakeryCelebrationSound(widget.player));
    }
    if (widget.autoDismissAfter > Duration.zero) {
      Future<void>.delayed(widget.autoDismissAfter, _dismiss);
    }
  }

  void _dismiss() {
    if (!mounted || _closing) return;
    _closing = true;
    popThen(context, () async {});
  }

  @override
  Widget build(BuildContext context) {
    const tileSize = 260.0;
    final scale = CurvedAnimation(parent: widget.animation, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: widget.animation, curve: Curves.easeOut);

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _dismiss,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
        if (widget.showConfetti && _showConfetti) ...[
          IgnorePointer(
            child: BakeryShapeConfetti(
              onFinished: () {
                if (mounted && !_closing) setState(() => _showConfetti = false);
              },
            ),
          ),
          IgnorePointer(
            child: BakeryEmojiConfetti(onFinished: () {}),
          ),
        ],
        Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1).animate(scale),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: tileSize,
                  height: tileSize,
                  child: BakerySquarePalette.shell(
                    context: context,
                    borderRadius: 22,
                    border: Border.all(color: widget.accent.withValues(alpha: 0.4), width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: BakerySquarePalette.shadow(context),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(widget.icon, color: widget.accent, size: 40),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.style(
                                      fontSize: 18,
                                      fontWeight: AppFonts.bold,
                                      height: 1.25,
                                      color: BakeryTheme.body(context),
                                    ),
                                  ),
                                ),
                                if (widget.subtitle != null && widget.subtitle!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      widget.subtitle!,
                                      textAlign: TextAlign.center,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.style(
                                        fontSize: 14,
                                        fontWeight: AppFonts.medium,
                                        height: 1.35,
                                        color: BakeryTheme.subtitle(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _dismiss,
                              child: Text(
                                AppLocale.instance.s.confirm,
                                style: AppFonts.style(fontSize: 15, fontWeight: AppFonts.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
