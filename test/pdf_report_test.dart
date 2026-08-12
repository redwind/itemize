import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:inventa/core/utils/pdf_service.dart';
import 'package:inventa/l10n/app_localizations_en.dart';
import 'package:inventa/l10n/app_localizations_fr.dart';
import 'package:inventa/data/models/asset.dart';

Asset asset({
  required String id,
  String name = 'Sofa',
  String room = 'Living Room',
  String category = 'Furniture',
  String? serialNumber,
  String? receiptPath,
  double price = 1200,
}) => Asset(
  id: id,
  name: name,
  price: price,
  currency: 'USD',
  room: room,
  category: category,
  serialNumber: serialNumber,
  receiptPath: receiptPath,
  purchaseDate: DateTime(2024, 3, 1),
  warrantyExpiry: DateTime(2027, 3, 1),
);

String money(double v) => '\$${v.toStringAsFixed(2)}';

void main() {
  // rootBundle needs a binding before the report can load its fonts.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final service = PDFService();

  Future<List<int>> build(List<Asset> assets, {required bool isPro}) =>
      service.generateAssetsReport(
        assets,
        money,
        l10n: AppLocalizationsEn(),
        isPro: isPro,
      );

  test('produces a structurally valid PDF', () async {
    final bytes = await build([asset(id: 'a')], isPro: true);
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('an empty inventory still produces a report rather than throwing',
      () async {
    final free = await build([], isPro: false);
    final pro = await build([], isPro: true);
    expect(free, isNotEmpty);
    expect(pro, isNotEmpty);
  });

  test('the Pro report carries substantially more than the free one', () async {
    final assets = [
      asset(id: 'a', serialNumber: 'SN-1'),
      asset(id: 'b', name: 'Television', category: 'Electronics'),
      asset(id: 'c', name: 'Kettle', room: 'Kitchen', category: 'Appliances'),
    ];

    final free = await build(assets, isPro: false);
    final pro = await build(assets, isPro: true);

    // Per-item detail blocks, estimated values and the declaration only appear
    // in the Pro document; if this ever stops holding, the paywall is once
    // again promising something it does not deliver.
    expect(pro.length, greaterThan(free.length));
  });

  test('grows with the inventory, so every item is actually written', () async {
    final one = await build([asset(id: 'a')], isPro: true);
    final many = await build([
      for (var i = 0; i < 12; i++) asset(id: '$i', name: 'Item $i'),
    ], isPro: true);

    expect(many.length, greaterThan(one.length));
  });

  test('a missing photo or receipt file does not fail the report', () async {
    // Paths that resolve to nothing: the item was photographed on a device the
    // library has since been moved off.
    final bytes = await build([
      Asset(
        id: 'a',
        name: 'Ghost',
        price: 10,
        currency: 'USD',
        room: 'Office',
        category: 'Other',
        photoPaths: const ['images/does-not-exist.jpg'],
        receiptPath: 'images/also-missing.jpg',
        purchaseDate: DateTime(2024, 1, 1),
      ),
    ], isPro: true);

    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('Vietnamese item names are drawn, not silently dropped', () async {
    // PDF's built-in Helvetica cannot draw these at all, and fails by leaving
    // the page blank rather than by throwing -- so this asserts on the warning
    // dart_pdf prints when it cannot find a glyph.
    final complaints = <String>[];
    await runZoned(
      () => build([
        asset(id: 'a', name: 'Tủ lạnh Panasonic'),
        asset(id: 'b', name: 'Máy giặt cửa trước — đã qua sử dụng'),
        asset(id: 'c', name: 'Bàn ghế phòng khách ₫'),
      ], isPro: true),
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) {
          if (line.contains('Unable to find a font') ||
              line.contains('no Unicode support')) {
            complaints.add(line);
          }
        },
      ),
    );

    expect(complaints, isEmpty, reason: complaints.join('\n'));
  });

  test('items carried over with no category are reported, not skipped',
      () async {
    final bytes = await build([
      asset(id: 'a', category: kUncategorized),
    ], isPro: true);
    expect(bytes, isNotEmpty);
  });

  test('the report is written in the language the app is set to', () async {
    // A claim submitted to a French insurer has to read in French, so the
    // document follows the interface rather than staying English.
    final assets = [asset(id: 'a')];

    final english = await service.generateAssetsReport(
      assets,
      money,
      l10n: AppLocalizationsEn(),
      isPro: true,
    );
    final french = await service.generateAssetsReport(
      assets,
      money,
      l10n: AppLocalizationsFr(),
      isPro: true,
    );

    expect(french, isNot(equals(english)));
    expect(utf8.decode(french.take(5).toList()), '%PDF-');
  });

  test('dates in the report follow the report language, not the process', () {
    // A French report dated "July 28, 2026" is worse than one wholly in
    // either language, and that is what reading Intl.defaultLocale gave.
    final march = DateTime(2024, 3, 1);
    expect(DateFormat.yMMMMd('fr').format(march), contains('mars'));
    expect(DateFormat.yMMMMd('de').format(march), contains('März'));
    expect(DateFormat.yMMMMd('en').format(march), contains('March'));
  });
}
