import 'dart:convert';

import 'package:http/http.dart' as http;

/// Detects Hebrew vs English and fills both locale fields (online translate with fallback).
class LocaleTranslate {
  static bool isPrimarilyHebrew(String text) {
    var hebrew = 0;
    var latin = 0;
    for (final rune in text.runes) {
      if (rune >= 0x0590 && rune <= 0x05FF) {
        hebrew++;
      } else if ((rune >= 0x0041 && rune <= 0x005A) || (rune >= 0x0061 && rune <= 0x007A)) {
        latin++;
      }
    }
    return hebrew >= latin;
  }

  static Future<({String he, String en})> toBilingual(String text, {bool? sourceHebrew}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return (he: '', en: '');

    final isHe = sourceHebrew ?? isPrimarilyHebrew(trimmed);
    if (isHe) {
      final en = await _translate(trimmed, 'he|en');
      return (he: trimmed, en: en.isNotEmpty ? en : trimmed);
    }
    final he = await _translate(trimmed, 'en|he');
    return (he: he.isNotEmpty ? he : trimmed, en: trimmed);
  }

  static Future<String> _translate(String text, String langPair) async {
    try {
      final uri = Uri.https('api.mymemory.translated.net', '/get', {
        'q': text,
        'langpair': langPair,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return '';
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return '';
      final data = body['responseData'];
      if (data is! Map<String, dynamic>) return '';
      final translated = data['translatedText'] as String? ?? '';
      return translated.trim();
    } catch (_) {
      return '';
    }
  }
}
