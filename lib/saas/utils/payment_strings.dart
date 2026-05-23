import '../../core/app_locale.dart';

/// Customer-to-business payment copy (pilot — manual / external only).
abstract final class PaymentStrings {
  static bool get isHebrew => AppLocale.instance.isHebrew;

  static String get paymentSettingsTitle => isHebrew ? 'הגדרות תשלום' : 'Payment Settings';

  static String get pilotDisclaimer => isHebrew
      ? 'בפיילוט, התשלום מתבצע ישירות בין הלקוח לבעל העסק. Peymiz לא מעבדת ולא מחזיקה כספים.'
      : 'During the pilot, payments are handled directly between the customer and the business. Peymiz does not process or hold funds.';

  static String get optionDisabled => isHebrew ? 'ללא תשלום מקוון' : 'No online payment';

  static String get optionManual => isHebrew ? 'תשלום ישיר לעסק' : 'Pay directly to business';

  static String get optionExternalLink => isHebrew ? 'קישור תשלום חיצוני' : 'External payment link';

  static String get optionPayOnArrival => isHebrew ? 'תשלום בהגעה / במקום' : 'Pay on arrival / in person';

  static String get optionCashDelivery => isHebrew ? 'מזומן / תשלום במסירה' : 'Cash / pay on delivery';

  static String get paymentInstructionsLabel =>
      isHebrew ? 'הוראות תשלום ללקוח' : 'Payment instructions for customers';

  static String get externalLinkLabel => isHebrew ? 'קישור תשלום חיצוני' : 'External payment link';

  static String get paymentPhoneLabel => isHebrew ? 'טלפון לתשלום' : 'Payment phone number';

  static String get currencyLabel => isHebrew ? 'מטבע' : 'Currency';

  static String get saveSettings => isHebrew ? 'שמירת הגדרות' : 'Save settings';

  static String get settingsSaved => isHebrew ? 'הגדרות התשלום נשמרו' : 'Payment settings saved';

  static String get orderSuccessTitle =>
      isHebrew ? 'ההזמנה נשלחה בהצלחה' : 'Your order was sent successfully';

  static String get appointmentSuccessTitle =>
      isHebrew ? 'התור נקבע בהצלחה' : 'Your appointment was booked successfully';

  static String get payBusinessHint => isHebrew
      ? 'אנא שלמו ישירות לעסק לפי ההוראות למטה.'
      : 'Please pay the business directly using the instructions below.';

  static String get payNow => isHebrew ? 'לתשלום' : 'Pay Now';

  static String paymentPhone(String phone) =>
      isHebrew ? 'טלפון לתשלום: $phone' : 'Payment phone: $phone';

  static String get close => isHebrew ? 'סגירה' : 'Close';

  static String modeLabel(String mode) => switch (mode) {
        'external_link' => optionExternalLink,
        'cash_on_delivery' => optionCashDelivery,
        'pay_on_arrival' => optionPayOnArrival,
        'future_provider' => isHebrew ? 'ספק תשלום (בקרוב)' : 'Payment provider (coming soon)',
        _ => optionManual,
      };
}
