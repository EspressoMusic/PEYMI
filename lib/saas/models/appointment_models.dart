class AppointmentSlot {
  const AppointmentSlot({required this.time, required this.status});

  final String time;
  final String status;

  bool get isAvailable => status == 'available';
  bool get isBooked => status == 'booked';

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      time: json['time'] as String,
      status: json['status'] as String? ?? 'available',
    );
  }
}

class AppointmentScheduleDay {
  const AppointmentScheduleDay({
    required this.date,
    required this.closed,
    required this.availableCount,
    required this.fullyBooked,
    required this.slots,
  });

  final DateTime date;
  final bool closed;
  final int availableCount;
  final bool fullyBooked;
  final List<AppointmentSlot> slots;

  factory AppointmentScheduleDay.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    return AppointmentScheduleDay(
      date: DateTime.parse(json['date'] as String),
      closed: json['closed'] as bool? ?? true,
      availableCount: json['available_count'] as int? ?? 0,
      fullyBooked: json['fully_booked'] as bool? ?? false,
      slots: rawSlots
          .map((e) => AppointmentSlot.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class PublicAppointmentSchedule {
  const PublicAppointmentSchedule({
    required this.businessId,
    required this.acceptsCustomers,
    required this.slotDurationMinutes,
    required this.days,
  });

  final String businessId;
  final bool acceptsCustomers;
  final int slotDurationMinutes;
  final List<AppointmentScheduleDay> days;

  factory PublicAppointmentSchedule.fromJson(Map<String, dynamic> json) {
    if (json['error'] != null) {
      throw Exception(json['error'].toString());
    }
    final rawDays = json['days'] as List<dynamic>? ?? [];
    return PublicAppointmentSchedule(
      businessId: json['business_id'] as String,
      acceptsCustomers: json['accepts_customers'] as bool? ?? false,
      slotDurationMinutes: json['slot_duration_minutes'] as int? ?? 30,
      days: rawDays
          .map((e) => AppointmentScheduleDay.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class SaasAppointment {
  const SaasAppointment({
    required this.id,
    required this.businessId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.serviceName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.notes,
  });

  final String id;
  final String businessId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String serviceName;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String status;
  final String? notes;

  factory SaasAppointment.fromJson(Map<String, dynamic> json) {
    final timeRaw = json['appointment_time'] as String;
    final time = timeRaw.length >= 5 ? timeRaw.substring(0, 5) : timeRaw;
    return SaasAppointment(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      customerEmail: json['customer_email'] as String?,
      serviceName: json['service_name'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      appointmentTime: time,
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class AppointmentWaitlistEntry {
  const AppointmentWaitlistEntry({
    required this.id,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.customerName,
    required this.customerPhone,
    required this.notifyStatus,
  });

  final String id;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String customerName;
  final String customerPhone;
  final String notifyStatus;

  factory AppointmentWaitlistEntry.fromJson(Map<String, dynamic> json) {
    final timeRaw = json['appointment_time'] as String;
    return AppointmentWaitlistEntry(
      id: json['id'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      appointmentTime: timeRaw.length >= 5 ? timeRaw.substring(0, 5) : timeRaw,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      notifyStatus: json['notify_status'] as String? ?? 'waiting',
    );
  }
}

class BusinessAppointmentSettings {
  const BusinessAppointmentSettings({
    required this.businessId,
    required this.slotDurationMinutes,
    required this.bookingNoticeMinutes,
    required this.maxDaysAhead,
    required this.timezone,
  });

  final String businessId;
  final int slotDurationMinutes;
  final int bookingNoticeMinutes;
  final int maxDaysAhead;
  final String timezone;

  factory BusinessAppointmentSettings.fromJson(Map<String, dynamic> json) {
    return BusinessAppointmentSettings(
      businessId: json['business_id'] as String,
      slotDurationMinutes: json['slot_duration_minutes'] as int? ?? 30,
      bookingNoticeMinutes: json['booking_notice_minutes'] as int? ?? 60,
      maxDaysAhead: json['max_days_ahead'] as int? ?? 30,
      timezone: json['timezone'] as String? ?? 'Asia/Jerusalem',
    );
  }
}
