import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itemize/core/utils/amount.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/l10n/domain_labels.dart';

/// One photographed thing, waiting to be named.
class _Draft {
  final String photoPath;
  final TextEditingController name = TextEditingController();
  final TextEditingController price = TextEditingController();

  _Draft(this.photoPath);

  bool get isNamed => name.text.trim().isNotEmpty;

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

/// Photograph a room in one pass, then name everything sitting down.
///
/// The ordinary add screen asks for a name, a price, a room and a category
/// before it will take a second photograph, which is fine for one item and
/// unbearable for the eighty in a living room. Someone starting an inventory
/// faces that wall immediately and usually stops. Here the camera stays open,
/// and the typing happens once, afterwards, in one list.
class QuickCaptureScreen extends ConsumerStatefulWidget {
  const QuickCaptureScreen({super.key});

  @override
  ConsumerState<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends ConsumerState<QuickCaptureScreen> {
  final _imagePicker = ImagePicker();
  final List<_Draft> _drafts = [];

  String _room = kAssetRooms.first;
  String _category = kAssetCategories.first;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  int get _namedCount => _drafts.where((d) => d.isNamed).length;

  /// Keeps the camera open until the user backs out of it.
  ///
  /// image_picker returns after every shot, so the loop is what makes this feel
  /// like a camera rather than a form. Cancelling ends it.
  Future<void> _capture() async {
    while (mounted) {
      final XFile? shot = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        imageQuality: 88,
      );
      if (shot == null) break;

      final stored = await ImageStorage.saveFile(shot.path);
      if (!mounted) return;
      setState(() => _drafts.add(_Draft(stored)));
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> _addFromLibrary() async {
    final shots = await _imagePicker.pickMultiImage(
      maxWidth: 2048,
      imageQuality: 88,
    );
    if (shots.isEmpty) return;

    final stored = <String>[];
    for (final shot in shots) {
      stored.add(await ImageStorage.saveFile(shot.path));
    }
    if (!mounted) return;
    setState(() => _drafts.addAll(stored.map(_Draft.new)));
  }

  Future<void> _saveNamed() async {
    final ready = _drafts.where((d) => d.isNamed).toList();
    if (ready.isEmpty) return;

    setState(() => _isSaving = true);

    final settings = ref.read(settingsProvider);
    final currency = settings.currencyCode;
    final notifier = ref.read(assetListProvider.notifier);
    final now = DateTime.now();

    for (final draft in ready) {
      await notifier.addAsset(
        Asset(
          id: const Uuid().v4(),
          name: draft.name.text.trim(),
          // Optional here, so an unreadable amount is the same as none.
          price:
              parseAmount(draft.price.text, locale: settings.languageCode) ?? 0,
          currency: currency,
          room: _room,
          category: _category,
          photoPaths: [draft.photoPath],
          // Today, because that is the honest answer for something being
          // catalogued now rather than bought now. It is on the item's own
          // screen to correct.
          purchaseDate: now,
          // Photographed and named a moment ago, so it has been reviewed more
          // recently than any prompt could ask for. Left unset, a null date
          // reads as never-reviewed, and the batch the welcome screen walks
          // everyone through would land on the Care tab as a list of entries to
          // go back and check.
          lastReviewedAt: now,
        ),
      );
    }

    if (!mounted) return;

    final leftover = _drafts.length - ready.length;
    setState(() {
      for (final draft in ready) {
        draft.dispose();
        _drafts.remove(draft);
      }
      _isSaving = false;
    });

    await HapticFeedback.mediumImpact();
    if (!mounted) return;

    if (leftover == 0) {
      Navigator.pop(context);
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    // The unnamed ones stay put rather than being thrown away with the
    // photographs the user just walked around taking.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.savedNeedNames(ready.length, leftover))),
    );
  }

  Future<void> _removeDraft(int index) async {
    final draft = _drafts[index];
    setState(() => _drafts.removeAt(index));
    draft.dispose();
    // Safe to delete here, unlike elsewhere in the app: this photograph was
    // taken moments ago and has never belonged to a saved item.
    await ImageStorage.delete(draft.photoPath);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quickCaptureTitle),
        actions: [
          TextButton(
            onPressed: _namedCount == 0 || _isSaving ? null : _saveNamed,
            child: Text(_namedCount == 0 ? l10n.save : l10n.saveCount(_namedCount)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRoomAndCategory(l10n),
          const Divider(height: 1),
          Expanded(
            child:
                _drafts.isEmpty
                    ? _buildEmpty(l10n)
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _drafts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder:
                          (context, index) =>
                              _buildDraftRow(index, settings, l10n),
                    ),
          ),
          if (_isSaving) const LinearProgressIndicator(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _capture,
                      icon: const Icon(Icons.photo_camera),
                      label: Text(l10n.keepShooting),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _isSaving ? null : _addFromLibrary,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    child: const Icon(Icons.photo_library_outlined),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomAndCategory(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _room,
              isExpanded: true,
              isDense: true,
              items:
                  kAssetRooms
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(l10n.roomLabel(r)),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _room = v ?? _room),
              decoration: InputDecoration(
                labelText: l10n.room,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              isDense: true,
              items:
                  kAssetCategories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(l10n.categoryLabel(c)),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
              decoration: InputDecoration(
                labelText: l10n.category,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.burst_mode, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.quickCaptureEmptyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.quickCaptureEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftRow(
    int index,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    final draft = _drafts[index];
    final file = ImageStorage.resolve(draft.photoPath);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            image:
                file != null
                    ? DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              TextField(
                controller: draft.name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                // Redraws the Save count in the app bar as names are typed.
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.itemName,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: draft.price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.price,
                  isDense: true,
                  prefixText: settings.currencySymbol,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.discardPhoto,
          onPressed: _isSaving ? null : () => _removeDraft(index),
        ),
      ],
    );
  }
}
