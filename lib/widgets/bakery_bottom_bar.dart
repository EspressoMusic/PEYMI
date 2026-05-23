import 'package:flutter/material.dart';

import '../core/app_theme_mode.dart';

/// Custom bottom nav — avoids Material [NavigationBar] GlobalKey collisions when routes stack.
class BakeryBottomBar extends StatelessWidget {
  const BakeryBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    this.badgeIndices = const {},
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<({IconData icon, String label})> items;
  final Set<int> badgeIndices;

  @override
  Widget build(BuildContext context) {
    final accent = BakeryTheme.accent(context);
    final muted = BakeryTheme.muted(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: Material(
                  color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onSelected(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(item.icon, color: selected ? accent : muted, size: 24),
                              if (badgeIndices.contains(i))
                                const Positioned(
                                  top: -2,
                                  right: -4,
                                  child: _PulsingAlertDot(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? accent : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _PulsingAlertDot extends StatefulWidget {
  const _PulsingAlertDot();

  @override
  State<_PulsingAlertDot> createState() => _PulsingAlertDotState();
}

class _PulsingAlertDotState extends State<_PulsingAlertDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
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
      builder: (context, _) {
        final pulse = 0.35 + _controller.value * 0.65;
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(const Color(0xFFB71C1C), const Color(0xFFFF5252), _controller.value),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: pulse),
                blurRadius: 6 + _controller.value * 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
