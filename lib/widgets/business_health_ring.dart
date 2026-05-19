import 'package:flutter/material.dart';

import '../core/app_theme_mode.dart';

/// Circular tank — liquid height matches [level] exactly (1.0 = full circle, 100%).
class BusinessHealthRing extends StatelessWidget {
  const BusinessHealthRing({
    super.key,
    required this.level,
    this.size = 172,
    this.onTapWhenBelowPerfect,
  });

  final double level;
  final double size;
  final VoidCallback? onTapWhenBelowPerfect;

  @override
  Widget build(BuildContext context) {
    final fill = level.clamp(0.0, 1.0);
    final percent = (fill * 100).round();
    final liquid = BakeryTheme.healthLiquid(context, fill);
    final inner = size - 10;
    final canTap = percent < 100 && onTapWhenBelowPerfect != null;

    final ring = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BakeryTheme.cardSurface(context).withValues(alpha: 0.45),
              border: Border.all(color: BakeryTheme.border(context), width: 3),
            ),
          ),
          ClipOval(
            child: SizedBox(
              width: inner,
              height: inner,
              child: fill <= 0
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: fill,
                      child: Container(
                        width: inner,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              liquid,
                              Color.lerp(liquid, Colors.white, 0.18)!,
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Text(
            '$percent%',
            style: BakeryTheme.text(
              context,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1,
            ).copyWith(
              color: fill > 0.42 ? Colors.white : liquid,
              shadows: fill > 0.42
                  ? const [Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))]
                  : null,
            ),
          ),
          if (canTap)
            Positioned(
              bottom: 6,
              child: Icon(
                Icons.touch_app_rounded,
                size: 18,
                color: BakeryTheme.muted(context).withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );

    if (!canTap) return ring;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTapWhenBelowPerfect,
        child: ring,
      ),
    );
  }
}
