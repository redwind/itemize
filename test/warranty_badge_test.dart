import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/warranty_status.dart';
import 'package:inventa/data/models/asset.dart';

// Regression coverage for the list badge, which used to compute its own
// expired-or-not arithmetic instead of asking WarrantyStatus -- so an item
// three days from lapsing still read as a green "Covered". These mirror the
// standings the Care tab already renders, expressed the way the bug report
// was: in days from now, not calendar boundaries (see warranty_status_test
// for those).
Asset asset({DateTime? expiry}) => Asset(
  id: 'a',
  name: 'Fridge',
  price: 100,
  currency: 'USD',
  room: 'Kitchen',
  category: 'Appliances',
  purchaseDate: DateTime(2024, 1, 1),
  warrantyExpiry: expiry,
);

void main() {
  final now = DateTime(2026, 7, 28, 12);

  test('three days from expiry is not "covered"', () {
    final standing = WarrantyStatus.of(
      asset(expiry: now.add(const Duration(days: 3))),
      now: now,
    );
    expect(standing, isNot(WarrantyStanding.covered));
    expect(standing, WarrantyStanding.expiringSoon);
  });

  test('two hundred days out reads as covered', () {
    final standing = WarrantyStatus.of(
      asset(expiry: now.add(const Duration(days: 200))),
      now: now,
    );
    expect(standing, WarrantyStanding.covered);
  });

  test('a lapsed date reads as expired', () {
    final standing = WarrantyStatus.of(
      asset(expiry: now.subtract(const Duration(days: 1))),
      now: now,
    );
    expect(standing, WarrantyStanding.expired);
  });

  test('no date on record reads as unknown, not covered', () {
    expect(WarrantyStatus.of(asset(), now: now), WarrantyStanding.unknown);
  });
}
