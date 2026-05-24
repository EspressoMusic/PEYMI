import 'legal_config.dart';

/// Platform-operator legal summaries for the manager panel (template — lawyer review required).
abstract final class PlatformLegalNotice {
  static bool he(bool? force) => force ?? false; // callers pass AppLocale.instance.isHebrew

  static String managerPageTitle(bool hebrew) =>
      hebrew ? 'הגנה משפטית — מפעיל הפלטפורמה' : 'Legal protection — platform operator';

  static String managerPageSubtitle(bool hebrew) => hebrew
      ? 'Peymiz / Bizmi הוא מספק טכנולוגיה בלבד, לא המוכר. קראו בעיון.'
      : 'Peymiz / Bizmi is a technology provider only, not the seller. Read carefully.';

  static String fraudDisclaimer(bool hebrew) => hebrew
      ? '''⚠️ אין לנו אחריות על הונאות שנגרמות ממוכרים

Peymiz (Bizmi) אינו צד לעסקה בין לקוח לבעל עסק. איננו בודקים, מאשרים או מערבים אחריות לכל מוכר, מוצר, שירות, מחיר, משלוח, פגישה או תשלום.

אם מוכר הונא, מטעה, לא מספק, גובה שלא כדין או מפר חוק — האחריות המלאה חלה על אותו מוכר בלבד, לא על מפעיל הפלטפורמה.

אנו רשאים (אך לא חייבים) להשעות חשבון חשוד. דיווח על חשד להונאה: ${LegalConfig.supportEmail}'''
      : '''⚠️ We have no liability for fraud caused by sellers

Peymiz (Bizmi) is not a party to transactions between customers and business owners. We do not verify, endorse, or guarantee any seller, product, service, price, delivery, appointment, or payment.

If a seller commits fraud, misrepresentation, non-delivery, overcharging, or illegal conduct — full responsibility lies with that seller alone, not the platform operator.

We may (but are not required to) suspend suspicious accounts. Report suspected fraud: ${LegalConfig.supportEmail}''';

  static List<String> exposureAreas(bool hebrew) => hebrew
      ? [
          'הונאות, תרמיות ומכירות מטעות על ידי מוכרים',
          'אי-אספקה, איכות ירודה, ביטולים והחזרים — בין לקוח למוכר',
          'תשלומים, חיובים, chargebacks ומחלוקות כספיות (בפיילוט: תשלום ישיר לעסק)',
          'הפרות חוק הגנת הצרכות, מיסוי, רישוי ותקנות מקצועיות של המוכר',
          'תוכן מפר (זכויות יוצרים, סימן מסחר) שמוכרים מפרסמים',
          'טיפול בנתונים אישיים של לקוחות — חובות המוכר כ"ב controller" כלפי לקוחותיו',
          'פגישות/תורים שלא התקיימו, איחורים או ביטולים',
          'ביקורות, הודעות ותקשורת בין משתמשים',
          'תביעות צד שלישי בגין פעילות מוכר בפלטפורמה',
        ]
      : [
          'Fraud, scams, and misrepresentation by sellers',
          'Non-delivery, poor quality, cancellations, and refunds — between customer and seller',
          'Payments, charges, chargebacks, and money disputes (pilot: pay seller directly)',
          'Seller violations of consumer law, tax, licensing, and sector regulations',
          'Infringing content (copyright, trademarks) posted by sellers',
          'Customer personal data — seller duties as controller toward their customers',
          'Missed, late, or cancelled appointments',
          'Reviews, messages, and user-generated content',
          'Third-party claims arising from a seller\'s use of the platform',
        ];

  static List<String> operatorProtections(bool hebrew) => hebrew
      ? [
          'מעמד "פלטפורמה" / מתווך טכנולוגי — לא מוכר ולא ספק השירותים של המוכרים',
          'הצהרת "כמות שהוא" (as is) — ללא אחריות מרומזת לתוכן מוכרים',
          'הגבלת אחריות — ללא נזקים עקיפים; תקרה לנזק ישיר (דמי מנוי או \$100)',
          'שיפוי מבעלי עסק — מוכרים מכסים תביעות הנובעות מפעילותם ותוכנם',
          'זכות להשעיה/הסרה — חשבונות מפרים, חשודים או מסוכנים',
          'סמכות שיפוט — דיני מדינת ישראל (כמפורט בתנאי השימוש)',
          'תנאים מעודכנים — המשך שימוש מהווה הסכמה לגרסה מעודכנת',
        ]
      : [
          'Platform / technology intermediary status — not the seller of listed goods or services',
          '"As is" disclaimer — no implied warranty for seller content or listings',
          'Limitation of liability — no indirect damages; cap on direct damages (fees paid or \$100)',
          'Seller indemnity — businesses cover claims from their conduct and content',
          'Right to suspend/remove — violating, suspicious, or risky accounts',
          'Governing law — State of Israel (see Terms of Use)',
          'Updated terms — continued use may constitute acceptance of new versions',
        ];

  static List<String> sellerDuties(bool hebrew) => hebrew
      ? [
          'איסור הונאה, הטעיה ופעילות בלתי חוקית',
          'דיוק במחירים, מלאי, שעות פגישות ותיאורי שירות',
          'עמידה בדין החל (צרכנות, פרטיות, מיסוי, רישוי)',
          'טיפול בפניות, תלונות והחזרים של לקוחותיכם',
          'פרסום תקנון חנות ברור ללקוחות',
        ]
      : [
          'No fraud, deception, or illegal activity',
          'Accurate prices, availability, appointment hours, and service descriptions',
          'Compliance with applicable law (consumer, privacy, tax, licensing)',
          'Handling your customers\' complaints, disputes, and refunds',
          'Publishing clear store terms for your customers',
        ];

  static String lawyerNote(bool hebrew) => hebrew
      ? 'מסמך תבנית לפיילוט — אינו ייעוץ משפטי. חובה לעבור אישור עורך דין לפני השקה מסחרית מלאה.'
      : 'Pilot template — not legal advice. Qualified lawyer review required before full commercial launch.';
}
