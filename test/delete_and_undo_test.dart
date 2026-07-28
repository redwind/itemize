import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/data/database/database_helper.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/models/service_record.dart';
import 'package:itemize/data/repositories/asset_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Asset asset({String id = 'a', String name = 'Boiler'}) => Asset(
  id: id,
  name: name,
  price: 2000,
  currency: 'USD',
  room: 'Garage',
  category: 'Appliances',
  photoPaths: const ['images/boiler.jpg'],
  serialNumber: 'SN-77',
  purchaseDate: DateTime(2023, 4, 1),
  warrantyExpiry: DateTime(2028, 4, 1),
);

MaintenanceSchedule schedule({String id = 's1', String assetId = 'a'}) =>
    MaintenanceSchedule(
      id: id,
      assetId: assetId,
      title: 'Annual service',
      intervalMonths: 12,
      lastDoneAt: DateTime(2026, 5, 1),
      requiredForWarranty: true,
    );

ServiceRecord record({
  String id = 'r1',
  String assetId = 'a',
  String? scheduleId = 's1',
  double cost = 145,
  DateTime? date,
}) => ServiceRecord(
  id: id,
  assetId: assetId,
  date: date ?? DateTime(2026, 5, 1),
  kind: ServiceKind.maintenance,
  description: 'Annual service',
  cost: cost,
  provider: 'Gas Safe Ltd',
  scheduleId: scheduleId,
);

void main() {
  sqfliteFfiInit();

  late Database db;
  late AssetRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseHelper.schemaVersion,
        onCreate: DatabaseHelper.createSchema,
      ),
    );
    repository = AssetRepository(dbHelper: DatabaseHelper.withDatabase(db));
  });

  tearDown(() async => db.close());

  Future<void> seed() async {
    await repository.addAsset(asset());
    await repository.saveSchedule(schedule());
    await repository.saveServiceRecordRaw(record());
  }

  group('deleting takes the history with it', () {
    test('schedules and records go too, leaving no orphans', () async {
      await seed();
      await repository.deleteAsset('a');

      expect(await repository.getAllAssets(), isEmpty);
      expect(await repository.allSchedules(), isEmpty);
      expect(await repository.allServiceRecords(), isEmpty);
    });

    test('another item is untouched', () async {
      await seed();
      await repository.addAsset(asset(id: 'b', name: 'Mower'));
      await repository.saveSchedule(schedule(id: 's2', assetId: 'b'));
      await repository.saveServiceRecordRaw(
        record(id: 'r2', assetId: 'b', scheduleId: 's2'),
      );

      await repository.deleteAsset('a');

      expect((await repository.getAllAssets()).single.id, 'b');
      expect((await repository.allSchedules()).single.id, 's2');
      expect((await repository.allServiceRecords()).single.id, 'r2');
    });
  });

  group('undo', () {
    test('puts the item, its schedules and its history back', () async {
      await seed();

      final snapshot = await repository.takeSnapshot(asset());
      await repository.deleteAsset('a');
      expect(await repository.getAllAssets(), isEmpty);

      await repository.restore(snapshot);

      final restored = (await repository.getAllAssets()).single;
      expect(restored.id, 'a');
      expect(restored.name, 'Boiler');
      expect(restored.serialNumber, 'SN-77');
      expect(restored.photoPaths, ['images/boiler.jpg']);
      expect(restored.warrantyExpiry, DateTime(2028, 4, 1));

      final restoredSchedule = (await repository.allSchedules()).single;
      expect(restoredSchedule.title, 'Annual service');
      expect(restoredSchedule.requiredForWarranty, isTrue);
      expect(
        restoredSchedule.lastDoneAt,
        DateTime(2026, 5, 1),
        reason: 'restoring must not replay history over the schedule',
      );

      final restoredRecord = (await repository.allServiceRecords()).single;
      expect(restoredRecord.cost, 145);
      expect(restoredRecord.provider, 'Gas Safe Ltd');
      expect(restoredRecord.scheduleId, 's1');
    });

    test('the snapshot is taken before the delete, not after', () async {
      await seed();

      final snapshot = await repository.takeSnapshot(asset());
      expect(snapshot.schedules, hasLength(1));
      expect(snapshot.records, hasLength(1));
      expect(snapshot.hadHistory, isTrue);
    });

    test('an item with nothing attached reports no history', () async {
      await repository.addAsset(asset(id: 'bare'));
      final snapshot = await repository.takeSnapshot(asset(id: 'bare'));
      expect(snapshot.hadHistory, isFalse);
    });

    test('restoring twice does not duplicate anything', () async {
      await seed();
      final snapshot = await repository.takeSnapshot(asset());
      await repository.deleteAsset('a');

      await repository.restore(snapshot);
      await repository.restore(snapshot);

      expect(await repository.getAllAssets(), hasLength(1));
      expect(await repository.allSchedules(), hasLength(1));
      expect(await repository.allServiceRecords(), hasLength(1));
    });
  });

  group('deleting a schedule is gentler than deleting an item', () {
    test('the history survives, only its link goes', () async {
      await seed();

      await repository.deleteSchedule('s1');

      expect(await repository.allSchedules(), isEmpty);
      final surviving = (await repository.allServiceRecords()).single;
      expect(surviving.id, 'r1');
      expect(
        surviving.scheduleId,
        isNull,
        reason: 'the record stays, unlinked from a schedule that has gone',
      );
      expect(surviving.cost, 145);
    });
  });

  group('logging work', () {
    test('moves the schedule forward', () async {
      await repository.addAsset(asset());
      await repository.saveSchedule(
        MaintenanceSchedule(
          id: 's1',
          assetId: 'a',
          title: 'Annual service',
          intervalMonths: 12,
        ),
      );

      await repository.logService(record(date: DateTime(2026, 7, 1)));

      expect(
        (await repository.allSchedules()).single.lastDoneAt,
        DateTime(2026, 7, 1),
        reason: 'a job never done before is now dated by the work logged',
      );
    });

    test('back-filling an old receipt does not drag the schedule backwards',
        () async {
      await seed(); // schedule last done 1 May 2026

      await repository.logService(
        ServiceRecord(
          id: 'old',
          assetId: 'a',
          date: DateTime(2024, 1, 1),
          kind: ServiceKind.maintenance,
          cost: 100,
          scheduleId: 's1',
        ),
      );

      expect(
        (await repository.allSchedules()).single.lastDoneAt,
        DateTime(2026, 5, 1),
        reason: 'an older record must not make the job look overdue again',
      );
      expect(await repository.allServiceRecords(), hasLength(2));
    });
  });
}
