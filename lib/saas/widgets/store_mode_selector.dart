import 'package:flutter/material.dart';

import '../../core/app_fonts.dart';
import '../../core/app_locale.dart';
import '../../core/app_theme_mode.dart';
import '../../core/bakery_navigator.dart';
import '../../core/bakery_square_palette.dart';
import '../../core/manager_store.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../data/saas_repository.dart';
import '../models/saas_models.dart';
import '../utils/appointment_strings.dart';

/// Products vs appointments — inline buttons or bottom square tiles.
class StoreModeSelector extends StatefulWidget {
  const StoreModeSelector({
    super.key,
    this.business,
    this.onBusinessChanged,
    this.squareTiles = false,
  });

  final SaasBusiness? business;
  final ValueChanged<SaasBusiness>? onBusinessChanged;
  final bool squareTiles;

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
    if (widget.squareTiles) {
      return _buildSquareTiles(context);
    }
    return _buildInlineButtons(context);
  }

  Widget _buildSquareTiles(BuildContext context) {
    final strings = AppLocale.instance.s;
    final accent = BakeryTheme.accent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.managerActionStoreMode,
          textAlign: TextAlign.center,
          style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          strings.managerActionStoreModeSub,
          textAlign: TextAlign.center,
          style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.3),
        ),
        if (_saving) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _StoreModeSquare(
                  label: AppointmentStrings.productsShort,
                  icon: Icons.storefront_outlined,
                  selected: _mode == 'products',
                  enabled: !_saving,
                  onTap: () => _save('products'),
                  onInfo: () => _showModeInfo(
                    AppointmentStrings.productsShort,
                    AppointmentStrings.productStoreSub,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _StoreModeSquare(
                  label: AppointmentStrings.appointmentsShort,
                  icon: Icons.calendar_month_outlined,
                  selected: _mode == 'appointments',
                  enabled: !_saving,
                  onTap: () => _save('appointments'),
                  onInfo: () => _showModeInfo(
                    AppointmentStrings.appointmentsShort,
                    AppointmentStrings.appointmentBookingSub,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _mode == 'appointments'
              ? AppointmentStrings.appointmentBookingSub
              : AppointmentStrings.productStoreSub,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: BakeryTheme.subtitleText(context, fontSize: 12, height: 1.3).copyWith(
            color: accent.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineButtons(BuildContext context) {
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

class _StoreModeSquare extends StatelessWidget {
  const _StoreModeSquare({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.onInfo,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final accent = BakeryTheme.accent(context);
    final titleColor = BakerySquarePalette.title(context);

    return BakerySquarePalette.shell(
      context: context,
      borderRadius: 20,
      border: selected
          ? Border.all(color: accent, width: 2)
          : BakerySquarePalette.squareBorder(context),
      color: selected ? accent.withValues(alpha: 0.12) : BakerySquarePalette.squareFill(context),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 34, color: selected ? accent : titleColor),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.style(
                        fontSize: 17,
                        height: 1.15,
                        color: titleColor,
                        fontWeight: AppFonts.bold,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(height: 8),
                      Icon(Icons.check_circle_rounded, color: accent, size: 22),
                    ],
                  ],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, end: 4),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(Icons.info_outline_rounded, size: 18, color: BakeryTheme.muted(context)),
                  onPressed: onInfo,
                ),
              ),
            ),
          ],
        ),
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
