import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:itemize/ui/dashboard/dashboard_screen.dart';
import 'package:itemize/ui/assets/asset_list_screen.dart';
import 'package:itemize/ui/care/care_screen.dart';
import 'package:itemize/ui/add_item/add_item_screen.dart';
import 'package:itemize/ui/add_item/quick_capture_screen.dart';
import 'package:itemize/ui/settings/settings_screen.dart';
import 'package:itemize/l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AssetListScreen(),
    const CareScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openSingleItem() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddItemScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  /// Asks which of the two ways of adding is wanted.
  ///
  /// It costs the single-item case one tap, which buys quick capture being
  /// findable at all — on a long-press nobody would ever discover it, and it is
  /// the flow that decides whether a new user gets past their first ten items.
  void _onAddPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add One Item'),
                  subtitle: const Text('With all its details'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openSingleItem();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.burst_mode),
                  title: const Text('Quick Capture a Room'),
                  subtitle: const Text(
                    'Photograph everything, name it afterwards',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QuickCaptureScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        child: const Icon(CupertinoIcons.add),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Or center docked
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.home),
            label: l10n.dashboardTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.cube_box),
            label: l10n.assetsTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.shield),
            label: 'Care',
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}
