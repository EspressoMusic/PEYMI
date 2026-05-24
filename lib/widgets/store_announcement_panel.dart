import 'package:flutter/material.dart';

import '../core/app_fonts.dart';
import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/bakery_navigator.dart';
import '../core/bakery_square_palette.dart';
import 'catalog_item_image.dart';

/// Centered cream square popup when the manager publishes a store update.
Future<void> showStoreAnnouncementPopupBanner(
  BuildContext context, {
  required String title,
  required String message,
  String imagePath = '',
  required VoidCallback onDismiss,
}) {
  final host = bakeryOverlayContext ?? context;
  return showOverlaySafely<void>(
    context: host,
    show: (overlayHost) => showGeneralDialog<void>(
      context: overlayHost,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, _, __) {
        return _StoreAnnouncementCenterOverlay(
          animation: animation,
          title: title,
          message: message,
          imagePath: imagePath,
          onDismiss: onDismiss,
        );
      },
    ),
  );
}

class _StoreAnnouncementCenterOverlay extends StatefulWidget {
  const _StoreAnnouncementCenterOverlay({
    required this.animation,
    required this.title,
    required this.message,
    required this.imagePath,
    required this.onDismiss,
  });

  final Animation<double> animation;
  final String title;
  final String message;
  final String imagePath;
  final VoidCallback onDismiss;

  @override
  State<_StoreAnnouncementCenterOverlay> createState() => _StoreAnnouncementCenterOverlayState();
}

class _StoreAnnouncementCenterOverlayState extends State<_StoreAnnouncementCenterOverlay> {
  var _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    popThen(context, () async {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: widget.animation, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: widget.animation, curve: Curves.easeOut);
    final accent = BakeryTheme.accent(context);
    final hasImage = widget.imagePath.trim().isNotEmpty;
    final hasMessage = widget.message.trim().isNotEmpty;
    final strings = AppLocale.instance.s;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _close,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
        Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1).animate(scale),
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 300,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                  ),
                  child: BakerySquarePalette.shell(
                    context: context,
                    borderRadius: 22,
                    border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: BakerySquarePalette.shadow(context),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.campaign_rounded, color: accent, size: 36),
                          const SizedBox(height: 10),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: AppFonts.style(
                              fontSize: 18,
                              fontWeight: AppFonts.bold,
                              height: 1.25,
                              color: BakeryTheme.body(context),
                            ),
                          ),
                          if (hasImage) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CatalogItemImage(
                                path: widget.imagePath,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                emoji: '📣',
                              ),
                            ),
                          ],
                          if (hasMessage) ...[
                            const SizedBox(height: 12),
                            Flexible(
                              child: SingleChildScrollView(
                                child: Text(
                                  widget.message,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.style(
                                    fontSize: 15,
                                    fontWeight: AppFonts.medium,
                                    height: 1.45,
                                    color: BakeryTheme.subtitle(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _close,
                            child: Text(strings.confirm),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
