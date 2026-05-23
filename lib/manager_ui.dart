import 'package:flutter/material.dart';
import 'core/bakery_square_palette.dart';
import 'core/app_locale.dart';
import 'core/app_theme_mode.dart';
import 'core/business_health.dart';
import 'core/business_store.dart';
import 'core/catalog_data.dart';
import 'core/keyboard_safe.dart';
import 'core/manager_notifications_store.dart';
import 'core/manager_store.dart';
import 'core/policy_consent_store.dart';
import 'core/public_store_links.dart';
import 'core/reviews_store.dart';
import 'manager_action_pages.dart';
import 'saas/app_creator_flow.dart';
import 'saas/saas_flow.dart';
import 'widgets/app_creator_six_tap.dart';
import 'widgets/bakery_bottom_bar.dart';
import 'widgets/business_health_ring.dart';
import 'widgets/accessibility_panel_sheet.dart';
import 'widgets/policy_consent_gate.dart';

AppStrings get _s => AppLocale.instance.s;

class ManagerHomePage extends StatefulWidget {
  const ManagerHomePage({super.key});

  @override
  State<ManagerHomePage> createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> {
  int _tab = 0;

  static const _tabCount = 2;

  @override
  void initState() {
    super.initState();
    _tab = _tab.clamp(0, _tabCount - 1);
  }

  void _selectTab(int index) {
    setState(() => _tab = index.clamp(0, _tabCount - 1));
  }

  static IconData _notificationIcon(ManagerNotificationKind kind) {
    switch (kind) {
      case ManagerNotificationKind.order:
        return Icons.receipt_long_rounded;
      case ManagerNotificationKind.review:
        return Icons.star_rounded;
      case ManagerNotificationKind.inquiry:
      case ManagerNotificationKind.problem:
        return Icons.report_problem_rounded;
    }
  }

  void _openNotifications() {
    final strings = _s;
    final he = AppLocale.instance.isHebrew;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: ManagerNotificationsStore.instance,
          builder: (context, _) {
            final items = ManagerNotificationsStore.instance.items;
            return bakeryModalSheetFrame(
              ctx,
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (items.any((n) => !n.read))
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => ManagerNotificationsStore.instance.markAllRead(),
                        child: Text(strings.managerMarkAllRead),
                      ),
                    ),
                  if (items.any((n) => !n.read)) const SizedBox(height: 4),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        strings.managerNoNotifications,
                        textAlign: TextAlign.center,
                        style: BakeryTheme.subtitleText(ctx, fontSize: 15),
                      ),
                    )
                  else
                    ...items.map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          tileColor: n.read
                              ? BakeryTheme.cardSurface(ctx).withValues(alpha: 0.5)
                              : BakeryTheme.accent(ctx).withValues(alpha: 0.12),
                          leading: Icon(_notificationIcon(n.kind), color: BakeryTheme.accent(ctx)),
                          title: Text(
                            n.title(he),
                            style: BakeryTheme.text(ctx, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(n.body(he), style: BakeryTheme.subtitleText(ctx, fontSize: 13)),
                          onTap: () => ManagerNotificationsStore.instance.markRead(n.id),
                        ),
                      ),
                    ),
                ],
              ),
              title: strings.managerNotifications,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PolicyConsentGate(
      audience: PolicyAudience.owner,
      child: _ManagerShell(
        tab: _tab,
        onTab: _selectTab,
        onOpenNotifications: _openNotifications,
      ),
    );
  }
}

class _ManagerShell extends StatelessWidget {
  const _ManagerShell({
    required this.tab,
    required this.onTab,
    required this.onOpenNotifications,
  });

  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onOpenNotifications;

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
        automaticallyImplyLeading: true,
        title: const SizedBox.shrink(),
        toolbarHeight: 44,
        actions: [
          if (tab == 0) _ManagerNotificationButton(onOpen: onOpenNotifications),
        ],
      ),
      body: IndexedStack(
        index: tab.clamp(0, 1),
        children: [
          _ManagerDashboardTab(isVisible: tab == 0),
          const _ManagerActionsTab(),
        ],
      ),
      bottomNavigationBar: BakeryBottomBar(
        selectedIndex: tab.clamp(0, 1),
        onSelected: onTab,
        items: [
          (icon: Icons.dashboard_rounded, label: strings.managerNavDashboard),
          (icon: Icons.bolt_rounded, label: strings.managerNavActions),
        ],
      ),
    );
  }
}

class _ManagerNotificationButton extends StatelessWidget {
  const _ManagerNotificationButton({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    return ListenableBuilder(
      listenable: ManagerNotificationsStore.instance,
      builder: (context, _) {
        final unread = ManagerNotificationsStore.instance.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: strings.managerNotifications,
              onPressed: onOpen,
              iconSize: 30,
              icon: const Icon(Icons.notifications_rounded),
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ManagerDashboardTab extends StatefulWidget {
  const _ManagerDashboardTab({required this.isVisible});

  final bool isVisible;

  @override
  State<_ManagerDashboardTab> createState() => _ManagerDashboardTabState();
}

class _ManagerDashboardTabState extends State<_ManagerDashboardTab> {
  static String _formatOrderTime(int ms, bool hebrew) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return hebrew ? '$day/$month · $hour:$min' : '$month/$day · $hour:$min';
  }

  void _openOrdersDetailSheet(BuildContext context, List<BusinessOrderRecord> orders) {
    final strings = _s;
    final he = AppLocale.instance.isHebrew;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        return bakeryModalSheetFrame(
          ctx,
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (orders.isEmpty)
                Text(strings.managerNoOrdersYet, style: BakeryTheme.subtitleText(ctx))
              else
                ...orders.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ManagerPanel(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(o.id, style: BakeryTheme.text(ctx, fontSize: 16, fontWeight: FontWeight.w800)),
                              const Spacer(),
                              Text(o.total, style: BakeryTheme.text(ctx, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          Text(
                            _formatOrderTime(o.createdAtMs, he),
                            style: BakeryTheme.subtitleText(ctx, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          ...o.lines.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  _PrepLineThumb(name: line.name, size: 36),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('${line.name} ×${line.quantity}')),
                                ],
                              ),
                            ),
                          ),
                          if (o.lines.isEmpty)
                            Text(o.summary, style: BakeryTheme.subtitleText(ctx, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: strings.managerPrepDetails,
        );
      },
    );
  }

  void _handleHealthAction(BuildContext context, HealthIssueAction action) {
    switch (action.kind) {
      case HealthIssueKind.poorReview:
        final index = action.reviewIndex;
        if (index == null) return;
        openManagerPage(context, ManagerCustomersPage(initialReviewIndex: index));
        break;
      case HealthIssueKind.customerInquiries:
        openManagerPage(context, const ManagerCustomersPage());
        break;
    }
  }

  List<HealthRingBadge> _issueBadges(BuildContext context, BusinessHealthSnapshot snapshot) {
    final he = AppLocale.instance.isHebrew;
    final seen = <String>{};
    final badges = <HealthRingBadge>[];

    for (final f in snapshot.actionableFactors) {
      final action = f.action!;
      final key = switch (action.kind) {
        HealthIssueKind.poorReview => 'review_${action.reviewIndex}',
        HealthIssueKind.customerInquiries => 'inquiries',
      };
      if (!seen.add(key)) continue;
      badges.add(
        HealthRingBadge(
          icon: f.icon,
          tooltip: f.title(he),
          onTap: () => _handleHealthAction(context, action),
        ),
      );
    }
    return badges;
  }

  void _openHealthSheet(BuildContext context, BusinessHealthSnapshot snapshot) {
    final strings = _s;
    final he = AppLocale.instance.isHebrew;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        return bakeryModalSheetFrame(
          ctx,
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                '${snapshot.percent}% · ${healthLabel(he, snapshot.level)}',
                style: BakeryTheme.subtitleText(ctx, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (snapshot.factors.isEmpty)
                Text(
                  strings.managerHealthPerfect,
                  style: BakeryTheme.text(ctx, fontSize: 15, fontWeight: FontWeight.w600),
                )
              else
                ...snapshot.factors.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: BakeryTheme.cardSurface(ctx),
                      leading: Icon(
                        f.icon,
                        color: f.isActionable ? const Color(0xFFE53935) : BakeryTheme.accent(ctx),
                      ),
                      title: Text(
                        f.title(he),
                        style: BakeryTheme.text(ctx, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        f.detail(he),
                        style: BakeryTheme.subtitleText(ctx, fontSize: 13, height: 1.35),
                      ),
                      trailing: f.isActionable
                          ? const Icon(Icons.chevron_left_rounded, color: Color(0xFFE53935))
                          : null,
                      onTap: f.isActionable
                          ? () {
                              Navigator.pop(ctx);
                              _handleHealthAction(context, f.action!);
                            }
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          title: strings.managerHealthWhy,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: ManagerStore.instance,
          builder: (context, _) {
            final shareSlug = ManagerStore.instance.linkedBusinessSlug?.trim();
            final hasShareLink = shareSlug != null && shareSlug.isNotEmpty;
            final shareUrl = hasShareLink ? PublicStoreLinks.publicUrlForSlug(shareSlug) : null;
            return _ManagerShareStoreButton(
              strings: strings,
              hasLink: hasShareLink,
              linkPreview: shareUrl,
              onTap: () => openManagerShareFlow(context),
            );
          },
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: Listenable.merge([BusinessStore.instance, ReviewsStore.instance]),
          builder: (context, _) {
            final store = BusinessStore.instance;
            final snapshot = analyzeBusinessHealth(
              ordersCount: store.ordersCount,
              inquiriesCount: store.inquiriesCount,
              reviews: ReviewsStore.instance.reviews,
            );
            return Column(
              children: [
                Center(
                  child: AppCreatorSixTapDetector(
                    onTriggered: () => openAppCreatorPasswordGate(context),
                    child: BusinessHealthRing(
                      level: snapshot.level,
                      size: 240,
                      animateWaves: widget.isVisible,
                      issueBadges: _issueBadges(context, snapshot),
                      onTapWhenBelowPerfect: snapshot.isPerfect
                          ? null
                          : () => _openHealthSheet(context, snapshot),
                    ),
                  ),
                ),
                if (!snapshot.isPerfect) ...[
                  const SizedBox(height: 6),
                  Text(
                    snapshot.actionableFactors.isNotEmpty
                        ? strings.managerHealthTapIssue
                        : strings.managerHealthTap,
                    textAlign: TextAlign.center,
                    style: BakeryTheme.subtitleText(context, fontSize: 12),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: BusinessStore.instance,
          builder: (context, _) {
            final store = BusinessStore.instance;
            final orders = store.recentOrders;
            final prep = store.preparationTotals;
            final prepUnits = store.preparationUnitCount;
            return _ManagerPanel(
              padding: const EdgeInsets.all(16),
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
                      if (orders.isNotEmpty)
                        IconButton(
                          tooltip: strings.managerPrepDetails,
                          onPressed: () => _openOrdersDetailSheet(context, orders),
                          icon: Icon(Icons.info_outline_rounded, color: BakeryTheme.accent(context)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (prep.isEmpty)
                    Text(
                      strings.managerPrepEmpty,
                      style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.4),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: prep.entries.map((e) => _PrepQuantityChip(name: e.key, quantity: e.value)).toList(),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ManagerShareStoreButton extends StatelessWidget {
  const _ManagerShareStoreButton({
    required this.strings,
    required this.hasLink,
    required this.onTap,
    this.linkPreview,
  });

  final AppStrings strings;
  final bool hasLink;
  final String? linkPreview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = BakeryTheme.accent(context);

    return Semantics(
      button: true,
      label: strings.managerShareStore,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: _ManagerPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.ios_share_rounded, color: accent, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.managerShareStore,
                        style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasLink
                            ? (linkPreview ?? strings.managerShareStoreSub)
                            : strings.managerShareStoreNoLink,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: BakeryTheme.muted(context), size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrepLineThumb extends StatelessWidget {
  const _PrepLineThumb({required this.name, this.size = 52});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = CatalogData.visualForLineName(name);
    final chipFill = BakerySquarePalette.squareFill(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: chipFill,
        borderRadius: BorderRadius.circular(10),
        border: BakerySquarePalette.squareBorder(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: visual == null
            ? Center(child: Text('🥖', style: TextStyle(fontSize: size * 0.45)))
            : Image.asset(
                visual.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: Text(visual.emoji, style: TextStyle(fontSize: size * 0.45))),
              ),
      ),
    );
  }
}

class _PrepQuantityChip extends StatelessWidget {
  const _PrepQuantityChip({required this.name, required this.quantity});

  final String name;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final accent = BakeryTheme.accent(context);
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
          _PrepLineThumb(name: name, size: 56),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: BakeryTheme.text(context, fontSize: 12, fontWeight: FontWeight.w700, height: 1.15),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '×$quantity',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerActionsTab extends StatelessWidget {
  const _ManagerActionsTab();

  @override
  Widget build(BuildContext context) {
    final strings = _s;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
        children: [
          ManagerActionSquare(
            title: strings.managerActionCustomers,
            subtitle: strings.managerActionCustomersSub,
            icon: Icons.forum_outlined,
            colorIndex: 0,
            onTap: () => openManagerPage(context, const ManagerCustomersPage()),
          ),
          ManagerActionSquare(
            title: strings.managerActionNewDeal,
            subtitle: strings.managerActionNewDealSub,
            icon: Icons.local_offer_outlined,
            colorIndex: 2,
            onTap: () => openManagerPage(context, const ManagerNewDealPage()),
          ),
          ManagerActionSquare(
            title: strings.managerActionSubscriptions,
            subtitle: strings.managerActionSubscriptionsSub,
            icon: Icons.workspace_premium_outlined,
            colorIndex: 1,
            onTap: () => openManagerPage(context, const ManagerSubscriptionsPage()),
          ),
          ManagerActionSquare(
            title: strings.managerActionStore,
            subtitle: strings.managerActionStoreSub,
            icon: Icons.storefront_outlined,
            colorIndex: 3,
            onTap: () => openManagerPage(context, const ManagerStorePage()),
          ),
          ManagerActionSquare(
            title: strings.managerActionStats,
            subtitle: strings.managerActionStatsSub,
            icon: Icons.insights_outlined,
            colorIndex: 4,
            onTap: () => openManagerPage(context, const ManagerStatsPage()),
          ),
          ManagerActionSquare(
            title: strings.managerActionOrderLimits,
            subtitle: strings.managerActionOrderLimitsSub,
            icon: Icons.block_flipped,
            colorIndex: 6,
            onTap: () => openManagerPage(context, const ManagerOrderRestrictionsPage()),
          ),
          ManagerActionSquare(
            title: strings.managerActionFaq,
            subtitle: strings.managerActionFaqSub,
            icon: Icons.quiz_outlined,
            colorIndex: 7,
            onTap: () => openManagerPage(context, const ManagerFaqPage()),
          ),
          ManagerActionSquare(
            title: strings.managerActionStoreTerms,
            subtitle: strings.managerActionStoreTermsSub,
            icon: Icons.gavel_outlined,
            colorIndex: 8,
            onTap: () => openManagerPage(context, const ManagerStoreTermsPage()),
          ),
          ManagerActionSquare(
            title: strings.managerActionAccessibility,
            subtitle: strings.managerActionAccessibilitySub,
            icon: Icons.accessible_forward_rounded,
            colorIndex: 5,
            onTap: () => showAccessibilityPanel(context),
          ),
        ],
      ),
    );
  }
}

class _ManagerPanel extends StatelessWidget {
  const _ManagerPanel({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: BakerySquarePalette.squareFill(context),
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
