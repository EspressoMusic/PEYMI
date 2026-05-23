import 'legal_config.dart';

/// Full privacy policy & terms (template — have a lawyer review before production).
abstract final class LegalDocuments {
  static String privacyAndTermsCustomer(bool he) => he ? _buildCustomerHe() : _buildCustomerEn();

  static String privacyAndTermsOwner(bool he) {
    final base = privacyAndTermsCustomer(he);
    if (he) {
      return '''$base

תוספות לבעל עסק:
• אתם אחראים לעיבוד נתוני לקוחות, עמידה בחוק הגנת הפרטיות ומתן מענה לפניות.
• מפעיל האפליקציה רשאי להשהות/לסגור חנות באי-תשלום מנוי או הפרת תנאים.
• תוכן שתפרסמו (מוצרים, מבצעים, הודעות) באחריותכם בלבד.
• יצירת קשר למפעיל: ${LegalConfig.operatorEmail}''';
    }
    return '''$base

Additional owner terms:
• You are responsible for customer data processing and privacy law compliance.
• The operator may suspend stores for unpaid subscription or terms violations.
• You are solely responsible for products, deals, and announcements you publish.
• Operator contact: ${LegalConfig.operatorEmail}''';
  }

  static String _buildCustomerHe() {
    final biz = LegalConfig.businessDisplayName(true);
    return '''
מדיניות פרטיות ותנאי שימוש — $biz
עודכן: מאי 2026 | גרסה 2

חלק א׳ — מדיניות פרטיות
1. מי אנחנו: מפעיל האפליקציה (${LegalConfig.operatorEmail}) ועסק $biz שאליו מזמינים.
2. מידע שנאסף: שם, טלפון, כתובת/אזור משלוח (אם רלוונטי), פרטי הזמנה, תשלום (דרך ספק חיצוני), העדפות שפה ונגישות, חוות דעת ופניות.
3. מטרות: מתן שירות הזמנה, תמיכה, שיפור האפליקציה, עמידה בדין.
4. שיתוף: נתוני הזמנה מועברים לעסק הרלוונטי; לא נמכור מידע לצד שלישי ללא הסכמה, למעט ספקי תשתית (אחסון, תשלום) תחת התחייבות סודיות.
5. אבטחה: אמצעים סבירים להגנה על המידע; אין אבטחה מוחלטת ברשת.
6. שמירה: כל עוד נדרש לשירות, חשבונאות או דין.
7. זכויותיכם: עיון, תיקון, מחיקה (בכפוף לדין) — פנו לעסק או ל-${LegalConfig.operatorEmail}.
8. קטינים: השירות אינו מיועד למי שמתחת לגיל 18 ללא אישור הורה.
9. שינויים: עדכון במסמך זה; שימוש מתמשך מהווה הסכמה לגרסה המעודכנת.

חלק ב׳ — תנאי שימוש
1. הסכמה: הורדה/שימוש באפליקציה מהווים הסכמה לתנאים אלה.
2. שימוש מותר: הזמנות אישיות, מידע מדויק, איסור שימוש לרמאות או הפרת דין.
3. מחירים ומלאי: כפופים לעסק; טעויות במחיר רשאיות העסק לתקן.
4. ביטולים והחזרים: לפי מדיניות העסק; פנו לעסק או ליצירת קשר באפליקציה.
5. אחריות: השירות ניתן "כמות שהוא"; האחריות המקסימלית של המפעיל מוגבלת כדין.
6. קניין רוחני: עיצוב, לוגו ותוכן האפליקציה שמורים למפעיל/עסק.
7. סמכות שיפוט: דיני מדינת ישראל (יש לעדכן סמכות שיפוט עם עו״ד).
8. יצירת קשר: ${LegalConfig.operatorEmail}

הערה: מסמך תבנית — מומלץ אישור עו״ד לפני פרסום סופי.''';
  }

  static String _buildCustomerEn() {
    final biz = LegalConfig.businessDisplayName(false);
    return '''
Privacy Policy & Terms of Use — $biz
Updated: May 2026 | Version 2

Part A — Privacy Policy
1. Who we are: the app operator (${LegalConfig.operatorEmail}) and the business you order from.
2. Data collected: name, phone, delivery area (if applicable), order details, payment (via third party), language/accessibility preferences, reviews and inquiries.
3. Purposes: fulfilling orders, support, improving the app, legal compliance.
4. Sharing: order data goes to the relevant business; we do not sell data without consent, except infrastructure providers under confidentiality.
5. Security: reasonable safeguards; no absolute security online.
6. Retention: as needed for service, accounting, or law.
7. Your rights: access, correction, deletion (subject to law) — contact the business or ${LegalConfig.operatorEmail}.
8. Minors: not intended for under-18 without parental consent.
9. Changes: updates posted here; continued use means acceptance.

Part B — Terms of Use
1. Acceptance: downloading/using the app means you agree.
2. Permitted use: personal orders, accurate information, no fraud or illegal use.
3. Prices/stock: set by the business; pricing errors may be corrected.
4. Cancellations/refunds: per business policy; contact via the app.
5. Liability: service provided "as is"; operator liability limited as permitted by law.
6. IP: app design and content belong to operator/business.
7. Governing law: Israel (confirm venue with counsel).
8. Contact: ${LegalConfig.operatorEmail}

Note: template text — have legal counsel review before production.''';
  }
}
