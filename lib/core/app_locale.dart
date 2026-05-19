import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String get appTitle => _he ? 'מאפיית הבית' : 'Home Bakery';
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
  String get managerPrepUnits => _he ? 'יחידות בסך הכל' : 'Total units';
  String get managerShowOrders => _he ? 'הצג כל ההזמנות' : 'Show all orders';
  String get managerHideOrders => _he ? 'הסתר הזמנות' : 'Hide orders';
  String get managerHealthWhy => _he ? 'למה לא 100%?' : 'Why not 100%?';
  String get managerHealthPerfect => _he ? 'העסק במצב מצוין — 100%' : 'Excellent — 100%';
  String get managerHealthTap => _he ? 'לחצו על העיגול לפירוט' : 'Tap the ring for details';
  String get managerOrderLines => _he ? 'פירוט הזמנה' : 'Order breakdown';

  String get managerNavDashboard => _he ? 'ראשי' : 'Home';
  String get managerNavActions => _he ? 'פעולות' : 'Actions';
  String get managerNavSettings => _he ? 'הגדרות' : 'Settings';
  String get managerActionsSub => _he ? 'ניהול החנות והלקוחות' : 'Manage store & customers';
  String get managerActionCustomers => _he ? 'מענה ללקוחות' : 'Customer messages';
  String get managerActionCustomersSub => _he ? 'פניות, חוות דעת והמלצות' : 'Inquiries, reviews & ratings';
  String get managerActionUpdate => _he ? 'עדכון ללקוחות' : 'Customer update';
  String get managerActionUpdateSub => _he ? 'הודעה שמופיעה באפליקציה' : 'Message shown in the app';
  String get managerActionNewDeal => _he ? 'דיל / מבצע חדש' : 'New deal';
  String get managerActionNewDealSub => _he ? 'פרסום מבצע בלשונית מבצעים' : 'Publish in Deals tab';
  String get managerActionStoreMode => _he ? 'מצב חנות' : 'Store mode';
  String get managerActionStoreModeSub =>
      _he ? 'מוצרים או פגישות — מה הלקוחות רואים' : 'Products or appointments — customer view';
  String get managerActionStore => _he ? 'ניהול פאנל החנות' : 'Store panel';
  String get managerActionStoreSub =>
      _he ? 'קטלוג, דילים ועדכונים פעילים' : 'Catalog, deals & live updates';
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
  String get managerStatsWeekly => _he ? 'שבועי' : 'Weekly';
  String get managerStatsMonthly => _he ? 'חודשי' : 'Monthly';
  String get managerStatsYearly => _he ? 'שנתי' : 'Yearly';
  String get managerStatsRevenue => _he ? 'הכנסות' : 'Revenue';
  String get managerStatsGrowing => _he ? 'העסק בצמיחה' : 'Business is growing';
  String get managerStatsDeclining => _he ? 'ירידה בהכנסות' : 'Revenue declining';
  String get managerStatsStable => _he ? 'יציב' : 'Stable';
  String get managerBack => _he ? 'חזרה' : 'Back';
  String get managerSettingsSub => _he ? 'העדפות מנהל' : 'Manager preferences';
  String get managerLogout => _he ? 'יציאה מהפאנל' : 'Leave manager panel';
  String get managerActiveDeals => _he ? 'דילים פעילים' : 'Active deals';
  String get managerCustomDeals => _he ? 'דילים שהוספת' : 'Deals you added';
  String get managerNoInquiries => _he ? 'אין פניות עדיין' : 'No inquiries yet';
  String get managerNoReviews => _he ? 'אין חוות דעת עדיין' : 'No reviews yet';
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
  String get contactSub => _he ? 'בוט, מייל או בעל העסק' : 'Bot, email, or owner';
  String get contactBotTab => _he ? 'צ׳אט' : 'Chat';
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
  String get saasCreateStore => _he ? 'יצירת חנות' : 'Create Store';
  String get saasCreateStoreSub => _he ? 'חנות אונליין עם קישור ציבורי' : 'Online store with public link';
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
  String get themeLightSub => _he ? 'לבן ושחור' : 'White & black';
  String get themeDark => _he ? 'מצב כהה' : 'Dark mode';
  String get themeDarkSub => _he ? 'אפור-כחול עדין וקריא' : 'Soft grey-blue & readable';

  String get accessibilityTitle => _he ? 'נגישות והצהרת נגישות' : 'Accessibility statement';
  String accessibilityBody(String email) => accessibilityStatement(email);

  String accessibilityStatement(String email) => _he
      ? '''הצהרת נגישות — מאפיית הבית (אפליקציית הזמנות)

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
      : '''Accessibility Statement — Home Bakery (ordering app)

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

  String get contactCommunityTab => _he ? 'קהילה' : 'Community';
  String get contactCommunityHint => _he ? 'כתבו הודעה וראו מה אחרים כתבו' : 'Post a message and read others';
  String get contactYourName => _he ? 'השם שלכם' : 'Your name';
  String get contactPostMessage => _he ? 'פרסום הודעה' : 'Post message';
  String get contactCommunityEmpty => _he ? 'היו הראשונים לכתוב!' : 'Be the first to post!';
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

  List<({String q, String a})> get faqItems => _he
      ? [
          (q: 'מה שעות הפעילות?', a: 'א׳-ה׳ 07:00-21:00, שישי עד 14:00.'),
          (q: 'תוך כמה זמן משלוח?', a: '45-90 דקות לפי אזור ועומס.'),
          (q: 'איך משלמים?', a: 'אשראי, ביט או מזומן לשליח.'),
          (q: 'איך עוקבים אחרי הזמנה?', a: 'בלשונית הזמנות — הזמנות בתהליך והיסטוריה.'),
          (q: 'איך מממשים דיל?', a: 'בלשונית מבצעים — לאחר מימוש המוצרים עוברים להזמנה.'),
          (q: 'האם יש משלוח חינם?', a: 'לעיתים יש מבצעים — בדקו בלשונית מבצעים.'),
          (q: 'איך מבטלים הזמנה?', a: 'פנו אלינו בצ׳אט, במייל או לבעל העסק בהגדרות.'),
          (q: 'שאלות על אלרגנים?', a: 'כתבו לנו בפנייה ונחזור עם פירוט מדויק על המוצר.'),
        ]
      : [
          (q: 'What are your hours?', a: 'Sun–Thu 07:00–21:00, Fri until 14:00.'),
          (q: 'How long is delivery?', a: '45–90 minutes depending on area and load.'),
          (q: 'How can I pay?', a: 'Card, Bit, or cash to the courier.'),
          (q: 'How do I track an order?', a: 'In the Orders tab — active orders and history.'),
          (q: 'How do I redeem a deal?', a: 'In the Deals tab — items move to your order after redeeming.'),
          (q: 'Is there free delivery?', a: 'Sometimes — check the Deals tab for promotions.'),
          (q: 'How do I cancel an order?', a: 'Contact us via chat, email, or the owner in Settings.'),
          (q: 'Questions about allergens?', a: 'Message us and we will reply with exact product details.'),
        ];
}
