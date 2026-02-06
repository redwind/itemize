import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/ui/assets/asset_list_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalValue = ref.watch(totalValueProvider);
    final assetsAsync = ref.watch(assetListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalValueCard(totalValue),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: assetsAsync.when(
                data: (assets) => _buildChart(assets),
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

  Widget _buildTotalValueCard(double value) {
    // Format currency properly later using intl
    final formattedValue = '\$${value.toStringAsFixed(2)}';

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
          const Text(
            'Total Value',
            style: TextStyle(color: Colors.white70, fontSize: 16),
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

  Widget _buildChart(List<dynamic> assets) {
    // dynamic to avoid import loop for now, theoretically Asset
    if (assets.isEmpty) {
      return const Center(child: Text('No assets data'));
    }

    // Group by category
    final Map<String, double> categoryValues = {};
    for (var asset in assets) {
      final category = asset.category;
      categoryValues[category] = (categoryValues[category] ?? 0) + asset.price;
    }

    final sections =
        categoryValues.entries.map((e) {
          // final isLarge = e.value > 0; // Simplified logic
          // Generate color based on hash or fixed list
          final color =
              Colors.primaries[e.key.hashCode % Colors.primaries.length];

          return PieChartSectionData(
            color: color,
            value: e.value,
            title: '', // Hide title on chart for clean look
            radius: 20, // Donut thickness
            showTitle: false,
          );
        }).toList();

    return PieChart(
      PieChartData(sections: sections, centerSpaceRadius: 60, sectionsSpace: 2),
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
