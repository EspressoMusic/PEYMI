import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../saas/data/saas_repository.dart';
import 'manager_store.dart';
import 'supabase/supabase_bootstrap.dart';

/// Store-specific terms/regulations — keyed by linked business slug.
class StoreTermsStore extends ChangeNotifier {
  StoreTermsStore._();

  static final StoreTermsStore instance = StoreTermsStore._();

  String _terms = '';
  String? _loadedSlug;

  String get terms => _terms;
  bool get hasTerms => _terms.trim().isNotEmpty;

  static String _prefsKey(String slug) => 'store_terms_v1_$slug';

  Future<void> loadForCurrentStore() async {
    final slug = ManagerStore.instance.linkedBusinessSlug?.trim();
    if (slug == null || slug.isEmpty) {
      _terms = '';
      _loadedSlug = null;
      notifyListeners();
      return;
    }
    await loadForSlug(slug);
  }

  Future<void> loadForSlug(String slug) async {
    final normalized = slug.trim().toLowerCase();
    if (normalized.isEmpty) return;

    _loadedSlug = normalized;
    final prefs = await SharedPreferences.getInstance();
    _terms = prefs.getString(_prefsKey(normalized)) ?? '';

    if (SupabaseBootstrap.isReady) {
      try {
        final business = await SaasRepository.instance.fetchBusinessBySlug(normalized);
        final remote = business?.storeTerms?.trim();
        if (remote != null && remote.isNotEmpty) {
          _terms = remote;
          await prefs.setString(_prefsKey(normalized), _terms);
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> save(String text) async {
    final slug = ManagerStore.instance.linkedBusinessSlug?.trim();
    if (slug == null || slug.isEmpty) {
      throw Exception('No store linked');
    }

    _terms = text.trim();
    _loadedSlug = slug;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey(slug), _terms);

    final businessId = ManagerStore.instance.linkedBusinessId;
    if (SupabaseBootstrap.isReady &&
        businessId != null &&
        businessId.isNotEmpty &&
        businessId != 'local') {
      await SaasRepository.instance.updateBusinessStoreTerms(
        businessId: businessId,
        storeTerms: _terms.isEmpty ? null : _terms,
      );
    }

    notifyListeners();
  }

  void clearIfSlugChanged(String? slug) {
    final next = slug?.trim().toLowerCase();
    if (next == _loadedSlug) return;
    _terms = '';
    _loadedSlug = next;
    notifyListeners();
  }
}
