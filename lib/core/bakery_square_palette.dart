import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_mode.dart';

/// Action-square colors — calm: cream; light: white; dark: navy.
abstract final class BakerySquarePalette {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color title(BuildContext context) {
    if (_isDark(context)) return Colors.white;
    return BakeryTheme.body(context);
  }

  static Color subtitle(BuildContext context) {
    if (_isDark(context)) return Colors.white.withValues(alpha: 0.78);
    if (AppThemeController.instance.mode == AppThemeMode.light) {
      return Colors.black.withValues(alpha: 0.72);
    }
    return BakeryTheme.subtitle(context);
  }

  static Color shadow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.shadow.withValues(alpha: scheme.brightness == Brightness.dark ? 0.55 : 0.28);
  }

  /// Action squares / tiles — darker than [BakeryTheme.softSurface] backdrop in every theme.
  static Color squareFill(BuildContext context) {
    return switch (AppThemeController.instance.mode) {
      AppThemeMode.dark => AppColors.darkBlueSquare,
      AppThemeMode.light => AppColors.darkCreamSquare,
      AppThemeMode.calm => AppColors.darkCreamSquare,
    };
  }

  /// Same as [BakeryTheme.softSurface] — use behind square grids.
  static Color squareBackdrop(BuildContext context) => BakeryTheme.softSurface(context);

  /// Softer tile variant (between backdrop and [squareFill]).
  static Color lighterSquareFill(BuildContext context) {
    return switch (AppThemeController.instance.mode) {
      AppThemeMode.dark => AppColors.darkBlueElevated,
      AppThemeMode.light => AppColors.brownSurfaceTint,
      AppThemeMode.calm => AppColors.brownSurfaceTint,
    };
  }

  /// Delicate border — matches [_OrdersPanel] / panel rectangles (1.2).
  static const double squareBorderWidth = 1.2;

  static BoxBorder squareBorder(BuildContext context, {double width = squareBorderWidth}) {
    final color = switch (AppThemeController.instance.mode) {
      AppThemeMode.dark => Colors.white.withValues(alpha: 0.45),
      AppThemeMode.light => Colors.black.withValues(alpha: 0.45),
      AppThemeMode.calm => BakeryTheme.border(context),
    };
    return Border.all(color: color, width: width);
  }

  /// Border on the outer box so the stroke follows the full rounded perimeter
  /// (avoids [Material.clipBehavior] clipping corners).
  static Widget shell({
    required BuildContext context,
    required Widget child,
    double borderRadius = 20,
    BoxBorder? border,
    Color? color,
    List<BoxShadow>? boxShadow,
  }) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? squareFill(context),
        borderRadius: radius,
        border: border ?? squareBorder(context),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );
  }

  static List<Color> gradientAt(BuildContext context, int index) {
    final c = squareFill(context);
    return [c, c];
  }

  static Color solidAt(BuildContext context, int index) => squareFill(context);

  static Color managerEntrySolid(BuildContext context) => squareFill(context);

  static List<Color> managerEntryGradient(BuildContext context) {
    final c = squareFill(context);
    return [c, c];
  }

  static Color? managerEntryBorder(BuildContext context) => null;

  static Color managerEntryTitle(BuildContext context) => title(context);

  static Color managerEntrySubtitle(BuildContext context) => subtitle(context);
}
