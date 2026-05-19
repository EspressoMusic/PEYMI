"""Assemble lib/main.dart from recovered fragments."""
from pathlib import Path

ROOT = Path(r"c:\Users\Nirhdhd\bakery_shop_app")
TOOLS = ROOT / "tools"
OUT = ROOT / "lib" / "main.dart"

HEADER = r'''import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:ui' show lerpDouble;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BakeryApp());
}

class BakeryApp extends StatelessWidget {
  const BakeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'מאפיית הבית',
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1) * 1.22,
            ),
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'VarelaRound',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        textTheme: const TextTheme().copyWith(
          titleLarge: const TextStyle(fontWeight: FontWeight.w900),
          titleMedium: const TextStyle(fontWeight: FontWeight.w800),
          bodyLarge: const TextStyle(fontWeight: FontWeight.w700),
          bodyMedium: const TextStyle(fontWeight: FontWeight.w700),
          bodySmall: const TextStyle(fontWeight: FontWeight.w700),
          labelLarge: const TextStyle(fontWeight: FontWeight.w900),
          labelMedium: const TextStyle(fontWeight: FontWeight.w800),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: const RoleSelectionPage(),
    );
  }
}

const String _managerPassword = '1234';

'''

PREFIX = (TOOLS / "_prefix.dart").read_text(encoding="utf-8")
# Fix password dialog to use StatefulBuilder
PREFIX = PREFIX.replace(
    """    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('כניסת מנהל', textAlign: TextAlign.right),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'הזן סיסמת מנהל',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'סיסמה',
                      border: const OutlineInputBorder(),
                      errorText: authFailed ? 'סיסמה שגויה' : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'נא להזין סיסמה';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.pop(dialogContext, passwordController.text == _managerPassword);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('ביטול'),
              ),
              FilledButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final ok = passwordController.text == _managerPassword;
                  if (!ok) {
                    authFailed = true;
                    formKey.currentState!.validate();
                    (dialogContext as Element).markNeedsBuild();
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('כניסה'),
              ),
            ],
          ),
        );
      },
    );""",
    """    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('כניסת מנהל', textAlign: TextAlign.right),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'הזן סיסמת מנהל',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'סיסמה',
                          border: const OutlineInputBorder(),
                          errorText: authFailed ? 'סיסמה שגויה' : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'נא להזין סיסמה';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.pop(
                              dialogContext,
                              passwordController.text == _managerPassword,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('ביטול'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final ok = passwordController.text == _managerPassword;
                      if (!ok) {
                        setDialogState(() => authFailed = true);
                        formKey.currentState!.validate();
                        return;
                      }
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('כניסה'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );""",
)

# Extract BakeryHomePage block from rebuilt_skip3 (clean section)
rebuilt = (TOOLS / "rebuilt_skip3.dart").read_text(encoding="utf-8")
start = rebuilt.index("class BakeryHomePage extends StatefulWidget")
end = rebuilt.index("class _CatalogPage extends StatelessWidget")
bakery_block = rebuilt[start:end]

# Add cart sound player and helpers to _BakeryHomePageState
bakery_block = bakery_block.replace(
    "  final Map<String, int> _cartQuantities = {};",
    """  final Map<String, int> _cartQuantities = {};
  final AudioPlayer _cartSoundPlayer = AudioPlayer();
  final Set<String> _redeemedDealTitles = <String>{};""",
)

bakery_block = bakery_block.replace(
    "          setState(() => _cartQuantities[name] = current + 1);",
    "          setState(() => _setCartQuantity(name, current + 1));",
)
bakery_block = bakery_block.replace(
    "            _cartQuantities[name] = quantity.clamp(0, 10);",
    "            _setCartQuantity(name, quantity);",
)

HELPERS = r'''
  int _parsePrice(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _setCartQuantity(String name, int quantity) {
    final previous = _cartQuantities[name] ?? 0;
    final next = quantity.clamp(0, 10);
    _cartQuantities[name] = next;
    if (next > previous) {
      _playCartAddSound();
    }
  }

  Future<void> _playCartAddSound() async {
    await _cartSoundPlayer.stop();
    await _cartSoundPlayer.play(AssetSource('sounds/cart_add.mp3'));
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  void dispose() {
    _cartSoundPlayer.dispose();
    super.dispose();
  }
'''

# Insert helpers before closing brace of _BakeryHomePageState
idx = bakery_block.rfind("  }\n}\n\nclass")
if idx == -1:
    idx = bakery_block.rfind("\n}\n\nclass _CatalogPage")
bakery_block = bakery_block[:idx] + HELPERS + bakery_block[idx:]

CONFETTI = rebuilt[rebuilt.index("class _EmojiConfettiOverlay"): rebuilt.index("class BakeryHomePage")]

# Read patch files for large widget sections - use line 152 patch tail for AnimatedProductCard
p152 = (TOOLS / "extracted_patches" / "012_line152.patch").read_text(encoding="utf-8")
# Extract _AnimatedProductCard class from patch additions
def extract_added_class(patch_text: str, class_name: str) -> str:
    lines = patch_text.splitlines()
    out = []
    capture = False
    for line in lines:
        if line.startswith("+class %s" % class_name):
            capture = True
        if capture:
            if line.startswith("+") and not line.startswith("+++"):
                out.append(line[1:])
            elif line.startswith(" ") and capture and out:
                out.append(line[1:])
            elif line.startswith("-") and capture:
                continue
            elif line.startswith("@@") and capture and out:
                break
            elif line.startswith("***") and capture and out:
                break
    return "\n".join(out)

# For full sections, read from patch 008+012 combined file built manually
CATALOG_AND_CARDS = (TOOLS / "catalog_section.dart").read_text(encoding="utf-8") if (TOOLS / "catalog_section.dart").exists() else ""

print("catalog_section exists:", (TOOLS / "catalog_section.dart").exists())
