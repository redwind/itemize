import 'package:itemize/data/models/asset.dart';

/// Estimates what belongings are worth now rather than what they cost.
///
/// A contents policy that pays actual cash value settles on the depreciated
/// figure, not the purchase price, and the gap between the two is the thing
/// owners are most often surprised by at the worst possible moment. Showing it
/// in advance is the point.
///
/// These are straight-line estimates on published useful-life conventions, not
/// any particular insurer's schedule. Everything that surfaces a number from
/// here has to say it is an estimate.
class Depreciation {
  const Depreciation._();

  /// How long each category is conventionally treated as lasting, in years.
  ///
  /// A null entry means the category is not depreciated: jewellery, art and
  /// collectibles are scheduled separately by insurers and frequently hold or
  /// gain value, so guessing them downward would be worse than not guessing.
  static const Map<String, int?> usefulLifeYears = {
    'Electronics': 5,
    'Furniture': 15,
    'Appliances': 10,
    'Jewelry & Watches': null,
    'Clothing': 5,
    'Tools & Equipment': 10,
    'Sports & Outdoors': 8,
    'Kitchenware': 10,
    'Art & Collectibles': null,
    'Other': 10,
    kUncategorized: 10,
  };

  /// The share of the original price an item keeps however old it gets.
  ///
  /// Something still in use is worth more than nothing, and an inventory that
  /// depreciates a working sofa to zero invites an adjuster to pay zero for it.
  static const double salvageFraction = 0.10;

  static int? lifeFor(String category) =>
      usefulLifeYears.containsKey(category)
          ? usefulLifeYears[category]
          : usefulLifeYears['Other'];

  /// Whether this category is depreciated at all.
  static bool depreciates(String category) => lifeFor(category) != null;

  /// The estimated value of [asset] as of [asOf], defaulting to today.
  static double currentValue(Asset asset, {DateTime? asOf}) {
    final life = lifeFor(asset.category);
    if (life == null || life <= 0) return asset.price;

    final now = asOf ?? DateTime.now();
    // A future purchase date means somebody mistyped it. Depreciating by a
    // negative age would inflate the value above what was paid, so hold it at
    // the price instead.
    final ageDays = now.difference(asset.purchaseDate).inDays;
    if (ageDays <= 0) return asset.price;

    final ageYears = ageDays / 365.25;
    final remaining = 1 - (ageYears / life);
    final fraction = remaining < salvageFraction ? salvageFraction : remaining;
    return asset.price * fraction;
  }

  /// How much [asset] has lost since it was bought.
  static double lossToDate(Asset asset, {DateTime? asOf}) =>
      asset.price - currentValue(asset, asOf: asOf);

  /// Totals across a list, so a caller does not walk it three times.
  static DepreciationSummary summarize(List<Asset> assets, {DateTime? asOf}) {
    var paid = 0.0;
    var current = 0.0;
    for (final asset in assets) {
      paid += asset.price;
      current += currentValue(asset, asOf: asOf);
    }
    return DepreciationSummary(totalPaid: paid, totalCurrent: current);
  }
}

class DepreciationSummary {
  /// What everything cost when it was bought.
  final double totalPaid;

  /// What everything is estimated to be worth now.
  final double totalCurrent;

  const DepreciationSummary({
    required this.totalPaid,
    required this.totalCurrent,
  });

  double get totalLoss => totalPaid - totalCurrent;

  /// The loss as a share of what was paid, 0 when nothing was.
  double get lossFraction => totalPaid == 0 ? 0 : totalLoss / totalPaid;
}
