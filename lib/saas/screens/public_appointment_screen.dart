import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme_mode.dart';
import '../../widgets/bakery_celebration.dart';
import '../../widgets/customer_name_field.dart';
import '../../core/manager_store.dart';
import '../data/saas_repository.dart';
import '../models/appointment_models.dart';
import '../models/saas_models.dart';
import '../utils/appointment_strings.dart';
import 'appointment_booking_screen.dart';

class PublicAppointmentScreen extends StatefulWidget {
  const PublicAppointmentScreen({
    super.key,
    required this.business,
    this.embedded = false,
  });

  final SaasBusiness business;
  final bool embedded;

  @override
  State<PublicAppointmentScreen> createState() => _PublicAppointmentScreenState();
}

class _PublicAppointmentScreenState extends State<PublicAppointmentScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  PublicAppointmentSchedule? _schedule;
  var _loading = true;
  String? _error;

  static const _embeddedTopPadding = 12.0;
  static const _dayCellHeight = 54.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    if (widget.embedded) {
      ManagerStore.instance.ensureAppointmentModeReady().then((_) {
        if (mounted) _load();
      });
    } else {
      _load();
    }
  }

  DateTime get _monthStart => DateTime(_focusedMonth.year, _focusedMonth.month, 1);

  DateTime get _monthEnd => DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isPastDay(DateTime day) {
    final today = DateTime.now();
    final tn = DateTime(today.year, today.month, today.day);
    final d = DateTime(day.year, day.month, day.day);
    return d.isBefore(tn);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final schedule = await SaasRepository.instance.fetchPublicAppointmentSchedule(
        slug: widget.business.slug,
        from: _monthStart,
        to: _monthEnd,
      );
      if (!mounted) return;
      setState(() {
        _schedule = schedule;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppointmentStrings.friendlyError(e);
        _loading = false;
      });
    }
  }

  AppointmentScheduleDay? _dayFor(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    for (final d in _schedule?.days ?? const <AppointmentScheduleDay>[]) {
      final dk = DateTime(d.date.year, d.date.month, d.date.day);
      if (dk == key) return d;
    }
    return null;
  }

  Future<void> _openBooking(DateTime date, String time) async {
    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentBookingScreen(
          business: widget.business,
          date: date,
          time: time,
        ),
      ),
    );
    if (booked == true && mounted) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      _load();
    }
  }

  Future<void> _waitlistSlot(DateTime date, String time) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppointmentStrings.notifyIfOpens),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_fmtDate(date)} · $time'),
            const SizedBox(height: 12),
            CustomerNameField(
              controller: nameCtrl,
              label: AppointmentStrings.yourName.replaceAll(' *', ''),
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: AppointmentStrings.phone),
            ),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: AppointmentStrings.emailOptional),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppointmentStrings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppointmentStrings.save)),
        ],
      ),
    );

    if (ok != true) return;
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      if (mounted) {
        unawaited(showBakeryNoticeBanner(context, title: AppointmentStrings.namePhoneRequired, isError: true));
      }
      return;
    }
    try {
      await SaasRepository.instance.joinAppointmentWaitlist(
        businessId: widget.business.id,
        date: date,
        timeHHmm: time,
        customerName: nameCtrl.text.trim(),
        customerPhone: phoneCtrl.text.trim(),
        customerEmail: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      );
      if (mounted) {
        await showBakeryUpdateBanner(context, title: AppointmentStrings.waitlistSaved);
      }
    } catch (e) {
      if (mounted) {
        unawaited(showBakeryNoticeBanner(context, title: AppointmentStrings.friendlyError(e), isError: true));
      }
    }
  }

  void _shiftMonth(int direction) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + direction, 1);
      _selectedDay = null;
    });
    _load();
  }

  void _selectDay(DateTime day) {
    if (_isPastDay(day)) return;
    setState(() => _selectedDay = DateTime(day.year, day.month, day.day));
  }

  void _clearSelectedDay() {
    setState(() => _selectedDay = null);
  }

  Widget _buildDaySlotsPanel(BuildContext context, DateTime day, bool canBook) {
    final info = _dayFor(day);

    if (info == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (info.closed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          AppointmentStrings.closed,
          textAlign: TextAlign.center,
          style: BakeryTheme.subtitleText(context, fontSize: 15),
        ),
      );
    }
    if (info.slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          AppointmentStrings.noSlots,
          textAlign: TextAlign.center,
          style: BakeryTheme.subtitleText(context, fontSize: 15),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [for (final slot in info.slots) _slotChip(day, slot, canBook)],
    );
  }

  Widget _buildMonthCalendar(BuildContext context, bool canBook) {
    final daysInMonth = _monthEnd.day;
    final leadBlank = _monthStart.weekday % 7;
    final totalCells = leadBlank + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    final headers = AppointmentStrings.weekdayHeaders;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: BoxDecoration(
        color: BakeryTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BakeryTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final label in headers)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: BakeryTheme.text(context, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(rowCount, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  if (cellIndex < leadBlank || cellIndex >= leadBlank + daysInMonth) {
                    return const Expanded(child: SizedBox(height: _dayCellHeight));
                  }
                  final dayNum = cellIndex - leadBlank + 1;
                  final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                  return Expanded(child: _dayCell(context, day, canBook));
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _dayCell(BuildContext context, DateTime day, bool canBook) {
    final info = _dayFor(day);
    final selected = _selectedDay != null && _sameDay(day, _selectedDay!);
    final isToday = _sameDay(day, DateTime.now());
    final isPast = _isPastDay(day);
    final accent = BakeryTheme.accent(context);

    Color? fill;
    Color borderColor = Colors.transparent;
    double borderWidth = 1.2;

    if (selected) {
      fill = Theme.of(context).colorScheme.primaryContainer;
      borderColor = accent;
      borderWidth = 2;
    } else if (isPast) {
      fill = BakeryTheme.inputFill(context).withValues(alpha: 0.45);
    } else {
      fill = BakeryTheme.appointmentTileSurface(context);
    }

    Color statusColor = Colors.grey;
    if (!isPast && info != null) {
      if (info.closed) {
        statusColor = Colors.grey;
      } else if (info.fullyBooked) {
        statusColor = Colors.orange.shade700;
      } else if (info.availableCount > 0) {
        statusColor = Colors.green.shade700;
      }
    }

    final tappable = !isPast && canBook;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: tappable ? () => _selectDay(day) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: _dayCellHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday && !selected ? accent.withValues(alpha: 0.7) : borderColor,
                width: isToday && !selected ? 1.6 : borderWidth,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: BakeryTheme.text(
                    context,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isPast ? BakeryTheme.muted(context) : null,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isPast ? Colors.transparent : statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsSection(BuildContext context, bool canBook) {
    final day = _selectedDay!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: BakeryTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BakeryTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _clearSelectedDay,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: AppointmentStrings.backToCalendar,
              ),
              Expanded(
                child: Text(
                  '${AppointmentStrings.slotsForDay} · ${_fmtDate(day)}',
                  textAlign: TextAlign.center,
                  style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppointmentStrings.chooseAvailableTime,
            textAlign: TextAlign.center,
            style: BakeryTheme.subtitleText(context, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _buildDaySlotsPanel(context, day, canBook),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleReady = _schedule != null && !_loading && _error == null;
    final canBook = widget.business.acceptsCustomers &&
        (scheduleReady ? (_schedule?.acceptsCustomers ?? false) : widget.embedded);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.embedded) const SizedBox(height: _embeddedTopPadding),
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              widget.business.businessName,
              style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        if (!canBook && !_loading && _error == null)
          Container(
            width: double.infinity,
            color: Colors.red.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
            child: Text(
              AppointmentStrings.unavailable,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(
            children: [
              IconButton(onPressed: _loading ? null : () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text(
                  AppointmentStrings.monthYear(_focusedMonth),
                  textAlign: TextAlign.center,
                  style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(onPressed: _loading ? null : () => _shiftMonth(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        if (!_loading && _error == null && _selectedDay == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              AppointmentStrings.tapDay,
              textAlign: TextAlign.center,
              style: BakeryTheme.subtitleText(context, fontSize: 14),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: BakeryTheme.text(context, fontSize: 16),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final showSlots = _selectedDay != null;
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                            children: [
                              if (!showSlots)
                                SizedBox(
                                  height: (constraints.maxHeight - 24).clamp(280.0, double.infinity),
                                  child: Center(child: _buildMonthCalendar(context, canBook)),
                                )
                              else ...[
                                _buildMonthCalendar(context, canBook),
                                const SizedBox(height: 16),
                                _buildSlotsSection(context, canBook),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: body,
    );
  }

  Widget _slotChip(DateTime day, AppointmentSlot slot, bool canBook) {
    final booked = slot.isBooked;
    return SizedBox(
      width: 108,
      child: Material(
        color: booked ? Colors.grey.shade200 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: !canBook
              ? null
              : booked
                  ? () => _waitlistSlot(day, slot.time)
                  : () => _openBooking(day, slot.time),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: booked ? Colors.grey.shade400 : Colors.green.shade600,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  slot.time,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: booked ? Colors.grey : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booked ? AppointmentStrings.booked : AppointmentStrings.available,
                  style: TextStyle(fontSize: 11, color: booked ? Colors.grey : Colors.green.shade800),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
