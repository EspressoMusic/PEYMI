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
  static String get weekMeetings => _he ? 'מפגשים השבוע' : 'This week';
  static String get tapDay => _he ? 'לחצו על יום לבחירת שעה' : 'Tap a day to pick a time';

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

  static String friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw == 'not_appointment_mode') {
      return _he
          ? 'החנות עדיין במצב מוצרים בשרת. בפאנל מנהל → מצב חנות → בחרו "פגישות", או התחברו כבעלים בהגדרות → יצירת חנות.'
          : 'This store is still in product mode on the server. In Manager → Store mode → choose Appointments.';
    }
    if (raw == 'business_unavailable' || raw.contains('unavailable')) {
      return unavailable;
    }
    return raw;
  }
}
