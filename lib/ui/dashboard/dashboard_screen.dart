import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/maintenance_planner.dart';
import 'package:itemize/core/utils/review_status.dart';
import 'package:itemize/core/utils/warranty_status.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/assets/asset_list_screen.dart';
import 'package:itemize/ui/care/care_screen.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/l10n/domain_labels.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalValue = ref.watch(totalValueProvider);
    // Every item, not the Assets tab's current filter -- the pie and the room
    // grid are a picture of the whole inventory and must not redraw themselves
    // around someone's search.
    final assetsAsync = ref.watch(allAssetsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalValueCard(totalValue, l10n, ref),
            _buildCoverageWarning(ref, l10n),
            const SizedBox(height: 24),
            // Leads the screen, above the chart: "is anything about to cost me
            // money" is the question worth answering before a picture of what
            // is merely owned.
            _buildAttentionSection(context, ref, l10n),
            const SizedBox(height: 24),
            // Trimmed from 250: with the attention section now above it, the
            // chart is a picture of the inventory rather than the reason to
            // open the screen, and does not need the room it used to have.
            SizedBox(
              height: 200,
              child: assetsAsync.when(
                data: (assets) => _buildChart(assets, ref, l10n),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (_, __) => Center(child: Text(l10n.errorLoadingChart)),
              ),
            ),
            const SizedBox(height: 24),
            assetsAsync.when(
              data: (assets) => _buildRoomGrid(context, assets, ref, l10n),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(l10n.errorLoadingChart)),
            ),
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
    final settings = ref.watch(settingsProvider);
    final depreciation = ref.watch(depreciationProvider);
    final formattedValue = settings.formatAmount(value);

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
          // The figure a cash-value policy would actually settle on. Shown
          // beside what was paid because the gap between them is the thing
          // owners discover too late, and only when they are already claiming.
          if (depreciation.totalPaid > 0) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.estimatedValueToday,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  settings.formatAmount(depreciation.totalCurrent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Says so when what the owner has recorded has outgrown their policy.
  ///
  /// Compared against the estimated current value, not the purchase total: on a
  /// cash-value policy that is the figure a claim is settled at, so it is the
  /// one that has to fit under the limit. Shown only once there is a limit to
  /// compare against, and only when it has actually been passed — a banner that
  /// is always there is a banner nobody reads.
  Widget _buildCoverageWarning(WidgetRef ref, AppLocalizations l10n) {
    final settings = ref.watch(settingsProvider);
    final depreciation = ref.watch(depreciationProvider);

    if (!settings.hasCoverageLimit) return const SizedBox.shrink();
    if (depreciation.totalCurrent <= settings.coverageLimit) {
      return const SizedBox.shrink();
    }

    final shortfall = depreciation.totalCurrent - settings.coverageLimit;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorRed.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.report_problem, color: AppTheme.errorRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.underInsuredTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.underInsuredBody(
                    settings.formatAmount(shortfall),
                    settings.formatAmount(settings.coverageLimit),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Is anything about to cost me money" — built entirely from planners the
  /// Care screen already trusts, never re-derived here, so the two screens
  /// can never disagree about what counts as urgent.
  ///
  /// Assets and the maintenance plan load separately (the plan waits on the
  /// asset fetch plus a schedules query), so this only blocks on assets: rows
  /// that need nothing but the asset list appear as soon as they can, and the
  /// two maintenance-derived rows fade in once the plan resolves rather than
  /// holding the whole section behind a second spinner.
  Widget _buildAttentionSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final assetsAsync = ref.watch(allAssetsProvider);
    final planAsync = ref.watch(maintenancePlanProvider);

    return assetsAsync.when(
      loading:
          () => _attentionShell(
            l10n,
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      error:
          (err, _) => _attentionShell(
            l10n,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.genericError('$err'),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
      data: (assets) {
        final warrantiesEnding =
            WarrantyStatus.group(assets)[WarrantyStanding.expiringSoon]!
                .length;
        final toReview = ReviewStatus.needingReview(assets).length;

        final plan = planAsync.valueOrNull;
        final warrantyAtRisk =
            plan == null
                ? null
                : MaintenancePlanner.threateningWarranty(plan).length;
        final jobsOverdue =
            plan == null
                ? null
                : MaintenancePlanner.needingAttention(plan).length;

        final rows = <Widget>[
          // Sorted by urgency, not by data source: the warranty-put-at-risk
          // by a skipped service is the one claim in the app worth real
          // money, so it leads and it is the only row styled as a warning.
          if (warrantyAtRisk != null && warrantyAtRisk > 0)
            _attentionRow(
              context,
              l10n.attentionWarrantyAtRisk(warrantyAtRisk),
              icon: Icons.gpp_maybe,
              color: AppTheme.errorRed,
              strong: true,
            ),
          if (jobsOverdue != null && jobsOverdue > 0)
            _attentionRow(
              context,
              l10n.attentionJobsOverdue(jobsOverdue),
              icon: Icons.build_circle_outlined,
              color: Colors.orange.shade800,
            ),
          if (warrantiesEnding > 0)
            _attentionRow(
              context,
              l10n.attentionWarrantiesEnding(warrantiesEnding),
              icon: Icons.shield_outlined,
              color: Colors.amber.shade800,
            ),
          if (toReview > 0)
            _attentionRow(
              context,
              l10n.attentionToReview(toReview),
              icon: Icons.fact_check_outlined,
              color: AppTheme.textSecondary,
            ),
        ];

        if (rows.isEmpty && plan == null) {
          // Nothing to show yet, but the plan hasn't answered either: staying
          // quiet here would read as "all clear" for a heartbeat and then
          // possibly contradict itself the moment the plan lands.
          return _attentionShell(
            l10n,
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (rows.isEmpty) {
          return _attentionShell(
            l10n,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.dashboardAllClear,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }

        return _attentionShell(l10n, Column(children: rows));
      },
    );
  }

  Widget _attentionShell(AppLocalizations l10n, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardAttention.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  /// The Care tab is only reachable by tapping its item in [MainScreen]'s
  /// bottom bar, and that index is private state with no way in from here
  /// without editing a file every other screen is also mid-change on. Pushing
  /// [CareScreen] as its own route gets to the same content honestly, at the
  /// cost of a back button instead of a tab switch.
  Widget _attentionRow(
    BuildContext context,
    String label, {
    required IconData icon,
    required Color color,
    bool strong = false,
  }) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CareScreen()),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: strong ? color.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: strong ? Border.all(color: color.withAlpha(70)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: strong ? FontWeight.bold : FontWeight.w600,
                  color: strong ? color : AppTheme.textPrimary,
                  fontSize: strong ? 15 : 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary.withAlpha(150),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<Asset> assets, WidgetRef ref, AppLocalizations l10n) {
    final settings = ref.watch(settingsProvider);
    if (assets.isEmpty) {
      return Center(child: Text(l10n.noAssetsData));
    }

    // Grouped by room rather than category: it matches the room grid directly
    // below, and every item has a room, whereas items carried over from before
    // the two were split have no category yet.
    final Map<String, double> roomValues = {};
    for (final asset in assets) {
      roomValues[asset.room] = (roomValues[asset.room] ?? 0) + asset.price;
    }

    // Sort by value desc
    final sortedEntries =
        roomValues.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final colors = roomColorPalette(roomValues.keys);

    final sections =
        sortedEntries.map((e) {
          return PieChartSectionData(
            color: colors[e.key]!,
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[e.key]!,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.roomLabel(e.key),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          settings.formatAmountCompact(e.value),
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

  /// Only the rooms something is actually kept in, each with what it holds.
  ///
  /// The old grid was the six fixed rooms every install starts with, shown
  /// whether or not anything was ever put in them — "Garage" for a flat with
  /// none, and no count or value on any of them. This is a picture of the
  /// inventory as it stands, not of the onboarding form.
  Widget _buildRoomGrid(
    BuildContext context,
    List<Asset> assets,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final settings = ref.watch(settingsProvider);

    final Map<String, List<Asset>> byRoom = {};
    for (final asset in assets) {
      byRoom.putIfAbsent(asset.room, () => []).add(asset);
    }

    if (byRoom.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.dashboardNothingYet,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final colors = roomColorPalette(byRoom.keys);
    final rooms =
        byRoom.keys.toList()..sort(
          (a, b) => roomTotal(byRoom[b]!).compareTo(roomTotal(byRoom[a]!)),
        );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        // A fixed height rather than an aspect ratio: the card now carries a
        // count and a value line on top of the room name, and a ratio tuned
        // for the old two-line card clipped the new ones on a narrow phone.
        mainAxisExtent: 140,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final items = byRoom[room]!;
        return _buildRoomCard(
          context,
          room,
          items,
          colors[room]!,
          settings,
          l10n,
        );
      },
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    String room,
    List<Asset> items,
    Color color,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetListScreen(room: room)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.room_preferences, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.roomLabel(room),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              l10n.itemsCount(items.length),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              settings.formatAmount(roomTotal(items)),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// What a room's contents add up to.
double roomTotal(List<Asset> items) =>
    items.fold(0.0, (sum, asset) => sum + asset.price);

/// One colour per room, assigned so no two ever land on the same one.
///
/// The old assignment was `Colors.primaries[room.hashCode % length]`, which
/// two room names can hash into the same slot under — the pie chart and grid
/// would then show two rooms in identical colour with nothing to tell them
/// apart. Assigning by index over the alphabetised set of rooms actually
/// present is deterministic (a room keeps its colour across rebuilds) and
/// collision-free as long as there are no more distinct rooms than
/// `Colors.primaries` has entries, which covers every real inventory.
Map<String, Color> roomColorPalette(Iterable<String> rooms) {
  final sorted = rooms.toSet().toList()..sort();
  return {
    for (var i = 0; i < sorted.length; i++)
      sorted[i]: Colors.primaries[i % Colors.primaries.length],
  };
}
