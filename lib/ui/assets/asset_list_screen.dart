import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'dart:io';
import 'package:itemize/ui/assets/asset_detail_screen.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  final String? category;

  const AssetListScreen({super.key, this.category});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isNotEmpty) {
      _isSearching = true;
      ref.read(assetListProvider.notifier).search(query);
    } else {
      _isSearching = false;
      ref.refresh(assetListProvider); // Reload all
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category ?? 'Assets')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              placeholder: 'Search assets...',
            ),
          ),
          Expanded(
            child: assetsAsync.when(
              data: (assets) {
                // Filter by category if provided and not searching (search usually global, or scoped?)
                // Assuming scoped search if category present logic is complex, for now global search defaults,
                // but if category is strictly set, we should filter memory or initial query.
                // Simplified: If category is set, filter the list from provider unless provider handles it.
                // Since provider search is global in my impl, I'll filter result here.

                var displayAssets = assets;
                if (widget.category != null && !_isSearching) {
                  displayAssets =
                      assets
                          .where((a) => a.category == widget.category)
                          .toList();
                }

                if (displayAssets.isEmpty) {
                  return const Center(child: Text('No assets found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayAssets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final asset = displayAssets[index];
                    return _buildAssetItem(asset, ref);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetItem(Asset asset, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final bool isExpired =
        asset.warrantyExpiry != null &&
        asset.warrantyExpiry!.isBefore(DateTime.now());
    final warrantyColor = isExpired ? AppTheme.errorRed : AppTheme.successGreen;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image:
                    asset.imagePath.isNotEmpty
                        ? DecorationImage(
                          image: FileImage(File(asset.imagePath)),
                          fit: BoxFit.cover,
                        )
                        : null, // Should use FileImage if local path
              ),
              child:
                  asset.imagePath.isEmpty
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${settings.currencySymbol}${asset.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    asset.category,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Warranty Badge
            if (asset.warrantyExpiry != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: warrantyColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpired ? 'Exp' : 'Warranty',
                  style: TextStyle(
                    color: warrantyColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
