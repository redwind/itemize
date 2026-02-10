import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/assets/asset_list_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalValue = ref.watch(totalValueProvider);
    final assetsAsync = ref.watch(assetListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalValueCard(totalValue, l10n, ref),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: assetsAsync.when(
                data: (assets) => _buildChart(assets, ref),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (_, __) => const Center(child: Text('Error loading chart')),
              ),
            ),
            const SizedBox(height: 24),
            _buildRoomGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalValueCard(
    double value,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    // Format currency properly later using intl
    final settings = ref.watch(settingsProvider);
    final formattedValue =
        '${settings.currencySymbol}${value.toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.totalValue,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            formattedValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<dynamic> assets, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    if (assets.isEmpty) {
      return const Center(child: Text('No assets data'));
    }

    // Group by category
    final Map<String, double> categoryValues = {};
    for (var asset in assets) {
      final category = asset.category;
      categoryValues[category] = (categoryValues[category] ?? 0) + asset.price;
    }

    // Sort by value desc
    final sortedEntries =
        categoryValues.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final sections =
        sortedEntries.map((e) {
          final color =
              Colors.primaries[e.key.hashCode % Colors.primaries.length];
          return PieChartSectionData(
            color: color,
            value: e.value,
            title: '',
            radius: 20,
            showTitle: false,
          );
        }).toList();

    return Row(
      children: [
        // Chart
        Expanded(
          flex: 1,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                sortedEntries.map((e) {
                  final color =
                      Colors.primaries[e.key.hashCode %
                          Colors.primaries.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${settings.currencySymbol}${e.value.toStringAsFixed(0)}', // Rounded for cleaner look in legend
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomGrid(BuildContext context) {
    final rooms = [
      'Living Room',
      'Kitchen',
      'Bedroom',
      'Office',
      'Garage',
      'Other',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _buildRoomCard(context, room);
      },
    );
  }

  Widget _buildRoomCard(BuildContext context, String room) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetListScreen(category: room)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon could be dynamic based on room name
            Icon(
              Icons.room_preferences,
              color: AppTheme.primaryBlue.withAlpha(180),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              room,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
