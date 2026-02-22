import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/ocr_service.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/providers/pro_provider.dart';
import 'package:itemize/ui/settings/paywall_screen.dart';
import 'package:uuid/uuid.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

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
  final _categoryController = TextEditingController(text: 'Living Room');
  final _barcodeController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  DateTime? _warrantyExpiry;
  String? _imagePath;
  bool _isFavorite = false;
  bool _isProcessingAI = false;

  final List<String> _rooms = [
    'Living Room',
    'Kitchen',
    'Bedroom',
    'Office',
    'Garage',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    _ocrService.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _scanBarcode() async {
    final proState = ref.read(proProvider);
    final proNotifier = ref.read(proProvider.notifier);

    if (!proState.canScan) {
      _showLimitReachedDialog(
        "Daily Scan Limit Reached",
        "Upgrade to Pro for unlimited AI scans.",
      );
      return;
    }

    // ... (existing image picker logic) ...
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image == null) return;

    if (!proState.isPro) {
      await proNotifier.incrementScanCount();
    }

    // ... (rest of logic)

    setState(() => _isProcessingAI = true);

    try {
      final barcode = await _ocrService.scanBarcode(image.path);
      if (barcode != null) {
        _barcodeController.text = barcode;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Barcode Found!")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No barcode found")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _scanReceipt() async {
    final proState = ref.read(proProvider);
    final proNotifier = ref.read(proProvider.notifier);

    if (!proState.canScan) {
      _showLimitReachedDialog(
        "Daily Scan Limit Reached",
        "Upgrade to Pro for unlimited AI scans.",
      );
      return;
    }

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image == null) return;

    if (!proState.isPro) {
      await proNotifier.incrementScanCount();
    }

    setState(() => _isProcessingAI = true);

    try {
      final data = await _ocrService.scanReceipt(image.path);

      if (data['name'] != null) _nameController.text = data['name'];
      if (data['price'] != null && data['price'] != 0.0)
        _priceController.text = data['price'].toString();

      if (data['date'] != null) {
        // Basic parser placeholder
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt Scanned! Verify details.")),
      );

      setState(() {
        _imagePath = image.path;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    // Check Asset Limit
    final proState = ref.read(proProvider);
    final assets = ref.read(assetListProvider).asData?.value ?? [];

    if (!proState.isPro && assets.length >= kFreeAssetLimit) {
      _showLimitReachedDialog(
        "Asset Limit Reached",
        "Free version is limited to $kFreeAssetLimit items. Upgrade to Pro for unlimited storage.",
      );
      return;
    }

    if (_imagePath == null) {
      // Allow no image? Or require it?
      // Let's allow no image but warn?
    }

    final settings = ref.read(settingsProvider);
    final newAsset = Asset(
      id: const Uuid().v4(),
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      currency: settings.currencyCode,
      category: _categoryController.text,
      imagePath: _imagePath ?? '',
      barcode:
          _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
      purchaseDate: _purchaseDate,
      warrantyExpiry: _warrantyExpiry,
      isFavorite: _isFavorite,
    );

    await ref.read(assetListProvider.notifier).addAsset(newAsset);
    await HapticFeedback.mediumImpact();

    if (mounted) Navigator.pop(context);
  }

  void _showLimitReachedDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
    );
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
                  leading: const Icon(Icons.qr_code),
                  title: const Text('Scan Barcode'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scanBarcode();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Scan Receipt (OCR)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scanReceipt();
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Asset'),
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
                      // Image Section
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            image:
                                _imagePath != null
                                    ? DecorationImage(
                                      image: FileImage(File(_imagePath!)),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              _imagePath == null
                                  ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        'Tap to add photo',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Smart Scan Button
                      ElevatedButton.icon(
                        onPressed: _showSmartScanOptions,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Smart Scan (AI)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.purple, // Differentiate AI action
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator:
                            (v) => v!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Price & Currency
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price',
                                prefixText: settings.currencySymbol,
                                prefixStyle: const TextStyle(fontSize: 16),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Currency Display
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

                      // Category
                      DropdownButtonFormField<String>(
                        value:
                            _rooms.contains(_categoryController.text)
                                ? _categoryController.text
                                : _rooms.first,
                        items:
                            _rooms
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => _categoryController.text = v!,
                        decoration: const InputDecoration(
                          labelText: 'Category/Room',
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Barcode
                      TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode / Serial',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dates
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Purchase Date: ${DateFormat.yMMMd().format(_purchaseDate)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
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
                        title: Text(
                          _warrantyExpiry == null
                              ? 'Set Warranty Expiry'
                              : 'Warranty Expires: ${DateFormat.yMMMd().format(_warrantyExpiry!)}',
                        ),
                        trailing: const Icon(Icons.security),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _purchaseDate.add(
                              const Duration(days: 365),
                            ),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setState(() => _warrantyExpiry = d);
                        },
                      ),

                      // Favorite
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
}
