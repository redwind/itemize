import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/core/utils/asset_search.dart';
import 'package:itemize/data/models/asset.dart';

/// Which fields a query is allowed to match.
///
/// Needs no database: matching is a pure function of the item and the query,
/// which is the whole reason it was moved out of the repository. Searching used
/// to be a round trip to storage whose result was written back into the shared
/// asset list, so a query typed on one screen narrowed every other one.
Asset asset({
  String id = 'a',
  String name = 'Boiler',
  String room = 'Garage',
  String category = 'Appliances',
  String? barcode,
  String? serialNumber,
  String? brand,
  String? model,
}) => Asset(
  id: id,
  name: name,
  price: 2000,
  currency: 'USD',
  room: room,
  category: category,
  photoPaths: const ['images/boiler.jpg'],
  barcode: barcode,
  serialNumber: serialNumber,
  brand: brand,
  model: model,
  purchaseDate: DateTime(2023, 4, 1),
  warrantyExpiry: DateTime(2028, 4, 1),
);

void main() {
  List<String> idsMatching(List<Asset> assets, String query) =>
      filterAssets(assets, query).map((a) => a.id).toList();

  group('searching by the fields that identify a specific unit', () {
    test('a barcode finds the item it was scanned onto', () {
      final assets = [
        asset(id: 'a', barcode: '012345678905'),
        asset(id: 'b', name: 'Mower'),
      ];

      expect(idsMatching(assets, '012345678905'), ['a']);
    });

    test('serial number still works', () {
      final assets = [
        asset(id: 'a', serialNumber: 'SN-77'),
        asset(id: 'b', name: 'Mower'),
      ];

      expect(idsMatching(assets, 'SN-77'), ['a']);
    });

    test('brand still works', () {
      final assets = [
        asset(id: 'a', brand: 'Worcester'),
        asset(id: 'b', name: 'Mower'),
      ];

      expect(idsMatching(assets, 'Worcester'), ['a']);
    });

    test('model still works', () {
      final assets = [
        asset(id: 'a', model: 'CDi'),
        asset(id: 'b', name: 'Mower'),
      ];

      expect(idsMatching(assets, 'CDi'), ['a']);
    });

    test('name, room and category all match', () {
      final assets = [
        asset(id: 'a', name: 'Boiler', room: 'Garage'),
        asset(id: 'b', name: 'Sofa', room: 'Living Room'),
      ];

      expect(idsMatching(assets, 'Boiler'), ['a']);
      expect(idsMatching(assets, 'Living'), ['b']);
      expect(idsMatching(assets, 'Appliances'), ['a', 'b']);
    });

    test('search is case-insensitive and matches partially', () {
      final assets = [asset(id: 'a', barcode: 'ABC-999-XYZ')];

      expect(idsMatching(assets, 'abc-999'), ['a']);
    });
  });

  group('filtering leaves the list alone when there is nothing to filter by', () {
    test('an empty query returns everything, and the same list object', () {
      final assets = [asset(id: 'a'), asset(id: 'b', name: 'Mower')];

      expect(filterAssets(assets, ''), same(assets));
      expect(filterAssets(assets, '   '), same(assets));
    });

    test('a query matching nothing returns nothing, not everything', () {
      final assets = [asset(id: 'a'), asset(id: 'b', name: 'Mower')];

      expect(filterAssets(assets, 'zzzzz'), isEmpty);
    });

    test('order is preserved', () {
      final assets = [
        asset(id: 'a', name: 'Boiler'),
        asset(id: 'b', name: 'Mower'),
        asset(id: 'c', name: 'Boiler spare'),
      ];

      expect(idsMatching(assets, 'boiler'), ['a', 'c']);
    });
  });
}
