import 'app_locale.dart';

class CatalogData {
  static String name(Map<String, String> item) =>
      AppLocale.instance.isHebrew ? item['nameHe']! : item['nameEn']!;

  static String subtitle(Map<String, String> item) =>
      AppLocale.instance.isHebrew ? item['subtitleHe']! : item['subtitleEn']!;

  static String dealField(Map<String, dynamic> deal, String field) =>
      AppLocale.instance.isHebrew ? deal['${field}He'] as String : deal['${field}En'] as String;

  static int? dealExpiresAtMs(Map<String, dynamic> deal) {
    final raw = deal['expiresAtMs'];
    if (raw == null) return null;
    return raw is int ? raw : (raw as num).toInt();
  }

  static bool isDealExpired(Map<String, dynamic> deal) {
    final expires = dealExpiresAtMs(deal);
    if (expires == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= expires;
  }

  static String validUntilLabel(int expiresAtMs, {required bool hebrew}) {
    final d = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
    if (hebrew) return '${d.day}.${d.month}.${d.year}';
    return '${d.month}/${d.day}/${d.year}';
  }

  /// Match order line name (Hebrew or English) to catalog image/emoji.
  static ({String image, String emoji})? visualForLineName(String lineName) {
    final trimmed = lineName.trim();
    if (trimmed.isEmpty) return null;
    for (final item in [...products, ...drinks]) {
      if (item['nameHe'] == trimmed || item['nameEn'] == trimmed) {
        return (image: item['image']!, emoji: item['emoji'] ?? '🥖');
      }
    }
    return null;
  }

  static List<Map<String, String>> get products => const [
        {
          'id': 'burekas',
          'nameHe': 'בורקס',
          'nameEn': 'Bourekas',
          'subtitleHe': 'אפוי במקום',
          'subtitleEn': 'Fresh from the oven',
          'price': '18₪',
          'image': 'assets/images/products/burekas.png',
          'emoji': '🥟',
        },
        {
          'id': 'croissant',
          'nameHe': 'קוראסון',
          'nameEn': 'Croissant',
          'subtitleHe': 'חמאתי ופריך',
          'subtitleEn': 'Buttery and flaky',
          'price': '16₪',
          'image': 'assets/images/products/קוראסון.png',
          'emoji': '🥐',
        },
        {
          'id': 'personal_pizza',
          'nameHe': 'פיצה אישית',
          'nameEn': 'Personal pizza',
          'subtitleHe': 'עם גבינה ורוטב ביתי',
          'subtitleEn': 'With cheese and house sauce',
          'price': '29₪',
          'image': 'assets/images/products/פיצה.png',
          'emoji': '🍕',
        },
        {
          'id': 'personal_cake',
          'nameHe': 'עוגה אישית',
          'nameEn': 'Personal cake',
          'subtitleHe': 'קינוח אישי לבחירה',
          'subtitleEn': 'Pick your dessert',
          'price': '24₪',
          'image': 'assets/images/products/עוגה אישית.png',
          'emoji': '🍰',
        },
      ];

  static List<Map<String, String>> get drinks => const [
        {
          'id': 'coffee',
          'nameHe': 'קפה',
          'nameEn': 'Coffee',
          'subtitleHe': 'אספרסו או הפוך',
          'subtitleEn': 'Espresso or latte',
          'price': '12₪',
          'image': 'assets/images/products/קפה.png',
          'emoji': '☕',
        },
        {
          'id': 'mint_tea',
          'nameHe': 'תה נענע',
          'nameEn': 'Mint tea',
          'subtitleHe': 'חליטה טרייה',
          'subtitleEn': 'Fresh brew',
          'price': '10₪',
          'image': 'assets/images/products/mint_tea.png',
          'emoji': '🍵',
        },
        {
          'id': 'lemon_soda',
          'nameHe': 'סודה לימון',
          'nameEn': 'Lemon soda',
          'subtitleHe': 'מרענן עם לימון',
          'subtitleEn': 'Refreshing with lemon',
          'price': '11₪',
          'image': 'assets/images/products/סודה.png',
          'emoji': '🥤',
        },
        {
          'id': 'house_shake',
          'nameHe': 'שייק הבית',
          'nameEn': 'House shake',
          'subtitleHe': 'פירות העונה',
          'subtitleEn': 'Seasonal fruit',
          'price': '19₪',
          'image': 'assets/images/products/מילקשייק.png',
          'emoji': '🧋',
        },
      ];

  static List<Map<String, dynamic>> get deals {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    return [
        {
          'id': 'pizza_soda',
          'titleHe': 'דיל פיצה + סודה',
          'titleEn': 'Pizza + soda deal',
          'descHe': 'פיצה אישית וסודה לימון במחיר מיוחד',
          'descEn': 'Personal pizza and lemon soda at a special price',
          'validHe': 'יום שישי',
          'validEn': 'Fridays',
          'priceAfterDiscount': '35₪',
          'images': ['assets/images/products/פיצה.png', 'assets/images/products/סודה.png'],
          'items': [
            {'id': 'personal_pizza', 'quantity': '1', 'price': '29₪'},
            {'id': 'lemon_soda', 'quantity': '1', 'price': '11₪'},
          ],
        },
        {
          'id': 'coffee_cake',
          'titleHe': 'קפה ועוגה אישית',
          'titleEn': 'Coffee & cake combo',
          'descHe': 'קומבו מתוק לבוקר עם הנחה',
          'descEn': 'Sweet morning combo with a discount',
          'validHe': 'כל השבוע',
          'validEn': 'All week',
          'priceAfterDiscount': '30₪',
          'images': ['assets/images/products/קפה.png', 'assets/images/products/עוגה אישית.png'],
          'items': [
            {'id': 'coffee', 'quantity': '1', 'price': '12₪'},
            {'id': 'personal_cake', 'quantity': '1', 'price': '24₪'},
          ],
        },
        {
          'id': 'croissant_tea',
          'titleHe': 'קוראסון + תה נענע',
          'titleEn': 'Croissant + mint tea',
          'descHe': 'נשנוש מפנק עם חליטה חמה',
          'descEn': 'Treat with a hot infusion',
          'validHe': validUntilLabel(endOfMonth.millisecondsSinceEpoch, hebrew: true),
          'validEn': validUntilLabel(endOfMonth.millisecondsSinceEpoch, hebrew: false),
          'expiresAtMs': endOfMonth.millisecondsSinceEpoch,
          'priceAfterDiscount': '22₪',
          'images': ['assets/images/products/קוראסון.png', 'assets/images/products/mint_tea.png'],
          'items': [
            {'id': 'croissant', 'quantity': '1', 'price': '16₪'},
            {'id': 'mint_tea', 'quantity': '1', 'price': '10₪'},
          ],
        },
      ];
  }

  static Map<String, String>? findById(String id) {
    for (final item in [...products, ...drinks]) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  static String nameForId(String id) {
    final item = findById(id);
    if (item != null) return name(item);
    return id;
  }
}
