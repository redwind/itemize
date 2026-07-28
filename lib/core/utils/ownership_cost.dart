import 'package:flutter/foundation.dart';
import 'package:itemize/core/utils/depreciation.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/service_record.dart';

/// What the running total says about mending something again.
enum OwnershipVerdict {
  /// Repairs are small against what the thing is still worth.
  healthy,

  /// Repairs have passed half its remaining value — worth watching.
  watch,

  /// More has been spent mending it than it is now worth.
  replace,
}

/// What an item has actually cost, against what it is now worth.
///
/// This is the question a home inventory is otherwise no help with. Everyone
/// facing a third repair bill asks whether to pay it, and answers from memory —
/// which reliably understates what has already gone in. Purchase price,
/// depreciation and every repair are all here already; putting them side by
/// side is the whole of it.
@immutable
class OwnershipCost {
  final double purchasePrice;

  /// Everything spent on repairs, servicing and inspections since.
  final double serviceSpend;

  /// Today's estimated value, from [Depreciation].
  final double estimatedValue;

  final int serviceCount;
  final DateTime? lastServiced;

  const OwnershipCost({
    required this.purchasePrice,
    required this.serviceSpend,
    required this.estimatedValue,
    required this.serviceCount,
    this.lastServiced,
  });

  /// Everything the item has cost to date.
  double get totalOutlay => purchasePrice + serviceSpend;

  /// Repairs as a share of what the item is still worth.
  ///
  /// Infinite when the item is valued at nothing but has been repaired, which
  /// is exactly the case the verdict wants to catch.
  double get spendAgainstValue {
    if (estimatedValue <= 0) return serviceSpend > 0 ? double.infinity : 0;
    return serviceSpend / estimatedValue;
  }

  /// The rule of thumb repair trades quote: once mending has cost more than
  /// half of what the thing is worth, it is on notice; past all of it, replace.
  ///
  /// A heuristic, and presented as one. It is a prompt to think, not an
  /// instruction, and the UI says so.
  OwnershipVerdict get verdict {
    if (serviceSpend <= 0) return OwnershipVerdict.healthy;
    final ratio = spendAgainstValue;
    if (ratio > 1) return OwnershipVerdict.replace;
    if (ratio > 0.5) return OwnershipVerdict.watch;
    return OwnershipVerdict.healthy;
  }

  static OwnershipCost of(
    Asset asset,
    List<ServiceRecord> records, {
    DateTime? asOf,
  }) {
    var spend = 0.0;
    DateTime? last;
    for (final record in records) {
      spend += record.cost;
      if (last == null || record.date.isAfter(last)) last = record.date;
    }

    return OwnershipCost(
      purchasePrice: asset.price,
      serviceSpend: spend,
      estimatedValue: Depreciation.currentValue(asset, asOf: asOf),
      serviceCount: records.length,
      lastServiced: last,
    );
  }
}
