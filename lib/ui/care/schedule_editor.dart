import 'package:flutter/material.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:uuid/uuid.dart';

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
  List<({String title, int months, bool warranty})> get _suggestions =>
      kSuggestedMaintenance[widget.asset.category] ?? const [];

  void _apply(({String title, int months, bool warranty}) suggestion) {
    setState(() {
      _title.text = suggestion.title;
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit job' : 'New job',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (!_isEditing && _suggestions.isNotEmpty) ...[
              const Text(
                'Common for this kind of thing',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final suggestion in _suggestions)
                    ActionChip(
                      label: Text(suggestion.title),
                      onPressed: () => _apply(suggestion),
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
              decoration: const InputDecoration(
                labelText: 'What needs doing',
                hintText: 'Replace water filter',
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue:
                  kMaintenanceIntervals.values.contains(_intervalMonths)
                      ? _intervalMonths
                      : null,
              decoration: const InputDecoration(labelText: 'How often'),
              items: [
                for (final entry in kMaintenanceIntervals.entries)
                  DropdownMenuItem(value: entry.value, child: Text(entry.key)),
              ],
              onChanged:
                  (v) => setState(() => _intervalMonths = v ?? _intervalMonths),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Required to keep the warranty valid'),
              subtitle: const Text(
                'You will be warned if this lapses while the item is still '
                'covered.',
                style: TextStyle(fontSize: 12),
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
                child: Text(_isEditing ? 'Save' : 'Add job'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
