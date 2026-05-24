import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_data.dart';
import 'demo_store.dart';
import 'manager_store.dart';
import 'safe_change_notifier.dart';

/// Runtime catalog: manager-added items (persisted). Built-in samples only for demo store slug.
class CatalogStore extends ChangeNotifier with SafeChangeNotifier {
  CatalogStore._();

  static final CatalogStore instance = CatalogStore._();
  static const _productsKey = 'catalog_custom_products_v1';
  static const _drinksKey = 'catalog_custom_drinks_v1';
  static const _setupPromptKey = 'catalog_setup_prompt_shown_v1';

  List<Map<String, String>> _customProducts = [];
  List<Map<String, String>> _customDrinks = [];

  List<Map<String, String>> get products => List.unmodifiable(_visible(_customProducts, CatalogData.products));

  List<Map<String, String>> get drinks => List.unmodifiable(_visible(_customDrinks, CatalogData.drinks));

  List<Map<String, String>> get allItems => [...products, ...drinks];

  bool get isCatalogEmpty => products.isEmpty && drinks.isEmpty;

  static var _managerListenerAttached = false;

  bool get _showBuiltinSamples => DemoStore.isDemoSlug(ManagerStore.instance.linkedBusinessSlug);

  /// True when the manager catalog has nothing to show (no demo samples and no custom items).
  bool get shouldShowManagerEmptyState => isCatalogEmpty && !_showBuiltinSamples;

  List<Map<String, String>> _visible(
    List<Map<String, String>> custom,
    List<Map<String, String>> builtin,
  ) =>
      _showBuiltinSamples ? [...builtin, ...custom] : custom;

  Map<String, String>? findById(String id) {
    for (final item in allItems) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  /// Match an order/prep line label to a catalog item (custom + visible built-ins).
  Map<String, String>? findByLineName(String lineName) {
    final trimmed = lineName.trim();
    if (trimmed.isEmpty) return null;
    for (final item in allItems) {
      if (item['nameHe'] == trimmed || item['nameEn'] == trimmed) return item;
    }
    return null;
  }

  ({String image, String emoji})? visualForLineName(String lineName) {
    final item = findByLineName(lineName);
    if (item == null) return null;
    final image = item['image']?.trim() ?? '';
    if (image.isEmpty) return null;
    return (image: image, emoji: item['emoji'] ?? '🥖');
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _customProducts = _decodeList(prefs.getString(_productsKey));
    _customDrinks = _decodeList(prefs.getString(_drinksKey));
    if (!_managerListenerAttached) {
      _managerListenerAttached = true;
      ManagerStore.instance.addListener(notifyListeners);
    }
    notifyListeners();
  }

  Future<bool> shouldShowSetupPrompt() async {
    if (!isCatalogEmpty || _showBuiltinSamples) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_setupPromptKey) ?? false);
  }

  Future<void> markSetupPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupPromptKey, true);
  }

  /// Show the setup banner again when entering products mode with an empty catalog.
  Future<void> armSetupPromptForProductsMode() async {
    if (!isCatalogEmpty || _showBuiltinSamples) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupPromptKey, false);
  }

  List<Map<String, String>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final e in decoded)
          if (e is Map) Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v.toString()))),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> addProduct({
    required String nameHe,
    required String nameEn,
    required String subtitleHe,
    required String subtitleEn,
    required String price,
    required String image,
    String emoji = '🥖',
  }) async {
    final id = 'custom_p_${DateTime.now().millisecondsSinceEpoch}';
    final item = {
      'id': id,
      'nameHe': nameHe,
      'nameEn': nameEn,
      'subtitleHe': subtitleHe,
      'subtitleEn': subtitleEn,
      'price': price.contains('₪') ? price : '$price₪',
      'image': image,
      'emoji': emoji,
    };
    _customProducts = [..._customProducts, item];
    await _persistCustoms(_productsKey, _customProducts);
    notifyListeners();
  }

  Future<void> addDrink({
    required String nameHe,
    required String nameEn,
    required String subtitleHe,
    required String subtitleEn,
    required String price,
    required String image,
    String emoji = '☕',
  }) async {
    final id = 'custom_d_${DateTime.now().millisecondsSinceEpoch}';
    final item = {
      'id': id,
      'nameHe': nameHe,
      'nameEn': nameEn,
      'subtitleHe': subtitleHe,
      'subtitleEn': subtitleEn,
      'price': price.contains('₪') ? price : '$price₪',
      'image': image,
      'emoji': emoji,
    };
    _customDrinks = [..._customDrinks, item];
    await _persistCustoms(_drinksKey, _customDrinks);
    notifyListeners();
  }

  Future<void> updateItem({
    required String id,
    required String nameHe,
    required String nameEn,
    required String subtitleHe,
    required String subtitleEn,
    required String price,
    required String image,
    required String emoji,
    required bool isDrink,
  }) async {
    final list = isDrink ? _customDrinks : _customProducts;
    final idx = list.indexWhere((e) => e['id'] == id);
    if (idx < 0 || !id.startsWith('custom_')) return;
    list[idx] = {
      'id': id,
      'nameHe': nameHe,
      'nameEn': nameEn,
      'subtitleHe': subtitleHe,
      'subtitleEn': subtitleEn,
      'price': price.contains('₪') ? price : '$price₪',
      'image': image,
      'emoji': emoji,
    };
    if (isDrink) {
      _customDrinks = List.from(list);
      await _persistCustoms(_drinksKey, _customDrinks);
    } else {
      _customProducts = List.from(list);
      await _persistCustoms(_productsKey, _customProducts);
    }
    notifyListeners();
  }

  Future<void> removeItem(String id, {required bool isDrink}) async {
    if (!id.startsWith('custom_')) return;
    if (isDrink) {
      _customDrinks = _customDrinks.where((d) => d['id'] != id).toList();
      await _persistCustoms(_drinksKey, _customDrinks);
    } else {
      _customProducts = _customProducts.where((p) => p['id'] != id).toList();
      await _persistCustoms(_productsKey, _customProducts);
    }
    notifyListeners();
  }

  Future<void> _persistCustoms(String key, List<Map<String, String>> customs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(customs));
  }

  static List<String> get availableImages => [
        ...CatalogData.products.map((p) => p['image']!),
        ...CatalogData.drinks.map((d) => d['image']!),
      ];
}
