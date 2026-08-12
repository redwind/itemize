import 'package:flutter/foundation.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/data/models/maintenance_schedule.dart';

/// A job, the item it belongs to, and when it falls due.
///
/// The schedule alone cannot answer that: a job never yet done counts from the
/// item's purchase date, so the two have to be looked at together.
@immutable
class MaintenanceDue {
  final Asset asset;
  final MaintenanceSchedule schedule;
  final DateTime dueAt;

  const MaintenanceDue({
    required this.asset,
    required this.schedule,
    required this.dueAt,
  });

  /// Whole days until it is due; negative once it is late.
  int daysUntilDue({DateTime? now}) {
    final moment = now ?? DateTime.now();
    final today = DateTime(moment.year, moment.month, moment.day);
    final due = DateTime(dueAt.year, dueAt.month, dueAt.day);
    return due.difference(today).inDays;
  }

  bool isOverdue({DateTime? now}) => daysUntilDue(now: now) < 0;

  bool isDueWithin(int days, {DateTime? now}) {
    final remaining = daysUntilDue(now: now);
    return remaining >= 0 && remaining <= days;
  }

  /// The cover is still live, and the servicing it depends on has lapsed.
  ///
  /// This is the one thing here that is worth real money. A manufacturer that
  /// requires annual servicing can decline a claim when it was skipped, and the
  /// owner finds out at the worst possible moment. The app holds the warranty
  /// date and the service schedule, so it is the only thing in a position to
  /// say so a year in advance.
  ///
  /// Deliberately false once the warranty has already expired: there is nothing
  /// left to protect, and nagging about it would be noise.
  bool threatensWarranty({DateTime? now}) {
    if (!schedule.requiredForWarranty) return false;
    if (!isOverdue(now: now)) return false;

    final expiry = asset.warrantyExpiry;
    if (expiry == null) return false;
    return expiry.isAfter(now ?? DateTime.now());
  }
}

/// Works out what needs doing, and when.
class MaintenancePlanner {
  const MaintenancePlanner._();

  /// How far ahead a job counts as coming up rather than merely existing.
  static const int dueSoonDays = 14;

  /// Every job across every item, soonest first.
  ///
  /// Schedules whose item has gone are dropped rather than carried as orphans:
  /// deleting an item takes its schedules with it, so one appearing here would
  /// be a bug worth not compounding by displaying.
  static List<MaintenanceDue> plan(
    List<Asset> assets,
    List<MaintenanceSchedule> schedules,
  ) {
    final byId = {for (final asset in assets) asset.id: asset};
    final due = <MaintenanceDue>[];

    for (final schedule in schedules) {
      final asset = byId[schedule.assetId];
      if (asset == null) continue;

      due.add(
        MaintenanceDue(
          asset: asset,
          schedule: schedule,
          dueAt: schedule.nextDueAfter(asset.purchaseDate),
        ),
      );
    }

    due.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return due;
  }

  /// Jobs that are late or nearly so — what the Care screen leads with.
  static List<MaintenanceDue> needingAttention(
    List<MaintenanceDue> plan, {
    DateTime? now,
  }) =>
      plan
          .where(
            (d) => d.isOverdue(now: now) || d.isDueWithin(dueSoonDays, now: now),
          )
          .toList();

  /// Jobs whose lapse is putting a live warranty at risk.
  static List<MaintenanceDue> threateningWarranty(
    List<MaintenanceDue> plan, {
    DateTime? now,
  }) => plan.where((d) => d.threatensWarranty(now: now)).toList();
}
