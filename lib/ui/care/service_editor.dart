import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/models/service_record.dart';
import 'package:uuid/uuid.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/l10n/domain_labels.dart';

/// Records work done on an item, returning null if nothing was saved.
Future<ServiceRecord?> showServiceEditor(
  BuildContext context, {
  required Asset asset,
  required List<MaintenanceSchedule> schedules,
  MaintenanceSchedule? preselected,
  required String currencySymbol,
}) {
  return showModalBottomSheet<ServiceRecord>(
    context: context,
    isScrollControlled: true,
    builder:
        (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _ServiceEditor(
            asset: asset,
            schedules: schedules,
            preselected: preselected,
            currencySymbol: currencySymbol,
          ),
        ),
  );
}

class _ServiceEditor extends StatefulWidget {
  final Asset asset;
  final List<MaintenanceSchedule> schedules;
  final MaintenanceSchedule? preselected;
  final String currencySymbol;

  const _ServiceEditor({
    required this.asset,
    required this.schedules,
    this.preselected,
    required this.currencySymbol,
  });

  @override
  State<_ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends State<_ServiceEditor> {
  final _description = TextEditingController();
  final _cost = TextEditingController();
  final _provider = TextEditingController();

  DateTime _date = DateTime.now();
  late ServiceKind _kind;
  String? _scheduleId;

  @override
  void initState() {
    super.initState();
    _scheduleId = widget.preselected?.id;
    // Logging against a schedule is nearly always the scheduled job being done,
    // so start there rather than making them say so.
    _kind =
        widget.preselected != null ? ServiceKind.maintenance : ServiceKind.repair;
    if (widget.preselected != null) {
      _description.text = widget.preselected!.title;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      ServiceRecord(
        id: const Uuid().v4(),
        assetId: widget.asset.id,
        date: _date,
        kind: _kind,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        cost: double.tryParse(_cost.text.trim()) ?? 0,
        provider:
            _provider.text.trim().isEmpty ? null : _provider.text.trim(),
        scheduleId: _scheduleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.logWorkDone,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SegmentedButton<ServiceKind>(
              segments: [
                for (final kind in ServiceKind.values)
                  ButtonSegment(value: kind, label: Text(l10n.serviceKindLabel(kind))),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.whatWasDone,
                hintText: l10n.whatWasDoneHint,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cost,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.cost,
                      prefixText: widget.currencySymbol,
                      // Free work is still worth recording, and leaving this
                      // blank should not feel like an omission.
                      hintText: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _provider,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.whoDidIt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.when),
              subtitle: Text(DateFormat.yMMMd().format(_date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: widget.asset.purchaseDate,
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),

            if (widget.schedules.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: _scheduleId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.satisfiesWhichJob,
                  helperText: l10n.satisfiesWhichJobHint,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.none)),
                  for (final schedule in widget.schedules)
                    DropdownMenuItem(
                      value: schedule.id,
                      child: Text(schedule.title),
                    ),
                ],
                onChanged: (v) => setState(() => _scheduleId = v),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
