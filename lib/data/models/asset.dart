import 'dart:convert';

/// Where an item is kept.
const List<String> kAssetRooms = [
  'Living Room',
  'Kitchen',
  'Bedroom',
  'Office',
  'Garage',
  'Other',
];

/// What kind of thing an item is.
///
/// Kept separate from the room because a contents claim is settled category by
/// category, and policies routinely cap the payout per category -- jewellery
/// especially. "Three rings in the bedroom" and "three rings" are different
/// questions, and only the second one is the one an adjuster asks.
const List<String> kAssetCategories = [
  'Electronics',
  'Furniture',
  'Appliances',
  'Jewelry & Watches',
  'Clothing',
  'Tools & Equipment',
  'Sports & Outdoors',
  'Kitchenware',
  'Art & Collectibles',
  'Other',
];

/// Carried by rows that predate the room/category split, whose single field
/// held the room. Nothing invents a category for them; the owner chooses.
const String kUncategorized = 'Uncategorized';

class Asset {
  final String id;
  final String name;
  final double price;
  final String currency;

  /// Where the item is kept. See [kAssetRooms].
  final String room;

  /// What kind of thing it is. See [kAssetCategories].
  final String category;

  /// Every photo of the item, cover first.
  ///
  /// A claim is argued with pictures, and one picture rarely shows the item,
  /// the serial plate and the damage all at once.
  final List<String> photoPaths;

  /// Proof of purchase, held apart from [photoPaths] so a report can give it a
  /// page of its own rather than bury it among product shots.
  final String? receiptPath;

  final String? barcode;

  /// The three things an insurer asks for by name when identifying an item.
  final String? serialNumber;
  final String? brand;
  final String? model;

  final String? notes;
  final DateTime purchaseDate;
  final DateTime? warrantyExpiry;
  final bool isFavorite;

  /// When the owner last confirmed this entry is still true.
  ///
  /// An inventory written in one year and claimed on in another is half wrong
  /// by then — things get sold, given away, replaced, and nobody comes back to
  /// say so. Recording when each entry was last looked at is what lets the app
  /// ask, and an inventory nobody has checked is one an insurer can argue with.
  final DateTime? lastReviewedAt;

  Asset({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.room,
    required this.category,
    this.photoPaths = const [],
    this.receiptPath,
    this.barcode,
    this.serialNumber,
    this.brand,
    this.model,
    this.notes,
    required this.purchaseDate,
    this.warrantyExpiry,
    this.isFavorite = false,
    this.lastReviewedAt,
  });

  /// The cover photo, or '' when the item has none.
  String get imagePath => photoPaths.isEmpty ? '' : photoPaths.first;

  bool get hasWarranty => warrantyExpiry != null;

  bool get isWarrantyExpired =>
      warrantyExpiry != null && warrantyExpiry!.isBefore(DateTime.now());

  Asset copyWith({
    String? id,
    String? name,
    double? price,
    String? currency,
    String? room,
    String? category,
    List<String>? photoPaths,
    String? receiptPath,
    String? barcode,
    String? serialNumber,
    String? brand,
    String? model,
    String? notes,
    DateTime? purchaseDate,
    DateTime? warrantyExpiry,
    bool? isFavorite,
    DateTime? lastReviewedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      room: room ?? this.room,
      category: category ?? this.category,
      photoPaths: photoPaths ?? this.photoPaths,
      receiptPath: receiptPath ?? this.receiptPath,
      barcode: barcode ?? this.barcode,
      serialNumber: serialNumber ?? this.serialNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      notes: notes ?? this.notes,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      isFavorite: isFavorite ?? this.isFavorite,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'currency': currency,
      'room': room,
      'category': category,
      // The v1 column, still fed with the cover photo. SQLite below 3.35 --
      // which older Androids ship -- cannot drop a column, and this one is NOT
      // NULL, so it has to stay; better kept truthful than left to rot.
      'imagePath': imagePath,
      'photoPaths': jsonEncode(photoPaths),
      'receiptPath': receiptPath,
      'barcode': barcode,
      'serialNumber': serialNumber,
      'brand': brand,
      'model': model,
      'notes': notes,
      'purchaseDate': purchaseDate.toIso8601String(),
      'warrantyExpiry': warrantyExpiry?.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      currency: map['currency'] as String,
      // Rows written before the split kept the room in `category`. The
      // migration moves it across; this is the belt to that pair of braces.
      room: (map['room'] ?? map['category'] ?? 'Other') as String,
      category: (map['category'] ?? kUncategorized) as String,
      photoPaths: _decodePhotoPaths(map['photoPaths'], map['imagePath']),
      receiptPath: _emptyToNull(map['receiptPath']),
      barcode: _emptyToNull(map['barcode']),
      serialNumber: _emptyToNull(map['serialNumber']),
      brand: _emptyToNull(map['brand']),
      model: _emptyToNull(map['model']),
      notes: _emptyToNull(map['notes']),
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      warrantyExpiry:
          map['warrantyExpiry'] != null
              ? DateTime.parse(map['warrantyExpiry'] as String)
              : null,
      isFavorite: map['isFavorite'] == 1,
      lastReviewedAt:
          map['lastReviewedAt'] != null
              ? DateTime.parse(map['lastReviewedAt'] as String)
              : null,
    );
  }

  /// Reads the photo list, falling back to the single v1 `imagePath`.
  ///
  /// The upgrade deliberately leaves `photoPaths` null on existing rows instead
  /// of backfilling it, so this fallback is the normal path for anything added
  /// before multi-photo, not an error case.
  static List<String> _decodePhotoPaths(Object? encoded, Object? legacyCover) {
    if (encoded is String && encoded.isNotEmpty) {
      final decoded = jsonDecode(encoded);
      if (decoded is List) {
        return decoded.whereType<String>().where((p) => p.isNotEmpty).toList();
      }
    }
    final cover = legacyCover as String?;
    if (cover == null || cover.isEmpty) return const [];
    return [cover];
  }

  /// Treats a blank column as absent, so "no serial number" has one
  /// representation rather than two that read differently in the UI.
  static String? _emptyToNull(Object? value) {
    final text = value as String?;
    if (text == null || text.trim().isEmpty) return null;
    return text;
  }

  String toJson() => json.encode(toMap());

  factory Asset.fromJson(String source) => Asset.fromMap(json.decode(source));

  @override
  String toString() =>
      'Asset(id: $id, name: $name, price: $price, currency: $currency, '
      'room: $room, category: $category, photos: ${photoPaths.length}, '
      'serialNumber: $serialNumber, brand: $brand, model: $model, '
      'purchaseDate: $purchaseDate, warrantyExpiry: $warrantyExpiry)';
}
