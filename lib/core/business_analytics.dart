import 'business_store.dart' show BusinessOrderRecord;

enum RevenuePeriod { week, month, year }

class RevenueBucket {
  const RevenueBucket({required this.label, required this.amount});

  final String label;
  final double amount;
}

List<RevenueBucket> buildRevenueBuckets({
  required List<BusinessOrderRecord> orders,
  required RevenuePeriod period,
  required bool hebrew,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (period) {
    case RevenuePeriod.week:
      final labels = hebrew
          ? ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש']
          : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final amounts = List<double>.filled(7, 0);
      for (final o in orders) {
        final dt = DateTime.fromMillisecondsSinceEpoch(o.createdAtMs);
        final day = DateTime(dt.year, dt.month, dt.day);
        final diff = today.difference(day).inDays;
        if (diff >= 0 && diff < 7) {
          amounts[6 - diff] += o.revenueShekels;
        }
      }
      return List.generate(7, (i) => RevenueBucket(label: labels[i], amount: amounts[i]));

    case RevenuePeriod.month:
      final amounts = List<double>.filled(4, 0);
      final weekLabels = hebrew ? ['שב׳ 1', 'שב׳ 2', 'שב׳ 3', 'שב׳ 4'] : ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      for (final o in orders) {
        final dt = DateTime.fromMillisecondsSinceEpoch(o.createdAtMs);
        final day = DateTime(dt.year, dt.month, dt.day);
        final diff = today.difference(day).inDays;
        if (diff >= 0 && diff < 28) {
          final bucket = 3 - (diff ~/ 7);
          amounts[bucket] += o.revenueShekels;
        }
      }
      return List.generate(4, (i) => RevenueBucket(label: weekLabels[i], amount: amounts[i]));

    case RevenuePeriod.year:
      final amounts = List<double>.filled(12, 0);
      for (final o in orders) {
        final dt = DateTime.fromMillisecondsSinceEpoch(o.createdAtMs);
        if (dt.year == now.year) {
          amounts[dt.month - 1] += o.revenueShekels;
        }
      }
      final monthLabels = hebrew
          ? ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']
          : ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
      return List.generate(12, (i) => RevenueBucket(label: monthLabels[i], amount: amounts[i]));
  }
}

double sumBuckets(List<RevenueBucket> buckets) => buckets.fold(0, (s, b) => s + b.amount);

List<RevenueBucket> buildOrderCountBuckets({
  required List<BusinessOrderRecord> orders,
  required RevenuePeriod period,
  required bool hebrew,
}) {
  final revenueBuckets = buildRevenueBuckets(orders: orders, period: period, hebrew: hebrew);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final counts = List<double>.filled(revenueBuckets.length, 0);

  for (final o in orders) {
    final dt = DateTime.fromMillisecondsSinceEpoch(o.createdAtMs);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;

    switch (period) {
      case RevenuePeriod.week:
        if (diff >= 0 && diff < 7) counts[6 - diff] += 1;
        break;
      case RevenuePeriod.month:
        if (diff >= 0 && diff < 28) counts[3 - (diff ~/ 7)] += 1;
        break;
      case RevenuePeriod.year:
        if (dt.year == now.year) counts[dt.month - 1] += 1;
        break;
    }
  }

  return List.generate(
    revenueBuckets.length,
    (i) => RevenueBucket(label: revenueBuckets[i].label, amount: counts[i]),
  );
}

/// Positive = growing vs previous window of same length.
double revenueTrendPercent(List<BusinessOrderRecord> orders, RevenuePeriod period) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  double current = 0;
  double previous = 0;

  for (final o in orders) {
    final dt = DateTime.fromMillisecondsSinceEpoch(o.createdAtMs);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    final rev = o.revenueShekels.toDouble();

    switch (period) {
      case RevenuePeriod.week:
        if (diff >= 0 && diff < 7) current += rev;
        else if (diff >= 7 && diff < 14) previous += rev;
        break;
      case RevenuePeriod.month:
        if (diff >= 0 && diff < 28) current += rev;
        else if (diff >= 28 && diff < 56) previous += rev;
        break;
      case RevenuePeriod.year:
        if (dt.year == now.year) current += rev;
        else if (dt.year == now.year - 1) previous += rev;
        break;
    }
  }

  if (previous <= 0) return current > 0 ? 100 : 0;
  return ((current - previous) / previous) * 100;
}
