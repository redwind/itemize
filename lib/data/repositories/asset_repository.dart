import 'package:itemize/data/database/database_helper.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/models/service_record.dart';

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

  /// The asset with this id, or null when there is none.
  ///
  /// Distinct from [getAsset], which throws: a restore asks about hundreds of
  /// ids expecting most to be absent, and absence there is the ordinary case
  /// rather than an error.
  Future<Asset?> findAsset(String id) async {
    try {
      return await _dbHelper.readAsset(id);
    } catch (_) {
      return null;
    }
  }

  /// Total stored assets, independent of any active search filter.
  Future<int> countAssets() async {
    return await _dbHelper.countAssets();
  }

  Future<void> updateAsset(Asset asset) async {
    await _dbHelper.update(asset);
  }

  Future<void> deleteAsset(String id) async {
    await _dbHelper.delete(id);
  }

  /// Everything belonging to an item, kept so a deletion can be undone.
  ///
  /// Deleting takes the schedules and the whole service history with it, which
  /// on a well-kept item is years of records that cannot be reconstructed. A
  /// confirmation dialog guards against the wrong tap; this guards against the
  /// right tap being regretted.
  Future<DeletedAsset> takeSnapshot(Asset asset) async {
    return DeletedAsset(
      asset: asset,
      schedules: await schedulesFor(asset.id),
      records: await serviceRecordsFor(asset.id),
    );
  }

  /// Puts back everything [takeSnapshot] captured.
  ///
  /// Records go back through [saveServiceRecordRaw] rather than [logService]:
  /// the schedules carry their own restored last-done dates, and replaying the
  /// history over them would rewrite those with whatever landed last.
  /// Restoring the same snapshot twice is harmless, which matters because the
  /// only caller is a button somebody may press more than once.
  Future<void> restore(DeletedAsset snapshot) async {
    await _dbHelper.upsert(snapshot.asset);
    for (final schedule in snapshot.schedules) {
      await saveSchedule(schedule);
    }
    for (final record in snapshot.records) {
      await saveServiceRecordRaw(record);
    }
  }

  // --- Maintenance and history --------------------------------------------

  Future<List<MaintenanceSchedule>> schedulesFor(String assetId) =>
      _dbHelper.readSchedules(assetId);

  Future<List<MaintenanceSchedule>> allSchedules() =>
      _dbHelper.readAllSchedules();

  Future<void> saveSchedule(MaintenanceSchedule schedule) =>
      _dbHelper.upsertSchedule(schedule);

  Future<void> deleteSchedule(String id) => _dbHelper.deleteSchedule(id);

  Future<List<ServiceRecord>> serviceRecordsFor(String assetId) =>
      _dbHelper.readServiceRecords(assetId);

  Future<List<ServiceRecord>> allServiceRecords() =>
      _dbHelper.readAllServiceRecords();

  Future<void> deleteServiceRecord(String id) =>
      _dbHelper.deleteServiceRecord(id);

  /// Stores a record without touching any schedule.
  ///
  /// Used by the restore, where the archived schedules already carry their own
  /// last-done dates; replaying the history through [logService] would rewrite
  /// them with whatever happened to be processed last.
  Future<void> saveServiceRecordRaw(ServiceRecord record) =>
      _dbHelper.upsertServiceRecord(record);

  /// Records work done, and marks the schedule it satisfies as up to date.
  ///
  /// The two go together on purpose. Logging a service and separately telling
  /// the app the schedule is done is a step people would forget, leaving them
  /// nagged about a job they have just paid for.
  Future<void> logService(ServiceRecord record) async {
    await _dbHelper.upsertServiceRecord(record);

    final scheduleId = record.scheduleId;
    if (scheduleId == null) return;

    final schedules = await _dbHelper.readSchedules(record.assetId);
    for (final schedule in schedules) {
      if (schedule.id != scheduleId) continue;
      // Only moves the clock forward. Back-filling an old receipt should not
      // make a schedule look more overdue than it is.
      if (schedule.lastDoneAt != null &&
          !record.date.isAfter(schedule.lastDoneAt!)) {
        return;
      }
      await _dbHelper.upsertSchedule(schedule.copyWith(lastDoneAt: record.date));
      return;
    }
  }

  // Basic search implementation (can be improved with SQL LIKE)
  Future<List<Asset>> searchAssets(String query) async {
    final allAssets = await getAllAssets();
    if (query.isEmpty) return allAssets;

    final lowerQuery = query.toLowerCase();
    return allAssets.where((asset) {
      // Serial and model are searched too: hunting down one specific unit --
      // which is what someone does mid-claim -- is done by the number on it,
      // not by a name they may have typed inconsistently.
      return [
        asset.name,
        asset.room,
        asset.category,
        asset.brand,
        asset.model,
        asset.serialNumber,
      ].any(
        (field) => field != null && field.toLowerCase().contains(lowerQuery),
      );
    }).toList();
  }
}

/// An item and everything that hung off it, held long enough to change your
/// mind.
class DeletedAsset {
  final Asset asset;
  final List<MaintenanceSchedule> schedules;
  final List<ServiceRecord> records;

  const DeletedAsset({
    required this.asset,
    required this.schedules,
    required this.records,
  });

  /// True when the item carried history worth warning about losing.
  bool get hadHistory => schedules.isNotEmpty || records.isNotEmpty;
}
