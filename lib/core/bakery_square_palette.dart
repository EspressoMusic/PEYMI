import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_mode.dart';

/// Action-square colors derived from the active calm / light / dark theme.
abstract final class BakerySquarePalette {
  static Color title(BuildContext context) => BakeryTheme.body(context);

  static Color subtitle(BuildContext context) => BakeryTheme.subtitle(context);

  static Color shadow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.shadow.withValues(alpha: scheme.brightness == Brightness.dark ? 0.45 : 0.28);
  }

  static List<Color> gradientAt(BuildContext context, int index) {
    if (AppThemeController.instance.mode == AppThemeMode.calm) {
      return _calmGradients(index);
    }
    return _themeGradients(context, index);
  }

  /// Settings — manager login tile (stands out from other squares).
  static List<Color> managerEntryGradient(BuildContext context) {
    final accent = BakeryTheme.accent(context);
    return switch (AppThemeController.instance.mode) {
      AppThemeMode.calm => [
          Color.lerp(AppColors.brown, const Color(0xFF6D4C41), 0.5)!,
          const Color(0xFF8D6E63),
        ],
      AppThemeMode.light => [
          const Color(0xFF3E2723),
          const Color(0xFF5D4037),
        ],
      AppThemeMode.dark => [
          const Color(0xFF1E3A5F),
          Color.lerp(accent, const Color(0xFF2C3340), 0.35)!,
        ],
    };
  }

  static Color managerEntryBorder(BuildContext context) {
    final accent = BakeryTheme.accent(context);
    return switch (AppThemeController.instance.mode) {
      AppThemeMode.calm => const Color(0xFFD4A574),
      AppThemeMode.light => accent,
      AppThemeMode.dark => accent,
    };
  }

  static Color managerEntryTitle(BuildContext context) => Colors.white;

  static Color managerEntrySubtitle(BuildContext context) =>
      Colors.white.withValues(alpha: 0.88);

  /// Richer earthy squares for calm mode (stronger than panel tints alone).
  static List<Color> _calmGradients(int index) {
    const pairs = <List<Color>>[
      [Color(0xFFEBD9C8), Color(0xFFD4B896)],
      [Color(0xFFF2E8DA), Color(0xFFDFC4B0)],
      [Color(0xFFE8D0C0), Color(0xFFCDB39E)],
      [Color(0xFFD9C3B0), Color(0xFFBC9E86)],
      [Color(0xFFE5D8CC), Color(0xFFC9AE98)],
    ];
    return pairs[index % pairs.length];
  }

  static List<Color> _themeGradients(BuildContext context, int index) {
    final decor = bakeryDecor(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final mid = Color.lerp(decor.panelTop, decor.panelBottom, 0.45)!;
    final soft = Color.lerp(decor.cardFill, decor.chipFill, 0.5)!;
    final deep = Color.lerp(decor.panelBottom, decor.mutedText, isDark ? 0.35 : 0.18)!;

    final pairs = <List<Color>>[
      [decor.panelTop, decor.panelBottom],
      [decor.cardFill, decor.chipFill],
      [mid, soft],
      [soft, deep],
      [decor.panelTop, soft],
    ];
    return pairs[index % pairs.length];
  }
}
