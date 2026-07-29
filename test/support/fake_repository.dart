import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/models/service_record.dart';
import 'package:itemize/data/repositories/asset_repository.dart';

/// An asset store that lives in a list, for widget tests.
///
/// The real repository goes through sqflite_ffi, which opens the database on
/// a background isolate. A widget test runs inside a fake clock, so a future
/// that only completes when real I/O finishes never completes at all: the test
/// hangs in `pumpWidget` rather than failing, which is a great deal harder to
/// diagnose than a failure. Everything here resolves on a microtask, which the
/// fake clock does run.
///
/// Deliberately a subclass rather than an interface: nothing in the app needs
/// a repository abstraction, and inventing one only so a test can substitute
/// for it would be a production design change made for a test's benefit.
class FakeRepository extends AssetRepository {
  FakeRepository([List<Asset> seed = const []]) : _assets = [...seed];

  final List<Asset> _assets;
  final List<MaintenanceSchedule> _schedules = [];
  final List<ServiceRecord> _records = [];

  List<Asset> get assets => List.unmodifiable(_assets);

  @override
  Future<List<Asset>> getAllAssets() async => List.of(_assets);

  @override
  Future<void> addAsset(Asset asset) async => _assets.add(asset);

  @override
  Future<void> addAssets(List<Asset> assets) async => _assets.addAll(assets);

  @override
  Future<int> countAssets() async => _assets.length;

  @override
  Future<Asset> getAsset(String id) async =>
      _assets.firstWhere((a) => a.id == id);

  @override
  Future<Asset?> findAsset(String id) async {
    for (final asset in _assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    final at = _assets.indexWhere((a) => a.id == asset.id);
    if (at >= 0) _assets[at] = asset;
  }

  @override
  Future<void> deleteAsset(String id) async {
    _assets.removeWhere((a) => a.id == id);
    _schedules.removeWhere((s) => s.assetId == id);
    _records.removeWhere((r) => r.assetId == id);
  }

  @override
  Future<List<MaintenanceSchedule>> allSchedules() async => List.of(_schedules);

  @override
  Future<List<MaintenanceSchedule>> schedulesFor(String assetId) async =>
      _schedules.where((s) => s.assetId == assetId).toList();

  @override
  Future<void> saveSchedule(MaintenanceSchedule schedule) async {
    final at = _schedules.indexWhere((s) => s.id == schedule.id);
    at >= 0 ? _schedules[at] = schedule : _schedules.add(schedule);
  }

  @override
  Future<List<ServiceRecord>> allServiceRecords() async => List.of(_records);

  @override
  Future<List<ServiceRecord>> serviceRecordsFor(String assetId) async =>
      _records.where((r) => r.assetId == assetId).toList();
}
