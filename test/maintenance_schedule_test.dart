import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';

MaintenanceSchedule schedule({
  int intervalMonths = 6,
  DateTime? lastDoneAt,
  bool requiredForWarranty = false,
}) => MaintenanceSchedule(
  id: 's',
  assetId: 'a',
  title: 'Replace water filter',
  intervalMonths: intervalMonths,
  lastDoneAt: lastDoneAt,
  requiredForWarranty: requiredForWarranty,
);

void main() {
  group('adding months', () {
    test('walks forward within a year', () {
      expect(
        MaintenanceSchedule.addMonths(DateTime(2026, 1, 15), 3),
        DateTime(2026, 4, 15),
      );
    });

    test('rolls over the year end', () {
      expect(
        MaintenanceSchedule.addMonths(DateTime(2026, 11, 15), 3),
        DateTime(2027, 2, 15),
      );
    });

    test('clamps to the end of a shorter month', () {
      // 31 January plus one month is 28 February, not 3 March. Rolling over
      // would walk a monthly job out of its month for good.
      expect(
        MaintenanceSchedule.addMonths(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28),
      );
      expect(
        MaintenanceSchedule.addMonths(DateTime(2026, 3, 31), 1),
        DateTime(2026, 4, 30),
      );
    });

    test('knows about leap years', () {
      expect(
        MaintenanceSchedule.addMonths(DateTime(2028, 1, 31), 1),
        DateTime(2028, 2, 29),
      );
    });

    test('clamping does not compound over repeated additions', () {
      // Counting from the original date each time keeps the 31st, rather than
      // sliding to the 28th and staying there.
      final start = DateTime(2026, 1, 31);
      expect(MaintenanceSchedule.addMonths(start, 2), DateTime(2026, 3, 31));
      expect(MaintenanceSchedule.addMonths(start, 4), DateTime(2026, 5, 31));
    });

    test('handles intervals longer than a year', () {
      expect(
        MaintenanceSchedule.addMonths(DateTime(2026, 7, 28), 24),
        DateTime(2028, 7, 28),
      );
    });
  });

  group('when it next falls due', () {
    final bought = DateTime(2024, 1, 10);

    test('counts from the last time it was done', () {
      final next = schedule(
        intervalMonths: 6,
        lastDoneAt: DateTime(2026, 3, 10),
      ).nextDueAfter(bought);
      expect(next, DateTime(2026, 9, 10));
    });

    test('counts from the purchase date when it never has been', () {
      expect(schedule(intervalMonths: 12).nextDueAfter(bought),
          DateTime(2025, 1, 10));
    });

    test('a schedule added to an old item is overdue at once', () {
      // Honest rather than kind: a boiler bought in 2024 with an annual
      // service and no record of one is genuinely overdue.
      final next = schedule(intervalMonths: 12).nextDueAfter(bought);
      expect(next.isBefore(DateTime(2026, 7, 28)), isTrue);
    });
  });

  group('storage round trip', () {
    test('every field survives', () {
      final original = schedule(
        intervalMonths: 12,
        lastDoneAt: DateTime(2026, 5, 1),
        requiredForWarranty: true,
      );

      final restored = MaintenanceSchedule.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.assetId, original.assetId);
      expect(restored.title, original.title);
      expect(restored.intervalMonths, 12);
      expect(restored.lastDoneAt, DateTime(2026, 5, 1));
      expect(restored.requiredForWarranty, isTrue);
    });

    test('a schedule never done round-trips as never done', () {
      final restored = MaintenanceSchedule.fromMap(schedule().toMap());
      expect(restored.lastDoneAt, isNull);
      expect(restored.requiredForWarranty, isFalse);
    });
  });

  test('copyWith moves the last-done date without disturbing the rest', () {
    final updated = schedule(
      requiredForWarranty: true,
    ).copyWith(lastDoneAt: DateTime(2026, 7, 1));

    expect(updated.lastDoneAt, DateTime(2026, 7, 1));
    expect(updated.title, 'Replace water filter');
    expect(updated.requiredForWarranty, isTrue);
    expect(updated.id, 's');
  });

  test('the suggestion lists only name real categories', () {
    // A suggestion filed under a category that does not exist would never be
    // offered to anyone.
    const categories = {
      'Electronics',
      'Furniture',
      'Appliances',
      'Jewelry & Watches',
      'Clothing',
      'Tools & Equipment',
      'Sports & Outdoors',
      'Kitchenware',
      'Art & Collectibles',
      'Other',
    };
    expect(kSuggestedMaintenance.keys, everyElement(isIn(categories)));
  });

  test('the offered intervals are all whole months and ordered', () {
    final months = kMaintenanceIntervals.values.toList();
    expect(months.every((m) => m > 0), isTrue);
    expect(months, orderedEquals([...months]..sort()));
  });
}
