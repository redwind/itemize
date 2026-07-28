import 'package:flutter/material.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:uuid/uuid.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/l10n/domain_labels.dart';

/// Creates or edits one recurring job, returning null if nothing was saved.
Future<MaintenanceSchedule?> showScheduleEditor(
  BuildContext context, {
  required Asset asset,
  MaintenanceSchedule? existing,
}) {
  return showModalBottomSheet<MaintenanceSchedule>(
    context: context,
    isScrollControlled: true,
    builder:
        (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _ScheduleEditor(asset: asset, existing: existing),
        ),
  );
}

class _ScheduleEditor extends StatefulWidget {
  final Asset asset;
  final MaintenanceSchedule? existing;

  const _ScheduleEditor({required this.asset, this.existing});

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  late final TextEditingController _title;
  late int _intervalMonths;
  late bool _requiredForWarranty;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _intervalMonths = widget.existing?.intervalMonths ?? 12;
    _requiredForWarranty = widget.existing?.requiredForWarranty ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// Jobs this kind of thing usually needs, if there are any.
  ///
  /// The blank form is what stops people using a feature like this at all —
  /// nobody sits down to invent a servicing schedule from nothing. Offering
  /// three plausible ones turns it into a tap.
  List<({String titleKey, int months, bool warranty})> get _suggestions =>
      kSuggestedMaintenance[widget.asset.category] ?? const [];

  void _apply(
    AppLocalizations l10n,
    ({String titleKey, int months, bool warranty}) suggestion,
  ) {
    setState(() {
      _title.text = l10n.jobLabel(suggestion.titleKey);
      _intervalMonths = suggestion.months;
      _requiredForWarranty = suggestion.warranty;
    });
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(
      context,
      widget.existing?.copyWith(
            title: title,
            intervalMonths: _intervalMonths,
            requiredForWarranty: _requiredForWarranty,
          ) ??
          MaintenanceSchedule(
            id: const Uuid().v4(),
            assetId: widget.asset.id,
            title: title,
            intervalMonths: _intervalMonths,
            requiredForWarranty: _requiredForWarranty,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? l10n.editJob : l10n.newJob,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (!_isEditing && _suggestions.isNotEmpty) ...[
              Text(
                l10n.commonForThis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final suggestion in _suggestions)
                    ActionChip(
                      label: Text(l10n.jobLabel(suggestion.titleKey)),
                      onPressed: () => _apply(l10n, suggestion),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.whatNeedsDoing,
                hintText: l10n.whatNeedsDoingHint,
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue:
                  kMaintenanceIntervals.contains(_intervalMonths)
                      ? _intervalMonths
                      : null,
              decoration: InputDecoration(labelText: l10n.howOften),
              items: [
                for (final months in kMaintenanceIntervals)
                  DropdownMenuItem(
                    value: months,
                    child: Text(l10n.intervalLabel(months)),
                  ),
              ],
              onChanged:
                  (v) => setState(() => _intervalMonths = v ?? _intervalMonths),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.requiredForWarranty),
              subtitle: Text(
                l10n.requiredForWarrantyHint,
                style: const TextStyle(fontSize: 12),
              ),
              value: _requiredForWarranty,
              onChanged: (v) => setState(() => _requiredForWarranty = v),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _title.text.trim().isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_isEditing ? l10n.save : l10n.addJob),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
