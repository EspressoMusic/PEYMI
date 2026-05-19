import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/accessibility_settings.dart';
import 'core/app_fonts.dart';
import 'core/app_config_scope.dart';
import 'core/bakery_navigator.dart';
import 'core/app_locale.dart';
import 'core/app_theme_mode.dart';
import 'core/business_store.dart';
import 'core/catalog_store.dart';
import 'core/community_messages_store.dart';
import 'core/catalog_data.dart';
import 'core/contact_bot.dart';
import 'core/keyboard_safe.dart';
import 'core/manager_notifications_store.dart';
import 'core/manager_store.dart';
import 'core/reviews_store.dart';
import 'core/stripe_payment_service.dart';
import 'core/stripe_config.dart';
import 'manager_action_pages.dart';
import 'widgets/bakery_celebration.dart';
import 'widgets/catalog_item_image.dart';
import 'employee_ui.dart';
import 'manager_ui.dart';
import 'widgets/bakery_bottom_bar.dart';
import 'widgets/store_announcement_panel.dart';

AppStrings get s => AppLocale.instance.s;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.instance.load();
  await AppThemeController.instance.load();
  await AccessibilitySettings.instance.load();
  await BusinessStore.instance.load();
  await ReviewsStore.instance.load();
  await ManagerStore.instance.load();
  await ManagerNotificationsStore.instance.load();
  await CatalogStore.instance.load();
  await CommunityMessagesStore.instance.load();
  await StripePaymentService.initialize();
  runApp(const BakeryApp());
}

class BakeryApp extends StatelessWidget {
  const BakeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: bakeryNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppLocale.instance.s.appTitle,
      theme: AppThemeController.instance.theme(),
      builder: (context, child) => AppConfigScope(child: child ?? const SizedBox.shrink()),
      home: const BakeryHomePage(),
    );
  }
}

const String _managerPassword = '1234';
const String _employeePassword = '4321';

Future<void> showStaffLogin(
  BuildContext context, {
  required String loginTitle,
  required String passwordHint,
  required IconData headerIcon,
  required String password,
  required Widget homePage,
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
    Navigator.pop(dialogContext, true);
  }

  final approved = await showBakeryDialog<bool>(
    context: context,
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
                  icon: Icons.close,
                  label: strings.cancel,
                  onPressed: () => Navigator.pop(dialogContext, false),
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
  await WidgetsBinding.instance.endOfFrame;

  final navigator = bakeryNavigatorKey.currentState;
  if (navigator == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => passwordController.dispose());
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => passwordController.dispose());

  navigator.push<void>(
    MaterialPageRoute<void>(builder: (_) => homePage),
  );
}

Future<void> showManagerLogin(BuildContext context) async {
  await showStaffLogin(
    context,
    loginTitle: s.managerLoginTitle,
    passwordHint: s.managerPasswordHint,
    headerIcon: Icons.admin_panel_settings,
    password: _managerPassword,
    homePage: const ManagerHomePage(),
  );
}

Future<void> showEmployeeLogin(BuildContext context) async {
  await showStaffLogin(
    context,
    loginTitle: s.employeeLoginTitle,
    passwordHint: s.employeePasswordHint,
    headerIcon: Icons.badge_outlined,
    password: _employeePassword,
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
    builder: (sheetContext) => bakeryModalSheetFrame(sheetContext, const _ReviewSheet()),
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
                    strings.reviewsSheetTitle,
                    textAlign: TextAlign.center,
                    style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.reviewsSheetSub,
                    textAlign: TextAlign.center,
                    style: BakeryTheme.subtitleText(context, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
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
        final bottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 8, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.storeAnnouncementPopupTitle,
                      style: BakeryTheme.text(sheetContext, fontSize: 20, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetContext),
                    tooltip: s.dismissAnnouncement,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StoreAnnouncementPanel(
                message: message,
                imagePath: ann.imagePath,
                showHeader: false,
                compact: true,
              ),
            ],
          ),
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
    final hasActiveOrder = cartItems.isNotEmpty || _dealOrders.isNotEmpty;

    final List<Widget> pages = [
      _SettingsHelpPage(),
      ListenableBuilder(
        listenable: ManagerStore.instance,
        builder: (context, _) => _DealsPage(
        deals: _visibleDeals,
        redeemedDealIds: _activeRedeemedDealIds,
        onRedeemDeal: (deal) async {
          final dealId = deal['id'] as String;
          if (_redeemedDealsAt.containsKey(dealId)) return;
          await _markDealRedeemed(dealId);
          setState(() {
            _dealOrders.add({
              'id': 'DEAL-${_dealOrders.length + 1}',
              'title': CatalogData.dealField(deal, 'title'),
              'total': deal['priceAfterDiscount'],
              'statusKey': 'ready',
              'date': _formatDate(DateTime.now()),
              'items': List<Map<String, dynamic>>.from(deal['items'] as List),
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
      const SizedBox.shrink(),
      ListenableBuilder(
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
    ];

    final showBottomBar = ModalRoute.of(context)?.isCurrent ?? true;

    return Scaffold(
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
                      final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
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
            ? BakeryBottomBar(
                selectedIndex: _navBarIndex(_selectedIndex),
                onSelected: _onBottomNavSelected,
                badgeIndices: _dealAlertBadge ? {_navDealsIndex} : const {},
                items: [
                  (icon: Icons.settings, label: strings.navSettings),
                  (icon: Icons.local_offer, label: strings.navDeals),
                  (icon: Icons.receipt_long, label: strings.navOrders),
                  (icon: Icons.storefront, label: strings.navCatalog),
                ],
              )
            : null,
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
  bool _showDrinks = false;
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
    final items = _showDrinks ? widget.drinks : widget.products;
    return Stack(
      children: [
        Column(
          children: [
            SafeArea(
              bottom: false,
              minimum: const EdgeInsets.only(top: 8),
              child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: SegmentedButton<bool>(
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  textStyle: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800),
                  foregroundColor: BakeryTheme.body(context),
                  selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                  selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                  iconSize: 28,
                ),
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.bakery_dining, size: 28),
                    label: Text(s.bakeryCategory),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.local_cafe, size: 28),
                    label: Text(s.drinksCategory),
                  ),
                ],
                selected: {_showDrinks},
                onSelectionChanged: (v) => setState(() => _showDrinks = v.first),
              ),
            ),
            ),
            Expanded(
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
          ],
        ),
        if (_confettiToken > 0)
          IgnorePointer(
            child: BakeryEmojiConfetti(
              key: ValueKey(_confettiToken),
              onFinished: () {},
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
        border: Border.all(color: BakeryTheme.border(context)),
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

class _AnimatedProductCard extends StatefulWidget {
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
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _showProductInfo() => _ProductInfoSheet.show(context, widget.item);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: Builder(
        builder: (context) {
          final decor = bakeryDecor(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [decor.panelTop, decor.cardFill],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BakeryTheme.border(context)),
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
                  onTap: _showProductInfo,
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
                      _CompactIconButton(onPressed: widget.onDecrease, icon: Icons.remove),
                      GestureDetector(
                        onTap: widget.onPickQuantity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${widget.quantity}',
                            style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      _CompactIconButton(onPressed: widget.onIncrease, icon: Icons.add),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
          );
        },
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
      minimum: const EdgeInsets.only(top: 20),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          ...sortedDeals.map((deal) {
            final dealId = deal['id'] as String;
            final redeemed = redeemedDealIds.contains(dealId);
            final images = (deal['images'] as List?)?.cast<String>() ?? const <String>[];
            final price = deal['priceAfterDiscount']?.toString() ?? '';
            final valid = CatalogData.dealField(deal, 'valid');

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Opacity(
                opacity: redeemed ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: redeemed,
                  child: _OrdersPanel(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          CatalogData.dealField(deal, 'title'),
                          textAlign: TextAlign.center,
                          style: BakeryTheme.text(context, fontSize: 27, fontWeight: FontWeight.w800, height: 1.2),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: BakeryTheme.cardSurface(context).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: BakeryTheme.border(context)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 20, color: BakeryTheme.subtitle(context)),
                                const SizedBox(width: 6),
                                Text(
                                  strings.validUntil(valid),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: BakeryTheme.subtitle(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _DealProductsRow(deal: deal, images: images),
                        const SizedBox(height: 18),
                        _DealPriceTile(
                          label: strings.totalPrice,
                          value: price,
                        ),
                        const SizedBox(height: 16),
                        _OrderSheetActionButton(
                          primary: true,
                          disabled: redeemed,
                          icon: redeemed ? Icons.check_circle_outline : Icons.discount_outlined,
                          label: redeemed ? strings.dealRedeemed : strings.redeemDeal,
                          labelFontSize: 18,
                          onPressed: redeemed ? null : () => onRedeemDeal(deal),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DealProductsRow extends StatelessWidget {
  const _DealProductsRow({required this.deal, required this.images});

  final Map<String, dynamic> deal;
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final items = (deal['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();

    Widget plusBadge() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: BakeryTheme.cardSurface(context).withValues(alpha: 0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.add, color: BakeryTheme.accent(context), size: 22),
          ),
        );

    final previews = <Widget>[
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) plusBadge(),
        SizedBox(
          width: items.length <= 2 ? 140 : 112,
          child: _DealProductPreview(
            imagePath: i < images.length ? images[i] : null,
            deal: deal,
            itemIndex: i,
          ),
        ),
      ],
    ];

    if (items.length == 1) {
      return Center(child: SizedBox(width: 160, child: previews.first));
    }
    if (items.length == 2) {
      return Row(children: [Expanded(child: previews[0]), previews[1], Expanded(child: previews[2])]);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: previews),
    );
  }
}

class _DealProductPreview extends StatelessWidget {
  const _DealProductPreview({required this.imagePath, required this.deal, required this.itemIndex});

  final String? imagePath;
  final Map<String, dynamic> deal;
  final int itemIndex;

  @override
  Widget build(BuildContext context) {
    final items = (deal['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final item = itemIndex < items.length ? items[itemIndex] : null;
    final productId = item?['id']?.toString();
    final product = productId != null ? CatalogStore.instance.findById(productId) : null;
    final name = product != null ? CatalogData.name(product) : '';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _DealImageFallback(emoji: product?['emoji'] ?? '🥖'),
                    )
                  : _DealImageFallback(emoji: product?['emoji'] ?? '🥖'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
        ),
      ],
    );
  }
}

class _DealImageFallback extends StatelessWidget {
  const _DealImageFallback({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BakeryTheme.softSurface(context),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 36)),
    );
  }
}

class _OrdersPanel extends StatelessWidget {
  const _OrdersPanel({required this.child, this.padding = const EdgeInsets.all(18), this.border});

  final Widget child;
  final EdgeInsets padding;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: BakeryTheme.panelGradient(context),
        ),
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

    return Material(
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
                ? (enabled ? null : decor.chipFill)
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
                Text(
                  strings.orderTitle(orderId),
                  style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
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

  @override
  Widget build(BuildContext context) {
    final strings = s;
    final cartEmpty = widget.cartItems.isEmpty;
    final dealsEmpty = widget.dealOrders.isEmpty;
    final hasCheckout = !cartEmpty || !dealsEmpty;

    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.only(top: 20),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (widget.showAnnouncement) ...[
            Text(strings.storeAnnouncementInOrders, style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: StoreAnnouncementPanel(
                message: widget.announcementMessage,
                imagePath: widget.announcementImagePath,
                onDismiss: widget.onDismissAnnouncement,
                compact: true,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!hasCheckout)
            _OrdersPanel(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BakeryTheme.cardSurface(context).withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.shopping_cart_outlined, color: BakeryTheme.accent(context), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.cartEmpty,
                          style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.cartEmptySub,
                          style: TextStyle(fontSize: 14, height: 1.35, color: BakeryTheme.subtitle(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (!dealsEmpty) ...[
              Text(strings.cartDealsSection, style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...widget.dealOrders.map(
                (deal) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DealCartCard(
                    dealOrder: deal,
                    onRemove: () => widget.onRemoveDeal(deal['id'] as String),
                  ),
                ),
              ),
              if (!cartEmpty) const SizedBox(height: 8),
            ],
            if (!cartEmpty) ...[
              GridView.builder(
                itemCount: widget.cartItems.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return _CartSquareCard(
                    item: item,
                    onDecrease: () => widget.onDecrease(item['id']!),
                    onIncrease: () => widget.onIncrease(item['id']!),
                  );
                },
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: widget.onConfirmOrder,
                icon: const Icon(Icons.check_circle),
                label: Text(strings.confirmOrder),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => setState(() => _showPastOrders = !_showPastOrders),
              child: _OrdersPanel(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.orderHistory,
                            style: BakeryTheme.text(context, fontSize: 19, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.tapToExpandHistory,
                            style: TextStyle(fontSize: 14, color: BakeryTheme.subtitle(context)),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showPastOrders ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(Icons.expand_more, color: BakeryTheme.accent(context), size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showPastOrders) ...[
            const SizedBox(height: 20),
            if (widget.orders.isEmpty)
              _OrdersPanel(
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off, size: 40, color: BakeryTheme.muted(context)),
                    const SizedBox(height: 12),
                    Text(
                      strings.noPastOrders,
                      textAlign: TextAlign.center,
                      style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.noPastOrdersSub,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, height: 1.35, color: BakeryTheme.subtitle(context)),
                    ),
                  ],
                ),
              )
            else
              ...widget.orders.map((order) {
                final id = order['id'].toString();
                final remembered = _rememberedOrderIds.contains(id);
                final date = order['date']?.toString() ?? '';
                final total = order['total']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _OrdersPanel(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openPastOrderSheet(order),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _OrderMetricTile(
                                      icon: Icons.calendar_month_outlined,
                                      label: strings.date,
                                      value: date,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _OrderMetricTile(
                                      icon: Icons.payments_outlined,
                                      label: strings.totalPrice,
                                      value: total,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (remembered)
                          IconButton(
                            tooltip: strings.forgetOrder,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            onPressed: () => _forgetOrder(id),
                            icon: Icon(Icons.bookmark, color: BakeryTheme.accent(context), size: 24),
                          )
                        else
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            onPressed: () => _openPastOrderSheet(order),
                            icon: Icon(Icons.chevron_right, color: BakeryTheme.muted(context), size: 26),
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _DealCartCard extends StatelessWidget {
  const _DealCartCard({
    required this.dealOrder,
    required this.onRemove,
  });

  final Map<String, dynamic> dealOrder;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = s;
    final items = (dealOrder['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final title = dealOrder['title']?.toString() ?? strings.navDeals;
    final total = dealOrder['total']?.toString() ?? '';

    return _OrdersPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_offer_outlined, color: BakeryTheme.accent(context), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800)),
                    if (total.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(total, style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: strings.removeDealFromCart,
                onPressed: onRemove,
                icon: Icon(Icons.close_rounded, color: BakeryTheme.muted(context)),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...items.map((item) {
              final id = item['id']?.toString();
              final product = id != null ? CatalogStore.instance.findById(id) : null;
              final name = product != null ? CatalogData.name(product) : id ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    if (product?['image'] != null)
                      CatalogItemImage(
                        path: product!['image']!,
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.circular(10),
                        emoji: product['emoji'] ?? '🥖',
                      ),
                    if (product?['image'] != null) const SizedBox(width: 10),
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
  });

  final Map<String, String> item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final imagePath = item['image'];
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: BakeryTheme.panelGradient(context),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BakeryTheme.border(context), width: 2.4),
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
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imagePath != null
                  ? CatalogItemImage(
                      path: imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      emoji: item['emoji'] ?? '🥖',
                    )
                  : Center(
                      child: Text(item['emoji'] ?? '🥖', style: const TextStyle(fontSize: 40)),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['name']!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: BakeryTheme.body(context)),
          ),
          Text(
            item['price']!,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: BakeryTheme.subtitle(context)),
          ),
          const SizedBox(height: 6),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: BakeryTheme.cardSurface(context).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BakeryTheme.border(context), width: 1.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: onDecrease,
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(width: 32, height: 32, child: Icon(Icons.remove, size: 18)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    item['quantity']!,
                    style: BakeryTheme.text(context, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                InkWell(
                  onTap: onIncrease,
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(width: 32, height: 32, child: Icon(Icons.add, size: 18)),
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
    final gradient = BakeryTheme.panelGradient(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradient.first, gradient.last.withValues(alpha: 0.92), Theme.of(context).scaffoldBackgroundColor],
            stops: const [0, 0.35, 1],
          ),
          border: Border(top: BorderSide(color: BakeryTheme.border(context), width: 1.2)),
        ),
        child: child,
      ),
    );
  }
}

class _HelpSheetHeader extends StatelessWidget {
  const _HelpSheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
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
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.4),
        ),
      ],
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

class _FaqExpandTile extends StatelessWidget {
  const _FaqExpandTile({
    required this.index,
    required this.question,
    required this.answer,
    required this.isOpen,
    required this.onTap,
  });

  final int index;
  final String question;
  final String answer;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final decor = bakeryDecor(context);
    final accent = BakeryTheme.accent(context);
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOpen ? accent.withValues(alpha: 0.55) : BakeryTheme.border(context),
          width: isOpen ? 1.4 : 1.1,
        ),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: _OrdersPanel(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isOpen ? scheme.primary.withValues(alpha: 0.07) : Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isOpen ? accent.withValues(alpha: 0.2) : decor.chipFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isOpen ? accent : decor.mutedText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question,
                          style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800, height: 1.35),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                        child: Icon(Icons.add_rounded, color: accent, size: 26),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: isOpen
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12, left: 42, right: 8),
                            child: Text(
                              answer,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: AppFonts.regular,
                                color: decor.mutedText,
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactChatBubble extends StatefulWidget {
  const _ContactChatBubble({super.key, required this.fromBot, required this.text});

  final bool fromBot;
  final String text;

  @override
  State<_ContactChatBubble> createState() => _ContactChatBubbleState();
}

class _ContactChatBubbleState extends State<_ContactChatBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.fromBot ? -0.08 : 0.08, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final align = widget.fromBot ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd;
    final scheme = Theme.of(context).colorScheme;
    final accent = BakeryTheme.accent(context);

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: widget.fromBot
            ? null
            : LinearGradient(
                colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.1)],
              ),
        color: widget.fromBot ? BakeryTheme.cardSurface(context).withValues(alpha: 0.96) : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(widget.fromBot ? 4 : 18),
          bottomRight: Radius.circular(widget.fromBot ? 18 : 4),
        ),
        border: Border.all(
          color: widget.fromBot ? BakeryTheme.border(context) : accent.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: scheme.brightness == Brightness.dark ? 0.28 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        widget.text,
        style: TextStyle(
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: BakeryTheme.body(context),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Align(
            alignment: align,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.fromBot) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: accent.withValues(alpha: 0.18),
                    child: Icon(Icons.smart_toy_rounded, size: 18, color: accent),
                  ),
                  const SizedBox(width: 8),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.68),
                  child: bubble,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ContactPanelMode { bot, email, community }

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
  _ContactPanelMode _mode = _ContactPanelMode.bot;
  final List<({bool fromBot, String text})> _messages = [];
  int _botFails = 0;
  bool _showOwnerForm = false;
  final _listScroll = ScrollController();

  final _chatController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerMessageController = TextEditingController();
  final _communityNameController = TextEditingController();
  final _communityMessageController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _ownerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _messages.add((fromBot: true, text: s.botWelcome));
  }

  @override
  void dispose() {
    _listScroll.dispose();
    _chatController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _ownerNameController.dispose();
    _ownerMessageController.dispose();
    _communityNameController.dispose();
    _communityMessageController.dispose();
    super.dispose();
  }

  void _sendChat() {
    final strings = s;
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add((fromBot: false, text: text));
      _chatController.clear();
      final reply = ContactBot.reply(text, AppLocale.instance.isHebrew);
      if (reply != null) {
        _botFails = 0;
        _messages.add((fromBot: true, text: reply));
      } else {
        _botFails++;
        _messages.add((fromBot: true, text: strings.botNoAnswer));
        if (_botFails >= 2) _showOwnerForm = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScroll.hasClients) {
        _listScroll.animateTo(
          _listScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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

  Future<void> _sendToOwner() async {
    final strings = s;
    if (!(_ownerFormKey.currentState?.validate() ?? false)) return;
    final body =
        '${strings.yourName}: ${_ownerNameController.text.trim()}\n${_ownerMessageController.text.trim()}';
    final smsUri = Uri.parse('sms:${widget.contactPhone}?body=${Uri.encodeComponent(body)}');
    final waUri = Uri.parse(
      'https://wa.me/972${widget.contactPhone.substring(1)}?text=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
    await ManagerStore.instance.logInquiry(
      message: _ownerMessageController.text.trim(),
      channel: 'owner',
      customerName: _ownerNameController.text.trim(),
    );
    await BusinessStore.instance.recordInquiry();
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.parentContext.mounted) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text(strings.ownerMessageSent)),
      );
    }
  }

  Widget _buildModeSwitcher(AppStrings strings) {
    return _OrdersPanel(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _contactModeChip(
            selected: _mode == _ContactPanelMode.bot,
            icon: Icons.smart_toy_rounded,
            label: strings.contactBotTab,
            onTap: () => setState(() => _mode = _ContactPanelMode.bot),
          ),
          const SizedBox(width: 6),
          _contactModeChip(
            selected: _mode == _ContactPanelMode.email,
            icon: Icons.email_rounded,
            label: strings.contactEmailTab,
            onTap: () => setState(() => _mode = _ContactPanelMode.email),
          ),
          const SizedBox(width: 6),
          _contactModeChip(
            selected: _mode == _ContactPanelMode.community,
            icon: Icons.forum_outlined,
            label: strings.contactCommunityTab,
            onTap: () => setState(() => _mode = _ContactPanelMode.community),
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
    final decor = bakeryDecor(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HelpSheetHeader(
            icon: Icons.support_agent_rounded,
            title: strings.contactTitle,
            subtitle: strings.contactSub,
          ),
          const SizedBox(height: 16),
          _buildModeSwitcher(strings),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
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
                _ContactPanelMode.bot => _buildBotView(strings, decor, key: const ValueKey('bot')),
                _ContactPanelMode.email => _buildEmailView(strings, key: const ValueKey('email')),
                _ContactPanelMode.community => _buildCommunityView(strings, key: const ValueKey('community')),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityView(AppStrings strings, {Key? key}) {
    final he = AppLocale.instance.isHebrew;
    return ListenableBuilder(
      key: key,
      listenable: CommunityMessagesStore.instance,
      builder: (context, _) {
        final messages = CommunityMessagesStore.instance.messages;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.contactCommunityHint, style: BakeryTheme.subtitleText(context, fontSize: 13)),
            const SizedBox(height: 10),
            Expanded(
              child: _OrdersPanel(
                padding: const EdgeInsets.all(12),
                child: messages.isEmpty
                    ? Center(child: Text(strings.contactCommunityEmpty, style: BakeryTheme.subtitleText(context)))
                    : ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.author(he), style: BakeryTheme.text(context, fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(m.text(he), style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.35)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _communityNameController,
              decoration: bakeryInputDecoration(context, label: strings.contactYourName, icon: Icons.person_outline),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _communityMessageController,
              maxLines: 3,
              decoration: bakeryInputDecoration(context, label: strings.yourMessage, icon: Icons.chat_bubble_outline),
            ),
            const SizedBox(height: 10),
            _OrderSheetActionButton(
              primary: true,
              icon: Icons.send_rounded,
              label: strings.contactPostMessage,
              onPressed: () async {
                await CommunityMessagesStore.instance.post(
                  author: _communityNameController.text,
                  text: _communityMessageController.text,
                );
                _communityMessageController.clear();
                if (!mounted) return;
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBotView(AppStrings strings, BakeryDecor decor, {Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _OrdersPanel(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: ListView(
              controller: _listScroll,
              children: [
                ..._messages.asMap().entries.map(
                      (e) => _ContactChatBubble(
                        key: ValueKey('msg_${e.key}_${e.value.text.hashCode}'),
                        fromBot: e.value.fromBot,
                        text: e.value.text,
                      ),
                    ),
                if (_showOwnerForm) ...[
                  const SizedBox(height: 8),
                  _SheetEntrance(
                    delayMs: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.contactOwnerHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: decor.mutedText),
                        ),
                        const SizedBox(height: 12),
                        _OrdersPanel(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _ownerFormKey,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_pin_circle_rounded, color: BakeryTheme.accent(context)),
                                    const SizedBox(width: 8),
                                    Text(
                                      strings.contactOwner,
                                      style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _ownerNameController,
                                  decoration: bakeryInputDecoration(context, label: strings.yourName, icon: Icons.person_outline),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? strings.fillAllFields : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _ownerMessageController,
                                  maxLines: 4,
                                  decoration: bakeryInputDecoration(context, label: strings.yourMessage, icon: Icons.chat_bubble_outline),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? strings.fillAllFields : null,
                                ),
                                const SizedBox(height: 14),
                                _OrderSheetActionButton(
                                  primary: true,
                                  icon: Icons.send_rounded,
                                  label: strings.sendToOwner,
                                  onPressed: _sendToOwner,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _OrdersPanel(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendChat(),
                  decoration: bakeryInputDecoration(context, label: '', icon: Icons.chat_outlined).copyWith(
                    hintText: strings.botTypeHint,
                    labelText: null,
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded, color: BakeryTheme.muted(context), size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
                elevation: 2,
                shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _sendChat,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailView(AppStrings strings, {Key? key}) {
    return ListView(
      key: key,
      controller: _listScroll,
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

  Future<void> _openSheet({required String title, required Widget child}) async {
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
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
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

  Future<void> _openAccessibilityPanel() async {
    const accessibilityEmail = 'shilohdhd1@gmail.com';
    final strings = s;
    final a11y = AccessibilitySettings.instance;

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
          ListenableBuilder(
            listenable: a11y,
            builder: (context, _) {
              final percent = (a11y.textScale * 100).round();
              return ListView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
                children: [
                  Text(
                    strings.accessibilityTitle,
                    textAlign: TextAlign.center,
                    style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  _OrdersPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.textSize,
                          textAlign: TextAlign.center,
                          style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$percent%',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: BakeryTheme.body(context)),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _OrderSheetActionButton(
                                icon: Icons.text_decrease,
                                label: strings.decreaseText,
                                onPressed: a11y.decreaseText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _OrderSheetActionButton(
                                icon: Icons.restart_alt,
                                label: strings.resetTextSize,
                                onPressed: a11y.resetText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _OrderSheetActionButton(
                                primary: true,
                                icon: Icons.text_increase,
                                label: strings.increaseText,
                                onPressed: a11y.increaseText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.accessibilityBody(accessibilityEmail),
                    style: TextStyle(fontSize: 14, height: 1.45, color: BakeryTheme.subtitle(context)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openFaqPanel() async {
    final strings = s;
    final faq = strings.faqItems;
    final expanded = <int>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.viewPaddingOf(context).bottom;
        return _SheetRouteFade(
          child: bakeryModalSheetFrame(
            context,
            _HelpSheetShell(
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return ListView(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
                    children: [
                      _HelpSheetHeader(
                        icon: Icons.quiz_rounded,
                        title: strings.faqTitle,
                        subtitle: strings.faqSub,
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(faq.length, (i) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: i < faq.length - 1 ? 12 : 0),
                          child: _SheetEntrance(
                            delayMs: 50 + i * 45,
                            child: _FaqExpandTile(
                              index: i,
                              question: faq[i].q,
                              answer: faq[i].a,
                              isOpen: expanded.contains(i),
                              onTap: () => setModalState(() {
                                if (expanded.contains(i)) {
                                  expanded.remove(i);
                                } else {
                                  expanded.add(i);
                                }
                              }),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
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
      backgroundColor: Colors.transparent,
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
    ];

    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.only(top: 20),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
                children: [
                  ManagerActionSquare(
                    title: strings.contact,
                    subtitle: strings.contactSub,
                    icon: Icons.mail_outline_rounded,
                    colorIndex: 0,
                    showInfoButton: true,
                    onTap: _openContactPanel,
                  ),
                  ManagerActionSquare(
                    title: strings.faq,
                    subtitle: strings.faqSub,
                    icon: Icons.help_outline_rounded,
                    colorIndex: 1,
                    showInfoButton: true,
                    onTap: _openFaqPanel,
                  ),
                  ManagerActionSquare(
                    title: strings.leaveReview,
                    subtitle: strings.leaveReviewSub,
                    icon: Icons.star_outline_rounded,
                    colorIndex: 2,
                    showInfoButton: true,
                    onTap: _openReviewPanel,
                  ),
                  ManagerActionSquare(
                    title: strings.managerEntry,
                    subtitle: strings.managerEntrySub,
                    icon: Icons.admin_panel_settings_outlined,
                    colorIndex: 3,
                    highlighted: true,
                    showInfoButton: true,
                    onTap: () => showManagerLogin(context),
                  ),
                  ManagerActionSquare(
                    title: strings.employeeEntry,
                    subtitle: strings.employeeEntrySub,
                    icon: Icons.badge_outlined,
                    colorIndex: 4,
                    highlighted: true,
                    showInfoButton: true,
                    onTap: () => showEmployeeLogin(context),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...moreSettings.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: item,
                ),
              ),
            ],
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
            color: selected
                ? decor.cardFill
                : decor.chipFill.withValues(alpha: isDark ? 0.85 : 0.65),
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