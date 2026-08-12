import 'package:inventa/data/models/asset.dart';

/// Whether [asset] answers to [query].
///
/// Serial, model and barcode are matched as well as the name: hunting down one
/// specific unit -- which is what someone does mid-claim -- is done by the
/// number printed on it, not by a name they may have typed inconsistently.
bool assetMatchesQuery(Asset asset, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;

  for (final field in [
    asset.name,
    asset.room,
    asset.category,
    asset.brand,
    asset.model,
    asset.serialNumber,
    asset.barcode,
  ]) {
    if (field != null && field.toLowerCase().contains(needle)) return true;
  }
  return false;
}

/// The items in [assets] that answer to [query], in the order given.
///
/// Filtering is done here, over a list already in memory, rather than by
/// asking storage on every keystroke. It also has to stay a pure function of
/// the list: search used to be a method on the asset list notifier that
/// replaced the shared state with a narrowed one, and since the tabs are held
/// alive by an IndexedStack, typing on the Assets tab rewrote the dashboard's
/// headline total to the value of whatever matched. What one screen displays
/// is that screen's business.
List<Asset> filterAssets(List<Asset> assets, String query) {
  if (query.trim().isEmpty) return assets;
  return assets.where((a) => assetMatchesQuery(a, query)).toList();
}
