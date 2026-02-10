import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';

class AssetDetailScreen extends ConsumerStatefulWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  late Asset _currentAsset;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  _currentAsset.imagePath.isNotEmpty
                      ? Image.file(
                        File(_currentAsset.imagePath),
                        fit: BoxFit.cover,
                      )
                      : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _currentAsset.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () async {
                  // Toggle favorite locally for immediate UI update
                  setState(() {
                    _currentAsset = _currentAsset.copyWith(
                      isFavorite: !_currentAsset.isFavorite,
                    );
                  });
                  await HapticFeedback.selectionClick();

                  // Update provider
                  ref
                      .read(assetListProvider.notifier)
                      .updateAsset(_currentAsset);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _currentAsset.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${settings.currencySymbol}${_currentAsset.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_currentAsset.category),
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Purchased',
                      DateFormat.yMMMd().format(_currentAsset.purchaseDate),
                    ),
                    if (_currentAsset.warrantyExpiry != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.security,
                        'Warranty Expires',
                        DateFormat.yMMMd().format(
                          _currentAsset.warrantyExpiry!,
                        ),
                        isWarning: _currentAsset.warrantyExpiry!.isBefore(
                          DateTime.now(),
                        ),
                      ),
                    ],
                    if (_currentAsset.barcode != null &&
                        _currentAsset.barcode!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.qr_code,
                        'Barcode',
                        _currentAsset.barcode!,
                      ),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: isWarning ? Colors.red : Colors.grey),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isWarning ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Asset?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ref.read(assetListProvider.notifier).deleteAsset(_currentAsset.id);
      await HapticFeedback.mediumImpact();
      if (context.mounted) Navigator.pop(context);
    }
  }
}
