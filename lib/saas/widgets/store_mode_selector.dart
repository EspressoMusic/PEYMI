import 'package:flutter/material.dart';

import '../../core/app_locale.dart';
import '../../core/bakery_navigator.dart';
import '../../core/manager_store.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../data/saas_repository.dart';
import '../models/saas_models.dart';
import '../utils/appointment_strings.dart';

/// Two-button store mode: products or appointments.
class StoreModeSelector extends StatefulWidget {
  const StoreModeSelector({
    super.key,
    this.business,
    this.onBusinessChanged,
  });

  final SaasBusiness? business;
  final ValueChanged<SaasBusiness>? onBusinessChanged;

  @override
  State<StoreModeSelector> createState() => _StoreModeSelectorState();
}

class _StoreModeSelectorState extends State<StoreModeSelector> {
  late String _mode;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.business?.storeMode ?? ManagerStore.instance.customerPanelMode;
  }

  @override
  void didUpdateWidget(covariant StoreModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.business?.storeMode ?? ManagerStore.instance.customerPanelMode;
    if (next != _mode) _mode = next;
  }

  Future<void> _save(String mode) async {
    if (_mode == mode || _saving) return;
    setState(() {
      _mode = mode;
      _saving = true;
    });

    try {
      if (mode == 'appointments' && !ManagerStore.instance.hasLinkedBusiness) {
        await ManagerStore.instance.ensureDemoStoreLinked(preferAppointments: true);
      }
      await ManagerStore.instance.setCustomerPanelMode(mode);

      var syncedOnline = false;
      final biz = widget.business;
      if (SupabaseBootstrap.isReady &&
          biz != null &&
          SaasRepository.instance.currentUser != null) {
        await SaasRepository.instance.setBusinessStoreMode(
          businessId: biz.id,
          storeMode: mode,
        );
        final fresh = await SaasRepository.instance.fetchBusinessBySlug(biz.slug);
        if (fresh != null) {
          await ManagerStore.instance.linkOnlineBusiness(
            id: fresh.id,
            slug: fresh.slug,
            storeMode: fresh.storeMode,
          );
          widget.onBusinessChanged?.call(fresh);
          syncedOnline = true;
        }
      }

      _showSnack(
        syncedOnline
            ? (AppointmentStrings.isHebrew
                ? 'עודכן: ${mode == 'appointments' ? AppointmentStrings.appointmentsShort : AppointmentStrings.productsShort}'
                : 'Updated: ${mode == 'appointments' ? AppointmentStrings.appointmentsShort : AppointmentStrings.productsShort}')
            : AppLocale.instance.s.managerStoreModeLocalOnly(
                mode == 'appointments'
                    ? AppointmentStrings.appointmentsShort
                    : AppointmentStrings.productsShort,
              ),
      );
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
        setState(() => _mode = ManagerStore.instance.customerPanelMode);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    final root = bakeryNavigatorKey.currentContext;
    if (root == null) return;
    ScaffoldMessenger.of(root).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showModeInfo(String title, String body) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppointmentStrings.isHebrew ? 'סגור' : 'Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ModeChoiceButton(
                  label: AppointmentStrings.productsShort,
                  selected: _mode == 'products',
                  enabled: !_saving,
                  onPressed: () => _save('products'),
                  onInfo: () => _showModeInfo(
                    AppointmentStrings.productsShort,
                    AppointmentStrings.productStoreSub,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeChoiceButton(
                  label: AppointmentStrings.appointmentsShort,
                  selected: _mode == 'appointments',
                  enabled: !_saving,
                  onPressed: () => _save('appointments'),
                  onInfo: () => _showModeInfo(
                    AppointmentStrings.appointmentsShort,
                    AppointmentStrings.appointmentBookingSub,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeChoiceButton extends StatelessWidget {
  const _ModeChoiceButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    required this.onInfo,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: selected ? scheme.primary : scheme.surfaceContainerHighest,
              foregroundColor: selected ? scheme.onPrimary : scheme.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Icon(Icons.info_outline, size: 20, color: scheme.primary.withValues(alpha: 0.85)),
          onPressed: onInfo,
        ),
      ],
    );
  }
}
