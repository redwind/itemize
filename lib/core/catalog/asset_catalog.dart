import 'package:flutter/material.dart';

/// A stock item people can pick instead of photographing their own.
///
/// Artwork is drawn from the bundled Material Icons font rather than shipped as
/// image files, so the catalog costs nothing in app size and carries no stock
/// photo licensing.
class CatalogItem {
  /// Translation key, resolved through `AppLocalizations.catalogLabel`.
  ///
  /// A key rather than a word: the label is shown in a picker and then offered
  /// as the item's name, both of which have to read in the owner's language,
  /// while the `category` beside it stays the English value the database is
  /// keyed on.
  final String labelKey;
  final IconData icon;
  final String category;

  const CatalogItem({
    required this.labelKey,
    required this.icon,
    required this.category,
  });
}

/// Background tints, keyed by the same room names the rest of the app uses.
const Map<String, List<Color>> catalogTints = {
  'Living Room': [Color(0xFFFFEEE1), Color(0xFFFFD4BA)],
  'Kitchen': [Color(0xFFE0F6EC), Color(0xFFBCE6D4)],
  'Bedroom': [Color(0xFFEAE7FB), Color(0xFFD0CAF6)],
  'Office': [Color(0xFFE0ECFF), Color(0xFFBCD5FB)],
  'Garage': [Color(0xFFF1F2F6), Color(0xFFD4D9E2)],
  'Other': [Color(0xFFFFE9F1), Color(0xFFFACBDD)],
};

const List<CatalogItem> assetCatalog = [
  // Living Room
  CatalogItem(labelKey: 'sofa', icon: Icons.weekend, category: 'Living Room'),
  CatalogItem(labelKey: 'armchair', icon: Icons.chair, category: 'Living Room'),
  CatalogItem(
    labelKey: 'coffeeTable',
    icon: Icons.table_restaurant,
    category: 'Living Room',
  ),
  CatalogItem(labelKey: 'television', icon: Icons.tv, category: 'Living Room'),
  CatalogItem(labelKey: 'floorLamp', icon: Icons.light, category: 'Living Room'),
  CatalogItem(labelKey: 'bookshelf', icon: Icons.shelves, category: 'Living Room'),
  CatalogItem(labelKey: 'speaker', icon: Icons.speaker, category: 'Living Room'),

  // Kitchen
  CatalogItem(labelKey: 'refrigerator', icon: Icons.kitchen, category: 'Kitchen'),
  CatalogItem(labelKey: 'microwave', icon: Icons.microwave, category: 'Kitchen'),
  CatalogItem(
    labelKey: 'coffeeMaker',
    icon: Icons.coffee_maker,
    category: 'Kitchen',
  ),
  CatalogItem(labelKey: 'blender', icon: Icons.blender, category: 'Kitchen'),
  CatalogItem(
    labelKey: 'diningTable',
    icon: Icons.table_bar,
    category: 'Kitchen',
  ),
  CatalogItem(
    labelKey: 'dishwasher',
    icon: Icons.countertops,
    category: 'Kitchen',
  ),

  // Bedroom
  CatalogItem(labelKey: 'bed', icon: Icons.king_bed, category: 'Bedroom'),
  CatalogItem(labelKey: 'wardrobe', icon: Icons.checkroom, category: 'Bedroom'),
  CatalogItem(
    labelKey: 'washingMachine',
    icon: Icons.local_laundry_service,
    category: 'Bedroom',
  ),
  CatalogItem(labelKey: 'airPurifier', icon: Icons.air, category: 'Bedroom'),
  CatalogItem(labelKey: 'iron', icon: Icons.iron, category: 'Bedroom'),

  // Office
  CatalogItem(labelKey: 'laptop', icon: Icons.laptop_mac, category: 'Office'),
  CatalogItem(labelKey: 'monitor', icon: Icons.desktop_mac, category: 'Office'),
  CatalogItem(labelKey: 'desk', icon: Icons.desk, category: 'Office'),
  CatalogItem(labelKey: 'officeChair', icon: Icons.chair_alt, category: 'Office'),
  CatalogItem(labelKey: 'printer', icon: Icons.print, category: 'Office'),
  CatalogItem(labelKey: 'router', icon: Icons.router, category: 'Office'),
  CatalogItem(labelKey: 'keyboard', icon: Icons.keyboard, category: 'Office'),
  CatalogItem(labelKey: 'headphones', icon: Icons.headphones, category: 'Office'),

  // Garage
  CatalogItem(
    labelKey: 'bicycle',
    icon: Icons.directions_bike,
    category: 'Garage',
  ),
  CatalogItem(labelKey: 'car', icon: Icons.directions_car, category: 'Garage'),
  CatalogItem(labelKey: 'powerTools', icon: Icons.handyman, category: 'Garage'),
  CatalogItem(labelKey: 'toolbox', icon: Icons.build, category: 'Garage'),
  CatalogItem(labelKey: 'lawnMower', icon: Icons.grass, category: 'Garage'),

  // Other
  CatalogItem(labelKey: 'camera', icon: Icons.camera_alt, category: 'Other'),
  CatalogItem(labelKey: 'watch', icon: Icons.watch, category: 'Other'),
  CatalogItem(labelKey: 'phone', icon: Icons.phone_iphone, category: 'Other'),
  CatalogItem(labelKey: 'tablet', icon: Icons.tablet_mac, category: 'Other'),
  CatalogItem(labelKey: 'books', icon: Icons.menu_book, category: 'Other'),
  CatalogItem(
    labelKey: 'gymEquipment',
    icon: Icons.fitness_center,
    category: 'Other',
  ),
  CatalogItem(labelKey: 'luggage', icon: Icons.luggage, category: 'Other'),
  CatalogItem(labelKey: 'musicalInstrument', icon: Icons.piano, category: 'Other'),
];
