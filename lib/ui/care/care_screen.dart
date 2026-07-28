import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/core/utils/maintenance_planner.dart';
import 'package:itemize/core/utils/review_status.dart';
import 'package:itemize/core/utils/warranty_status.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/assets/asset_detail_screen.dart';
import 'package:itemize/ui/care/asset_care_screen.dart';

/// What the app is for between the day it is filled in and the day it is needed.
///
/// The inventory itself is written once and then sits there; this is the screen
/// with a reason to be opened. It starts with the question people actually come
/// here to ask — is this still under warranty — and is where maintenance due,
/// service history and review nudges belong as they arrive.
class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

/// Below this, there is not yet enough recorded to be worth warning about.
const int _backupNudgeMinItems = 10;

/// How long a record may go uncopied before it is worth mentioning.
const int _backupNudgeAfterDays = 90;

class _CareScreenState extends ConsumerState<CareScreen> {
  WarrantyStanding _filter = WarrantyStanding.expiringSoon;

  static const Map<WarrantyStanding, String> _labels = {
    WarrantyStanding.expiringSoon: 'Ending soon',
    WarrantyStanding.covered: 'Covered',
    WarrantyStanding.expired: 'Expired',
    WarrantyStanding.unknown: 'No date',
  };

  static const Map<WarrantyStanding, String> _emptyMessages = {
    WarrantyStanding.expiringSoon:
        'Nothing is about to run out. This is where things appear in their '
        'last three months of cover.',
    WarrantyStanding.covered: 'Nothing here is under warranty yet.',
    WarrantyStanding.expired: 'Nothing has run out of cover.',
    WarrantyStanding.unknown:
        'Every item has a warranty date on it. Adding them is what makes this '
        'screen worth opening.',
  };

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(allAssetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Care')),
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (assets) {
          final grouped = WarrantyStatus.group(assets);
          final shown = grouped[_filter]!;

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildBackupNudge(assets),
              _buildReviewSection(assets),
              _buildMaintenanceSection(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'WARRANTIES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildFilters(grouped),
              if (shown.isEmpty)
                _buildEmpty()
              else
                ...shown.map(
                  (asset) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _buildRow(asset),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(Map<WarrantyStanding, List<Asset>> grouped) {
    // Ordered by urgency rather than by the enum: what is about to lapse is
    // what someone needs to see first, and it is the tab that opens.
    const order = [
      WarrantyStanding.expiringSoon,
      WarrantyStanding.covered,
      WarrantyStanding.expired,
      WarrantyStanding.unknown,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (final standing in order)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('${_labels[standing]} (${grouped[standing]!.length})'),
                selected: _filter == standing,
                onSelected: (_) => setState(() => _filter = standing),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            _emptyMessages[_filter]!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Says so when the record has not been copied anywhere in a long while.
  ///
  /// Only once there is something to lose, and only after long enough that the
  /// warning means something. A new user who has entered three items does not
  /// need telling to protect them.
  Widget _buildBackupNudge(List<Asset> assets) {
    if (assets.length < _backupNudgeMinItems) return const SizedBox.shrink();

    final days = ref.watch(settingsProvider).daysSinceBackup;
    if (days != null && days < _backupNudgeAfterDays) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.backup_outlined, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days == null
                      ? 'This is only on this phone'
                      : 'No backup for $days days',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${assets.length} items, their photographs and every repair '
                  'you have logged. Lose the phone and it goes with it.',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A handful of entries worth confirming are still true.
  ///
  /// Shown a few at a time rather than as a list of two hundred, because a
  /// chore nobody starts keeps nothing accurate. The rest come round next time.
  Widget _buildReviewSection(List<Asset> assets) {
    final batch = ReviewStatus.nextBatch(assets);
    if (batch.isEmpty) return const SizedBox.shrink();

    final total = ReviewStatus.needingReview(assets).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryBlue.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: AppTheme.primaryBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  total == 1
                      ? '1 entry to check'
                      : '$total entries to check',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Still own these, and are the details still right? A list that has '
            'drifted is one an insurer can argue with.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (final asset in batch)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      asset.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => ref
                            .read(assetListProvider.notifier)
                            .markReviewed(asset),
                    child: const Text('Still right'),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssetDetailScreen(asset: asset),
                          ),
                        ),
                    child: const Text('Check'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Jobs that are late or nearly due, warranty-critical ones first.
  ///
  /// Leads the screen because it is the part that changes: a warranty date sits
  /// still for years, whereas something falls due every few weeks, and that is
  /// what makes the app worth opening again.
  Widget _buildMaintenanceSection() {
    final plan = ref.watch(maintenancePlanProvider).valueOrNull;
    if (plan == null) return const SizedBox.shrink();

    final attention = MaintenancePlanner.needingAttention(plan);
    final atRisk = MaintenancePlanner.threateningWarranty(plan);

    if (plan.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          'Nothing scheduled anywhere yet. Open any item and add what it needs '
          'doing — a filter, a service — and it will show up here when due.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    // Warranty-critical lapses sort above merely-late jobs: they are the ones
    // with money attached.
    final ordered = [
      ...attention.where((d) => d.threatensWarranty()),
      ...attention.where((d) => !d.threatensWarranty()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'NEEDS DOING (${attention.length})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (atRisk.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.errorRed.withAlpha(70)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gpp_maybe, color: AppTheme.errorRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${atRisk.length} warrant${atRisk.length == 1 ? 'y is' : 'ies are'} at risk',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorRed,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Servicing these items is a condition of their cover, '
                        'and it has lapsed. A missed service is grounds to '
                        'decline a claim.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (ordered.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Nothing due in the next fortnight.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          ...ordered.map(
            (due) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildDueRow(due),
            ),
          ),
      ],
    );
  }

  Widget _buildDueRow(MaintenanceDue due) {
    final days = due.daysUntilDue();
    final overdue = due.isOverdue();
    final atRisk = due.threatensWarranty();
    final color =
        atRisk
            ? AppTheme.errorRed
            : overdue
            ? Colors.orange.shade800
            : Colors.grey.shade700;

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetCareScreen(asset: due.asset),
            ),
          ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: atRisk ? Border.all(color: AppTheme.errorRed) : null,
        ),
        child: Row(
          children: [
            Icon(
              atRisk ? Icons.gpp_maybe : Icons.build_circle_outlined,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    due.schedule.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    due.asset.name,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              overdue ? '${-days} d late' : 'in $days d',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Asset asset) {
    final days = WarrantyStatus.daysRemaining(asset);
    final thumbnail = ImageStorage.resolve(asset.imagePath);
    final standing = WarrantyStatus.of(asset);

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset)),
          ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                image:
                    thumbnail != null
                        ? DecorationImage(
                          image: FileImage(thumbnail),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  thumbnail == null
                      ? const Icon(Icons.image, size: 20, color: Colors.grey)
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${asset.room} · ${asset.category}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildRemaining(standing, days, asset),
          ],
        ),
      ),
    );
  }

  Widget _buildRemaining(WarrantyStanding standing, int? days, Asset asset) {
    if (days == null || asset.warrantyExpiry == null) {
      return const Text(
        'Not recorded',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    final color = switch (standing) {
      WarrantyStanding.covered => AppTheme.successGreen,
      WarrantyStanding.expiringSoon => Colors.orange.shade800,
      WarrantyStanding.expired => AppTheme.errorRed,
      WarrantyStanding.unknown => Colors.grey,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _remainingLabel(days),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat.yMMMd().format(asset.warrantyExpiry!),
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  /// Days, weeks or months, whichever reads as a decision rather than a number.
  ///
  /// "412 days left" is arithmetic; "1 yr 2 mo left" is an answer.
  static String _remainingLabel(int days) {
    if (days < 0) {
      final gone = -days;
      if (gone < 31) return 'Ended $gone d ago';
      if (gone < 365) return 'Ended ${(gone / 30).round()} mo ago';
      return 'Ended ${(gone / 365).floor()} yr ago';
    }
    if (days == 0) return 'Ends today';
    if (days < 31) return '$days d left';
    if (days < 365) return '${(days / 30).round()} mo left';

    final years = days ~/ 365;
    final months = ((days % 365) / 30).round();
    return months == 0 ? '$years yr left' : '$years yr $months mo left';
  }
}
