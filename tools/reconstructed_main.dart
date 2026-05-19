import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

void main() {
  runApp(const BakeryApp());
}

class BakeryApp extends StatelessWidget {
  const BakeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'מאפיית הבית',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const BakeryHomePage(),
    );
  }

  Future<void> _openFaqPanel() async {
    final allFaq = [
      {
        'q': 'מה שעות הפעילות של המאפייה?',
        'a': 'ימים א׳-ה׳ 07:00-21:00, שישי 07:00-14:00. במוצ״ש פתוח לפי הזמנות מראש.',
      },
      {
        'q': 'תוך כמה זמן משלוח מגיע?',
        'a': 'משלוחים בעיר עד 45-60 דקות, ובאזורים סמוכים עד 90 דקות בהתאם לעומס.',
      },
      {
        'q': 'אפשר לבצע הזמנה לאירוע?',
        'a': 'כן. ניתן להזמין מגשי אירוח ועוגות אישיות לאירועים קטנים וגדולים.',
      },
      {
        'q': 'אפשר לשנות הזמנה אחרי שבוצעה?',
        'a': 'כן, עד 10 דקות מרגע האישור דרך פאנל ההזמנות או בשיחה עם שירות הלקוחות.',
      },
      {
        'q': 'יש אופציות ללא סוכר או טבעוני?',
        'a': 'יש מגוון פריטים מותאמים. מומלץ לציין בהערות הזמנה את ההעדפה התזונתית.',
      },
      {
        'q': 'איך אפשר לשלם?',
        'a': 'אפשר לשלם בכרטיס אשראי, ביט או מזומן לשליח (לפי זמינות אזורית).',
      },
    ];
    final randomFaq = [...allFaq]..shuffle(Random());
    final visibleFaq = randomFaq.take(5).toList();
    final expanded = <int>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    const Text(
                      'שאלות נפוצות',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'מידע על המאפייה, הזמנות ומשלוחים',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.brown.shade500, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: visibleFaq.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final faq = visibleFaq[index];
                          final isOpen = expanded.contains(index);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F4EC),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3)),
                              ],
                            );
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                setModalState(() {
                                  if (isOpen) {
                                    expanded.remove(index);
                                  } else {
                                    expanded.add(index);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.help_outline, color: Color(0xFF4E342E)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            faq['q']!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            );
                                          );
                                        ),
                                        AnimatedRotation(
                                          turns: isOpen ? 0.5 : 0,
                                          duration: const Duration(milliseconds: 220),
                                          child: const Icon(Icons.expand_more),
                                        ),
                                      ],
                                    ),
                                    AnimatedCrossFade(
                                      duration: const Duration(milliseconds: 220),
                                      crossFadeState: isOpen
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      firstChild: const SizedBox.shrink(),
                                      secondChild: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          faq['a']!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.brown.shade700,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<int?> _showQuantityPicker({
    required BuildContext context,
    required int current,
  }) async {
    int tempSelected = current;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('בחר כמות (עד 10)', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 44,
                  perspective: 0.005,
                  diameterRatio: 1.2,
                  onSelectedItemChanged: (index) => tempSelected = index,
                  controller: FixedExtentScrollController(initialItem: current.clamp(0, 10)),
                  physics: const FixedExtentScrollPhysics(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index > 10) return null;
                      return Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, tempSelected),
                    child: const Text('אישור'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _parsePrice(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}

class _EmojiConfettiOverlay extends StatefulWidget {
  const _EmojiConfettiOverlay({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_EmojiConfettiOverlay> createState() => _EmojiConfettiOverlayState();
}

class _EmojiConfettiOverlayState extends State<_EmojiConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  final List<String> _emojis = const ['🥐', '🧁', '🍰', '🍪', '🍩', '🍕'];

  @override
  void initState() {
    super.initState();
    final random = Random();
    _particles = List.generate(22, (index) {
      return _ConfettiParticle(
        x: random.nextDouble(),
        drift: (random.nextDouble() - 0.5) * 0.20,
        size: 22 + random.nextDouble() * 12,
        delay: random.nextDouble() * 0.35,
        emoji: _emojis[random.nextInt(_emojis.length)],
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeIn.transform(_controller.value);
            return Stack(
              children: _particles.map((p) {
                final localT = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
                final y = lerpDouble(-40, constraints.maxHeight + 40, localT)!;
                final x = ((p.x + (sin(localT * pi * 3) * p.drift)) * constraints.maxWidth)
                    .clamp(0.0, constraints.maxWidth - 24);
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: 1 - localT,
                    child: Transform.rotate(
                      angle: localT * pi * 2,
                      child: Text(
                        p.emoji,
                        style: TextStyle(fontSize: p.size),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.x,
    required this.drift,
    required this.size,
    required this.delay,
    required this.emoji,
  });

  final double x;
  final double drift;
  final double size;
  final double delay;
  final String emoji;
}

class BakeryHomePage extends StatefulWidget {
  const BakeryHomePage({super.key});

  @override
  State<BakeryHomePage> createState() => _BakeryHomePageState();
}

class _BakeryHomePageState extends State<BakeryHomePage> {
  int _selectedIndex = 3;
  final Map<String, int> _cartQuantities = {};

  final List<Map<String, String>> _products = const [
    {'name': 'בורקס', 'price': '18₪', 'category': 'מלוחים', 'subtitle': 'אפוי במקום', 'image': 'assets/images/products/burekas.png'},
    {'name': 'קוראסון', 'price': '16₪', 'category': 'מאפים', 'subtitle': 'חמאתי ופריך', 'image': 'assets/images/products/קוראסון.png'},
    {'name': 'פיצה אישית', 'price': '29₪', 'category': 'מלוחים', 'subtitle': 'עם גבינה ורוטב ביתי', 'image': 'assets/images/products/פיצה.png'},
    {'name': 'עוגה אישית', 'price': '24₪', 'category': 'קינוחים', 'subtitle': 'קינוח אישי לבחירה', 'image': 'assets/images/products/עוגה אישית.png'},
  ];
  final List<Map<String, String>> _drinks = const [
    {'name': 'קפה', 'price': '12₪', 'category': 'שתייה חמה', 'subtitle': 'אספרסו או הפוך', 'image': 'assets/images/products/קפה.png'},
    {'name': 'תה נענע', 'price': '10₪', 'category': 'שתייה חמה', 'subtitle': 'חליטה טרייה', 'image': 'assets/images/products/mint_tea.png'},
    {'name': 'סודה לימון', 'price': '11₪', 'category': 'שתייה קרה', 'subtitle': 'מרענן עם לימון', 'image': 'assets/images/products/סודה.png'},
    {'name': 'שייק הבית', 'price': '19₪', 'category': 'שייקים', 'subtitle': 'פירות העונה', 'image': 'assets/images/products/מילקשייק.png'},
  ];

  final List<Map<String, dynamic>> _deals = [
    {
      'title': 'דיל פיצה + קולה',
      'desc': 'פיצה אישית וסודה לימון במחיר מיוחד',
      'valid': 'יום שישי',
      'priceAfterDiscount': '35₪',
      'images': ['assets/images/products/פיצה.png', 'assets/images/products/סודה.png'],
      'items': [
        {'name': 'פיצה אישית', 'quantity': '1', 'price': '29₪'},
        {'name': 'סודה לימון', 'quantity': '1', 'price': '11₪'},
      ],
    },
    {
      'title': 'קפה ועוגה אישית',
      'desc': 'קומבו מתוק לבוקר עם הנחה',
      'valid': 'כל השבוע',
      'priceAfterDiscount': '30₪',
      'images': ['assets/images/products/קפה.png', 'assets/images/products/עוגה אישית.png'],
      'items': [
        {'name': 'קפה', 'quantity': '1', 'price': '12₪'},
        {'name': 'עוגה אישית', 'quantity': '1', 'price': '24₪'},
      ],
    },
    {
      'title': 'קוראסון + תה נענע',
      'desc': 'נשנוש מפנק עם חליטה חמה',
      'valid': 'עד סוף החודש',
      'priceAfterDiscount': '22₪',
      'images': ['assets/images/products/קוראסון.png', 'assets/images/products/mint_tea.png'],
      'items': [
        {'name': 'קוראסון', 'quantity': '1', 'price': '16₪'},
        {'name': 'תה נענע', 'quantity': '1', 'price': '10₪'},
      ],
    },
  ];
  final List<Map<String, dynamic>> _dealOrders = [];

  final List<Map<String, dynamic>> _pastOrders = [
    {
      'id': '#1042',
      'date': '24/04/2026',
      'total': '132₪',
      'status': 'נמסר',
      'progress': 1.0,
      'items': [
        {'name': 'בורקס', 'quantity': '2', 'price': '18₪'},
        {'name': 'קפה', 'quantity': '1', 'price': '12₪'},
      ],
    },
    {
      'id': '#1031',
      'date': '17/04/2026',
      'total': '96₪',
      'status': 'נמסר',
      'progress': 1.0,
      'items': [
        {'name': 'פיצה אישית', 'quantity': '2', 'price': '29₪'},
      ],
    },
    {
      'id': '#1018',
      'date': '08/04/2026',
      'total': '210₪',
      'status': 'נמסר',
      'progress': 1.0,
      'items': [
        {'name': 'עוגה אישית', 'quantity': '3', 'price': '24₪'},
        {'name': 'שייק הבית', 'quantity': '2', 'price': '19₪'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final allItems = [..._products, ..._drinks];
    final itemByName = {for (final item in allItems) item['name']!: item};
    final cartItems = _cartQuantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final base = itemByName[entry.key]!;
          return {
            ...base,
            'quantity': entry.value.toString(),
          };
        })
        .toList();
    final hasActiveOrder = cartItems.isNotEmpty || _dealOrders.isNotEmpty;

    final List<Widget> pages = [
      _SettingsHelpPage(),
      _DealsPage(
        deals: _deals,
        onRedeemDeal: (deal) {
          setState(() {
            _dealOrders.add({
              'id': 'DEAL-${_dealOrders.length + 1}',
              'title': deal['title'],
              'total': deal['priceAfterDiscount'],
              'status': 'מוכן לאישור',
              'date': _formatDate(DateTime.now()),
              'items': List<Map<String, dynamic>>.from(deal['items']),
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('הדיל נוסף להזמנות בתהליך')),
          );
          setState(() => _selectedIndex = 2);
        },
      ),
      _OrdersPage(
        orders: _pastOrders,
        cartItems: cartItems,
        dealOrders: _dealOrders,
        onDecrease: (name) {
          final current = _cartQuantities[name] ?? 0;
          if (current <= 0) return;
          setState(() => _cartQuantities[name] = current - 1);
        },
        onIncrease: (name) {
          final current = _cartQuantities[name] ?? 0;
          if (current >= 10) return;
          setState(() => _cartQuantities[name] = current + 1);
        },
        onConfirmOrder: () {
          if (!hasActiveOrder) return;
          final total = cartItems.fold<int>(
            0,
            (sum, item) =>
                sum + ((_parsePrice(item['price'] ?? '0')) * (int.tryParse(item['quantity'] ?? '0') ?? 0)),
          );
          setState(() {
            final purchasedItems = cartItems
                .map(
                  (item) => {
                    'name': item['name']!,
                    'quantity': item['quantity']!,
                    'price': item['price']!,
                  },
                )
                .toList();
            for (final dealOrder in _dealOrders) {
              _pastOrders.insert(0, {
                'id': '#${1100 + _pastOrders.length + 1}',
                'date': _formatDate(DateTime.now()),
                'total': dealOrder['total'],
                'status': 'הושלמה (דיל)',
                'progress': 1.0,
                'items': List<Map<String, dynamic>>.from(dealOrder['items'] as List),
              });
            }
            if (purchasedItems.isNotEmpty) {
            _pastOrders.insert(0, {
              'id': '#${1100 + _pastOrders.length + 1}',
              'date': _formatDate(DateTime.now()),
              'total': '$total₪',
              'status': 'הושלמה',
              'progress': 1.0,
              'items': purchasedItems,
            });
            }
            _cartQuantities.clear();
            _dealOrders.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ההזמנה אושרה בהצלחה!')),
          );
        },
        onRepeatOrder: (order) {
          final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          setState(() {
            _cartQuantities.clear();
            for (final item in items) {
              final name = item['name']?.toString();
              final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
              if (name != null && qty > 0) {
                _cartQuantities[name] = qty.clamp(0, 10);
              }
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('הזמנה חוזרת נוספה להזמנות בתהליך')),
          );
        },
      ),
      _CatalogPage(
        products: _products,
        drinks: _drinks,
        quantities: _cartQuantities,
        onSetQuantity: (name, quantity) {
          setState(() {
            _cartQuantities[name] = quantity.clamp(0, 10);
          });
        },
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('מאפיית הבית'),
          centerTitle: true,
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.local_offer), label: 'מבצעים'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'הזמנות'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'הגדרות ועזרה'),
            NavigationDestination(icon: Icon(Icons.storefront), label: 'קטלוג'),
          ],
        ),
      ),
    );
  }
}

class _CatalogPage extends StatelessWidget {
  const _CatalogPage({required this.products});

  final List<Map<String, String>> products;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...products.map(
          (item) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.cake)),
              title: Text(item['name']!),
              subtitle: Text(item['category']!),
              trailing: Text(
                item['price']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DealsPage extends StatelessWidget {
  const _DealsPage({required this.deals, required this.onRedeemDeal});

  final List<Map<String, dynamic>> deals;
  final void Function(Map<String, dynamic> deal) onRedeemDeal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'מבצעים ודילים',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...deals.map(
          (deal) => Card(
            color: Colors.orange.shade50,
            child: ListTile(
              leading: const Icon(Icons.discount, color: Colors.deepOrange),
              title: Text(deal['title']!),
              subtitle: Text('${deal['desc']!}\nתוקף: ${deal['valid']!}'),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrdersPage extends StatefulWidget {
  const _OrdersPage({
    required this.orders,
    required this.cartItems,
    required this.dealOrders,
    required this.onDecrease,
    required this.onIncrease,
    required this.onConfirmOrder,
    required this.onRepeatOrder,
  });

  final List<Map<String, dynamic>> orders;
  final List<Map<String, String>> cartItems;
  final List<Map<String, dynamic>> dealOrders;
  final void Function(String name) onDecrease;
  final void Function(String name) onIncrease;
  final VoidCallback onConfirmOrder;
  final void Function(Map<String, dynamic> order) onRepeatOrder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'העגלה שלך',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (cartItems.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.shopping_cart_outlined),
              title: Text('העגלה ריקה'),
              subtitle: Text('הוסף מוצרים מהקטלוג כדי לבצע הזמנה'),
            ),
          ),
        ...cartItems.map(
          (item) => Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Text(item['emoji'] ?? '🥖', style: const TextStyle(fontSize: 24)),
              title: Text(item['name']!),
              subtitle: Text('${item['price']}'),
              trailing: SizedBox(
                width: 106,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => onDecrease(item['name']!),
                      borderRadius: BorderRadius.circular(12),
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(Icons.remove, size: 14),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          item['quantity']!,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onIncrease(item['name']!),
                      borderRadius: BorderRadius.circular(12),
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(Icons.add, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (cartItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onConfirmOrder,
              icon: const Icon(Icons.check_circle),
              label: const Text('אישור לביצוע ההזמנה'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'פאנל הזמנות',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('היסטוריית הזמנות ומעקב משלוחים בזמן אמת'),
        const SizedBox(height: 14),
        ...orders.map(
          (order) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(order['total']),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('תאריך: ${order['date']}'),
                  const SizedBox(height: 4),
                  Text('סטטוס משלוח: ${order['status']}'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: order['progress']),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsHelpPage extends StatelessWidget {
  const _SettingsHelpPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        Text(
          'הגדרות',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: Icon(Icons.notifications_active),
            title: Text('התראות'),
            subtitle: Text('קבלת עדכוני מבצעים ומשלוחים'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.location_on),
            title: Text('כתובת משלוח'),
            subtitle: Text('רחוב הדוגמה 12, תל אביב'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('מרכז עזרה'),
            subtitle: Text('שאלות נפוצות, יצירת קשר ותמיכה'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.phone),
            title: Text('יצירת קשר'),
            subtitle: Text('050-1234567 | bakery@example.com'),
          ),
        ),
      ],
    );
  }
}
