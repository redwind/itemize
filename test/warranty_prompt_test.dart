import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/ui/add_item/warranty_prompt_screen.dart';

void main() {
  group('addWarrantyYears', () {
    test('adds whole years from an ordinary date', () {
      final purchase = DateTime(2025, 6, 15);
      expect(addWarrantyYears(purchase, 1), DateTime(2026, 6, 15));
      expect(addWarrantyYears(purchase, 2), DateTime(2027, 6, 15));
      expect(addWarrantyYears(purchase, 3), DateTime(2028, 6, 15));
    });

    test('29 February plus one year lands on 28 February in a non-leap year', () {
      final purchase = DateTime(2024, 2, 29); // 2024 is a leap year
      expect(addWarrantyYears(purchase, 1), DateTime(2025, 2, 28));
    });

    test('29 February plus four years lands back on 29 February', () {
      final purchase = DateTime(2024, 2, 29);
      expect(addWarrantyYears(purchase, 4), DateTime(2028, 2, 29));
    });

    test('31 January plus one year stays on the 31st', () {
      // January has 31 days in every year, so this is the sanity check that
      // the day-clamping logic does not clip a month that never needed it.
      final purchase = DateTime(2024, 1, 31);
      expect(addWarrantyYears(purchase, 1), DateTime(2025, 1, 31));
    });

    test('is computed from the purchase date, not from today', () {
      // No DateTime.now() involved anywhere in the function -- an old
      // purchase date must resolve exactly as if it were catalogued that day.
      final purchase = DateTime(2020, 3, 10);
      expect(addWarrantyYears(purchase, 2), DateTime(2022, 3, 10));
    });
  });

  group('warrantyExpiryForChoice', () {
    final purchase = DateTime(2025, 6, 15);

    test('resolves each year option relative to the purchase date', () {
      expect(
        warrantyExpiryForChoice(WarrantyChoice.oneYear, purchase),
        DateTime(2026, 6, 15),
      );
      expect(
        warrantyExpiryForChoice(WarrantyChoice.twoYears, purchase),
        DateTime(2027, 6, 15),
      );
      expect(
        warrantyExpiryForChoice(WarrantyChoice.threeYears, purchase),
        DateTime(2028, 6, 15),
      );
    });

    test('none produces no date', () {
      expect(warrantyExpiryForChoice(WarrantyChoice.none, purchase), isNull);
    });

    test('other date without a pick yet produces no date', () {
      expect(warrantyExpiryForChoice(WarrantyChoice.other, purchase), isNull);
    });

    test('other date returns exactly the date it was given', () {
      final custom = DateTime(2030, 1, 1);
      expect(
        warrantyExpiryForChoice(
          WarrantyChoice.other,
          purchase,
          customDate: custom,
        ),
        custom,
      );
    });
  });
}
