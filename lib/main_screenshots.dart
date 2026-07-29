// Temporary App Store screenshot harness. Runs the real ItemizeApp and walks it
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
import 'package:itemize/core/catalog/asset_catalog.dart';
import 'package:itemize/core/utils/catalog_image.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/repositories/asset_repository.dart';
import 'package:itemize/main.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/add_item/warranty_prompt_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _settle = Duration(milliseconds: 1500);
const _dwell = Duration(seconds: 5);

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

  // Warranty ending soon: inside WarrantyStatus.expiringSoonDays (90) but not
  // yet lapsed, so it lands in the dashboard's "ending soon" row and the Care
  // tab's default filter.
  final fridge = Asset(
    id: 'shot-demo-fridge',
    name: 'Kitchen Fridge-Freezer',
    price: 899,
    currency: 'EUR',
    room: 'Kitchen',
    category: 'Appliances',
    photoPaths: [await CatalogImage.render(catalogItem('refrigerator'))],
    purchaseDate: now.subtract(const Duration(days: 700)),
    warrantyExpiry: now.add(const Duration(days: 30)),
    lastReviewedAt: now,
  );
  await upsert(fridge);

  // A live warranty plus a lapsed, warranty-required job: the one row the
  // dashboard styles as an actual warning rather than a nudge.
  final boiler = Asset(
    id: 'shot-demo-boiler',
    name: 'Gas Boiler',
    price: 2100,
    currency: 'EUR',
    room: 'Basement',
    category: 'Appliances',
    photoPaths: [await CatalogImage.render(catalogItem('dishwasher'))],
    purchaseDate: now.subtract(const Duration(days: 400)),
    warrantyExpiry: now.add(const Duration(days: 200)),
    lastReviewedAt: now,
  );
  await upsert(boiler);

  await repository.saveSchedule(
    MaintenanceSchedule(
      id: 'shot-demo-boiler-service',
      assetId: boiler.id,
      title: 'Annual Boiler Service',
      intervalMonths: 12,
      lastDoneAt: now.subtract(const Duration(days: 400)),
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

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ItemizeApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) => _run());
}
