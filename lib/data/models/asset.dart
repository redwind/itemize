import 'dart:convert';

class Asset {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String category;
  final String imagePath;
  final String? barcode;
  final DateTime purchaseDate;
  final DateTime? warrantyExpiry;
  final bool isFavorite;

  Asset({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.category,
    required this.imagePath,
    this.barcode,
    required this.purchaseDate,
    this.warrantyExpiry,
    this.isFavorite = false,
  });

  Asset copyWith({
    String? id,
    String? name,
    double? price,
    String? currency,
    String? category,
    String? imagePath,
    String? barcode,
    DateTime? purchaseDate,
    DateTime? warrantyExpiry,
    bool? isFavorite,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      barcode: barcode ?? this.barcode,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'currency': currency,
      'category': category,
      'imagePath': imagePath,
      'barcode': barcode,
      'purchaseDate': purchaseDate.toIso8601String(),
      'warrantyExpiry': warrantyExpiry?.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      currency: map['currency'],
      category: map['category'],
      imagePath: map['imagePath'],
      barcode: map['barcode'],
      purchaseDate: DateTime.parse(map['purchaseDate']),
      warrantyExpiry: map['warrantyExpiry'] != null ? DateTime.parse(map['warrantyExpiry']) : null,
      isFavorite: map['isFavorite'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory Asset.fromJson(String source) => Asset.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Asset(id: $id, name: $name, price: $price, currency: $currency, category: $category, imagePath: $imagePath, barcode: $barcode, purchaseDate: $purchaseDate, warrantyExpiry: $warrantyExpiry, isFavorite: $isFavorite)';
  }
}
