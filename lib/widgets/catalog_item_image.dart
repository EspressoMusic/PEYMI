import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_theme_mode.dart';

/// Product image from bundled asset or manager-uploaded file path.
class CatalogItemImage extends StatelessWidget {
  const CatalogItemImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.emoji = '🥖',
    this.borderRadius,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String emoji;
  final BorderRadius? borderRadius;

  static bool isAssetPath(String path) => path.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (path.isEmpty) {
      image = _fallback(context);
    } else if (isAssetPath(path)) {
      image = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    } else {
      image = Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: BakeryTheme.softSurface(context),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: (height ?? 48) * 0.45)),
    );
  }
}
