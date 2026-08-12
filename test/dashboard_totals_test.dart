import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/asset_search.dart';
import 'package:inventa/data/database/database_helper.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/data/repositories/asset_repository.dart';
import 'package:inventa/providers/asset_provider.dart';
import 'package:inventa/providers/settings_provider.dart';
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

    test('what a screen displays is not what the providers report', () async {
      final all = await container.read(allAssetsProvider.future);

      // What the Assets tab shows while a query is typed into it.
      expect(filterAssets(all, 'Television'), hasLength(1));
      expect(filterAssets(all, 'zzzzz'), isEmpty);

      // And what everything else still reports. Filtering is a view over the
      // list rather than a replacement of it -- when searching was a method on
      // the notifier it rewrote this shared state, and the headline total
      // became the value of the televisions, or zero.
      expect(container.read(totalValueProvider), 2200);
      expect(container.read(assetCountProvider), 3);
      expect(container.read(depreciationProvider).totalPaid, 2200);
      expect(container.read(assetListProvider).value, hasLength(3));
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
