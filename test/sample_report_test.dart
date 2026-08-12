import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/l10n/app_localizations.dart';
import 'package:inventa/l10n/app_localizations_en.dart';
import 'package:inventa/l10n/app_localizations_fr.dart';
import 'package:inventa/providers/asset_provider.dart';
import 'package:inventa/providers/pro_provider.dart';
import 'package:inventa/providers/settings_provider.dart';
import 'package:inventa/ui/settings/paywall_screen.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_repository.dart';

/// Covers the paywall's "see a sample report" seam: what the sample is made
/// of, and that a free visitor is shown the Pro document without a way to
/// keep it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildDemoSampleAssets', () {
    final items = buildDemoSampleAssets(AppLocalizationsEn());
    final now = DateTime.now();

    test('is never empty', () {
      expect(items, isNotEmpty);
    });

    test('every item has a price, so the totals column is not blank', () {
      for (final item in items) {
        expect(item.price, greaterThan(0));
      }
    });

    test('every purchase date is in the past, so depreciation has something '
        'to work from', () {
      for (final item in items) {
        expect(item.purchaseDate.isBefore(now), isTrue);
      }
    });

    test('every item carries a warranty date, so that column is not blank',
        () {
      for (final item in items) {
        expect(item.warrantyExpiry, isNotNull);
      }
    });

    test('names come from the translated item catalog', () {
      final l10n = AppLocalizationsEn();
      final names = items.map((a) => a.name).toList();
      expect(names, contains(l10n.itemSofa));
      expect(names, contains(l10n.itemTelevision));
      expect(names, contains(l10n.itemWashingMachine));
    });

    test('is localized: French visitors get French item names', () {
      final fr = buildDemoSampleAssets(AppLocalizationsFr());
      final l10nFr = AppLocalizationsFr();
      final names = fr.map((a) => a.name).toList();
      expect(names, contains(l10nFr.itemSofa));
      expect(names, contains(l10nFr.itemTelevision));
      expect(names, contains(l10nFr.itemWashingMachine));
      expect(names, isNot(contains('Sofa')));
    });
  });

  group('sampleReportAssets', () {
    final l10n = AppLocalizationsEn();

    Asset item(String id) => Asset(
      id: id,
      name: 'Thing $id',
      price: 100,
      currency: 'USD',
      room: 'Living Room',
      category: 'Furniture',
      purchaseDate: DateTime(2024, 1, 1),
    );

    test('falls back to the demo items when nothing is recorded yet', () {
      final result = sampleReportAssets(const [], l10n);
      final demo = buildDemoSampleAssets(l10n);
      // Not a full equality check: buildDemoSampleAssets stamps dates from
      // DateTime.now() on each call, so two separately-built lists are never
      // identical down to the microsecond. The ids identify the same items.
      expect(result.map((a) => a.id).toList(), demo.map((a) => a.id).toList());
    });

    test("uses the owner's own items when there are any", () {
      final owned = [item('a'), item('b')];
      final result = sampleReportAssets(owned, l10n);
      expect(result, equals(owned));
    });

    test('caps the count so a large inventory does not slow the sample '
        'down', () {
      final owned = List.generate(50, (i) => item('$i'));
      final result = sampleReportAssets(owned, l10n);
      expect(result.length, kSampleReportItemCap);
      expect(result, equals(owned.take(kSampleReportItemCap)));
    });
  });

  group('the paywall sample button', () {
    late FakeRepository repository;
    late SharedPreferences prefs;

    setUp(() async {
      repository = FakeRepository();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetRepositoryProvider.overrideWithValue(repository),
            sharedPreferencesProvider.overrideWithValue(prefs),
            proProvider.overrideWith(
              (ref) => ProNotifier.withState(
                const ProState(isStoreAvailable: true),
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PaywallScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'opens the Pro report, with sharing and printing switched off',
      (tester) async {
        await pump(tester);

        expect(find.text('See a sample report'), findsOneWidget);
        await tester.ensureVisible(find.text('See a sample report'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('See a sample report'));
        // Not pumpAndSettle: PdfPreview kicks off a platform-channel raster
        // of the generated PDF once the build future resolves, which has no
        // real implementation in a widget test and never completes -- an
        // indeterminate progress spinner keeps scheduling frames forever, so
        // waiting for the tree to go quiet hangs rather than fails. A couple
        // of pumps are enough to run the route transition; nothing under
        // test here depends on the raster finishing.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Sample report'), findsOneWidget);
        expect(find.textContaining('Sharing is switched off'), findsWidgets);

        final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
        expect(preview.allowSharing, isFalse);
        expect(preview.allowPrinting, isFalse);
      },
    );
  });
}
