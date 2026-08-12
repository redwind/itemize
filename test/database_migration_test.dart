import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/data/database/database_helper.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/data/models/maintenance_schedule.dart';
import 'package:inventa/data/models/service_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The schema as it shipped in v1, reproduced verbatim.
///
/// Copied rather than imported because the point is to prove that a database
/// built by the *old* code survives the upgrade; generating it from the current
/// code would only prove the current code agrees with itself.
const String _v1Schema = '''
CREATE TABLE assets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  price REAL NOT NULL,
  currency TEXT NOT NULL,
  category TEXT NOT NULL,
  imagePath TEXT NOT NULL,
  barcode TEXT,
  purchaseDate TEXT NOT NULL,
  warrantyExpiry TEXT,
  isFavorite INTEGER NOT NULL
  )
''';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  group('v1 -> v2 migration', () {
    late Database db;

    setUp(() async {
      db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 1, onCreate: (db, _) async {
          await db.execute(_v1Schema);
        }),
      );
    });

    tearDown(() async => db.close());

    Future<void> insertV1Row({
      required String id,
      required String category,
      String imagePath = 'images/old.jpg',
    }) {
      return db.insert('assets', {
        'id': id,
        'name': 'Old Sofa',
        'price': 1200.0,
        'currency': 'USD',
        'category': category,
        'imagePath': imagePath,
        'barcode': null,
        'purchaseDate': '2023-04-01T00:00:00.000',
        'warrantyExpiry': null,
        'isFavorite': 1,
      });
    }

    test('moves the room out of category and leaves the category blank',
        () async {
      await insertV1Row(id: 'a', category: 'Living Room');

      await DatabaseHelper.migrate(db, 1, DatabaseHelper.schemaVersion);

      final asset = Asset.fromMap((await db.query('assets')).single);
      expect(asset.room, 'Living Room');
      expect(asset.category, kUncategorized);
    });

    test('keeps the v1 photo reachable without backfilling photoPaths',
        () async {
      await insertV1Row(id: 'a', category: 'Kitchen');

      await DatabaseHelper.migrate(db, 1, DatabaseHelper.schemaVersion);

      final row = (await db.query('assets')).single;
      expect(row['photoPaths'], isNull, reason: 'backfill is deliberately skipped');

      final asset = Asset.fromMap(row);
      expect(asset.photoPaths, ['images/old.jpg']);
      expect(asset.imagePath, 'images/old.jpg');
    });

    test('carries every other v1 field across untouched', () async {
      await insertV1Row(id: 'a', category: 'Office');

      await DatabaseHelper.migrate(db, 1, DatabaseHelper.schemaVersion);

      final asset = Asset.fromMap((await db.query('assets')).single);
      expect(asset.id, 'a');
      expect(asset.name, 'Old Sofa');
      expect(asset.price, 1200.0);
      expect(asset.currency, 'USD');
      expect(asset.purchaseDate, DateTime.parse('2023-04-01T00:00:00.000'));
      expect(asset.isFavorite, isTrue);
      expect(asset.serialNumber, isNull);
      expect(asset.receiptPath, isNull);
    });

    test('an item with no photo migrates to an empty photo list', () async {
      await insertV1Row(id: 'a', category: 'Garage', imagePath: '');

      await DatabaseHelper.migrate(db, 1, DatabaseHelper.schemaVersion);

      final asset = Asset.fromMap((await db.query('assets')).single);
      expect(asset.photoPaths, isEmpty);
      expect(asset.imagePath, '');
    });

    test('migrates every row, not just the first', () async {
      await insertV1Row(id: 'a', category: 'Bedroom');
      await insertV1Row(id: 'b', category: 'Garage');

      await DatabaseHelper.migrate(db, 1, DatabaseHelper.schemaVersion);

      final assets =
          (await db.query('assets', orderBy: 'id')).map(Asset.fromMap).toList();
      expect(assets.map((a) => a.room), ['Bedroom', 'Garage']);
      expect(assets.every((a) => a.category == kUncategorized), isTrue);
    });

    test('a migrated row accepts a full v2 write', () async {
      await insertV1Row(id: 'a', category: 'Living Room');
      await DatabaseHelper.migrate(db, 1, DatabaseHelper.schemaVersion);

      final updated = Asset.fromMap((await db.query('assets')).single).copyWith(
        category: 'Furniture',
        photoPaths: ['images/one.jpg', 'images/two.jpg'],
        receiptPath: 'images/receipt.jpg',
        serialNumber: 'SN-123',
        brand: 'Ikea',
        model: 'KIVIK',
        notes: 'Corner unit, grey',
      );
      await db.update('assets', updated.toMap(),
          where: 'id = ?', whereArgs: ['a']);

      final reread = Asset.fromMap((await db.query('assets')).single);
      expect(reread.category, 'Furniture');
      expect(reread.photoPaths, ['images/one.jpg', 'images/two.jpg']);
      expect(reread.imagePath, 'images/one.jpg',
          reason: 'cover stays the first photo');
      expect(reread.serialNumber, 'SN-123');
      expect(reread.notes, 'Corner unit, grey');
    });
  });

  group('v2 -> v3 migration', () {
    /// The v2 schema, reproduced as it shipped.
    const v2Schema = '''
CREATE TABLE assets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  price REAL NOT NULL,
  currency TEXT NOT NULL,
  room TEXT,
  category TEXT NOT NULL,
  imagePath TEXT NOT NULL,
  photoPaths TEXT,
  receiptPath TEXT,
  barcode TEXT,
  serialNumber TEXT,
  brand TEXT,
  model TEXT,
  notes TEXT,
  purchaseDate TEXT NOT NULL,
  warrantyExpiry TEXT NOT NULL,
  isFavorite INTEGER NOT NULL
  )
''';

    late Database db;

    setUp(() async {
      db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, _) async => db.execute(v2Schema),
        ),
      );
      await db.insert('assets', {
        'id': 'a',
        'name': 'Boiler',
        'price': 2000.0,
        'currency': 'USD',
        'room': 'Garage',
        'category': 'Appliances',
        'imagePath': 'images/boiler.jpg',
        'photoPaths': '["images/boiler.jpg"]',
        'purchaseDate': '2023-04-01T00:00:00.000',
        'warrantyExpiry': '2028-04-01T00:00:00.000',
        'isFavorite': 0,
      });
    });

    tearDown(() async => db.close());

    test('adds the new tables and leaves the item intact', () async {
      await DatabaseHelper.migrate(db, 2, DatabaseHelper.schemaVersion);

      final asset = Asset.fromMap((await db.query('assets')).single);
      expect(asset.name, 'Boiler');
      expect(asset.room, 'Garage');
      expect(asset.category, 'Appliances');
      expect(asset.photoPaths, ['images/boiler.jpg']);
      expect(asset.lastReviewedAt, isNull);

      expect((await db.query('maintenance_schedules')), isEmpty);
      expect((await db.query('service_records')), isEmpty);
    });

    test('the new tables accept and return their rows', () async {
      await DatabaseHelper.migrate(db, 2, DatabaseHelper.schemaVersion);

      await db.insert(
        'maintenance_schedules',
        const MaintenanceSchedule(
          id: 's1',
          assetId: 'a',
          title: 'Annual service',
          intervalMonths: 12,
          requiredForWarranty: true,
        ).toMap(),
      );
      await db.insert(
        'service_records',
        ServiceRecord(
          id: 'r1',
          assetId: 'a',
          date: DateTime(2026, 5, 1),
          kind: ServiceKind.maintenance,
          cost: 120,
          provider: 'Gas Safe Ltd',
          scheduleId: 's1',
        ).toMap(),
      );

      final schedule = MaintenanceSchedule.fromMap(
        (await db.query('maintenance_schedules')).single,
      );
      expect(schedule.title, 'Annual service');
      expect(schedule.requiredForWarranty, isTrue);
      expect(schedule.lastDoneAt, isNull);

      final record = ServiceRecord.fromMap(
        (await db.query('service_records')).single,
      );
      expect(record.kind, ServiceKind.maintenance);
      expect(record.cost, 120);
      expect(record.provider, 'Gas Safe Ltd');
      expect(record.scheduleId, 's1');
    });
  });

  group('v1 -> v3 in one step', () {
    test('a database that skipped v2 entirely still arrives whole', () async {
      final db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async => db.execute(_v1Schema),
        ),
      );
      addTearDown(db.close);

      await db.insert('assets', {
        'id': 'a',
        'name': 'Old Sofa',
        'price': 1200.0,
        'currency': 'USD',
        'category': 'Living Room',
        'imagePath': 'images/old.jpg',
        'purchaseDate': '2023-04-01T00:00:00.000',
        'isFavorite': 1,
      });

      // Someone who has not opened the app since v1 gets both steps at once.
      await DatabaseHelper.migrate(db, 1, DatabaseHelper.schemaVersion);

      final asset = Asset.fromMap((await db.query('assets')).single);
      expect(asset.room, 'Living Room', reason: 'the v2 step still ran');
      expect(asset.category, kUncategorized);
      expect(asset.photoPaths, ['images/old.jpg']);
      expect(asset.lastReviewedAt, isNull, reason: 'the v3 step ran too');
      expect((await db.query('maintenance_schedules')), isEmpty);
    });
  });

  group('fresh v3 install', () {
    test('createSchema accepts a full asset and reads it back', () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DatabaseHelper.schemaVersion,
          onCreate: DatabaseHelper.createSchema,
        ),
      );
      addTearDown(db.close);

      final asset = Asset(
        id: 'new',
        name: 'Espresso Machine',
        price: 499.99,
        currency: 'EUR',
        room: 'Kitchen',
        category: 'Appliances',
        photoPaths: ['images/a.jpg'],
        receiptPath: 'images/r.jpg',
        serialNumber: 'X1',
        brand: 'Gaggia',
        model: 'Classic',
        notes: 'Bought on sale',
        purchaseDate: DateTime(2025, 6, 1),
        warrantyExpiry: DateTime(2027, 6, 1),
      );
      await db.insert('assets', asset.toMap());

      final reread = Asset.fromMap((await db.query('assets')).single);
      expect(reread.room, 'Kitchen');
      expect(reread.category, 'Appliances');
      expect(reread.brand, 'Gaggia');
      expect(reread.warrantyExpiry, DateTime(2027, 6, 1));
      expect(reread.isFavorite, isFalse);
    });
  });
}
