import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_fonts.dart';
import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/bakery_navigator.dart';
import '../core/bakery_square_palette.dart';
import '../core/catalog_store.dart';

Future<void> showCatalogSetupPromptIfNeeded(BuildContext context) async {
  if (!context.mounted) return;
  if (!await CatalogStore.instance.shouldShowSetupPrompt()) return;
  await CatalogStore.instance.markSetupPromptShown();
  if (!context.mounted) return;
  final strings = AppLocale.instance.s;
  await showCatalogSetupBanner(
    context,
    title: strings.catalogEmptyManagerTitle,
    message: strings.catalogEmptyManagerSub,
    buttonLabel: strings.catalogSetupGotIt,
  );
}

/// Centered square banner — clear copy for empty catalog setup.
Future<void> showCatalogSetupBanner(
  BuildContext context, {
  required String title,
  required String message,
  required String buttonLabel,
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
        return _CatalogSetupBannerOverlay(
          animation: animation,
          title: title,
          message: message,
          buttonLabel: buttonLabel,
        );
      },
    ),
  );
}

class _CatalogSetupBannerOverlay extends StatefulWidget {
  const _CatalogSetupBannerOverlay({
    required this.animation,
    required this.title,
    required this.message,
    required this.buttonLabel,
  });

  final Animation<double> animation;
  final String title;
  final String message;
  final String buttonLabel;

  @override
  State<_CatalogSetupBannerOverlay> createState() => _CatalogSetupBannerOverlayState();
}

class _CatalogSetupBannerOverlayState extends State<_CatalogSetupBannerOverlay> {
  var _closing = false;

  void _dismiss() {
    if (!mounted || _closing) return;
    _closing = true;
    popThen(context, () async {});
  }

  @override
  Widget build(BuildContext context) {
    const tileSize = 280.0;
    final scale = CurvedAnimation(parent: widget.animation, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: widget.animation, curve: Curves.easeOut);
    final accent = BakeryTheme.accent(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _dismiss,
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
                child: SizedBox(
                  width: tileSize,
                  height: tileSize,
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
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.storefront_rounded, color: accent, size: 40),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.style(
                                      fontSize: 20,
                                      fontWeight: AppFonts.bold,
                                      height: 1.2,
                                      color: BakeryTheme.body(context),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    widget.message,
                                    textAlign: TextAlign.center,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.style(
                                      fontSize: 15,
                                      fontWeight: AppFonts.medium,
                                      height: 1.35,
                                      color: BakeryTheme.subtitle(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _dismiss,
                              child: Text(
                                widget.buttonLabel,
                                style: AppFonts.style(
                                  fontSize: 15,
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CatalogEmptyState extends StatelessWidget {
  const CatalogEmptyState({
    super.key,
    required this.message,
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = BakeryTheme.accent(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 24, horizontal: 12),
      child: BakerySquarePalette.shell(
        context: context,
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: compact ? 32 : 40, color: accent),
              SizedBox(height: compact ? 8 : 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  fontSize: compact ? 14 : 16,
                  fontWeight: AppFonts.bold,
                  height: 1.35,
                  color: BakeryTheme.body(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
