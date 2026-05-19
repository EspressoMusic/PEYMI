import 'package:flutter/material.dart';

import 'core/app_locale.dart';
import 'core/app_theme_mode.dart';
import 'core/business_store.dart';
import 'core/catalog_data.dart';
AppStrings get _s => AppLocale.instance.s;

class _EmployeePanel extends StatelessWidget {
  const _EmployeePanel({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: BakeryTheme.panelGradient(context),
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BakeryTheme.border(context), width: 1.2),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))]
            : const [
                BoxShadow(color: Color(0x38000000), blurRadius: 16, offset: Offset(0, 8)),
                BoxShadow(color: Color(0x18FFFFFF), blurRadius: 8, offset: Offset(-2, -3)),
              ],
      ),
      child: child,
    );
  }
}

class EmployeeHomePage extends StatelessWidget {
  const EmployeeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(strings.employeePanel, style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w800)),
        leading: IconButton(
          tooltip: strings.exit,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.logout_rounded),
        ),
      ),
      body: ListenableBuilder(
        listenable: BusinessStore.instance,
        builder: (context, _) {
          final store = BusinessStore.instance;
          final orders = store.recentOrders;
          final prep = store.preparationTotals;
          final prepUnits = store.preparationUnitCount;
          final he = AppLocale.instance.isHebrew;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(strings.employeePanelSub, style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.35)),
              const SizedBox(height: 16),
              _EmployeePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_rounded, color: BakeryTheme.accent(context), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.managerPrepSummary,
                            style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (prepUnits > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BakeryTheme.accent(context).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$prepUnits',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: BakeryTheme.accent(context),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (prep.isEmpty)
                      Text(strings.managerPrepEmpty, style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.4))
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: prep.entries
                            .map((e) => _EmployeePrepChip(name: e.key, quantity: e.value))
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(strings.managerRecentOrders, style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (orders.isEmpty)
                _EmployeePanel(child: Text(strings.managerNoOrdersYet, style: BakeryTheme.subtitleText(context)))
              else
                ...orders.take(20).map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EmployeePanel(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(o.id, style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800)),
                              const Spacer(),
                              Text(o.total, style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          Text(_formatOrderTime(o.createdAtMs, he), style: BakeryTheme.subtitleText(context, fontSize: 12)),
                          const SizedBox(height: 8),
                          ...o.lines.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('${line.name} ×${line.quantity}', style: BakeryTheme.subtitleText(context, fontSize: 14)),
                            ),
                          ),
                          if (o.lines.isEmpty && o.summary.isNotEmpty)
                            Text(o.summary, style: BakeryTheme.subtitleText(context, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _formatOrderTime(int ms, bool hebrew) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return hebrew ? '$day/$month · $hour:$min' : '$month/$day · $hour:$min';
  }
}

class _EmployeePrepChip extends StatelessWidget {
  const _EmployeePrepChip({required this.name, required this.quantity});

  final String name;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final accent = BakeryTheme.accent(context);
    final visual = CatalogData.visualForLineName(name);
    return Container(
      width: 108,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BakeryTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          if (visual != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                visual.image,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(visual.emoji, style: const TextStyle(fontSize: 28)),
              ),
            )
          else
            const Text('🥖', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: BakeryTheme.text(context, fontSize: 12, fontWeight: FontWeight.w700, height: 1.15),
          ),
          const SizedBox(height: 6),
          Text('×$quantity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: accent)),
        ],
      ),
    );
  }
}
