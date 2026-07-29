import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/ui/widgets/asset_thumbnail.dart';
import 'package:itemize/l10n/app_localizations.dart';

/// Asks how long each of [assets] is covered for, returning the ones the owner
/// gave a date for. Returns an empty list if they skipped.
///
/// Quick Capture exists to get a whole room catalogued in one pass, and the
/// price of that speed is that every item it saves has no warranty date and
/// no maintenance schedule -- the two things the Care tab is built around.
/// Asked as fields on the add screen, that question is the first thing
/// people skip; asked here, immediately after a batch that took thirty
/// seconds to shoot, it can stay one tap because the photo and the name are
/// already on screen and there is nothing left to type.
///
/// Nothing is written here -- no database, no provider. The caller saves the
/// returned [Asset] copies, which keeps the save path in one place and this
/// screen trivial to test.
Future<List<Asset>> showWarrantyPrompt(
  BuildContext context, {
  required List<Asset> assets,
}) async {
  final result = await Navigator.of(context).push<List<Asset>>(
    MaterialPageRoute(builder: (_) => WarrantyPromptScreen(assets: assets)),
  );
  return result ?? const [];
}

/// A tap on one row of the prompt. Kept separate from the resulting date so
/// "no warranty" (an answer) and "not answered yet" (silence) are never
/// confused with each other.
enum WarrantyChoice { oneYear, twoYears, threeYears, none, other }

/// The date warranty cover lasting [years] from [purchaseDate] runs out.
///
/// Counted from `purchaseDate`, not from today -- Quick Capture happens to
/// set both to the same day for items being catalogued right now, but an
/// item later corrected to its real purchase date must still compute
/// correctly from that date. `DateTime(y, m, d)` silently rolls an
/// out-of-range day into the next month (29 Feb plus one year would
/// otherwise become 1 Mar in a non-leap target year), so the day is pinned
/// back to the last real day of the target month instead of letting that
/// rollover happen.
DateTime addWarrantyYears(DateTime purchaseDate, int years) {
  final targetYear = purchaseDate.year + years;
  // Day 0 of the following month is the calendar's own answer to "how many
  // days does this month have", leap years included, without a table of
  // month lengths to keep in sync.
  final daysInTargetMonth = DateTime(targetYear, purchaseDate.month + 1, 0).day;
  final day =
      purchaseDate.day > daysInTargetMonth ? daysInTargetMonth : purchaseDate.day;
  return DateTime(targetYear, purchaseDate.month, day);
}

/// The concrete expiry a tap on the prompt resolves to, or null when the row
/// has no date to show yet -- "None" was chosen, or "Other date" is waiting
/// on a pick.
DateTime? warrantyExpiryForChoice(
  WarrantyChoice choice,
  DateTime purchaseDate, {
  DateTime? customDate,
}) {
  switch (choice) {
    case WarrantyChoice.oneYear:
      return addWarrantyYears(purchaseDate, 1);
    case WarrantyChoice.twoYears:
      return addWarrantyYears(purchaseDate, 2);
    case WarrantyChoice.threeYears:
      return addWarrantyYears(purchaseDate, 3);
    case WarrantyChoice.none:
      return null;
    case WarrantyChoice.other:
      return customDate;
  }
}

/// One-tap sweep through a freshly captured batch, asking only how long each
/// item is covered for. See [showWarrantyPrompt] for why this screen exists.
class WarrantyPromptScreen extends StatefulWidget {
  const WarrantyPromptScreen({super.key, required this.assets});

  final List<Asset> assets;

  @override
  State<WarrantyPromptScreen> createState() => _WarrantyPromptScreenState();
}

class _WarrantyPromptScreenState extends State<WarrantyPromptScreen> {
  // Keyed by index into widget.assets rather than by Asset.id so two drafts
  // that briefly share an id during a batch save can never collide here.
  // Absent from the map is "untouched"; present with any value, including
  // WarrantyChoice.none, is "the owner looked at this one".
  final Map<int, WarrantyChoice> _choice = {};
  final Map<int, DateTime> _customDates = {};

  DateTime? _dateFor(int index) => warrantyExpiryForChoice(
    _choice[index] ?? WarrantyChoice.none,
    widget.assets[index].purchaseDate,
    customDate: _customDates[index],
  );

  /// Rows that will actually be handed back to the caller. "None" is a real
  /// answer but produces no date, so it is deliberately left out of both
  /// this count and the save -- unchanged from how the row arrived.
  int get _savableCount => List.generate(widget.assets.length, (i) {
    if (!_choice.containsKey(i)) return null;
    return _dateFor(i);
  }).whereType<DateTime>().length;

  Future<void> _pickOtherDate(int index) async {
    final asset = widget.assets[index];
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDates[index] ?? addWarrantyYears(asset.purchaseDate, 2),
      firstDate: asset.purchaseDate,
      lastDate: DateTime(asset.purchaseDate.year + 50),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _choice[index] = WarrantyChoice.other;
      _customDates[index] = picked;
    });
  }

  void _save() {
    final updated = <Asset>[];
    for (var i = 0; i < widget.assets.length; i++) {
      if (!_choice.containsKey(i)) continue;
      final date = _dateFor(i);
      if (date == null) continue;
      updated.add(widget.assets[i].copyWith(warrantyExpiry: date));
    }
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.warrantyPromptTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.warrantyPromptBody,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.assets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildRow(index, l10n),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      // The unembarrassing way out: skipping returns exactly
                      // what saving zero rows would, but does not make anyone
                      // tap through five empty rows to get there.
                      onPressed: () => Navigator.pop(context, <Asset>[]),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.warrantyPromptSkip),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _savableCount == 0
                            ? l10n.save
                            : l10n.saveCount(_savableCount),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int index, AppLocalizations l10n) {
    final asset = widget.assets[index];
    final choice = _choice[index];
    final thumbnail = AssetThumbnail.provider(
      context,
      asset.imagePath,
      width: 56,
      height: 56,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  image:
                      thumbnail != null
                          ? DecorationImage(image: thumbnail, fit: BoxFit.cover)
                          : null,
                ),
                child:
                    thumbnail == null
                        ? const Icon(Icons.image, size: 20, color: Colors.grey)
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  asset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _yearChip(index, l10n, WarrantyChoice.oneYear, 1, choice),
              // Visually the loudest option on the row. Germany -- the target
              // market -- gives every consumer purchase a statutory two-year
              // Gewährleistung (BGB §438) regardless of what any manufacturer
              // offers, so two years is the answer that is true for almost
              // everything someone photographs, and the one tap should look
              // like the obvious tap.
              _yearChip(
                index,
                l10n,
                WarrantyChoice.twoYears,
                2,
                choice,
                prominent: true,
              ),
              _yearChip(index, l10n, WarrantyChoice.threeYears, 3, choice),
              _plainChip(
                index,
                l10n.warrantyNoneOption,
                WarrantyChoice.none,
                choice,
              ),
              _otherDateChip(index, l10n, choice),
            ],
          ),
        ],
      ),
    );
  }

  Widget _yearChip(
    int index,
    AppLocalizations l10n,
    WarrantyChoice option,
    int years,
    WarrantyChoice? current, {
    bool prominent = false,
  }) {
    return _choiceChip(
      label: l10n.warrantyYears(years),
      selected: current == option,
      prominent: prominent,
      onTap: () => setState(() => _choice[index] = option),
    );
  }

  Widget _plainChip(
    int index,
    String label,
    WarrantyChoice option,
    WarrantyChoice? current,
  ) {
    return _choiceChip(
      label: label,
      selected: current == option,
      onTap: () => setState(() => _choice[index] = option),
    );
  }

  Widget _otherDateChip(int index, AppLocalizations l10n, WarrantyChoice? current) {
    final picked = _customDates[index];
    final label =
        current == WarrantyChoice.other && picked != null
            ? DateFormat.yMMMd().format(picked)
            : l10n.warrantyOtherDate;

    return _choiceChip(
      label: label,
      selected: current == WarrantyChoice.other,
      onTap: () => _pickOtherDate(index),
    );
  }

  /// A shared chip look so the one row that is meant to stand out --
  /// [prominent] -- does so by being visibly branded even before it is
  /// picked, rather than by breaking the row's layout to say so in words.
  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool prominent = false,
  }) {
    final foreground =
        selected
            ? Colors.white
            : prominent
            ? AppTheme.primaryBlue
            : AppTheme.textPrimary;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: prominent ? AppTheme.primaryBlue.withAlpha(28) : null,
      side: prominent && !selected ? const BorderSide(color: AppTheme.primaryBlue) : null,
      labelStyle: TextStyle(
        color: foreground,
        fontWeight: prominent || selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
