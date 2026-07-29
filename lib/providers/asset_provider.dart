import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/core/utils/depreciation.dart';
import 'package:itemize/core/utils/maintenance_planner.dart';
import 'package:itemize/core/utils/reminders.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/models/service_record.dart';
import 'package:itemize/data/repositories/asset_repository.dart';
import 'package:itemize/providers/settings_provider.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

final assetListProvider =
    StateNotifierProvider<AssetListNotifier, AsyncValue<List<Asset>>>((ref) {
      return AssetListNotifier(
        ref.watch(assetRepositoryProvider),
        onReload: (assets) async {
          final settings = ref.read(settingsProvider);
          // Schedules are fetched here rather than watched: the reminder set is
          // rebuilt whole on every reload, and reading them once at that moment
          // is what keeps the two in step without a second listener.
          final schedules =
              await ref.read(assetRepositoryProvider).allSchedules();
          await Reminders.instance.sync(
            assets,
            schedules: schedules,
            warrantyEnabled: settings.warrantyRemindersEnabled,
            maintenanceEnabled: settings.maintenanceRemindersEnabled,
          );
        },
      );
    });

/// Every stored item, whatever the Assets tab happens to be showing.
///
/// [assetListProvider] is watched only as a change signal; the items themselves
/// come from storage. Its state is replaced by a narrowed list whenever
/// [AssetListNotifier.search] runs, so reading it here would quietly shrink the
/// Care screen and the maintenance plan to match a query typed on another tab.
final allAssetsProvider = FutureProvider<List<Asset>>((ref) {
  ref.watch(assetListProvider);
  return ref.read(assetRepositoryProvider).getAllAssets();
});

/// Every job across every item, soonest first.
final maintenancePlanProvider = FutureProvider<List<MaintenanceDue>>((
  ref,
) async {
  final assets = await ref.watch(allAssetsProvider.future);
  final schedules = await ref.read(assetRepositoryProvider).allSchedules();
  return MaintenancePlanner.plan(assets, schedules);
});

/// The schedules attached to one item.
final schedulesForAssetProvider =
    FutureProvider.family<List<MaintenanceSchedule>, String>((ref, assetId) {
      // Watched so that adding an item's schedule refreshes its own screen too.
      ref.watch(assetListProvider);
      return ref.read(assetRepositoryProvider).schedulesFor(assetId);
    });

/// The history recorded against one item, newest first.
final serviceRecordsProvider =
    FutureProvider.family<List<ServiceRecord>, String>((ref, assetId) {
      ref.watch(assetListProvider);
      return ref.read(assetRepositoryProvider).serviceRecordsFor(assetId);
    });

// The three below read [allAssetsProvider], never [assetListProvider].
//
// They answer "what do I own, in total", and the answer must not change because
// a query happens to be typed on another tab. Search replaces the list state
// with a narrowed one and the tabs are kept alive by an IndexedStack, so
// reading it here meant typing "TV" on the Assets tab silently rewrote the
// dashboard's headline total to the value of the televisions.

// For Total Value
final totalValueProvider = Provider<double>((ref) {
  final assetsAsync = ref.watch(allAssetsProvider);
  return assetsAsync.maybeWhen(
    // Simple sum, currency handling needed later
    data: (assets) => assets.fold<double>(0, (sum, item) => sum + item.price),
    orElse: () => 0.0,
  );
});

/// What everything cost against what it is estimated to be worth now.
final depreciationProvider = Provider<DepreciationSummary>((ref) {
  final assetsAsync = ref.watch(allAssetsProvider);
  return assetsAsync.maybeWhen(
    data: Depreciation.summarize,
    orElse: () => const DepreciationSummary(totalPaid: 0, totalCurrent: 0),
  );
});

// For Asset Count
final assetCountProvider = Provider<int>((ref) {
  final assetsAsync = ref.watch(allAssetsProvider);
  return assetsAsync.maybeWhen(
    data: (assets) => assets.length,
    orElse: () => 0,
  );
});

class AssetListNotifier extends StateNotifier<AsyncValue<List<Asset>>> {
  final AssetRepository _repository;

  /// Handed the complete list every time it is reloaded from storage.
  ///
  /// Called from [loadAssets] alone, deliberately never from [search]: search
  /// replaces the state with a narrowed list, and rescheduling reminders off
  /// that would cancel them for every item the query happened to exclude.
  final Future<void> Function(List<Asset>)? onReload;

  AssetListNotifier(this._repository, {this.onReload})
    : super(const AsyncValue.loading()) {
    loadAssets();
  }

  Future<void> loadAssets() async {
    try {
      final assets = await _repository.getAllAssets();
      state = AsyncValue.data(assets);
      await onReload?.call(assets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Helper for export
  Future<List<Asset>> loadAssetsForExport() async {
    return _repository.getAllAssets();
  }

  Future<void> addAsset(Asset asset) async {
    try {
      await _repository.addAsset(asset);
      await loadAssets(); // Reload to refresh list
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Records that the owner has confirmed this entry is still true.
  Future<void> markReviewed(Asset asset) =>
      updateAsset(asset.copyWith(lastReviewedAt: DateTime.now()));

  Future<void> updateAsset(Asset asset) async {
    try {
      await _repository.updateAsset(asset);
      await loadAssets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await _repository.deleteAsset(id);
      await loadAssets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Deletes an item, handing back everything needed to put it right again.
  ///
  /// The snapshot is taken before the delete, not reconstructed after: the
  /// schedules and history go with the item and there is nothing left to read
  /// once it has gone.
  Future<DeletedAsset?> deleteAssetWithUndo(Asset asset) async {
    try {
      final snapshot = await _repository.takeSnapshot(asset);
      await _repository.deleteAsset(asset.id);
      await loadAssets();
      return snapshot;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> undoDelete(DeletedAsset snapshot) async {
    try {
      await _repository.restore(snapshot);
      await loadAssets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> search(String query) async {
    try {
      // Optimistic filtering or DB query
      final assets = await _repository.searchAssets(query);
      state = AsyncValue.data(assets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
