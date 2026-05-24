import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_creator_unlock.dart';
import '../../core/app_locale.dart';
import '../../core/app_theme_mode.dart';
import '../../core/bakery_navigator.dart';
import '../../core/manager_store.dart';
import '../../core/public_store_links.dart';
import '../../widgets/bakery_celebration.dart';
import '../data/saas_repository.dart';
import '../models/saas_models.dart';

enum _CreatorStoreFilter { all, open, paymentIssues, disabled }

/// App creator dashboard — all businesses (via creator password or super_admin role).
class AppCreatorDashboardScreen extends StatefulWidget {
  const AppCreatorDashboardScreen({super.key});

  @override
  State<AppCreatorDashboardScreen> createState() => _AppCreatorDashboardScreenState();
}

class _AppCreatorDashboardScreenState extends State<AppCreatorDashboardScreen> {
  List<SaasBusinessAdminRow> _rows = [];
  var _loading = true;
  String _query = '';
  String? _error;
  _CreatorStoreFilter _filter = _CreatorStoreFilter.all;
  String? _updatingBusinessId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final password = AppCreatorUnlock.sessionPassword;
      if (password == null) {
        throw Exception('Not unlocked');
      }
      final rows = await SaasRepository.instance.fetchAllBusinessesForCreator(password);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool _isStoreDisabled(SaasBusiness b) =>
      !b.isActive || b.subscriptionStatus == 'suspended' || b.subscriptionStatus == 'cancelled';

  bool _isStoreOpen(SaasBusiness b) => b.isActive && !_isStoreDisabled(b);

  bool _hasPaymentIssue(SaasBusiness b) =>
      _isStoreDisabled(b) || b.subscriptionStatus == 'past_due';

  bool _matchesFilter(SaasBusiness b) {
    switch (_filter) {
      case _CreatorStoreFilter.open:
        return _isStoreOpen(b);
      case _CreatorStoreFilter.paymentIssues:
        return _hasPaymentIssue(b);
      case _CreatorStoreFilter.disabled:
        return _isStoreDisabled(b);
      case _CreatorStoreFilter.all:
        return true;
    }
  }

  List<SaasBusinessAdminRow> get _filtered {
    final q = _query.trim().toLowerCase();
    return _rows.where((r) {
      if (!_matchesFilter(r.business)) return false;
      if (q.isEmpty) return true;
      return r.business.businessName.toLowerCase().contains(q) ||
          r.business.slug.toLowerCase().contains(q) ||
          (r.ownerEmail?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _setStatus(
    SaasBusiness b, {
    bool? isActive,
    String? status,
    String? storeMode,
  }) async {
    final password = AppCreatorUnlock.sessionPassword;
    if (password == null) return;
    setState(() => _updatingBusinessId = b.id);
    try {
      await SaasRepository.instance.creatorUpdateBusiness(
        password: password,
        businessId: b.id,
        isActive: isActive,
        subscriptionStatus: status,
        storeMode: storeMode,
      );
      if (!mounted) return;
      await showBakeryUpdateBanner(context, title: AppLocale.instance.s.appCreatorUpdateOk);
      await _load();
    } catch (e) {
      if (!mounted) return;
      unawaited(showBakeryNoticeBanner(context, title: '${AppLocale.instance.s.appCreatorUpdateFailed}: $e', isError: true));
    } finally {
      if (mounted) setState(() => _updatingBusinessId = null);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    bool destructive = false,
  }) async {
    final strings = AppLocale.instance.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: BakeryTheme.text(ctx, fontWeight: FontWeight.w800)),
        content: Text(body, style: BakeryTheme.subtitleText(ctx, height: 1.35)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _hardLockStore(SaasBusiness b) async {
    final strings = AppLocale.instance.s;
    if (!await _confirm(
      title: strings.appCreatorHardLock,
      body: strings.appCreatorHardLockConfirm(b.businessName),
      destructive: true,
    )) {
      return;
    }
    await _setStatus(b, isActive: false, status: 'cancelled');
  }

  Future<void> _openFullControl(SaasBusiness b) async {
    final strings = AppLocale.instance.s;
    if (!await _confirm(
      title: strings.appCreatorFullControl,
      body: strings.appCreatorFullControlConfirm(b.businessName),
    )) {
      return;
    }
    await ManagerStore.instance.linkOnlineBusiness(
      id: b.id,
      slug: b.slug,
      storeMode: b.storeMode,
      contactEmail: b.contactEmail,
    );
    if (!mounted) return;
    await pushProgrammerManagerHome();
  }

  Future<void> _setStoreMode(SaasBusiness b, String mode) async {
    if (b.storeMode == mode) return;
    await _setStatus(b, storeMode: mode);
  }

  Future<void> _disableForNonPayment(SaasBusiness b) async {
    final strings = AppLocale.instance.s;
    if (!await _confirm(
      title: strings.appCreatorDisableConfirmTitle,
      body: strings.appCreatorDisableConfirmBody(b.businessName),
      destructive: true,
    )) {
      return;
    }
    await _setStatus(b, isActive: false, status: 'suspended');
  }

  Future<void> _reenableStore(SaasBusiness b) async {
    final strings = AppLocale.instance.s;
    if (!await _confirm(
      title: strings.appCreatorReenableConfirmTitle,
      body: strings.appCreatorReenableConfirmBody(b.businessName),
    )) {
      return;
    }
    await _setStatus(b, isActive: true, status: 'active');
  }

  String _statusLabel(SaasBusiness b, AppStrings strings) {
    if (_isStoreDisabled(b)) return strings.appCreatorStoreDisabled;
    if (b.subscriptionStatus == 'past_due') return strings.appCreatorPaymentOverdue;
    if (b.subscriptionStatus == 'trial') return strings.appCreatorStatusTrial;
    if (b.subscriptionStatus == 'active') return strings.appCreatorStoreOpen;
    if (b.subscriptionStatus == 'cancelled') return strings.appCreatorStatusCancelled;
    if (b.subscriptionStatus == 'suspended') return strings.appCreatorStatusSuspended;
    return b.subscriptionStatus;
  }

  Color _statusColor(BuildContext context, SaasBusiness b) {
    if (_isStoreDisabled(b)) return Theme.of(context).colorScheme.error;
    if (b.subscriptionStatus == 'past_due') return Colors.orange.shade700;
    if (b.subscriptionStatus == 'active' || b.subscriptionStatus == 'trial') {
      return Colors.green.shade700;
    }
    return BakeryTheme.muted(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(strings.appCreatorDashboardTitle, style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              strings.appCreatorDashboardSub,
              style: BakeryTheme.subtitleText(context, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: bakeryInputDecoration(
                context,
                label: strings.appCreatorSearch,
                icon: Icons.search_rounded,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: strings.appCreatorFilterAll,
                  selected: _filter == _CreatorStoreFilter.all,
                  onTap: () => setState(() => _filter = _CreatorStoreFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: strings.appCreatorFilterOpen,
                  selected: _filter == _CreatorStoreFilter.open,
                  onTap: () => setState(() => _filter = _CreatorStoreFilter.open),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: strings.appCreatorFilterPayment,
                  selected: _filter == _CreatorStoreFilter.paymentIssues,
                  onTap: () => setState(() => _filter = _CreatorStoreFilter.paymentIssues),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: strings.appCreatorFilterDisabled,
                  selected: _filter == _CreatorStoreFilter.disabled,
                  onTap: () => setState(() => _filter = _CreatorStoreFilter.disabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center, style: BakeryTheme.subtitleText(context)),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(child: Text(strings.appCreatorNoBusinesses, style: BakeryTheme.subtitleText(context)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final row = _filtered[index];
                                final b = row.business;
                                final disabled = _isStoreDisabled(b);
                                final busy = _updatingBusinessId == b.id;
                                final statusColor = _statusColor(context, b);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: disabled
                                          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.55)
                                          : BakeryTheme.border(context),
                                      width: disabled ? 1.5 : 1,
                                    ),
                                  ),
                                  child: ExpansionTile(
                                    leading: Icon(
                                      disabled ? Icons.block_rounded : Icons.storefront_rounded,
                                      color: statusColor,
                                    ),
                                    title: Text(
                                      b.businessName,
                                      style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                                          ),
                                          child: Text(
                                            _statusLabel(b, strings),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${PublicStoreLinks.publicUrlForSlug(b.slug)}\n${row.ownerEmail ?? '—'}',
                                          style: BakeryTheme.subtitleText(context, fontSize: 12, height: 1.3),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              strings.appCreatorStoreDetails,
                                              style: BakeryTheme.text(context, fontSize: 14, fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 8),
                                            _DetailLine(
                                              label: AppLocale.instance.isHebrew ? 'Slug' : 'Slug',
                                              value: b.slug,
                                            ),
                                            _DetailLine(
                                              label: AppLocale.instance.isHebrew ? 'בעלים' : 'Owner',
                                              value: row.ownerEmail ?? '—',
                                            ),
                                            if (b.phone?.trim().isNotEmpty == true)
                                              _DetailLine(
                                                label: AppLocale.instance.isHebrew ? 'טלפון' : 'Phone',
                                                value: b.phone!.trim(),
                                              ),
                                            if (b.contactEmail?.trim().isNotEmpty == true)
                                              _DetailLine(
                                                label: AppLocale.instance.isHebrew ? 'מייל לפניות' : 'Inquiry email',
                                                value: b.contactEmail!.trim(),
                                              ),
                                            if (b.address?.trim().isNotEmpty == true)
                                              _DetailLine(
                                                label: AppLocale.instance.isHebrew ? 'כתובת' : 'Address',
                                                value: b.address!.trim(),
                                              ),
                                            if (b.businessType?.trim().isNotEmpty == true)
                                              _DetailLine(
                                                label: AppLocale.instance.isHebrew ? 'סוג עסק' : 'Business type',
                                                value: b.businessType!.trim(),
                                              ),
                                            if (b.description?.trim().isNotEmpty == true)
                                              _DetailLine(
                                                label: AppLocale.instance.isHebrew ? 'תיאור' : 'Description',
                                                value: b.description!.trim(),
                                              ),
                                            _DetailLine(
                                              label: AppLocale.instance.isHebrew ? 'מצב חנות' : 'Store mode',
                                              value: b.storeMode,
                                            ),
                                          ],
                                        ),
                                      ),
                                      ListTile(
                                        dense: true,
                                        title: Text(
                                          '${strings.appCreatorStatus}: ${b.subscriptionStatus} · ${b.isActive ? strings.appCreatorActive : strings.appCreatorInactive}',
                                          style: BakeryTheme.subtitleText(context, fontSize: 13),
                                        ),
                                      ),
                                      ListTile(
                                        dense: true,
                                        title: Text(
                                          strings.appCreatorCounts(
                                            row.productCount,
                                            row.orderCount,
                                            row.appointmentCount,
                                            row.customerCount,
                                          ),
                                          style: BakeryTheme.subtitleText(context, fontSize: 13),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            FilledButton.icon(
                                              onPressed: busy ? null : () => _openFullControl(b),
                                              icon: const Icon(Icons.admin_panel_settings_outlined),
                                              label: Text(strings.appCreatorFullControl),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                FilterChip(
                                                  label: Text(strings.appCreatorSetProductsMode),
                                                  selected: b.isProductMode,
                                                  onSelected: busy ? null : (_) => _setStoreMode(b, 'products'),
                                                ),
                                                FilterChip(
                                                  label: Text(strings.appCreatorSetAppointmentsMode),
                                                  selected: b.isAppointmentMode,
                                                  onSelected: busy ? null : (_) => _setStoreMode(b, 'appointments'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            if (disabled)
                                              FilledButton.icon(
                                                onPressed: busy ? null : () => _reenableStore(b),
                                                icon: busy
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    : const Icon(Icons.check_circle_outline),
                                                label: Text(strings.appCreatorReenableStore),
                                              )
                                            else ...[
                                              FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.error,
                                                  foregroundColor: Theme.of(context).colorScheme.onError,
                                                ),
                                                onPressed: busy ? null : () => _disableForNonPayment(b),
                                                icon: busy
                                                    ? SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Theme.of(context).colorScheme.onError,
                                                        ),
                                                      )
                                                    : const Icon(Icons.block_rounded),
                                                label: Text(strings.appCreatorLockStore),
                                              ),
                                              const SizedBox(height: 8),
                                              OutlinedButton.icon(
                                                onPressed: busy
                                                    ? null
                                                    : () => _setStatus(b, isActive: true, status: 'past_due'),
                                                icon: const Icon(Icons.warning_amber_rounded),
                                                label: Text(strings.appCreatorMarkPastDue),
                                              ),
                                              const SizedBox(height: 8),
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Theme.of(context).colorScheme.error,
                                                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                                                ),
                                                onPressed: busy ? null : () => _hardLockStore(b),
                                                icon: const Icon(Icons.gpp_bad_outlined),
                                                label: Text(strings.appCreatorHardLock),
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                FilledButton.tonal(
                                                  onPressed: busy
                                                      ? null
                                                      : () => _setStatus(b, isActive: true, status: 'active'),
                                                  child: Text(strings.appCreatorActivate),
                                                ),
                                                FilledButton.tonal(
                                                  onPressed: busy
                                                      ? null
                                                      : () => _setStatus(b, isActive: true, status: 'trial'),
                                                  child: Text(strings.appCreatorTrial),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: BakeryTheme.text(context, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: value,
              style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
