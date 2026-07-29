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
            languageCode: settings.languageCode,
          );
        },
      );
    });

/// Every stored item, whatever the Assets tab happens to be showing.
///
/// [assetListProvider] is watched only as a change signal; the items themselves
/// come from storage. Screens that show a filtered view read this and narrow it
/// themselves, so no screen's filter can shrink another's.
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
  /// Reminders are rebuilt from whatever this is given, so it must only ever
  /// be given everything: handing it a subset would cancel the reminders of
  /// every item left out of it.
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

  /// Stores a whole batch and reloads once.
  ///
  /// Quick Capture saves a photographed room in one go. Looping [addAsset]
  /// meant a full table reload and a complete reminder resync -- cancel
  /// everything, then re-schedule up to sixty notifications -- for each item in
  /// turn, so a forty-item room cost forty reloads and some two thousand
  /// platform calls while the owner watched a progress bar. The batch is
  /// written in one transaction, so a room is saved whole or not at all.
  ///
  /// Returns whether it was stored. The caller has to know: nothing else on
  /// screen reads this notifier's error state any more, so a failure that only
  /// went into the state would leave the owner looking at a success message
  /// for a room that was never saved.
  Future<bool> addAssets(List<Asset> assets) async {
    if (assets.isEmpty) return true;
    try {
      await _repository.addAssets(assets);
      await loadAssets();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
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

  // There is deliberately no search() here any more.
  //
  // It replaced the shared state with a narrowed list, which is a screen's
  // display decision written into everybody's data: the tabs are held alive by
  // an IndexedStack, so a query typed on the Assets tab followed the user to
  // the dashboard and to the room drill-down. Filtering now happens where it
  // is displayed, over the list this notifier already provides. See
  // `assetMatchesQuery` in core/utils/asset_search.dart.
}
