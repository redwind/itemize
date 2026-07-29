/// How many items a free account may hold before Pro is required.
///
/// Chosen as a number that lets someone genuinely try the app on a real room
/// or two before hitting it -- a limit low enough to nag never gets tried,
/// and one high enough to be pointless never converts.
const int kFreeItemLimit = 40;

/// How much room a free account has left to add new items.
///
/// This gates *creation* only. It answers "how many more can I add", never
/// "how many may I keep" -- a restored backup, a synced device, or a Pro
/// grant that RevenueCat has not caught up on yet can all leave someone
/// holding more than [kFreeItemLimit] items, and that is not this function's
/// business to fix or flag. Nothing is ever deleted or refused on read; the
/// gate belongs solely at the point where a new item is about to be written,
/// and callers on any restore, sync or import path must not call this at all.
///
/// `null` means unlimited, standing in for "no ceiling" rather than some
/// arbitrarily large int a caller could accidentally compare against, add to,
/// or format into a UI string as if it were a real count. A sentinel like -1
/// would need every caller to remember to check for it before doing math;
/// `int?` makes the unlimited case something the type system forces a caller
/// to handle before treating the value as a number.
///
/// [currentCount] may exceed [kFreeItemLimit] (see above); this clamps the
/// result at zero rather than returning negative "room".
int? remainingFreeSlots({required int currentCount, required bool isPro}) {
  if (isPro) return null;
  final remaining = kFreeItemLimit - currentCount;
  return remaining > 0 ? remaining : 0;
}

/// How many items of a proposed batch may be added right now.
///
/// Built for Quick Capture: a whole room gets photographed and drafted in one
/// pass, and the save step needs to know up front that 12 of 30 drafts fit
/// rather than writing them one at a time until the 13th is turned away.
///
/// Returns [batchSize] unchanged for Pro, or when the batch is empty -- both
/// cases where there is nothing for the limit to say. Otherwise returns
/// however much of the batch fits in the room reported by
/// [remainingFreeSlots], which is never more than [batchSize] and never
/// negative. This never inspects the batch's contents, only its length: which
/// items get kept when a batch is trimmed is a UI decision, not this one.
int fitBatch({
  required int batchSize,
  required int currentCount,
  required bool isPro,
}) {
  if (batchSize <= 0) return batchSize < 0 ? 0 : batchSize;

  final remaining = remainingFreeSlots(currentCount: currentCount, isPro: isPro);
  if (remaining == null) return batchSize;
  return remaining < batchSize ? remaining : batchSize;
}
