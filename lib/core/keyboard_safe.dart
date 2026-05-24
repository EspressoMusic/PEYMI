import 'package:flutter/material.dart';

import 'app_theme_mode.dart';
import 'app_locale.dart';
import 'bakery_navigator.dart';
import '../widgets/bakery_orders_panel.dart';
import '../widgets/bakery_sheet_close_bar.dart';

/// Prevents "bottom overflowed" when the soft keyboard opens.
class KeyboardSafeScroll extends StatelessWidget {
  const KeyboardSafeScroll({
    super.key,
    required this.child,
    this.padding,
    this.maxHeightFactor = 0.88,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final topInset = media.viewPadding.top;
    final available = media.size.height - topInset - keyboard - 32;
    final maxHeight = (media.size.height * maxHeightFactor).clamp(180.0, available);

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboard),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: padding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: child,
        ),
      ),
    );
  }
}

/// Dialog with keyboard-safe scrolling, opaque panel, and an exit button.
Future<T?> showBakeryDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  Color barrierColor = Colors.black54,
  bool showCloseButton = true,
  bool wrapInPanel = true,
  EdgeInsets panelPadding = const EdgeInsets.fromLTRB(22, 8, 22, 20),
}) {
  return showOverlaySafely<T>(
    context: context,
    show: (host) => showDialog<T>(
      context: host,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: (dialogContext) {
        final Widget framedChild;
        if (wrapInPanel) {
          framedChild = BakeryOrdersPanel(
            padding: EdgeInsets.zero,
            child: showCloseButton
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BakerySheetCloseBar(onClose: () => popRouteSafely(dialogContext)),
                      Padding(
                        padding: panelPadding.copyWith(top: 0),
                        child: child,
                      ),
                    ],
                  )
                : Padding(
                    padding: panelPadding,
                    child: child,
                  ),
          );
        } else if (showCloseButton) {
          framedChild = BakeryOrdersPanel(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BakerySheetCloseBar(onClose: () => popRouteSafely(dialogContext)),
                Padding(
                  padding: panelPadding.copyWith(top: 0),
                  child: child,
                ),
              ],
            ),
          );
        } else {
          framedChild = child;
        }

        return Theme(
          data: Theme.of(dialogContext),
          child: Directionality(
            textDirection: AppLocale.instance.direction,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: KeyboardSafeScroll(
                child: framedChild,
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Standard bottom sheet with drag handle, close bar, and keyboard-safe height.
Future<T?> showBakeryBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext sheetContext) builder,
  String? title,
  double heightFactor = 0.92,
  bool showCloseButton = true,
}) {
  return showOverlaySafely<T>(
    context: context,
    show: (host) => showModalBottomSheet<T>(
      context: host,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(host).scaffoldBackgroundColor,
      builder: (sheetContext) => bakeryModalSheetFrame(
        sheetContext,
        builder(sheetContext),
        title: title,
        heightFactor: heightFactor,
        showCloseButton: showCloseButton,
      ),
    ),
  );
}

/// Fixed-height frame for [showModalBottomSheet] that shrinks when the keyboard opens.
Widget bakeryModalSheetFrame(
  BuildContext context,
  Widget child, {
  double heightFactor = 0.92,
  String? title,
  bool showCloseButton = true,
}) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  final height = MediaQuery.sizeOf(context).height * heightFactor;
  final sheetFill = BakeryTheme.softSurface(context);

  final framedBody = showCloseButton
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BakerySheetCloseBar(title: title, barColor: sheetFill),
            Expanded(child: child),
          ],
        )
      : child;

  // Modal routes can inherit a Theme without [BakeryDecor] while [AppConfigScope]
  // rebuilds after locale/theme changes — pin the full app theme here.
  final body = Theme(
    data: AppThemeController.instance.theme(),
    child: Directionality(
      textDirection: AppLocale.instance.direction,
      child: framedBody,
    ),
  );

  return AnimatedPadding(
    padding: EdgeInsets.only(bottom: keyboard),
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOut,
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: ColoredBox(
        color: sheetFill,
        child: SizedBox(
          height: (height - keyboard).clamp(220.0, height),
          child: body,
        ),
      ),
    ),
  );
}
