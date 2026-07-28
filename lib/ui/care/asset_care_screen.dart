import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/maintenance_planner.dart';
import 'package:itemize/core/utils/ownership_cost.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/models/service_record.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/care/schedule_editor.dart';
import 'package:itemize/ui/care/service_editor.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/l10n/domain_labels.dart';

/// Everything about looking after one item: what it needs, what has been done,
/// and what it has cost.
class AssetCareScreen extends ConsumerWidget {
  final Asset asset;

  const AssetCareScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(schedulesForAssetProvider(asset.id));
    final records = ref.watch(serviceRecordsProvider(asset.id));
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(asset.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            l10n.scheduledJobs,
            onAdd: () => _addSchedule(context, ref),
          ),
          schedules.when(
            loading: () => const _Loading(),
            error: (e, _) => Text('Error: $e'),
            data:
                (list) =>
                    list.isEmpty
                        ? _Empty(l10n.noSchedulesYet)
                        : Column(
                          children: [
                            for (final schedule in list)
                              _ScheduleTile(
                                asset: asset,
                                schedule: schedule,
                                onEdit:
                                    () => _addSchedule(
                                      context,
                                      ref,
                                      existing: schedule,
                                    ),
                                onLog:
                                    () => _logService(
                                      context,
                                      ref,
                                      schedule: schedule,
                                    ),
                                onDelete:
                                    () => _deleteSchedule(ref, schedule.id),
                              ),
                          ],
                        ),
          ),

          const SizedBox(height: 24),
          _sectionHeader(l10n.history, onAdd: () => _logService(context, ref)),
          records.when(
            loading: () => const _Loading(),
            error: (e, _) => Text('Error: $e'),
            data:
                (list) =>
                    list.isEmpty
                        ? _Empty(l10n.noHistoryYet)
                        : Column(
                          children: [
                            for (final record in list)
                              _RecordTile(
                                record: record,
                                settings: settings,
                                l10n: l10n,
                                onDelete:
                                    () => _deleteRecord(ref, record.id),
                              ),
                          ],
                        ),
          ),

          const SizedBox(height: 24),
          records.maybeWhen(
            data:
                (list) => _CostCard(
                  cost: OwnershipCost.of(asset, list),
                  settings: settings,
                ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: Builder(
            builder: (c) => Text(AppLocalizations.of(c)!.add),
          ),
        ),
      ],
    );
  }

  Future<void> _addSchedule(
    BuildContext context,
    WidgetRef ref, {
    MaintenanceSchedule? existing,
  }) async {
    final result = await showScheduleEditor(
      context,
      asset: asset,
      existing: existing,
    );
    if (result == null) return;

    await ref.read(assetRepositoryProvider).saveSchedule(result);
    await _refresh(ref);
  }

  Future<void> _logService(
    BuildContext context,
    WidgetRef ref, {
    MaintenanceSchedule? schedule,
  }) async {
    final schedules =
        await ref.read(assetRepositoryProvider).schedulesFor(asset.id);
    if (!context.mounted) return;

    final result = await showServiceEditor(
      context,
      asset: asset,
      schedules: schedules,
      preselected: schedule,
      currencySymbol: ref.read(settingsProvider).currencySymbol,
    );
    if (result == null) return;

    await ref.read(assetRepositoryProvider).logService(result);
    await _refresh(ref);
  }

  Future<void> _deleteSchedule(WidgetRef ref, String id) async {
    await ref.read(assetRepositoryProvider).deleteSchedule(id);
    await _refresh(ref);
  }

  Future<void> _deleteRecord(WidgetRef ref, String id) async {
    await ref.read(assetRepositoryProvider).deleteServiceRecord(id);
    await _refresh(ref);
  }

  /// Reloads the item list, which is what rebuilds the reminder schedule.
  ///
  /// The child providers hang off it, so this refreshes the screen as well as
  /// the notifications — adding a job and not being reminded about it would
  /// make the whole feature pointless.
  Future<void> _refresh(WidgetRef ref) =>
      ref.read(assetListProvider.notifier).loadAssets();
}

class _ScheduleTile extends StatelessWidget {
  final Asset asset;
  final MaintenanceSchedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onLog;
  final VoidCallback onDelete;

  const _ScheduleTile({
    required this.asset,
    required this.schedule,
    required this.onEdit,
    required this.onLog,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final due = MaintenanceDue(
      asset: asset,
      schedule: schedule,
      dueAt: schedule.nextDueAfter(asset.purchaseDate),
    );
    final days = due.daysUntilDue();
    final overdue = due.isOverdue();
    final atRisk = due.threatensWarranty();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: atRisk ? AppTheme.errorRed : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(schedule.title),
            subtitle: Text(
              overdue
                  ? l10n.overdueByEvery(-days, schedule.intervalMonths)
                  : l10n.dueOnEvery(
                    DateFormat.yMMMd().format(due.dueAt),
                    schedule.intervalMonths,
                  ),
              style: TextStyle(
                color: overdue ? AppTheme.errorRed : Colors.grey,
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder:
                  (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                    PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                  ],
            ),
            onTap: onLog,
          ),
          if (atRisk)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.gpp_maybe,
                    size: 18,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.warrantyAtRiskItem,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final ServiceRecord record;
  final AppSettings settings;
  final AppLocalizations l10n;
  final VoidCallback onDelete;

  const _RecordTile({
    required this.record,
    required this.settings,
    required this.l10n,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        switch (record.kind) {
          ServiceKind.maintenance => Icons.build_circle_outlined,
          ServiceKind.repair => Icons.handyman_outlined,
          ServiceKind.inspection => Icons.fact_check_outlined,
        },
        color: Colors.grey,
      ),
      title: Text(
        record.description?.isNotEmpty == true
            ? record.description!
            : l10n.serviceKindLabel(record.kind),
      ),
      subtitle: Text(
        [
          DateFormat.yMMMd().format(record.date),
          if (record.provider?.isNotEmpty == true) record.provider!,
        ].join(' · '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            record.cost > 0 ? settings.formatAmount(record.cost) : l10n.free,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  final OwnershipCost cost;
  final AppSettings settings;

  const _CostCard({required this.cost, required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, headline) = switch (cost.verdict) {
      OwnershipVerdict.healthy => (AppTheme.successGreen, l10n.verdictKeep),
      OwnershipVerdict.watch => (Colors.orange.shade800, l10n.verdictWatch),
      OwnershipVerdict.replace => (AppTheme.errorRed, l10n.verdictReplace),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 12),
          _row(l10n.paidForIt, settings.formatAmount(cost.purchasePrice)),
          _row(l10n.spentOnRepairs, settings.formatAmount(cost.serviceSpend)),
          _row(l10n.worthToday, settings.formatAmount(cost.estimatedValue)),
          const Divider(height: 20),
          _row(
            l10n.totalOutlay,
            settings.formatAmount(cost.totalOutlay),
            bold: true,
          ),
          const SizedBox(height: 8),
          Text(
            switch (cost.verdict) {
              OwnershipVerdict.healthy => l10n.verdictKeepBody,
              OwnershipVerdict.watch => l10n.verdictWatchBody,
              OwnershipVerdict.replace => l10n.verdictReplaceBody,
            },
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.verdictDisclaimer,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty(this.message);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      message,
      style: const TextStyle(color: Colors.grey, fontSize: 13),
    ),
  );
}
