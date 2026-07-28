import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:itemize/core/catalog/asset_catalog.dart';
import 'package:itemize/core/utils/catalog_image.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/core/utils/ocr_service.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/add_item/asset_library_screen.dart';
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
  final _ocrService = OCRService(); // In a real app, use a provider
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
    _ocrService.close();
    super.dispose();
  }

  /// image_picker hands back a file in a temporary directory that iOS is free
  /// to purge, so copy it somewhere the asset can keep referring to.
  Future<String> _persistImage(XFile image) =>
      ImageStorage.saveFile(image.path);

  // --- Photos -------------------------------------------------------------

  Future<_PhotoAction?> _choosePhotoSource() {
    return showModalBottomSheet<_PhotoAction>(
      context: context,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Photo'),
                  onTap: () => Navigator.pop(sheetContext, _PhotoAction.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Photos'),
                  onTap:
                      () => Navigator.pop(sheetContext, _PhotoAction.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Pick a Stock Image'),
                  subtitle: const Text('Chairs, tables, appliances and more'),
                  onTap:
                      () => Navigator.pop(sheetContext, _PhotoAction.catalog),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _addPhoto() async {
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
          _nameController.text = picked.label;
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
                    title: const Text('Make Cover Photo'),
                    subtitle: const Text('Shown in lists and reports'),
                    onTap:
                        () => Navigator.pop(sheetContext, _PhotoTap.makeCover),
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove Photo'),
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
    final image = await _startScan();
    if (image == null || !mounted) return;

    setState(() => _isProcessingAI = true);

    try {
      final barcode = await _ocrService.scanBarcode(image.path);
      if (!mounted) return;

      if (barcode == null) {
        _showSnack("No barcode found");
        return;
      }

      _barcodeController.text = barcode;
      _showSnack("Barcode saved: $barcode");
    } catch (e) {
      if (mounted) _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  /// Reads the rating plate and fills in what it says.
  Future<void> _scanNameplate() async {
    final image = await _startScan();
    if (image == null || !mounted) return;

    setState(() => _isProcessingAI = true);

    try {
      final info = await _ocrService.scanNameplate(image.path);
      if (!mounted) return;

      if (info.isEmpty) {
        _showSnack(
          "Nothing readable on that label. Try filling the frame with it.",
        );
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

      _showSnack(
        "Read ${info.fieldCount} field${info.fieldCount == 1 ? '' : 's'}. "
        "Please check them against the label.",
      );
    } catch (e) {
      if (mounted) _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _scanReceipt() async {
    final image = await _startScan();
    if (image == null || !mounted) return;

    setState(() => _isProcessingAI = true);

    try {
      final data = await _ocrService.scanReceipt(image.path);
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

      _showSnack("Receipt scanned. Please check the details.");
    } catch (e) {
      if (mounted) _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  // --- Saving -------------------------------------------------------------

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    if (_category == kUncategorized) {
      _showSnack("Please choose a category.");
      return;
    }

    // No ceiling on how much can be recorded, deliberately.
    //
    // Capping stored items charged for the work the owner does rather than for
    // anything the app provides, and it bit hardest at the moment the app was
    // finally being used properly. Pro is charged for what comes back out --
    // the insurance report, the backup, unlimited lookups -- which is reached
    // once the inventory is worth having, not while it is being built.

    final settings = ref.read(settingsProvider);
    final asset = Asset(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
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
    await HapticFeedback.mediumImpact();

    if (mounted) Navigator.pop(context, asset);
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
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.label_important_outline),
                  title: const Text('Scan Label / Nameplate'),
                  subtitle: const Text(
                    'Reads the brand, model and serial number',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scanNameplate();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Scan Receipt'),
                  subtitle: const Text('Fills in the price and purchase date'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scanReceipt();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: const Text('Scan Barcode'),
                  subtitle: const Text('Records the product code'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Asset' : 'Add New Asset'),
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
                      _buildPhotoSection(),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: _showSmartScanOptions,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Smart Scan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
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
                                labelText: 'Price',
                                prefixText: settings.currencySymbol,
                                prefixStyle: const TextStyle(fontSize: 16),
                              ),
                              validator:
                                  (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Required'
                                          : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Currency',
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
                                          child: Text(r),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _room = v ?? _room),
                              decoration: const InputDecoration(
                                labelText: 'Room',
                                prefixIcon: Icon(Icons.meeting_room),
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
                                  const DropdownMenuItem(
                                    value: kUncategorized,
                                    child: Text(
                                      kUncategorized,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ...kAssetCategories.map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                ),
                              ],
                              onChanged:
                                  (v) => setState(
                                    () => _category = v ?? _category,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildSectionLabel(
                        'Identification',
                        'What an insurer asks for to prove which unit you owned.',
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brandController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                                prefixIcon: Icon(Icons.storefront),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              decoration: const InputDecoration(
                                labelText: 'Model',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _serialController,
                        decoration: const InputDecoration(
                          labelText: 'Serial Number',
                          prefixIcon: Icon(Icons.pin),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionLabel('Purchase', null),
                      const SizedBox(height: 4),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Purchase Date'),
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
                        title: const Text('Warranty Expiry'),
                        subtitle: Text(
                          _warrantyExpiry == null
                              ? 'Not set'
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
                      _buildReceiptTile(),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          alignLabelWithHint: true,
                          hintText: 'Condition, where it was bought, extras...',
                        ),
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mark as Favorite'),
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

  Widget _buildPhotoSection() {
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
                return _buildAddPhotoTile(tileSize);
              }
              return _buildPhotoTile(index, tileSize);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _photoPaths.isEmpty
              ? 'Add photos — the first one becomes the cover.'
              : '${_photoPaths.length} photo${_photoPaths.length == 1 ? '' : 's'}. Tap one to remove it or make it the cover.',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAddPhotoTile(double size) {
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(int index, double size) {
    final file = ImageStorage.resolve(_photoPaths[index]);

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
                  file != null
                      ? DecorationImage(
                        image: FileImage(file),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                file == null
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
                child: const Text(
                  'Cover',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReceiptTile() {
    final attached = _receiptPath != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.receipt_long,
        color: attached ? Colors.green : Colors.grey,
      ),
      title: const Text('Receipt'),
      subtitle: Text(attached ? 'Attached' : 'Proof of purchase for a claim'),
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
