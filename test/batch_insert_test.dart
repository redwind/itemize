import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/data/database/database_helper.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/data/repositories/asset_repository.dart';
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

  group('batch insert', () {
    test('stores every item and reads them all back intact', () async {
      final batch = [
        asset(id: 'a', name: 'Boiler'),
        asset(id: 'b', name: 'Mower'),
        asset(id: 'c', name: 'Fridge'),
      ];

      await repository.addAssets(batch);

      final stored = await repository.getAllAssets();
      expect(stored, hasLength(3));
      expect(stored.map((a) => a.id).toSet(), {'a', 'b', 'c'});
      final boiler = stored.firstWhere((a) => a.id == 'a');
      expect(boiler.name, 'Boiler');
      expect(boiler.serialNumber, 'SN-77');
      expect(boiler.photoPaths, ['images/boiler.jpg']);
      expect(boiler.warrantyExpiry, DateTime(2028, 4, 1));
    });

    test('an empty batch is a harmless no-op', () async {
      await repository.addAssets(const []);
      expect(await repository.getAllAssets(), isEmpty);
    });

    test('a duplicate id fails the whole batch, leaving nothing behind',
        () async {
      final batch = [
        asset(id: 'a', name: 'Boiler'),
        asset(id: 'b', name: 'Mower'),
        asset(id: 'a', name: 'Duplicate Boiler'),
      ];

      await expectLater(repository.addAssets(batch), throwsA(anything));

      expect(
        await repository.getAllAssets(),
        isEmpty,
        reason:
            'a non-transactional insert would have left "a" and "b" behind '
            'even though the batch as a whole failed',
      );
    });

    test('a batch of 200 completes', () async {
      final batch = List.generate(
        200,
        (i) => asset(id: 'item-$i', name: 'Item $i'),
      );

      await repository.addAssets(batch);

      expect(await repository.getAllAssets(), hasLength(200));
    });
  });
}
