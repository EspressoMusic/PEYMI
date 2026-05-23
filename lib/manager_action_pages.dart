import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'core/app_colors.dart';
import 'core/app_fonts.dart';
import 'core/app_locale.dart';
import 'core/app_theme_mode.dart';
import 'core/bakery_square_palette.dart';
import 'core/business_analytics.dart';
import 'core/business_store.dart';
import 'core/catalog_data.dart';
import 'core/catalog_store.dart';
import 'core/faq_store.dart';
import 'core/store_terms_store.dart';
import 'core/catalog_image_storage.dart';
import 'core/locale_translate.dart';
import 'core/manager_store.dart';
import 'core/manager_subscription_store.dart';
import 'core/order_restrictions_store.dart';
import 'core/reviews_store.dart';
import 'widgets/bakery_celebration.dart';
import 'widgets/catalog_item_image.dart';
import 'widgets/bakery_sheet_close_bar.dart';
import 'widgets/manager_revenue_chart.dart';
import 'saas/widgets/saas_store_mode_section.dart';

AppStrings get _s => AppLocale.instance.s;

const _managerFormFieldHeight = 56.0;

class ManagerActionSquare extends StatelessWidget {
  const ManagerActionSquare({
    super.key,
    required this.title,
    required this.subtitle,
    required this.colorIndex,
    required this.onTap,
    this.icon,
    this.showInfoButton = false,
    this.highlighted = false,
    this.solidFill = false,
    this.comingSoon = false,
    this.fillColor,
  });

  final String title;
  final String subtitle;
  final int colorIndex;
  final VoidCallback onTap;
  final IconData? icon;
  /// Small ℹ️ in the corner (manager actions tab only).
  final bool showInfoButton;
  /// Manager login tile in settings — distinct accent styling.
  final bool highlighted;
  /// Uniform color (settings tab); default gradient elsewhere.
  final bool solidFill;
  /// Disabled, faded tile (e.g. employee login not ready yet).
  final bool comingSoon;
  /// Overrides [BakerySquarePalette.squareFill] when set.
  final Color? fillColor;

  void _showInfo(BuildContext context) {
    if (subtitle.trim().isEmpty) return;
    final strings = _s;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: AppFonts.style(fontSize: 22, color: BakerySquarePalette.title(ctx), fontWeight: AppFonts.bold),
        ),
        content: Text(
          subtitle,
          textAlign: TextAlign.center,
          style: BakeryTheme.subtitleText(ctx, fontSize: 16, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.close)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildCenteredTile(context);

  Widget _buildCenteredTile(BuildContext context) {
    final textDirection = Directionality.of(context);
    final fillColor = this.fillColor ??
        (solidFill
            ? BakerySquarePalette.squareFill(context)
            : BakerySquarePalette.solidAt(context, colorIndex));
    final border = switch ((highlighted, solidFill, comingSoon)) {
      (_, _, true) => BakerySquarePalette.squareBorder(context),
      (true, _, false) => Border.all(color: BakeryTheme.accent(context), width: 2),
      (_, true, false) => Border.all(
          color: AppColors.brownMedium.withValues(alpha: 0.55),
          width: BakerySquarePalette.squareBorderWidth,
        ),
      _ => BakerySquarePalette.squareBorder(context),
    };
    final titleColor = BakerySquarePalette.title(context);
    final infoColor = BakerySquarePalette.subtitle(context);
    const titleSize = 17.0;
    const iconSize = 30.0;

    final tile = BakerySquarePalette.shell(
      context: context,
      borderRadius: 20,
      border: border,
      color: fillColor,
      boxShadow: comingSoon
          ? null
          : [
              BoxShadow(
                color: BakerySquarePalette.shadow(context),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!comingSoon)
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: title,
                  child: InkWell(
                    onTap: onTap,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final inset = showInfoButton ? 28.0 : 12.0;
                final innerW = (constraints.maxWidth - inset * 2).clamp(48.0, double.infinity);
                final innerH = (constraints.maxHeight - inset * 2).clamp(48.0, double.infinity);
                final resolvedIcon = icon ??
                    (highlighted ? Icons.admin_panel_settings_outlined : Icons.touch_app_outlined);
                final resolvedIconSize = innerH < 88 ? 24.0 : iconSize;
                final resolvedTitleSize = innerH < 88 ? 14.0 : titleSize;

                return IgnorePointer(
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.all(inset),
                      child: SizedBox(
                        width: innerW,
                        height: innerH,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(resolvedIcon, size: resolvedIconSize, color: titleColor),
                            SizedBox(height: innerH < 88 ? 6 : 10),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: innerW),
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.style(
                                    fontSize: resolvedTitleSize,
                                    height: 1.15,
                                    color: titleColor,
                                    fontWeight: AppFonts.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (showInfoButton && subtitle.trim().isNotEmpty)
              Positioned.directional(
                textDirection: textDirection,
                top: 6,
                end: 6,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showInfo(context),
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: titleColor.withValues(alpha: 0.12),
                        border: Border.all(color: infoColor.withValues(alpha: 0.35)),
                      ),
                      child: Icon(Icons.info_outline_rounded, size: 20, color: infoColor),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!comingSoon) return tile;

    return Opacity(
      opacity: 0.42,
      child: IgnorePointer(child: tile),
    );
  }
}

class ManagerSubPage extends StatelessWidget {
  const ManagerSubPage({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
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
      ),
      body: body,
    );
  }
}

class _Mp extends StatelessWidget {
  const _Mp({required this.child, this.padding = const EdgeInsets.all(18)});

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
            : const [BoxShadow(color: Color(0x38000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class _MpButton extends StatelessWidget {
  const _MpButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: scheme.onPrimary),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openManagerReviewReplySheet(BuildContext context, int index, CustomerReview review) async {
  final strings = _s;
  final hebrew = AppLocale.instance.isHebrew;
  final controller = TextEditingController(text: review.managerReply(hebrew));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (sheetContext) {
      final bottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BakerySheetCloseBar(title: strings.managerReplyToReview),
            Text(
              review.name(hebrew),
              textAlign: TextAlign.center,
              style: BakeryTheme.subtitleText(sheetContext, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _Mp(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 18,
                        color: review.isPoorReview ? const Color(0xFFC62828) : BakeryTheme.accent(sheetContext),
                      ),
                    ),
                  ),
                  if (review.comment(hebrew).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(review.comment(hebrew), style: BakeryTheme.subtitleText(sheetContext, fontSize: 14, height: 1.35)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 4,
              textAlign: TextAlign.start,
              decoration: bakeryInputDecoration(sheetContext, label: strings.managerReplyHint, icon: Icons.reply_rounded),
            ),
            const SizedBox(height: 16),
            _MpButton(
              icon: Icons.send_rounded,
              label: strings.save,
              onPressed: () async {
                final recovered = await ReviewsStore.instance.setManagerReply(index, controller.text);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        recovered ? strings.managerReplyStatsRecovered : strings.managerReplySaved,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    },
  );
  controller.dispose();
}

class _ManagerReviewCard extends StatelessWidget {
  const _ManagerReviewCard({
    required this.index,
    required this.review,
    required this.hebrew,
  });

  final int index;
  final CustomerReview review;
  final bool hebrew;

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    final isPoor = review.isPoorReview;
    final reply = review.managerReply(hebrew);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openManagerReviewReplySheet(context, index, review),
        child: Container(
          decoration: isPoor
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFC62828), width: 2.5),
                )
              : null,
          child: _Mp(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(review.name(hebrew), style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
                    ),
                    if (isPoor)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC62828), width: 1),
                        ),
                        child: Text(
                          strings.managerPoorReview,
                          style: const TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: isPoor ? const Color(0xFFC62828) : BakeryTheme.accent(context),
                    ),
                  ),
                ),
                if (review.comment(hebrew).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(review.comment(hebrew), style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.35)),
                ],
                const SizedBox(height: 8),
                if (reply.isNotEmpty) ...[
                  Text(strings.managerBakeryReply, style: BakeryTheme.text(context, fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(reply, style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.3)),
                  if (isPoor) ...[
                    const SizedBox(height: 6),
                    Text(
                      strings.managerPoorReviewRecovered,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF43A047)),
                    ),
                  ],
                ] else
                  Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16, color: BakeryTheme.muted(context)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          strings.managerTapReviewToReply,
                          style: BakeryTheme.subtitleText(context, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManagerCustomersPage extends StatefulWidget {
  const ManagerCustomersPage({super.key, this.initialReviewIndex});

  final int? initialReviewIndex;

  @override
  State<ManagerCustomersPage> createState() => _ManagerCustomersPageState();
}

class _ManagerCustomersPageState extends State<ManagerCustomersPage> {
  bool _openedInitialReview = false;
  late final TextEditingController _messageCtrl;
  String _imagePath = '';
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    final hebrew = AppLocale.instance.isHebrew;
    _messageCtrl = TextEditingController(text: ManagerStore.instance.announcement(hebrew));
    _imagePath = ManagerStore.instance.announcementImagePath;
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAnnouncementImage() async {
    if (_publishing) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 88);
    if (!mounted || picked == null) return;
    final saved = await CatalogImageStorage.saveFromPicker(picked.path);
    if (!mounted) return;
    setState(() => _imagePath = saved);
  }

  Future<void> _publishAnnouncement() async {
    if (_publishing) return;
    final text = _messageCtrl.text.trim();
    if (text.isEmpty && _imagePath.isEmpty) return;
    setState(() => _publishing = true);
    try {
      await ManagerStore.instance.setAnnouncementFromText(text, imagePath: _imagePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.managerUpdatePublished)));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _openInitialReviewIfNeeded(List<CustomerReview> reviews) {
    if (_openedInitialReview || widget.initialReviewIndex == null) return;
    final index = widget.initialReviewIndex!;
    if (index < 0 || index >= reviews.length) return;
    _openedInitialReview = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      openManagerReviewReplySheet(context, index, reviews[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    final hebrew = AppLocale.instance.isHebrew;
    return ManagerSubPage(
      body: ListenableBuilder(
        listenable: Listenable.merge([ReviewsStore.instance, ManagerStore.instance]),
        builder: (context, _) {
          final reviews = ReviewsStore.instance.reviews;
          _openInitialReviewIfNeeded(reviews);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _Mp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.managerActionUpdate,
                      style: BakeryTheme.text(context, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(strings.managerActionUpdateSub, style: BakeryTheme.subtitleText(context, fontSize: 13)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      enabled: !_publishing,
                      decoration: bakeryInputDecoration(
                        context,
                        label: strings.managerUpdateMessage,
                        icon: Icons.campaign_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.managerUpdateImage,
                      style: BakeryTheme.text(context, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (_imagePath.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CatalogItemImage(
                          path: _imagePath,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          emoji: '📣',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _publishing ? null : _pickAnnouncementImage,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(strings.managerUpdatePickImage),
                          ),
                        ),
                        if (_imagePath.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _publishing ? null : () => setState(() => _imagePath = ''),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: strings.managerUpdateRemoveImage,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: _publishing ? 0.55 : 1,
                      child: _MpButton(
                        icon: Icons.publish_rounded,
                        label: _publishing ? strings.managerItemSaving : strings.managerPublishUpdate,
                        onPressed: _publishing ? () {} : _publishAnnouncement,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _publishing
                          ? null
                          : () async {
                              await ManagerStore.instance.clearAnnouncement();
                              if (!mounted) return;
                              setState(() {
                                _messageCtrl.clear();
                                _imagePath = '';
                              });
                            },
                      child: Text(strings.managerClearUpdate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.managerActionCustomers,
                style: BakeryTheme.text(context, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(strings.managerReviewsSectionHint, style: BakeryTheme.subtitleText(context, fontSize: 13)),
              const SizedBox(height: 12),
              if (reviews.isEmpty)
                _Mp(child: Text(strings.managerNoReviews, style: BakeryTheme.subtitleText(context)))
              else
                ...reviews.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ManagerReviewCard(
                      index: entry.key,
                      review: entry.value,
                      hebrew: hebrew,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ManagerNewDealPage extends StatefulWidget {
  const ManagerNewDealPage({super.key});

  @override
  State<ManagerNewDealPage> createState() => _ManagerNewDealPageState();
}

class _ManagerNewDealPageState extends State<ManagerNewDealPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final AudioPlayer _celebrationPlayer = AudioPlayer();

  final List<String> _selectedIds = [];
  int _confettiToken = 0;
  int _validityDays = 7;

  static const _validityDayOptions = [1, 3, 7, 14, 30];
  static const _maxProductsInDeal = 6;

  bool get _canPublish => _selectedIds.isNotEmpty && _price.text.trim().isNotEmpty;

  void _removeProduct(String id) => setState(() => _selectedIds.remove(id));

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _celebrationPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    if (_selectedIds.length >= _maxProductsInDeal) return;
    final catalog = CatalogStore.instance;
    final items = catalog.allItems;
    final takenIds = _selectedIds.toSet();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final id = item['id']!;
                final disabled = takenIds.contains(id);
                return ListTile(
                  enabled: !disabled,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      item['image']!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(item['emoji'] ?? '🥖', style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  title: Text(CatalogData.name(item), style: BakeryTheme.text(context, fontWeight: FontWeight.w700)),
                  subtitle: Text(item['price'] ?? '', style: BakeryTheme.subtitleText(context, fontSize: 13)),
                  onTap: disabled ? null : () => Navigator.pop(sheetContext, id),
                );
              },
            );
          },
        );
      },
    );
    if (picked == null || takenIds.contains(picked)) return;
    setState(() => _selectedIds.add(picked));
  }

  Future<void> _publishDeal() async {
    if (!_canPublish) return;
    final strings = _s;
    final catalog = CatalogStore.instance;
    final products = _selectedIds.map((id) => catalog.findById(id)!).toList();

    final titleRaw = _title.text.trim();
    final autoTitleHe = products.map((p) => p['nameHe']).join(' + ');
    final autoTitleEn = products.map((p) => p['nameEn']).join(' + ');
    final titleHe = titleRaw.isNotEmpty ? titleRaw : autoTitleHe;
    final titleEn = titleRaw.isNotEmpty ? titleRaw : autoTitleEn;
    final descRaw = _desc.text.trim();
    final priceText = _price.text.trim().contains('₪') ? _price.text.trim() : '${_price.text.trim()}₪';
    final expiresAt = DateTime.now().add(Duration(days: _validityDays));

    await ManagerStore.instance.addDeal(
      titleHe: titleHe,
      titleEn: titleEn,
      descHe: descRaw,
      descEn: descRaw,
      expiresAtMs: expiresAt.millisecondsSinceEpoch,
      priceAfterDiscount: priceText,
      images: products.map((p) => p['image']!).toList(),
      items: [
        for (final p in products)
          {'id': p['id'], 'quantity': '1', 'price': p['price']},
      ],
      notifyCustomers: true,
    );

    if (!mounted) return;
    await playBakeryCelebrationSound(_celebrationPlayer);
    setState(() => _confettiToken++);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.managerDealPublished)));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context);
  }

  Widget _dealSectionTitle(BuildContext context, String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.3)),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _productThumb(BuildContext context, Map<String, String> item, {double size = 56}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CatalogItemImage(
        path: item['image']!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        emoji: item['emoji'] ?? '🥖',
      ),
    );
  }

  Widget _selectedProductTile(BuildContext context, String productId) {
    final item = CatalogStore.instance.findById(productId)!;
    return SizedBox(
      width: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            decoration: BoxDecoration(
              color: BakeryTheme.cardSurface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BakeryTheme.border(context)),
            ),
            child: Column(
              children: [
                _productThumb(context, item),
                const SizedBox(height: 6),
                Text(
                  CatalogData.name(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: BakeryTheme.text(context, fontSize: 12, fontWeight: FontWeight.w700, height: 1.2),
                ),
              ],
            ),
          ),
          Positioned.directional(
            top: -6,
            start: -6,
            textDirection: Directionality.of(context),
            child: Material(
              color: BakeryTheme.cardSurface(context),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _removeProduct(productId),
                child: Icon(Icons.close_rounded, size: 18, color: BakeryTheme.muted(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addProductTile(BuildContext context) {
    final strings = _s;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickProduct,
        child: Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BakeryTheme.border(context), width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 28, color: BakeryTheme.accent(context)),
              const SizedBox(height: 4),
              Text(
                strings.managerDealAddProduct,
                textAlign: TextAlign.center,
                style: BakeryTheme.subtitleText(context, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _validityChip(BuildContext context, int days) {
    final strings = _s;
    final selected = _validityDays == days;
    final accent = BakeryTheme.accent(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _validityDays = days),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.14) : BakeryTheme.cardSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? accent : BakeryTheme.border(context),
                width: selected ? 1.6 : 1.2,
              ),
            ),
            child: Text(
              strings.managerDealValidityDays(days),
              textAlign: TextAlign.center,
              style: BakeryTheme.text(
                context,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    return ManagerSubPage(
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _Mp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _dealSectionTitle(context, strings.managerDealProducts),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final id in _selectedIds) ...[
                            _selectedProductTile(context, id),
                            const SizedBox(width: 10),
                          ],
                          if (_selectedIds.length < _maxProductsInDeal) _addProductTile(context),
                        ],
                      ),
                    ),
                    if (_selectedIds.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        strings.managerDealPickProductsHint,
                        style: BakeryTheme.subtitleText(context, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Mp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: bakeryInputDecoration(
                        context,
                        label: strings.managerDealPrice,
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _dealSectionTitle(context, strings.managerDealValidity),
                    Row(
                      children: [
                        for (var i = 0; i < _validityDayOptions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          _validityChip(context, _validityDayOptions[i]),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Mp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _dealSectionTitle(
                      context,
                      strings.managerDealOptionalSection,
                      subtitle: strings.managerDealOptionalSectionSub,
                    ),
                    TextField(
                      controller: _title,
                      decoration: bakeryInputDecoration(
                        context,
                        label: strings.managerDealTitle,
                        icon: Icons.title_rounded,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _desc,
                      maxLines: 2,
                      decoration: bakeryInputDecoration(
                        context,
                        label: strings.managerDealDesc,
                        icon: Icons.notes_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _canPublish ? 1 : 0.45,
                child: _MpButton(
                  icon: Icons.celebration_outlined,
                  label: strings.managerPublishDeal,
                  onPressed: _canPublish ? _publishDeal : () {},
                ),
              ),
            ],
          ),
          if (_confettiToken > 0)
            IgnorePointer(
              child: BakeryShapeConfetti(
                key: ValueKey(_confettiToken),
                onFinished: () {},
              ),
            ),
        ],
      ),
    );
  }
}

class _ManagerAddItemForm extends StatefulWidget {
  const _ManagerAddItemForm({
    super.key,
    required this.isDrink,
    required this.onDone,
  });

  final bool isDrink;
  final VoidCallback onDone;

  @override
  State<_ManagerAddItemForm> createState() => _ManagerAddItemFormState();
}

class _ManagerAddItemFormState extends State<_ManagerAddItemForm> {
  final _name = TextEditingController();
  final _subtitle = TextEditingController();
  final _price = TextEditingController();
  final _celebrationPlayer = AudioPlayer();
  String _pickedImage = '';
  bool _saving = false;
  int _confettiToken = 0;

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _price.text.trim().isNotEmpty && _pickedImage.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    _price.dispose();
    _celebrationPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromDevice() async {
    if (_saving) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1400, imageQuality: 88);
    if (!mounted || picked == null) return;
    final saved = await CatalogImageStorage.saveFromPicker(picked.path);
    if (!mounted) return;
    setState(() => _pickedImage = saved);
  }

  Future<void> _saveItem() async {
    if (!_canSave || _saving) return;

    final nameText = _name.text.trim();
    final subText = _subtitle.text.trim();
    final priceText = _price.text.trim();
    final imagePath = _pickedImage;
    final isDrink = widget.isDrink;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);

    try {
      final nameB = await LocaleTranslate.toBilingual(nameText);
      final subB = subText.isEmpty ? (he: '', en: '') : await LocaleTranslate.toBilingual(subText);

      if (isDrink) {
        await CatalogStore.instance.addDrink(
          nameHe: nameB.he,
          nameEn: nameB.en,
          subtitleHe: subB.he,
          subtitleEn: subB.en,
          price: priceText,
          image: imagePath,
        );
      } else {
        await CatalogStore.instance.addProduct(
          nameHe: nameB.he,
          nameEn: nameB.en,
          subtitleHe: subB.he,
          subtitleEn: subB.en,
          price: priceText,
          image: imagePath,
        );
      }

      if (!mounted) return;
      await playBakeryCelebrationSound(_celebrationPlayer);
      setState(() {
        _saving = false;
        _confettiToken++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      widget.onDone();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _uniformField({required Widget child}) {
    return SizedBox(height: _managerFormFieldHeight, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    const fieldPad = EdgeInsets.symmetric(horizontal: 12, vertical: 16);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _Mp(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _uniformField(
                child: TextField(
                  controller: _name,
              enabled: !_saving,
              onChanged: (_) => setState(() {}),
              decoration: bakeryInputDecoration(
                context,
                label: strings.managerItemName,
                icon: widget.isDrink ? Icons.local_cafe_outlined : Icons.bakery_dining,
                required: true,
              ).copyWith(
                contentPadding: fieldPad,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _uniformField(
            child: TextField(
              controller: _subtitle,
              enabled: !_saving,
              decoration: bakeryInputDecoration(
                context,
                label: strings.managerItemSubtitle,
                icon: Icons.notes,
              ).copyWith(
                contentPadding: fieldPad,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _uniformField(
            child: TextField(
              controller: _price,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: bakeryInputDecoration(
                context,
                label: strings.managerItemPrice,
                icon: Icons.payments,
                required: true,
              ).copyWith(
                contentPadding: fieldPad,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _uniformField(
            child: InkWell(
              onTap: _saving ? null : _pickImageFromDevice,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                isFocused: false,
                decoration: bakeryInputDecoration(
                  context,
                  label: strings.managerPickImage,
                  icon: Icons.image_outlined,
                  required: true,
                ),
                child: Row(
                  children: [
                    if (_pickedImage.isNotEmpty)
                      CatalogItemImage(
                        path: _pickedImage,
                        width: 36,
                        height: 36,
                        borderRadius: BorderRadius.circular(8),
                        emoji: widget.isDrink ? '☕' : '🥖',
                      ),
                    if (_pickedImage.isNotEmpty) const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickedImage.isEmpty ? strings.managerTapToUploadImage : p.basename(_pickedImage),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BakeryTheme.text(context, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.upload_rounded, color: BakeryTheme.accent(context), size: 22),
                  ],
                ),
              ),
            ),
          ),
          if (!_canSave) ...[
            const SizedBox(height: 8),
            Text(
              strings.managerItemRequiredHint,
              style: BakeryTheme.subtitleText(context, fontSize: 12).copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
              Opacity(
                opacity: _canSave && !_saving ? 1 : 0.45,
                child: _MpButton(
                  icon: Icons.save,
                  label: _saving ? strings.managerItemSaving : strings.save,
                  onPressed: _canSave && !_saving ? _saveItem : () {},
                ),
              ),
            ],
          ),
        ),
        if (_confettiToken > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: BakeryShapeConfetti(
                key: ValueKey(_confettiToken),
                onFinished: () {},
              ),
            ),
          ),
      ],
    );
  }
}

class ManagerOrderRestrictionsPage extends StatefulWidget {
  const ManagerOrderRestrictionsPage({super.key});

  @override
  State<ManagerOrderRestrictionsPage> createState() => _ManagerOrderRestrictionsPageState();
}

class _ManagerOrderRestrictionsPageState extends State<ManagerOrderRestrictionsPage> {
  late final TextEditingController _maxOrdersCtrl;

  @override
  void initState() {
    super.initState();
    _maxOrdersCtrl = TextEditingController(
      text: '${OrderRestrictionsStore.instance.maxOrders}',
    );
  }

  @override
  void dispose() {
    _maxOrdersCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCutoffTime(BuildContext context) async {
    final store = OrderRestrictionsStore.instance;
    final picked = await showTimePicker(
      context: context,
      initialTime: store.cutoffTime,
    );
    if (picked == null) return;
    await store.setCutoffTime(picked);
  }

  void _syncMaxOrdersField() {
    _maxOrdersCtrl.text = '${OrderRestrictionsStore.instance.maxOrders}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    return ManagerSubPage(
      body: ListenableBuilder(
        listenable: Listenable.merge([OrderRestrictionsStore.instance, BusinessStore.instance]),
        builder: (context, _) {
          final store = OrderRestrictionsStore.instance;
          final currentCount = store.currentOrderCount();
          final periodLabel = store.maxOrdersPeriod == OrderLimitPeriod.day
              ? strings.orderLimitPeriodDay
              : strings.orderLimitPeriodWeek;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _Mp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.managerOrderCutoffSection,
                      style: BakeryTheme.text(context, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(strings.managerOrderCutoffHint, style: BakeryTheme.subtitleText(context, fontSize: 13)),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.managerOrderCutoffSection, style: BakeryTheme.text(context)),
                      value: store.cutoffEnabled,
                      onChanged: (v) => store.setCutoffEnabled(v),
                    ),
                    if (store.cutoffEnabled) ...[
                      const SizedBox(height: 4),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(store.cutoffTimeLabel(strings), style: BakeryTheme.text(context, fontSize: 22)),
                        trailing: const Icon(Icons.schedule_rounded),
                        onTap: () => _pickCutoffTime(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Mp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.managerOrderMaxSection,
                      style: BakeryTheme.text(context, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(strings.managerOrderMaxHint, style: BakeryTheme.subtitleText(context, fontSize: 13)),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.managerOrderMaxSection, style: BakeryTheme.text(context)),
                      value: store.maxOrdersEnabled,
                      onChanged: (v) => store.setMaxOrdersEnabled(v),
                    ),
                    if (store.maxOrdersEnabled) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _maxOrdersCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: strings.managerOrderMaxCount,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (v) {
                          final n = int.tryParse(v.trim());
                          if (n != null) store.setMaxOrders(n);
                          _syncMaxOrdersField();
                        },
                        onEditingComplete: () {
                          final n = int.tryParse(_maxOrdersCtrl.text.trim());
                          if (n != null) store.setMaxOrders(n);
                          _syncMaxOrdersField();
                        },
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<OrderLimitPeriod>(
                        segments: [
                          ButtonSegment(
                            value: OrderLimitPeriod.day,
                            label: Text(strings.orderLimitPeriodDay),
                          ),
                          ButtonSegment(
                            value: OrderLimitPeriod.week,
                            label: Text(strings.orderLimitPeriodWeek),
                          ),
                        ],
                        selected: {store.maxOrdersPeriod},
                        onSelectionChanged: (s) {
                          if (s.isEmpty) return;
                          store.setMaxOrdersPeriod(s.first);
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.managerOrderCurrentCount(currentCount),
                        style: BakeryTheme.subtitleText(context),
                      ),
                      Text(
                        '${strings.managerOrderMaxCount}: ${store.maxOrders} · $periodLabel',
                        style: BakeryTheme.subtitleText(context, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ManagerStorePage extends StatefulWidget {
  const ManagerStorePage({super.key});

  @override
  State<ManagerStorePage> createState() => _ManagerStorePageState();
}

class _ManagerStorePageState extends State<ManagerStorePage> {
  bool _addingProduct = false;
  bool _addingDrink = false;
  int _formSession = 0;

  void _openProductForm() => setState(() {
        _formSession++;
        _addingProduct = true;
        _addingDrink = false;
      });

  void _openDrinkForm() => setState(() {
        _formSession++;
        _addingProduct = false;
        _addingDrink = true;
      });

  void _closeForm() => setState(() {
        _addingProduct = false;
        _addingDrink = false;
      });

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    final hebrew = AppLocale.instance.isHebrew;
    return ManagerSubPage(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: _MpButton(
                  icon: Icons.add,
                  label: strings.managerAddProduct,
                  onPressed: _openProductForm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MpButton(
                  icon: Icons.local_cafe_outlined,
                  label: strings.managerAddDrink,
                  onPressed: _openDrinkForm,
                ),
              ),
            ],
          ),
          if (_addingProduct || _addingDrink) ...[
            const SizedBox(height: 12),
            _ManagerAddItemForm(
              key: ValueKey('add_${_formSession}_${_addingDrink ? 'd' : 'p'}'),
              isDrink: _addingDrink,
              onDone: _closeForm,
            ),
          ],
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: Listenable.merge([CatalogStore.instance, ManagerStore.instance]),
            builder: (context, _) {
              final catalog = CatalogStore.instance;
              final mgr = ManagerStore.instance;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(strings.managerCatalogProducts, style: BakeryTheme.text(context, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...catalog.products.map((item) => _catalogItemTile(context, item, isDrink: false, hebrew: hebrew)),
                  const SizedBox(height: 12),
                  Text(strings.managerCatalogDrinks, style: BakeryTheme.text(context, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...catalog.drinks.map((item) => _catalogItemTile(context, item, isDrink: true, hebrew: hebrew)),
                  const SizedBox(height: 16),
                  Text(strings.managerActiveDeals, style: BakeryTheme.text(context, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (mgr.activeCustomDeals.isEmpty)
                    Text(strings.managerNoAnnouncement, style: BakeryTheme.subtitleText(context))
                  else
                    ...mgr.activeCustomDeals.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _Mp(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(child: Text(CatalogData.dealField(d, 'title'), style: BakeryTheme.text(context))),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => ManagerStore.instance.removeDeal(d['id'] as String),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _Mp(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: SaasStoreModeSection(
              squareTiles: true,
              onBusinessChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catalogItemTile(BuildContext context, Map<String, String> item, {required bool isDrink, required bool hebrew}) {
    final canEdit = item['id']!.startsWith('custom_');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Mp(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CatalogItemImage(
              path: item['image']!,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(10),
              emoji: item['emoji'] ?? '🥖',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(CatalogData.name(item), style: BakeryTheme.text(context, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(CatalogData.subtitle(item), style: BakeryTheme.subtitleText(context, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(item['price']!, style: BakeryTheme.subtitleText(context, fontSize: 12)),
                ],
              ),
            ),
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => CatalogStore.instance.removeItem(item['id']!, isDrink: isDrink),
              ),
          ],
        ),
      ),
    );
  }
}

class ManagerStatsPage extends StatefulWidget {
  const ManagerStatsPage({super.key});

  @override
  State<ManagerStatsPage> createState() => _ManagerStatsPageState();
}

enum _ManagerStatsView { revenue, satisfaction }

class _ManagerStatsPageState extends State<ManagerStatsPage> {
  RevenuePeriod _period = RevenuePeriod.week;
  _ManagerStatsView _view = _ManagerStatsView.revenue;

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    final he = AppLocale.instance.isHebrew;
    final accent = BakeryTheme.accent(context);

    return ManagerSubPage(
      body: ListenableBuilder(
        listenable: Listenable.merge([BusinessStore.instance, ReviewsStore.instance]),
        builder: (context, _) {
          final orders = BusinessStore.instance.recentOrders;
          final reviews = ReviewsStore.instance.reviews;
          final revenueBuckets = buildRevenueBuckets(orders: orders, period: _period, hebrew: he);
          final orderBuckets = buildOrderCountBuckets(orders: orders, period: _period, hebrew: he);
          final revenueTotal = sumBuckets(revenueBuckets);
          final ordersTotal = sumBuckets(orderBuckets).round();
          final trend = revenueTrendPercent(orders, _period);
          final trendUp = trend > 4;
          final trendDown = trend < -4;
          final trendLabel = trendUp
              ? strings.managerStatsGrowing
              : trendDown
                  ? strings.managerStatsDeclining
                  : strings.managerStatsStable;
          final ratingBuckets = ReviewsStore.instance.ratingDistribution();
          final avgRating = ReviewsStore.instance.averageRating;
          final happyPct = ReviewsStore.instance.happyPercent();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              SegmentedButton<_ManagerStatsView>(
                segments: [
                  ButtonSegment(value: _ManagerStatsView.revenue, label: Text(strings.managerStatsRevenue)),
                  ButtonSegment(value: _ManagerStatsView.satisfaction, label: Text(strings.managerStatsSatisfaction)),
                ],
                selected: {_view},
                onSelectionChanged: (v) => setState(() => _view = v.first),
              ),
              const SizedBox(height: 14),
              SegmentedButton<RevenuePeriod>(
                segments: [
                  ButtonSegment(value: RevenuePeriod.week, label: Text(strings.managerStatsWeekly)),
                  ButtonSegment(value: RevenuePeriod.month, label: Text(strings.managerStatsMonthly)),
                  ButtonSegment(value: RevenuePeriod.year, label: Text(strings.managerStatsYearly)),
                ],
                selected: {_period},
                onSelectionChanged: (v) => setState(() => _period = v.first),
              ),
              const SizedBox(height: 16),
              if (_view == _ManagerStatsView.revenue) ...[
                _Mp(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(strings.managerStatsRevenue, style: BakeryTheme.subtitleText(context, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '₪${revenueTotal.round()}',
                        style: BakeryTheme.text(context, fontSize: 34, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            trendUp ? Icons.north_east_rounded : (trendDown ? Icons.south_east_rounded : Icons.trending_flat_rounded),
                            color: trendUp
                                ? const Color(0xFF43A047)
                                : (trendDown ? const Color(0xFFE53935) : BakeryTheme.muted(context)),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$trendLabel (${trend >= 0 ? '+' : ''}${trend.round()}%)',
                              style: BakeryTheme.text(context, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Mp(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  child: ManagerRevenueChart(buckets: revenueBuckets, accentColor: accent),
                ),
              ] else ...[
                _Mp(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(strings.managerStatsAvgRating, style: BakeryTheme.subtitleText(context, fontSize: 13)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      reviews.isEmpty ? '—' : avgRating.toStringAsFixed(1),
                                      style: BakeryTheme.text(context, fontSize: 28, fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.star_rounded, color: BakeryTheme.accent(context), size: 26),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(strings.managerStatsReviewsCount, style: BakeryTheme.subtitleText(context, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  '${reviews.length}',
                                  style: BakeryTheme.text(context, fontSize: 28, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(strings.managerStatsHappyRate, style: BakeryTheme.subtitleText(context, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        reviews.isEmpty ? '—' : '$happyPct%',
                        style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Text(strings.managerStatsOrdersInPeriod, style: BakeryTheme.subtitleText(context, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '$ordersTotal',
                        style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(strings.managerStatsRatingBreakdown, style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                _Mp(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  child: reviews.isEmpty
                      ? Text(strings.managerStatsNoReviewsYet, style: BakeryTheme.subtitleText(context, fontSize: 14))
                      : ManagerRevenueChart(buckets: ratingBuckets, accentColor: accent),
                ),
                const SizedBox(height: 16),
                Text(strings.managerStatsOrdersInPeriod, style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                _Mp(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  child: ManagerRevenueChart(buckets: orderBuckets, accentColor: BakeryTheme.accent(context)),
                ),
                if (reviews.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(strings.managerStatsRecentReviews, style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...reviews.take(5).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _Mp(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(r.name(he), style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 16,
                                      color: r.isPoorReview ? const Color(0xFFC62828) : BakeryTheme.accent(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (r.comment(he).trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(r.comment(he), style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.35)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class ManagerFaqPage extends StatefulWidget {
  const ManagerFaqPage({super.key});

  @override
  State<ManagerFaqPage> createState() => _ManagerFaqPageState();
}

class _ManagerFaqPageState extends State<ManagerFaqPage> {
  Future<void> _openEditor({int? index, FaqItem? existing}) async {
    final strings = _s;
    final qHeCtrl = TextEditingController(text: existing?.qHe ?? '');
    final aHeCtrl = TextEditingController(text: existing?.aHe ?? '');
    final qEnCtrl = TextEditingController(text: existing?.qEn ?? '');
    final aEnCtrl = TextEditingController(text: existing?.aEn ?? '');
    var saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        final bottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> save() async {
                if (saving) return;
                final item = FaqItem(
                  qHe: qHeCtrl.text.trim(),
                  aHe: aHeCtrl.text.trim(),
                  qEn: qEnCtrl.text.trim(),
                  aEn: aEnCtrl.text.trim(),
                );
                if (item.qHe.isEmpty ||
                    item.aHe.isEmpty ||
                    item.qEn.isEmpty ||
                    item.aEn.isEmpty) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text(strings.managerFaqRequired)),
                  );
                  return;
                }
                setSheetState(() => saving = true);
                await FaqStore.instance.upsertAt(index, item);
                if (sheetContext.mounted) Navigator.pop(sheetContext, true);
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      index == null ? strings.managerFaqAdd : strings.managerFaqEdit,
                      textAlign: TextAlign.center,
                      style: BakeryTheme.text(sheetContext, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: qHeCtrl,
                      enabled: !saving,
                      decoration: bakeryInputDecoration(sheetContext, label: strings.managerFaqQuestionHe, icon: Icons.quiz_outlined),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: aHeCtrl,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: bakeryInputDecoration(sheetContext, label: strings.managerFaqAnswerHe, icon: Icons.chat_bubble_outline),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: qEnCtrl,
                      enabled: !saving,
                      decoration: bakeryInputDecoration(sheetContext, label: strings.managerFaqQuestionEn, icon: Icons.quiz_outlined),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: aEnCtrl,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: bakeryInputDecoration(sheetContext, label: strings.managerFaqAnswerEn, icon: Icons.chat_bubble_outline),
                    ),
                    const SizedBox(height: 18),
                    _MpButton(
                      icon: Icons.save_outlined,
                      label: strings.confirm,
                      onPressed: saving ? () {} : save,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    qHeCtrl.dispose();
    aHeCtrl.dispose();
    qEnCtrl.dispose();
    aEnCtrl.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.managerFaqSaved)));
    }
  }

  Future<void> _confirmDelete(int index) async {
    final strings = _s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.managerFaqDelete, textAlign: TextAlign.center),
        content: Text(strings.managerFaqDeleteConfirm, textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.close)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.managerFaqDelete, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FaqStore.instance.removeAt(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.managerFaqSaved)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    final hebrew = AppLocale.instance.isHebrew;

    return ManagerSubPage(
      body: ListenableBuilder(
        listenable: FaqStore.instance,
        builder: (context, _) {
          final items = FaqStore.instance.items;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (items.isEmpty)
                _Mp(child: Text(strings.managerFaqEmpty, style: BakeryTheme.subtitleText(context)))
              else
                ...items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _Mp(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  item.question(hebrew),
                                  style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.answer(hebrew),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openEditor(index: i, existing: item),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                            onPressed: () => _confirmDelete(i),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              _MpButton(icon: Icons.add_circle_outline, label: strings.managerFaqAdd, onPressed: () => _openEditor()),
            ],
          );
        },
      ),
    );
  }
}

class ManagerStoreTermsPage extends StatefulWidget {
  const ManagerStoreTermsPage({super.key});

  @override
  State<ManagerStoreTermsPage> createState() => _ManagerStoreTermsPageState();
}

class _ManagerStoreTermsPageState extends State<ManagerStoreTermsPage> {
  final _controller = TextEditingController();
  var _saving = false;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _reload();
    ManagerStore.instance.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    StoreTermsStore.instance.clearIfSlugChanged(ManagerStore.instance.linkedBusinessSlug);
    _reload();
  }

  Future<void> _reload() async {
    await StoreTermsStore.instance.loadForCurrentStore();
    if (!mounted) return;
    _controller.text = StoreTermsStore.instance.terms;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    ManagerStore.instance.removeListener(_onStoreChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final strings = _s;
    if (_saving) return;
    final slug = ManagerStore.instance.linkedBusinessSlug?.trim();
    if (slug == null || slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.managerStoreTermsNoStore)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await StoreTermsStore.instance.save(_controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.managerStoreTermsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    final hasStore = ManagerStore.instance.linkedBusinessSlug?.trim().isNotEmpty == true;

    return ManagerSubPage(
      body: ListenableBuilder(
        listenable: Listenable.merge([StoreTermsStore.instance, ManagerStore.instance]),
        builder: (context, _) {
          if (!_loaded) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _Mp(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel_outlined, color: BakeryTheme.accent(context), size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            strings.managerStoreTermsTitle,
                            style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.managerStoreTermsHint,
                      style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!hasStore)
                _Mp(
                  child: Text(
                    strings.managerStoreTermsNoStore,
                    textAlign: TextAlign.center,
                    style: BakeryTheme.subtitleText(context, height: 1.4),
                  ),
                )
              else ...[
                _Mp(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: TextField(
                    controller: _controller,
                    enabled: !_saving,
                    maxLines: 16,
                    minLines: 10,
                    textAlignVertical: TextAlignVertical.top,
                    style: BakeryTheme.text(context, fontSize: 15, height: 1.45),
                    decoration: bakeryInputDecoration(
                      context,
                      label: strings.managerStoreTermsField,
                      icon: Icons.article_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _MpButton(
                  icon: Icons.save_outlined,
                  label: strings.confirm,
                  onPressed: _saving ? () {} : _save,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ManagerSubscriptionsPage extends StatelessWidget {
  const ManagerSubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    return ManagerSubPage(
      body: ListenableBuilder(
        listenable: ManagerSubscriptionStore.instance,
        builder: (context, _) {
          final current = ManagerSubscriptionStore.instance.tier;
          final currentLabel = switch (current) {
            ManagerSubscriptionTier.premium => strings.managerSubscriptionsPremium,
            ManagerSubscriptionTier.ultimate => strings.managerSubscriptionsUltimate,
            _ => strings.managerSubscriptionsNone,
          };

          return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.managerSubscriptionsTitle,
                      textAlign: TextAlign.center,
                      style: BakeryTheme.text(context, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.managerSubscriptionsSub,
                      textAlign: TextAlign.center,
                      style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: BakeryTheme.accent(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: BakeryTheme.border(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_rounded, color: BakeryTheme.accent(context), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            strings.managerSubscriptionsCurrent,
                            style: BakeryTheme.subtitleText(context, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentLabel,
                              textAlign: TextAlign.end,
                              style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _SubscriptionPlanCard(
                              title: strings.managerSubscriptionsPremium,
                              priceUsd: ManagerSubscriptionTier.premiumUsd,
                              featureLines: _subscriptionFeatureLines(strings.managerSubscriptionsPremiumFeatures),
                              isSelected: current == ManagerSubscriptionTier.premium,
                              onSelect: () => _selectPlan(context, ManagerSubscriptionTier.premium),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SubscriptionPlanCard(
                              title: strings.managerSubscriptionsUltimate,
                              priceUsd: ManagerSubscriptionTier.ultimateUsd,
                              featureLines: _subscriptionFeatureLines(strings.managerSubscriptionsUltimateFeatures),
                              isSelected: current == ManagerSubscriptionTier.ultimate,
                              recommended: true,
                              onSelect: () => _selectPlan(context, ManagerSubscriptionTier.ultimate),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.managerSubscriptionsPaymentNote,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BakeryTheme.subtitleText(context, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                ),
              );
        },
      ),
    );
  }

  static List<String> _subscriptionFeatureLines(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim().replaceFirst(RegExp(r'^[•\-]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<void> _selectPlan(BuildContext context, ManagerSubscriptionTier tier) async {
    await ManagerSubscriptionStore.instance.selectTier(tier);
    if (!context.mounted) return;
    final name = tier == ManagerSubscriptionTier.premium
        ? _s.managerSubscriptionsPremium
        : _s.managerSubscriptionsUltimate;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_s.managerSubscriptionsPlanChosen(name))),
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    required this.title,
    required this.priceUsd,
    required this.featureLines,
    required this.isSelected,
    required this.onSelect,
    this.recommended = false,
  });

  final String title;
  final int priceUsd;
  final List<String> featureLines;
  final bool isSelected;
  final VoidCallback onSelect;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    final accent = BakeryTheme.accent(context);
    final borderColor = isSelected ? accent : BakeryTheme.border(context);

    return Material(
      color: BakeryTheme.cardSurface(context),
      elevation: isSelected ? 4 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: isSelected ? 2.2 : 1.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (recommended) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        strings.managerSubscriptionsRecommended,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: accent),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$$priceUsd',
                    style: BakeryTheme.text(context, fontSize: 32, fontWeight: FontWeight.w900, color: accent, height: 1),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    strings.managerSubscriptionsPerMonth,
                    style: BakeryTheme.subtitleText(context, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: featureLines.map((line) {
                    return Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_rounded, color: accent, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                line,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: BakeryTheme.text(
                                  context,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: FilledButton(
                  onPressed: onSelect,
                  style: FilledButton.styleFrom(
                    backgroundColor: isSelected ? Colors.green.shade700 : accent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isSelected ? strings.managerSubscriptionsSelected : strings.managerSubscriptionsSelect,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

void openManagerPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
