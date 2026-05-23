import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_theme_mode.dart';
import 'catalog_item_image.dart';

/// Per-store branding image (local file, network URL, or default app icon).
class StoreAppBrandBadge extends StatelessWidget {
  const StoreAppBrandBadge({
    super.key,
    this.imagePath,
    this.logoUrl,
    this.size = 72,
    this.borderRadius,
    this.fallbackEmoji = '🏪',
  });

  final String? imagePath;
  final String? logoUrl;
  final double size;
  final BorderRadius? borderRadius;
  final String fallbackEmoji;

  static bool _isNetwork(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);
    final url = logoUrl?.trim();
    final local = imagePath?.trim();

    Widget child;
    if (url != null && url.isNotEmpty) {
      child = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    } else if (local != null && local.isNotEmpty) {
      if (CatalogItemImage.isAssetPath(local)) {
        child = Image.asset(
          local,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(context),
        );
      } else if (_isNetwork(local)) {
        child = Image.network(
          local,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(context),
        );
      } else {
        child = Image.file(
          File(local),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(context),
        );
      }
    } else {
      child = _fallback(context);
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: BakeryTheme.border(context)),
        ),
        child: child,
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: BakeryTheme.softSurface(context),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size * 0.72,
        height: size * 0.72,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.42)),
      ),
    );
  }
}
