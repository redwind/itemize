// Temporary App Store screenshot harness. Runs the real InventaApp and walks it
// through the screens worth capturing, printing a SHOT marker whenever a screen
// has settled so an external script can grab the simulator frame.
//
// Navigation invokes the widgets' own callbacks rather than synthesising pointer
// events -- injected PointerDown/Up never reached the gesture arena here, so the
// walk silently stayed on the first screen. Delete when the screenshots are done.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventa/core/catalog/asset_catalog.dart';
import 'package:inventa/core/utils/catalog_image.dart';
import 'package:inventa/core/utils/image_storage.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/data/models/maintenance_schedule.dart';
import 'package:inventa/data/repositories/asset_repository.dart';
import 'package:inventa/main.dart';
import 'package:inventa/providers/settings_provider.dart';
import 'package:inventa/ui/add_item/warranty_prompt_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _settle = Duration(milliseconds: 1500);
const _dwell = Duration(seconds: 5);

/// Pinned rather than inherited from the simulator; see [main]. Read here as
/// well as there so the currency stored on each seeded item is the same one
/// the app is set to display, instead of the two disagreeing whenever a run
/// overrides it.
const _shotCurrency = String.fromEnvironment(
  'SHOT_CURRENCY',
  defaultValue: 'USD',
);

void _walk(Element element, void Function(Element) visit) {
  visit(element);
  element.visitChildren((child) => _walk(child, visit));
}

Element? _root() => WidgetsBinding.instance.rootElement;

T? _findWidget<T extends Widget>() {
  T? found;
  final root = _root();
  if (root == null) return null;
  _walk(root, (element) {
    final widget = element.widget;
    if (found == null && widget is T) found = widget;
  });
  return found;
}

Element? _elementOfText(String label) {
  Element? found;
  final root = _root();
  if (root == null) return null;
  _walk(root, (element) {
    final widget = element.widget;
    if (found == null && widget is Text && widget.data == label) {
      found = element;
    }
  });
  return found;
}

/// Fires the nearest enclosing tap handler above [start].
bool _activateAncestor(Element start) {
  var fired = false;
  start.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is GestureDetector && widget.onTap != null) {
      widget.onTap!();
      fired = true;
      return false;
    }
    if (widget is InkWell && widget.onTap != null) {
      widget.onTap!();
      fired = true;
      return false;
    }
    return true;
  });
  return fired;
}

NavigatorState? _navigator() {
  NavigatorState? state;
  final root = _root();
  if (root == null) return null;
  _walk(root, (element) {
    if (state == null &&
        element is StatefulElement &&
        element.state is NavigatorState) {
      state = element.state as NavigatorState;
    }
  });
  return state;
}

Future<void> _shot(String name) async {
  await Future<void>.delayed(_settle);
  debugPrint('SHOT $name');
  await Future<void>.delayed(_dwell);
}

Future<void> _selectTab(int index, String name) async {
  final bar = _findWidget<BottomNavigationBar>();
  if (bar?.onTap == null) {
    debugPrint('SHOT_WARN no BottomNavigationBar for $name');
    return;
  }
  bar!.onTap!(index);
  await Future<void>.delayed(_settle);
}

Future<void> _openByText(String label) async {
  // Lists arrive asynchronously from sqflite, so poll rather than assuming the
  // target has already been built after a fixed delay.
  Element? element;
  for (var i = 0; i < 40 && element == null; i++) {
    element = _elementOfText(label);
    if (element == null) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  if (element == null) {
    debugPrint('SHOT_WARN could not find "$label"');
    return;
  }
  if (!_activateAncestor(element)) {
    debugPrint('SHOT_WARN no tap handler above "$label"');
    return;
  }
  await Future<void>.delayed(_settle);
}

/// Fires an [IconButton] found by its tooltip, for the actions -- edit,
/// delete -- that carry no [Text] of their own for [_openByText] to find.
Future<void> _tapIconByTooltip(String tooltip) async {
  VoidCallback? onPressed;
  for (var i = 0; i < 40 && onPressed == null; i++) {
    final root = _root();
    if (root != null) {
      _walk(root, (element) {
        final widget = element.widget;
        if (onPressed == null &&
            widget is IconButton &&
            widget.tooltip == tooltip) {
          onPressed = widget.onPressed;
        }
      });
    }
    if (onPressed == null) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  if (onPressed == null) {
    debugPrint('SHOT_WARN no IconButton with tooltip "$tooltip"');
    return;
  }
  onPressed!();
  await Future<void>.delayed(_settle);
}

/// Scrolls the item page far enough down that its content, not its cover
/// photo, is what the picture is of.
///
/// The detail screen sizes its `SliverAppBar` as `screenWidth * 0.9`, so the
/// wider the device the taller the cover -- 929pt of it on a 13-inch iPad's
/// 1376pt screen, which leaves the estimated value, the care link, the dates
/// and the serial number all below the fold. Rather than pick an offset per
/// device, this caps how much of the screen the cover is allowed to keep:
/// past that, it scrolls the difference away. On a phone the cover is already
/// inside the cap, so the shot there barely moves.
///
/// Takes the last [Scrollable] in tree order, not the first: routes below the
/// top one stay in the tree, and the tab list underneath this page would
/// otherwise be the one that scrolled.
Future<void> _scrollCoverUp({double keepFraction = 0.35}) async {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final width = view.physicalSize.width / view.devicePixelRatio;
  final height = view.physicalSize.height / view.devicePixelRatio;
  final offset = (width * 0.9) - (height * keepFraction);
  if (offset <= 0) return;

  ScrollableState? scrollable;
  final root = _root();
  if (root == null) return;
  _walk(root, (element) {
    if (element is StatefulElement && element.state is ScrollableState) {
      scrollable = element.state as ScrollableState;
    }
  });

  if (scrollable == null) {
    debugPrint('SHOT_WARN no Scrollable to scroll');
    return;
  }

  final position = scrollable!.position;
  await position.animateTo(
    offset.clamp(0.0, position.maxScrollExtent),
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeOut,
  );
  await Future<void>.delayed(_settle);
}

Future<void> _back() async {
  final navigator = _navigator();
  if (navigator != null && navigator.canPop()) {
    navigator.pop();
    await Future<void>.delayed(_settle);
  }
}

/// Guarantees the dashboard's "needs attention" section and the Care tab's
/// default "Ending soon" filter have something in them, independent of
/// whatever an external tool did or didn't seed. Fixed ids make this
/// idempotent across reruns against the same simulator instead of piling up
/// duplicate rows every launch.
///
/// Renders real catalog artwork rather than leaving these photo-less: a card
/// with a grey placeholder icon is not what the store listing is selling.
///
/// Eleven items across six rooms rather than the two this started with. Two
/// filled a phone screen and left the bottom half of a 13-inch iPad shot as
/// empty background, and a room chart drawn from two rooms is not a chart.
/// The spread is deliberate: every warranty state the app can show -- ending
/// soon, covered, lapsed, none recorded -- appears at least once, because the
/// listing is selling the app's ability to tell them apart.
///
/// Order matters. The Care tab's lists are what the walk taps into, and only
/// built (findable) rows can be tapped, so the two items it opens by name are
/// kept at the top of their list: the fridge expires soonest of anything
/// covered, and the boiler's service is the latest of the overdue jobs.
Future<void> _seedAttentionDemo() async {
  final repository = AssetRepository();
  final now = DateTime.now();

  Future<void> upsert(Asset asset) async {
    final existing = await repository.findAsset(asset.id);
    if (existing == null) {
      await repository.addAsset(asset);
    } else {
      await repository.updateAsset(asset);
    }
  }

  CatalogItem catalogItem(String labelKey) =>
      assetCatalog.firstWhere((item) => item.labelKey == labelKey);

  /// [art] is a catalog `labelKey`, whose own category picks the background
  /// tint -- so varying it is what keeps the list from being eleven cards of
  /// the same colour. [warrantyInDays] of null records no warranty date.
  Future<void> add({
    required String id,
    required String name,
    required String art,
    required String room,
    required String category,
    required double price,
    required int boughtDaysAgo,
    int? warrantyInDays,
    String? brand,
    String? model,
    String? serialNumber,
    String? notes,
  }) async => upsert(
    Asset(
      id: id,
      name: name,
      price: price,
      currency: _shotCurrency,
      room: room,
      category: category,
      photoPaths: [await CatalogImage.render(catalogItem(art))],
      brand: brand,
      model: model,
      serialNumber: serialNumber,
      notes: notes,
      purchaseDate: now.subtract(Duration(days: boughtDaysAgo)),
      warrantyExpiry: warrantyInDays == null
          ? null
          : now.add(Duration(days: warrantyInDays)),
      lastReviewedAt: now,
    ),
  );

  // Ending soon: inside WarrantyStatus.expiringSoonDays (90) but not yet
  // lapsed, so it lands in the dashboard's "ending soon" row and heads the
  // Care tab's default filter. The walk opens this one, so it is the one
  // carrying the identifying fields an insurer asks for by name -- the item
  // page is the screenshot that has to look worth paying for.
  await add(
    id: 'shot-demo-fridge',
    name: 'Kitchen Fridge-Freezer',
    art: 'refrigerator',
    room: 'Kitchen',
    category: 'Appliances',
    price: 899,
    boughtDaysAgo: 700,
    warrantyInDays: 30,
    brand: 'Bosch',
    model: 'KGN39VLEB',
    serialNumber: 'FD9402-118374',
    notes: 'Extended cover bought with it; receipt filed with the policy.',
  );

  // A live warranty plus a lapsed, warranty-required job: the one row the
  // dashboard styles as an actual warning rather than a nudge.
  await add(
    id: 'shot-demo-boiler',
    name: 'Gas Boiler',
    art: 'dishwasher',
    room: 'Basement',
    category: 'Appliances',
    price: 2100,
    boughtDaysAgo: 400,
    warrantyInDays: 200,
    brand: 'Vaillant',
    model: 'ecoTEC plus 832',
  );

  await add(
    id: 'shot-demo-laptop',
    name: 'MacBook Pro 16"',
    art: 'laptop',
    room: 'Office',
    category: 'Electronics',
    price: 3199,
    boughtDaysAgo: 300,
    warrantyInDays: 65,
    brand: 'Apple',
    serialNumber: 'C02XK1TQJGH7',
  );

  await add(
    id: 'shot-demo-tv',
    name: 'Living Room TV',
    art: 'television',
    room: 'Living Room',
    category: 'Electronics',
    price: 1499,
    boughtDaysAgo: 420,
    warrantyInDays: 410,
    brand: 'Samsung',
    model: 'QN65Q80D',
  );

  await add(
    id: 'shot-demo-espresso',
    name: 'Espresso Machine',
    art: 'coffeeMaker',
    room: 'Kitchen',
    category: 'Appliances',
    price: 1290,
    boughtDaysAgo: 200,
    warrantyInDays: 530,
    brand: 'Sage',
  );

  await add(
    id: 'shot-demo-bike',
    name: 'E-Bike',
    art: 'bicycle',
    room: 'Garage',
    category: 'Sports & Outdoors',
    price: 2890,
    boughtDaysAgo: 500,
    warrantyInDays: 55,
    brand: 'Cube',
    serialNumber: 'WBK-4471-2290',
  );

  await add(
    id: 'shot-demo-camera',
    name: 'Mirrorless Camera',
    art: 'camera',
    room: 'Office',
    category: 'Electronics',
    price: 1799,
    boughtDaysAgo: 260,
    warrantyInDays: 80,
    brand: 'Fujifilm',
    model: 'X-T5',
  );

  // Lapsed cover, so the Care tab's "Expired" filter is not an empty tab.
  await add(
    id: 'shot-demo-washer',
    name: 'Washing Machine',
    art: 'washingMachine',
    room: 'Bathroom',
    category: 'Appliances',
    price: 749,
    boughtDaysAgo: 1100,
    warrantyInDays: -40,
    brand: 'Miele',
  );

  await add(
    id: 'shot-demo-mower',
    name: 'Lawn Mower',
    art: 'lawnMower',
    room: 'Garden & Balcony',
    category: 'Tools & Equipment',
    price: 429,
    boughtDaysAgo: 800,
    warrantyInDays: -70,
  );

  // No warranty date recorded -- the state the app has to hold without
  // pretending it is either covered or lapsed.
  await add(
    id: 'shot-demo-sofa',
    name: 'Three-Seat Sofa',
    art: 'sofa',
    room: 'Living Room',
    category: 'Furniture',
    price: 2450,
    boughtDaysAgo: 900,
  );

  await add(
    id: 'shot-demo-watch',
    name: 'Wristwatch',
    art: 'watch',
    room: 'Bedroom',
    category: 'Jewelry & Watches',
    price: 1850,
    boughtDaysAgo: 1500,
    brand: 'Omega',
    serialNumber: '81729947',
  );

  // Overdue, and cover depends on it: this is the warning the Care tab leads
  // with and the screen the walk opens from it.
  await repository.saveSchedule(
    MaintenanceSchedule(
      id: 'shot-demo-boiler-service',
      assetId: 'shot-demo-boiler',
      title: 'Annual Boiler Service',
      intervalMonths: 12,
      lastDoneAt: now.subtract(const Duration(days: 400)),
      requiredForWarranty: true,
    ),
  );

  // Overdue but harmless to the warranty, so the two are visibly not the same
  // kind of row. Less late than the boiler's, which keeps that one on top.
  await repository.saveSchedule(
    MaintenanceSchedule(
      id: 'shot-demo-mower-blade',
      assetId: 'shot-demo-mower',
      title: 'Sharpen Blades',
      intervalMonths: 12,
      lastDoneAt: now.subtract(const Duration(days: 380)),
    ),
  );

  // Kept up to date, so "due in" has something to say next to the overdue
  // pair.
  await repository.saveSchedule(
    MaintenanceSchedule(
      id: 'shot-demo-espresso-descale',
      assetId: 'shot-demo-espresso',
      title: 'Descale',
      intervalMonths: 3,
      lastDoneAt: now.subtract(const Duration(days: 30)),
    ),
  );

  await repository.saveSchedule(
    MaintenanceSchedule(
      id: 'shot-demo-bike-service',
      assetId: 'shot-demo-bike',
      title: 'Brake & Gear Service',
      intervalMonths: 12,
      lastDoneAt: now.subtract(const Duration(days: 330)),
      requiredForWarranty: true,
    ),
  );
}

Future<void> _run() async {
  // Let the first frame render and the asset list load from sqflite.
  await Future<void>.delayed(const Duration(seconds: 4));

  await _shot('01-dashboard');

  // The Care tab is the one the app is now sold on -- warranty and
  // maintenance guardian rather than a plain inventory -- so it leads the
  // rest of the walk. Its default filter is "Ending soon", which the seed
  // above guarantees is never empty.
  await _selectTab(2, 'care');
  await _shot('02-care');

  await _openByText('Kitchen Fridge-Freezer');
  await _scrollCoverUp();
  await _shot('03-item-detail');

  await _tapIconByTooltip('Edit');
  await _shot('04-edit-item');
  await _back(); // -> item detail
  await _back(); // -> Care tab

  // The maintenance section above the warranty list, and the item-level
  // screen it opens onto: scheduled jobs, history and the ownership-cost
  // verdict.
  await _openByText('Annual Boiler Service');
  await _shot('05-care-job');
  await _back(); // -> Care tab

  await _selectTab(1, 'assets');
  await _shot('06-assets');

  // Add Item, via the FAB's "Add One Item" choice, through to a stock photo
  // applied -- the stock library and its catalog artwork are the only part of
  // this flow reachable without a real camera, which the simulator has none
  // of.
  final fab = _findWidget<FloatingActionButton>();
  if (fab?.onPressed != null) {
    fab!.onPressed!();
    await Future<void>.delayed(_settle);

    await _openByText('Add One Item');
    await _shot('07-add-item');

    await _openByText('Add Photo');
    await _shot('08-photo-options');

    await _openByText('Pick a Stock Image');
    await Future<void>.delayed(_settle);
    await _shot('09-stock-library');

    await _openByText('Armchair');
    await Future<void>.delayed(_settle);
    await _shot('10-stock-image-applied');

    await _back(); // discard the draft, back to the Assets tab
  } else {
    debugPrint('SHOT_WARN no FloatingActionButton');
  }

  // Quick Capture's own landing screen. Actually shooting a batch needs a
  // real camera the simulator does not have, so this stops at the screen
  // itself rather than faking photographs.
  final fab2 = _findWidget<FloatingActionButton>();
  if (fab2?.onPressed != null) {
    fab2!.onPressed!();
    await Future<void>.delayed(_settle);
    await _openByText('Quick Capture a Room');
    await _shot('11-quick-capture');
    await _back();
  } else {
    debugPrint('SHOT_WARN no FloatingActionButton');
  }

  // The prompt Quick Capture shows right after a batch save, reached
  // directly for the same reason: nothing in this harness can drive the
  // camera far enough to produce a real batch to prompt about.
  final navigator = _navigator();
  if (navigator != null) {
    final assets = await AssetRepository().getAllAssets();
    final sample = assets.take(3).toList();
    if (sample.isNotEmpty) {
      unawaited(
        navigator.push(
          MaterialPageRoute(
            builder: (_) => WarrantyPromptScreen(assets: sample),
          ),
        ),
      );
      await _shot('12-warranty-prompt');
      await _back();
    } else {
      debugPrint('SHOT_WARN no assets to show the warranty prompt with');
    }
  }

  await _selectTab(3, 'settings');
  await _shot('13-settings');

  await _openByText('Upgrade to Pro');
  await _shot('14-paywall');
  await _back();

  debugPrint('SHOT done');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Installing the app changes the sandbox container, so the demo rows can only
  // be seeded once this build is on the device. Announce where they belong and
  // hold the UI back until the seeder says it is done.
  final documents = await getApplicationDocumentsDirectory();
  debugPrint('SHOT_DOCS ${documents.path}');
  final gate = File('${documents.path}/go.txt');
  for (var i = 0; i < 240 && !gate.existsSync(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  // The real entrypoint does this too; the harness bypasses it by calling
  // runApp itself, and without it every picture resolves to null.
  await ImageStorage.init();

  // Independent of whatever an external tool seeded through the gate above:
  // this is what guarantees the dashboard and Care tab have something to
  // show rather than their empty states.
  await _seedAttentionDemo();

  final prefs = await SharedPreferences.getInstance();

  // Past the welcome screen and the lock before the walk starts.
  //
  // A fresh install is the honest state to screenshot from in every respect
  // but this one: OnboardingGate holds WelcomeScreen in front of MainScreen
  // until this flag is set, and the walk has no way through it. Left unset,
  // every "screen" the harness captures is the welcome screen -- and it does
  // not fail while doing it, it just quietly photographs the same thing
  // fourteen times.
  await prefs.setBool('hasOnboarded', true);
  await prefs.setBool('isBiometricEnabled', false);

  // Pinned rather than inherited from the simulator.
  //
  // A fresh install now takes its currency from the device region, which is
  // right for a real owner and wrong for a store listing: shots taken on a
  // Vietnamese simulator came out priced in dong for a listing aimed at
  // dollars and euros. Override per run:
  //   flutter run -t lib/main_screenshots.dart --dart-define=SHOT_CURRENCY=EUR
  //                                            --dart-define=SHOT_LANGUAGE=de
  await prefs.setString('currencyCode', _shotCurrency);
  await prefs.setString(
    'languageCode',
    const String.fromEnvironment('SHOT_LANGUAGE', defaultValue: 'en'),
  );

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const InventaApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) => _run());
}
