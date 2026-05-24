import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_locale.dart';

abstract final class AppointmentStrings {
  static bool get isHebrew => AppLocale.instance.isHebrew;
  static bool get _he => isHebrew;

  static String get pickDayAndTime =>
      _he ? 'בחרו יום ושעה לתור' : 'Pick a day and time for your appointment';

  static String get today => _he ? 'היום' : 'Today';
  static String get week => _he ? 'שבוע' : 'Week';
  static String get month => _he ? 'חודש' : 'Month';

  static String get available => _he ? 'פנוי' : 'Available';
  static String get booked => _he ? 'תפוס' : 'Booked';
  static String get closed => _he ? 'סגור' : 'Closed';
  static String get full => _he ? 'מלא' : 'Full';
  static String get noSlots => _he ? 'אין שעות פנויות' : 'No available times';

  static String get chooseTime => _he ? 'בחרו שעה' : 'Choose this time';
  static String get chooseAvailableTime =>
      _he ? 'בחרו שעה פנויה' : 'Choose an available time';
  static String get notifyIfOpens => _he ? 'הודיעו לי אם יתפנה' : 'Notify me if this opens';
  static String get bookAppointment => _he ? 'קביעת תור' : 'Book appointment';
  static String get yourName => _he ? 'שם מלא *' : 'Your name *';
  static String get phone => _he ? 'טלפון *' : 'Phone *';
  static String get emailOptional => _he ? 'אימייל (אופציונלי)' : 'Email (optional)';
  static String get notesOptional => _he ? 'הערות (אופציונלי)' : 'Notes (optional)';
  static String get confirmBooking => _he ? 'אשרו תור' : 'Confirm appointment';
  static String get bookingSuccess => _he ? 'התור נקבע בהצלחה' : 'Appointment booked successfully';
  static String get unavailable => _he ? 'העסק אינו זמין כרגע' : 'This business is currently unavailable';
  static String get freeSlots => _he ? 'שעות פנויות' : 'open slots';
  static String get requiredField => _he ? 'נדרש' : 'Required';
  static String get cancel => _he ? 'ביטול' : 'Cancel';
  static String get save => _he ? 'שמירה' : 'Save';
  static String get waitlistSaved => _he
      ? 'נשמר. נודיע לכם אם השעה תתפנה.'
      : 'Saved. You will be notified if this slot opens.';
  static String get namePhoneRequired =>
      _he ? 'שם וטלפון נדרשים' : 'Name and phone are required';
  static String get weekMeetings => _he ? 'יומן פגישות' : 'Appointment calendar';
  static String get tapDay =>
      _he ? 'לחצו על יום כדי לראות שעות פנויות' : 'Tap a day to see available times';
  static String get backToCalendar => _he ? 'חזרה ללוח שנה' : 'Back to calendar';
  static String get pastDay => _he ? 'יום שעבר' : 'Past day';
  static String get slotsForDay => _he ? 'שעות פנויות' : 'Available times';

  static String monthYear(DateTime date) {
    if (_he) {
      const months = [
        'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
        'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static List<String> get weekdayHeaders {
    if (!_he) return const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return const ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];
  }

  static String dayName(int weekday) {
    if (!_he) {
      const en = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return en[weekday % 7];
    }
    const he = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];
    return he[weekday % 7];
  }

  static String get storeModeButton => _he ? 'מצב חנות' : 'Store mode';
  static String get productsShort => _he ? 'מוצרים' : 'Products';
  static String get appointmentsShort => _he ? 'פגישות' : 'Appointments';
  static String get storeModeTitle => _he ? 'סוג חנות / פאנל ללקוחות' : 'Store mode / customer panel';
  static String get storeModeHint =>
      _he ? 'בחרו מה הלקוחות רואים בקישור הציבורי' : 'Choose what customers see on your public link';
  static String get productStore => _he ? 'חנות מוצרים' : 'Product Store';
  static String get productStoreSub => _he ? 'קטלוג, הזמנות, מבצעים' : 'Catalog, orders, deals';
  static String get appointmentBooking => _he ? 'קביעת תורים' : 'Appointment Booking';
  static String get appointmentBookingSub =>
      _he ? 'יומן שבועי, שעות, תורים' : 'Weekly calendar, time slots, bookings';

  static String get serverBookingNotConfigured => _he
      ? 'לא ניתן לקבוע תור כרגע. נסו שוב בעוד כמה שניות.'
      : 'Unable to book an appointment right now. Please try again in a few seconds.';

  static String friendlyError(Object error) {
    if (error is FunctionException && error.status == 404) {
      return serverBookingNotConfigured;
    }
    if (error is PostgrestException) {
      final msg = error.message ?? '';
      if (error.code == 'PGRST202' ||
          msg.contains('book_appointment') ||
          msg.contains('get_public_appointment_schedule') ||
          msg.contains('get_customer_appointments')) {
        if (msg.contains('book_appointment')) return serverBookingNotConfigured;
        if (msg.contains('get_customer_appointments')) {
          return _he
              ? 'חסרה פונקציה בשרת. ב-Supabase → SQL Editor הריצו את supabase/APPLY_GET_CUSTOMER_APPOINTMENTS.sql'
              : 'Server function missing. In Supabase SQL Editor run supabase/APPLY_GET_CUSTOMER_APPOINTMENTS.sql';
        }
      }
    }
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.contains('book_appointment') ||
        raw.contains('PGRST202') ||
        (raw.contains('NOT_FOUND') && raw.contains('function'))) {
      return serverBookingNotConfigured;
    }
    if (raw == 'not_appointment_mode') {
      return _he
          ? 'החנות עדיין במצב מוצרים בשרת. בפאנל מנהל → מצב חנות → בחרו "פגישות", או התחברו כבעלים בהגדרות → יצירת חנות.'
          : 'This store is still in product mode on the server. In Manager → Store mode → choose Appointments.';
    }
    if (raw == 'business_unavailable' || raw.contains('unavailable')) {
      return unavailable;
    }
    if (raw.contains('get_customer_appointments') || raw.contains('PGRST202')) {
      return _he
          ? 'חסרה פונקציה בשרת. ב-Supabase → SQL Editor הריצו את הקובץ supabase/APPLY_GET_CUSTOMER_APPOINTMENTS.sql'
          : 'Server function missing. In Supabase SQL Editor run supabase/APPLY_GET_CUSTOMER_APPOINTMENTS.sql';
    }
    return raw;
  }
}
