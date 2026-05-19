"""Build lib/main.dart from rebuilt_skip3 + prefix."""
import re
from pathlib import Path

ROOT = Path(r"c:\Users\Nirhdhd\bakery_shop_app")
rebuilt = (ROOT / "tools" / "rebuilt_skip3.dart").read_text(encoding="utf-8")

# Strip broken BakeryApp methods
rebuilt = re.sub(
    r"class BakeryApp extends StatelessWidget \{.*?class _EmojiConfettiOverlay",
    "class _EMOJI_PLACEHOLDER",
    rebuilt,
    count=1,
    flags=re.DOTALL,
)

header = '''import 'package:flutter/material.dart';
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
      home: const RoleSelectionPage(),
    );
  }
}

'''

prefix = (ROOT / "tools" / "_prefix.dart").read_text(encoding="utf-8")
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
# _prefix starts with home: RoleSelection - drop duplicate lines at start
prefix = re.sub(r"^\s*home: const RoleSelectionPage\(\),\s*\);\s*\}\s*\}\s*\n*", "", prefix)

emoji_and_rest = rebuilt.split("class _EMOJI_PLACEHOLDER", 1)[1]
emoji_and_rest = "class _EmojiConfettiOverlay" + emoji_and_rest

# Fix duplicate dealOrders
emoji_and_rest = emoji_and_rest.replace(
    "required this.dealOrders,\n    required this.dealOrders,",
    "required this.dealOrders,",
).replace(
    "final List<Map<String, dynamic>> dealOrders;\n  final List<Map<String, dynamic>> dealOrders;",
    "final List<Map<String, dynamic>> dealOrders;",
)

# Add AudioPlayer + helpers to _BakeryHomePageState
emoji_and_rest = emoji_and_rest.replace(
    "  final Map<String, int> _cartQuantities = {};",
    "  final Map<String, int> _cartQuantities = {};\n  final AudioPlayer _cartSoundPlayer = AudioPlayer();",
    1,
)

if "_playCartAddSound" not in emoji_and_rest:
    emoji_and_rest = emoji_and_rest.replace(
        "          setState(() => _cartQuantities[name] = current + 1);",
        "          setState(() => _setCartQuantity(name, current + 1));",
    )
    emoji_and_rest = emoji_and_rest.replace(
        "            _cartQuantities[name] = quantity.clamp(0, 10);",
        "            _setCartQuantity(name, quantity);",
    )
    insert_at = emoji_and_rest.find("\n}\n\nclass _CatalogPage")
    helpers = """
  void _setCartQuantity(String name, int quantity) {
    final previous = _cartQuantities[name] ?? 0;
    final next = quantity.clamp(0, 10);
    _cartQuantities[name] = next;
    if (next > previous) _playCartAddSound();
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
"""
    emoji_and_rest = emoji_and_rest[:insert_at] + helpers + emoji_and_rest[insert_at:]

# Replace _CatalogPage (simple) with full version
CATALOG = r'''
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
    int temp = current;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: 280,
        child: Column(
          children: [
            const Text('בחר כמות (עד 10)', style: TextStyle(fontWeight: FontWeight.w800)),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 44,
                onSelectedItemChanged: (i) => temp = i,
                controller: FixedExtentScrollController(initialItem: current.clamp(0, 10)),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index > 10) return null;
                    return Center(child: Text('$index', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)));
                  },
                ),
              ),
            ),
            FilledButton(onPressed: () => Navigator.pop(context, temp), child: const Text('אישור')),
          ],
        ),
      ),
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
                  ButtonSegment(value: false, icon: Icon(Icons.bakery_dining), label: Text('מאפים')),
                  ButtonSegment(value: true, icon: Icon(Icons.local_cafe), label: Text('שתייה')),
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
                      if (qty > 0) widget.onSetQuantity(item['name']!, qty - 1);
                    },
                    onIncrease: () {
                      if (qty < 10) {
                        widget.onSetQuantity(item['name']!, qty + 1);
                        setState(() => _confettiToken++);
                      }
                    },
                    onPickQuantity: () async {
                      final s = await _showQuantityPicker(context: context, current: qty);
                      if (s != null) widget.onSetQuantity(item['name']!, s);
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
              key: ValueKey(_confettiToken),
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
            const SizedBox(height: 6),
            Text(item['name']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(item['subtitle'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.brown.shade500)),
            Row(
              children: [
                Expanded(child: Text(item['price']!, style: const TextStyle(fontWeight: FontWeight.w900))),
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
                      GestureDetector(onTap: widget.onPickQuantity, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('${widget.quantity}', style: const TextStyle(fontWeight: FontWeight.w900)))),
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

emoji_and_rest = re.sub(
    r"class _CatalogPage extends StatelessWidget \{.*?\n\}\n\nclass _DealsPage",
    CATALOG + "\nclass _DealsPage",
    emoji_and_rest,
    count=1,
    flags=re.DOTALL,
)

# Fix _OrdersPage - add State class
if "class _OrdersPageState" not in emoji_and_rest:
    emoji_and_rest = emoji_and_rest.replace(
        """  final void Function(Map<String, dynamic> order) onRepeatOrder;

  @override
  Widget build(BuildContext context) {""",
        """  final void Function(Map<String, dynamic> order) onRepeatOrder;

  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage> {
  @override
  Widget build(BuildContext context) {""",
        1,
    )
    emoji_and_rest = emoji_and_rest.replace("onDecrease(item", "widget.onDecrease(item")
    emoji_and_rest = emoji_and_rest.replace("onConfirmOrder", "widget.onConfirmOrder")
    emoji_and_rest = emoji_and_rest.replace("...orders.map", "...widget.orders.map")
    emoji_and_rest = emoji_and_rest.replace("if (cartItems.isEmpty)", "if (widget.cartItems.isEmpty)")
    emoji_and_rest = emoji_and_rest.replace("...cartItems.map", "...widget.cartItems.map")
    emoji_and_rest = emoji_and_rest.replace("if (cartItems.isNotEmpty)", "if (widget.cartItems.isNotEmpty)")

# Replace settings page
SETTINGS = r'''
class _SettingsHelpPage extends StatefulWidget {
  const _SettingsHelpPage();

  @override
  State<_SettingsHelpPage> createState() => _SettingsHelpPageState();
}

class _SettingsHelpPageState extends State<_SettingsHelpPage> {
  static const String _contactPhone = '0501234567';

  Future<void> _openAccessibilityPanel() async {
    const accessibilityEmail = 'shilohdhd1@gmail.com';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('נגישות ותקנון נגישות', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text('אימייל לרכז/ת נגישות: $accessibilityEmail', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'אנו מחויבים לספק חוויית שימוש נגישה. האפליקציה תומכת בעברית ובכיוון RTL, עם טקסט מוגדל וכפתורים ברורים.',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFaqPanel() async {
    final faq = [
      {'q': 'מה שעות הפעילות?', 'a': 'א׳-ה׳ 07:00-21:00, שישי עד 14:00.'},
      {'q': 'תוך כמה זמן משלוח?', 'a': '45-90 דקות לפי אזור ועומס.'},
      {'q': 'איך משלמים?', 'a': 'אשראי, ביט או מזומן לשליח.'},
    ];
    final expanded = <int>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('שאלות נפוצות', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Expanded(
                child: ListView.builder(
                  itemCount: faq.length,
                  itemBuilder: (context, i) {
                    final open = expanded.contains(i);
                    return Card(
                      child: ListTile(
                        title: Text(faq[i]['q']!),
                        subtitle: open ? Text(faq[i]['a']!) : null,
                        trailing: Icon(open ? Icons.expand_less : Icons.expand_more),
                        onTap: () => setModalState(() {
                          if (open) {
                            expanded.remove(i);
                          } else {
                            expanded.add(i);
                          }
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openContactOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('צור קשר', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            Text('טלפון: $_contactPhone'),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56), backgroundColor: const Color(0xFF4E342E), foregroundColor: Colors.white),
              onPressed: () async {
                final uri = Uri.parse('https://wa.me/972${_contactPhone.substring(1)}');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.chat),
              label: const Text('וואטסאפ'),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    const tiles = [
      {'title': 'צור קשר', 'subtitle': 'וואטסאפ וטלפון', 'icon': Icons.phone},
      {'title': 'המליצו עלינו', 'subtitle': 'שתפו חברים', 'icon': Icons.campaign},
      {'title': 'נגישות', 'subtitle': 'מידע והתאמות', 'icon': Icons.accessible},
      {'title': 'שאלות נפוצות', 'subtitle': 'תשובות מהירות', 'icon': Icons.quiz},
    ];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('הגדרות ועזרה', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.05,
              ),
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                final tile = tiles[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    switch (tile['title']) {
                      case 'צור קשר':
                        _openContactOptions();
                      case 'המליצו עלינו':
                        _openReviewsPanel();
                      case 'נגישות':
                        _openAccessibilityPanel();
                      case 'שאלות נפוצות':
                        _openFaqPanel();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EC),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(tile['icon'] as IconData, color: const Color(0xFF4E342E)),
                        const Spacer(),
                        Text(tile['title'] as String, style: const TextStyle(fontWeight: FontWeight.w900)),
                        Text(tile['subtitle'] as String, style: TextStyle(color: Colors.brown.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
'''

emoji_and_rest = re.sub(
    r"class _SettingsHelpPage extends StatelessWidget \{.*$",
    SETTINGS.strip(),
    emoji_and_rest,
    count=1,
    flags=re.DOTALL,
)

# Enhance deals redeem UI
if "מימוש" not in emoji_and_rest.split("class _DealsPage")[1].split("class _OrdersPage")[0]:
    emoji_and_rest = emoji_and_rest.replace(
        "              isThreeLine: true,\n            ),",
        "              isThreeLine: true,\n              trailing: FilledButton(onPressed: () => onRedeemDeal(deal), child: const Text('מימוש דיל')),\n            ),",
        1,
    )

out = header + prefix + emoji_and_rest
(ROOT / "lib" / "main.dart").write_text(out, encoding="utf-8", newline="\n")
print("lines", len(out.splitlines()))
