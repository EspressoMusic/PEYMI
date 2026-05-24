import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/legal_config.dart';
import '../core/legal_versions.dart';
import 'bakery_celebration.dart';

enum LegalDocumentKind { privacy, terms }

/// Full-text legal document (pilot draft) from bundled assets.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocumentKind kind;

  static Future<void> open(BuildContext context, LegalDocumentKind kind) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalDocumentScreen(kind: kind)),
    );
  }

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  String? _body;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hebrew = AppLocale.instance.isHebrew;
    final path = switch (widget.kind) {
      LegalDocumentKind.privacy => 'assets/legal/privacy_policy_en.txt',
      LegalDocumentKind.terms =>
          hebrew ? 'assets/legal/terms_of_use_he.txt' : 'assets/legal/terms_of_use_en.txt',
    };
    final text = await rootBundle.loadString(path);
    if (!mounted) return;
    setState(() {
      _body = text;
      _loading = false;
    });
  }

  String get _title => switch (widget.kind) {
        LegalDocumentKind.privacy => 'Privacy Policy',
        LegalDocumentKind.terms => 'Terms of Use',
      };

  String get _version => switch (widget.kind) {
        LegalDocumentKind.privacy => LegalVersions.privacyVersion,
        LegalDocumentKind.terms => LegalVersions.termsVersion,
      };

  Future<void> _openWeb() async {
    final uri = switch (widget.kind) {
      LegalDocumentKind.privacy => LegalConfig.privacyPolicyUri,
      LegalDocumentKind.terms => LegalConfig.termsOfUseUri,
    };
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      unawaited(showBakeryNoticeBanner(context, title: 'Could not open web page', isError: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Open on web',
            onPressed: _openWeb,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'Version $_version · ${LegalVersions.lastUpdatedLabel}',
                  style: BakeryTheme.subtitleText(context, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilot-ready draft — not legal advice. Lawyer review required before full launch.',
                  style: BakeryTheme.subtitleText(context, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  _body ?? '',
                  style: BakeryTheme.text(context, fontSize: 14, height: 1.45),
                ),
              ],
            ),
    );
  }
}
