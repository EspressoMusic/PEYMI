import 'package:bakery_shop_app/core/reviews_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CustomerReview.fromJson handles missing rating', () {
    final review = CustomerReview.fromJson(<String, dynamic>{});
    expect(review.rating, 5);
  });

  test('manager reply to poor review restores effective rating', () {
    const good = CustomerReview(
      nameHe: 'א',
      nameEn: 'A',
      rating: 5,
      commentHe: '',
      commentEn: '',
      createdAtMs: 1,
    );
    const poor = CustomerReview(
      nameHe: 'ב',
      nameEn: 'B',
      rating: 1,
      commentHe: 'רע',
      commentEn: 'bad',
      createdAtMs: 2,
    );
    final reviews = [good, poor];
    expect(ReviewsStore.effectiveRating(good, reviews), 5);
    expect(ReviewsStore.effectiveRating(poor, reviews), 1);

    const poorReplied = CustomerReview(
      nameHe: 'ב',
      nameEn: 'B',
      rating: 1,
      commentHe: 'רע',
      commentEn: 'bad',
      createdAtMs: 2,
      managerReplyHe: 'סליחה, נשפר',
      managerReplyEn: 'Sorry, we will improve',
    );
    final withReply = [good, poorReplied];
    expect(ReviewsStore.effectiveRating(poorReplied, withReply), 5);
    final avg = withReply.map((r) => ReviewsStore.effectiveRating(r, withReply)).reduce((a, b) => a + b) /
        withReply.length;
    expect(avg, 5);
  });
}
