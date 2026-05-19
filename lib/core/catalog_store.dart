import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_data.dart';

/// Runtime catalog: built-in products/drinks + manager-added items (persisted).
class CatalogStore extends ChangeNotifier {
  CatalogStore._();

  static final CatalogStore instance = CatalogStore._();
  static const _productsKey = 'catalog_custom_products_v1';
  static const _drinksKey = 'catalog_custom_drinks_v1';

  List<Map<String, String>> _products = [];
  List<Map<String, String>> _drinks = [];

  List<Map<String, String>> get products => List.unmodifiable(_products);
  List<Map<String, String>> get drinks => List.unmodifiable(_drinks);

  List<Map<String, String>> get allItems => [..._products, ..._drinks];

  Map<String, String>? findById(String id) {
    for (final item in allItems) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _products = [...CatalogData.products, ..._decodeList(prefs.getString(_productsKey))];
    _drinks = [...CatalogData.drinks, ..._decodeList(prefs.getString(_drinksKey))];
    notifyListeners();
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
    final customs = _products.where((p) => p['id']!.startsWith('custom_')).toList()..add(item);
    _products = [...CatalogData.products, ...customs];
    await _persistCustoms(_productsKey, customs);
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
    final customs = _drinks.where((d) => d['id']!.startsWith('custom_')).toList()..add(item);
    _drinks = [...CatalogData.drinks, ...customs];
    await _persistCustoms(_drinksKey, customs);
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
    final list = isDrink ? _drinks : _products;
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
      final customs = list.where((d) => d['id']!.startsWith('custom_')).toList();
      _drinks = [...CatalogData.drinks, ...customs];
      await _persistCustoms(_drinksKey, customs);
    } else {
      final customs = list.where((p) => p['id']!.startsWith('custom_')).toList();
      _products = [...CatalogData.products, ...customs];
      await _persistCustoms(_productsKey, customs);
    }
    notifyListeners();
  }

  Future<void> removeItem(String id, {required bool isDrink}) async {
    if (!id.startsWith('custom_')) return;
    if (isDrink) {
      final customs = _drinks.where((d) => d['id']!.startsWith('custom_') && d['id'] != id).toList();
      _drinks = [...CatalogData.drinks, ...customs];
      await _persistCustoms(_drinksKey, customs);
    } else {
      final customs = _products.where((p) => p['id']!.startsWith('custom_') && p['id'] != id).toList();
      _products = [...CatalogData.products, ...customs];
      await _persistCustoms(_productsKey, customs);
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
