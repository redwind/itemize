import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/asset_search.dart';
import 'package:itemize/core/utils/warranty_status.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/assets/asset_detail_screen.dart';
import 'package:itemize/ui/widgets/asset_thumbnail.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/l10n/domain_labels.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  /// Shows only the items kept in this room, or every item when null.
  final String? room;

  const AssetListScreen({super.key, this.room});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// This screen's own query, and nothing else's.
  ///
  /// Two of these screens exist over one provider -- the Assets tab and the
  /// room drill-down from the dashboard -- and searching used to narrow the
  /// shared state. So a search run in one room followed the user back to the
  /// tab, which then showed a filtered list with an empty search box.
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Every stored item. What this screen shows is decided below, in this
    // screen, rather than by rewriting the list everything else reads from.
    final assetsAsync = ref.watch(allAssetsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.room == null ? l10n.assetsTab : l10n.roomLabel(widget.room!),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: (query) => setState(() => _query = query),
              placeholder: l10n.searchPlaceholder,
            ),
          ),
          Expanded(
            child: assetsAsync.when(
              data: (assets) {
                // The room narrows the list first and stays applied while
                // searching. Searching inside "Garage" used to return matches
                // from the whole house under a heading that said Garage.
                final inRoom =
                    widget.room == null
                        ? assets
                        : assets.where((a) => a.room == widget.room).toList();
                final displayAssets = filterAssets(inRoom, _query);

                if (displayAssets.isEmpty) {
                  return Center(child: Text(l10n.noAssetsFound));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayAssets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final asset = displayAssets[index];
                    return _buildAssetItem(asset, ref, l10n);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text(l10n.genericError(err.toString()))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetItem(Asset asset, WidgetRef ref, AppLocalizations l10n) {
    final settings = ref.watch(settingsProvider);
    final thumbnail = AssetThumbnail.provider(
      context,
      asset.imagePath,
      width: 60,
      height: 60,
    );
    // Same standings, labels and colours as the Care tab -- see
    // WarrantyStatus.of. Two screens disagreeing about whether something is
    // covered is worse than either being wrong on its own.
    final standing = WarrantyStatus.of(asset);
    final warrantyColor = switch (standing) {
      WarrantyStanding.covered => AppTheme.successGreen,
      WarrantyStanding.expiringSoon => Colors.orange.shade800,
      WarrantyStanding.expired => AppTheme.errorRed,
      WarrantyStanding.unknown => Colors.grey,
    };
    final warrantyLabel = switch (standing) {
      WarrantyStanding.covered => l10n.standingCovered,
      WarrantyStanding.expiringSoon => l10n.standingEndingSoon,
      WarrantyStanding.expired => l10n.standingExpired,
      WarrantyStanding.unknown => l10n.standingUnknown,
    };

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
                    thumbnail != null
                        ? DecorationImage(image: thumbnail, fit: BoxFit.cover)
                        : null,
              ),
              child:
                  thumbnail == null
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
                    settings.formatAmount(asset.price),
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    // Both, because the list is reached from a room grid and
                    // from a global search, and which one is the useful label
                    // depends on which way they came in.
                    '${l10n.roomLabel(asset.room)} · '
                    '${l10n.categoryLabel(asset.category)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
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
                  warrantyLabel,
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
