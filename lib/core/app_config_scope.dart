import 'package:flutter/material.dart';

import 'accessibility_settings.dart';
import 'app_locale.dart';
import 'app_theme_mode.dart';

/// Theme, text direction, and text scale for a route subtree — without rebuilding [MaterialApp].
class AppConfigScope extends StatefulWidget {
  const AppConfigScope({super.key, required this.child});

  final Widget child;

  @override
  State<AppConfigScope> createState() => _AppConfigScopeState();
}

class _AppConfigScopeState extends State<AppConfigScope> {
  @override
  void initState() {
    super.initState();
    AppLocale.instance.addListener(_rebuild);
    AppThemeController.instance.addListener(_rebuild);
    AccessibilitySettings.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    AppLocale.instance.removeListener(_rebuild);
    AppThemeController.instance.removeListener(_rebuild);
    AccessibilitySettings.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.instance;
    final theme = AppThemeController.instance.theme();
    final scale = AccessibilitySettings.instance.textScale;
    final media = MediaQuery.maybeOf(context);
    final scaledMedia = media == null
        ? null
        : media.copyWith(textScaler: TextScaler.linear(scale));

    Widget child = Theme(
      data: theme,
      child: Directionality(
        textDirection: locale.direction,
        child: widget.child,
      ),
    );

    if (scaledMedia != null) {
      child = MediaQuery(data: scaledMedia, child: child);
    }

    return child;
  }
}
