import 'package:flutter/material.dart';

import 'reviews_store.dart';

enum HealthIssueKind { poorReview, customerInquiries }

class HealthIssueAction {
  const HealthIssueAction._(this.kind, {this.reviewIndex});

  const HealthIssueAction.poorReview(int index)
      : this._(HealthIssueKind.poorReview, reviewIndex: index);

  const HealthIssueAction.customerInquiries() : this._(HealthIssueKind.customerInquiries);

  final HealthIssueKind kind;
  final int? reviewIndex;
}

class HealthFactor {
  const HealthFactor({
    required this.icon,
    required this.titleHe,
    required this.titleEn,
    required this.detailHe,
    required this.detailEn,
    this.action,
  });

  final IconData icon;
  final String titleHe;
  final String titleEn;
  final String detailHe;
  final String detailEn;
  final HealthIssueAction? action;

  String title(bool hebrew) => hebrew ? titleHe : titleEn;
  String detail(bool hebrew) => hebrew ? detailHe : detailEn;

  bool get isActionable => action != null;
}

class BusinessHealthSnapshot {
  const BusinessHealthSnapshot({required this.level, required this.factors});

  final double level;
  final List<HealthFactor> factors;

  int get percent => (level.clamp(0.0, 1.0) * 100).round();
  bool get isPerfect => percent >= 100;

  List<HealthFactor> get actionableFactors => factors.where((f) => f.isActionable).toList();
}

/// 0 = critical, 1 = excellent (100% only when truly full score).
BusinessHealthSnapshot analyzeBusinessHealth({
  required int ordersCount,
  required int inquiriesCount,
  required List<CustomerReview> reviews,
}) {
  var score = 1.0;
  final factors = <HealthFactor>[];

  final unrepliedPoor = <int>[];
  for (var i = 0; i < reviews.length; i++) {
    final r = reviews[i];
    if (r.isPoorReview && !r.hasManagerReply) unrepliedPoor.add(i);
  }

  for (final i in unrepliedPoor) {
    final r = reviews[i];
    score -= 0.2;
    factors.add(
      HealthFactor(
        icon: Icons.thumb_down_alt_rounded,
        titleHe: 'תגובה שלילית',
        titleEn: 'Negative review',
        detailHe: '${r.name(true)} · ${r.rating} כוכבים — הגיבו כדי להחזיר את הציון',
        detailEn: '${r.name(false)} · ${r.rating} stars — reply to restore your score',
        action: HealthIssueAction.poorReview(i),
      ),
    );
  }

  if (reviews.isEmpty) {
    score -= 0.12;
    factors.add(
      const HealthFactor(
        icon: Icons.star_border_rounded,
        titleHe: 'חסרות חוות דעת',
        titleEn: 'Missing reviews',
        detailHe: 'אין עדיין מספיק דירוגים — קשה לדעת שביעות רצון הלקוחות',
        detailEn: 'Not enough ratings yet to measure customer satisfaction',
      ),
    );
  } else if (unrepliedPoor.isEmpty) {
    final avg =
        reviews.map((r) => ReviewsStore.effectiveRating(r, reviews)).reduce((a, b) => a + b) / reviews.length;
    if (avg < 4.5) {
      final penalty = ((4.5 - avg) / 1.5).clamp(0.0, 1.0) * 0.28;
      score -= penalty;
      factors.add(
        HealthFactor(
          icon: Icons.star_half_rounded,
          titleHe: 'דירוג נמוך מלקוחות',
          titleEn: 'Low customer ratings',
          detailHe: 'ממוצע ${avg.toStringAsFixed(1)} כוכבים — בדקו תלונות אחרונות',
          detailEn: 'Average ${avg.toStringAsFixed(1)} stars — check recent complaints',
          action: const HealthIssueAction.customerInquiries(),
        ),
      );
    }
  }

  if (ordersCount > 0 && inquiriesCount > 0) {
    final ratio = inquiriesCount / ordersCount;
    if (ratio >= 0.12) {
      final penalty = ratio.clamp(0.0, 1.0) * 0.42;
      score -= penalty;
      factors.add(
        HealthFactor(
          icon: Icons.report_problem_outlined,
          titleHe: 'פניות ותלונות',
          titleEn: 'Inquiries & issues',
          detailHe:
              '$inquiriesCount פניות מול $ordersCount הזמנות — ייתכן משלוחים שלא התקבלו, עיכובים או בעיות שירות',
          detailEn:
              '$inquiriesCount inquiries vs $ordersCount orders — possible undelivered orders, delays, or service issues',
          action: const HealthIssueAction.customerInquiries(),
        ),
      );
    }
  } else if (inquiriesCount > 0 && ordersCount == 0) {
    score -= 0.38;
    factors.add(
      HealthFactor(
        icon: Icons.support_agent_rounded,
        titleHe: 'פניות בלי הזמנות',
        titleEn: 'Inquiries without orders',
        detailHe: 'יש $inquiriesCount פניות לקוחות אך כמעט אין הזמנות — דורש טיפול דחוף',
        detailEn: '$inquiriesCount customer contacts but almost no orders — needs urgent attention',
        action: const HealthIssueAction.customerInquiries(),
      ),
    );
  }

  if (inquiriesCount >= 3 && ordersCount < 2) {
    score -= 0.14;
    factors.add(
      const HealthFactor(
        icon: Icons.warning_amber_rounded,
        titleHe: 'עומס תלונות',
        titleEn: 'High complaint load',
        detailHe: 'ריבוי פניות ביחס למעט הזמנות — בדקו משלוחים ואיכות',
        detailEn: 'Many contacts vs few orders — check deliveries and quality',
        action: HealthIssueAction.customerInquiries(),
      ),
    );
  }

  if (ordersCount == 0 && inquiriesCount == 0 && reviews.isEmpty) {
    score -= 0.08;
    factors.add(
      const HealthFactor(
        icon: Icons.storefront_outlined,
        titleHe: 'אין עדיין פעילות',
        titleEn: 'No activity yet',
        detailHe: 'המתינו להזמנות וחוות דעת כדי למלא את המד',
        detailEn: 'Wait for orders and reviews to fill the gauge',
      ),
    );
  }

  return BusinessHealthSnapshot(
    level: score.clamp(0.0, 1.0),
    factors: factors,
  );
}

double computeBusinessHealth({
  required int ordersCount,
  required int inquiriesCount,
  required List<CustomerReview> reviews,
}) =>
    analyzeBusinessHealth(
      ordersCount: ordersCount,
      inquiriesCount: inquiriesCount,
      reviews: reviews,
    ).level;

String healthLabel(bool hebrew, double level) {
  if (level >= 0.95) return hebrew ? 'העסק במצב מצוין' : 'Business is excellent';
  if (level >= 0.65) return hebrew ? 'ביצועים טובים — יש מקום לשיפור' : 'Good — room to improve';
  if (level >= 0.4) return hebrew ? 'בינוני — שימו לב' : 'Moderate — keep an eye';
  return hebrew ? 'יש בעיות — דורש טיפול' : 'Issues detected — needs attention';
}
