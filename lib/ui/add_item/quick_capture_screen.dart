import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';

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

    final currency = ref.read(settingsProvider).currencyCode;
    final notifier = ref.read(assetListProvider.notifier);
    final now = DateTime.now();

    for (final draft in ready) {
      await notifier.addAsset(
        Asset(
          id: const Uuid().v4(),
          name: draft.name.text.trim(),
          price: double.tryParse(draft.price.text.trim()) ?? 0,
          currency: currency,
          room: _room,
          category: _category,
          photoPaths: [draft.photoPath],
          // Today, because that is the honest answer for something being
          // catalogued now rather than bought now. It is on the item's own
          // screen to correct.
          purchaseDate: now,
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

    // The unnamed ones stay put rather than being thrown away with the
    // photographs the user just walked around taking.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${ready.length} saved. $leftover still needs a name.',
        ),
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Capture'),
        actions: [
          TextButton(
            onPressed: _namedCount == 0 || _isSaving ? null : _saveNamed,
            child: Text(_namedCount == 0 ? 'Save' : 'Save $_namedCount'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRoomAndCategory(),
          const Divider(height: 1),
          Expanded(
            child:
                _drafts.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _drafts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder:
                          (context, index) => _buildDraftRow(index, settings),
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
                      label: const Text('Keep Shooting'),
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

  Widget _buildRoomAndCategory() {
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
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
              onChanged: (v) => setState(() => _room = v ?? _room),
              decoration: const InputDecoration(
                labelText: 'Room',
                border: OutlineInputBorder(),
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
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.burst_mode, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Photograph everything first',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'The camera stays open between shots. Walk the room, then come '
              'back here and name what you photographed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftRow(int index, AppSettings settings) {
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
                decoration: const InputDecoration(
                  labelText: 'Name',
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
                  labelText: 'Price',
                  isDense: true,
                  prefixText: settings.currencySymbol,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Discard this photo',
          onPressed: _isSaving ? null : () => _removeDraft(index),
        ),
      ],
    );
  }
}
