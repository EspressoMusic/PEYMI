import 'package:flutter/material.dart';

import '../../core/app_theme_mode.dart';
import '../../core/manager_store.dart';
import '../data/saas_repository.dart';
import '../models/appointment_models.dart';
import '../models/saas_models.dart';
import '../utils/appointment_strings.dart';
import 'appointment_booking_screen.dart';

enum _CalendarView { today, week, month }

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
  _CalendarView _view = _CalendarView.week;
  DateTime _anchor = DateTime.now();
  late DateTime _selectedDay;
  PublicAppointmentSchedule? _schedule;
  var _loading = true;
  String? _error;

  static const _embeddedTopPadding = 12.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    if (widget.embedded) {
      ManagerStore.instance.ensureAppointmentModeReady().then((_) {
        if (mounted) _load();
      });
    } else {
      _load();
    }
  }

  DateTime get _weekStart {
    final d = DateTime(_anchor.year, _anchor.month, _anchor.day);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  (DateTime, DateTime) get _range {
    switch (_view) {
      case _CalendarView.today:
        final t = DateTime(_anchor.year, _anchor.month, _anchor.day);
        return (t, t);
      case _CalendarView.week:
        final start = _weekStart;
        return (start, start.add(const Duration(days: 6)));
      case _CalendarView.month:
        final first = DateTime(_anchor.year, _anchor.month, 1);
        final last = DateTime(_anchor.year, _anchor.month + 1, 0);
        return (first, last);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (from, to) = _range;
      final schedule = await SaasRepository.instance.fetchPublicAppointmentSchedule(
        slug: widget.business.slug,
        from: from,
        to: to,
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

  void _setView(_CalendarView v) {
    if (_view == v) return;
    setState(() => _view = v);
    _load();
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
    if (booked == true && mounted) _load();
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
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: AppointmentStrings.yourName),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppointmentStrings.namePhoneRequired)),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppointmentStrings.waitlistSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _shiftPeriod(int direction) {
    setState(() {
      if (_view == _CalendarView.month) {
        _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
      } else {
        _anchor = _anchor.add(Duration(days: 7 * direction));
        _selectedDay = _weekStart;
      }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleReady = _schedule != null && !_loading && _error == null;
    final canBook = widget.business.acceptsCustomers &&
        (scheduleReady ? (_schedule?.acceptsCustomers ?? false) : widget.embedded);

    final body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.embedded) SizedBox(height: _embeddedTopPadding),
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SegmentedButton<_CalendarView>(
              segments: [
                ButtonSegment(value: _CalendarView.today, label: Text(AppointmentStrings.today)),
                ButtonSegment(value: _CalendarView.week, label: Text(AppointmentStrings.week)),
                ButtonSegment(value: _CalendarView.month, label: Text(AppointmentStrings.month)),
              ],
              selected: {_view},
              onSelectionChanged: (s) => _setView(s.first),
            ),
          ),
          if (_view != _CalendarView.today)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => _shiftPeriod(-1), icon: const Icon(Icons.chevron_left)),
                  Text(
                    _view == _CalendarView.month
                        ? '${_monthName(_anchor.month)} ${_anchor.year}'
                        : '${_fmtDate(_range.$1)} – ${_fmtDate(_range.$2)}',
                    style: BakeryTheme.text(context, fontWeight: FontWeight.w700),
                  ),
                  IconButton(onPressed: () => _shiftPeriod(1), icon: const Icon(Icons.chevron_right)),
                ],
              ),
            ),
          if (_view == _CalendarView.week && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppointmentStrings.weekMeetings,
                    style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(AppointmentStrings.tapDay, style: BakeryTheme.subtitleText(context)),
                ],
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
                        child: _buildBody(canBook),
                      ),
          ),
        ],
      );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(widget.business.businessName)),
      body: body,
    );
  }

  Widget _buildBody(bool canBook) {
    switch (_view) {
      case _CalendarView.today:
        return _buildSelectedDayPanel(
          DateTime(_anchor.year, _anchor.month, _anchor.day),
          canBook,
        );
      case _CalendarView.week:
        return _buildWeekJournal(canBook);
      case _CalendarView.month:
        return _buildMonthGrid(canBook);
    }
  }

  Widget _buildWeekJournal(bool canBook) {
    return Column(
      children: [
        SizedBox(
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: 7,
            itemBuilder: (_, i) {
              final day = _weekStart.add(Duration(days: i));
              return _weekDayChip(day, canBook);
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildSelectedDayPanel(_selectedDay, canBook)),
      ],
    );
  }

  Widget _weekDayChip(DateTime day, bool canBook) {
    final info = _dayFor(day);
    final selected = _sameDay(day, _selectedDay);
    final isToday = _sameDay(day, DateTime.now());

    String statusLabel;
    Color statusColor;
    if (info == null) {
      statusLabel = '…';
      statusColor = Colors.grey;
    } else if (info.closed) {
      statusLabel = AppointmentStrings.closed;
      statusColor = Colors.grey;
    } else if (info.fullyBooked) {
      statusLabel = AppointmentStrings.full;
      statusColor = Colors.orange;
    } else {
      statusLabel = '${info.availableCount}';
      statusColor = Colors.green.shade700;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        elevation: selected ? 3 : 0,
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => setState(() => _selectedDay = DateTime(day.year, day.month, day.day)),
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppointmentStrings.dayName(day.weekday % 7),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isToday ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                Text(
                  '${day.day}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayPanel(DateTime day, bool canBook) {
    final info = _dayFor(day);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _fmtDate(day),
          style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(AppointmentStrings.pickDayAndTime, style: BakeryTheme.subtitleText(context)),
        const SizedBox(height: 16),
        if (info == null)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (info.closed)
          Text(AppointmentStrings.closed, style: const TextStyle(color: Colors.grey, fontSize: 16))
        else if (info.slots.isEmpty)
          Text(AppointmentStrings.noSlots, style: const TextStyle(color: Colors.grey, fontSize: 16))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final slot in info.slots)
                _slotChip(day, slot, canBook),
            ],
          ),
      ],
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

  Widget _buildMonthGrid(bool canBook) {
    final first = DateTime(_anchor.year, _anchor.month, 1);
    final leading = first.weekday % 7;
    final daysInMonth = DateTime(_anchor.year, _anchor.month + 1, 0).day;
    final total = leading + daysInMonth;
    final rows = (total / 7).ceil();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            7,
            (i) => Text(
              AppointmentStrings.dayName(i),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              if (index < leading || index >= leading + daysInMonth) {
                return const Expanded(child: SizedBox(height: 72));
              }
              final dayNum = index - leading + 1;
              final date = DateTime(_anchor.year, _anchor.month, dayNum);
              final info = _dayFor(date);
              return Expanded(child: _monthCell(date, info, canBook));
            }),
          );
        }),
      ],
    );
  }

  Widget _monthCell(DateTime date, AppointmentScheduleDay? info, bool canBook) {
    String label;
    Color? bg;
    if (info == null || info.closed) {
      label = AppointmentStrings.closed;
      bg = Colors.grey.shade200;
    } else if (info.fullyBooked) {
      label = AppointmentStrings.full;
      bg = Colors.orange.shade100;
    } else {
      label = '${info.availableCount}';
      bg = Colors.green.shade100;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            setState(() {
              _view = _CalendarView.week;
              _anchor = date;
              _selectedDay = DateTime(date.year, date.month, date.day);
            });
            _load();
          },
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _monthName(int m) {
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const he = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
    ];
    return AppointmentStrings.isHebrew ? he[m - 1] : en[m - 1];
  }
}
