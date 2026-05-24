import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/bakery_navigator.dart';
import 'bakery_orders_panel.dart';

/// Top bar with title (optional) and a clear exit control for sheets / panels.
class BakerySheetCloseBar extends StatelessWidget {
  const BakerySheetCloseBar({
    super.key,
    this.title,
    this.onClose,
    this.barColor,
  });

  final String? title;
  final VoidCallback? onClose;
  /// Must match the parent panel/sheet surface. Defaults to [BakeryOrdersPanel.surfaceOf].
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    final accent = BakeryTheme.accent(context);
    final barFill = barColor ?? BakeryOrdersPanel.surfaceOf(context);

    return ColoredBox(
      color: barFill,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
        child: Row(
          children: [
            if (title != null && title!.trim().isNotEmpty) ...[
              Expanded(
                child: Text(
                  title!,
                  style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ] else
              const Spacer(),
            Semantics(
              button: true,
              label: strings.close,
              child: TextButton.icon(
                onPressed: onClose ?? () => popRouteSafely(context),
                icon: Icon(Icons.close_rounded, color: accent, size: 22),
                label: Text(
                  strings.close,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: accent,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legacy wrapper — prefer [showBakeryDialog] with default panel wrap.
class BakeryDialogCloseWrap extends StatelessWidget {
  const BakeryDialogCloseWrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BakeryOrdersPanel(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BakerySheetCloseBar(onClose: () => popRouteSafely(context)),
          child,
        ],
      ),
    );
  }
}
