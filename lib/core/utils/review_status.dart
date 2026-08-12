import 'package:inventa/data/models/asset.dart';

/// Keeps the record honest enough to be worth something.
///
/// An inventory written in one year and claimed on in another is half wrong by
/// then. Things get sold, given away, broken and replaced, and nobody comes
/// back to say so. An insurer given a list that includes a television sold two
/// years ago has a reason to doubt the rest of it, so drift does not merely
/// waste the entry — it weakens every other one.
///
/// The remedy is small: keep track of when each entry was last confirmed, and
/// ask about the oldest.
class ReviewStatus {
  const ReviewStatus._();

  /// How long an entry stands before it is worth confirming again.
  ///
  /// A year, matched to the rhythm of a policy renewal, which is when someone
  /// is already thinking about what they own.
  static const int staleAfterDays = 365;

  /// How many to ask about at once.
  ///
  /// A list of two hundred is a chore nobody starts. A handful is a minute's
  /// work, and the rest come round next time.
  static const int batchSize = 5;

  static bool needsReview(Asset asset, {DateTime? now}) {
    final reviewed = asset.lastReviewedAt;
    // Null means the entry predates the app tracking this at all — the oldest
    // records, and the least likely to still be true.
    if (reviewed == null) return true;

    final moment = now ?? DateTime.now();
    return moment.difference(reviewed).inDays >= staleAfterDays;
  }

  /// Days since an entry was last confirmed, or null when it never was.
  static int? daysSinceReview(Asset asset, {DateTime? now}) {
    final reviewed = asset.lastReviewedAt;
    if (reviewed == null) return null;
    return (now ?? DateTime.now()).difference(reviewed).inDays;
  }

  /// Everything worth asking about, longest-unconfirmed first.
  static List<Asset> needingReview(List<Asset> assets, {DateTime? now}) {
    final stale = assets.where((a) => needsReview(a, now: now)).toList();

    stale.sort((a, b) {
      final aReviewed = a.lastReviewedAt;
      final bReviewed = b.lastReviewedAt;
      // Never-confirmed entries come first: they are the ones carried over from
      // before any of this existed.
      if (aReviewed == null && bReviewed == null) return a.name.compareTo(b.name);
      if (aReviewed == null) return -1;
      if (bReviewed == null) return 1;
      return aReviewed.compareTo(bReviewed);
    });

    return stale;
  }

  /// The handful to put in front of someone now.
  static List<Asset> nextBatch(List<Asset> assets, {DateTime? now}) =>
      needingReview(assets, now: now).take(batchSize).toList();
}
