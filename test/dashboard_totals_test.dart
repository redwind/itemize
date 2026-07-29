import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/data/database/database_helper.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/repositories/asset_repository.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The dashboard's figures against a search typed on another tab.
///
/// [AssetListNotifier.search] replaces the list state with a narrowed one, and
/// the tabs are kept alive by an IndexedStack, so anything summarising "what I
/// own in total" off that provider silently answered for the query instead.
/// Typing "TV" on the Assets tab rewrote the headline total to the value of the
/// televisions, which is the one number in the app nobody may be shown wrong.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late AssetRepository repository;
  late ProviderContainer container;

  Asset item(String id, String name, double price, String category) => Asset(
    id: id,
    name: name,
    price: price,
    currency: 'USD',
    room: 'Living Room',
    category: category,
    purchaseDate: DateTime(2026, 1, 1),
  );

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseHelper.schemaVersion,
        onCreate: DatabaseHelper.createSchema,
      ),
    );
    repository = AssetRepository(dbHelper: DatabaseHelper.withDatabase(db));

    await repository.addAsset(item('1', 'Television', 1200, 'Electronics'));
    await repository.addAsset(item('2', 'Sofa', 800, 'Furniture'));
    await repository.addAsset(item('3', 'Rug', 200, 'Furniture'));

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        assetRepositoryProvider.overrideWithValue(repository),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    // The list loads itself on creation; wait for it before asserting.
    await container.read(assetListProvider.notifier).loadAssets();
    await container.read(allAssetsProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('the dashboard summarises everything owned', () {
    test('before any search, the totals are the whole inventory', () {
      expect(container.read(totalValueProvider), 2200);
      expect(container.read(assetCountProvider), 3);
      expect(container.read(depreciationProvider).totalPaid, 2200);
    });

    test('a search on the Assets tab does not move the total value', () async {
      await container.read(assetListProvider.notifier).search('Television');

      // The Assets tab is showing one item, as it should.
      expect(container.read(assetListProvider).value, hasLength(1));

      await container.read(allAssetsProvider.future);
      expect(container.read(totalValueProvider), 2200);
      expect(container.read(assetCountProvider), 3);
      expect(container.read(depreciationProvider).totalPaid, 2200);
    });

    test('a search that matches nothing does not empty the dashboard',
        () async {
      await container.read(assetListProvider.notifier).search('zzzzz');

      expect(container.read(assetListProvider).value, isEmpty);

      await container.read(allAssetsProvider.future);
      expect(container.read(totalValueProvider), 2200);
      expect(container.read(assetCountProvider), 3);
    });

    test('adding an item still moves the total', () async {
      await container
          .read(assetListProvider.notifier)
          .addAsset(item('4', 'Lamp', 100, 'Furniture'));

      await container.read(allAssetsProvider.future);
      expect(container.read(totalValueProvider), 2300);
      expect(container.read(assetCountProvider), 4);
    });
  });
}
