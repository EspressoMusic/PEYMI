import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/accessibility_settings.dart';
import 'core/app_fonts.dart';
import 'core/app_config_scope.dart';
import 'core/bakery_navigator.dart' show bakeryNavigatorKey, bakeryRootContext, popRouteSafely, waitForNavigatorSettle;
import 'core/app_locale.dart';
import 'core/bakery_square_palette.dart';
import 'core/app_theme_mode.dart';
import 'core/business_store.dart';
import 'core/customer_appointments_store.dart';
import 'core/catalog_store.dart';
import 'core/community_messages_store.dart';
import 'core/faq_store.dart';
import 'core/store_terms_store.dart';
import 'core/catalog_data.dart';
import 'core/keyboard_safe.dart';
import 'core/manager_notifications_store.dart';
import 'core/manager_store.dart';
import 'core/order_restrictions_store.dart';
import 'core/manager_subscription_store.dart';
import 'core/policy_consent_store.dart';
import 'core/reviews_store.dart';
import 'core/staff_auth_config.dart';
import 'core/stripe_payment_service.dart';
import 'core/stripe_config.dart';
import 'manager_action_pages.dart';
import 'widgets/bakery_celebration.dart';
import 'widgets/catalog_item_image.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'employee_ui.dart';
import 'manager_ui.dart';
import 'core/store_deep_links.dart';
import 'saas/saas_flow.dart';
import 'saas/store_routes.dart';
import 'widgets/bakery_bottom_bar.dart';
import 'widgets/home_catalog_slot.dart';
import 'widgets/home_customer_nav_slots.dart';
import 'widgets/store_announcement_panel.dart';
import 'widgets/accessibility_panel_sheet.dart';
import 'widgets/legal_document_screen.dart';
import 'widgets/policy_consent_gate.dart';
import 'widgets/semantic_icon_button.dart';
import 'widgets/customer_tab_body.dart';

AppStrings get s => AppLocale.instance.s;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.instance.load();
  await AppThemeController.instance.load();
  await AccessibilitySettings.instance.load();
  await BusinessStore.instance.load();
  await OrderRestrictionsStore.instance.load();
  await ReviewsStore.instance.load();
  await ManagerStore.instance.load();
  await CustomerAppointmentsStore.instance.load();
  await ManagerNotificationsStore.instance.load();
  await CatalogStore.instance.load();
  await CommunityMessagesStore.instance.load();
  await FaqStore.instance.load();
  await PolicyConsentStore.instance.load();
  await ManagerSubscriptionStore.instance.load();
  await StripePaymentService.initialize();
  await SupabaseBootstrap.init();
  await ManagerStore.instance.ensureDemoStoreLinked(
    preferAppointments: ManagerStore.instance.isAppointmentCustomerMode,
  );
  await StoreTermsStore.instance.loadForCurrentStore();
  await StoreDeepLinks.init();
  runApp(const BakeryApp());
}

class BakeryApp extends StatelessWidget {
  const BakeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme/locale updates go through [AppConfigScope] — do not rebuild [MaterialApp]
    // (that breaks the navigator element tree when pushing manager/employee routes).
    return MaterialApp(
      navigatorKey: bakeryNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppLocale.instance.s.appTitle,
      theme: AppThemeController.instance.theme(),
      builder: (context, child) => AppConfigScope(child: child ?? const SizedBox.shrink()),
      home: const BakeryHomePage(),
      onGenerateRoute: saasRouteFactory,
    );
  }
}

Future<void> showStaffLogin(
  BuildContext context, {
  required String loginTitle,
  required String passwordHint,
  required IconData headerIcon,
  required String password,
  Widget? homePage,
  Future<void> Function(BuildContext context)? onApproved,
  String? alternateActionLabel,
  IconData? alternateActionIcon,
  void Function(BuildContext dialogContext)? onAlternateAction,
}) async {
  final strings = s;
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var authFailed = false;

  void tryLogin(BuildContext dialogContext, StateSetter setDialogState) {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final ok = passwordController.text == password;
    if (!ok) {
      setDialogState(() => authFailed = true);
      formKey.currentState!.validate();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    popRouteSafely(dialogContext, true);
  }

  final dialogHost = bakeryRootContext ?? context;
  if (!dialogHost.mounted) return;

  final approved = await showBakeryDialog<bool>(
    context: dialogHost,
    showCloseButton: false,
    child: StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return _OrdersPanel(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BakeryTheme.cardSurface(dialogContext).withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(headerIcon, size: 40, color: BakeryTheme.accent(dialogContext)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loginTitle,
                  textAlign: TextAlign.center,
                  style: BakeryTheme.text(dialogContext, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  passwordHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.35, color: BakeryTheme.subtitle(dialogContext)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: BakeryTheme.body(dialogContext),
                  ),
                  decoration: bakeryInputDecoration(
                    dialogContext,
                    label: strings.passwordLabel,
                    icon: Icons.lock_outline,
                  ).copyWith(
                    fillColor: BakeryTheme.cardSurface(dialogContext).withValues(alpha: 0.95),
                    errorText: authFailed ? strings.wrongPassword : null,
                    errorStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return strings.enterPassword;
                    }
                    if (authFailed) return strings.wrongPassword;
                    return null;
                  },
                  onChanged: (_) {
                    if (authFailed) setDialogState(() => authFailed = false);
                  },
                  onFieldSubmitted: (_) => tryLogin(dialogContext, setDialogState),
                ),
                const SizedBox(height: 22),
                _OrderSheetActionButton(
                  primary: true,
                  icon: Icons.login_rounded,
                  label: strings.login,
                  onPressed: () => tryLogin(dialogContext, setDialogState),
                ),
                const SizedBox(height: 10),
                _OrderSheetActionButton(
                  icon: alternateActionIcon ?? Icons.close,
                  label: alternateActionLabel ?? strings.cancel,
                  onPressed: () {
                    if (onAlternateAction != null) {
                      onAlternateAction(dialogContext);
                    } else {
                      popRouteSafely(dialogContext, false);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  if (approved != true) {
    WidgetsBinding.instance.addPostFrameCallback((_) => passwordController.dispose());
    return;
  }

  FocusManager.instance.primaryFocus?.unfocus();
  await waitForNavigatorSettle();

  WidgetsBinding.instance.addPostFrameCallback((_) => passwordController.dispose());

  if (onApproved != null) {
    final root = bakeryRootContext;
    if (root == null || !root.mounted) return;
    await onApproved(root);
    return;
  }

  if (homePage != null) {
    final navigator = bakeryNavigatorKey.currentState;
    if (navigator == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => homePage),
      );
    });
  }
}

Future<void> showManagerLogin(BuildContext context) async {
  if (!StaffAuthConfig.isManagerLoginEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manager login is not configured for this build.')),
    );
    return;
  }
  await showStaffLogin(
    context,
    loginTitle: s.managerLoginTitle,
    passwordHint: s.managerPasswordHint,
    headerIcon: Icons.admin_panel_settings,
    password: StaffAuthConfig.effectiveManagerPin,
    alternateActionLabel: s.managerLoginOpenStore,
    alternateActionIcon: Icons.storefront_outlined,
    onAlternateAction: (dialogContext) {
      popRouteSafely(dialogContext, false);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final root = bakeryRootContext;
        if (root == null || !root.mounted) return;
        await openSaasCreateStoreFlow(root);
      });
    },
    onApproved: (ctx) async {
      final proceed = await runManagerLoginStoreEntry(ctx);
      if (!proceed || !ctx.mounted) return;
      await waitForNavigatorSettle();
      if (!ctx.mounted) return;
      final navigator = bakeryNavigatorKey.currentState;
      if (navigator == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator.push<void>(
          MaterialPageRoute<void>(builder: (_) => const ManagerHomePage()),
        );
      });
    },
  );
}

Future<void> showEmployeeLogin(BuildContext context) async {
  if (!StaffAuthConfig.isEmployeeLoginEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee login is not configured for this build.')),
    );
    return;
  }
  await showStaffLogin(
    context,
    loginTitle: s.employeeLoginTitle,
    passwordHint: s.employeePasswordHint,
    headerIcon: Icons.badge_outlined,
    password: StaffAuthConfig.effectiveEmployeePin,
    homePage: const EmployeeHomePage(),
  );
}

Future<void> showReviewDialog(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (sheetContext) => bakeryModalSheetFrame(
      sheetContext,
      const _ReviewSheet(),
    ),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet();

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await ReviewsStore.instance.addReview(
      rating: _rating,
      comment: _commentController.text,
    );
    if (!mounted) return;
    Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.thanksReview)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = s;
    final hebrew = AppLocale.instance.isHebrew;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return ListenableBuilder(
      listenable: ReviewsStore.instance,
      builder: (context, _) {
        final reviews = ReviewsStore.instance.reviews;
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + bottom),
          children: [
                  Text(
                    strings.reviewsCountLabel(reviews.length),
                    textAlign: TextAlign.center,
                    style: BakeryTheme.subtitleText(context, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ...reviews.map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewListCard(review: review, hebrew: hebrew),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OrdersPanel(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    surfaceColor: BakerySquarePalette.squareFill(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.yourReviewSection,
                          textAlign: TextAlign.center,
                          style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.reviewTitle,
                          textAlign: TextAlign.center,
                          style: BakeryTheme.subtitleText(context, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final star = i + 1;
                            final filled = star <= _rating;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() => _rating = star),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                  child: AnimatedScale(
                                    scale: filled ? 1.08 : 1,
                                    duration: const Duration(milliseconds: 160),
                                    curve: Curves.easeOut,
                                    child: Icon(
                                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: filled
                                          ? BakeryTheme.accent(context)
                                          : BakeryTheme.muted(context),
                                      size: 34,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          decoration: bakeryInputDecoration(
                            context,
                            label: strings.reviewHint,
                            icon: Icons.edit_note_outlined,
                          ).copyWith(
                            fillColor: BakeryTheme.inputFill(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _OrderSheetActionButton(
                          primary: true,
                          icon: Icons.send_rounded,
                          label: strings.submitReview,
                          onPressed: _submitting ? null : _submit,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _submitting ? null : () => Navigator.pop(context),
                            child: Text(
                              strings.skip,
                              style: BakeryTheme.subtitleText(context, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _ReviewListCard extends StatelessWidget {
  const _ReviewListCard({required this.review, required this.hebrew});

  final CustomerReview review;
  final bool hebrew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = s;
    final comment = review.comment(hebrew).trim();
    final displayName = review.name(hebrew);
    final initial = displayName.isNotEmpty ? displayName.characters.first : '?';
    final reply = review.managerReply(hebrew).trim();
    final isPoor = review.isPoorReview;

    return _OrdersPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      border: isPoor ? Border.all(color: const Color(0xFFC62828), width: 2.5) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.25),
                  scheme.secondary.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    _ReviewStars(rating: review.rating, size: 18, poorColor: isPoor),
                  ],
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    comment,
                    style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.4),
                  ),
                ],
                if (reply.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    strings.managerBakeryReply,
                    style: BakeryTheme.text(context, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply,
                    style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStars extends StatelessWidget {
  const _ReviewStars({required this.rating, this.size = 16, this.poorColor = false});

  final int rating;
  final double size;
  final bool poorColor;

  @override
  Widget build(BuildContext context) {
    final starColor = poorColor ? const Color(0xFFC62828) : BakeryTheme.accent(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? starColor : BakeryTheme.muted(context).withValues(alpha: 0.45),
        );
      }),
    );
  }
}

class BakeryHomePage extends StatefulWidget {
  const BakeryHomePage({super.key});

  @override
  State<BakeryHomePage> createState() => _BakeryHomePageState();
}

class _BakeryHomePageState extends State<BakeryHomePage> {
  static const int _pageDeals = 1;
  static const int _pageOrders = 2;
  static const int _pageCatalog = 3;
  static const _redeemedDealsKey = 'redeemed_deal_records_v1';
  static const _legacyRedeemedDealsKey = 'redeemed_deal_ids';
  static const _dismissedAnnouncementKey = 'customer_dismissed_announcement_revision';
  static const _redeemVisibleFor = Duration(hours: 2);
  static const int _navDealsIndex = 1;

  int _selectedIndex = _pageCatalog;
  final Map<String, int> _redeemedDealsAt = {};
  bool _dealAlertBadge = false;
  int _dismissedAnnouncementRevision = 0;
  Timer? _redeemExpiryTimer;

  int _navBarIndex(int pageIndex) =>
      AppLocale.instance.isHebrew ? (_pageCatalog - pageIndex) : pageIndex;

  int _pageIndexFromNav(int navIndex) =>
      AppLocale.instance.isHebrew ? (_pageCatalog - navIndex) : navIndex;
  final Map<String, int> _cartQuantities = {};
  final AudioPlayer _cartSoundPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadRedeemedDeals();
    _loadAnnouncementDismissal();
    _redeemExpiryTimer = Timer.periodic(const Duration(minutes: 1), (_) => _onDealsMaintenanceTick());
    ManagerStore.instance.addListener(_onManagerStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDealAlert();
      _checkAnnouncementPopup();
    });
  }

  void _onManagerStoreChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      setState(() {});
      _checkAnnouncementPopup();
    });
  }

  bool get _showStoreAnnouncement {
    final ann = ManagerStore.instance.storeAnnouncement;
    if (!ann.hasContent) return false;
    return ann.revision > _dismissedAnnouncementRevision;
  }

  Future<void> _loadAnnouncementDismissal() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissedAnnouncementRevision = prefs.getInt(_dismissedAnnouncementKey) ?? 0;
    if (mounted) setState(() {});
  }

  Future<void> _dismissStoreAnnouncement() async {
    final rev = ManagerStore.instance.announcementRevision;
    _dismissedAnnouncementRevision = rev;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedAnnouncementKey, rev);
    if (mounted) setState(() {});
  }

  Future<void> _checkAnnouncementPopup() async {
    final popupRev = await ManagerStore.instance.peekAnnouncementPopupRevision();
    if (!mounted || popupRev == null) return;
    if (popupRev <= _dismissedAnnouncementRevision) {
      await ManagerStore.instance.dismissAnnouncementPopup();
      return;
    }
    final he = AppLocale.instance.isHebrew;
    final ann = ManagerStore.instance.storeAnnouncement;
    final message = ann.text(he);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return bakeryModalSheetFrame(
          sheetContext,
          ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              StoreAnnouncementPanel(
                message: message,
                imagePath: ann.imagePath,
                showHeader: false,
                compact: true,
              ),
            ],
          ),
          title: s.storeAnnouncementPopupTitle,
          heightFactor: 0.55,
        );
      },
    );
    await ManagerStore.instance.dismissAnnouncementPopup();
  }

  bool _isRedemptionExpired(int redeemedAtMs) =>
      DateTime.now().millisecondsSinceEpoch - redeemedAtMs >= _redeemVisibleFor.inMilliseconds;

  Set<String> get _activeRedeemedDealIds => _redeemedDealsAt.keys.toSet();

  List<Map<String, dynamic>> get _visibleDeals => _deals.where((d) {
        if (CatalogData.isDealExpired(d)) return false;
        final id = d['id'] as String;
        final at = _redeemedDealsAt[id];
        if (at == null) return true;
        return !_isRedemptionExpired(at);
      }).toList();

  void _onDealsMaintenanceTick() {
    _pruneExpiredRedemptions();
    ManagerStore.instance.pruneExpiredCustomDeals();
    if (mounted) setState(() {});
  }

  Future<void> _checkDealAlert() async {
    final alert = await ManagerStore.instance.peekDealAlert();
    if (!mounted || alert == null) return;
    setState(() => _dealAlertBadge = true);
    final strings = s;
    final he = AppLocale.instance.isHebrew;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${strings.newDealAlertTitle} ${he ? alert.titleHe : alert.titleEn}'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: strings.navDeals,
          onPressed: _openDealsFromAlert,
        ),
      ),
    );
  }

  void _openDealsFromAlert() {
    setState(() {
      _selectedIndex = _pageDeals;
      _dealAlertBadge = false;
    });
    ManagerStore.instance.dismissDealAlert();
  }

  void _onBottomNavSelected(int navIndex) {
    final page = _pageIndexFromNav(navIndex);
    setState(() {
      _selectedIndex = page;
      if (page == _pageDeals && _dealAlertBadge) {
        _dealAlertBadge = false;
        ManagerStore.instance.dismissDealAlert();
      }
    });
  }

  Future<void> _persistRedeemedDeals() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _redeemedDealsAt.entries.map((e) => {'id': e.key, 'at': e.value}).toList();
    await prefs.setString(_redeemedDealsKey, jsonEncode(payload));
  }

  void _pruneExpiredRedemptions() {
    final expired = _redeemedDealsAt.keys.where((id) => _isRedemptionExpired(_redeemedDealsAt[id]!)).toList();
    if (expired.isEmpty) return;
    for (final id in expired) {
      _redeemedDealsAt.remove(id);
    }
    _persistRedeemedDeals();
    if (mounted) setState(() {});
  }

  Future<void> _loadRedeemedDeals() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    _redeemedDealsAt.clear();

    final raw = prefs.getString(_redeemedDealsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final entry in list) {
          if (entry is! Map) continue;
          final id = entry['id']?.toString();
          final at = (entry['at'] as num?)?.toInt();
          if (id == null || at == null) continue;
          if (!_isRedemptionExpired(at)) _redeemedDealsAt[id] = at;
        }
      } catch (_) {}
    }

    final legacy = prefs.getStringList(_legacyRedeemedDealsKey) ?? const [];
    for (final id in legacy) {
      if (!_redeemedDealsAt.containsKey(id)) _redeemedDealsAt[id] = now;
    }
    if (legacy.isNotEmpty) await prefs.remove(_legacyRedeemedDealsKey);

    await _persistRedeemedDeals();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _markDealRedeemed(String dealId) async {
    if (_redeemedDealsAt.containsKey(dealId)) return;
    _redeemedDealsAt[dealId] = DateTime.now().millisecondsSinceEpoch;
    await _persistRedeemedDeals();
    if (!mounted) return;
    setState(() {});
  }

  List<Map<String, String>> get _products => CatalogStore.instance.products;
  List<Map<String, String>> get _drinks => CatalogStore.instance.drinks;

  Map<String, Map<String, String>> get _itemById {
    final all = [..._products, ..._drinks];
    return {for (final item in all) item['id']!: item};
  }
  List<Map<String, dynamic>> get _deals => ManagerStore.instance.allDeals;
  final List<Map<String, dynamic>> _dealOrders = [];

  final List<Map<String, dynamic>> _pastOrders = [
    {
      'id': '#1042',
      'date': '24/04/2026',
      'total': '132₪',
      'statusKey': 'delivered',
      'progress': 1.0,
      'items': [
        {'id': 'burekas', 'quantity': '2', 'price': '18₪'},
        {'id': 'coffee', 'quantity': '1', 'price': '12₪'},
      ],
    },
    {
      'id': '#1031',
      'date': '17/04/2026',
      'total': '96₪',
      'statusKey': 'delivered',
      'progress': 1.0,
      'items': [
        {'id': 'personal_pizza', 'quantity': '2', 'price': '29₪'},
      ],
    },
    {
      'id': '#1018',
      'date': '08/04/2026',
      'total': '210₪',
      'statusKey': 'delivered',
      'progress': 1.0,
      'items': [
        {'id': 'personal_cake', 'quantity': '3', 'price': '24₪'},
        {'id': 'house_shake', 'quantity': '2', 'price': '19₪'},
      ],
    },
  ];

  String _orderStatusLabel(String? key) {
    switch (key) {
      case 'delivered':
        return s.statusDelivered;
      case 'completed':
        return s.statusCompleted;
      case 'completed_deal':
        return s.statusCompletedDeal;
      case 'ready':
        return s.statusReady;
      default:
        return key ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = s;
    final allItems = [..._products, ..._drinks];
    final itemById = {for (final item in allItems) item['id']!: item};
    final cartItems = _cartQuantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final base = itemById[entry.key]!;
          return {
            'id': entry.key,
            'name': CatalogData.name(base),
            'price': base['price']!,
            'image': base['image']!,
            'emoji': base['emoji'] ?? '🥖',
            'quantity': entry.value.toString(),
          };
        })
        .toList();

    final List<Widget> pages = [
      _SettingsHelpPage(),
      HomeDealsSlot(
        productDealsPage: ListenableBuilder(
          listenable: ManagerStore.instance,
          builder: (context, _) => _DealsPage(
            deals: _visibleDeals,
            redeemedDealIds: _activeRedeemedDealIds,
            onRedeemDeal: (deal) async {
              final dealId = deal['id'] as String;
              if (_redeemedDealsAt.containsKey(dealId)) return;
              await _markDealRedeemed(dealId);
              setState(() {
                final dealItems = <Map<String, dynamic>>[];
                for (final raw in deal['items'] as List) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  final id = item['id']?.toString();
                  final product = id != null ? CatalogStore.instance.findById(id) : null;
                  if (product != null) {
                    item['image'] = product['image'];
                    item['emoji'] = product['emoji'] ?? '🥖';
                  }
                  dealItems.add(item);
                }
                _dealOrders.add({
                  'id': 'DEAL-${_dealOrders.length + 1}',
                  'title': CatalogData.dealField(deal, 'title'),
                  'total': deal['priceAfterDiscount'],
                  'statusKey': 'ready',
                  'date': _formatDate(DateTime.now()),
                  'items': dealItems,
                  'images': (deal['images'] as List?)?.cast<String>() ?? const <String>[],
                });
              });
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.dealAdded)),
              );
              setState(() => _selectedIndex = _pageOrders);
            },
          ),
        ),
      ),
      const HomeOrdersSlot(),
      HomeCatalogSlot(
        needLinkMessage: strings.managerAppointmentsNeedLink,
        catalogPage: ListenableBuilder(
          listenable: CatalogStore.instance,
          builder: (context, _) => _CatalogPage(
            products: _products,
            drinks: _drinks,
            quantities: _cartQuantities,
            onSetQuantity: (id, quantity) {
              setState(() {
                _setCartQuantity(id, quantity);
              });
            },
          ),
        ),
      ),
    ];

    final showBottomBar = ModalRoute.of(context)?.isCurrent ?? true;

    return PolicyConsentGate(
      audience: PolicyAudience.customer,
      child: Scaffold(
        body: Column(
          children: [
            ListenableBuilder(
              listenable: ManagerStore.instance,
              builder: (context, _) {
                if (!_showStoreAnnouncement) return const SizedBox.shrink();
                final he = AppLocale.instance.isHebrew;
                return SafeArea(
                  bottom: false,
                  child: StoreAnnouncementPanel(
                    message: ManagerStore.instance.announcement(he),
                    imagePath: ManagerStore.instance.announcementImagePath,
                    onDismiss: _dismissStoreAnnouncement,
                  ),
                );
              },
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: ManagerStore.instance,
                builder: (context, _) {
                  final he = AppLocale.instance.isHebrew;
                  final announcementPages = List<Widget>.from(pages);
                  final appointmentMode = ManagerStore.instance.isAppointmentCustomerMode;
                  if (!appointmentMode) {
                    announcementPages[_pageOrders] = _OrdersPage(
                      orders: _pastOrders,
                      cartItems: cartItems,
                      dealOrders: _dealOrders,
                      showAnnouncement: _showStoreAnnouncement,
                      announcementMessage: ManagerStore.instance.announcement(he),
                      announcementImagePath: ManagerStore.instance.announcementImagePath,
                      onDismissAnnouncement: _dismissStoreAnnouncement,
                      statusLabel: _orderStatusLabel,
                      onDecrease: (id) {
                        final current = _cartQuantities[id] ?? 0;
                        if (current <= 0) return;
                        setState(() => _cartQuantities[id] = current - 1);
                      },
                      onIncrease: (id) {
                        final current = _cartQuantities[id] ?? 0;
                        if (current >= 10) return;
                        setState(() => _setCartQuantity(id, current + 1));
                      },
                      onConfirmOrder: () => _confirmOrderWithPayment(context),
                      onRemoveDeal: (dealId) {
                        setState(() => _dealOrders.removeWhere((d) => d['id'] == dealId));
                      },
                      onRepeatOrder: (order) {
                        final items =
                            (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
                        setState(() {
                          for (final item in items) {
                            final id = item['id']?.toString();
                            final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
                            if (id != null && qty > 0) {
                              final current = _cartQuantities[id] ?? 0;
                              _cartQuantities[id] = (current + qty).clamp(0, 10);
                            }
                          }
                          _selectedIndex = _pageOrders;
                        });
                        _playCartAddSound();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.repeatOrderAdded)),
                        );
                      },
                    );
                  }
                  return IndexedStack(
                    index: _selectedIndex,
                    children: announcementPages,
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: showBottomBar
            ? ListenableBuilder(
                listenable: ManagerStore.instance,
                builder: (context, _) {
                  final appointmentTab = ManagerStore.instance.isAppointmentCustomerMode;
                  return BakeryBottomBar(
                    selectedIndex: _navBarIndex(_selectedIndex),
                    onSelected: _onBottomNavSelected,
                    badgeIndices:
                        !appointmentTab && _dealAlertBadge ? {_navDealsIndex} : const {},
                    items: [
                      (icon: Icons.settings, label: strings.navSettings),
                      (
                        icon: appointmentTab ? Icons.design_services_outlined : Icons.local_offer,
                        label: appointmentTab ? strings.navServices : strings.navDeals,
                      ),
                      (
                        icon: appointmentTab ? Icons.event_note_outlined : Icons.receipt_long,
                        label: appointmentTab ? strings.navMyAppointments : strings.navOrders,
                      ),
                      (
                        icon: appointmentTab ? Icons.calendar_month : Icons.storefront,
                        label: appointmentTab ? strings.navAppointments : strings.navCatalog,
                      ),
                    ],
                  );
                },
              )
            : null,
      ),
    );
  }

  void _setCartQuantity(String id, int quantity) {
    final previous = _cartQuantities[id] ?? 0;
    final next = quantity.clamp(0, 10);
    _cartQuantities[id] = next;
    if (next > previous) _playCartAddSound();
  }

  Future<void> _playCartAddSound() async {
    await _cartSoundPlayer.stop();
    await _cartSoundPlayer.play(AssetSource('sounds/cart_add.mp3'));
  }

  int _parsePrice(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  int _cartTotalShekels(List<Map<String, String>> cartItems) {
    return cartItems.fold<int>(
      0,
      (sum, item) =>
          sum + (_parsePrice(item['price'] ?? '0') * (int.tryParse(item['quantity'] ?? '0') ?? 0)),
    );
  }

  int _dealOrdersTotalShekels() {
    var sum = 0;
    for (final deal in _dealOrders) {
      sum += _parsePrice(deal['total']?.toString() ?? '0');
    }
    return sum;
  }

  Future<void> _confirmOrderWithPayment(BuildContext context) async {
    final strings = s;
    final cartItems = <Map<String, String>>[
      for (final product in _products)
        if ((_cartQuantities[product['id']] ?? 0) > 0)
          {
            'id': product['id']!,
            'name': CatalogData.name(product),
            'price': product['price']!,
            'quantity': '${_cartQuantities[product['id']]}',
            'image': product['image']!,
            'emoji': product['emoji'] ?? '🥖',
          },
      for (final drink in _drinks)
        if ((_cartQuantities[drink['id']] ?? 0) > 0)
          {
            'id': drink['id']!,
            'name': CatalogData.name(drink),
            'price': drink['price']!,
            'quantity': '${_cartQuantities[drink['id']]}',
            'image': drink['image']!,
            'emoji': drink['emoji'] ?? '☕',
          },
    ];
    final hasActiveOrder = cartItems.isNotEmpty || _dealOrders.isNotEmpty;
    if (!hasActiveOrder) return;

    final blockMessage = OrderRestrictionsStore.instance.placementBlockMessage(strings);
    if (blockMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blockMessage)));
      }
      return;
    }

    final cartTotal = _cartTotalShekels(cartItems);
    final dealTotal = _dealOrdersTotalShekels();
    final totalShekels = cartTotal + dealTotal;
    if (totalShekels <= 0) return;

    final amountAgorot = totalShekels * 100;
    final orderId = '#${1100 + _pastOrders.length + 1}';
    final summaryParts = <String>[
      for (final item in cartItems) '${item['name']} ×${item['quantity']}',
      for (final dealOrder in _dealOrders)
        (dealOrder['title'] ?? dealOrder['titleHe'] ?? strings.navDeals).toString(),
    ];

    if (StripeConfig.isConfigured) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(strings.paymentProcessing, style: BakeryTheme.text(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    bool paid = true;
    try {
      if (StripeConfig.isConfigured) {
        paid = await StripePaymentService.payForOrder(
          context: context,
          amountAgorot: amountAgorot,
          orderId: orderId,
          description: summaryParts.join(' · '),
        );
      } else {
        await StripePaymentService.payForOrder(
          context: context,
          amountAgorot: amountAgorot,
          orderId: orderId,
        );
        return;
      }
    } on StripePaymentException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      paid = false;
    } finally {
      if (mounted && StripeConfig.isConfigured) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!paid || !mounted) {
      if (mounted && StripeConfig.isConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.paymentCanceled)));
      }
      return;
    }

    var recordedTotal = '$totalShekels₪';
    if (cartItems.isNotEmpty && _dealOrders.isEmpty) {
      recordedTotal = '$cartTotal₪';
    } else if (cartItems.isEmpty && _dealOrders.length == 1) {
      recordedTotal = _dealOrders.first['total']?.toString() ?? '$dealTotal₪';
    }
    final dealOrdersSnapshot = List<Map<String, dynamic>>.from(_dealOrders);
    final orderLines = <BusinessOrderLine>[
      for (final item in cartItems)
        BusinessOrderLine(
          name: item['name']!,
          quantity: int.tryParse(item['quantity'] ?? '0') ?? 0,
        ),
    ];
    for (final dealOrder in dealOrdersSnapshot) {
      final dealItems = (dealOrder['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final it in dealItems) {
        final id = it['id']?.toString();
        final qty = int.tryParse(it['quantity']?.toString() ?? '0') ?? 0;
        if (id == null || qty <= 0) continue;
        final base = _itemById[id];
        final name = base != null ? CatalogData.name(base) : id;
        orderLines.add(BusinessOrderLine(name: name, quantity: qty));
      }
    }

    setState(() {
      final purchasedItems = cartItems
          .map(
            (item) => {
              'id': item['id']!,
              'quantity': item['quantity']!,
              'price': item['price']!,
            },
          )
          .toList();
      for (final dealOrder in _dealOrders) {
        _pastOrders.insert(0, {
          'id': '#${1100 + _pastOrders.length + 1}',
          'date': _formatDate(DateTime.now()),
          'total': dealOrder['total'],
          'statusKey': 'completed_deal',
          'progress': 1.0,
          'items': List<Map<String, dynamic>>.from(dealOrder['items'] as List),
        });
      }
      if (purchasedItems.isNotEmpty) {
        _pastOrders.insert(0, {
          'id': orderId,
          'date': _formatDate(DateTime.now()),
          'total': '$cartTotal₪',
          'statusKey': 'completed',
          'progress': 1.0,
          'items': purchasedItems,
        });
      }
      _cartQuantities.clear();
      _dealOrders.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.orderConfirmed)),
    );
    if (summaryParts.isNotEmpty) {
      await BusinessStore.instance.recordOrder(
        orderId: orderId,
        total: recordedTotal.isNotEmpty ? recordedTotal : '$cartTotal₪',
        summary: summaryParts.join(' · '),
        lines: orderLines.where((l) => l.quantity > 0).toList(),
      );
    }
    if (mounted) {
      await showReviewDialog(context);
    }
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  void dispose() {
    ManagerStore.instance.removeListener(_onManagerStoreChanged);
    _redeemExpiryTimer?.cancel();
    _cartSoundPlayer.dispose();
    super.dispose();
  }

}


class _CatalogPage extends StatefulWidget {
  const _CatalogPage({
    required this.products,
    required this.drinks,
    required this.quantities,
    required this.onSetQuantity,
  });

  final List<Map<String, String>> products;
  final List<Map<String, String>> drinks;
  final Map<String, int> quantities;
  final void Function(String id, int quantity) onSetQuantity;

  @override
  State<_CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<_CatalogPage> {
  int _confettiToken = 0;

  Future<int?> _showQuantityPicker({required BuildContext context, required int current}) async {
    int temp = current;
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => bakeryModalSheetFrame(
        context,
        Column(
          children: [
            Text(s.pickQuantity, style: BakeryTheme.text(context, fontSize: 16)),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 44,
                onSelectedItemChanged: (i) => temp = i,
                controller: FixedExtentScrollController(initialItem: current.clamp(0, 10)),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index > 10) return null;
                    return Center(
                      child: Text(
                        '$index',
                        style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    );
                  },
                ),
              ),
            ),
            FilledButton(onPressed: () => Navigator.pop(context, temp), child: Text(s.confirm)),
          ],
        ),
        heightFactor: 0.42,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.products;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                minimum: const EdgeInsets.only(top: 12),
                child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.62,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final id = item['id']!;
                  final qty = widget.quantities[id] ?? 0;
                  return _AnimatedProductCard(
                    item: item,
                    quantity: qty,
                    onDecrease: () {
                      if (qty > 0) widget.onSetQuantity(id, qty - 1);
                    },
                    onIncrease: () {
                      if (qty < 10) {
                        widget.onSetQuantity(id, qty + 1);
                        setState(() => _confettiToken++);
                      }
                    },
                    onPickQuantity: () async {
                      final picked = await _showQuantityPicker(context: context, current: qty);
                      if (picked != null) widget.onSetQuantity(id, picked);
                    },
                  );
                },
              ),
              ),
            ),
          ],
        ),
        if (_confettiToken > 0)
          IgnorePointer(
            child: BakeryShapeConfetti(
              key: ValueKey(_confettiToken),
              onFinished: () {
                if (mounted) setState(() => _confettiToken = 0);
              },
            ),
          ),
      ],
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Icon(icon, size: 15, color: BakeryTheme.body(context)),
      ),
    );
  }
}

class _ProductInfoSheet extends StatelessWidget {
  const _ProductInfoSheet({required this.item});

  final Map<String, String> item;

  static Future<void> show(BuildContext context, Map<String, String> item) {
    final name = CatalogData.name(item);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: name,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: _ProductInfoSheet(item: item),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = s;
    final imagePath = item['image'];
    final emoji = item['emoji'] ?? '🥖';
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 10 + bottom),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: BakeryTheme.panelGradient(context),
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: BakeryTheme.border(context), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: BakeryTheme.muted(context).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProductInfoHero(imagePath: imagePath, emoji: emoji),
                      const SizedBox(height: 18),
                      _OrdersPanel(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              CatalogData.name(item),
                              textAlign: TextAlign.center,
                              style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              CatalogData.subtitle(item),
                              textAlign: TextAlign.center,
                              style: BakeryTheme.subtitleText(context, fontSize: 15, height: 1.45),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      scheme.primary.withValues(alpha: 0.22),
                                      scheme.secondary.withValues(alpha: 0.14),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  strings.priceLabel(item['price']!),
                                  style: BakeryTheme.text(
                                    context,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _OrderSheetActionButton(
                        primary: true,
                        icon: Icons.check_rounded,
                        label: strings.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductInfoHero extends StatelessWidget {
  const _ProductInfoHero({required this.imagePath, required this.emoji});

  final String? imagePath;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.4;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight, minHeight: 160),
      decoration: BoxDecoration(
        color: BakeryTheme.softSurface(context),
        borderRadius: BorderRadius.circular(22),
        border: BakerySquarePalette.squareBorder(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: imagePath != null && imagePath!.isNotEmpty
          ? Center(
              child: CatalogItemImage(
                path: imagePath!,
                fit: BoxFit.contain,
                emoji: emoji,
              ),
            )
          : Center(child: Text(emoji, style: const TextStyle(fontSize: 72))),
    );
  }
}

class _AnimatedProductCard extends StatelessWidget {
  const _AnimatedProductCard({
    required this.item,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onPickQuantity,
  });

  final Map<String, String> item;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onPickQuantity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: BakerySquarePalette.squareFill(context),
        borderRadius: BorderRadius.circular(20),
        border: BakerySquarePalette.squareBorder(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.13),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: item['image'] != null
                  ? CatalogItemImage(
                      path: item['image']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      emoji: item['emoji'] ?? '🥖',
                    )
                  : Center(child: Text(item['emoji'] ?? '🥖', style: const TextStyle(fontSize: 40))),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  CatalogData.name(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              InkWell(
                onTap: () => _ProductInfoSheet.show(context, item),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.info_outline, size: 20, color: BakeryTheme.muted(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  item['price']!,
                  style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: BakeryTheme.cardSurface(context).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BakeryTheme.border(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CompactIconButton(onPressed: onDecrease, icon: Icons.remove),
                    GestureDetector(
                      onTap: onPickQuantity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '$quantity',
                          style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    _CompactIconButton(onPressed: onIncrease, icon: Icons.add),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DealsPage extends StatelessWidget {
  const _DealsPage({
    required this.deals,
    required this.redeemedDealIds,
    required this.onRedeemDeal,
  });

  final List<Map<String, dynamic>> deals;
  final Set<String> redeemedDealIds;
  final Future<void> Function(Map<String, dynamic> deal) onRedeemDeal;

  @override
  Widget build(BuildContext context) {
    final strings = s;
    final sortedDeals = [...deals]
      ..sort((a, b) {
        final aRedeemed = redeemedDealIds.contains(a['id']);
        final bRedeemed = redeemedDealIds.contains(b['id']);
        if (aRedeemed == bRedeemed) return 0;
        return aRedeemed ? 1 : -1;
      });

    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.only(top: 12),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: sortedDeals.length,
        itemBuilder: (context, index) {
          final deal = sortedDeals[index];
          final dealId = deal['id'] as String;
          final redeemed = redeemedDealIds.contains(dealId);
          final images = (deal['images'] as List?)?.cast<String>() ?? const <String>[];
          final price = deal['priceAfterDiscount']?.toString() ?? '';
          final valid = CatalogData.dealField(deal, 'valid');

          return Opacity(
            opacity: redeemed ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: redeemed,
              child: _OrdersPanel(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      CatalogData.dealField(deal, 'title'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BakeryTheme.text(context, fontSize: 15, fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.validUntil(valid),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BakeryTheme.subtitleText(context, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _DealProductsRow(deal: deal, images: images, compact: true)),
                    const SizedBox(height: 6),
                    Text(
                      price,
                      textAlign: TextAlign.center,
                      style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: redeemed ? null : () => onRedeemDeal(deal),
                        child: Text(
                          redeemed ? strings.dealRedeemed : strings.redeemDeal,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DealProductsRow extends StatelessWidget {
  const _DealProductsRow({
    required this.deal,
    required this.images,
    this.compact = false,
    this.previewTileWidth,
  });

  final Map<String, dynamic> deal;
  final List<String> images;
  final bool compact;
  final double? previewTileWidth;

  @override
  Widget build(BuildContext context) {
    final items = (deal['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();

    final maxShow = compact ? 2 : 3;
    final shown = items.length > maxShow ? items.sublist(0, maxShow) : items;
    final extra = items.length - shown.length;
    final tileWidth = previewTileWidth ?? (compact ? 56.0 : 96.0);

    Widget plusBadge() => Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 6),
          child: Icon(Icons.add, color: BakeryTheme.accent(context), size: compact ? 14 : 18),
        );

    final previews = <Widget>[
      for (var i = 0; i < shown.length; i++) ...[
        if (i > 0) plusBadge(),
        SizedBox(
          width: tileWidth,
          child: _DealProductPreview(
            imagePath: i < images.length ? images[i] : null,
            deal: deal,
            itemIndex: items.indexOf(shown[i]),
            compact: compact,
          ),
        ),
      ],
      if (extra > 0)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '+$extra',
            style: BakeryTheme.text(context, fontSize: compact ? 12 : 14, fontWeight: FontWeight.w800),
          ),
        ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: previews,
    );
  }
}

class _DealProductPreview extends StatelessWidget {
  const _DealProductPreview({
    required this.imagePath,
    required this.deal,
    required this.itemIndex,
    this.compact = false,
  });

  final String? imagePath;
  final Map<String, dynamic> deal;
  final int itemIndex;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = (deal['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final item = itemIndex < items.length ? items[itemIndex] : null;
    final productId = item?['id']?.toString();
    final product = productId != null ? CatalogStore.instance.findById(productId) : null;
    final name = product != null ? CatalogData.name(product) : '';
    final radius = compact ? 10.0 : 16.0;
    final itemImage = item?['image']?.toString();
    final effectivePath = (imagePath != null && imagePath!.isNotEmpty)
        ? imagePath
        : (itemImage != null && itemImage.isNotEmpty ? itemImage : product?['image']);
    final emoji = item?['emoji']?.toString() ?? product?['emoji'] ?? '🥖';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: compact ? 4 : 8,
                offset: Offset(0, compact ? 2 : 4),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: effectivePath != null && effectivePath.isNotEmpty
                  ? CatalogItemImage(
                      path: effectivePath,
                      fit: BoxFit.cover,
                      emoji: emoji,
                    )
                  : _DealImageFallback(emoji: emoji, compact: compact),
            ),
          ),
        ),
        if (!compact && name.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
          ),
        ],
      ],
    );
  }
}

class _DealImageFallback extends StatelessWidget {
  const _DealImageFallback({required this.emoji, this.compact = false});

  final String emoji;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BakeryTheme.softSurface(context),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: compact ? 22 : 36)),
    );
  }
}

class _OrdersPanel extends StatelessWidget {
  const _OrdersPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.border,
    this.surfaceColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final BoxBorder? border;
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor ?? BakerySquarePalette.squareFill(context),
        borderRadius: BorderRadius.circular(22),
        border: border ?? Border.all(color: BakeryTheme.border(context), width: 1.2),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [
                BoxShadow(color: Color(0x38000000), blurRadius: 16, offset: Offset(0, 8)),
                BoxShadow(color: Color(0x18FFFFFF), blurRadius: 8, offset: Offset(-2, -3)),
              ],
      ),
      child: child,
    );
  }
}

class _DealPriceTile extends StatelessWidget {
  const _DealPriceTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final decor = bakeryDecor(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: decor.cardFill.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.local_offer_outlined, size: 26, color: decor.accent),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: decor.mutedText),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: BakeryTheme.text(context, fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _OrderMetricTile extends StatelessWidget {
  const _OrderMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final decor = bakeryDecor(context);
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: decor.cardFill.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5), width: 2.4),
          boxShadow: const [
            BoxShadow(color: Color(0x28000000), blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: decor.accent),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: decor.mutedText),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BakeryTheme.text(context, fontSize: 15, fontWeight: FontWeight.w800, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({
    required this.name,
    required this.quantity,
    required this.price,
    this.emoji = '🥖',
    this.imagePath,
  });

  final String name;
  final String quantity;
  final String price;
  final String emoji;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BakeryTheme.cardSurface(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BakeryTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 52,
              color: BakeryTheme.softSurface(context),
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                    )
                  : Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '×$quantity',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: BakeryTheme.subtitle(context)),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: BakeryTheme.body(context)),
          ),
        ],
      ),
    );
  }
}

class _OrderSheetActionButton extends StatelessWidget {
  const _OrderSheetActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.disabled = false,
    this.labelFontSize = 15,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool disabled;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !disabled;
    final scheme = Theme.of(context).colorScheme;
    final decor = bakeryDecor(context);

    return SemanticIconButton(
      label: label,
      enabled: enabled,
      onPressed: enabled ? onPressed : null,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: primary && enabled
                ? LinearGradient(colors: [scheme.primary, scheme.secondary])
                : null,
            color: primary
                ? (enabled ? null : BakeryTheme.softSurface(context))
                : decor.cardFill.withValues(alpha: enabled ? 0.95 : 0.5),
            borderRadius: BorderRadius.circular(18),
            border: primary ? null : Border.all(color: scheme.outline.withValues(alpha: 0.5), width: 1.4),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: primary ? scheme.onPrimary : (enabled ? decor.accent : decor.mutedText),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w800,
                  color: primary ? scheme.onPrimary : (enabled ? scheme.onSurface : decor.mutedText),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _OrdersPage extends StatefulWidget {
  const _OrdersPage({
    required this.orders,
    required this.cartItems,
    required this.dealOrders,
    required this.showAnnouncement,
    required this.announcementMessage,
    required this.announcementImagePath,
    required this.onDismissAnnouncement,
    required this.statusLabel,
    required this.onDecrease,
    required this.onIncrease,
    required this.onConfirmOrder,
    required this.onRemoveDeal,
    required this.onRepeatOrder,
  });

  final List<Map<String, dynamic>> orders;
  final List<Map<String, String>> cartItems;
  final List<Map<String, dynamic>> dealOrders;
  final bool showAnnouncement;
  final String announcementMessage;
  final String announcementImagePath;
  final VoidCallback onDismissAnnouncement;
  final void Function(String id) onDecrease;
  final void Function(String id) onIncrease;
  final String Function(String? statusKey) statusLabel;
  final VoidCallback onConfirmOrder;
  final void Function(String dealId) onRemoveDeal;
  final void Function(Map<String, dynamic> order) onRepeatOrder;

  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage> {
  static const _rememberedOrdersKey = 'remembered_order_ids';

  bool _showPastOrders = false;
  Set<String> _rememberedOrderIds = {};

  @override
  void initState() {
    super.initState();
    _loadRememberedOrders();
  }

  Future<void> _loadRememberedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_rememberedOrdersKey) ?? const [];
    if (!mounted) return;
    setState(() => _rememberedOrderIds = ids.toSet());
  }

  Future<void> _rememberOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    _rememberedOrderIds.add(orderId);
    await prefs.setStringList(_rememberedOrdersKey, _rememberedOrderIds.toList());
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.orderRemembered)),
    );
  }

  Future<void> _forgetOrder(String orderId) async {
    if (!_rememberedOrderIds.contains(orderId)) return;
    final prefs = await SharedPreferences.getInstance();
    _rememberedOrderIds.remove(orderId);
    await prefs.setStringList(_rememberedOrdersKey, _rememberedOrderIds.toList());
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.orderRemovedFromMemory)),
    );
  }

  Future<void> _openPastOrderSheet(Map<String, dynamic> order) async {
    final strings = s;
    final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final orderId = order['id'].toString();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final remembered = _rememberedOrderIds.contains(orderId);
            final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Row(
                  children: [
                    Expanded(
                      child: _OrderMetricTile(
                        icon: Icons.calendar_month_outlined,
                        label: strings.date,
                        value: order['date']?.toString() ?? '',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OrderMetricTile(
                        icon: Icons.payments_outlined,
                        label: strings.totalPrice,
                        value: order['total']?.toString() ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OrderMetricTile(
                        icon: Icons.tag_outlined,
                        label: strings.orderNumber,
                        value: orderId,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OrderMetricTile(
                        icon: Icons.local_shipping_outlined,
                        label: strings.status,
                        value: widget.statusLabel(order['statusKey']?.toString()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _OrdersPanel(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.orderedItems,
                        textAlign: TextAlign.center,
                        style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      ...items.map((item) {
                        final id = item['id']?.toString();
                        final product = id != null ? CatalogData.findById(id) : null;
                        final name = product != null
                            ? CatalogData.name(product)
                            : item['name']?.toString() ?? '';
                        return _OrderItemCard(
                          name: name,
                          quantity: item['quantity']?.toString() ?? '1',
                          price: item['price']?.toString() ?? '',
                          emoji: product?['emoji'] ?? '🥖',
                          imagePath: product?['image'],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _OrderSheetActionButton(
                  primary: true,
                  icon: Icons.replay_rounded,
                  label: strings.repeatOrder,
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRepeatOrder(order);
                  },
                ),
                const SizedBox(height: 12),
                _OrderSheetActionButton(
                  icon: remembered ? Icons.bookmark : Icons.bookmark_outline,
                  label: remembered ? strings.forgetOrder : strings.rememberOrder,
                  onPressed: () async {
                    if (remembered) {
                      await _forgetOrder(orderId);
                    } else {
                      await _rememberOrder(orderId);
                    }
                    setSheetState(() {});
                  },
                ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _activeOrdersBody(BuildContext context, AppStrings strings, bool hasCheckout) {
    if (!hasCheckout) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, color: BakeryTheme.accent(context), size: 40),
            const SizedBox(height: 12),
            Text(strings.cartEmpty, textAlign: TextAlign.center, style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              strings.cartEmptySub,
              textAlign: TextAlign.center,
              style: BakeryTheme.subtitleText(context, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final cartEmpty = widget.cartItems.isEmpty;
    final dealsEmpty = widget.dealOrders.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!dealsEmpty) ...[
                  Text(strings.cartDealsSection, style: BakeryTheme.text(context, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  ...widget.dealOrders.map(
                    (deal) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _DealCartCard(
                        dealOrder: deal,
                        compact: true,
                        onRemove: () => widget.onRemoveDeal(deal['id'] as String),
                      ),
                    ),
                  ),
                ],
                if (!cartEmpty)
                  GridView.builder(
                    itemCount: widget.cartItems.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return _CartSquareCard(
                        item: item,
                        compact: true,
                        onDecrease: () => widget.onDecrease(item['id']!),
                        onIncrease: () => widget.onIncrease(item['id']!),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: widget.onConfirmOrder,
            icon: const Icon(Icons.check_circle, size: 20),
            label: Text(strings.confirmOrder, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _historyOrdersBody(BuildContext context, AppStrings strings) {
    if (!_showPastOrders) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: BakeryTheme.muted(context), size: 28),
            const SizedBox(height: 4),
            Text(
              '${widget.orders.length}',
              style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(strings.tapToExpandHistory, style: BakeryTheme.subtitleText(context, fontSize: 12)),
          ],
        ),
      );
    }

    if (widget.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 36, color: BakeryTheme.muted(context)),
            const SizedBox(height: 10),
            Text(strings.noPastOrders, textAlign: TextAlign.center, style: BakeryTheme.text(context, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(strings.noPastOrdersSub, textAlign: TextAlign.center, style: BakeryTheme.subtitleText(context, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: widget.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = widget.orders[index];
        final id = order['id'].toString();
        final remembered = _rememberedOrderIds.contains(id);
        final date = order['date']?.toString() ?? '';
        final total = order['total']?.toString() ?? '';
        return Material(
          color: BakeryTheme.cardSurface(context).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openPastOrderSheet(order),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text(date, style: BakeryTheme.text(context, fontSize: 13, fontWeight: FontWeight.w700))),
                  Text(total, style: BakeryTheme.text(context, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Icon(
                    remembered ? Icons.bookmark : Icons.chevron_right,
                    color: remembered ? BakeryTheme.accent(context) : BakeryTheme.muted(context),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = s;
    final cartEmpty = widget.cartItems.isEmpty;
    final dealsEmpty = widget.dealOrders.isEmpty;
    final hasCheckout = !cartEmpty || !dealsEmpty;

    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showAnnouncement) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: StoreAnnouncementPanel(
                  message: widget.announcementMessage,
                  imagePath: widget.announcementImagePath,
                  onDismiss: widget.onDismissAnnouncement,
                  compact: true,
                ),
              ),
              const SizedBox(height: 10),
            ],
            _OrdersHubSquare(
              title: strings.activeOrdersSection,
              icon: Icons.shopping_bag_outlined,
              child: _activeOrdersBody(context, strings, hasCheckout),
            ),
            const SizedBox(height: 10),
            _OrdersHubSquare(
              title: strings.orderHistory,
              icon: Icons.history,
              onHeaderTap: () => setState(() => _showPastOrders = !_showPastOrders),
              expanded: _showPastOrders,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: _showPastOrders ? 200 : 88),
                child: _historyOrdersBody(context, strings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersHubSquare extends StatelessWidget {
  const _OrdersHubSquare({
    required this.title,
    required this.child,
    this.icon,
    this.onHeaderTap,
    this.expanded = false,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final VoidCallback? onHeaderTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return _OrdersPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onHeaderTap,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: BakeryTheme.accent(context), size: 22),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (onHeaderTap != null)
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(Icons.expand_more, color: BakeryTheme.accent(context), size: 24),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _DealCartCard extends StatelessWidget {
  const _DealCartCard({
    required this.dealOrder,
    required this.onRemove,
    this.compact = false,
  });

  final Map<String, dynamic> dealOrder;
  final VoidCallback onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = s;
    final items = (dealOrder['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final images = (dealOrder['images'] as List?)?.cast<String>() ?? const <String>[];
    final title = dealOrder['title']?.toString() ?? strings.navDeals;
    final total = dealOrder['total']?.toString() ?? '';
    final showPreviews = items.isNotEmpty || images.isNotEmpty;

    final thumb = compact ? 36.0 : 40.0;
    return _OrdersPanel(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 14, compact ? 8 : 14, compact ? 8 : 10, compact ? 8 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showPreviews) ...[
                SizedBox(
                  width: compact ? 108 : 140,
                  child: _DealProductsRow(
                    deal: {'items': items},
                    images: images,
                    compact: true,
                    previewTileWidth: thumb,
                  ),
                ),
                SizedBox(width: compact ? 8 : 10),
              ] else
                Padding(
                  padding: EdgeInsets.only(top: compact ? 2 : 0),
                  child: Icon(Icons.local_offer_outlined, color: BakeryTheme.accent(context), size: compact ? 22 : 28),
                ),
              if (!showPreviews) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BakeryTheme.text(
                        context,
                        fontSize: compact ? 14 : 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (total.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        total,
                        style: BakeryTheme.text(
                          context,
                          fontSize: compact ? 15 : 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: strings.removeDealFromCart,
                onPressed: onRemove,
                icon: Icon(Icons.close_rounded, color: BakeryTheme.muted(context), size: compact ? 20 : 24),
              ),
            ],
          ),
          if (items.isNotEmpty && !compact) ...[
            const SizedBox(height: 10),
            ...items.map((item) {
              final id = item['id']?.toString();
              final product = id != null ? CatalogStore.instance.findById(id) : null;
              final name = product != null ? CatalogData.name(product) : id ?? '';
              final imagePath = item['image']?.toString() ?? product?['image'];
              final emoji = item['emoji']?.toString() ?? product?['emoji'] ?? '🥖';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    if (imagePath != null && imagePath.isNotEmpty)
                      CatalogItemImage(
                        path: imagePath,
                        width: thumb,
                        height: thumb,
                        borderRadius: BorderRadius.circular(10),
                        emoji: emoji,
                      ),
                    if (imagePath != null && imagePath.isNotEmpty) const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$name ×${item['quantity'] ?? '1'}',
                        style: BakeryTheme.subtitleText(context, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _CartSquareCard extends StatelessWidget {
  const _CartSquareCard({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    this.compact = false,
  });

  final Map<String, String> item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imagePath = item['image'];
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final pad = compact ? 4.0 : 12.0;
    final radius = compact ? 10.0 : 18.0;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: BakeryTheme.softSurface(context),
        borderRadius: BorderRadius.circular(radius),
        border: BakerySquarePalette.squareBorder(context),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [
                BoxShadow(color: Color(0x35000000), blurRadius: 12, offset: Offset(0, 6)),
                BoxShadow(color: Color(0x14FFFFFF), blurRadius: 6, offset: Offset(-2, -2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: compact ? 3 : 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 6 : 14),
              child: imagePath != null && imagePath.isNotEmpty
                  ? CatalogItemImage(
                      path: imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      emoji: item['emoji'] ?? '🥖',
                    )
                  : Center(
                      child: Text(
                        item['emoji'] ?? '🥖',
                        style: TextStyle(fontSize: compact ? 18 : 40),
                      ),
                    ),
            ),
          ),
          SizedBox(height: compact ? 2 : 6),
          Text(
            item['name']!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 8 : 12,
              color: BakeryTheme.body(context),
            ),
          ),
          Text(
            item['price']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 7 : 11,
              color: BakeryTheme.subtitle(context),
            ),
          ),
          SizedBox(height: compact ? 2 : 6),
          Container(
            height: compact ? 20 : 34,
            decoration: BoxDecoration(
              color: BakeryTheme.cardSurface(context).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(compact ? 8 : 12),
              border: Border.all(color: BakeryTheme.border(context), width: compact ? 1.2 : 1.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: onDecrease,
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: compact ? 18 : 32,
                    height: compact ? 18 : 32,
                    child: Icon(Icons.remove, size: compact ? 12 : 18),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 8),
                  child: Text(
                    item['quantity']!,
                    style: BakeryTheme.text(
                      context,
                      fontSize: compact ? 9 : 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onIncrease,
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: compact ? 18 : 32,
                    height: compact ? 18 : 32,
                    child: Icon(Icons.add, size: compact ? 12 : 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHelpPage extends StatefulWidget {
  const _SettingsHelpPage();

  @override
  State<_SettingsHelpPage> createState() => _SettingsHelpPageState();
}

class _SheetRouteFade extends StatelessWidget {
  const _SheetRouteFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null) return child;
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

class _HelpSheetShell extends StatelessWidget {
  const _HelpSheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BakeryTheme.softSurface(context),
      child: child,
    );
  }
}

class _HelpSheetHeader extends StatelessWidget {
  const _HelpSheetHeader({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.3),
              scheme.secondary.withValues(alpha: 0.14),
            ],
          ),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.38)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, size: 32, color: scheme.primary),
      ),
    );
  }
}

class _SheetEntrance extends StatefulWidget {
  const _SheetEntrance({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  State<_SheetEntrance> createState() => _SheetEntranceState();
}

class _SheetEntranceState extends State<_SheetEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

String _formatCommunityTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return '$hh:$mm';
  }
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} $hh:$mm';
}

Color _whatsappChatBackground(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD);
}

class _CommunityMessageBubble extends StatelessWidget {
  const _CommunityMessageBubble({
    required this.author,
    required this.text,
    required this.timeLabel,
    required this.isMine,
  });

  final String author;
  final String text;
  final String timeLabel;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final incomingBg = dark ? const Color(0xFF1F2C34) : Colors.white;
    final outgoingBg = dark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6);
    final incomingText = dark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21);
    final outgoingText = dark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21);
    final authorColor = dark ? const Color(0xFF53BDEB) : const Color(0xFF128C7E);

    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: isMine ? outgoingBg : incomingBg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMine ? 12 : 2),
          bottomRight: Radius.circular(isMine ? 2 : 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine && author.isNotEmpty) ...[
            Text(
              author,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: authorColor),
            ),
            const SizedBox(height: 3),
          ],
          Text(
            text,
            style: TextStyle(fontSize: 15, height: 1.38, color: isMine ? outgoingText : incomingText),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              timeLabel,
              style: TextStyle(
                fontSize: 11,
                color: (isMine ? outgoingText : incomingText).withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: isMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: isMine ? TextDirection.rtl : TextDirection.ltr,
          children: [
            if (!isMine) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: authorColor.withValues(alpha: 0.2),
                child: Text(
                  author.isNotEmpty ? author[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: authorColor),
                ),
              ),
              const SizedBox(width: 6),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
              child: bubble,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ContactPanelMode { community, email }

class _ContactPanelSheet extends StatefulWidget {
  const _ContactPanelSheet({
    required this.contactPhone,
    required this.contactEmail,
    required this.parentContext,
  });

  final String contactPhone;
  final String contactEmail;
  final BuildContext parentContext;

  @override
  State<_ContactPanelSheet> createState() => _ContactPanelSheetState();
}

class _ContactPanelSheetState extends State<_ContactPanelSheet> {
  _ContactPanelMode _mode = _ContactPanelMode.community;
  final _communityScroll = ScrollController();
  final _emailScroll = ScrollController();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _communityNameController = TextEditingController();
  final _communityMessageController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final saved = CommunityMessagesStore.instance.displayName;
    if (saved.isNotEmpty) {
      _communityNameController.text = saved;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollCommunityToEnd());
  }

  @override
  void dispose() {
    _communityScroll.dispose();
    _emailScroll.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _communityNameController.dispose();
    _communityMessageController.dispose();
    super.dispose();
  }

  void _scrollCommunityToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_communityScroll.hasClients) return;
      _communityScroll.animateTo(
        _communityScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendCommunityMessage() async {
    final text = _communityMessageController.text.trim();
    if (text.isEmpty) return;
    await CommunityMessagesStore.instance.post(
      author: _communityNameController.text,
      text: text,
    );
    _communityMessageController.clear();
    if (!mounted) return;
    setState(() {});
    _scrollCommunityToEnd();
  }

  Future<void> _sendEmail() async {
    final strings = s;
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    final subject = Uri.encodeComponent(strings.contactTitle);
    final body = Uri.encodeComponent(
      '${strings.yourName}: ${_nameController.text.trim()}\n'
      '${strings.yourEmail}: ${_emailController.text.trim()}\n\n'
      '${_messageController.text.trim()}',
    );
    final uri = Uri.parse('mailto:${widget.contactEmail}?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
    await ManagerStore.instance.logInquiry(
      message: _messageController.text.trim(),
      channel: 'email',
      customerName: _nameController.text.trim(),
    );
    await BusinessStore.instance.recordInquiry();
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.parentContext.mounted) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text(strings.messageSent)),
      );
    }
  }

  Widget _buildModeSwitcher(AppStrings strings) {
    return _OrdersPanel(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _contactModeChip(
            selected: _mode == _ContactPanelMode.community,
            icon: Icons.forum_rounded,
            label: strings.contactCommunityTab,
            onTap: () {
              setState(() => _mode = _ContactPanelMode.community);
              _scrollCommunityToEnd();
            },
          ),
          const SizedBox(width: 6),
          _contactModeChip(
            selected: _mode == _ContactPanelMode.email,
            icon: Icons.email_rounded,
            label: strings.contactEmailTab,
            onTap: () => setState(() => _mode = _ContactPanelMode.email),
          ),
        ],
      ),
    );
  }

  Widget _contactModeChip({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final accent = BakeryTheme.accent(context);
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? accent.withValues(alpha: 0.45) : Colors.transparent),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: selected ? accent : BakeryTheme.muted(context)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: selected ? accent : BakeryTheme.muted(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = s;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeSwitcher(strings),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              child: switch (_mode) {
                _ContactPanelMode.community => SizedBox.expand(
                  key: const ValueKey('community'),
                  child: _buildCommunityView(strings),
                ),
                _ContactPanelMode.email => SizedBox.expand(
                  key: const ValueKey('email'),
                  child: _buildEmailView(strings),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityView(AppStrings strings) {
    final he = AppLocale.instance.isHebrew;
    final store = CommunityMessagesStore.instance;
    final myName = store.displayName.trim().isNotEmpty
        ? store.displayName.trim()
        : _communityNameController.text.trim();

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final messages = store.messagesChronological;
        final chatChildren = <Widget>[
          if (messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                strings.contactCommunityEmpty,
                textAlign: TextAlign.center,
                style: BakeryTheme.subtitleText(context, fontSize: 14),
              ),
            )
          else
            for (final m in messages)
              if (m.text(he).isNotEmpty)
                _CommunityMessageBubble(
                  author: m.author(he),
                  text: m.text(he),
                  timeLabel: _formatCommunityTime(m.createdAtMs),
                  isMine: myName.isNotEmpty && m.author(he) == myName,
                ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                controller: _communityScroll,
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1F2C34)
                          : const Color(0xFF075E54),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.contactCommunityTitle,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                strings.contactCommunityHint,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ColoredBox(
                      color: _whatsappChatBackground(context),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: chatChildren,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SafeArea(
              top: false,
              minimum: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (store.displayName.isEmpty) ...[
                    TextField(
                      controller: _communityNameController,
                      style: BakeryTheme.text(context, fontSize: 14),
                      decoration: bakeryInputDecoration(
                        context,
                        label: strings.contactYourName,
                        icon: Icons.person_outline,
                      ).copyWith(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _communityMessageController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendCommunityMessage(),
                          style: BakeryTheme.text(context, fontSize: 15),
                          decoration: bakeryInputDecoration(
                            context,
                            label: strings.contactTypeMessage,
                            icon: Icons.chat_bubble_outline,
                          ).copyWith(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Material(
                          color: const Color(0xFF25D366),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _sendCommunityMessage,
                            child: const Center(
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmailView(AppStrings strings) {
    return ListView(
      controller: _emailScroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(
          strings.contactFormHint,
          textAlign: TextAlign.center,
          style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 16),
        _OrdersPanel(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Form(
            key: _emailFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline_rounded, color: BakeryTheme.accent(context)),
                    const SizedBox(width: 8),
                    Text(
                      strings.contactEmailTab,
                      style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  decoration: bakeryInputDecoration(context, label: strings.yourName, icon: Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? strings.fillAllFields : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: bakeryInputDecoration(context, label: strings.yourEmail, icon: Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return strings.fillAllFields;
                    if (!v.contains('@')) return strings.fillAllFields;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: bakeryInputDecoration(context, label: strings.yourMessage, icon: Icons.chat_bubble_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? strings.fillAllFields : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _OrderSheetActionButton(
          primary: true,
          icon: Icons.email_outlined,
          label: strings.sendEmail,
          onPressed: _sendEmail,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SettingsHelpPageState extends State<_SettingsHelpPage> {
  static const _contactPhone = '0501234567';
  static const _contactEmail = 'shilohdhd1@gmail.com';

  String _languageSubtitle(AppStrings strings) =>
      AppLocale.instance.isHebrew ? strings.languageCurrentHe : strings.languageCurrentEn;

  String _themeSubtitle(AppStrings strings) {
    return switch (AppThemeController.instance.mode) {
      AppThemeMode.calm => strings.themeCalm,
      AppThemeMode.light => strings.themeLight,
      AppThemeMode.dark => strings.themeDark,
    };
  }

  Future<void> _openSheet({required Widget child, String? title}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        final bottom = MediaQuery.viewPaddingOf(context).bottom;
        return bakeryModalSheetFrame(
          context,
          ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
            children: [child],
          ),
          title: title,
        );
      },
    );
  }

  Future<void> _openLanguagePanel() async {
    final strings = s;
    await _openSheet(
      title: strings.chooseLanguage,
      child: ListenableBuilder(
        listenable: AppLocale.instance,
        builder: (context, _) {
          return Column(
            children: [
              _SettingsOptionTile(
                label: strings.languageCurrentHe,
                selected: AppLocale.instance.isHebrew,
                icon: Icons.translate,
                onTap: () => AppLocale.instance.setHebrew(true),
              ),
              const SizedBox(height: 10),
              _SettingsOptionTile(
                label: strings.languageCurrentEn,
                selected: AppLocale.instance.isEnglish,
                icon: Icons.language,
                onTap: () => AppLocale.instance.setHebrew(false),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openDisplayModePanel() async {
    final strings = s;
    final theme = AppThemeController.instance;
    await _openSheet(
      title: strings.chooseDisplayMode,
      child: ListenableBuilder(
        listenable: theme,
        builder: (context, _) {
          return Column(
            children: [
              _SettingsOptionTile(
                label: strings.themeCalm,
                subtitle: strings.themeCalmSub,
                selected: theme.mode == AppThemeMode.calm,
                icon: Icons.spa,
                onTap: () => theme.setMode(AppThemeMode.calm),
              ),
              const SizedBox(height: 10),
              _SettingsOptionTile(
                label: strings.themeLight,
                subtitle: strings.themeLightSub,
                selected: theme.mode == AppThemeMode.light,
                icon: Icons.light_mode,
                onTap: () => theme.setMode(AppThemeMode.light),
              ),
              const SizedBox(height: 10),
              _SettingsOptionTile(
                label: strings.themeDark,
                subtitle: strings.themeDarkSub,
                selected: theme.mode == AppThemeMode.dark,
                icon: Icons.dark_mode,
                onTap: () => theme.setMode(AppThemeMode.dark),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openAccessibilityPanel() => showAccessibilityPanel(context);

  Future<void> _openStoreTermsPanel() async {
    final strings = s;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: BakeryTheme.softSurface(context),
      builder: (context) {
        final bottom = MediaQuery.viewPaddingOf(context).bottom;
        return _SheetRouteFade(
          child: bakeryModalSheetFrame(
            context,
            _HelpSheetShell(
              child: ListenableBuilder(
                listenable: StoreTermsStore.instance,
                builder: (context, _) {
                  final text = StoreTermsStore.instance.terms.trim();
                  return ListView(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
                    children: [
                      Center(child: _HelpSheetHeader(icon: Icons.gavel_rounded)),
                      const SizedBox(height: 16),
                      if (text.isEmpty)
                        Text(
                          strings.managerStoreTermsEmpty,
                          textAlign: TextAlign.center,
                          style: BakeryTheme.subtitleText(context, height: 1.4),
                        )
                      else
                        SelectableText(
                          text,
                          style: BakeryTheme.text(context, fontSize: 15, height: 1.5),
                        ),
                    ],
                  );
                },
              ),
            ),
            title: strings.storeTerms,
          ),
        );
      },
    );
  }

  Future<void> _openContactPanel() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: BakeryTheme.softSurface(context),
      builder: (sheetContext) => _SheetRouteFade(
        child: bakeryModalSheetFrame(
          sheetContext,
          _HelpSheetShell(
            child: _ContactPanelSheet(
              contactPhone: _contactPhone,
              contactEmail: _contactEmail,
              parentContext: context,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReviewPanel() async {
    await showReviewDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = s;

    final moreSettings = [
          _SettingsMenuItem(
            icon: Icons.language,
            title: strings.language,
            subtitle: _languageSubtitle(strings),
            onTap: _openLanguagePanel,
          ),
          _SettingsMenuItem(
            icon: Icons.palette_outlined,
            title: strings.displayMode,
            subtitle: _themeSubtitle(strings),
            onTap: _openDisplayModePanel,
          ),
          _SettingsMenuItem(
            icon: Icons.accessible_forward,
            title: strings.accessibility,
            subtitle: strings.accessibilitySub,
            onTap: _openAccessibilityPanel,
          ),
          _SettingsMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: strings.legalPrivacyPolicy,
            subtitle: strings.legalPrivacySub,
            onTap: () => LegalDocumentScreen.open(context, LegalDocumentKind.privacy),
          ),
          _SettingsMenuItem(
            icon: Icons.description_outlined,
            title: strings.legalTermsOfUse,
            subtitle: strings.legalTermsSub,
            onTap: () => LegalDocumentScreen.open(context, LegalDocumentKind.terms),
          ),
    ];

    final bottomPad = 24 + MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight;

    return CustomerTabBody(
      child: ListenableBuilder(
        listenable: Listenable.merge([StoreTermsStore.instance, ManagerStore.instance]),
        builder: (context, _) {
          final showStoreTerms = StoreTermsStore.instance.hasTerms;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
            children: [
              _OrdersPanel(
                padding: const EdgeInsets.all(12),
                surfaceColor: BakeryTheme.softSurface(context),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.02,
                  children: [
                  ManagerActionSquare(
                    title: strings.contact,
                    subtitle: strings.contactSub,
                    icon: Icons.mail_outline_rounded,
                    colorIndex: 0,
                    solidFill: true,
                    onTap: _openContactPanel,
                  ),
                  if (showStoreTerms)
                    ManagerActionSquare(
                      title: strings.storeTerms,
                      subtitle: strings.storeTermsSub,
                      icon: Icons.gavel_outlined,
                      colorIndex: 4,
                      solidFill: true,
                      onTap: _openStoreTermsPanel,
                    ),
                  ManagerActionSquare(
                    title: strings.leaveReview,
                    subtitle: strings.leaveReviewSub,
                    icon: Icons.star_outline_rounded,
                    colorIndex: 2,
                    solidFill: true,
                    onTap: _openReviewPanel,
                  ),
                  ManagerActionSquare(
                    title: strings.managerEntry,
                    subtitle: strings.managerEntrySub,
                    icon: Icons.admin_panel_settings_outlined,
                    colorIndex: 3,
                    highlighted: true,
                    solidFill: true,
                    onTap: () => showManagerLogin(context),
                  ),
                  if (SupabaseBootstrap.isReady)
                    ManagerActionSquare(
                      title: strings.saasCreateStore,
                      subtitle: strings.saasCreateStoreSub,
                      icon: Icons.add_business_outlined,
                      colorIndex: 0,
                      solidFill: true,
                      onTap: () => openSaasCreateStoreFlow(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ...moreSettings.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: item,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  const _SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: _OrdersPanel(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BakeryTheme.cardSurface(context).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: BakeryTheme.accent(context), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BakeryTheme.body(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BakeryTheme.subtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: BakeryTheme.muted(context), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsOptionTile extends StatelessWidget {
  const _SettingsOptionTile({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decor = bakeryDecor(context);
    final isDark = scheme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? decor.cardFill : BakeryTheme.softSurface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? decor.accent : BakeryTheme.border(context),
              width: selected ? 2.2 : 1,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
                  ],
          ),
          child: Row(
            children: [
              Icon(icon, color: decor.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: scheme.onSurface),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: decor.accent),
            ],
          ),
        ),
      ),
    );
  }
}