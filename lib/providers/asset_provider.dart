import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/repositories/asset_repository.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

final assetListProvider =
    StateNotifierProvider<AssetListNotifier, AsyncValue<List<Asset>>>((ref) {
      return AssetListNotifier(ref.watch(assetRepositoryProvider));
    });

// For Total Value
final totalValueProvider = Provider<double>((ref) {
  final assetsAsync = ref.watch(assetListProvider);
  return assetsAsync.when(
    data:
        (assets) => assets.fold(
          0,
          (sum, item) => sum + item.price,
        ), // Simple sum, currency handling needed later
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// For Asset Count
final assetCountProvider = Provider<int>((ref) {
  final assetsAsync = ref.watch(assetListProvider);
  return assetsAsync.maybeWhen(
    data: (assets) => assets.length,
    orElse: () => 0,
  );
});

class AssetListNotifier extends StateNotifier<AsyncValue<List<Asset>>> {
  final AssetRepository _repository;

  AssetListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAssets();
  }

  Future<void> loadAssets() async {
    try {
      final assets = await _repository.getAllAssets();
      state = AsyncValue.data(assets);
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
