import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:itemize/ui/dashboard/dashboard_screen.dart';
import 'package:itemize/ui/assets/asset_list_screen.dart';
import 'package:itemize/ui/add_item/add_item_screen.dart';
import 'package:itemize/ui/settings/settings_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddItemScreen(),
        fullscreenDialog: true,
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
            icon: const Icon(CupertinoIcons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}
