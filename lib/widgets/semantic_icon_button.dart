import 'package:flutter/material.dart';

/// Tap target with an explicit screen-reader label.
class SemanticIconButton extends StatelessWidget {
  const SemanticIconButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: child,
    );
  }
}
