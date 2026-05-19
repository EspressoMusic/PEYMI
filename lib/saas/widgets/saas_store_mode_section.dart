import 'package:flutter/material.dart';

import '../../core/manager_store.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../data/saas_repository.dart';
import '../models/saas_models.dart';
import 'store_mode_selector.dart';

/// Store mode control for manager panel — no separate sign-in required.
class SaasStoreModeSection extends StatefulWidget {
  const SaasStoreModeSection({super.key, this.onBusinessChanged});

  final ValueChanged<SaasBusiness>? onBusinessChanged;

  @override
  State<SaasStoreModeSection> createState() => _SaasStoreModeSectionState();
}

class _SaasStoreModeSectionState extends State<SaasStoreModeSection> {
  SaasBusiness? _business;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseBootstrap.isReady) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      SaasBusiness? biz;
      if (SaasRepository.instance.currentUser != null) {
        biz = await SaasRepository.instance.fetchOwnedBusiness();
      }
      if (biz == null && ManagerStore.instance.hasLinkedBusiness) {
        biz = await SaasRepository.instance.fetchBusinessBySlug(
          ManagerStore.instance.linkedBusinessSlug!,
        );
      }
      if (biz != null) {
        await ManagerStore.instance.linkOnlineBusiness(
          id: biz.id,
          slug: biz.slug,
          storeMode: biz.storeMode,
        );
      }
      if (!mounted) return;
      setState(() {
        _business = biz;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }

    return StoreModeSelector(
      business: _business,
      onBusinessChanged: (b) {
        setState(() => _business = b);
        widget.onBusinessChanged?.call(b);
      },
    );
  }
}
