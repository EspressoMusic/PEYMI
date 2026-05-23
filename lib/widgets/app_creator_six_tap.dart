import 'package:flutter/material.dart';

/// Counts rapid taps; calls [onTriggered] after [requiredTaps] within [window].
class AppCreatorSixTapDetector extends StatefulWidget {
  const AppCreatorSixTapDetector({
    super.key,
    required this.child,
    required this.onTriggered,
    this.requiredTaps = 6,
    this.window = const Duration(seconds: 2),
  });

  final Widget child;
  final VoidCallback onTriggered;
  final int requiredTaps;
  final Duration window;

  @override
  State<AppCreatorSixTapDetector> createState() => _AppCreatorSixTapDetectorState();
}

class _AppCreatorSixTapDetectorState extends State<AppCreatorSixTapDetector> {
  int _count = 0;
  DateTime? _lastTap;

  void _onTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) > widget.window) {
      _count = 0;
    }
    _lastTap = now;
    _count++;
    if (_count >= widget.requiredTaps) {
      _count = 0;
      _lastTap = null;
      widget.onTriggered();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onTap(),
      child: widget.child,
    );
  }
}
