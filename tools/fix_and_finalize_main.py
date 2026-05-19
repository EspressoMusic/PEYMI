"""Fix lenient reconstruction and write lib/main.dart."""
import re
from pathlib import Path

ROOT = Path(r"c:\Users\Nirhdhd\bakery_shop_app")
src = (ROOT / "tools" / "rebuilt_skip3.dart").read_text(encoding="utf-8")

# Remove misplaced methods from BakeryApp (between build's closing and next class)
app_match = re.search(
    r"(class BakeryApp extends StatelessWidget \{.*?Widget build\(BuildContext context\) \{.*?return MaterialApp\(.*?\);\s*\})\s*(Future<void>.*?)(class _EmojiConfettiOverlay)",
    src,
    re.DOTALL,
)
if not app_match:
    raise SystemExit("Could not parse BakeryApp block")

bakery_app = app_match.group(1)
misplaced = app_match.group(2)
rest_from_confetti = app_match.group(3) + src[app_match.end(2) - len(app_match.group(3)) :]

# Fix BakeryApp theme + RoleSelection home
bakery_app = bakery_app.replace(
    "      home: const BakeryHomePage(),",
    "",
).replace(
    """      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),""",
    """      builder: (context, child) {
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
          titleLarge: TextStyle(fontWeight: FontWeight.w900),
          titleMedium: TextStyle(fontWeight: FontWeight.w800),
          bodyLarge: TextStyle(fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(fontWeight: FontWeight.w700),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: const RoleSelectionPage(),""",
)

# Fix syntax errors in misplaced FAQ block
misplaced = misplaced.replace("                            );", "                            ),")
misplaced = misplaced.replace("                                            );", "                                            ),")
misplaced = misplaced.replace("                                        );", "                                        ),")

header = """import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:ui' show lerpDouble;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BakeryApp());
}

"""

prefix = (ROOT / "tools" / "_prefix.dart").read_text(encoding="utf-8")
# StatefulBuilder password fix
prefix = prefix.replace(
    "builder: (dialogContext) {\n        return Directionality(",
    "builder: (dialogContext) {\n        return StatefulBuilder(\n          builder: (dialogContext, setDialogState) {\n            return Directionality(",
)
prefix = prefix.replace(
    "                    authFailed = true;\n                    formKey.currentState!.validate();\n                    (dialogContext as Element).markNeedsBuild();",
    "                    setDialogState(() => authFailed = true);\n                    formKey.currentState!.validate();",
)
prefix = prefix.replace(
    "          ),\n        );\n      },\n    );\n\n    passwordController.dispose();",
    "          ),\n        );\n          },\n        );\n      },\n    );\n\n    passwordController.dispose();",
)

# Fix duplicate dealOrders in OrdersPage
rest = rest_from_confetti.replace(
    "    required this.dealOrders,\n    required this.dealOrders,",
    "    required this.dealOrders,",
).replace(
    "  final List<Map<String, dynamic>> dealOrders;\n  final List<Map<String, dynamic>> dealOrders;",
    "  final List<Map<String, dynamic>> dealOrders;",
)

# Fix OrdersPage - needs createState and State class
if "class _OrdersPage extends StatefulWidget" in rest and "createState" not in rest.split("class _OrdersPage")[1].split("class _SettingsHelpPage")[0]:
    rest = rest.replace(
        """class _OrdersPage extends StatefulWidget {
  const _OrdersPage({""",
        """class _OrdersPage extends StatefulWidget {
  const _OrdersPage({""",
    )
    orders_insert = """
  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage> {
"""
    rest = rest.replace(
        "  final void Function(Map<String, dynamic> order) onRepeatOrder;\n\n  @override\n  Widget build(BuildContext context) {",
        "  final void Function(Map<String, dynamic> order) onRepeatOrder;\n" + orders_insert + "\n  @override\n  Widget build(BuildContext context) {",
        1,
    )
    rest = rest.replace("onDecrease(item", "widget.onDecrease(item").replace(
        "onConfirmOrder", "widget.onConfirmOrder"
    )
    rest = rest.replace("orders: _pastOrders", "orders: widget.orders").replace(
        "cartItems: cartItems", "cartItems: widget.cartItems"
    )

# Add cart sound to BakeryHomePage
rest = rest.replace(
    "  final Map<String, int> _cartQuantities = {};",
    """  final Map<String, int> _cartQuantities = {};
  final AudioPlayer _cartSoundPlayer = AudioPlayer();""",
    1,
)

if "_playCartAddSound" not in rest:
    rest = rest.replace(
        "\n}\n\nclass _CatalogPage",
        """
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

  int _parsePrice(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
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
}

class _CatalogPage""",
        1,
    )

# Replace simple Settings with Stateful + grid + misplaced helper methods
settings_state = misplaced + """

class _SettingsHelpPage extends StatefulWidget {
  const _SettingsHelpPage();

  @override
  State<_SettingsHelpPage> createState() => _SettingsHelpPageState();
}

class _SettingsHelpPageState extends State<_SettingsHelpPage> {
  static const String _contactPhone = '0501234567';

  Future<void> _openAccessibilityPanel() async {
    const String accessibilityEmail = 'shilohdhd1@gmail.com';
    const String lastUpdated = '29/04/2026';
    const sections = [
      {
        'title': 'מחויבות לנגישות',
        'items': [
          'אנו פועלים לקדם שוויון זכויות ושקיפות כלפי כלל הלקוחות, כולל אנשים עם מוגבלות.',
          'האפליקציה מותאמת לשימוש בעברית ובכיוון קריאה מימין לשמאל (RTL).',
        ],
      },
      {
        'title': 'סיוע ושירות נגיש',
        'items': [
          'ניתן לפנות דרך וואטסאפ או דרך טופס פנייה בתוך האפליקציה.',
          'בקשות בנושא נגישות מטופלות בעדיפות.',
        ],
      },
    ];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'נגישות ותקנון נגישות',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        ...sections.map((section) {
                          final items = (section['items'] as List<String>);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F4EC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section['title'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                ...items.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text('• $item'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFE3CF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('רכז/ת נגישות', style: TextStyle(fontWeight: FontWeight.w900)),
                              Text('אימייל: $accessibilityEmail'),
                              Text('עדכון אחרון: $lastUpdated', style: TextStyle(color: Colors.brown.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openContactOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('צור קשר', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                Text('טלפון: $_contactPhone', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 62), backgroundColor: const Color(0xFF4E342E), foregroundColor: Colors.white),
                  onPressed: () async {
                    final uri = Uri.parse('https://wa.me/972${_contactPhone.substring(1)}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('מעבר לוואטסאפ'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openReviewsPanel() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text('תודה על המלצתכם!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ),
    );
  }

"""

# Remove old _SettingsHelpPage at end
rest = re.sub(
    r"class _SettingsHelpPage extends StatelessWidget \{.*?\n\}\s*$",
    "",
    rest,
    flags=re.DOTALL,
)

# Replace _CatalogPage with StatefulWidget version (read from patch 008 additions - simplified)
catalog = '''
class _CatalogPage extends StatefulWidget {
  const _CatalogPage({
    required this.products,
    required this.drinks,
    required this.quantities,
    required this.onSetQuantity,
  });

  final List<Map<String, String>> products;
  final List<Map<String, String>> drinks;
  final Map<String, int> quantities;
  final void Function(String name, int quantity) onSetQuantity;

  @override
  State<_CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<_CatalogPage> {
  bool _showDrinks = false;
  int _confettiToken = 0;

  Future<int?> _showQuantityPicker({required BuildContext context, required int current}) async {
    int tempSelected = current;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              const Text('בחר כמות (עד 10)', style: TextStyle(fontWeight: FontWeight.w800)),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 44,
                  onSelectedItemChanged: (index) => tempSelected = index,
                  controller: FixedExtentScrollController(initialItem: current.clamp(0, 10)),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index > 10) return null;
                      return Center(child: Text('$index', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)));
                    },
                  ),
                ),
              ),
              FilledButton(onPressed: () => Navigator.pop(context, tempSelected), child: const Text('אישור')),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _showDrinks ? widget.drinks : widget.products;
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: false, icon: Icon(Icons.bakery_dining), label: Text('מאפים')),
                  ButtonSegment<bool>(value: true, icon: Icon(Icons.local_cafe), label: Text('שתייה')),
                ],
                selected: {_showDrinks},
                onSelectionChanged: (v) => setState(() => _showDrinks = v.first),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.62,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final qty = widget.quantities[item['name']] ?? 0;
                  return _AnimatedProductCard(
                    item: item,
                    quantity: qty,
                    onDecrease: () {
                      if (qty <= 0) return;
                      widget.onSetQuantity(item['name']!, qty - 1);
                    },
                    onIncrease: () {
                      if (qty >= 10) return;
                      widget.onSetQuantity(item['name']!, qty + 1);
                      setState(() => _confettiToken++);
                    },
                    onPickQuantity: () async {
                      final selected = await _showQuantityPicker(context: context, current: qty);
                      if (selected != null) widget.onSetQuantity(item['name']!, selected);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        if (_confettiToken > 0)
          IgnorePointer(
            child: _EmojiConfettiOverlay(
              key: ValueKey<int>(_confettiToken),
              onFinished: () {},
            ),
          ),
      ],
    );
  }
}

class _AnimatedProductCard extends StatefulWidget {
  const _AnimatedProductCard({
    required this.item,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onPickQuantity,
  });

  final Map<String, String> item;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onPickQuantity;

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: item['image'] != null
                    ? Image.asset(item['image']!, fit: BoxFit.cover, width: double.infinity)
                    : Center(child: Text(item['emoji'] ?? '🥖', style: const TextStyle(fontSize: 48))),
              ),
            ),
            const SizedBox(height: 8),
            Text(item['name']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(item['subtitle'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.brown.shade500)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text(item['price']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: widget.onDecrease, icon: const Icon(Icons.remove, size: 16), visualDensity: VisualDensity.compact),
                      GestureDetector(onTap: widget.onPickQuantity, child: Text('${widget.quantity}', style: const TextStyle(fontWeight: FontWeight.w900))),
                      IconButton(onPressed: widget.onIncrease, icon: const Icon(Icons.add, size: 16), visualDensity: VisualDensity.compact),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
'''

rest = re.sub(
    r"class _CatalogPage extends StatelessWidget \{.*?\n\}\n\nclass _DealsPage",
    catalog + "\nclass _DealsPage",
    rest,
    count=1,
    flags=re.DOTALL,
)

# Enhance _DealsPage with redeem button if simple
if "onRedeemDeal" in rest and "מימוש דיל" not in rest:
    rest = rest.replace(
        "              isThreeLine: true,\n            ),\n          ),\n        ),",
        """              isThreeLine: true,
              ),
              trailing: FilledButton(
                onPressed: () => onRedeemDeal(deal),
                child: const Text('מימוש'),
              ),
            ),
          ),
        ),""",
        1,
    )

out = header + bakery_app + "\n}\n\n" + prefix + "\n" + rest + settings_state
OUT = ROOT / "lib" / "main.dart"
OUT.write_text(out, encoding="utf-8", newline="\n")
print("Wrote", OUT, "lines", len(out.splitlines()))
