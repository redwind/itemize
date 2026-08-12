import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/free_tier.dart';

void main() {
  group('remainingFreeSlots', () {
    test('a fresh free user has the whole limit available', () {
      expect(
        remainingFreeSlots(currentCount: 0, isPro: false),
        kFreeItemLimit,
      );
    });

    test('a free user partway through has what is left', () {
      expect(remainingFreeSlots(currentCount: 25, isPro: false), 15);
    });

    test('a free user at exactly the limit has none left', () {
      expect(
        remainingFreeSlots(currentCount: kFreeItemLimit, isPro: false),
        0,
      );
    });

    test('a free user over the limit reports zero, not negative', () {
      // Reachable after a restore drops in more items than the limit allows;
      // nothing about that should read as "owes items back".
      expect(
        remainingFreeSlots(currentCount: kFreeItemLimit + 200, isPro: false),
        0,
      );
    });

    test('a Pro user is unbounded at any count', () {
      expect(remainingFreeSlots(currentCount: 0, isPro: true), isNull);
      expect(
        remainingFreeSlots(currentCount: kFreeItemLimit, isPro: true),
        isNull,
      );
      expect(
        remainingFreeSlots(currentCount: kFreeItemLimit + 1000, isPro: true),
        isNull,
      );
    });
  });

  group('fitBatch', () {
    test('a batch that fits entirely is unchanged', () {
      expect(
        fitBatch(batchSize: 12, currentCount: 20, isPro: false),
        12,
      );
    });

    test('a batch that only partly fits is trimmed to what is left', () {
      // 30 drafts from a photographed room, but only 12 slots remain.
      expect(
        fitBatch(
          batchSize: 30,
          currentCount: kFreeItemLimit - 12,
          isPro: false,
        ),
        12,
      );
    });

    test('a batch that does not fit at all returns zero', () {
      expect(
        fitBatch(batchSize: 5, currentCount: kFreeItemLimit, isPro: false),
        0,
      );
    });

    test('a zero-length batch fits trivially', () {
      expect(fitBatch(batchSize: 0, currentCount: 0, isPro: false), 0);
      expect(
        fitBatch(batchSize: 0, currentCount: kFreeItemLimit, isPro: false),
        0,
      );
    });

    test('a Pro user fits the whole batch regardless of count', () {
      expect(
        fitBatch(batchSize: 30, currentCount: kFreeItemLimit + 500, isPro: true),
        30,
      );
    });
  });
}
