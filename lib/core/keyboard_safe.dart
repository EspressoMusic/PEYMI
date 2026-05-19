import 'package:flutter/material.dart';

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

/// Dialog with keyboard-safe scrolling — use for any form inside a dialog.
Future<T?> showBakeryDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  Color barrierColor = Colors.black54,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: KeyboardSafeScroll(child: child),
      );
    },
  );
}

/// Fixed-height frame for [showModalBottomSheet] that shrinks when the keyboard opens.
Widget bakeryModalSheetFrame(
  BuildContext context,
  Widget child, {
  double heightFactor = 0.92,
}) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  final height = MediaQuery.sizeOf(context).height * heightFactor;

  return AnimatedPadding(
    padding: EdgeInsets.only(bottom: keyboard),
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOut,
    child: SizedBox(
      height: (height - keyboard).clamp(220.0, height),
      child: child,
    ),
  );
}
