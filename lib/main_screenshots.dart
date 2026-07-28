// Temporary App Store screenshot harness. Runs the real ItemizeApp and walks it
// through the screens worth capturing, printing a SHOT marker whenever a screen
// has settled so an external script can grab the simulator frame.
//
// Navigation invokes the widgets' own callbacks rather than synthesising pointer
// events -- injected PointerDown/Up never reached the gesture arena here, so the
// walk silently stayed on the first screen. Delete when the screenshots are done.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/main.dart';
import 'package:itemize/providers/settings_provider.dart';
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

Future<void> _back() async {
  final navigator = _navigator();
  if (navigator != null && navigator.canPop()) {
    navigator.pop();
    await Future<void>.delayed(_settle);
  }
}

Future<void> _run() async {
  // Let the first frame render and the asset list load from sqflite.
  await Future<void>.delayed(const Duration(seconds: 4));

  await _shot('01-dashboard');

  // Do the Add Item flow first: pushing a route, popping it and pushing another
  // left the walk activating handlers from the route that was on its way out.
  final fab = _findWidget<FloatingActionButton>();
  if (fab?.onPressed != null) {
    fab!.onPressed!();
    await Future<void>.delayed(_settle);
    await _shot('04-add-item');

    // Photo source sheet -> stock library -> item filled in from the catalog.
    await _openByText('Tap to add photo');
    await _shot('05-photo-options');

    await _openByText('Pick a Stock Image');
    await Future<void>.delayed(_settle);
    await _shot('06-stock-library');

    await _openByText('Armchair');
    await Future<void>.delayed(_settle);
    await _shot('07-stock-image-applied');

    await _back();
    await Future<void>.delayed(_settle);
  } else {
    debugPrint('SHOT_WARN no FloatingActionButton');
  }

  await _selectTab(1, 'assets');
  await _shot('02-assets');

  await _openByText('65" OLED Smart TV');
  await _shot('03-detail');
  await _back();
  await Future<void>.delayed(_settle);

  await _selectTab(2, 'settings');
  await _shot('08-settings');

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

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ItemizeApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) => _run());
}
