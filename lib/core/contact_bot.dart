class ContactBot {
  const ContactBot._();

  static String? reply(String input, bool hebrew) {
    final text = input.toLowerCase().trim();
    if (text.isEmpty) return null;

    bool hasAny(Iterable<String> keys) => keys.any(text.contains);

    if (hasAny(['שעות', 'hour', 'open', 'פתוח', 'סגור', 'close'])) {
      return hebrew
          ? 'שעות הפעילות: א׳-ה׳ 07:00-21:00, שישי עד 14:00.'
          : 'Hours: Sun–Thu 07:00–21:00, Fri until 14:00.';
    }
    if (hasAny(['משלוח', 'delivery', 'זמן', 'time', 'מתי'])) {
      return hebrew
          ? 'זמן משלוח ממוצע: 45–90 דקות, תלוי באזור ובעומס.'
          : 'Average delivery: 45–90 minutes, depending on area and load.';
    }
    if (hasAny(['תשלום', 'pay', 'payment', 'ביט', 'מזומן', 'cash', 'אשראי', 'card'])) {
      return hebrew
          ? 'אפשר לשלם באשראי, ביט או מזומן לשליח.'
          : 'You can pay by card, Bit, or cash to the courier.';
    }
    if (hasAny(['הזמנה', 'order', 'עגלה', 'cart', 'מעקב'])) {
      return hebrew
          ? 'ניתן לעקוב אחרי ההזמנה בלשונית הזמנות באפליקציה.'
          : 'Track your order in the Orders tab in the app.';
    }
    if (hasAny(['דיל', 'מבצע', 'deal', 'הנחה', 'discount'])) {
      return hebrew
          ? 'כל הדילים מופיעים בלשונית מבצעים. לאחר מימוש דיל הוא יעבור לעגלה.'
          : 'All deals are in the Deals tab. After redeeming, items go to your cart.';
    }
    if (hasAny(['תפריט', 'menu', 'מאפה', 'bakery', 'שתייה', 'drink', 'קפה', 'coffee'])) {
      return hebrew
          ? 'התפריט המלא נמצא בלשונית קטלוג — מאפים ושתייה.'
          : 'The full menu is in the Menu tab — bakery and drinks.';
    }
    if (hasAny(['החזר', 'refund', 'ביטול', 'cancel'])) {
      return hebrew
          ? 'לביטול או החזר, פנו אלינו בטופס יצירת קשר או למנהל.'
          : 'For cancellation or refund, contact us via the form or manager.';
    }
    if (hasAny(['כשר', 'gluten', 'אלרג', 'allerg'])) {
      return hebrew
          ? 'לשאלות על רכיבים ואלרגנים, כתבו לנו ונחזור עם פירוט מדויק.'
          : 'For ingredients and allergens, message us and we will reply with details.';
    }

    return null;
  }
}
