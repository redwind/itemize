import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/review_status.dart';
import 'package:inventa/data/models/asset.dart';

Asset asset({
  String id = 'a',
  String name = 'Sofa',
  DateTime? lastReviewedAt,
}) => Asset(
  id: id,
  name: name,
  price: 100,
  currency: 'USD',
  room: 'Living Room',
  category: 'Furniture',
  purchaseDate: DateTime(2020, 1, 1),
  lastReviewedAt: lastReviewedAt,
);

void main() {
  final now = DateTime(2026, 7, 28);

  group('what needs confirming', () {
    test('an entry never confirmed does', () {
      expect(ReviewStatus.needsReview(asset(), now: now), isTrue);
    });

    test('an entry confirmed recently does not', () {
      expect(
        ReviewStatus.needsReview(
          asset(lastReviewedAt: DateTime(2026, 6, 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('an entry confirmed over a year ago does', () {
      expect(
        ReviewStatus.needsReview(
          asset(lastReviewedAt: DateTime(2025, 1, 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('the boundary is a full year', () {
      final exactlyAYear = now.subtract(
        const Duration(days: ReviewStatus.staleAfterDays),
      );
      final dayShort = now.subtract(
        const Duration(days: ReviewStatus.staleAfterDays - 1),
      );

      expect(
        ReviewStatus.needsReview(asset(lastReviewedAt: exactlyAYear), now: now),
        isTrue,
      );
      expect(
        ReviewStatus.needsReview(asset(lastReviewedAt: dayShort), now: now),
        isFalse,
      );
    });
  });

  group('ordering', () {
    test('never-confirmed entries come before merely-stale ones', () {
      final ordered = ReviewStatus.needingReview([
        asset(id: 'stale', lastReviewedAt: DateTime(2024, 1, 1)),
        asset(id: 'never'),
      ], now: now);

      expect(ordered.map((a) => a.id), ['never', 'stale']);
    });

    test('the longest unconfirmed comes first among the stale', () {
      final ordered = ReviewStatus.needingReview([
        asset(id: 'b', lastReviewedAt: DateTime(2024, 6, 1)),
        asset(id: 'a', lastReviewedAt: DateTime(2023, 1, 1)),
        asset(id: 'c', lastReviewedAt: DateTime(2025, 1, 1)),
      ], now: now);

      expect(ordered.map((a) => a.id), ['a', 'b', 'c']);
    });

    test('never-confirmed entries are ordered by name between themselves', () {
      final ordered = ReviewStatus.needingReview([
        asset(id: 'z', name: 'Zebra'),
        asset(id: 'a', name: 'Anvil'),
      ], now: now);

      expect(ordered.map((a) => a.name), ['Anvil', 'Zebra']);
    });

    test('fresh entries are left out entirely', () {
      final ordered = ReviewStatus.needingReview([
        asset(id: 'fresh', lastReviewedAt: DateTime(2026, 7, 1)),
        asset(id: 'old'),
      ], now: now);

      expect(ordered.map((a) => a.id), ['old']);
    });
  });

  group('the batch', () {
    test('is capped, so the prompt stays a minute of work', () {
      final many = [for (var i = 0; i < 40; i++) asset(id: '$i', name: 'It $i')];
      expect(
        ReviewStatus.nextBatch(many, now: now),
        hasLength(ReviewStatus.batchSize),
      );
    });

    test('takes the most overdue first', () {
      final assets = [
        asset(id: 'recent', lastReviewedAt: DateTime(2025, 6, 1)),
        asset(id: 'ancient', lastReviewedAt: DateTime(2020, 1, 1)),
      ];
      expect(ReviewStatus.nextBatch(assets, now: now).first.id, 'ancient');
    });

    test('is empty when everything has been confirmed lately', () {
      expect(
        ReviewStatus.nextBatch([
          asset(lastReviewedAt: DateTime(2026, 7, 1)),
        ], now: now),
        isEmpty,
      );
    });
  });

  test('days since review is null when it never happened', () {
    expect(ReviewStatus.daysSinceReview(asset(), now: now), isNull);
    expect(
      ReviewStatus.daysSinceReview(
        asset(lastReviewedAt: DateTime(2026, 7, 18)),
        now: now,
      ),
      10,
    );
  });
}
