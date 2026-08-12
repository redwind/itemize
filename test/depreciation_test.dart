import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/depreciation.dart';
import 'package:inventa/data/models/asset.dart';

Asset asset({
  required String category,
  required DateTime purchaseDate,
  double price = 1000,
}) => Asset(
  id: 'a',
  name: 'Thing',
  price: price,
  currency: 'USD',
  room: 'Office',
  category: category,
  purchaseDate: purchaseDate,
);

void main() {
  final today = DateTime(2026, 7, 27);

  double value(Asset a) => Depreciation.currentValue(a, asOf: today);

  group('straight-line depreciation', () {
    test('a brand new item is worth what was paid', () {
      expect(
        value(asset(category: 'Electronics', purchaseDate: today)),
        1000,
      );
    });

    test('halfway through its life it has lost about half', () {
      // Electronics run five years; two and a half years in.
      final a = asset(
        category: 'Electronics',
        purchaseDate: DateTime(2024, 1, 27),
      );
      expect(value(a), closeTo(500, 15));
    });

    test('a longer-lived category loses less over the same time', () {
      final bought = DateTime(2024, 1, 27);
      final laptop = asset(category: 'Electronics', purchaseDate: bought);
      final sofa = asset(category: 'Furniture', purchaseDate: bought);
      expect(value(sofa), greaterThan(value(laptop)));
    });
  });

  group('the floor', () {
    test('a very old item keeps the salvage share, not zero', () {
      final a = asset(
        category: 'Electronics',
        purchaseDate: DateTime(2000, 1, 1),
      );
      expect(value(a), 1000 * Depreciation.salvageFraction);
    });

    test('value never goes negative however old', () {
      final a = asset(
        category: 'Clothing',
        purchaseDate: DateTime(1970, 1, 1),
      );
      expect(value(a), greaterThan(0));
    });
  });

  group('categories that are not depreciated', () {
    test('jewellery holds its price', () {
      final a = asset(
        category: 'Jewelry & Watches',
        purchaseDate: DateTime(2001, 1, 1),
      );
      expect(value(a), 1000);
      expect(Depreciation.depreciates('Jewelry & Watches'), isFalse);
    });

    test('art holds its price', () {
      final a = asset(
        category: 'Art & Collectibles',
        purchaseDate: DateTime(2001, 1, 1),
      );
      expect(value(a), 1000);
    });
  });

  group('bad input is held, not amplified', () {
    test('a purchase date in the future does not inflate the value', () {
      final a = asset(
        category: 'Electronics',
        purchaseDate: DateTime(2030, 1, 1),
      );
      expect(value(a), 1000);
    });

    test('an unknown category falls back to the default life', () {
      final a = asset(
        category: 'Something Invented',
        purchaseDate: DateTime(2021, 7, 27),
      );
      // Default life is ten years; five years in, about half remains.
      expect(value(a), closeTo(500, 15));
    });

    test('a migrated item with no category still gets a figure', () {
      final a = asset(
        category: kUncategorized,
        purchaseDate: DateTime(2021, 7, 27),
      );
      expect(value(a), closeTo(500, 15));
    });
  });

  group('summary', () {
    test('adds up both figures in one pass', () {
      final summary = Depreciation.summarize([
        asset(category: 'Jewelry & Watches', purchaseDate: DateTime(2010, 1, 1)),
        asset(category: 'Electronics', purchaseDate: today, price: 500),
      ], asOf: today);

      expect(summary.totalPaid, 1500);
      expect(summary.totalCurrent, 1500, reason: 'neither has depreciated yet');
      expect(summary.totalLoss, 0);
      expect(summary.lossFraction, 0);
    });

    test('reports the loss and its share', () {
      final summary = Depreciation.summarize([
        asset(category: 'Electronics', purchaseDate: DateTime(2000, 1, 1)),
      ], asOf: today);

      expect(summary.totalCurrent, 100);
      expect(summary.totalLoss, 900);
      expect(summary.lossFraction, closeTo(0.9, 0.001));
    });

    test('an empty list does not divide by zero', () {
      final summary = Depreciation.summarize([], asOf: today);
      expect(summary.totalPaid, 0);
      expect(summary.lossFraction, 0);
    });
  });
}
