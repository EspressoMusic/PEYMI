import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import 'catalog_item_image.dart';

/// Customer-facing store update: text, optional image, optional dismiss control.
class StoreAnnouncementPanel extends StatelessWidget {
  const StoreAnnouncementPanel({
    super.key,
    required this.message,
    this.imagePath = '',
    this.onDismiss,
    this.compact = false,
    this.showHeader = true,
  });

  final String message;
  final String imagePath;
  final VoidCallback? onDismiss;
  final bool compact;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    final hasImage = imagePath.trim().isNotEmpty;
    final hasText = message.trim().isNotEmpty;

    return Material(
      color: BakeryTheme.accent(context).withValues(alpha: compact ? 0.1 : 0.14),
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 14 : 16, compact ? 10 : 8, compact ? 10 : 8, compact ? 10 : 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.campaign_outlined, color: BakeryTheme.accent(context), size: compact ? 20 : 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    Text(
                      strings.storeAnnouncementBanner,
                      style: BakeryTheme.text(context, fontSize: compact ? 11 : 12, fontWeight: FontWeight.w800),
                    ),
                  if (hasImage) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CatalogItemImage(
                        path: imagePath,
                        height: compact ? 100 : 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        emoji: '📣',
                      ),
                    ),
                  ],
                  if (hasText) ...[
                    SizedBox(height: (hasImage || showHeader) ? 8 : 0),
                    Text(
                      message,
                      style: BakeryTheme.subtitleText(context, fontSize: compact ? 12 : 13, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: Icon(Icons.close_rounded, color: BakeryTheme.muted(context), size: 22),
                onPressed: onDismiss,
                tooltip: strings.dismissAnnouncement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
          ],
        ),
      ),
    );
  }
}
