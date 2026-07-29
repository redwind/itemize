import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/depreciation.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/add_item/add_item_screen.dart';
import 'package:itemize/ui/care/asset_care_screen.dart';
import 'package:itemize/ui/widgets/asset_thumbnail.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/l10n/domain_labels.dart';

class AssetDetailScreen extends ConsumerStatefulWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  late Asset _currentAsset;
  final PageController _photoController = PageController();
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<Asset>(
      context,
      MaterialPageRoute(builder: (_) => AddItemScreen(existing: _currentAsset)),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _currentAsset = updated;
      _photoIndex = 0;
    });
    // After the rebuild, not before: the edit may have left fewer photos than
    // the page the controller is parked on, and jumping now would move the
    // outgoing PageView rather than the one about to replace it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_photoController.hasClients) _photoController.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final photos = _currentAsset.photoPaths;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // Item photos are square-ish, so a short header cropped the subject
            // in half. Keep the header near square to show the whole thing.
            expandedHeight: MediaQuery.of(context).size.width * 0.9,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhotoPager(photos),
                  // Keeps the back/edit/delete icons legible over a light photo
                  // without darkening the picture itself.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x59000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: _buildPhotoDots(photos.length),
                    ),
                ],
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
                icon: const Icon(Icons.edit),
                tooltip: l10n.edit,
                onPressed: _edit,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(width: 12),
                        Text(
                          settings.formatAmount(_currentAsset.price),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.meeting_room, size: 16),
                          label: Text(l10n.roomLabel(_currentAsset.room)),
                          backgroundColor: Colors.grey[200],
                        ),
                        Chip(
                          avatar: const Icon(Icons.category, size: 16),
                          label: Text(
                            l10n.categoryLabel(_currentAsset.category),
                          ),
                          backgroundColor: Colors.grey[200],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildValueEstimate(settings, l10n),
                    const SizedBox(height: 12),
                    _buildCareLink(l10n),
                    const SizedBox(height: 24),

                    _buildInfoRow(
                      Icons.calendar_today,
                      l10n.purchased,
                      DateFormat.yMMMd().format(_currentAsset.purchaseDate),
                    ),
                    if (_currentAsset.warrantyExpiry != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.security,
                        l10n.warrantyExpires,
                        DateFormat.yMMMd().format(
                          _currentAsset.warrantyExpiry!,
                        ),
                        isWarning: _currentAsset.isWarrantyExpired,
                      ),
                    ],
                    ..._buildOptionalRow(
                      Icons.storefront,
                      l10n.brand,
                      _currentAsset.brand,
                    ),
                    ..._buildOptionalRow(
                      Icons.devices_other,
                      l10n.model,
                      _currentAsset.model,
                    ),
                    ..._buildOptionalRow(
                      Icons.pin,
                      l10n.serialNumber,
                      _currentAsset.serialNumber,
                    ),
                    ..._buildOptionalRow(
                      Icons.qr_code,
                      l10n.barcode,
                      _currentAsset.barcode,
                    ),
                    ..._buildOptionalRow(
                      Icons.notes,
                      l10n.notes,
                      _currentAsset.notes,
                    ),

                    if (_currentAsset.receiptPath != null) ...[
                      const SizedBox(height: 24),
                      _buildReceipt(l10n),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  /// What this item would likely be settled at today.
  ///
  /// Labelled an estimate everywhere it appears: it is a straight-line figure
  /// on a conventional useful life, not any insurer's own schedule, and
  /// presenting it as fact would be the kind of number people quote back at an
  /// adjuster and lose an argument with.
  Widget _buildValueEstimate(AppSettings settings, AppLocalizations l10n) {
    final current = Depreciation.currentValue(_currentAsset);
    final depreciates = Depreciation.depreciates(_currentAsset.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.estimatedValueToday,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                settings.formatAmount(current),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            depreciates
                ? l10n.valueEstimateDepreciates(
                  l10n.categoryLabel(_currentAsset.category),
                )
                : l10n.valueEstimateHeld(
                  l10n.categoryLabel(_currentAsset.category),
                ),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// The way through to what this item needs and what it has cost.
  ///
  /// Summarised rather than expanded here: the detail screen is already long,
  /// and the count of overdue jobs is the only part of it worth reading at a
  /// glance.
  Widget _buildCareLink(AppLocalizations l10n) {
    final plan = ref.watch(maintenancePlanProvider).valueOrNull ?? const [];
    final mine = plan.where((d) => d.asset.id == _currentAsset.id).toList();
    final overdue = mine.where((d) => d.isOverdue()).length;
    final atRisk = mine.any((d) => d.threatensWarranty());

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.build_circle_outlined,
        color: atRisk ? AppTheme.errorRed : AppTheme.primaryBlue,
      ),
      title: Text(l10n.careAndHistory),
      subtitle: Text(
        switch ((mine.length, overdue)) {
          (0, _) => l10n.careNothingScheduled,
          (_, 0) => l10n.careNoneOverdue(mine.length),
          (_, final late) => l10n.careOverdue(late, mine.length),
        },
        style: TextStyle(
          fontSize: 12,
          color: overdue > 0 ? AppTheme.errorRed : Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetCareScreen(asset: _currentAsset),
            ),
          ),
    );
  }

  Widget _buildPhotoPager(List<String> photos) {
    if (photos.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 80, color: Colors.grey),
      );
    }

    // Matches the SliverAppBar's expandedHeight above, which is what this
    // pager actually fills.
    final width = MediaQuery.of(context).size.width;
    final height = width * 0.9;

    return PageView.builder(
      controller: _photoController,
      itemCount: photos.length,
      onPageChanged: (i) => setState(() => _photoIndex = i),
      itemBuilder: (context, index) {
        final image = AssetThumbnail.provider(
          context,
          photos[index],
          width: width,
          height: height,
        );
        if (image == null) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
          );
        }
        return Image(image: image, fit: BoxFit.cover);
      },
    );
  }

  Widget _buildPhotoDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == _photoIndex;
        return Container(
          width: selected ? 10 : 6,
          height: selected ? 10 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? Colors.white : Colors.white54,
          ),
        );
      }),
    );
  }

  Widget _buildReceipt(AppLocalizations l10n) {
    // The Image below is laid out at the full content width (double.infinity
    // grows to it), so that -- not the fixed height -- is what the decode
    // needs to match to avoid both over- and under-sizing it.
    final image = AssetThumbnail.provider(
      context,
      _currentAsset.receiptPath,
      width: MediaQuery.of(context).size.width - 32,
      height: 220,
      fit: BoxFit.contain,
    );
    if (image == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.green),
            const SizedBox(width: 16),
            Text(
              l10n.receipt,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image(
            image: image,
            height: 220,
            width: double.infinity,
            // A till roll is far taller than it is wide, so cropping it to the
            // box would hide the total. Show it whole and let it sit small.
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  /// A row, or nothing at all when the field was never filled in.
  List<Widget> _buildOptionalRow(IconData icon, String label, String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return [const SizedBox(height: 16), _buildInfoRow(icon, label, value)];
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isWarning ? Colors.red : Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(assetRepositoryProvider);
    final scheduleCount =
        (await repository.schedulesFor(_currentAsset.id)).length;
    final recordCount =
        (await repository.serviceRecordsFor(_currentAsset.id)).length;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.deleteItemTitle(_currentAsset.name)),
            content: Text(
              // Named, because a service history is the part that cannot be
              // reconstructed from memory and the owner may not have realised
              // it goes too.
              recordCount == 0 && scheduleCount == 0
                  ? l10n.deleteItemSimple
                  : l10n.deleteItemWithHistory(scheduleCount, recordCount),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(assetListProvider.notifier);
    final snapshot = await notifier.deleteAssetWithUndo(_currentAsset);
    await HapticFeedback.mediumImpact();

    if (snapshot != null) {
      // Taken from the enclosing scaffold before this screen pops, so the bar
      // survives the navigation that immediately follows.
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.deletedItem(snapshot.asset.name)),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => notifier.undoDelete(snapshot),
          ),
        ),
      );
    }

    if (context.mounted) Navigator.pop(context);
  }
}
