import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'core/app_fonts.dart';
import 'core/app_locale.dart';
import 'core/app_theme_mode.dart';
import 'core/bakery_square_palette.dart';
import 'core/business_analytics.dart';
import 'core/business_store.dart';
import 'core/catalog_data.dart';
import 'core/catalog_store.dart';
import 'core/catalog_image_storage.dart';
import 'core/locale_translate.dart';
import 'core/manager_store.dart';
import 'core/reviews_store.dart';
import 'widgets/bakery_celebration.dart';
import 'widgets/catalog_item_image.dart';
import 'widgets/manager_revenue_chart.dart';
import 'saas/widgets/saas_store_mode_section.dart';

AppStrings get _s => AppLocale.instance.s;

const _ownerPhone = '0501234567';
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
    final gradient = highlighted
        ? BakerySquarePalette.managerEntryGradient(context)
        : BakerySquarePalette.gradientAt(context, colorIndex);
    final borderColor = highlighted ? BakerySquarePalette.managerEntryBorder(context) : null;
    final titleColor =
        highlighted ? BakerySquarePalette.managerEntryTitle(context) : BakerySquarePalette.title(context);
    final infoColor = highlighted ? BakerySquarePalette.managerEntryTitle(context) : BakerySquarePalette.subtitle(context);
    const titleSize = 17.0;
    const iconSize = 30.0;

    return Material(
      color: gradient.last,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          border: borderColor != null ? Border.all(color: borderColor, width: 2.5) : null,
          boxShadow: [
            BoxShadow(
              color: highlighted
                  ? borderColor!.withValues(alpha: 0.45)
                  : BakerySquarePalette.shadow(context),
              blurRadius: highlighted ? 14 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Center(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(showInfoButton ? 28 : 14, 14, showInfoButton ? 28 : 14, 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon ??
                            (highlighted ? Icons.admin_panel_settings_outlined : Icons.touch_app_outlined),
                        size: iconSize,
                        color: titleColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          fontSize: titleSize,
                          height: 1.2,
                          color: titleColor,
                          fontWeight: AppFonts.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
  }
}

class ManagerSubPage extends StatelessWidget {
  const ManagerSubPage({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: _s.managerBack,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800)),
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
            Text(
              strings.managerReplyToReview,
              textAlign: TextAlign.center,
              style: BakeryTheme.text(sheetContext, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
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

class ManagerCustomersPage extends StatelessWidget {
  const ManagerCustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    final hebrew = AppLocale.instance.isHebrew;
    return ManagerSubPage(
      title: strings.managerActionCustomers,
      body: ListenableBuilder(
        listenable: Listenable.merge([ManagerStore.instance, ReviewsStore.instance]),
        builder: (context, _) {
          final inquiries = ManagerStore.instance.inquiries;
          final reviews = ReviewsStore.instance.reviews;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(strings.managerActionCustomersSub, style: BakeryTheme.subtitleText(context, fontSize: 14)),
              const SizedBox(height: 16),
              Text(strings.managerInquiriesSection, style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (inquiries.isEmpty)
                _Mp(child: Text(strings.managerNoInquiries, style: BakeryTheme.subtitleText(context)))
              else
                ...inquiries.map(
                  (inq) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _Mp(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(inq.message, style: BakeryTheme.text(context, fontSize: 14, height: 1.4)),
                          const SizedBox(height: 8),
                          _MpButton(
                            icon: Icons.chat,
                            label: strings.managerReplyWhatsApp,
                            onPressed: () async {
                              final uri = Uri.parse(
                                'https://wa.me/972${_ownerPhone.substring(1)}?text=${Uri.encodeComponent(inq.message)}',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(strings.managerReviewsSection, style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
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

class ManagerUpdatePage extends StatefulWidget {
  const ManagerUpdatePage({super.key});

  @override
  State<ManagerUpdatePage> createState() => _ManagerUpdatePageState();
}

class _ManagerUpdatePageState extends State<ManagerUpdatePage> {
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

  Future<void> _pickImage() async {
    if (_publishing) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 88);
    if (!mounted || picked == null) return;
    final saved = await CatalogImageStorage.saveFromPicker(picked.path);
    if (!mounted) return;
    setState(() => _imagePath = saved);
  }

  Future<void> _publish() async {
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

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    return ManagerSubPage(
      title: strings.managerActionUpdate,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(strings.managerActionUpdateSub, style: BakeryTheme.subtitleText(context, fontSize: 14)),
          const SizedBox(height: 16),
          _Mp(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _messageCtrl,
                  maxLines: 4,
                  enabled: !_publishing,
                  decoration: bakeryInputDecoration(context, label: strings.managerUpdateMessage, icon: Icons.campaign_outlined),
                ),
                const SizedBox(height: 14),
                Text(strings.managerUpdateImage, style: BakeryTheme.text(context, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 8),
                if (_imagePath.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CatalogItemImage(path: _imagePath, height: 160, width: double.infinity, fit: BoxFit.cover, emoji: '📣'),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _publishing ? null : _pickImage,
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
                    onPressed: _publishing ? () {} : _publish,
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
        ],
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

  final List<String?> _productIds = [null];
  int _confettiToken = 0;
  int _validityDays = 7;

  static const _validityDayOptions = [1, 3, 7, 14, 30];
  static const _maxProductsInDeal = 6;

  List<String> get _selectedProductIds =>
      _productIds.whereType<String>().toList(growable: false);

  bool get _canPublish {
    final selected = _selectedProductIds;
    if (selected.isEmpty) return false;
    if (selected.length != selected.toSet().length) return false;
    return _price.text.trim().isNotEmpty;
  }

  void _addProductSlot() {
    if (_productIds.length >= _maxProductsInDeal) return;
    setState(() => _productIds.add(null));
  }

  void _removeProductSlot(int index) {
    if (_productIds.length <= 1) return;
    setState(() => _productIds.removeAt(index));
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _celebrationPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickProduct(int slotIndex) async {
    final catalog = CatalogStore.instance;
    final items = catalog.allItems;
    final takenIds = _selectedProductIds
        .where((id) => id != _productIds[slotIndex])
        .toSet();
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
    if (picked == null) return;
    setState(() => _productIds[slotIndex] = picked);
  }

  Future<void> _publishDeal() async {
    if (!_canPublish) return;
    final strings = _s;
    final catalog = CatalogStore.instance;
    final products = _selectedProductIds.map((id) => catalog.findById(id)!).toList();

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

  Widget _productSlot(
    BuildContext context, {
    required int index,
    required String? productId,
    required VoidCallback onTap,
    required bool canRemove,
    required VoidCallback? onRemove,
  }) {
    final strings = _s;
    final item = productId != null ? CatalogStore.instance.findById(productId) : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BakeryTheme.border(context), width: 1.2),
            color: BakeryTheme.cardSurface(context).withValues(alpha: 0.5),
          ),
          child: Row(
            children: [
              if (item != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    item['image']!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: 52,
                      height: 52,
                      child: Center(child: Text(item['emoji'] ?? '🥖', style: const TextStyle(fontSize: 26))),
                    ),
                  ),
                )
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: BakeryTheme.softSurface(context),
                  ),
                  child: Icon(Icons.add, color: BakeryTheme.muted(context)),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.managerDealProductN(index + 1), style: BakeryTheme.subtitleText(context, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      item != null ? CatalogData.name(item) : strings.managerDealTapToPick,
                      style: BakeryTheme.text(context, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (canRemove)
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: BakeryTheme.muted(context)),
                  onPressed: onRemove,
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                ),
              Icon(Icons.chevron_left, color: BakeryTheme.muted(context)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    return ManagerSubPage(
      title: strings.managerActionNewDeal,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                strings.managerActionNewDealSub,
                style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.35),
              ),
              const SizedBox(height: 16),
              _Mp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _title,
                      decoration: bakeryInputDecoration(context, label: strings.managerDealTitle, icon: Icons.title),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _desc,
                      maxLines: 2,
                      decoration: bakeryInputDecoration(context, label: strings.managerDealDesc, icon: Icons.notes),
                    ),
                    const SizedBox(height: 16),
                    Text(strings.managerDealProducts, style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...List.generate(_productIds.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < _productIds.length - 1 ? 8 : 0),
                        child: _productSlot(
                          context,
                          index: index,
                          productId: _productIds[index],
                          onTap: () => _pickProduct(index),
                          canRemove: _productIds.length > 1,
                          onRemove: () => _removeProductSlot(index),
                        ),
                      );
                    }),
                    if (_productIds.length < _maxProductsInDeal) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _addProductSlot,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(strings.managerDealAddProduct),
                      ),
                    ],
                    if (!_canPublish) ...[
                      const SizedBox(height: 8),
                      Text(
                        strings.managerDealPickProductsHint,
                        style: BakeryTheme.subtitleText(context, fontSize: 12, height: 1.3),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: bakeryInputDecoration(context, label: strings.managerDealPrice, icon: Icons.payments),
                    ),
                    const SizedBox(height: 16),
                    Text(strings.managerDealValidity, style: BakeryTheme.text(context, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _validityDayOptions.map((days) {
                        final selected = _validityDays == days;
                        return ChoiceChip(
                          label: Text(strings.managerDealValidityDays(days)),
                          selected: selected,
                          onSelected: (_) => setState(() => _validityDays = days),
                        );
                      }).toList(),
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
  String _pickedImage = '';
  bool _saving = false;

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _price.text.trim().isNotEmpty && _pickedImage.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    _price.dispose();
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

      if (!mounted) return;
      widget.onDone();
      await WidgetsBinding.instance.endOfFrame;

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

    return _Mp(
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
    );
  }
}

class ManagerStoreModePage extends StatelessWidget {
  const ManagerStoreModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = _s;
    return ManagerSubPage(
      title: strings.managerActionStoreMode,
      body: const Padding(
        padding: EdgeInsets.fromLTRB(20, 32, 20, 28),
        child: SaasStoreModeSection(),
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
      title: strings.managerActionStore,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            strings.managerLocalCatalogSection,
            style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
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
      title: strings.managerActionStats,
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
              Text(strings.managerActionStatsSub, style: BakeryTheme.subtitleText(context, fontSize: 14)),
              const SizedBox(height: 14),
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

void openManagerPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
