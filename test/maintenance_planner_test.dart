import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/maintenance_planner.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/data/models/maintenance_schedule.dart';

Asset asset({
  String id = 'a',
  String name = 'Boiler',
  DateTime? purchaseDate,
  DateTime? warrantyExpiry,
}) => Asset(
  id: id,
  name: name,
  price: 2000,
  currency: 'USD',
  room: 'Garage',
  category: 'Appliances',
  purchaseDate: purchaseDate ?? DateTime(2024, 1, 10),
  warrantyExpiry: warrantyExpiry,
);

MaintenanceSchedule schedule({
  String id = 's',
  String assetId = 'a',
  String title = 'Annual service',
  int intervalMonths = 12,
  DateTime? lastDoneAt,
  bool requiredForWarranty = false,
}) => MaintenanceSchedule(
  id: id,
  assetId: assetId,
  title: title,
  intervalMonths: intervalMonths,
  lastDoneAt: lastDoneAt,
  requiredForWarranty: requiredForWarranty,
);

void main() {
  final now = DateTime(2026, 7, 28);

  group('planning', () {
    test('pairs each schedule with its item and works out the due date', () {
      final plan = MaintenancePlanner.plan(
        [asset()],
        [schedule(lastDoneAt: DateTime(2026, 3, 10))],
      );

      expect(plan, hasLength(1));
      expect(plan.single.asset.id, 'a');
      expect(plan.single.dueAt, DateTime(2027, 3, 10));
    });

    test('sorts soonest first across items', () {
      final plan = MaintenancePlanner.plan(
        [asset(id: 'a'), asset(id: 'b', name: 'Mower')],
        [
          schedule(id: 's2', assetId: 'b', lastDoneAt: DateTime(2026, 6, 1)),
          schedule(id: 's1', assetId: 'a', lastDoneAt: DateTime(2026, 1, 1)),
        ],
      );

      expect(plan.map((d) => d.schedule.id), ['s1', 's2']);
    });

    test('drops a schedule whose item is gone rather than showing an orphan',
        () {
      final plan = MaintenancePlanner.plan(
        [asset(id: 'a')],
        [schedule(id: 's1', assetId: 'a'), schedule(id: 's2', assetId: 'gone')],
      );

      expect(plan.map((d) => d.schedule.id), ['s1']);
    });

    test('nothing scheduled means nothing planned', () {
      expect(MaintenancePlanner.plan([asset()], []), isEmpty);
    });
  });

  group('days until due', () {
    MaintenanceDue due(DateTime lastDone) =>
        MaintenancePlanner.plan(
          [asset()],
          [schedule(intervalMonths: 6, lastDoneAt: lastDone)],
        ).single;

    test('counts ahead', () {
      // Last done 1 May 2026 + 6 months = 1 Nov 2026.
      expect(due(DateTime(2026, 5, 1)).daysUntilDue(now: now), 96);
    });

    test('goes negative once late', () {
      // Last done 1 Jan 2026 + 6 months = 1 Jul 2026, four weeks ago.
      expect(due(DateTime(2026, 1, 1)).daysUntilDue(now: now), -27);
      expect(due(DateTime(2026, 1, 1)).isOverdue(now: now), isTrue);
    });

    test('due today is not yet overdue', () {
      expect(due(DateTime(2026, 1, 28)).daysUntilDue(now: now), 0);
      expect(due(DateTime(2026, 1, 28)).isOverdue(now: now), isFalse);
    });
  });

  group('what needs attention', () {
    test('gathers the late and the nearly due, leaving the rest', () {
      final plan = MaintenancePlanner.plan(
        [asset(id: 'a'), asset(id: 'b'), asset(id: 'c')],
        [
          // Overdue.
          schedule(id: 'late', assetId: 'a', intervalMonths: 6,
              lastDoneAt: DateTime(2026, 1, 1)),
          // Due in about a week.
          schedule(id: 'soon', assetId: 'b', intervalMonths: 6,
              lastDoneAt: DateTime(2026, 2, 4)),
          // Due in months.
          schedule(id: 'later', assetId: 'c', intervalMonths: 12,
              lastDoneAt: DateTime(2026, 6, 1)),
        ],
      );

      final attention = MaintenancePlanner.needingAttention(plan, now: now);
      expect(attention.map((d) => d.schedule.id), ['late', 'soon']);
    });
  });

  group('the warranty link', () {
    MaintenanceDue overdueRequired({DateTime? warrantyExpiry}) =>
        MaintenancePlanner.plan(
          [asset(warrantyExpiry: warrantyExpiry)],
          [
            schedule(
              intervalMonths: 6,
              lastDoneAt: DateTime(2026, 1, 1),
              requiredForWarranty: true,
            ),
          ],
        ).single;

    test('fires when required servicing has lapsed under a live warranty', () {
      final due = overdueRequired(warrantyExpiry: DateTime(2028, 1, 1));
      expect(due.isOverdue(now: now), isTrue);
      expect(due.threatensWarranty(now: now), isTrue);
    });

    test('stays quiet once the warranty has expired anyway', () {
      // Nothing left to protect; saying so would only be noise.
      final due = overdueRequired(warrantyExpiry: DateTime(2025, 1, 1));
      expect(due.threatensWarranty(now: now), isFalse);
    });

    test('stays quiet when no warranty was ever recorded', () {
      expect(overdueRequired().threatensWarranty(now: now), isFalse);
    });

    test('stays quiet for a job that is merely optional', () {
      final due = MaintenancePlanner.plan(
        [asset(warrantyExpiry: DateTime(2028, 1, 1))],
        [
          schedule(
            intervalMonths: 6,
            lastDoneAt: DateTime(2026, 1, 1),
            requiredForWarranty: false,
          ),
        ],
      ).single;

      expect(due.isOverdue(now: now), isTrue);
      expect(due.threatensWarranty(now: now), isFalse);
    });

    test('stays quiet while the required job is still in date', () {
      final due = MaintenancePlanner.plan(
        [asset(warrantyExpiry: DateTime(2028, 1, 1))],
        [
          schedule(
            intervalMonths: 12,
            lastDoneAt: DateTime(2026, 6, 1),
            requiredForWarranty: true,
          ),
        ],
      ).single;

      expect(due.threatensWarranty(now: now), isFalse);
    });

    test('the planner collects only the ones at risk', () {
      final plan = MaintenancePlanner.plan(
        [
          asset(id: 'a', warrantyExpiry: DateTime(2028, 1, 1)),
          asset(id: 'b', warrantyExpiry: DateTime(2028, 1, 1)),
        ],
        [
          schedule(id: 'risk', assetId: 'a', intervalMonths: 6,
              lastDoneAt: DateTime(2026, 1, 1), requiredForWarranty: true),
          schedule(id: 'fine', assetId: 'b', intervalMonths: 6,
              lastDoneAt: DateTime(2026, 1, 1), requiredForWarranty: false),
        ],
      );

      expect(
        MaintenancePlanner.threateningWarranty(plan, now: now)
            .map((d) => d.schedule.id),
        ['risk'],
      );
    });
  });

  test('a job never done counts from the purchase date, so old kit is late',
      () {
    final plan = MaintenancePlanner.plan(
      [asset(purchaseDate: DateTime(2020, 1, 1))],
      [schedule(intervalMonths: 12)],
    );

    expect(plan.single.isOverdue(now: now), isTrue);
    expect(plan.single.dueAt, DateTime(2021, 1, 1));
  });
}
