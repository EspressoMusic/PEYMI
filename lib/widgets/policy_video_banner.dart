import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/policy_consent_store.dart';

/// Policy explainer video (network URL) or styled placeholder when no URL is configured.
class PolicyVideoBanner extends StatefulWidget {
  const PolicyVideoBanner({super.key});

  @override
  State<PolicyVideoBanner> createState() => _PolicyVideoBannerState();
}

class _PolicyVideoBannerState extends State<PolicyVideoBanner> {
  VideoPlayerController? _controller;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = PolicyConsentStore.policyVideoUrl.trim();
    if (url.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    final controller = _controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: controller != null && controller.value.isInitialized
            ? controller.value.aspectRatio
            : 16 / 9,
        child: controller != null && controller.value.isInitialized
            ? Stack(
                fit: StackFit.expand,
                children: [
                  VideoPlayer(controller),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (controller.value.isPlaying) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            : _PlaceholderBanner(
                label: _failed ? strings.policyVideoPlaceholder : strings.policyVideoLoading,
              ),
      ),
    );
  }
}

class _PlaceholderBanner extends StatelessWidget {
  const _PlaceholderBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BakeryTheme.accent(context).withValues(alpha: 0.35),
            BakeryTheme.cardSurface(context),
          ],
        ),
        border: Border.all(color: BakeryTheme.border(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_fill_rounded, size: 56, color: BakeryTheme.accent(context)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
