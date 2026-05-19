import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilitySettings extends ChangeNotifier {
  AccessibilitySettings._();

  static final AccessibilitySettings instance = AccessibilitySettings._();
  static const _prefKey = 'accessibility_text_scale';

  static const double minScale = 0.9;
  static const double maxScale = 1.5;
  static const double defaultScale = 1.0;

  double _textScale = defaultScale;

  double get textScale => _textScale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _textScale = prefs.getDouble(_prefKey) ?? defaultScale;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    final next = value.clamp(minScale, maxScale);
    if ((_textScale - next).abs() < 0.01) return;
    _textScale = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, _textScale);
    notifyListeners();
  }

  Future<void> increaseText() => setTextScale(_textScale + 0.1);

  Future<void> decreaseText() => setTextScale(_textScale - 0.1);

  Future<void> resetText() => setTextScale(defaultScale);
}
