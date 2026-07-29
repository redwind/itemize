import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/models/service_record.dart';

class DatabaseHelper {
  /// Bumped whenever the schema changes; drives [migrate].
  static const int schemaVersion = 3;

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init() : _injected = null;

  /// Wraps a database that is already open.
  ///
  /// Exists so tests can drive the real queries against an in-memory database.
  /// The cascade on delete and the undo that puts an item's history back are
  /// the two places a bug costs somebody years of records, and neither is
  /// reachable through [createSchema] and [migrate] alone.
  @visibleForTesting
  DatabaseHelper.withDatabase(Database database) : _injected = database;

  final Database? _injected;

  Future<Database> get database async {
    final injected = _injected;
    if (injected != null) return injected;
    if (_database != null) return _database!;
    _database = await _initDB('itemize.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: schemaVersion,
      onCreate: createSchema,
      onUpgrade: migrate,
    );
  }

  /// Builds the current schema from scratch.
  ///
  /// Public, and static, so a test can run it against an in-memory database:
  /// this and [migrate] are the two pieces that touch data somebody cannot get
  /// back if they are wrong.
  static Future<void> createSchema(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE assets (
  id $idType,
  name $textType,
  price $doubleType,
  currency $textType,
  room $textNullable,
  category $textType,
  imagePath $textType,
  photoPaths $textNullable,
  receiptPath $textNullable,
  barcode $textNullable,
  serialNumber $textNullable,
  brand $textNullable,
  model $textNullable,
  notes $textNullable,
  purchaseDate $textType,
  warrantyExpiry $textNullable,
  isFavorite $boolType,
  lastReviewedAt $textNullable
  )
''');

    for (final statement in _v3Tables) {
      await db.execute(statement);
    }
  }

  /// Tables introduced in v3, shared by [createSchema] and [migrate] so a fresh
  /// install and an upgraded one cannot drift apart.
  static const _v3Tables = <String>[
    '''
CREATE TABLE maintenance_schedules (
  id TEXT PRIMARY KEY,
  assetId TEXT NOT NULL,
  title TEXT NOT NULL,
  intervalMonths INTEGER NOT NULL,
  lastDoneAt TEXT,
  requiredForWarranty INTEGER NOT NULL,
  notes TEXT
  )
''',
    '''
CREATE TABLE service_records (
  id TEXT PRIMARY KEY,
  assetId TEXT NOT NULL,
  date TEXT NOT NULL,
  kind TEXT NOT NULL,
  description TEXT,
  cost REAL NOT NULL,
  provider TEXT,
  scheduleId TEXT
  )
''',
    // Both child tables are always read by their asset, and a library of a few
    // hundred items with a history each is enough for the scan to show.
    'CREATE INDEX idx_schedules_asset ON maintenance_schedules (assetId)',
    'CREATE INDEX idx_services_asset ON service_records (assetId)',
  ];

  /// Columns added after v1, all nullable so existing rows stay valid.
  static const _v2Columns = <String>[
    'room TEXT',
    'photoPaths TEXT',
    'receiptPath TEXT',
    'serialNumber TEXT',
    'brand TEXT',
    'model TEXT',
    'notes TEXT',
  ];

  /// Brings a database opened at [oldVersion] up to [schemaVersion].
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      for (final column in _v2Columns) {
        await db.execute('ALTER TABLE assets ADD COLUMN $column');
      }

      // v1 had a single field standing in for both ideas, and the form that
      // filled it was labelled "Category/Room" while offering nothing but room
      // names -- so every value in `category` is in fact a room. Move it across
      // and leave the category blank rather than guess one on the owner's
      // behalf; a wrong category on an insurance record is worse than none.
      await db.rawUpdate('UPDATE assets SET room = category, category = ?', [
        kUncategorized,
      ]);

      // `photoPaths` is left null here on purpose. Asset.fromMap falls back to
      // the v1 `imagePath` when it is absent, so backfilling would only write
      // the same information twice and give the migration something to fail at.
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE assets ADD COLUMN lastReviewedAt TEXT');

      // Left null rather than stamped with today: nobody has reviewed these
      // entries, and claiming they did would suppress the first round of
      // review prompts on exactly the oldest, least trustworthy records.
      for (final statement in _v3Tables) {
        await db.execute(statement);
      }
    }
  }

  Future<int> create(Asset asset) async {
    final db = await database;
    return await db.insert('assets', asset.toMap());
  }

  /// Inserts a whole batch in one transaction, so a Quick Capture room either
  /// lands entirely or not at all instead of leaving half the photographs
  /// saved after one bad row.
  ///
  /// Same conflict behaviour as [create] (throws on a duplicate id) rather
  /// than [upsert]'s replace: a batch insert is new items being added, not a
  /// restore replaying something that may already be there.
  Future<void> createAll(List<Asset> assets) async {
    if (assets.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final asset in assets) {
        await txn.insert('assets', asset.toMap());
      }
    });
  }

  /// Writes an asset whether or not it is already there.
  ///
  /// Used by the undo, where a plain insert throws on the second attempt. That
  /// exception surfaced as an error state on the whole asset list — the user's
  /// entire inventory replaced by "Error:" because they tapped Undo twice.
  Future<void> upsert(Asset asset) async {
    final db = await database;
    await db.insert(
      'assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Asset> readAsset(String id) async {
    final db = await database;

    final maps = await db.query(
      'assets',
      columns: null, // Select all
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Asset.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Asset>> readAllAssets() async {
    final db = await database;
    final result = await db.query('assets');
    return result.map((json) => Asset.fromMap(json)).toList();
  }

  /// Total number of stored assets.
  ///
  /// Counts in SQL rather than off the in-memory list, because that list is
  /// narrowed by search and would under-report against the free-tier limit.
  Future<int> countAssets() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM assets');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(Asset asset) async {
    final db = await database;
    return db.update(
      'assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  /// Deletes an asset along with its schedules and its history.
  ///
  /// Done in one transaction and by hand rather than with foreign keys: sqflite
  /// leaves `PRAGMA foreign_keys` off by default and it has to be re-enabled on
  /// every connection, so relying on cascade would quietly leave orphaned rows
  /// on any connection where somebody forgot.
  Future<int> delete(String id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete(
        'maintenance_schedules',
        where: 'assetId = ?',
        whereArgs: [id],
      );
      await txn.delete('service_records', where: 'assetId = ?', whereArgs: [id]);
      return txn.delete('assets', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- Maintenance schedules ----------------------------------------------

  Future<List<MaintenanceSchedule>> readSchedules(String assetId) async {
    final db = await database;
    final rows = await db.query(
      'maintenance_schedules',
      where: 'assetId = ?',
      whereArgs: [assetId],
      orderBy: 'title',
    );
    return rows.map(MaintenanceSchedule.fromMap).toList();
  }

  Future<List<MaintenanceSchedule>> readAllSchedules() async {
    final db = await database;
    final rows = await db.query('maintenance_schedules');
    return rows.map(MaintenanceSchedule.fromMap).toList();
  }

  Future<void> upsertSchedule(MaintenanceSchedule schedule) async {
    final db = await database;
    await db.insert(
      'maintenance_schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSchedule(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'maintenance_schedules',
        where: 'id = ?',
        whereArgs: [id],
      );
      // The history stays; only its link to a schedule that no longer exists
      // goes. Deleting a schedule must not erase the record of work done.
      await txn.update(
        'service_records',
        {'scheduleId': null},
        where: 'scheduleId = ?',
        whereArgs: [id],
      );
    });
  }

  // --- Service history -----------------------------------------------------

  Future<List<ServiceRecord>> readServiceRecords(String assetId) async {
    final db = await database;
    final rows = await db.query(
      'service_records',
      where: 'assetId = ?',
      whereArgs: [assetId],
      orderBy: 'date DESC',
    );
    return rows.map(ServiceRecord.fromMap).toList();
  }

  Future<List<ServiceRecord>> readAllServiceRecords() async {
    final db = await database;
    final rows = await db.query('service_records', orderBy: 'date DESC');
    return rows.map(ServiceRecord.fromMap).toList();
  }

  Future<void> upsertServiceRecord(ServiceRecord record) async {
    final db = await database;
    await db.insert(
      'service_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteServiceRecord(String id) async {
    final db = await database;
    await db.delete('service_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
