import 'package:flutter/material.dart';

/// Keeps customer tab content below the status bar / notch (never flush to top).
class CustomerTabBody extends StatelessWidget {
  const CustomerTabBody({super.key, required this.child});

  final Widget child;

  static const double extraTop = 12;
  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(16, 8, 16, 28);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.only(top: extraTop),
      child: child,
    );
  }
}
