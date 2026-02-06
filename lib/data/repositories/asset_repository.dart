import 'package:itemize/data/database/database_helper.dart';
import 'package:itemize/data/models/asset.dart';

class AssetRepository {
  final DatabaseHelper _dbHelper;

  AssetRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> addAsset(Asset asset) async {
    await _dbHelper.create(asset);
  }

  Future<List<Asset>> getAllAssets() async {
    return await _dbHelper.readAllAssets();
  }

  Future<Asset> getAsset(String id) async {
    return await _dbHelper.readAsset(id);
  }

  Future<void> updateAsset(Asset asset) async {
    await _dbHelper.update(asset);
  }

  Future<void> deleteAsset(String id) async {
    await _dbHelper.delete(id);
  }

  // Basic search implementation (can be improved with SQL LIKE)
  Future<List<Asset>> searchAssets(String query) async {
    final allAssets = await getAllAssets();
    if (query.isEmpty) return allAssets;

    final lowerQuery = query.toLowerCase();
    return allAssets.where((asset) {
      return asset.name.toLowerCase().contains(lowerQuery) ||
          asset.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
