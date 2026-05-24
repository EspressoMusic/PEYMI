import 'package:flutter/material.dart';

import '../core/app_theme_mode.dart';
import '../core/bakery_square_palette.dart';

/// Rounded cream panel used in dialogs, settings rows, and order sheets.
class BakeryOrdersPanel extends StatelessWidget {
  const BakeryOrdersPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.border,
    this.surfaceColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final BoxBorder? border;
  final Color? surfaceColor;

  /// Single source of truth for dialog/panel fill — close bar must match this.
  static Color surfaceOf(BuildContext context) =>
      BakerySquarePalette.squareFill(context);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor ?? surfaceOf(context),
        borderRadius: BorderRadius.circular(22),
        border: border ?? Border.all(color: BakeryTheme.border(context), width: 1.2),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [
                BoxShadow(color: Color(0x38000000), blurRadius: 16, offset: Offset(0, 8)),
                BoxShadow(color: Color(0x18FFFFFF), blurRadius: 8, offset: Offset(-2, -3)),
              ],
      ),
      child: child,
    );
  }
}
