import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'faq_store.dart';

import 'safe_change_notifier.dart';

class AppLocale extends ChangeNotifier with SafeChangeNotifier {
  AppLocale._();

  static final AppLocale instance = AppLocale._();
  static const _prefKey = 'app_language_hebrew';

  bool _hebrew = false;

  bool get isHebrew => _hebrew;
  bool get isEnglish => !_hebrew;
  TextDirection get direction => _hebrew ? TextDirection.rtl : TextDirection.ltr;

  AppStrings get s => AppStrings(_hebrew);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hebrew = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> setHebrew(bool value) async {
    if (_hebrew == value) return;
    _hebrew = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  Future<void> toggleLanguage() => setHebrew(!_hebrew);
}

class AppStrings {
  const AppStrings(this._he);

  final bool _he;

  String get appTitle => 'Peymiz';
  String get navSettings => _he ? 'הגדרות' : 'Settings';
  String get navDeals => _he ? 'מבצעים' : 'Deals';
  String get navOrders => _he ? 'הזמנות' : 'Orders';
  String get navCatalog => _he ? 'קטלוג' : 'Menu';
  String get navAppointments => _he ? 'תורים' : 'Appointments';
  String get navMyAppointments => _he ? 'התורים שלי' : 'My bookings';
  String get navServices => _he ? 'שירותים' : 'Services';
  String get customerNoAppointments => _he
      ? 'אין תורים שמורים עדיין.\nקבעו תור בלשונית "תורים".'
      : 'No appointments yet.\nBook one in the Appointments tab.';
  String get customerServicesTitle => _he ? 'על העסק' : 'About the business';
  String get customerServicesList => _he ? 'שירותים' : 'Services';
  String get customerNoServices => _he
      ? 'אין שירותים רשומים כרגע. פנו לעסק לפרטים.'
      : 'No services listed yet. Contact the business for details.';
  String get managerStoreModeMenuHint => _he
      ? 'משנה את לשונית התפריט באפליקציה. אם מחוברים לחנות אונליינית — גם את הקישור הציבורי.'
      : 'Changes the app menu tab. When signed in to your online store, the public link updates too.';
  String managerStoreModeLocalOnly(String label) => _he
      ? 'עודכן בתפריט: $label. לסנכרון לקישור האינטרנט: הגדרות → יצירת חנות (פעם אחת).'
      : 'Menu updated: $label. For public link sync: Settings → Create Store (once).';
  String get managerStoreModeUpdatedTitle => _he ? 'עודכן!' : 'Updated!';
  String get managerAppointmentsNeedLink => _he
      ? 'כדי להציג יומן תורים, קשרו חנות אונליינית: הגדרות → יצירת חנות.\n(או ודאו שחנות הדמו shilo קיימת בשרת)'
      : 'To show the appointment calendar, link your online store: Settings → Create Store.\n(Ensure demo store "shilo" exists on the server)';
  String demoStoreBanner(String slug) =>
      _he ? 'חנות דמו: $slug' : 'Demo store: $slug';

  String get managerLoginTitle => _he ? 'כניסת מנהל' : 'Manager login';
  String get managerStoreNameLabel => _he ? 'שם החנות' : 'Store name';
  String get managerStoreNameRequired => _he ? 'נא להזין שם חנות' : 'Please enter store name';
  String get managerRememberPassword => _he ? 'זכור סיסמה במכשיר' : 'Remember password on this device';
  String get managerRememberEmail => _he ? 'זכור אימייל' : 'Remember email';
  String get managerForgotPassword => _he ? 'שכחתי סיסמה' : 'Forgot password';
  String get managerChangePinButton => _he ? 'שינוי סיסמת מנהל' : 'Change manager password';
  String get managerChangePinTitle => _he ? 'שינוי סיסמת מנהל' : 'Change manager password';
  String get managerChangePinHint => _he
      ? 'סיסמה לכניסה לפאנל המנהל באפליקציה — לא סיסמת מייל. נדרש חשבון בעל החנות.'
      : 'Password for the in-app manager panel — not your email password. Store owner account required.';
  String get managerOwnerAccountEmail => _he ? 'אימייל בעל החנות' : 'Store owner email';
  String get managerOwnerAccountPassword => _he ? 'סיסמת חשבון בעלים' : 'Owner account password';
  String get managerPinChangedTitle => _he ? 'סיסמת המנהל עודכנה!' : 'Manager password updated!';
  String get managerPinChangedSub => _he
      ? 'אפשר להיכנס לפאנל עם הסיסמה החדשה.'
      : 'You can sign in to the panel with the new password.';
  String get managerChangePinNotOwner => _he
      ? 'החנות לא נמצאה או שאינך הבעלים'
      : 'Store not found or you are not the owner';
  String get managerForgotPasswordTitle => _he ? 'שחזור סיסמת חשבון' : 'Account password recovery';
  String get managerForgotPasswordHint => _he
      ? 'קישור לאיפוס סיסמת חשבון Supabase (בעלים) — לא סיסמת מנהל באפליקציה.'
      : 'Resets your Supabase owner account password — not the in-app manager panel PIN.';
  String get managerResetSend => _he ? 'שליחת קישור' : 'Send reset link';
  String get managerResetByEmail => _he ? 'שחזור סיסמה במייל' : 'Reset password by email';
  String get managerResetSending => _he ? 'שולח…' : 'Sending…';
  String get managerResetEmailSent => _he
      ? 'נשלח מייל עם קישור לאיפוס. בדקו גם בתיקיית הספאם.'
      : 'Reset email sent. Check your inbox and spam folder.';
  String get managerResetInvalidEmail => _he ? 'כתובת המייל שגויה' : 'Invalid email address';
  String get managerPinChooseLabel => _he ? 'סיסמת מנהל *' : 'Manager password *';
  String get managerPinConfirmLabel => _he ? 'אימות סיסמת מנהל *' : 'Confirm manager password *';
  String get managerPinChooseHint => _he
      ? 'סיסמה זו לכניסה לפאנל המנהל (לפחות 4 תווים).'
      : 'Used for manager panel login (at least 4 characters).';
  String get managerPinTooShort => _he ? 'סיסמת מנהל: לפחות 4 תווים' : 'Manager password: at least 4 characters';
  String get managerPinMismatch => _he ? 'סיסמאות המנהל לא תואמות' : 'Manager passwords do not match';
  String get managerLoginNotConfigured => _he
      ? 'כניסת מנהל לא מוגדרת — צרו חנות אונליין או הגדירו MANAGER_PIN'
      : 'Manager login is not configured — create an online store or set MANAGER_PIN';
  String get managerLoginStoreChoiceTitle =>
      _he ? 'איזו חנות לנהל?' : 'Which store to manage?';
  String get managerLoginStoreChoiceHint => _he
      ? 'פתחו חנות חדשה או התחברו לחנות שכבר קיימת'
      : 'Open a new store or connect to one that already exists';
  String get managerLoginOpenStore => _he ? 'לפתוח חנות' : 'Open store';
  String get managerLoginCreateStore => _he ? 'פתיחת חנות חדשה' : 'Open a new store';
  String get managerLoginCreateStoreSub =>
      _he ? 'יצירה וחיבור אונליין' : 'Create and connect online';
  String get managerLoginExistingStore => _he ? 'כניסה לחנות קיימת' : 'Enter existing store';
  String get managerLoginExistingStoreSub =>
      _he ? 'הזנת שם החנות (slug)' : 'Enter your store slug';
  String get managerLoginContinueLinked => _he ? 'המשך לפאנל המנהל' : 'Continue to manager panel';
  String managerLoginContinueLinkedSub(String slug) =>
      _he ? 'חנות מקושרת: $slug' : 'Linked store: $slug';
  String get managerLoginExistingNotFound =>
      _he ? 'חנות לא נמצאה — בדקו את השם (slug)' : 'Store not found — check the slug';
  String get managerLoginLinkedOk => _he ? 'החנות קושרה בהצלחה' : 'Store linked successfully';
  String get employeeLoginTitle => _he ? 'כניסת עובד' : 'Employee login';
  String get employeePasswordHint => _he ? 'הזן סיסמת עובד' : 'Enter employee password';
  String get employeePanel => _he ? 'פאנל עובד' : 'Employee panel';
  String get employeePanelSub => _he ? 'הזמנות וסיכום להכנה' : 'Orders & prep summary';
  String get passwordLabel => _he ? 'סיסמה' : 'Password';
  String get wrongPassword => _he ? 'סיסמה שגויה' : 'Wrong password';
  String get enterPassword => _he ? 'נא להזין סיסמה' : 'Please enter password';
  String get cancel => _he ? 'ביטול' : 'Cancel';
  String get login => _he ? 'כניסה' : 'Log in';

  String get managerPanel => _he ? 'פאנל מנהל' : 'Manager panel';
  String get exit => _he ? 'יציאה' : 'Exit';
  String get managerDashboardSub => _he ? 'סיכום פעילות באפליקציה' : 'App activity summary';
  String get totalOrders => _he ? 'סה״כ הזמנות' : 'Total orders';
  String get totalInquiries => _he ? 'פניות לקוחות' : 'Customer inquiries';
  String get totalReviews => _he ? 'חוות דעת' : 'Reviews';
  String get managerHealthTitle => _he ? 'מד בריאות העסק' : 'Business health';
  String get managerRecentOrders => _he ? 'הזמנות אחרונות' : 'Recent orders';
  String get managerNoOrdersYet => _he ? 'עדיין אין הזמנות' : 'No orders yet';
  String get managerNotifications => _he ? 'התראות' : 'Notifications';
  String get managerMarkAllRead => _he ? 'סימון הכל כנקרא' : 'Mark all read';
  String get managerNoNotifications => _he ? 'אין התראות חדשות' : 'No notifications';
  String get managerPrepSummary => _he ? 'סיכום להכנה' : 'Preparation summary';
  String get managerPrepEmpty => _he ? 'אין פריטים להכנה כרגע' : 'Nothing to prepare yet';
  String get managerApprovePrepDone => _he ? 'אישור' : 'Confirm';
  String get managerAllOrdersApproved => _he ? 'כל ההזמנות אושרו' : 'All orders approved';
  String get managerShareStore => _he ? 'שיתוף החנות' : 'Share your store';
  String get managerShareStoreSub =>
      _he ? 'שתפו את הקישור עם לקוחות' : 'Share the link with customers';
  String get managerShareStoreNoLink =>
      _he ? 'הגדירו חנות כדי לקבל קישור לשיתוף' : 'Set up your store to get a shareable link';
  String get managerShareSetupOnline =>
      _he ? 'חיבור / יצירת חנות אונליינית' : 'Connect or create online store';
  String get managerShareSetupManualSlug =>
      _he ? 'הזנת שם חנות (slug) לשיתוף' : 'Enter store slug to share';
  String get managerShareStoreNoSupabaseTitle =>
      _he ? 'אין קישור לחנות' : 'No store link yet';
  String get managerShareStoreNoSupabaseBody => _he
      ? 'כדי ליצור חנות אונליינית נדרש Supabase — הריצו את האפליקציה עם קובץ .env (למשל tools\\refresh_app.ps1 או flutter run עם --dart-define מ-.env).\n\nאפשר גם להזין שם חנות (באנגלית) לשיתוף קישור מקומי:'
      : 'Creating an online store needs Supabase — run the app with a .env file (e.g. tools/refresh_app.ps1 or flutter run with --dart-define from .env).\n\nOr enter a store slug below to share a link locally:';
  String get managerShareStoreSlugField => _he ? 'שם החנות (slug)' : 'Store slug';
  String get managerShareStoreSlugSave => _he ? 'שמירה ושיתוף' : 'Save & share';
  String get managerShareStoreSupabaseSnack => _he
      ? 'Supabase לא מוגדר — הוסיפו SUPABASE_URL ו-SUPABASE_ANON_KEY (ראו .env.example)'
      : 'Supabase not configured — add SUPABASE_URL and SUPABASE_ANON_KEY (see .env.example)';
  String get managerShareStoreCopy => _he ? 'העתקת קישור' : 'Copy link';
  String get managerShareStoreWhatsApp => _he ? 'וואטסאפ' : 'WhatsApp';
  String get managerShareStoreEmail => _he ? 'אימייל' : 'Email';
  String get managerShareStoreSms => _he ? 'הודעה' : 'SMS';
  String get managerShareStoreTelegram => _he ? 'טלגרם' : 'Telegram';
  String get managerShareStoreFacebook => _he ? 'פייסבוק' : 'Facebook';
  String get managerShareStoreX => _he ? 'X (טוויטר)' : 'X (Twitter)';
  String get managerShareStoreMore => _he ? 'אפליקציות נוספות…' : 'More apps…';
  String get managerShareStoreSheetTitle => _he ? 'שיתוף קישור החנות' : 'Share store link';
  String get managerShareStoreSheetHint =>
      _he ? 'בחרו איך לשלוח את הקישור ללקוחות' : 'Choose how to send the link to customers';
  String get managerShareStoreLaunchFailed =>
      _he ? 'לא ניתן לפתוח את האפליקציה' : 'Could not open the app';
  String managerShareStoreLinkCopied(String link) =>
      _he ? 'הקישור הועתק' : 'Link copied';
  String get linkCopiedBadge => _he ? 'הועתק!' : 'COPIED!';
  String get ownerDashboardNoProducts => _he ? 'אין מוצרים עדיין.' : 'No products yet.';
  String get ownerDashboardGoCatalog => _he ? 'הוספת מוצרים' : 'Add products';
  String get managerPrepUnits => _he ? 'יחידות בסך הכל' : 'Total units';
  String get managerShowOrders => _he ? 'הצג כל ההזמנות' : 'Show all orders';
  String get managerHideOrders => _he ? 'הסתר הזמנות' : 'Hide orders';
  String get managerHealthWhy => _he ? 'למה לא 100%?' : 'Why not 100%?';
  String get managerHealthPerfect => _he ? 'העסק במצב מצוין — 100%' : 'Excellent — 100%';
  String get managerHealthTap => _he ? 'לחצו על העיגול לפירוט' : 'Tap the ring for details';
  String get managerHealthTapIssue =>
      _he ? 'לחצו על העיגול האדום לפתרון הבעיה' : 'Tap a red dot to fix the issue';

  String get appCreatorBannerTitle => _he ? 'פאנל מתכנת' : 'Programmer panel';
  String get appCreatorBannerSub => _he
      ? 'סיסמה סודית בלבד — שליטה מלאה על כל החנויות. לקוחות לא יכולים לגשת לכאן.'
      : 'Secret password only — full control over every store. Customers cannot access this.';
  String get appCreatorPasswordLabel => _he ? 'סיסמת מתכנת' : 'Programmer password';
  String get appCreatorWrongPassword => _he ? 'סיסמה שגויה' : 'Wrong password';
  String get appCreatorEnter => _he ? 'כניסה לפאנל מתכנת' : 'Open programmer panel';
  String get appCreatorDashboardTitle => _he ? 'פאנל מתכנת' : 'Programmer panel';
  String get appCreatorDashboardSub => _he
      ? 'כל החנויות הפתוחות והסגורות — ניהול, נעילה ושליטה מלאה'
      : 'All open and closed stores — manage, lock, and full control';
  String get appCreatorSearch => _he ? 'חיפוש עסק / slug / אימייל' : 'Search business / slug / email';
  String get appCreatorNoBusinesses => _he ? 'אין עסקים רשומים' : 'No businesses yet';
  String get appCreatorStatus => _he ? 'סטטוס' : 'Status';
  String get appCreatorActive => _he ? 'פעיל' : 'Active';
  String get appCreatorInactive => _he ? 'מושהה' : 'Inactive';
  String appCreatorCounts(int products, int orders, int appointments, int customers) => _he
      ? 'לקוחות: $customers · מוצרים: $products · הזמנות: $orders · תורים: $appointments'
      : 'Customers: $customers · Products: $products · Orders: $orders · Appointments: $appointments';
  String get appCreatorLockStore => _he ? 'נעילת חנות' : 'Lock store';
  String get appCreatorStoreDetails => _he ? 'פרטי חנות' : 'Store details';
  String get appCreatorActivate => _he ? 'הפעלה' : 'Activate';
  String get appCreatorSuspend => _he ? 'השהיה' : 'Suspend';
  String get appCreatorTrial => _he ? 'ניסיון' : 'Trial';
  String get appCreatorFilterAll => _he ? 'הכל' : 'All';
  String get appCreatorFilterOpen => _he ? 'פתוחות' : 'Open';
  String get appCreatorFilterPayment => _he ? 'בעיית תשלום' : 'Payment issue';
  String get appCreatorFilterDisabled => _he ? 'מושבתות' : 'Disabled';
  String get appCreatorFullControl => _he ? 'שליטה מלאה — ניהול חנות' : 'Full control — manage store';
  String appCreatorFullControlConfirm(String name) => _he
      ? 'לפתוח את "$name" בפאנל המנהל? תוכל לערוך מוצרים, הגדרות ותשלומים.'
      : 'Open "$name" in the manager panel? You can edit products, settings, and payments.';
  String get appCreatorSetProductsMode => _he ? 'מצב מוצרים' : 'Products mode';
  String get appCreatorSetAppointmentsMode => _he ? 'מצב תורים' : 'Appointments mode';
  String get appCreatorHardLock => _he ? 'חסימה מוחלטת' : 'Hard block';
  String appCreatorHardLockConfirm(String name) => _he
      ? 'לחסום לחלוטין את "$name"? לקוחות לא יוכלו להזמין או לקבוע תור.'
      : 'Hard-block "$name"? Customers will not be able to order or book.';
  String get appCreatorDisableStore => _he ? 'השבת חנות (אי תשלום)' : 'Disable store (non-payment)';
  String get appCreatorReenableStore => _he ? 'החזרת חנות לפעילות' : 'Re-enable store';
  String get appCreatorMarkPastDue => _he ? 'סימון חוב תשלום' : 'Mark payment overdue';
  String get appCreatorStoreOpen => _he ? 'חנות פעילה' : 'Store active';
  String get appCreatorStoreDisabled => _he ? 'חנות מושבתת' : 'Store disabled';
  String get appCreatorPaymentOverdue => _he ? 'חוב תשלום' : 'Payment overdue';
  String get appCreatorStatusTrial => _he ? 'ניסיון' : 'Trial';
  String get appCreatorStatusActive => _he ? 'פעיל' : 'Active';
  String get appCreatorStatusSuspended => _he ? 'מושהה' : 'Suspended';
  String get appCreatorStatusCancelled => _he ? 'מבוטל' : 'Cancelled';
  String get appCreatorDisableConfirmTitle => _he ? 'להשבית את החנות?' : 'Disable this store?';
  String appCreatorDisableConfirmBody(String name) => _he
      ? 'החנות "$name" תושבת — לקוחות לא יוכלו להזמין, ובעל העסק יאבד גישה לפאנל עד שתפעיל מחדש.'
      : 'Store "$name" will be disabled — customers cannot order and the owner loses dashboard access until you re-enable.';
  String get appCreatorReenableConfirmTitle => _he ? 'להפעיל את החנות מחדש?' : 'Re-enable this store?';
  String appCreatorReenableConfirmBody(String name) => _he
      ? 'החנות "$name" תחזור לפעילות מלאה.'
      : 'Store "$name" will be fully active again.';
  String get appCreatorUpdateOk => _he ? 'הסטטוס עודכן' : 'Status updated';
  String get appCreatorUpdateFailed => _he ? 'עדכון נכשל' : 'Update failed';

  String get policyConsentTitle => _he ? 'אישור תקנון' : 'Terms acceptance';
  String get policyConsentSubCustomer => _he
      ? 'לפני השימוש באפליקציה — צפו בסרטון ואשרו את המדיניות.'
      : 'Before using the app — watch the video and accept the policy.';
  String get policyConsentSubOwner => _he
      ? 'לפני ניהול העסק — צפו בסרטון ואשרו את המדיניות.'
      : 'Before managing your business — watch the video and accept the policy.';
  String get policyConsentBannerBeforeTerms => _he
      ? 'לפני השימוש יש לאשר את ה'
      : 'Before using the app you must accept the ';
  String get policyConsentTermsLink => _he ? 'תקנון' : 'terms';
  String get policyConsentBannerAfterTerms => _he
      ? ' — לחצו על המילה לקריאה מלאה.'
      : ' — tap the word to read the full text.';
  String get policyConsentFullTermsTitle => _he ? 'תקנון מלא' : 'Full terms';
  String get policyConsentExitApp => _he ? 'יציאה מהאפליקציה' : 'Exit app';
  String get policyVideoLoading => _he ? 'טוען סרטון מדיניות…' : 'Loading policy video…';
  String get policyVideoPlaceholder => _he
      ? 'סרטון הסבר (ניתן להגדיר POLICY_VIDEO_URL בהרצה)'
      : 'Policy explainer (set POLICY_VIDEO_URL when running)';
  String get policyConsentCheckbox => _he ? 'אני מאשר/ת' : 'I accept';
  String get policyConsentReadFull => _he ? 'קריאת תקנון מלא' : 'Read full terms';
  String get policyConsentAccept => _he ? 'מאשר/ת וממשיך/ה' : 'I accept — continue';
  String get policyConsentBodyCustomer => _he
      ? '''• האפליקציה אוספת שם, טלפון ופרטי הזמנה לצורך מתן השירות.
• הנתונים מועברים לבעל העסק שאליו הזמנתם.
• Peymiz הוא פלטפורמה בלבד — לא המוכר. עסקאות ומחלוקות מול בעל העסק.
• אין אחריות של מפעיל האפליקציה להונאות או התנהגות בלתי חוקית של מוכרים.
• לא נמכור את הנתונים לצד שלישי ללא הסכמתכם.
• שימוש באפליקציה מהווה הסכמה לתנאים אלה.'''
      : '''• The app collects name, phone, and order details to provide the service.
• Data is shared with the business you order from.
• Peymiz is a platform only — not the seller. Transactions and disputes are with the business.
• The app operator is not liable for seller fraud or illegal conduct.
• We do not sell your data to third parties without consent.
• Using the app means you agree to these terms.''';
  String get policyConsentBodyOwner => _he
      ? '''• Peymiz הוא פלטפורמה טכנולוגית — אינכם המוכרים בשם Peymiz.
• אין אחריות של Peymiz להונאות, תרמיות או מחלוקות בין לקוחות לביניכם.
• אתם אחראים לעיבוד נתוני לקוחות, עמידה בדין, ולשיפוי Peymiz מפני תביעות הנובעות מפעילותכם.
• מפעיל האפליקציה רשאי להשעות חנות בהפרת תנאים או חשד להונאה.
• המשך שימוש בפאנל המנהל מהווה הסכמה לתנאים אלה.'''
      : '''• Peymiz is a technology platform — you are not selling on Peymiz's behalf.
• Peymiz is not liable for fraud, scams, or disputes between you and your customers.
• You are responsible for customer data, legal compliance, and indemnifying Peymiz for claims from your conduct.
• The operator may suspend stores for Terms violations or suspected fraud.
• Continuing to use the manager panel means you accept these terms.''';

  String get managerOrderLines => _he ? 'פירוט הזמנה' : 'Order breakdown';

  String get managerNavDashboard => _he ? 'ראשי' : 'Home';
  String get managerNavActions => _he ? 'פעולות' : 'Actions';
  String get managerNavSettings => _he ? 'הגדרות' : 'Settings';
  String get managerActionsSub => _he ? 'ניהול החנות והלקוחות' : 'Manage store & customers';
  String get managerActionCustomers => _he ? 'מענה ללקוחות' : 'Customer messages';
  String get managerActionCustomersSub =>
      _he ? 'פניות, עדכונים, חוות דעת והמלצות' : 'Inquiries, updates, reviews & ratings';
  String get managerActionUpdate => _he ? 'עדכון ללקוחות' : 'Customer update';
  String get managerActionUpdateSub => _he ? 'הודעה שמופיעה באפליקציה' : 'Message shown in the app';
  String get managerInquiryEmailTitle => _he ? 'מייל לפניות מלקוחות' : 'Customer inquiry email';
  String get managerInquiryEmailHint => _he
      ? 'לקוחות יוכלו לפנות אליך במייל מהאפליקציה. אפשר להוסיף גם אם לא מילאת בפתיחת החנות.'
      : 'Customers can email you from the app. You can add this even if you skipped it when opening the store.';
  String get managerInquiryEmailSaved => _he ? 'מייל לפניות נשמר' : 'Inquiry email saved';
  String get managerInquiryEmailInvalid => _he ? 'נא להזין כתובת מייל תקינה' : 'Enter a valid email address';
  String get contactEmailUnavailable => _he
      ? 'בעל החנות עדיין לא הגדיר מייל לפניות.'
      : 'The store owner has not set an inquiry email yet.';
  String get managerActionNewDeal => _he ? 'דיל / מבצע חדש' : 'New deal';
  String get managerActionNewDealSub => _he ? 'פרסום מבצע בלשונית מבצעים' : 'Publish in Deals tab';
  String get managerActionStoreMode => _he ? 'מצב חנות' : 'Store mode';
  String get managerActionStoreModeSub =>
      _he ? 'מוצרים או פגישות — מה הלקוחות רואים' : 'Products or appointments — customer view';
  String get managerActionStore => _he ? 'ניהול פאנל החנות' : 'Store panel';
  String get managerStoreAppImageTitle => _he ? 'תמונת האפליקציה של העסק' : 'Your store app image';
  String get managerStoreAppImageSub => _he
      ? 'מוצגת לך בפאנל המנהל וללקוחות באפליקציה (הגדרות ותפריט).'
      : 'Shown in your manager panel and to customers in the app (settings & menu).';
  String get managerStoreAppImagePick => _he ? 'בחירת תמונה' : 'Choose image';
  String get managerStoreAppImageRemove => _he ? 'הסרת תמונה' : 'Remove image';
  String get managerStoreAppImageSaved => _he ? 'תמונת האפליקציה נשמרה' : 'App image saved';
  String get managerStoreAppImageCleared => _he ? 'תמונת האפליקציה הוסרה' : 'App image removed';
  String get managerStoreAppImageSyncHint => _he
      ? 'לסנכרון לכל המכשירים: התחברו לחנות אונליינית (Supabase) כבעלים.'
      : 'To sync on all devices: sign in to your online store (Supabase) as owner.';
  String get managerActionStoreSub =>
      _he ? 'מצב חנות, קטלוג, דילים ועדכונים' : 'Store mode, catalog, deals & updates';
  String get managerOnlineStoreSection => _he ? 'חנות אונליינית (קישור ללקוחות)' : 'Online store (public link)';
  String get managerLocalCatalogSection => _he ? 'קטלוג באפליקציה' : 'In-app catalog';
  String get managerOnlineStoreSignIn => _he
      ? 'כדי לבחור בין חנות מוצרים לקביעת תורים, התחברו תחילה: הגדרות → יצירת חנות.'
      : 'To switch between products and appointments, sign in first: Settings → Create Store.';
  String get managerOnlineStoreNoBusiness => _he
      ? 'עדיין אין חנות אונליינית. צרו חנות ב: הגדרות → יצירת חנות.'
      : 'No online store yet. Create one under Settings → Create Store.';
  String get managerOnlineStoreUnavailable => _he
      ? 'חנות אונליינית לא זמינה כרגע (בדקו חיבור לשרת).'
      : 'Online store is unavailable (check server connection).';
  String get managerOnlineStoreConnect => _he ? 'פתיחת חנות אונליינית' : 'Open online store setup';
  String get managerActionStats => _he ? 'סטטיסטיקה' : 'Statistics';
  String get managerActionStatsSub => _he ? 'הכנסות, הזמנות ושביעות רצון' : 'Revenue, orders & satisfaction';
  String get managerActionFaq => _he ? 'שאלות ותשובות' : 'FAQ';
  String get managerActionFaqSub =>
      _he ? 'שאלות נפוצות ותקנון החנות' : 'FAQ & store terms';
  String get managerActionStoreTerms => _he ? 'תקנון החנות' : 'Store terms';
  String get managerActionStoreTermsSub =>
      _he ? 'תנאים והוראות ללקוחות' : 'Rules & policies for customers';
  String get managerStoreTermsTitle => _he ? 'תקנון החנות' : 'Store terms';
  String get managerStoreTermsHint => _he
      ? 'כתבו כאן את התקנון, מדיניות ההחזרות, שעות פעילות מיוחדות וכל מה שלקוחות צריכים לדעת. הטקסט יוצג ללקוחות בהגדרות.'
      : 'Write your store rules, refund policy, special hours, and anything customers should know. Shown to customers in Settings.';
  String get managerStoreTermsField => _he ? 'טקסט התקנון' : 'Terms text';
  String get managerStoreTermsSaved => _he ? 'התקנון נשמר' : 'Terms saved';
  String get managerStoreTermsEmpty => _he ? 'עדיין לא הוגדר תקנון' : 'No terms defined yet';
  String get managerStoreTermsNoStore => _he
      ? 'קשרו חנות (כניסת מנהל) לפני עריכת תקנון'
      : 'Link a store (manager login) before editing terms';
  String get storeTerms => _he ? 'תקנון החנות' : 'Store terms';
  String get storeTermsSub => _he ? 'תנאי השימוש של העסק' : 'This business terms';
  String get managerActionSubscriptions => _he ? 'מנויים' : 'Subscriptions';
  String get managerActionSubscriptionsSub =>
      _he ? 'Premium \$50 · Ultimate \$100' : 'Premium \$50 · Ultimate \$100';
  String get managerSubscriptionsTitle => _he ? 'מסלולי מנוי' : 'Subscription plans';
  String get managerSubscriptionsSub => _he
      ? 'בחרו את המסלול המתאים לעסק שלכם'
      : 'Choose the plan that fits your business';
  String get managerSubscriptionsCurrent => _he ? 'המסלול הנוכחי' : 'Current plan';
  String get managerSubscriptionsNone => _he ? 'ללא מנוי בתשלום' : 'No paid plan';
  String get managerSubscriptionsPremium => 'Premium';
  String get managerSubscriptionsUltimate => 'ULTIMATE';
  String managerSubscriptionsPrice(int usd) => _he ? '\$$usd לחודש' : '\$$usd / month';
  String get managerSubscriptionsSelect => _he ? 'בחירת מסלול' : 'Select plan';
  String get managerSubscriptionsSelected => _he ? 'מסלול פעיל' : 'Active plan';
  String get managerSubscriptionsRecommended => _he ? 'מומלץ' : 'Recommended';
  String get managerSubscriptionsPerMonth => _he ? 'לחודש' : 'per month';
  String get managerSubscriptionsPremiumFeatures => _he
      ? '• חנות אונליינית\n• שיתוף קישור\n• מבצעים והתראות'
      : '• Online store\n• Share store link\n• Deals & alerts';
  String get managerSubscriptionsUltimateFeatures => _he
      ? '• כל Premium\n• יומן תורים\n• אנליטיקה ותמיכה'
      : '• All Premium\n• Appointments\n• Analytics & support';
  String get managerSubscriptionsPaymentNote => _he
      ? 'חיוב לאחר חיבור Stripe · הבחירה נשמרת באפליקציה'
      : 'Billed after Stripe setup · choice saved in app';
  String managerSubscriptionsPlanChosen(String plan) =>
      _he ? 'נבחר מסלול $plan' : 'Selected $plan plan';
  String get managerFaqAdd => _he ? 'הוספת שאלה' : 'Add question';
  String get managerFaqEdit => _he ? 'עריכת שאלה' : 'Edit question';
  String get managerFaqDelete => _he ? 'מחיקה' : 'Delete';
  String get managerFaqDeleteConfirm =>
      _he ? 'למחוק את השאלה הזו?' : 'Delete this question?';
  String get managerFaqQuestion => _he ? 'שאלה' : 'Question';
  String get managerFaqAnswer => _he ? 'תשובה' : 'Answer';
  String get managerFaqQuestionHe => _he ? 'שאלה (עברית)' : 'Question (Hebrew)';
  String get managerFaqAnswerHe => _he ? 'תשובה (עברית)' : 'Answer (Hebrew)';
  String get managerFaqQuestionEn => _he ? 'שאלה (אנגלית)' : 'Question (English)';
  String get managerFaqAnswerEn => _he ? 'תשובה (אנגלית)' : 'Answer (English)';
  String get managerFaqSaved => _he ? 'השאלות נשמרו' : 'FAQ saved';
  String get managerFaqEmpty => _he ? 'אין שאלות עדיין' : 'No questions yet';
  String get managerFaqRequired =>
      _he ? 'מלאו שאלה ותשובה' : 'Fill in the question and answer';
  String get managerStatsWeekly => _he ? 'שבועי' : 'Weekly';
  String get managerStatsMonthly => _he ? 'חודשי' : 'Monthly';
  String get managerStatsYearly => _he ? 'שנתי' : 'Yearly';
  String get managerStatsRevenue => _he ? 'הכנסות' : 'Revenue';
  String get managerStatsGrowing => _he ? 'העסק בצמיחה' : 'Business is growing';
  String get managerStatsDeclining => _he ? 'ירידה בהכנסות' : 'Revenue declining';
  String get managerStatsStable => _he ? 'יציב' : 'Stable';
  String get managerBack => _he ? 'חזרה' : 'Back';
  String get managerSettingsSub => _he ? 'העדפות מנהל' : 'Manager preferences';
  String get managerActionLegalProtection => _he ? 'הגנה משפטית' : 'Legal protection';
  String get managerActionLegalProtectionSub =>
      _he ? 'אחריות, הונאות מוכרים ותנאי פלטפורמה' : 'Liability, seller fraud & platform terms';
  String get managerLegalFullTerms => _he ? 'תנאי שימוש מלאים' : 'Full Terms of Use';
  String get managerActionOrderLimits => _he ? 'הגבלות הזמנה' : 'Order limits';
  String get managerActionOrderLimitsSub =>
      _he ? 'ימים, שעות ומכסת מוצרים' : 'Days, hours & product cap';
  String get managerActionAppointmentSchedule => _he ? 'שעות פגישות' : 'Appointment hours';
  String get managerActionAppointmentScheduleSub =>
      _he ? 'ימים, שעות פעילות ומשך פגישה' : 'Days, active hours & meeting length';
  String get managerAppointmentHoursSection => _he ? 'שעות פעילות' : 'Active hours';
  String get managerAppointmentHoursHint =>
      _he ? 'ממתי עד מתי ניתן לקבוע פגישות בכל יום' : 'When customers can book appointments each day';
  String get managerAppointmentDurationSection => _he ? 'משך כל פגישה' : 'Appointment length';
  String get managerAppointmentDurationHint =>
      _he ? 'כמה דקות כל תור / פגישה' : 'How many minutes each appointment lasts';
  String get managerAppointmentDurationLabel => _he ? 'דקות לפגישה' : 'Minutes per appointment';
  String get managerAppointmentDurationInvalid =>
      _he ? 'נא להזין בין 10 ל-240 דקות' : 'Enter between 10 and 240 minutes';
  String get managerAppointmentScheduleSaved => _he ? 'שעות הפגישות נשמרו' : 'Appointment hours saved';
  String get managerAddService => _he ? 'הוספת שירות' : 'Add service';
  String get managerCatalogServices => _he ? 'שירותים' : 'Services';
  String get managerDealServices => _he ? 'בחירת שירות' : 'Choose service';
  String get managerDealPickServicesHint =>
      _he ? 'בחרו שירות להנחה' : 'Pick a service for the discount';
  String get managerDealServiceDiscount => _he ? 'מחיר מוזל לשירות' : 'Discounted service price';
  String get managerActionNewDealSubAppointment =>
      _he ? 'הנחה על שירות בלשונית מבצעים' : 'Service discount in Deals tab';
  String get managerActionStoreSubAppointment =>
      _he ? 'שירותים, מבצעים ומצב חנות' : 'Services, offers & store mode';
  String get managerOrderLimitsTitle => _he ? 'הגבלות הזמנות' : 'Order restrictions';
  String get managerOrderHoursSection => _he ? 'מתי אפשר להזמין' : 'When orders are accepted';
  String get managerOrderHoursHint =>
      _he ? 'לכל יום — שעות משלו (אפשר לקבל הזמנות בימים ובשעות שונים)' : 'Set hours per weekday (different days, different times)';
  String get managerOrderHoursFrom => _he ? 'משעה' : 'From';
  String get managerOrderHoursTo => _he ? 'עד שעה' : 'Until';
  String get managerOrderHoursDays => _he ? 'ימים ושעות' : 'Days & hours';
  String get managerOrderHoursNone => _he ? 'אין ימים פתוחים להזמנה' : 'No days open for orders';
  String orderHoursDaySchedule(String day, String from, String to) =>
      _he ? '$day $from–$to' : '$day $from–$to';
  String orderHoursSchedule(String days, String from, String to) =>
      _he ? '$days · $from–$to' : '$days · $from–$to';
  String orderBlockedOutsideHours(String schedule) => _he
      ? 'לא ניתן להזמין עכשיו. שעות ההזמנה: $schedule'
      : 'Orders are not available now. Hours: $schedule';
  String get managerOrderCutoffSection => managerOrderHoursSection;
  String get managerOrderCutoffHint => managerOrderHoursHint;
  String get managerOrderMaxSection => _he ? 'מכסת מוצרים' : 'Product quantity cap';
  String get managerOrderMaxHint => _he
      ? 'סה״כ מוצרים ללקוח לתקופה — בהזמנה אחת או במספר הזמנות יחד (כולל מה שכבר בעגלה)'
      : 'Total product units per customer for the period — one order or many combined (includes cart)';
  String get managerOrderMaxCount => _he ? 'מספר מוצרים מקסימלי' : 'Maximum products';
  String get managerOrderMaxSaved => _he ? 'מכסת המוצרים עודכנה' : 'Product cap updated';
  String get managerOrderMaxInvalid =>
      _he ? 'נא להזין מספר מוצרים תקין (1–9999)' : 'Enter a valid product count (1–9999)';
  String get orderLimitPeriodDay => _he ? 'היום' : 'today';
  String get orderLimitPeriodWeek => _he ? 'השבוע' : 'this week';
  String managerOrderCurrentCount(int n) => _he ? 'כבר הוזמנו: $n מוצרים בתקופה' : 'Already ordered: $n products in period';
  String orderBlockedCutoff(String time) => orderBlockedOutsideHours(time);
  String orderBlockedMaxProducts(int max, String period, int alreadyOrdered, int inCart) {
    final total = alreadyOrdered + inCart;
    return _he
        ? 'מכסה: עד $max מוצרים ל$period (כבר $alreadyOrdered + עגלה $inCart = $total/$max)'
        : 'Limit: up to $max products for $period ($alreadyOrdered ordered + $inCart in cart = $total/$max)';
  }
  String get orderBlockedPreviewStore => _he
      ? 'לא ניתן לשלוח הזמנה — פתחו חנות משלכם (לא חנות הדגמה).'
      : 'Cannot place orders — open your own store (not the demo store).';
  String get managerLogout => _he ? 'יציאה מהפאנל' : 'Leave manager panel';
  String get managerActiveDeals => _he ? 'דילים פעילים' : 'Active deals';
  String get managerCustomDeals => _he ? 'דילים שהוספת' : 'Deals you added';
  String get managerNoInquiries => _he ? 'אין פניות עדיין' : 'No inquiries yet';
  String get managerNoReviews => _he ? 'אין חוות דעת עדיין' : 'No reviews yet';
  String get managerReviewsSectionHint => _he ? 'חוות דעת והמלצות' : 'Reviews & ratings';
  String get managerInquiriesSection => _he ? 'פניות' : 'Inquiries';
  String get managerInquiriesHint =>
      _he ? 'פניות מלקוחות מהאפליקציה' : 'Customer inquiries from the app';
  String get managerInquiryReplyHint => _he ? 'כתבו תשובה ללקוח…' : 'Write a reply to the customer…';
  String get managerInquirySendReply => _he ? 'שליחת תשובה' : 'Send reply';
  String get managerInquiryReplySent => _he ? 'התשובה נשלחה ללקוח' : 'Reply sent to customer';
  String get managerInquiryYourReply => _he ? 'התשובה שלכם' : 'Your reply';
  String get customerInquiryHistoryTitle => _he ? 'הפניות שלי' : 'My inquiries';
  String get customerInquiryYourMessage => _he ? 'הפנייה שלכם' : 'Your message';
  String get customerInquiryStoreReply => _he ? 'תשובת החנות' : 'Store reply';
  String get customerInquiryAwaitingReply =>
      _he ? 'ממתין לתשובה מהחנות' : 'Waiting for a reply from the store';
  String get managerReviewsSection => _he ? 'חוות דעת' : 'Reviews';
  String get managerUpdateMessage => _he ? 'העדכון ללקוחות' : 'Message for customers';
  String get managerUpdateImage => _he ? 'תמונה לעדכון (אופציונלי)' : 'Update image (optional)';
  String get managerUpdatePickImage => _he ? 'בחירת תמונה' : 'Choose image';
  String get managerUpdateRemoveImage => _he ? 'הסרת תמונה' : 'Remove image';
  String get managerUpdateAutoHint =>
      _he ? 'כותבים בשפה של הממשק — המערכת מתרגמת אוטומטית ללקוחות באנגלית/עברית' : 'Write in your UI language — we auto-translate for customers';
  String get managerUpdateTranslating => _he ? 'מתרגם ושומר…' : 'Translating & saving…';
  String get managerPublishUpdate => _he ? 'פרסום עדכון' : 'Publish update';
  String get managerUpdatePublished => _he ? 'העדכון פורסם ללקוחות' : 'Update published for customers';
  String get managerMessageSentTitle => _he ? 'ההודעה נשלחה בהצלחה!' : 'Message sent successfully!';
  String get managerMessageSentSub => _he
      ? 'הלקוחות יראו את העדכון כבאנר קופץ באפליקציה.'
      : 'Customers will see your update as a popup banner in the app.';
  String get managerClearUpdate => _he ? 'ניקוי עדכון' : 'Clear update';
  String get managerDealTitle => _he ? 'כותרת הדיל (אופציונלי)' : 'Deal title (optional)';
  String get managerDealDesc => _he ? 'תיאור (אופציונלי)' : 'Description (optional)';
  String get managerDealProducts => _he ? 'בחירת מוצרים' : 'Choose products';
  String managerDealProductN(int n) => _he ? 'מוצר $n' : 'Product $n';
  String get managerDealAddProduct => _he ? 'הוספת מוצר' : 'Add product';
  String get managerDealTapToPick => _he ? 'לחץ לבחירה' : 'Tap to choose';
  String get managerDealPickProductsHint =>
      _he ? 'יש לבחור לפחות מוצר אחד (ללא כפילויות) לפני הפרסום' : 'Pick at least one product (no duplicates) before publishing';
  String get managerDealPrice => _he ? 'מחיר הדיל' : 'Deal price';
  String get managerDealOptionalSection => _he ? 'פרטים נוספים' : 'More details';
  String get managerDealOptionalSectionSub =>
      _he ? 'אופציונלי — אם ריק, נבנית כותרת מהמוצרים' : 'Optional — title auto-built from products if empty';
  String get managerDealValidity => _he ? 'תוקף המבצע' : 'Deal validity';
  String managerDealValidityDays(int days) => _he ? '$days ימים' : '$days days';
  String get managerPublishDeal => _he ? 'פרסום דיל' : 'Publish deal';
  String get managerSaveDealChanges => _he ? 'שמירת שינויים' : 'Save changes';
  String get managerDealPublished => _he ? 'הדיל פורסם במבצעים' : 'Deal published in Deals';
  String get managerDealUpdated => _he ? 'הדיל עודכן' : 'Deal updated';
  String get managerDealDeleted => _he ? 'הדיל הוסר' : 'Deal removed';
  String get managerEditDeal => _he ? 'עריכה' : 'Edit';
  String get managerDeleteDeal => _he ? 'הסרה' : 'Remove';
  String get managerNewDeal => _he ? 'דיל חדש' : 'New deal';
  String get managerEditingDeal => _he ? 'עריכת דיל' : 'Editing deal';
  String get managerConfirmDeleteDeal => _he ? 'להסיר את הדיל?' : 'Remove this deal?';
  String get managerNoActiveDeals => _he ? 'אין דילים פעילים' : 'No active deals';
  String get managerStoreStatus => _he ? 'סטטוס החנות' : 'Store status';
  String get managerStoreAnnouncement => _he ? 'עדכון פעיל ללקוחות' : 'Active customer update';
  String get managerNoAnnouncement => _he ? 'אין עדכון פעיל' : 'No active update';
  String get managerReplyWhatsApp => _he ? 'מענה בוואטסאפ' : 'Reply on WhatsApp';
  String get save => _he ? 'שמירה' : 'Save';
  String get storeAnnouncementBanner => _he ? 'עדכון מהמאפייה' : 'Update from the bakery';
  String get dismissAnnouncement => _he ? 'סגירת העדכון' : 'Dismiss update';
  String get storeAnnouncementPopupTitle => _he ? 'עדכון חדש מהמאפייה' : 'New update from the bakery';
  String get storeAnnouncementInOrders => _he ? 'הודעה מהמאפייה' : 'Message from the bakery';

  String get settingsHelp => _he ? 'הגדרות ועזרה' : 'Settings & help';
  String get contact => _he ? 'צור קשר' : 'Contact us';
  String get contactSub => _he ? 'צ׳אט קהילה או פנייה לבעל העסק' : 'Community chat or contact the owner';
  String get contactInquiryTab => _he ? 'פנייה' : 'Inquiry';
  String get inquiryReasonLabel => _he ? 'סיבת הפנייה' : 'Reason for contact';
  String get inquirySent => _he ? 'הפנייה נשלחה לבעל החנות' : 'Your inquiry was sent to the store owner';
  String get sendInquiry => _he ? 'שליחת פנייה' : 'Send inquiry';
  String get botWelcome => _he
      ? 'שלום! אני כאן לעזור. שאלו על שעות, משלוח, תשלום או הזמנות.'
      : 'Hi! I can help with hours, delivery, payment, or orders.';
  String get botNoAnswer => _he
      ? 'לא מצאתי תשובה מדויקת. נסו לנסח אחרת, או שלחו מייל / פנו לבעל העסק.'
      : 'I could not find a precise answer. Try rephrasing, send email, or contact the owner.';
  String get botTypeHint => _he ? 'כתבו שאלה...' : 'Type a question...';
  String get sendChat => _he ? 'שליחה' : 'Send';
  String get contactOwner => _he ? 'פנייה לבעל העסק' : 'Contact business owner';
  String get contactOwnerHint => _he
      ? 'זמין לאחר שהבוט לא עזר — נשלח הודעה ישירות לבעל העסק'
      : 'Available when the bot could not help — message goes directly to the owner';
  String get sendToOwner => _he ? 'שליחה לבעל העסק' : 'Send to owner';
  String get ownerMessageSent => _he ? 'ההודעה נשלחה לבעל העסק' : 'Message sent to the owner';
  String get sendEmail => _he ? 'שליחה במייל' : 'Send by email';
  String get leaveReview => _he ? 'חוות דעת' : 'Leave a review';
  String get leaveReviewSub => _he ? 'דרגו את החוויה שלכם' : 'Rate your experience';
  String get reviewTitle => _he ? 'איך הייתה החוויה?' : 'How was your experience?';
  String get reviewsSheetTitle => _he ? 'חוות דעת והמלצות' : 'Reviews & recommendations';
  String get reviewsSheetSub => _he ? 'מה אחרים כתבו עלינו' : 'What others wrote about us';
  String get yourReviewSection => _he ? 'החוויה שלכם' : 'Your experience';
  String get reviewHint => _he ? 'הערה (אופציונלי)' : 'Note (optional)';
  String get submitReview => _he ? 'שליחת חוות דעת' : 'Submit review';
  String get skip => _he ? 'דילוג' : 'Skip';
  String reviewsCountLabel(int count) => _he ? '$count המלצות' : '$count reviews';
  String get recommend => _he ? 'המליצו עלינו' : 'Recommend us';
  String get recommendSub => _he ? 'שתפו חברים' : 'Share with friends';
  String get accessibility => _he ? 'נגישות' : 'Accessibility';
  String get accessibilitySub => _he ? 'הגדלת כתב והתאמות' : 'Text size & adjustments';
  String get accessibilityAndLegal => _he ? 'נגישות ומשפטי' : 'Accessibility & legal';
  String get accessibilityAndLegalSub =>
      _he ? 'הגדלת כתב, מדיניות פרטיות ותנאים' : 'Text size, privacy policy & terms';
  String get chooseAccessibilityAndLegal => _he ? 'נגישות ומשפטי' : 'Accessibility & legal';
  String get textSize => _he ? 'גודל טקסט' : 'Text size';
  String get decreaseText => _he ? 'הקטן' : 'Smaller';
  String get increaseText => _he ? 'הגדל' : 'Larger';
  String get resetTextSize => _he ? 'איפוס' : 'Reset';
  String get highContrast => _he ? 'ניגודיות גבוהה' : 'High contrast';
  String get highContrastSub => _he ? 'טקסט וכפתורים בולטים יותר' : 'Stronger text and buttons';
  String get faq => _he ? 'שאלות ותשובות' : 'FAQ';
  String get faqSub => _he ? 'תשובות מהירות' : 'Quick answers';
  String get managerEntry => _he ? 'כניסת מנהל' : 'Manager login';
  String get managerEntrySub => _he ? 'ניהול הזמנות והחנות' : 'Manage orders & store';
  String get employeeEntry => _he ? 'כניסת עובד' : 'Employee login';
  String get employeeEntrySub => _he ? 'הזמנות וסיכום להכנה' : 'Orders & prep list';
  String get comingSoon => _he ? 'בקרוב' : 'Coming soon';
  String get saasCreateStore => _he ? 'פתיחת חנות' : 'Open store';
  String get saasCreateStoreSub => _he ? 'חנות אונליין עם קישור ציבורי' : 'Online store with public link';
  String get openStoreTitle => _he ? 'פתיחת חנות' : 'Open a store';
  String get openStoreSubtitle => _he
      ? 'מלא/י שם חנות וסיסמת מנהל — השאר אופציונלי.'
      : 'Enter store name and manager password — the rest is optional.';
  String get storeNameLabel => _he ? 'שם החנות *' : 'Store name *';
  String get storeAdditionalDetails => _he ? 'פרטים נוספים' : 'Additional details';
  String get openStoreSubmit => _he ? 'פתיחת חנות' : 'Open store';
  String get openStoreSubmitting => _he ? 'פותח חנות…' : 'Opening store…';
  String get storeDescriptionLabel => _he ? 'תיאור' : 'Description';
  String get storePhoneLabel => _he ? 'טלפון' : 'Phone';
  String get storeAddressLabel => _he ? 'כתובת' : 'Address';
  String get storeBusinessTypeLabel => _he ? 'סוג עסק' : 'Business type';
  String get storeContactEmailLabel => _he ? 'מייל לפניות' : 'Inquiry email';
  String get storeContactEmailHint => _he
      ? 'אופציונלי בפתיחה — אפשר להוסיף/לעדכן גם בפאנל מנהל → מענה ללקוחות.'
      : 'Optional at setup — you can add or update it later under Manager → Customer messages.';
  String get storeCreatedReady => _he ? 'החנות שלך מוכנה!' : 'Your store is ready.';
  String get storeYourPublicLink => _he ? 'קישור החנות שלך:' : 'Your store link:';
  String get storeNameRequired => _he ? 'נדרש שם חנות.' : 'Store name is required.';
  String get legalPrivacyPolicy => _he ? 'מדיניות פרטיות' : 'Privacy Policy';
  String get legalTermsOfUse => _he ? 'תנאי שימוש' : 'Terms of Use';
  String supabaseDebugStatus(bool configured) =>
      _he ? 'Supabase מוגדר: $configured' : 'Supabase configured: $configured';

  String get legalDocuments => _he ? 'משפטי' : 'Legal';
  String get legalDocumentsSub => _he ? 'מדיניות פרטיות ותנאי שימוש' : 'Privacy Policy & Terms of Use';
  String get chooseLegalDocument => _he ? 'מסמכים משפטיים' : 'Legal documents';
  String get legalPrivacySub => _he ? 'טיוטת פיילוט — Peymiz' : 'Peymiz pilot draft';
  String get legalTermsSub => _he ? 'טיוטת פיילוט v2 — Peymiz' : 'Peymiz pilot draft v2';
  String get legalAcceptPrefix => _he ? 'אני מסכים/ה ל' : 'I agree to the ';
  String get legalAcceptMiddle => _he ? ' ול' : ' and ';
  String get legalAcceptSuffix => _he ? '.' : '.';
  String get legalTermsLink => _he ? 'תנאי השימוש' : 'Terms of Use';
  String get legalPrivacyLink => _he ? 'מדיניות הפרטיות' : 'Privacy Policy';
  String get legalMustAccept => _he
      ? 'יש לאשר את תנאי השימוש ומדיניות הפרטיות לפני יצירת חנות.'
      : 'You must accept the Terms of Use and Privacy Policy before creating a store.';

  String get authEmailNotConfirmed => _he
      ? 'יש לאשר את האימייל לפני כניסה. בדוק/י את תיבת הדואר (גם ספאם) ולחץ/י על הקישור מ-Supabase.'
      : 'Please confirm your email before signing in. Check your inbox (and spam) for the Supabase link.';

  String get authEmailConfirmSent => _he
      ? 'נשלח אימייל אישור. אחרי לחיצה על הקישור — חזור/י והתחבר/י.'
      : 'Confirmation email sent. After you click the link, return here and sign in.';

  String get authResendConfirmation => _he ? 'שליחת אימייל אישור שוב' : 'Resend confirmation email';

  String get authSignUpPendingConfirm => _he
      ? 'החשבון נוצר. אשר/י את האימייל ואז התחבר/י.'
      : 'Account created. Confirm your email, then sign in.';
  String get language => _he ? 'שפה' : 'Language';
  String get languageSub => _he ? 'עברית או אנגלית' : 'Hebrew or English';
  String get languageCurrentHe => _he ? 'עברית' : 'Hebrew';
  String get languageCurrentEn => _he ? 'אנגלית' : 'English';
  String get chooseLanguage => _he ? 'בחר שפה' : 'Choose language';

  String get displayMode => _he ? 'מצב תצוגה' : 'Display mode';
  String get displayModeSub => _he ? 'רגוע, בהיר או כהה' : 'Calm, light, or dark';
  String get chooseDisplayMode => _he ? 'בחר מצב תצוגה' : 'Choose display mode';
  String get languageAndDisplay => _he ? 'שפה ותצוגה' : 'Language & display';
  String get chooseLanguageAndDisplay => _he ? 'שפה ומצב תצוגה' : 'Language & display mode';

  String get appearance => _he ? 'מראה' : 'Appearance';
  String get themeCalm => _he ? 'מצב רגוע' : 'Calm mode';
  String get themeCalmSub => _he ? 'שמנת רכה — כמו הריבועים' : 'Soft cream — like the tiles';
  String get themeLight => _he ? 'מצב בהיר' : 'Light mode';
  String get themeLightSub => _he ? 'שחור ולבן בלבד — ניגודיות גבוהה' : 'Black & white only — high contrast';
  String get themeDark => _he ? 'מצב כהה' : 'Dark mode';
  String get themeDarkSub => _he ? 'כחול כהה ולבן — ניגודיות גבוהה' : 'Dark blue & white — high contrast';

  String get accessibilityTitle => _he ? 'נגישות והצהרת נגישות' : 'Accessibility statement';
  String get accessibilityWebLink => _he ? 'הצהרת נגישות באתר' : 'Accessibility statement on web';
  String get managerActionAccessibility => _he ? 'נגישות' : 'Accessibility';
  String get managerActionAccessibilitySub =>
      _he ? 'הגדלת טקסט והצהרת נגישות' : 'Text size & accessibility statement';
  String accessibilityBody(String email, String businessName) => accessibilityStatement(email, businessName);

  String accessibilityStatement(String email, String businessName) => _he
      ? '''הצהרת נגישות — $businessName (אפליקציית הזמנות)

עודכן לאחרונה: מאי 2026

מחויבותנו
אנו פועלים להנגיש את האפליקציה לכלל האוכלוסייה, כולל אנשים עם מוגבלות, בהתאם לחוק שוויון זכויות לאנשים עם מוגבלות, התשנ"ח-1998, תקנות שוויון זכויות לאנשים עם מוגבלות (התאמות נגישות לשירות), התשע"ג-2013, ות"י 5568 (נגישות תכנים באינטרנט) ברמת AA ככל האפשר.

תכונות נגישות באפליקציה
• תמיכה בעברית וכיוון RTL
• הגדלה והקטנה של גודל הטקסט (80%–150%)
• מצבי תצוגה: רגוע, בהיר וכהה לניגודיות נוחה
• כפתורים גדולים וברורים, תוויות לשדות טפסים
• ניווט תחתון עם אייקונים וטקסט

מגבלות ידועות
• חלק מהטקסט בעברית עשוי להיות מוצג בפונט גיבוי כאשר אין גליף מתאים בפונט העיצובי
• התראות דחיפה תלויות בהרשאות המכשיר

בקשות, משוב ותלונות נגישות
רכז/ת נגישות: $email
ניצור איתכם קשר בהקדם האפשר, ובכל מקרה לא יאוחר מ-14 ימי עסקים.

תאימות בינלאומית (ארה"ב)
אנו שואפים לעמוד בעקרונות WCAG 2.1 Level AA ו-Section 508 של חוק השחיקה בארה"ב, ככל הניתן במסגרת אפליקציית מובייל זו.'''
      : '''Accessibility Statement — $businessName (ordering app)

Last updated: May 2026

Our commitment
We work to make this app accessible to everyone, including people with disabilities, in line with the Israel Equal Rights for Persons with Disabilities Law (1998), accessibility service regulations (2013), and Israeli Standard 5568 (web content accessibility) at AA level where practicable.

In-app accessibility features
• Hebrew/English and RTL/LTR support
• Adjustable text size (80%–150%)
• Calm, light, and dark display modes
• Large tap targets, labeled form fields
• Bottom navigation with icons and labels

Known limitations
• Some Hebrew characters may use a fallback font when the display font lacks a glyph
• Push alerts depend on device permissions

Requests, feedback, and accessibility complaints
Accessibility coordinator: $email
We will respond as soon as possible and within 14 business days at the latest.

United States alignment
We aim to follow WCAG 2.1 Level AA and Section 508 principles, as applicable to this mobile application.''';

  String get contactCommunityTab => _he ? 'צ׳אט קהילה' : 'Community chat';
  String get contactCommunityTitle => _he ? 'קהילת הלקוחות' : 'Customer community';
  String get contactCommunityHint => _he ? 'שיחה פתוחה בין לקוחות' : 'Open conversation between customers';
  String get contactYourName => _he ? 'השם שלכם' : 'Your name';
  String get contactTypeMessage => _he ? 'הודעה' : 'Message';
  String get contactCommunityEmpty => _he ? 'אין הודעות עדיין — שלחו את הראשונה' : 'No messages yet — send the first one';
  String get managerPrepDetails => _he ? 'פירוט הזמנות' : 'Order breakdown';
  String get managerApproveOrder => _he ? 'אישור הזמנה' : 'Approve order';
  String get managerOrderApproved => _he ? 'ההזמנה אושרה' : 'Order approved';
  String get managerClearApprovedOrders => _he ? 'נקה הזמנות שאושרו' : 'Clear approved orders';
  String get managerApprovedOrdersCleared => _he ? 'ההזמנות שאושרו נוקו' : 'Approved orders cleared';
  String get managerNoPendingOrders => _he ? 'אין הזמנות ממתינות' : 'No pending orders';
  String get managerPendingOrdersBadge => _he ? 'ממתינות' : 'Pending';
  String get managerNotifyCustomers => _he ? 'התראה ללקוחות באפליקציה' : 'Notify customers in app';
  String get managerNotifySent => _he ? 'התראה נשלחה ללקוחות' : 'Customers were notified';
  String get managerReplyToReview => _he ? 'מענה ללקוח' : 'Reply to customer';
  String get managerReplySaved => _he ? 'המענה נשמר' : 'Reply saved';
  String get managerReplyStatsRecovered =>
      _he ? 'המענה נשמר — מדד שביעות הרצון התאושש' : 'Reply saved — satisfaction score recovered';
  String get managerTapReviewToReply => _he ? 'לחץ לכתיבת מענה' : 'Tap to write a reply';
  String get managerPoorReview => _he ? 'חוות דעת שלילית' : 'Poor review';
  String get managerPoorReviewRecovered =>
      _he ? 'מדד שביעות הרצון התאושש לאחר המענה' : 'Satisfaction score recovered after your reply';
  String get managerBakeryReply => _he ? 'תשובת המאפייה' : 'Bakery reply';
  String get managerReplyHint => _he ? 'כתבו מענה ללקוח…' : 'Write a reply to the customer…';
  String get managerStatsSatisfaction => _he ? 'שביעות רצון' : 'Satisfaction';
  String get managerStatsHappyRate => _he ? 'לקוחות מרוצים (4–5 כוכבים)' : 'Happy customers (4–5 stars)';
  String get managerStatsReviewsCount => _he ? 'חוות דעת' : 'Reviews';
  String get managerStatsAvgRating => _he ? 'דירוג ממוצע' : 'Average rating';
  String get managerStatsOrdersInPeriod => _he ? 'הזמנות בתקופה' : 'Orders in period';
  String get managerStatsRatingBreakdown => _he ? 'פילוח דירוגים' : 'Rating breakdown';
  String get managerStatsRecentReviews => _he ? 'חוות דעת אחרונות' : 'Recent reviews';
  String get managerStatsNoReviewsYet => _he ? 'אין עדיין חוות דעת לגרף' : 'No reviews yet for chart';
  String get managerAddProduct => _he ? 'הוספת מוצר' : 'Add product';
  String get managerAddDrink => _he ? 'הוספת שתייה' : 'Add drink';
  String get managerEditItem => _he ? 'עריכת פריט' : 'Edit item';
  String get managerItemName => _he ? 'שם המוצר' : 'Product name';
  String get managerItemSubtitle => _he ? 'תיאור (אופציונלי)' : 'Description (optional)';
  String get managerItemPrice => _he ? 'מחיר' : 'Price';
  String get managerItemRequiredHint => _he ? 'שם, מחיר ותמונה הם שדות חובה' : 'Name, price and image are required';
  String get managerItemSaving => _he ? 'שומר…' : 'Saving…';
  String get managerTapToUploadImage => _he ? 'לחץ להעלאת תמונה מהמכשיר' : 'Tap to upload from device';
  String get managerPickImage => _he ? 'תמונה' : 'Image';
  String get managerCatalogProducts => _he ? 'מוצרים בחנות' : 'Store products';
  String get managerCatalogDrinks => _he ? 'שתייה בחנות' : 'Store drinks';
  String get catalogEmptyManagerTitle => _he ? 'הגדירו את המוצרים' : 'Set up your products';
  String get catalogEmptyManagerSub =>
      _he ? 'הוסיפו מוצרים ושתייה.\nלחצו «הוספת מוצר» או «הוספת שתייה» למעלה.' : 'Add products and drinks.\nTap Add product or Add drink above.';
  String get catalogSetupGotIt => _he ? 'הבנתי' : 'Got it';
  String get catalogEmptyCustomer =>
      _he ? 'החנות עדיין לא הגדירה מוצרים. חזרו בקרוב!' : 'This store has not listed products yet. Check back soon!';
  String get catalogEmptyProductsSection => _he ? 'אין מוצרים עדיין' : 'No products yet';
  String get catalogEmptyDrinksSection => _he ? 'אין שתייה עדיין' : 'No drinks yet';
  String get newDealAlertTitle => _he ? 'מבצע חדש!' : 'New deal!';

  String get faqTitle => _he ? 'שאלות נפוצות' : 'FAQ';
  String get contactTitle => _he ? 'צור קשר' : 'Contact us';
  String get contactFormHint => _he ? 'מלאו פרטים ונחזור אליכם' : 'Fill in your details and we will get back to you';
  String get yourName => _he ? 'שם מלא' : 'Full name';
  String get yourEmail => _he ? 'אימייל' : 'Email';
  String get yourMessage => _he ? 'הודעה' : 'Message';
  String get sendMessage => _he ? 'שליחה' : 'Send';
  String get messageSent => _he ? 'ההודעה נשלחה! ניצור קשר בקרוב.' : 'Message sent! We will contact you soon.';
  String get contactEmailDelivered => _he ? 'המייל נשלח לבעל החנות.' : 'Email sent to the store owner.';
  String get contactEmailSendFailed => _he
      ? 'ההודעה נשמרה, אך המייל לא נשלח. נסו שוב או פנו ישירות לחנות.'
      : 'Message saved, but email could not be delivered. Try again or contact the store directly.';
  String get fillAllFields => _he ? 'נא למלא את כל השדות' : 'Please fill in all fields';
  String phoneLabel(String phone) => _he ? 'טלפון: $phone' : 'Phone: $phone';
  String get whatsapp => _he ? 'וואטסאפ' : 'WhatsApp';
  String get callUs => _he ? 'התקשרו' : 'Call us';
  String get thanksReview => _he ? 'תודה על המלצתכם!' : 'Thanks for your recommendation!';

  String get dealsTitle => _he ? 'מבצעים ודילים' : 'Deals & specials';
  String validUntil(String v) => _he ? 'תוקף: $v' : 'Valid: $v';
  String get redeemDeal => _he ? 'מימוש דיל' : 'Redeem deal';
  String get dealRedeemed => _he ? 'הדיל מומש' : 'Deal redeemed';
  String get dealAdded => _he ? 'הדיל נוסף לעגלה' : 'Deal added to cart';
  String get cartDealsSection => _he ? 'דילים בעגלה' : 'Deals in cart';
  String get removeDealFromCart => _he ? 'הסרת דיל' : 'Remove deal';

  String get yourCart => _he ? 'העגלה שלך' : 'Your cart';
  String get cartEmpty => _he ? 'העגלה ריקה' : 'Cart is empty';
  String get cartEmptySub => _he ? 'הוסף מוצרים מהקטלוג כדי לבצע הזמנה' : 'Add items from the menu to order';
  String get confirmOrder => _he ? 'שליחת הזמנה' : 'Send order';
  String get orderContactTitle => _he ? 'פרטי הזמנה' : 'Order details';
  String get orderContactHint => _he
      ? 'נדרש שם וטלפון ליצירת קשר. אפשר גם להיכנס מראש בהגדרות ולא למלא שוב.'
      : 'Name and phone are required. You can sign in from Settings to skip this next time.';
  String get customerProfileTitle => _he ? 'כניסת לקוח' : 'Customer sign-in';
  String get customerProfileSub => _he
      ? 'נשמר במכשיר — לא צריך למלא שוב.'
      : 'Saved on this device — skip next time.';
  String get customerDisplayName => _he ? 'שם מלא' : 'Full name';
  String get yourPhone => _he ? 'מספר טלפון' : 'Phone number';
  String get rememberMeForOrders => _he ? 'זכור אותי להזמנות הבאות' : 'Remember me for future orders';
  String get customerSignIn => _he ? 'כניסה' : 'Sign in';
  String get customerSignOut => _he ? 'יציאה' : 'Sign out';
  String get customerProfileSaved => _he ? 'הפרטים נשמרו' : 'Details saved';
  String get customerSignedOut => _he ? 'יצאת מהחשבון המקומי' : 'Signed out locally';
  String get invalidPhone => _he ? 'מספר טלפון לא תקין' : 'Invalid phone number';
  String customerSignedInAs(String name, String phone) =>
      _he ? 'מחובר: $name · $phone' : 'Signed in: $name · $phone';
  String get orderConfirmed => _he ? 'ההזמנה נשלחה וממתינה לאישור!' : 'Order sent — pending confirmation!';
  String get orderSuccessTitle => _he ? 'ההזמנה הושלמה בהצלחה!' : 'Order completed successfully!';
  String get orderSuccessBannerSub => _he
      ? 'תודה רבה! נעדכן אותך ברגע שהחנות תאשר.'
      : 'Thank you! We will update you once the store confirms.';
  String get paymentProcessing => _he ? 'פותח תשלום…' : 'Opening payment…';
  String get paymentCanceled => _he ? 'התשלום בוטל — ההזמנה לא נשמרה' : 'Payment canceled — order not saved';
  String get paymentFailed => _he ? 'התשלום נכשל' : 'Payment failed';
  String get paymentMinimum => _he ? 'סכום מינימלי לתשלום: ₪5' : 'Minimum payment amount: ₪5';
  String get paymentServerUnreachable =>
      _he ? 'שרת התשלום לא זמין. הפעל את server/ על המחשב.' : 'Payment server unreachable. Start server/ on your PC.';
  String get paymentNotConfiguredTitle => _he ? 'תשלום Stripe לא מוגדר' : 'Stripe not configured';
  String get paymentNotConfiguredBody => _he
      ? 'נדרש:\n'
          '1. חשבון Stripe (stripe.com)\n'
          '2. מפתחות Test מלוח הבקרה\n'
          '3. קובץ server/.env עם STRIPE_SECRET_KEY\n'
          '4. הפעלת השרת: npm start בתיקיית server\n'
          '5. הרצת האפליקציה עם STRIPE_PUBLISHABLE_KEY ו-STRIPE_BACKEND_URL'
      : 'You need:\n'
          '1. A Stripe account\n'
          '2. Test API keys from the Dashboard\n'
          '3. server/.env with STRIPE_SECRET_KEY\n'
          '4. Run the server: npm start in server/\n'
          '5. Run the app with STRIPE_PUBLISHABLE_KEY and STRIPE_BACKEND_URL';
  String get repeatOrderAdded => _he ? 'הזמנה חוזרת נוספה להזמנות בתהליך' : 'Repeat order added to cart';
  String get activeOrdersSection => _he ? 'הזמנות בתהליך' : 'Active orders';
  String get orderHistory => _he ? 'הסטוריית הזמנות' : 'Order history';
  String get tapToExpandHistory => _he ? 'לחץ לפתיחה' : 'Tap to open';
  String get noPastOrders => _he ? 'אין הזמנות עבר' : 'No past orders';
  String get noPastOrdersSub => _he ? 'לאחר סיום הזמנה היא תופיע כאן' : 'Completed orders appear here';
  String get orderDetailsHint => _he ? 'לחץ לפרטי ההזמנה' : 'Tap for details';
  String orderTitle(String id) => _he ? 'הזמנה $id' : 'Order $id';
  String get orderNumber => _he ? 'מספר הזמנה' : 'Order number';
  String get date => _he ? 'תאריך' : 'Date';
  String get status => _he ? 'סטטוס' : 'Status';
  String get totalPrice => _he ? 'מחיר כולל' : 'Total';
  String get orderedItems => _he ? 'מה הוזמן' : 'Items';
  String get close => _he ? 'סגירה' : 'Close';
  String get repeatOrder => _he ? 'הזמנה חוזרת' : 'Repeat order';
  String get rememberOrder => _he ? 'לזכור' : 'Remember';
  String get orderRemembered => _he ? 'ההזמנה נשמרה לזכרון' : 'Order saved to memory';
  String get forgetOrder => _he ? 'ביטול שמירה' : 'Remove save';
  String get orderRemovedFromMemory => _he ? 'השמירה בוטלה' : 'Order removed from saved';
  String priceLabel(String p) => _he ? 'מחיר: $p' : 'Price: $p';

  String get bakeryCategory => _he ? 'מאפים' : 'Bakery';
  String get drinksCategory => _he ? 'שתייה' : 'Drinks';
  String get pickQuantity => _he ? 'בחר כמות (עד 10)' : 'Choose quantity (up to 10)';
  String get confirm => _he ? 'אישור' : 'Confirm';

  String get statusDelivered => _he ? 'נמסר' : 'Delivered';
  String get statusCompleted => _he ? 'הושלמה' : 'Completed';
  String get statusCompletedDeal => _he ? 'הושלמה (דיל)' : 'Completed (deal)';
  String get statusReady => _he ? 'מוכן לאישור' : 'Ready to confirm';
  String get statusPendingApproval => _he ? 'ממתין לאישור' : 'Pending approval';
  String get statusPreparing => _he ? 'בהכנה' : 'Preparing';
  String get statusReadyPickup => _he ? 'מוכן לאיסוף' : 'Ready for pickup';

  List<({String q, String a})> get faqItems {
    // Kept for compatibility; live data comes from FaqStore after load().
    return _he
        ? kDefaultFaqItems.map((e) => e.pair(true)).toList()
        : kDefaultFaqItems.map((e) => e.pair(false)).toList();
  }
}
