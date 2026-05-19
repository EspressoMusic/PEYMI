import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

enum AppThemeMode { calm, light, dark }

@immutable
class BakeryDecor extends ThemeExtension<BakeryDecor> {
  const BakeryDecor({
    required this.panelTop,
    required this.panelBottom,
    required this.cardFill,
    required this.chipFill,
    required this.accent,
    required this.mutedText,
  });

  final Color panelTop;
  final Color panelBottom;
  final Color cardFill;
  final Color chipFill;
  final Color accent;
  final Color mutedText;

  @override
  BakeryDecor copyWith({
    Color? panelTop,
    Color? panelBottom,
    Color? cardFill,
    Color? chipFill,
    Color? accent,
    Color? mutedText,
  }) {
    return BakeryDecor(
      panelTop: panelTop ?? this.panelTop,
      panelBottom: panelBottom ?? this.panelBottom,
      cardFill: cardFill ?? this.cardFill,
      chipFill: chipFill ?? this.chipFill,
      accent: accent ?? this.accent,
      mutedText: mutedText ?? this.mutedText,
    );
  }

  @override
  BakeryDecor lerp(ThemeExtension<BakeryDecor>? other, double t) {
    if (other is! BakeryDecor) return this;
    return BakeryDecor(
      panelTop: Color.lerp(panelTop, other.panelTop, t)!,
      panelBottom: Color.lerp(panelBottom, other.panelBottom, t)!,
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      chipFill: Color.lerp(chipFill, other.chipFill, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
    );
  }
}

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();
  static const _prefKey = 'app_theme_mode';

  AppThemeMode _mode = AppThemeMode.calm;

  AppThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    _mode = AppThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AppThemeMode.calm,
    );
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
    notifyListeners();
  }

  ThemeData theme() {
    return switch (_mode) {
      AppThemeMode.calm => _calmTheme(),
      AppThemeMode.light => _lightTheme(),
      AppThemeMode.dark => _darkTheme(),
    };
  }

  ThemeData _calmTheme() {
    const scaffold = Color(0xFFF4F0E8);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brown,
      brightness: Brightness.light,
      surface: scaffold,
      onSurface: AppColors.darkBrown,
      primary: AppColors.brown,
      onPrimary: Colors.white,
    );
    return _baseTheme(
      scheme,
      scaffold: scaffold,
      decor: const BakeryDecor(
        panelTop: Color(0xFFFBF7EF),
        panelBottom: Color(0xFFF1E5D4),
        cardFill: Color(0xFFF8F4EC),
        chipFill: Color(0xFFF1E9D8),
        accent: AppColors.brown,
        mutedText: Color(0xFF6D4C41),
      ),
    );
  }

  ThemeData _lightTheme() {
    const scaffold = Colors.white;
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Color(0xFF212121),
      onSecondary: Colors.white,
      surface: scaffold,
      onSurface: Colors.black,
      onSurfaceVariant: Color(0xFF424242),
      surfaceContainerHighest: Color(0xFFF5F5F5),
      outline: Color(0xFFBDBDBD),
      error: Color(0xFFB00020),
      onError: Colors.white,
    );
    return _baseTheme(
      scheme,
      scaffold: scaffold,
      decor: const BakeryDecor(
        panelTop: Color(0xFFFFFFFF),
        panelBottom: Color(0xFFF0F0F0),
        cardFill: Color(0xFFFAFAFA),
        chipFill: Color(0xFFF5F5F5),
        accent: Colors.black,
        mutedText: Color(0xFF616161),
      ),
      navIndicator: Colors.black12,
    );
  }

  ThemeData _darkTheme() {
    // Soft slate — gentle dark, not black; strong text contrast.
    const scaffold = Color(0xFF2C3340);
    const surfaceHigh = Color(0xFF383F4D);
    const accent = Color(0xFF7EC0FF);
    const onSurface = Color(0xFFF8FAFC);
    const onSurfaceVariant = Color(0xFFD5DCE8);
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: Color(0xFF1A2330),
      secondary: Color(0xFFA8D4FF),
      onSecondary: Color(0xFF1A2330),
      surface: scaffold,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerHighest: surfaceHigh,
      outline: Color(0xFF6B7588),
      error: Color(0xFFFFB4C0),
      onError: Color(0xFF2C3340),
    );
    return _baseTheme(
      scheme,
      scaffold: scaffold,
      decor: const BakeryDecor(
        panelTop: Color(0xFF424C5E),
        panelBottom: Color(0xFF3A4354),
        cardFill: Color(0xFF404A5C),
        chipFill: Color(0xFF4A5568),
        accent: accent,
        mutedText: Color(0xFFB8C2D4),
      ),
      navIndicator: Color(0x507EC0FF),
    );
  }

  ThemeData _baseTheme(
    ColorScheme scheme, {
    required Color scaffold,
    required BakeryDecor decor,
    Color? navIndicator,
  }) {
    const bold = AppFonts.regular;
    const extraBold = AppFonts.medium;

    TextStyle themed({
      required double fontSize,
      required FontWeight fontWeight,
      required Color color,
    }) {
      return TextStyle(
        fontFamily: AppFonts.family,
        fontFamilyFallback: AppFonts.fallbacks,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }

    final textTheme = TextTheme(
      headlineSmall: themed(fontSize: 20, fontWeight: extraBold, color: scheme.onSurface),
      titleLarge: themed(fontSize: 18, fontWeight: extraBold, color: scheme.onSurface),
      titleMedium: themed(fontSize: 16, fontWeight: bold, color: scheme.onSurface),
      titleSmall: themed(fontSize: 14, fontWeight: bold, color: scheme.onSurface),
      bodyLarge: themed(fontSize: 15, fontWeight: bold, color: scheme.onSurface),
      bodyMedium: themed(fontSize: 14, fontWeight: bold, color: scheme.onSurface),
      bodySmall: themed(fontSize: 12, fontWeight: bold, color: scheme.onSurfaceVariant),
      labelLarge: themed(fontSize: 14, fontWeight: extraBold, color: scheme.onSurface),
    );

    final isDark = scheme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(16);

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.family,
      fontFamilyFallback: AppFonts.fallbacks,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [decor],
      dividerColor: scheme.outline.withValues(alpha: isDark ? 0.45 : 0.35),
      iconTheme: IconThemeData(color: scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: themed(fontSize: 20, fontWeight: AppFonts.medium, color: scheme.onSurface),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: decor.cardFill,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: themed(fontSize: 20, fontWeight: AppFonts.medium, color: scheme.onSurface),
        contentTextStyle: themed(fontSize: 15, fontWeight: AppFonts.regular, color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scaffold,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? decor.chipFill : Colors.white.withValues(alpha: 0.9),
        labelStyle: themed(fontSize: 14, fontWeight: AppFonts.regular, color: scheme.onSurfaceVariant),
        floatingLabelStyle: themed(fontSize: 14, fontWeight: AppFonts.medium, color: scheme.onSurface),
        hintStyle: themed(
          fontSize: 14,
          fontWeight: AppFonts.regular,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
        ),
        border: OutlineInputBorder(borderRadius: borderRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.55), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: decor.accent, width: 2),
        ),
        prefixIconColor: decor.accent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        indicatorColor: navIndicator ?? decor.accent.withValues(alpha: isDark ? 0.28 : 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return themed(
            fontSize: 12,
            fontWeight: AppFonts.regular,
            color: states.contains(WidgetState.selected) ? decor.accent : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? decor.accent : scheme.onSurfaceVariant,
          );
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.onPrimary;
            return scheme.onSurface;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return decor.chipFill;
          }),
          textStyle: WidgetStatePropertyAll(
            themed(fontSize: 14, fontWeight: AppFonts.regular, color: scheme.onSurface),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
          textStyle: WidgetStatePropertyAll(
            themed(fontSize: 14, fontWeight: AppFonts.regular, color: scheme.onPrimary),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 2 : 8,
        shadowColor: isDark ? Colors.black45 : Colors.black26,
        color: decor.cardFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

BakeryDecor bakeryDecor(BuildContext context) =>
    Theme.of(context).extension<BakeryDecor>()!;

/// Semantic colors that follow calm / light / dark themes.
abstract final class BakeryTheme {
  static ColorScheme scheme(BuildContext context) => Theme.of(context).colorScheme;

  static Color body(BuildContext context) => scheme(context).onSurface;

  static Color subtitle(BuildContext context) => scheme(context).onSurfaceVariant;

  static Color accent(BuildContext context) => bakeryDecor(context).accent;

  static Color muted(BuildContext context) => bakeryDecor(context).mutedText;

  static Color border(BuildContext context) =>
      scheme(context).outline.withValues(alpha: scheme(context).brightness == Brightness.dark ? 0.55 : 0.4);

  static Color softSurface(BuildContext context) => bakeryDecor(context).chipFill;

  static Color cardSurface(BuildContext context) => bakeryDecor(context).cardFill;

  static List<Color> panelGradient(BuildContext context) {
    final decor = bakeryDecor(context);
    return [decor.panelTop, decor.panelBottom];
  }

  /// Health-ring liquid: low = soft warning, high = theme accent (never generic green).
  static Color healthLiquid(BuildContext context, double level) {
    final fill = level.clamp(0.0, 1.0);
    final (Color low, Color high) = switch (AppThemeController.instance.mode) {
      AppThemeMode.calm => (
          const Color(0xFFCF8F8F),
          Color.lerp(AppColors.brown, AppColors.brownLight, 0.35)!,
        ),
      AppThemeMode.light => (
          const Color(0xFFD9A0A0),
          const Color(0xFF3D3D3D),
        ),
      AppThemeMode.dark => (
          const Color(0xFF9A7070),
          const Color(0xFF7EC0FF),
        ),
    };
    return Color.lerp(low, high, fill)!;
  }

  static TextStyle text(
    BuildContext context, {
    double fontSize = 15,
    FontWeight fontWeight = AppFonts.regular,
    Color? color,
    double? height,
  }) {
    return AppFonts.style(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? body(context),
      height: height,
    );
  }

  static TextStyle subtitleText(
    BuildContext context, {
    double fontSize = 14,
    FontWeight fontWeight = AppFonts.regular,
    double? height,
  }) {
    return AppFonts.style(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: subtitle(context),
      height: height ?? 1.35,
    );
  }
}

InputDecoration bakeryInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  bool required = false,
}) {
  final scheme = BakeryTheme.scheme(context);
  final accent = BakeryTheme.accent(context);
  final radius = BorderRadius.circular(16);
  final labelStyle = BakeryTheme.subtitleText(context, fontWeight: FontWeight.w700);
  return InputDecoration(
    label: required
        ? RichText(
            text: TextSpan(
              style: labelStyle,
              children: [
                TextSpan(text: label),
                TextSpan(text: ' *', style: labelStyle.copyWith(color: scheme.error, fontWeight: FontWeight.w900)),
              ],
            ),
          )
        : null,
    labelText: required ? null : label,
    prefixIcon: Icon(icon, color: accent),
    filled: true,
    fillColor: BakeryTheme.softSurface(context),
    labelStyle: BakeryTheme.subtitleText(context, fontWeight: FontWeight.w700),
    floatingLabelStyle: BakeryTheme.text(context, fontWeight: FontWeight.w800),
    border: OutlineInputBorder(borderRadius: radius),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: BakeryTheme.border(context), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: accent, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.85), width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error, width: 2),
    ),
  );
}
