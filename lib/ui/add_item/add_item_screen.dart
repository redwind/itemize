import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:inventa/core/catalog/asset_catalog.dart';
import 'package:inventa/core/utils/amount.dart';
import 'package:inventa/core/utils/free_tier.dart';
import 'package:inventa/core/utils/catalog_image.dart';
import 'package:inventa/core/utils/image_storage.dart';
import 'package:inventa/core/utils/ocr_service.dart';
import 'package:inventa/core/utils/reminders.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/l10n/app_localizations.dart';
import 'package:inventa/l10n/domain_labels.dart';
import 'package:inventa/providers/asset_provider.dart';
import 'package:inventa/providers/pro_provider.dart';
import 'package:inventa/providers/settings_provider.dart';
import 'package:inventa/ui/add_item/asset_library_screen.dart';
import 'package:inventa/ui/settings/paywall_screen.dart';
import 'package:inventa/ui/widgets/asset_thumbnail.dart';
import 'package:uuid/uuid.dart';

enum _PhotoAction { camera, gallery, catalog }

enum _PhotoTap { makeCover, remove }

/// Creates an item, or edits [existing] when one is handed in.
///
/// One screen serves both because the fields, the pickers and the validation
/// are identical; a separate edit screen would be this file with the save call
/// swapped, and would drift from it.
class AddItemScreen extends ConsumerStatefulWidget {
  final Asset? existing;

  const AddItemScreen({super.key, this.existing});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  /// Built on first use, not on first build.
  ///
  /// Constructing it spins up ML Kit's text recogniser and barcode scanner,
  /// which most visits to this screen never ask for -- and which nothing but a
  /// real device can provide, so eager construction also made the screen
  /// impossible to put in a widget test.
  OCRService? _ocr;
  OCRService get _ocrService => _ocr ??= OCRService();
  final _imagePicker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _serialController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _notesController = TextEditingController();

  String _room = kAssetRooms.first;
  String _category = kAssetCategories.first;
  DateTime _purchaseDate = DateTime.now();
  DateTime? _warrantyExpiry;
  List<String> _photoPaths = [];
  String? _receiptPath;
  bool _isFavorite = false;
  bool _isProcessingAI = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;

    _nameController.text = existing.name;
    _priceController.text = existing.price.toString();
    _barcodeController.text = existing.barcode ?? '';
    _serialController.text = existing.serialNumber ?? '';
    _brandController.text = existing.brand ?? '';
    _modelController.text = existing.model ?? '';
    _notesController.text = existing.notes ?? '';
    _room =
        kAssetRooms.contains(existing.room) ? existing.room : kAssetRooms.last;
    // Rows carried over from before the room/category split have no real
    // category. Offering the list unselected would fail validation on save, so
    // show the placeholder and make the owner choose.
    _category =
        kAssetCategories.contains(existing.category)
            ? existing.category
            : kUncategorized;
    _purchaseDate = existing.purchaseDate;
    _warrantyExpiry = existing.warrantyExpiry;
    _photoPaths = List<String>.from(existing.photoPaths);
    _receiptPath = existing.receiptPath;
    _isFavorite = existing.isFavorite;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _serialController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    // Only if it was ever built; asking for it here would construct one purely
    // in order to close it.
    _ocr?.close();
    super.dispose();
  }

  /// image_picker hands back a file in a temporary directory that iOS is free
  /// to purge, so copy it somewhere the asset can keep referring to.
  Future<String> _persistImage(XFile image) =>
      ImageStorage.saveFile(image.path);

  // --- Photos -------------------------------------------------------------

  Future<_PhotoAction?> _choosePhotoSource() {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<_PhotoAction>(
      context: context,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l10n.takePhoto),
                  onTap: () => Navigator.pop(sheetContext, _PhotoAction.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.chooseFromPhotos),
                  onTap:
                      () => Navigator.pop(sheetContext, _PhotoAction.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(l10n.pickStockImage),
                  subtitle: Text(l10n.pickStockImageHint),
                  onTap:
                      () => Navigator.pop(sheetContext, _PhotoAction.catalog),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final action = await _choosePhotoSource();
    if (action == null) return;

    if (action == _PhotoAction.catalog) {
      if (!mounted) return;
      final picked = await Navigator.of(context).push<CatalogItem>(
        MaterialPageRoute(
          builder: (_) => AssetLibraryScreen(initialCategory: _room),
        ),
      );
      if (picked == null) return;

      final rendered = await CatalogImage.render(picked);
      if (!mounted) return;
      setState(() {
        _photoPaths = [..._photoPaths, rendered];
        // Naming the item is the next thing they'd do anyway, so offer the
        // catalog label -- but never overwrite something already typed.
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = l10n.catalogLabel(picked.labelKey);
        }
      });
      return;
    }

    final XFile? image = await _imagePicker.pickImage(
      source:
          action == _PhotoAction.camera
              ? ImageSource.camera
              : ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 88,
    );
    if (image == null) return;

    final stored = await _persistImage(image);
    if (!mounted) return;
    setState(() => _photoPaths = [..._photoPaths, stored]);
  }

  Future<void> _tapPhoto(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final isCover = index == 0;
    final action = await showModalBottomSheet<_PhotoTap>(
      context: context,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCover)
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: Text(l10n.makeCoverPhoto),
                    subtitle: Text(l10n.makeCoverPhotoHint),
                    onTap:
                        () => Navigator.pop(sheetContext, _PhotoTap.makeCover),
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.removePhoto),
                  onTap: () => Navigator.pop(sheetContext, _PhotoTap.remove),
                ),
              ],
            ),
          ),
    );
    if (action == null) return;

    setState(() {
      final next = [..._photoPaths];
      final path = next.removeAt(index);
      if (action == _PhotoTap.makeCover) next.insert(0, path);
      _photoPaths = next;
    });
  }

  Future<void> _attachReceipt() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      imageQuality: 88,
    );
    if (image == null) return;
    final stored = await _persistImage(image);
    if (!mounted) return;
    setState(() => _receiptPath = stored);
  }

  // --- Scanning -----------------------------------------------------------

  /// Opens the camera for one of the scanners.
  ///
  /// No quota, no gate. Every scanner here runs on the device against the
  /// bundled recognizer, so a scan costs nothing to perform and there is
  /// nothing to ration.
  Future<XFile?> _startScan() =>
      _imagePicker.pickImage(source: ImageSource.camera);

  Future<void> _scanBarcode() async {
    final l10n = AppLocalizations.of(context)!;
    final image = await _startScan();
    if (image == null || !mounted) return;

    setState(() => _isProcessingAI = true);

    try {
      final barcode = await _ocrService.scanBarcode(image.path);
      if (!mounted) return;

      if (barcode == null) {
        _showSnack(l10n.noBarcodeFound);
        return;
      }

      _barcodeController.text = barcode;
      _showSnack(l10n.barcodeSaved(barcode));
    } catch (e) {
      if (mounted) _showSnack(l10n.genericError('$e'));
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  /// Reads the rating plate and fills in what it says.
  Future<void> _scanNameplate() async {
    final l10n = AppLocalizations.of(context)!;
    final image = await _startScan();
    if (image == null || !mounted) return;

    setState(() => _isProcessingAI = true);

    try {
      final info = await _ocrService.scanNameplate(image.path);
      if (!mounted) return;

      if (info.isEmpty) {
        _showSnack(l10n.nameplateUnreadable);
        return;
      }

      // Only into empty boxes. Whatever the owner typed is the better record --
      // they are holding the thing; the camera is guessing at small print.
      void fill(TextEditingController controller, String? value) {
        if (value == null || value.isEmpty) return;
        if (controller.text.trim().isNotEmpty) return;
        controller.text = value;
      }

      fill(_brandController, info.brand);
      fill(_modelController, info.model);
      fill(_serialController, info.serialNumber);
      setState(() {});

      _showSnack(l10n.nameplateRead(info.fieldCount));
    } catch (e) {
      if (mounted) _showSnack(l10n.genericError('$e'));
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _scanReceipt() async {
    final l10n = AppLocalizations.of(context)!;
    final image = await _startScan();
    if (image == null || !mounted) return;

    setState(() => _isProcessingAI = true);

    try {
      final data = await _ocrService.scanReceipt(
        image.path,
        locale: ref.read(settingsProvider).languageCode,
      );
      // Kept as the receipt rather than as the item's photo. Replacing the
      // cover here, as this used to, left the owner with a picture of a till
      // roll where the picture of the thing they own should be.
      final stored = await _persistImage(image);
      if (!mounted) return;

      if (data['name'] != null) _nameController.text = data['name'];
      if (data['price'] != null && data['price'] != 0.0) {
        _priceController.text = data['price'].toString();
      }
      final scannedDate = data['date'] as DateTime?;

      setState(() {
        _receiptPath = stored;
        if (scannedDate != null) _purchaseDate = scannedDate;
      });

      _showSnack(l10n.receiptScanned);
    } catch (e) {
      if (mounted) _showSnack(l10n.genericError('$e'));
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  // --- Saving -------------------------------------------------------------

  Future<void> _saveAsset() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_category == kUncategorized) {
      _showSnack(l10n.chooseCategory);
      return;
    }

    // The free ceiling applies to new items only.
    //
    // Editing is never blocked: someone who is over the limit -- which a
    // restored backup alone can do -- must still be able to correct what they
    // already own. Turning them away from their own data would be the app
    // holding it hostage, and it is not what is being sold.
    if (!_isEditing && !await _mayAddOneMore()) return;

    final settings = ref.read(settingsProvider);
    final asset = Asset(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      price:
          parseAmount(_priceController.text, locale: settings.languageCode) ??
          0.0,
      currency: settings.currencyCode,
      room: _room,
      category: _category,
      photoPaths: _photoPaths,
      receiptPath: _receiptPath,
      barcode: _trimmedOrNull(_barcodeController),
      serialNumber: _trimmedOrNull(_serialController),
      brand: _trimmedOrNull(_brandController),
      model: _trimmedOrNull(_modelController),
      notes: _trimmedOrNull(_notesController),
      purchaseDate: _purchaseDate,
      warrantyExpiry: _warrantyExpiry,
      isFavorite: _isFavorite,
      // Saving is confirming. Somebody who has just looked at the thing and
      // typed its details has reviewed it more thoroughly than any prompt
      // could ask for, so the clock starts here rather than at the first nudge.
      lastReviewedAt: DateTime.now(),
    );

    final notifier = ref.read(assetListProvider.notifier);
    if (_isEditing) {
      await notifier.updateAsset(asset);
    } else {
      await notifier.addAsset(asset);
    }

    // The first warranty date recorded is the first thing the app has to say
    // later, and the moment the request for permission to say it makes sense.
    // Asked after the save so a refusal never costs the owner their typing.
    if (_warrantyExpiry != null) {
      await Reminders.instance.ensurePermission();
    }

    await HapticFeedback.mediumImpact();

    if (mounted) Navigator.pop(context, asset);
  }

  /// Whether there is room for one more, offering the way past when there is
  /// not.
  ///
  /// The wall is shown with what has already been recorded intact and named as
  /// such: the fear at this moment is that paying is the price of keeping what
  /// you typed, and it is not.
  Future<bool> _mayAddOneMore() async {
    // Counted from storage, not from assetCountProvider. That provider is
    // derived from a FutureProvider, so the first read of it on a cold start
    // answers zero while the load is still in flight -- and a gate that
    // answers zero is a gate that is open. This is the number the decision has
    // to be made on, so it is asked for directly.
    final count = await ref.read(assetRepositoryProvider).countAssets();
    if (!mounted) return false;

    final remaining = remainingFreeSlots(
      currentCount: count,
      isPro: ref.read(proProvider).isPro,
    );
    if (remaining == null || remaining > 0) return true;

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
      // Straight back to saving if they bought it, rather than making them
      // find the button again on a screen they have already filled in.
      if (mounted && ref.read(proProvider).isPro) return true;
    }
    return false;
  }

  String? _trimmedOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSmartScanOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.label_important_outline),
                  title: Text(l10n.scanNameplate),
                  subtitle: Text(l10n.scanNameplateHint),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scanNameplate();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: Text(l10n.scanReceipt),
                  subtitle: Text(l10n.scanReceiptHint),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scanReceipt();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: Text(l10n.scanBarcode),
                  subtitle: Text(l10n.scanBarcodeHint),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scanBarcode();
                  },
                ),
              ],
            ),
          ),
    );
  }

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editItemTitle : l10n.addItemTitle),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveAsset),
        ],
      ),
      body:
          _isProcessingAI
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPhotoSection(l10n),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: _showSmartScanOptions,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(l10n.smartScan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: l10n.itemName,
                          prefixIcon: const Icon(Icons.label),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? l10n.nameRequired
                                    : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.price,
                                prefixText: settings.currencySymbol,
                                prefixStyle: const TextStyle(fontSize: 16),
                              ),
                              // Rejects what it cannot read rather than
                              // letting it through to be stored as zero.
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return l10n.fieldRequired;
                                }
                                return parseAmount(
                                          v,
                                          locale: settings.languageCode,
                                        ) ==
                                        null
                                    ? l10n.invalidAmount
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.currency,
                              ),
                              child: Text(
                                settings.currencyCode,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _room,
                              isExpanded: true,
                              items:
                                  kAssetRooms
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(l10n.roomLabel(r)),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _room = v ?? _room),
                              decoration: InputDecoration(
                                labelText: l10n.room,
                                prefixIcon: const Icon(Icons.meeting_room),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              isExpanded: true,
                              items: [
                                // Only offered while it is what the item
                                // actually is; saving with it selected is
                                // refused, so it cannot become a resting state.
                                if (_category == kUncategorized)
                                  DropdownMenuItem(
                                    value: kUncategorized,
                                    child: Text(
                                      l10n.uncategorized,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ...kAssetCategories.map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(l10n.categoryLabel(c)),
                                  ),
                                ),
                              ],
                              onChanged:
                                  (v) => setState(
                                    () => _category = v ?? _category,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.category,
                                prefixIcon: const Icon(Icons.category),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildSectionLabel(
                        l10n.identification,
                        l10n.identificationHint,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brandController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: l10n.brand,
                                prefixIcon: const Icon(Icons.storefront),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              decoration: InputDecoration(
                                labelText: l10n.model,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _serialController,
                        decoration: InputDecoration(
                          labelText: l10n.serialNumber,
                          prefixIcon: const Icon(Icons.pin),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: l10n.barcode,
                          prefixIcon: const Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionLabel(l10n.purchase, null),
                      const SizedBox(height: 4),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: Text(l10n.purchaseDate),
                        subtitle: Text(
                          DateFormat.yMMMd().format(_purchaseDate),
                        ),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _purchaseDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _purchaseDate = d);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.security),
                        title: Text(l10n.warrantyExpiry),
                        subtitle: Text(
                          _warrantyExpiry == null
                              ? l10n.notSet
                              : DateFormat.yMMMd().format(_warrantyExpiry!),
                        ),
                        trailing:
                            _warrantyExpiry == null
                                ? null
                                : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed:
                                      () => setState(
                                        () => _warrantyExpiry = null,
                                      ),
                                ),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate:
                                _warrantyExpiry ??
                                _purchaseDate.add(const Duration(days: 365)),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(DateTime.now().year + 30),
                          );
                          if (d != null) setState(() => _warrantyExpiry = d);
                        },
                      ),
                      _buildReceiptTile(l10n),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.notes,
                          alignLabelWithHint: true,
                          hintText: l10n.notesHint,
                        ),
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.markAsFavorite),
                        value: _isFavorite,
                        onChanged: (v) => setState(() => _isFavorite = v),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionLabel(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoSection(AppLocalizations l10n) {
    const double tileSize = 104;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: tileSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photoPaths.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == _photoPaths.length) {
                return _buildAddPhotoTile(tileSize, l10n);
              }
              return _buildPhotoTile(index, tileSize, l10n);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _photoPaths.isEmpty
              ? l10n.photosEmptyHint
              : l10n.photosCount(_photoPaths.length),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAddPhotoTile(double size, AppLocalizations l10n) {
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              l10n.addPhoto,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(int index, double size, AppLocalizations l10n) {
    final image = AssetThumbnail.provider(
      context,
      _photoPaths[index],
      width: size,
      height: size,
    );

    return GestureDetector(
      onTap: () => _tapPhoto(index),
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              image:
                  image != null
                      ? DecorationImage(image: image, fit: BoxFit.cover)
                      : null,
            ),
            child:
                image == null
                    ? const Icon(Icons.broken_image, color: Colors.grey)
                    : null,
          ),
          if (index == 0)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.coverBadge,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReceiptTile(AppLocalizations l10n) {
    final attached = _receiptPath != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.receipt_long,
        color: attached ? Colors.green : Colors.grey,
      ),
      title: Text(l10n.receipt),
      subtitle: Text(attached ? l10n.receiptAttached : l10n.receiptHint),
      trailing:
          attached
              ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _receiptPath = null),
              )
              : const Icon(Icons.add_a_photo, size: 20),
      onTap: _attachReceipt,
    );
  }
}
