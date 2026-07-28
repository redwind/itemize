import 'package:itemize/data/models/asset.dart';

/// Where an item stands on its warranty.
enum WarrantyStanding {
  /// Covered, with more than [WarrantyStatus.expiringSoonDays] left.
  covered,

  /// Covered, but not for much longer — the window in which it is worth
  /// getting a fault looked at rather than living with it.
  expiringSoon,

  /// The cover has run out.
  expired,

  /// No expiry was ever recorded, which is not the same as having none.
  unknown,
}

/// Answers the question people actually open this app to ask.
///
/// When something breaks, the first thing anyone wants to know is whether it is
/// still covered. Every fact needed to answer that was already stored; there was
/// simply no screen that asked it.
class WarrantyStatus {
  const WarrantyStatus._();

  /// How close to expiry counts as "soon".
  ///
  /// Three months: long enough to notice a fault, book a repair and have it
  /// seen to before the cover lapses, which is the whole point of being told.
  static const int expiringSoonDays = 90;

  static WarrantyStanding of(Asset asset, {DateTime? now}) {
    final remaining = daysRemaining(asset, now: now);
    if (remaining == null) return WarrantyStanding.unknown;
    if (remaining < 0) return WarrantyStanding.expired;
    if (remaining <= expiringSoonDays) return WarrantyStanding.expiringSoon;
    return WarrantyStanding.covered;
  }

  /// Whole days until the warranty runs out; negative once it has.
  ///
  /// Measured between calendar days rather than instants, so an item expiring
  /// later today reads as 0 days left rather than as already gone.
  static int? daysRemaining(Asset asset, {DateTime? now}) {
    final expiry = asset.warrantyExpiry;
    if (expiry == null) return null;

    final moment = now ?? DateTime.now();
    final today = DateTime(moment.year, moment.month, moment.day);
    final end = DateTime(expiry.year, expiry.month, expiry.day);
    return end.difference(today).inDays;
  }

  /// Items in each standing, soonest expiry first within each.
  ///
  /// Sorted that way because the list is read top-down under mild panic: the
  /// thing about to lapse is the thing worth acting on.
  static Map<WarrantyStanding, List<Asset>> group(
    List<Asset> assets, {
    DateTime? now,
  }) {
    final grouped = <WarrantyStanding, List<Asset>>{
      for (final standing in WarrantyStanding.values) standing: <Asset>[],
    };

    for (final asset in assets) {
      grouped[of(asset, now: now)]!.add(asset);
    }

    for (final entry in grouped.entries) {
      if (entry.key == WarrantyStanding.unknown) {
        entry.value.sort((a, b) => a.name.compareTo(b.name));
      } else {
        entry.value.sort(
          (a, b) => a.warrantyExpiry!.compareTo(b.warrantyExpiry!),
        );
      }
    }

    return grouped;
  }
}
