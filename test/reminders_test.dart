import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:itemize/core/utils/reminders.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Asset asset({
  required String id,
  DateTime? warrantyExpiry,
  String name = 'Fridge',
}) => Asset(
  id: id,
  name: name,
  price: 500,
  currency: 'USD',
  room: 'Kitchen',
  category: 'Appliances',
  purchaseDate: DateTime(2024, 1, 1),
  warrantyExpiry: warrantyExpiry,
);

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    // Fixed so the expected fire times below do not move with the machine
    // running the tests.
    tz.setLocalLocation(tz.getLocation('UTC'));
    // DateFormat falls back to raw ICU patterns for a locale it has no symbol
    // data for, which silently produces the English month names the German
    // and French tests below are checking are absent.
    await initializeDateFormatting();
  });

  // UTC throughout, matching the local zone pinned above, so "now" and the
  // computed fire times are read on the same clock.
  final now = DateTime.utc(2026, 7, 27, 9);

  List<ScheduledReminder> remindersFor(List<Asset> assets) =>
      Reminders.upcomingReminders(assets, now: now);

  MaintenanceSchedule schedule({
    String id = 's',
    String assetId = 'a',
    String title = 'Replace filter',
    int intervalMonths = 6,
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

  group('which reminders are produced', () {
    test('one per lead time, at the reminder hour', () {
      final reminders = remindersFor([
        asset(id: 'a', warrantyExpiry: DateTime(2026, 12, 25)),
      ]);

      expect(reminders.length, kReminderLeadDays.length);
      expect(
        reminders.map((r) => r.fireAt.day).toList(),
        [25, 18, 24], // 30 days before, 7 days before, 1 day before
      );
      expect(reminders.every((r) => r.fireAt.hour == kReminderHour), isTrue);
    });

    test('items with no warranty produce nothing', () {
      expect(remindersFor([asset(id: 'a')]), isEmpty);
    });

    test('reminders already in the past are dropped, the rest kept', () {
      // Expires in 10 days: the 30-day reminder is long gone, 7 and 1 remain.
      final reminders = remindersFor([
        asset(id: 'a', warrantyExpiry: now.add(const Duration(days: 10))),
      ]);

      expect(reminders.length, 2);
      expect(reminders.every((r) => r.fireAt.isAfter(now)), isTrue);
    });

    test('an already-expired warranty produces nothing', () {
      final reminders = remindersFor([
        asset(id: 'a', warrantyExpiry: DateTime(2025, 1, 1)),
      ]);
      expect(reminders, isEmpty);
    });

    test('a reminder falling earlier today is dropped, not fired late', () {
      // The 1-day reminder for this item falls on 27 July at 10:00. Asked at
      // 11:00 that same day, it is in the past and must not be scheduled --
      // zonedSchedule would otherwise fire it immediately.
      final reminders = Reminders.upcomingReminders([
        asset(id: 'a', warrantyExpiry: DateTime(2026, 7, 28)),
      ], now: DateTime.utc(2026, 7, 27, 11));

      expect(reminders, isEmpty);
    });

    test('the same reminder an hour before its time is kept', () {
      final reminders = Reminders.upcomingReminders([
        asset(id: 'a', warrantyExpiry: DateTime(2026, 7, 28)),
      ], now: DateTime.utc(2026, 7, 27, 9));

      expect(reminders.length, 1);
      expect(reminders.single.title, contains('tomorrow'));
    });
  });

  group('ordering and content', () {
    test('soonest first, across several items', () {
      final reminders = remindersFor([
        asset(id: 'far', warrantyExpiry: DateTime(2027, 1, 1)),
        asset(id: 'near', warrantyExpiry: DateTime(2026, 9, 1)),
      ]);

      final fireTimes = reminders.map((r) => r.fireAt).toList();
      final sorted = [...fireTimes]..sort();
      expect(fireTimes, sorted, reason: 'the cap keeps the soonest reminders');
    });

    test('the title says how long is left and names the item', () {
      final reminders = remindersFor([
        asset(
          id: 'a',
          name: 'Espresso Machine',
          warrantyExpiry: DateTime(2026, 12, 25),
        ),
      ]);

      final titles = reminders.map((r) => r.title).toList();
      expect(titles, contains('Espresso Machine — warranty ends in 30 days'));
      expect(titles, contains('Espresso Machine — warranty ends in a week'));
      expect(titles, contains('Espresso Machine — warranty ends tomorrow'));
    });

    test('the payload carries the item so a tap can open it', () {
      final reminders = remindersFor([
        asset(id: 'the-id', warrantyExpiry: DateTime(2026, 12, 25)),
      ]);
      expect(reminders.every((r) => r.assetId == 'the-id'), isTrue);
    });
  });

  group('notification ids', () {
    test('are stable for the same item and lead', () {
      expect(
        Reminders.notificationId('abc-123', 0),
        Reminders.notificationId('abc-123', 0),
      );
    });

    test('differ per lead time, so three can be pending at once', () {
      final ids = {
        for (var i = 0; i < kReminderLeadDays.length; i++)
          Reminders.notificationId('abc-123', i),
      };
      expect(ids.length, kReminderLeadDays.length);
    });

    test('differ per item', () {
      expect(
        Reminders.notificationId('abc-123', 0),
        isNot(Reminders.notificationId('abc-124', 0)),
      );
    });

    test('stay inside the 32-bit signed range Android requires', () {
      // A thousand realistic UUID-shaped ids, every lead time.
      for (var n = 0; n < 1000; n++) {
        for (var lead = 0; lead < kReminderLeadDays.length; lead++) {
          final id = Reminders.notificationId(
            '3f2504e0-4f89-11d3-9a0c-0305e82c${n.toString().padLeft(4, '0')}',
            lead,
          );
          expect(id, greaterThanOrEqualTo(0));
          expect(id, lessThan(2147483647));
        }
      }
    });

    test('a realistic library of items produces no id collisions', () {
      final ids = <int>{};
      for (var n = 0; n < 2000; n++) {
        for (var lead = 0; lead < kReminderLeadDays.length; lead++) {
          ids.add(
            Reminders.notificationId(
              '3f2504e0-4f89-11d3-9a0c-0305e82c${n.toString().padLeft(4, '0')}',
              lead,
            ),
          );
        }
      }
      expect(ids.length, 2000 * kReminderLeadDays.length);
    });
  });

  group('maintenance reminders', () {
    List<ScheduledReminder> forSchedules(
      List<MaintenanceSchedule> schedules, {
      bool warrantyEnabled = false,
      bool maintenanceEnabled = true,
    }) => Reminders.upcomingReminders(
      [asset(id: 'a', warrantyExpiry: DateTime(2028, 1, 1))],
      schedules: schedules,
      warrantyEnabled: warrantyEnabled,
      maintenanceEnabled: maintenanceEnabled,
      now: now,
    );

    test('one a week ahead and one on the day', () {
      // Last done 1 Jan 2026, every 6 months, so due 1 Jul 2027.
      final reminders = forSchedules([
        schedule(intervalMonths: 18, lastDoneAt: DateTime(2026, 1, 1)),
      ]);

      expect(reminders, hasLength(kMaintenanceLeadDays.length));
      expect(reminders.first.fireAt.hour, kReminderHour);
    });

    test('a job already overdue schedules nothing', () {
      // Nothing left in the future to fire; the Care screen carries it instead.
      expect(
        forSchedules([
          schedule(intervalMonths: 1, lastDoneAt: DateTime(2025, 1, 1)),
        ]),
        isEmpty,
      );
    });

    test('the title names the item and the job', () {
      final reminders = forSchedules([
        schedule(
          title: 'Annual service',
          intervalMonths: 18,
          lastDoneAt: DateTime(2026, 1, 1),
        ),
      ]);

      expect(reminders.first.title, contains('Fridge'));
      expect(reminders.first.title, contains('Annual service'));
    });

    test('a warranty-critical job says so in the body', () {
      final reminders = forSchedules([
        schedule(
          intervalMonths: 18,
          lastDoneAt: DateTime(2026, 1, 1),
          requiredForWarranty: true,
        ),
      ]);

      expect(reminders.first.body, contains('warranty'));
    });

    test('an ordinary job does not mention the warranty', () {
      final reminders = forSchedules([
        schedule(intervalMonths: 18, lastDoneAt: DateTime(2026, 1, 1)),
      ]);
      expect(reminders.first.body, isNot(contains('warranty')));
    });

    test('the payload points at the item, not the schedule', () {
      // Tapping it should open the thing that needs servicing.
      final reminders = forSchedules([
        schedule(intervalMonths: 18, lastDoneAt: DateTime(2026, 1, 1)),
      ]);
      expect(reminders.first.assetId, 'a');
    });

    test('switching maintenance off leaves only warranty reminders', () {
      final reminders = forSchedules(
        [schedule(intervalMonths: 18, lastDoneAt: DateTime(2026, 1, 1))],
        warrantyEnabled: true,
        maintenanceEnabled: false,
      );

      expect(reminders, isNotEmpty);
      expect(reminders.every((r) => r.title.contains('warranty')), isTrue);
    });

    test('a schedule and its item never collide on a notification id', () {
      // Both hash the same way; the lead-slot offset is what separates them.
      final reminders = Reminders.upcomingReminders(
        [asset(id: 'shared', warrantyExpiry: DateTime(2027, 12, 25))],
        schedules: [
          schedule(
            id: 'shared',
            assetId: 'shared',
            intervalMonths: 18,
            lastDoneAt: DateTime(2026, 1, 1),
          ),
        ],
        now: now,
      );

      final ids = reminders.map((r) => r.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('warranty and maintenance are merged into one sorted queue', () {
      // The 60-reminder cap has to drop the furthest-off of either kind, which
      // only works if they are sorted together.
      final reminders = Reminders.upcomingReminders(
        [asset(id: 'a', warrantyExpiry: DateTime(2027, 6, 1))],
        schedules: [
          schedule(intervalMonths: 14, lastDoneAt: DateTime(2026, 1, 1)),
        ],
        now: now,
      );

      final times = reminders.map((r) => r.fireAt).toList();
      expect(times, orderedEquals([...times]..sort()));
      expect(reminders.length, greaterThan(kReminderLeadDays.length));
    });
  });

  group('localization', () {
    final l10nDe = lookupAppLocalizations(const Locale('de'));
    final l10nFr = lookupAppLocalizations(const Locale('fr'));

    test('a German reminder has a German title and a German date in the body', () {
      final reminders = Reminders.upcomingReminders(
        [
          asset(
            id: 'a',
            name: 'Kühlschrank',
            warrantyExpiry: DateTime(2026, 12, 25),
          ),
        ],
        now: now,
        l10n: l10nDe,
      );

      // The 1-day lead is the last to fire, chronologically last in the sort.
      final tomorrow = reminders.last;
      expect(tomorrow.title, 'Kühlschrank — Garantie endet morgen');
      expect(
        tomorrow.body,
        'Garantie endet am 25. Dez. 2026. Gekauft am 1. Jan. 2024.',
      );
    });

    test(
      'a French reminder has a French title and a day-first date in the body',
      () {
        final reminders = Reminders.upcomingReminders(
          [
            asset(
              id: 'a',
              name: 'Réfrigérateur',
              warrantyExpiry: DateTime(2026, 12, 25),
            ),
          ],
          now: now,
          l10n: l10nFr,
        );

        final tomorrow = reminders.last;
        expect(tomorrow.title, 'Réfrigérateur — la garantie se termine demain');
        // Day before month, unlike the English "Dec 25, 2026" -- the bug an
        // American-formatted date inside a French notification would be.
        expect(
          tomorrow.body,
          "Garantie jusqu'au 25 déc. 2026. Acheté le 1 janv. 2024.",
        );
      },
    );

    test('a German maintenance reminder is fully translated, not mixed', () {
      final reminders = Reminders.upcomingReminders(
        [asset(id: 'a', warrantyExpiry: DateTime(2028, 1, 1))],
        schedules: [
          MaintenanceSchedule(
            id: 's',
            assetId: 'a',
            title: 'Filter wechseln',
            intervalMonths: 18,
            lastDoneAt: DateTime(2026, 1, 1),
            requiredForWarranty: true,
          ),
        ],
        warrantyEnabled: false,
        maintenanceEnabled: true,
        now: now,
        l10n: l10nDe,
      );

      expect(reminders, isNotEmpty);
      for (final reminder in reminders) {
        expect(reminder.title, contains('Filter wechseln'));
        expect(reminder.body, contains('1. Jan. 2026'));
        expect(reminder.body, contains('Erforderlich, damit die Garantie'));
      }
    });
  });
}
