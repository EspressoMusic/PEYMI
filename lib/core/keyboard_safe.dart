import 'package:flutter/material.dart';

import 'app_theme_mode.dart';
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

/// Dialog with keyboard-safe scrolling and an exit button.
Future<T?> showBakeryDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  Color barrierColor = Colors.black54,
  bool showCloseButton = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: KeyboardSafeScroll(
          child: showCloseButton ? BakeryDialogCloseWrap(child: child) : child,
        ),
      );
    },
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
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (sheetContext) => bakeryModalSheetFrame(
      sheetContext,
      builder(sheetContext),
      title: title,
      heightFactor: heightFactor,
      showCloseButton: showCloseButton,
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

  final body = showCloseButton
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BakerySheetCloseBar(title: title),
            Expanded(child: child),
          ],
        )
      : child;

  final sheetFill = BakeryTheme.softSurface(context);

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
