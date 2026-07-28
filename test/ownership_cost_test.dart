import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/core/utils/ownership_cost.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/service_record.dart';

Asset asset({double price = 1000, DateTime? purchaseDate}) => Asset(
  id: 'a',
  name: 'Washing Machine',
  price: price,
  currency: 'USD',
  room: 'Kitchen',
  category: 'Appliances', // ten-year life
  purchaseDate: purchaseDate ?? DateTime(2021, 7, 28),
);

ServiceRecord record(double cost, {DateTime? date}) => ServiceRecord(
  id: 'r$cost',
  assetId: 'a',
  date: date ?? DateTime(2026, 1, 1),
  kind: ServiceKind.repair,
  cost: cost,
);

void main() {
  final today = DateTime(2026, 7, 28);

  OwnershipCost costOf(List<ServiceRecord> records, {double price = 1000}) =>
      OwnershipCost.of(asset(price: price), records, asOf: today);

  group('totals', () {
    test('adds every repair to the purchase price', () {
      final cost = costOf([record(120), record(80)]);
      expect(cost.serviceSpend, 200);
      expect(cost.totalOutlay, 1200);
      expect(cost.serviceCount, 2);
    });

    test('an item never serviced has spent nothing', () {
      final cost = costOf([]);
      expect(cost.serviceSpend, 0);
      expect(cost.totalOutlay, 1000);
      expect(cost.lastServiced, isNull);
    });

    test('remembers the most recent service, not the last one listed', () {
      final cost = costOf([
        record(50, date: DateTime(2025, 3, 1)),
        record(50, date: DateTime(2026, 4, 1)),
        record(50, date: DateTime(2024, 9, 1)),
      ]);
      expect(cost.lastServiced, DateTime(2026, 4, 1));
    });

    test('a free repair still counts as a repair', () {
      // Warranty work costs nothing and is worth knowing about.
      final cost = costOf([record(0)]);
      expect(cost.serviceCount, 1);
      expect(cost.serviceSpend, 0);
      expect(cost.verdict, OwnershipVerdict.healthy);
    });
  });

  group('the verdict', () {
    // Five years into a ten-year life, so about half of 1000 remains.
    test('small repairs against a healthy value', () {
      expect(costOf([record(50)]).verdict, OwnershipVerdict.healthy);
    });

    test('past half its remaining value, it goes on notice', () {
      // Value is about 500; 300 spent is more than half of that.
      expect(costOf([record(300)]).verdict, OwnershipVerdict.watch);
    });

    test('past its whole remaining value, replace', () {
      expect(costOf([record(600)]).verdict, OwnershipVerdict.replace);
    });

    test('nothing spent is never a replace, however old', () {
      final cost = OwnershipCost.of(
        asset(purchaseDate: DateTime(2000, 1, 1)),
        [],
        asOf: today,
      );
      expect(cost.verdict, OwnershipVerdict.healthy);
    });

    test('a repair on something valued at nothing reads as replace', () {
      const cost = OwnershipCost(
        purchasePrice: 100,
        serviceSpend: 40,
        estimatedValue: 0,
        serviceCount: 1,
      );
      expect(cost.spendAgainstValue, double.infinity);
      expect(cost.verdict, OwnershipVerdict.replace);
    });

    test('nothing spent on something worth nothing does not divide by zero', () {
      const cost = OwnershipCost(
        purchasePrice: 0,
        serviceSpend: 0,
        estimatedValue: 0,
        serviceCount: 0,
      );
      expect(cost.spendAgainstValue, 0);
      expect(cost.verdict, OwnershipVerdict.healthy);
    });
  });

  test('a category that does not depreciate keeps its full value in the sum',
      () {
    final ring = Asset(
      id: 'r',
      name: 'Ring',
      price: 2000,
      currency: 'USD',
      room: 'Bedroom',
      category: 'Jewelry & Watches',
      purchaseDate: DateTime(2005, 1, 1),
    );

    final cost = OwnershipCost.of(ring, [record(100)], asOf: today);
    expect(cost.estimatedValue, 2000);
    expect(cost.verdict, OwnershipVerdict.healthy);
  });
}
