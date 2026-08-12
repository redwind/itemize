import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/free_tier.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/l10n/app_localizations.dart';
import 'package:inventa/providers/asset_provider.dart';
import 'package:inventa/providers/pro_provider.dart';
import 'package:inventa/providers/settings_provider.dart';
import 'package:inventa/ui/add_item/add_item_screen.dart';
import 'package:inventa/ui/settings/paywall_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'support/fake_repository.dart';

/// The paths where money and the owner's data meet.
///
/// The repo had no widget tests at all, and every one of the defects that
/// reached this branch lived exactly here: in what a screen does, not in what
/// a function returns. These four cover the ones that cost either the owner's
/// data or the sale.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRepository repository;
  late SharedPreferences prefs;

  Asset item(String id) => Asset(
    id: id,
    name: 'Thing $id',
    price: 100,
    currency: 'EUR',
    room: 'Living Room',
    category: 'Furniture',
    purchaseDate: DateTime(2026, 1, 1),
  );

  setUp(() async {
    repository = FakeRepository();
    SharedPreferences.setMockInitialValues({'currencyCode': 'EUR'});
    prefs = await SharedPreferences.getInstance();
  });

  /// Pumps [child] with everything the real app gives a screen: the three
  /// languages, the database, the settings, and a stated Pro status.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    ProState pro = const ProState(isStoreAvailable: true),
    String language = 'en',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesProvider.overrideWithValue(prefs),
          proProvider.overrideWith((ref) => ProNotifier.withState(pro)),
        ],
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: kSupportedLanguages.map(Locale.new),
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('adding an item', () {
    testWidgets('a comma decimal is stored as the number that was typed',
        (tester) async {
      await pump(tester, const AddItemScreen(), language: 'de');

      await tester.enterText(find.byType(TextFormField).first, 'Waschmaschine');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preis'),
        '1299,99',
      );
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      final stored = repository.assets;
      expect(stored, hasLength(1));
      // The bug this locks down stored 0 here, silently, past validation.
      expect(stored.single.price, 1299.99);
    });

    testWidgets('an unreadable amount is refused rather than saved as zero',
        (tester) async {
      await pump(tester, const AddItemScreen());

      await tester.enterText(find.byType(TextFormField).first, 'Sofa');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        'about a hundred',
      );
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid amount'), findsOneWidget);
      expect(repository.assets, isEmpty);
    });
  });

  group('the free ceiling', () {
    testWidgets('a free owner at the limit is stopped and offered the way past',
        (tester) async {
      await repository.addAssets([
        for (var i = 0; i < kFreeItemLimit; i++) item('$i'),
      ]);

      await pump(tester, const AddItemScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'One too many');
      await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '10');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('The free version holds $kFreeItemLimit items'),
          findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsOneWidget);

      // Nothing was saved, and nothing the owner typed was taken away.
      expect(repository.assets, hasLength(kFreeItemLimit));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('One too many'), findsOneWidget);
    });

    testWidgets('a Pro owner at the same count is not stopped', (tester) async {
      await repository.addAssets([
        for (var i = 0; i < kFreeItemLimit; i++) item('$i'),
      ]);

      await pump(
        tester,
        const AddItemScreen(),
        pro: const ProState(isPro: true, isStoreAvailable: true),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Number 41');
      await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '10');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(repository.assets, hasLength(kFreeItemLimit + 1));
    });

    testWidgets('editing is never blocked, even over the limit',
        (tester) async {
      // Over the ceiling, which a restored backup alone can do.
      final existing = item(const Uuid().v4());
      await repository.addAssets([
        existing,
        for (var i = 0; i < kFreeItemLimit + 5; i++) item('$i'),
      ]);

      await pump(tester, AddItemScreen(existing: existing));

      await tester.enterText(find.byType(TextFormField).first, 'Renamed');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.textContaining('free version holds'), findsNothing);
      expect(repository.assets.firstWhere((a) => a.id == existing.id).name,
          'Renamed');
    });
  });

  group('the paywall', () {
    testWidgets('a dead store offers a retry rather than a dead button',
        (tester) async {
      await pump(
        tester,
        const PaywallScreen(),
        pro: const ProState(isStoreAvailable: false),
      );

      expect(find.text('Try again'), findsOneWidget);
      final buy = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Upgrade'),
      );
      expect(buy.onPressed, isNull, reason: 'nothing to buy from a dead store');
    });

    testWidgets('unlimited items is the first thing it sells', (tester) async {
      await pump(tester, const PaywallScreen());

      expect(find.text('Unlimited Items'), findsOneWidget);
      // Above the report, because the ceiling is what the owner just hit.
      final unlimited = tester.getTopLeft(find.text('Unlimited Items')).dy;
      final report = tester.getTopLeft(find.text('Insurance Report')).dy;
      expect(unlimited, lessThan(report));
    });

    testWidgets('it says the same things in German', (tester) async {
      await pump(tester, const PaywallScreen(), language: 'de');

      expect(find.text('Unbegrenzte Einträge'), findsOneWidget);
      expect(find.textContaining('wiederherstellen'), findsWidgets);
    });
  });
}
