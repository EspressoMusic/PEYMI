import 'dart:convert';



import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';



import 'app_locale.dart';

import 'business_analytics.dart';
import 'business_store.dart';



class CustomerReview {

  const CustomerReview({

    required this.nameHe,

    required this.nameEn,

    required this.rating,

    required this.commentHe,

    required this.commentEn,

    required this.createdAtMs,

    this.managerReplyHe = '',

    this.managerReplyEn = '',

  });



  final String nameHe;

  final String nameEn;

  final int rating;

  final String commentHe;

  final String commentEn;

  final int createdAtMs;

  final String managerReplyHe;

  final String managerReplyEn;



  String name(bool hebrew) => hebrew ? nameHe : nameEn;

  String comment(bool hebrew) {

    final primary = hebrew ? commentHe : commentEn;

    if (primary.isNotEmpty) return primary;

    return hebrew ? commentEn : commentHe;

  }



  String managerReply(bool hebrew) => hebrew ? managerReplyHe : managerReplyEn;

  bool get hasManagerReply => managerReplyHe.trim().isNotEmpty || managerReplyEn.trim().isNotEmpty;

  /// 1–2 stars — highlighted for manager attention.
  bool get isPoorReview => rating <= 2;



  Map<String, dynamic> toJson() => {

        'nameHe': nameHe,

        'nameEn': nameEn,

        'rating': rating,

        'commentHe': commentHe,

        'commentEn': commentEn,

        'createdAtMs': createdAtMs,

        'managerReplyHe': managerReplyHe,

        'managerReplyEn': managerReplyEn,

      };



  factory CustomerReview.fromJson(Map<String, dynamic> json) {

    return CustomerReview(

      nameHe: json['nameHe'] as String? ?? '',

      nameEn: json['nameEn'] as String? ?? '',

      rating: ((json['rating'] as num?)?.toInt() ?? 5).clamp(1, 5),

      commentHe: json['commentHe'] as String? ?? '',

      commentEn: json['commentEn'] as String? ?? '',

      createdAtMs: json['createdAtMs'] as int? ?? 0,

      managerReplyHe: json['managerReplyHe'] as String? ?? '',

      managerReplyEn: json['managerReplyEn'] as String? ?? '',

    );

  }

}



class ReviewsStore extends ChangeNotifier {

  ReviewsStore._();



  static final ReviewsStore instance = ReviewsStore._();

  static const _storageKey = 'customer_reviews_v1';



  final List<CustomerReview> _reviews = [];



  List<CustomerReview> get reviews => List.unmodifiable(_reviews);



  static bool _sameReview(CustomerReview a, CustomerReview b) =>
      a.createdAtMs == b.createdAtMs && a.nameHe == b.nameHe && a.nameEn == b.nameEn;

  /// Poor reviews with a manager reply no longer drag satisfaction metrics down.
  static double effectiveRating(CustomerReview target, List<CustomerReview> reviews) {
    if (!target.isPoorReview || !target.hasManagerReply) {
      return target.rating.toDouble();
    }
    double sum = 0;
    var count = 0;
    for (final r in reviews) {
      if (_sameReview(r, target)) continue;
      sum += effectiveRating(r, reviews);
      count++;
    }
    if (count == 0) return 4;
    return sum / count;
  }

  double _effectiveRating(CustomerReview r) => effectiveRating(r, _reviews);

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.map(_effectiveRating).reduce((a, b) => a + b) / _reviews.length;
  }

  int get happyCustomersCount => _reviews.where((r) => _effectiveRating(r) >= 4).length;

  int happyPercent() {
    if (_reviews.isEmpty) return 0;
    return ((happyCustomersCount / _reviews.length) * 100).round();
  }

  List<RevenueBucket> ratingDistribution() {
    final counts = List<int>.filled(5, 0);
    for (final r in _reviews) {
      final stars = _effectiveRating(r).round().clamp(1, 5);
      counts[stars - 1]++;
    }
    return List.generate(5, (i) => RevenueBucket(label: '${i + 1}★', amount: counts[i].toDouble()));
  }



  static List<CustomerReview> get _seedReviews => [

        const CustomerReview(

          nameHe: 'דנה כ.',

          nameEn: 'Dana K.',

          rating: 5,

          commentHe: 'המאפים תמיד טריים והשירות מעולה. ממליצה בחום!',

          commentEn: 'Pastries are always fresh and service is excellent. Highly recommend!',

          createdAtMs: 0,

        ),

        const CustomerReview(

          nameHe: 'יוסי ל.',

          nameEn: 'Yossi L.',

          rating: 4,

          commentHe: 'קוראסון מושלם ומשלוח מהיר. חוויה נהדרת.',

          commentEn: 'Perfect croissant and fast delivery. Great experience.',

          createdAtMs: 0,

        ),

        const CustomerReview(

          nameHe: 'מיכל ר.',

          nameEn: 'Michal R.',

          rating: 5,

          commentHe: 'העוגות מדהימות והאפליקציה נוחה להזמנה.',

          commentEn: 'Amazing cakes and the app is easy to order from.',

          createdAtMs: 0,

        ),

        const CustomerReview(

          nameHe: 'אבי מ.',

          nameEn: 'Avi M.',

          rating: 5,

          commentHe: 'דילים שווים וטעם ביתי אמיתי.',

          commentEn: 'Great deals and a real homestyle taste.',

          createdAtMs: 0,

        ),

      ];



  Future<void> load() async {

    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_storageKey);

    _reviews.clear();

    if (raw == null || raw.isEmpty) {

      final now = DateTime.now().millisecondsSinceEpoch;

      for (var i = 0; i < _seedReviews.length; i++) {

        final seed = _seedReviews[i];

        _reviews.add(

          CustomerReview(

            nameHe: seed.nameHe,

            nameEn: seed.nameEn,

            rating: seed.rating,

            commentHe: seed.commentHe,

            commentEn: seed.commentEn,

            createdAtMs: now - (i + 2) * 86400000,

          ),

        );

      }

      await _persist();

    } else {

      try {

        final decoded = jsonDecode(raw);

        if (decoded is List) {

          for (final entry in decoded) {

            if (entry is Map<String, dynamic>) {

              _reviews.add(CustomerReview.fromJson(entry));

            } else if (entry is Map) {

              _reviews.add(CustomerReview.fromJson(Map<String, dynamic>.from(entry)));

            }

          }

          _reviews.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

        }

      } catch (_) {

        _reviews.clear();

      }

    }

    notifyListeners();

  }



  Future<void> addReview({required int rating, required String comment}) async {

    final trimmed = comment.trim();

    final he = AppLocale.instance.isHebrew;

    final text = trimmed.isEmpty ? (he ? 'חוויה מעולה!' : 'Great experience!') : trimmed;

    _reviews.insert(

      0,

      CustomerReview(

        nameHe: 'אורח',

        nameEn: 'Guest',

        rating: rating.clamp(1, 5),

        commentHe: he ? text : '',

        commentEn: he ? '' : text,

        createdAtMs: DateTime.now().millisecondsSinceEpoch,

      ),

    );

    await _persist();

    await BusinessStore.instance.recordReview();

    notifyListeners();

  }



  /// Returns true when saving a reply to a poor review restores satisfaction metrics.
  Future<bool> setManagerReply(int index, String reply) async {
    if (index < 0 || index >= _reviews.length) return false;

    final trimmed = reply.trim();
    final old = _reviews[index];
    final willRecoverStats = old.isPoorReview && trimmed.isNotEmpty;

    _reviews[index] = CustomerReview(
      nameHe: old.nameHe,
      nameEn: old.nameEn,
      rating: old.rating,
      commentHe: old.commentHe,
      commentEn: old.commentEn,
      createdAtMs: old.createdAtMs,
      managerReplyHe: trimmed,
      managerReplyEn: trimmed,
    );

    await _persist();
    notifyListeners();
    return willRecoverStats;
  }



  Future<void> _persist() async {

    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(_reviews.map((r) => r.toJson()).toList());

    await prefs.setString(_storageKey, encoded);

  }

}

