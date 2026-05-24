import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import 'bakery_celebration.dart';

/// Store link with inline copy feedback (COPIED! + confetti) instead of a banner.
class CopyableStoreLinkBlock extends StatefulWidget {
  const CopyableStoreLinkBlock({
    super.key,
    required this.link,
    this.compact = false,
  });

  final String link;
  final bool compact;

  @override
  State<CopyableStoreLinkBlock> createState() => CopyableStoreLinkBlockState();
}

class CopyableStoreLinkBlockState extends State<CopyableStoreLinkBlock> {
  var _copied = false;
  var _confettiToken = 0;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    if (!mounted) return;
    _copiedTimer?.cancel();
    setState(() {
      _copied = true;
      _confettiToken++;
    });
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    final copiedLabel = strings.linkCopiedBadge;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(widget.compact ? 10 : 12),
          decoration: BoxDecoration(
            color: BakeryTheme.softSurface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BakeryTheme.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.link,
                      style: BakeryTheme.text(
                        context,
                        fontSize: widget.compact ? 12 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: _copied
                        ? Padding(
                            key: const ValueKey('copied'),
                            padding: const EdgeInsetsDirectional.only(start: 8, top: 2),
                            child: Text(
                              copiedLabel,
                              style: BakeryTheme.text(
                                context,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ],
              ),
              if (!widget.compact) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: copyLink,
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(strings.managerShareStoreCopy),
                ),
              ],
            ],
          ),
        ),
        if (_confettiToken > 0)
          Positioned(
            left: 0,
            right: 0,
            top: -8,
            height: 120,
            child: IgnorePointer(
              child: BakeryShapeConfetti(
                key: ValueKey(_confettiToken),
                onFinished: () {
                  if (mounted) setState(() => _confettiToken = 0);
                },
              ),
            ),
          ),
      ],
    );
  }
}
