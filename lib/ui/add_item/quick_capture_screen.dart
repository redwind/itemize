import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventa/core/utils/amount.dart';
import 'package:inventa/core/utils/free_tier.dart';
import 'package:inventa/core/utils/image_storage.dart';
import 'package:inventa/core/utils/reminders.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/providers/asset_provider.dart';
import 'package:inventa/providers/pro_provider.dart';
import 'package:inventa/providers/settings_provider.dart';
import 'package:inventa/ui/add_item/warranty_prompt_screen.dart';
import 'package:inventa/ui/settings/paywall_screen.dart';
import 'package:inventa/ui/widgets/asset_thumbnail.dart';
import 'package:uuid/uuid.dart';
import 'package:inventa/l10n/app_localizations.dart';
import 'package:inventa/l10n/domain_labels.dart';

/// One photographed thing, waiting to be named.
class _Draft {
  final String photoPath;
  final TextEditingController name = TextEditingController();
  final TextEditingController price = TextEditingController();

  /// Its own, seeded from the batch's default and changeable per row.
  ///
  /// Category is not decoration: it keys the depreciation table, so a sofa
  /// filed as Electronics is written off over five years instead of fifteen
  /// and the "estimated value today" on the paid report drifts wrong month by
  /// month. One category for a whole living room guaranteed that for
  /// everything in it but the television.
  String category;

  _Draft(this.photoPath, this.category);

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
      setState(() => _drafts.add(_Draft(stored, _category)));
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
    setState(() => _drafts.addAll(stored.map((p) => _Draft(p, _category))));
  }

  Future<void> _saveNamed() async {
    final named = _drafts.where((d) => d.isNamed).toList();
    if (named.isEmpty) return;

    // How much of the room fits before the free ceiling. Worked out up front,
    // for the whole batch, rather than discovered on the thirteenth item after
    // the owner has walked round photographing thirty.
    //
    // Counted from storage rather than from assetCountProvider, which answers
    // zero while its underlying future is still in flight -- and a gate that
    // answers zero is a gate that is open.
    final count = await ref.read(assetRepositoryProvider).countAssets();
    if (!mounted) return;

    final fits = fitBatch(
      batchSize: named.length,
      currentCount: count,
      isPro: ref.read(proProvider).isPro,
    );
    if (fits == 0) {
      await _showLimitReached();
      return;
    }
    final ready = named.take(fits).toList();
    final capped = named.length - ready.length;

    setState(() => _isSaving = true);

    final settings = ref.read(settingsProvider);
    final currency = settings.currencyCode;
    final notifier = ref.read(assetListProvider.notifier);
    final now = DateTime.now();

    // Written as one batch rather than one at a time. Each save reloads the
    // whole table and rebuilds the reminder schedule from scratch, so saving a
    // forty-item room item by item meant forty reloads and some two thousand
    // platform calls -- and left the room half-stored if anything failed
    // part-way.
    final stored = [
      for (final draft in ready)
        Asset(
          id: const Uuid().v4(),
          name: draft.name.text.trim(),
          // Optional here, so an unreadable amount is the same as none.
          price:
              parseAmount(draft.price.text, locale: settings.languageCode) ?? 0,
          currency: currency,
          room: _room,
          category: draft.category,
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
    ];
    final saved = await notifier.addAssets(stored);

    if (!mounted) return;

    // Nothing was stored, so nothing is cleared. The drafts and their
    // photographs stay exactly where they were and the owner can try again,
    // rather than being congratulated on a room that was never saved.
    if (!saved) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.batchSaveFailed),
        ),
      );
      return;
    }

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

    await _askAboutWarranties(stored);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    if (capped > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.freeLimitBatchCapped(ready.length, kFreeItemLimit, capped),
          ),
        ),
      );
      return;
    }

    if (leftover == 0) {
      Navigator.pop(context);
      return;
    }

    // The unnamed ones stay put rather than being thrown away with the
    // photographs the user just walked around taking.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.savedNeedNames(ready.length, leftover))),
    );
  }

  /// Asks how long the batch is covered for, and records the answers.
  ///
  /// This is where the app stops being a list and starts being worth opening
  /// again. Quick Capture saves items with no warranty date and no schedules,
  /// so the funnel that onboards nearly everyone was producing a Care tab that
  /// would say nothing for as long as they owned the phone -- the one feature
  /// the app is actually sold on, never seen. Asked here, once, right after
  /// the photographs, where the answer is still in the owner's head.
  Future<void> _askAboutWarranties(List<Asset> stored) async {
    if (stored.isEmpty) return;

    final dated = await showWarrantyPrompt(context, assets: stored);
    if (dated.isEmpty || !mounted) return;

    final notifier = ref.read(assetListProvider.notifier);
    for (final asset in dated) {
      await notifier.updateAsset(asset);
    }

    // The first warranty date recorded is the first thing the app will have to
    // say later, and asking to be allowed to say it only makes sense once one
    // exists. Only the first of these prompts.
    await Reminders.instance.ensurePermission();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.warrantyPromptSaved(dated.length),
        ),
      ),
    );
  }

  /// The wall, with the way past it.
  Future<void> _showLimitReached() async {
    final l10n = AppLocalizations.of(context)!;
    final upgrade = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.freeLimitTitle(kFreeItemLimit)),
            content: Text(l10n.freeLimitBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.upgradeToPro),
              ),
            ],
          ),
    );
    if (upgrade == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      // Straight back into the save they were denied, with the photographs and
      // the typing still there.
      if (mounted && ref.read(proProvider).isPro) await _saveNamed();
    }
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Named as defaults now that each row carries its own category. The
          // room stays one per batch, because a batch is a room -- that is
          // what walking round with the camera means.
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.batchDefaults,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              if (_drafts.any((d) => d.category != _category))
                TextButton(
                  onPressed:
                      _isSaving
                          ? null
                          : () => setState(() {
                            for (final draft in _drafts) {
                              draft.category = _category;
                            }
                          }),
                  child: Text(l10n.applyToAll),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _buildDefaultsRow(l10n),
        ],
      ),
    );
  }

  Widget _buildDefaultsRow(AppLocalizations l10n) {
    return Row(
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
    final thumbnail = AssetThumbnail.provider(
      context,
      draft.photoPath,
      width: 72,
      height: 72,
    );

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
                thumbnail != null
                    ? DecorationImage(image: thumbnail, fit: BoxFit.cover)
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
                  ),
                  const SizedBox(width: 8),
                  // Per row, because the depreciation table is keyed on it and
                  // a whole living room filed as one category is a whole
                  // living room valued wrongly.
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: draft.category,
                      isExpanded: true,
                      isDense: true,
                      style: Theme.of(context).textTheme.bodyMedium,
                      items:
                          kAssetCategories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    l10n.categoryLabel(c),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          _isSaving
                              ? null
                              : (v) => setState(
                                () => draft.category = v ?? draft.category,
                              ),
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                ],
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
