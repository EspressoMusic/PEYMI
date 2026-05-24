import 'package:flutter/material.dart';

/// App palette — cream squares + warm ink text (no chocolate-brown fills).
abstract final class AppColors {
  /// Calm mode — soft-cream fill for action/product squares (manager + customer).
  static const darkCreamSquare = Color(0xFFE6D4B8);

  /// Readable text / icons on cream surfaces.
  static const creamInk = Color(0xFF3A2F26);
  /// Primary action buttons — warm brown (lighter than [creamInk] for fills).
  static const buttonFill = Color(0xFF5C4A3E);
  static const buttonOnFill = Color(0xFFF8F4EC);
  static const darkBrown = creamInk;
  static const brown = darkCreamSquare;
  static const brownMedium = Color(0xFFD4C4A8);
  static const brownAccent = Color(0xFF6B5D52);
  static const brownLight = Color(0xFF9A8B7A);
  static const brownBorder = Color(0xFFC9B89A);
  static const brownBorderLight = Color(0xFFE8DDD0);
  static const brownSurfaceTint = Color(0xFFEFEBE9);

  /// Dark mode — navy blue + white only.
  static const darkBlueBg = Color(0xFF081420);
  static const darkBluePanel = Color(0xFF102A47);
  static const darkBlueSquare = Color(0xFF1A3554);
  static const darkBlueElevated = Color(0xFF243D5E);
}
