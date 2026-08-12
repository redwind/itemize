import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/warranty_status.dart';
import 'package:inventa/data/models/asset.dart';

Asset asset({String id = 'a', String name = 'Fridge', DateTime? expiry}) =>
    Asset(
      id: id,
      name: name,
      price: 100,
      currency: 'USD',
      room: 'Kitchen',
      category: 'Appliances',
      purchaseDate: DateTime(2024, 1, 1),
      warrantyExpiry: expiry,
    );

void main() {
  final now = DateTime(2026, 7, 28, 15, 30);

  WarrantyStanding standing(DateTime? expiry) =>
      WarrantyStatus.of(asset(expiry: expiry), now: now);

  group('standing', () {
    test('well inside the warranty', () {
      expect(standing(DateTime(2027, 7, 28)), WarrantyStanding.covered);
    });

    test('inside the last three months', () {
      expect(standing(DateTime(2026, 9, 1)), WarrantyStanding.expiringSoon);
    });

    test('run out', () {
      expect(standing(DateTime(2026, 7, 27)), WarrantyStanding.expired);
    });

    test('never recorded', () {
      expect(standing(null), WarrantyStanding.unknown);
    });

    test('expiring later today still counts as covered, not expired', () {
      // The clock says 15:30; an item expiring "today" has the day left.
      expect(standing(DateTime(2026, 7, 28)), WarrantyStanding.expiringSoon);
      expect(WarrantyStatus.daysRemaining(asset(expiry: now), now: now), 0);
    });

    test('the boundary of the soon window is inclusive', () {
      final ninetyDays = DateTime(2026, 7, 28).add(const Duration(days: 90));
      final ninetyOne = DateTime(2026, 7, 28).add(const Duration(days: 91));
      expect(standing(ninetyDays), WarrantyStanding.expiringSoon);
      expect(standing(ninetyOne), WarrantyStanding.covered);
    });
  });

  group('days remaining', () {
    test('counts whole days ahead', () {
      expect(
        WarrantyStatus.daysRemaining(
          asset(expiry: DateTime(2026, 8, 7)),
          now: now,
        ),
        10,
      );
    });

    test('goes negative once expired', () {
      expect(
        WarrantyStatus.daysRemaining(
          asset(expiry: DateTime(2026, 7, 18)),
          now: now,
        ),
        -10,
      );
    });

    test('is null when nothing was recorded', () {
      expect(WarrantyStatus.daysRemaining(asset(), now: now), isNull);
    });

    test('ignores the time of day on either side', () {
      // Same calendar day, wildly different clock times.
      expect(
        WarrantyStatus.daysRemaining(
          asset(expiry: DateTime(2026, 8, 7, 23, 59)),
          now: DateTime(2026, 7, 28, 0, 1),
        ),
        10,
      );
    });
  });

  group('grouping', () {
    test('sorts each group by what runs out first', () {
      final grouped = WarrantyStatus.group([
        asset(id: 'c', name: 'Later', expiry: DateTime(2026, 9, 20)),
        asset(id: 'a', name: 'Soonest', expiry: DateTime(2026, 8, 1)),
        asset(id: 'b', name: 'Middle', expiry: DateTime(2026, 9, 1)),
      ], now: now);

      expect(
        grouped[WarrantyStanding.expiringSoon]!.map((a) => a.name),
        ['Soonest', 'Middle', 'Later'],
      );
    });

    test('items with no warranty are sorted by name instead', () {
      final grouped = WarrantyStatus.group([
        asset(id: 'b', name: 'Zebra'),
        asset(id: 'a', name: 'Anvil'),
      ], now: now);

      expect(
        grouped[WarrantyStanding.unknown]!.map((a) => a.name),
        ['Anvil', 'Zebra'],
      );
    });

    test('every standing is present even when empty', () {
      final grouped = WarrantyStatus.group([], now: now);
      expect(grouped.keys.toSet(), WarrantyStanding.values.toSet());
      expect(grouped.values.every((v) => v.isEmpty), isTrue);
    });

    test('each item lands in exactly one group', () {
      final assets = [
        asset(id: 'a', expiry: DateTime(2027, 1, 1)),
        asset(id: 'b', expiry: DateTime(2026, 8, 1)),
        asset(id: 'c', expiry: DateTime(2025, 1, 1)),
        asset(id: 'd'),
      ];
      final grouped = WarrantyStatus.group(assets, now: now);

      expect(grouped.values.expand((v) => v).length, assets.length);
      expect(grouped[WarrantyStanding.covered]!.single.id, 'a');
      expect(grouped[WarrantyStanding.expiringSoon]!.single.id, 'b');
      expect(grouped[WarrantyStanding.expired]!.single.id, 'c');
      expect(grouped[WarrantyStanding.unknown]!.single.id, 'd');
    });
  });
}
