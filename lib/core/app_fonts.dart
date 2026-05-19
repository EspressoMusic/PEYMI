import 'package:flutter/material.dart';

/// Varela Round (Latin) + Rubik fallback (Hebrew) — clean geometric sans like the app reference.
abstract final class AppFonts {
  static const family = 'Varela Round';

  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const bold = FontWeight.w700;

  static const fallbacks = <String>['Rubik'];

  static FontWeight soften(FontWeight weight) {
    if (weight.index >= FontWeight.w700.index) return bold;
    if (weight.index >= FontWeight.w500.index) return medium;
    return regular;
  }

  static TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallbacks,
      fontSize: fontSize,
      fontWeight: soften(fontWeight ?? regular),
      color: color,
      height: height,
    );
  }

  static TextStyle merge(TextStyle? base, TextStyle style) {
    return (base ?? const TextStyle()).merge(style).copyWith(
          fontFamily: family,
          fontFamilyFallback: fallbacks,
          fontWeight: soften(style.fontWeight ?? base?.fontWeight ?? regular),
        );
  }
}
