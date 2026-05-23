import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'faq_store.dart';

class AppLocale extends ChangeNotifier {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    notifyListeners();
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
  String get managerAppointmentsNeedLink => _he
      ? 'כדי להציג יומן תורים, קשרו חנות אונליינית: הגדרות → יצירת חנות.\n(או ודאו שחנות הדמו shiki קיימת בשרת)'
      : 'To show the appointment calendar, link your online store: Settings → Create Store.\n(Ensure demo store "shiki" exists on the server)';
  String demoStoreBanner(String slug) =>
      _he ? 'חנות דמו: $slug' : 'Demo store: $slug';

  String get managerLoginTitle => _he ? 'כניסת מנהל' : 'Manager login';
  String get managerPasswordHint => _he ? 'הזן סיסמת מנהל' : 'Enter manager password';
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
  String get managerPrepUnits => _he ? 'יחידות בסך הכל' : 'Total units';
  String get managerShowOrders => _he ? 'הצג כל ההזמנות' : 'Show all orders';
  String get managerHideOrders => _he ? 'הסתר הזמנות' : 'Hide orders';
  String get managerHealthWhy => _he ? 'למה לא 100%?' : 'Why not 100%?';
  String get managerHealthPerfect => _he ? 'העסק במצב מצוין — 100%' : 'Excellent — 100%';
  String get managerHealthTap => _he ? 'לחצו על העיגול לפירוט' : 'Tap the ring for details';
  String get managerHealthTapIssue =>
      _he ? 'לחצו על העיגול האדום לפתרון הבעיה' : 'Tap a red dot to fix the issue';

  String get appCreatorBannerTitle => _he ? 'גישת יוצר האפליקציה' : 'App creator access';
  String get appCreatorBannerSub => _he
      ? 'הזינו סיסמת יוצר כדי לנהל את כל בתי העסקים שהצטרפו.'
      : 'Enter the creator password to manage all joined businesses.';
  String get appCreatorPasswordLabel => _he ? 'סיסמת יוצר' : 'Creator password';
  String get appCreatorWrongPassword => _he ? 'סיסמה שגויה' : 'Wrong password';
  String get appCreatorEnter => _he ? 'כניסה לדשבורד' : 'Open dashboard';
  String get appCreatorDashboardTitle => _he ? 'דשבורד יוצר האפליקציה' : 'App creator dashboard';
  String get appCreatorDashboardSub => _he
      ? 'כל בתי העסקים — הפעלה, השהיה וניסיון'
      : 'All businesses — activate, suspend, or trial';
  String get appCreatorSearch => _he ? 'חיפוש עסק / slug / אימייל' : 'Search business / slug / email';
  String get appCreatorNoBusinesses => _he ? 'אין עסקים רשומים' : 'No businesses yet';
  String get appCreatorStatus => _he ? 'סטטוס' : 'Status';
  String get appCreatorActive => _he ? 'פעיל' : 'Active';
  String get appCreatorInactive => _he ? 'מושהה' : 'Inactive';
  String appCreatorCounts(int products, int orders, int appointments) => _he
      ? 'מוצרים: $products · הזמנות: $orders · תורים: $appointments'
      : 'Products: $products · Orders: $orders · Appointments: $appointments';
  String get appCreatorActivate => _he ? 'הפעלה' : 'Activate';
  String get appCreatorSuspend => _he ? 'השהיה' : 'Suspend';
  String get appCreatorTrial => _he ? 'ניסיון' : 'Trial';
  String get appCreatorFilterAll => _he ? 'הכל' : 'All';
  String get appCreatorFilterPayment => _he ? 'בעיית תשלום' : 'Payment issue';
  String get appCreatorFilterDisabled => _he ? 'מושבתות' : 'Disabled';
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
• לא נמכור את הנתונים לצד שלישי ללא הסכמתכם.
• ניתן לפנות לעסק או למפעיל האפליקציה לעדכון או מחיקת מידע.
• שימוש באפליקציה מהווה הסכמה לתנאים אלה.'''
      : '''• The app collects name, phone, and order details to provide the service.
• Data is shared with the business you order from.
• We do not sell your data to third parties without consent.
• You may contact the business or app operator to update or delete your data.
• Using the app means you agree to these terms.''';
  String get policyConsentBodyOwner => _he
      ? '''• ניהול העסק כולל עיבוד נתוני לקוחות, הזמנות ותשלומים.
• אתם אחראים לשמירה על פרטיות הלקוחות ולעמידה בדין.
• מפעיל האפליקציה רשאי להשהות חנות באי-תשלום מנוי.
• ניתן לפנות למפעיל האפליקציה בכל שאלה על המדיניות.
• המשך שימוש בפאנל המנהל מהווה הסכמה לתנאים אלה.'''
      : '''• Managing your business involves processing customer, order, and payment data.
• You are responsible for customer privacy and legal compliance.
• The app operator may suspend a store for unpaid subscription.
• Contact the app operator with any policy questions.
• Continuing to use the manager panel means you accept these terms.''';

  String get managerOrderLines => _he ? 'פירוט הזמנה' : 'Order breakdown';

  String get managerNavDashboard => _he ? 'ראשי' : 'Home';
  String get managerNavActions => _he ? 'פעולות' : 'Actions';
  String get managerNavSettings => _he ? 'הגדרות' : 'Settings';
  String get managerActionsSub => _he ? 'ניהול החנות והלקוחות' : 'Manage store & customers';
  String get managerActionCustomers => _he ? 'מענה ללקוחות' : 'Customer messages';
  String get managerActionCustomersSub =>
      _he ? 'עדכון ללקוחות, חוות דעת והמלצות' : 'Customer update, reviews & ratings';
  String get managerActionUpdate => _he ? 'עדכון ללקוחות' : 'Customer update';
  String get managerActionUpdateSub => _he ? 'הודעה שמופיעה באפליקציה' : 'Message shown in the app';
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
      _he ? 'עריכת שאלות נפוצות ללקוחות' : 'Edit customer help Q&A';
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
  String get managerFaqQuestionHe => _he ? 'שאלה (עברית)' : 'Question (Hebrew)';
  String get managerFaqAnswerHe => _he ? 'תשובה (עברית)' : 'Answer (Hebrew)';
  String get managerFaqQuestionEn => _he ? 'שאלה (אנגלית)' : 'Question (English)';
  String get managerFaqAnswerEn => _he ? 'תשובה (אנגלית)' : 'Answer (English)';
  String get managerFaqSaved => _he ? 'השאלות נשמרו' : 'FAQ saved';
  String get managerFaqEmpty => _he ? 'אין שאלות עדיין' : 'No questions yet';
  String get managerFaqRequired =>
      _he ? 'מלאו שאלה ותשובה בשתי השפות' : 'Fill question and answer in both languages';
  String get managerStatsWeekly => _he ? 'שבועי' : 'Weekly';
  String get managerStatsMonthly => _he ? 'חודשי' : 'Monthly';
  String get managerStatsYearly => _he ? 'שנתי' : 'Yearly';
  String get managerStatsRevenue => _he ? 'הכנסות' : 'Revenue';
  String get managerStatsGrowing => _he ? 'העסק בצמיחה' : 'Business is growing';
  String get managerStatsDeclining => _he ? 'ירידה בהכנסות' : 'Revenue declining';
  String get managerStatsStable => _he ? 'יציב' : 'Stable';
  String get managerBack => _he ? 'חזרה' : 'Back';
  String get managerSettingsSub => _he ? 'העדפות מנהל' : 'Manager preferences';
  String get managerActionOrderLimits => _he ? 'הגבלות הזמנה' : 'Order limits';
  String get managerActionOrderLimitsSub =>
      _he ? 'שעת סגירה ומכסת הזמנות' : 'Cutoff time & order cap';
  String get managerOrderLimitsTitle => _he ? 'הגבלות הזמנות' : 'Order restrictions';
  String get managerOrderCutoffSection => _he ? 'מועד אחרון להזמנה היום' : 'Order cutoff today';
  String get managerOrderCutoffHint =>
      _he ? 'לאחר השעה הזו לקוחות לא יוכלו לאשר הזמנה חדשה' : 'After this time customers cannot confirm new orders';
  String get managerOrderMaxSection => _he ? 'מכסת הזמנות' : 'Order quantity cap';
  String get managerOrderMaxHint => _he
      ? 'ספירה לפי הזמנות שאושרו באפליקציה (לא כולל ביטולים)'
      : 'Counts confirmed in-app orders (excludes cancellations)';
  String get managerOrderMaxCount => _he ? 'מספר הזמנות מקסימלי' : 'Maximum orders';
  String get orderLimitPeriodDay => _he ? 'היום' : 'today';
  String get orderLimitPeriodWeek => _he ? 'השבוע' : 'this week';
  String managerOrderCurrentCount(int n) => _he ? 'כרגע: $n הזמנות בתקופה' : 'Currently: $n orders in period';
  String orderBlockedCutoff(String time) => _he
      ? 'ההזמנות נסגרו להיום (מועד אחרון: $time)'
      : 'Orders are closed for today (cutoff: $time)';
  String orderBlockedMaxOrders(int max, String period, int current) => _he
      ? 'הגענו למכסה של $max הזמנות ל$period ($current/$max)'
      : 'Order limit reached: $max orders for $period ($current/$max)';
  String get managerLogout => _he ? 'יציאה מהפאנל' : 'Leave manager panel';
  String get managerActiveDeals => _he ? 'דילים פעילים' : 'Active deals';
  String get managerCustomDeals => _he ? 'דילים שהוספת' : 'Deals you added';
  String get managerNoInquiries => _he ? 'אין פניות עדיין' : 'No inquiries yet';
  String get managerNoReviews => _he ? 'אין חוות דעת עדיין' : 'No reviews yet';
  String get managerReviewsSectionHint => _he ? 'חוות דעת והמלצות' : 'Reviews & ratings';
  String get managerInquiriesSection => _he ? 'פניות לקוחות' : 'Customer inquiries';
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
  String get managerDealPublished => _he ? 'הדיל פורסם במבצעים' : 'Deal published in Deals';
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
  String get contactSub => _he ? 'מייל או צ׳אט קהילה' : 'Email or community chat';
  String get contactEmailTab => _he ? 'מייל' : 'Email';
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
  String get saasCreateStore => _he ? 'יצירת חנות' : 'Create Store';
  String get saasCreateStoreSub => _he ? 'חנות אונליין עם קישור ציבורי' : 'Online store with public link';
  String get legalPrivacyPolicy => _he ? 'מדיניות פרטיות' : 'Privacy Policy';
  String get legalTermsOfUse => _he ? 'תנאי שימוש' : 'Terms of Use';
  String get legalPrivacySub => _he ? 'טיוטת פיילוט — Peymiz' : 'Peymiz pilot draft';
  String get legalTermsSub => _he ? 'טיוטת פיילוט — Peymiz' : 'Peymiz pilot draft';
  String get legalAcceptPrefix => _he ? 'אני מסכים/ה ל' : 'I agree to the ';
  String get legalAcceptMiddle => _he ? ' ול' : ' and ';
  String get legalAcceptSuffix => _he ? '.' : '.';
  String get legalTermsLink => _he ? 'תנאי השימוש' : 'Terms of Use';
  String get legalPrivacyLink => _he ? 'מדיניות הפרטיות' : 'Privacy Policy';
  String get legalMustAccept => _he
      ? 'יש לאשר את תנאי השימוש ומדיניות הפרטיות לפני יצירת חנות.'
      : 'You must accept the Terms of Use and Privacy Policy before creating a store.';
  String get language => _he ? 'שפה' : 'Language';
  String get languageSub => _he ? 'עברית או אנגלית' : 'Hebrew or English';
  String get languageCurrentHe => _he ? 'עברית' : 'Hebrew';
  String get languageCurrentEn => _he ? 'אנגלית' : 'English';
  String get chooseLanguage => _he ? 'בחר שפה' : 'Choose language';

  String get displayMode => _he ? 'מצב תצוגה' : 'Display mode';
  String get displayModeSub => _he ? 'רגוע, בהיר או כהה' : 'Calm, light, or dark';
  String get chooseDisplayMode => _he ? 'בחר מצב תצוגה' : 'Choose display mode';

  String get appearance => _he ? 'מראה' : 'Appearance';
  String get themeCalm => _he ? 'מצב רגוע' : 'Calm mode';
  String get themeCalmSub => _he ? 'חום שמנת — כמו עכשיו' : 'Cream & brown — current look';
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
  String get newDealAlertTitle => _he ? 'מבצע חדש!' : 'New deal!';

  String get faqTitle => _he ? 'שאלות נפוצות' : 'FAQ';
  String get contactTitle => _he ? 'צור קשר' : 'Contact us';
  String get contactFormHint => _he ? 'מלאו פרטים ונחזור אליכם' : 'Fill in your details and we will get back to you';
  String get yourName => _he ? 'שם מלא' : 'Full name';
  String get yourEmail => _he ? 'אימייל' : 'Email';
  String get yourMessage => _he ? 'הודעה' : 'Message';
  String get sendMessage => _he ? 'שליחה' : 'Send';
  String get messageSent => _he ? 'ההודעה נשלחה! ניצור קשר בקרוב.' : 'Message sent! We will contact you soon.';
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
  String get confirmOrder => _he ? 'תשלום ואישור הזמנה' : 'Pay & confirm order';
  String get orderConfirmed => _he ? 'ההזמנה שולמה ואושרה!' : 'Order paid and confirmed!';
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
