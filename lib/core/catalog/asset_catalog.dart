import 'package:flutter/material.dart';

/// A stock item people can pick instead of photographing their own.
///
/// Artwork is drawn from the bundled Material Icons font rather than shipped as
/// image files, so the catalog costs nothing in app size and carries no stock
/// photo licensing.
class CatalogItem {
  final String label;
  final IconData icon;
  final String category;

  const CatalogItem({
    required this.label,
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
  CatalogItem(label: 'Sofa', icon: Icons.weekend, category: 'Living Room'),
  CatalogItem(label: 'Armchair', icon: Icons.chair, category: 'Living Room'),
  CatalogItem(
    label: 'Coffee Table',
    icon: Icons.table_restaurant,
    category: 'Living Room',
  ),
  CatalogItem(label: 'Television', icon: Icons.tv, category: 'Living Room'),
  CatalogItem(label: 'Floor Lamp', icon: Icons.light, category: 'Living Room'),
  CatalogItem(label: 'Bookshelf', icon: Icons.shelves, category: 'Living Room'),
  CatalogItem(label: 'Speaker', icon: Icons.speaker, category: 'Living Room'),

  // Kitchen
  CatalogItem(label: 'Refrigerator', icon: Icons.kitchen, category: 'Kitchen'),
  CatalogItem(label: 'Microwave', icon: Icons.microwave, category: 'Kitchen'),
  CatalogItem(
    label: 'Coffee Maker',
    icon: Icons.coffee_maker,
    category: 'Kitchen',
  ),
  CatalogItem(label: 'Blender', icon: Icons.blender, category: 'Kitchen'),
  CatalogItem(
    label: 'Dining Table',
    icon: Icons.table_bar,
    category: 'Kitchen',
  ),
  CatalogItem(
    label: 'Dishwasher',
    icon: Icons.countertops,
    category: 'Kitchen',
  ),

  // Bedroom
  CatalogItem(label: 'Bed', icon: Icons.king_bed, category: 'Bedroom'),
  CatalogItem(label: 'Wardrobe', icon: Icons.checkroom, category: 'Bedroom'),
  CatalogItem(
    label: 'Washing Machine',
    icon: Icons.local_laundry_service,
    category: 'Bedroom',
  ),
  CatalogItem(label: 'Air Purifier', icon: Icons.air, category: 'Bedroom'),
  CatalogItem(label: 'Iron', icon: Icons.iron, category: 'Bedroom'),

  // Office
  CatalogItem(label: 'Laptop', icon: Icons.laptop_mac, category: 'Office'),
  CatalogItem(label: 'Monitor', icon: Icons.desktop_mac, category: 'Office'),
  CatalogItem(label: 'Desk', icon: Icons.desk, category: 'Office'),
  CatalogItem(label: 'Office Chair', icon: Icons.chair_alt, category: 'Office'),
  CatalogItem(label: 'Printer', icon: Icons.print, category: 'Office'),
  CatalogItem(label: 'Router', icon: Icons.router, category: 'Office'),
  CatalogItem(label: 'Keyboard', icon: Icons.keyboard, category: 'Office'),
  CatalogItem(label: 'Headphones', icon: Icons.headphones, category: 'Office'),

  // Garage
  CatalogItem(
    label: 'Bicycle',
    icon: Icons.directions_bike,
    category: 'Garage',
  ),
  CatalogItem(label: 'Car', icon: Icons.directions_car, category: 'Garage'),
  CatalogItem(label: 'Power Tools', icon: Icons.handyman, category: 'Garage'),
  CatalogItem(label: 'Toolbox', icon: Icons.build, category: 'Garage'),
  CatalogItem(label: 'Lawn Mower', icon: Icons.grass, category: 'Garage'),

  // Other
  CatalogItem(label: 'Camera', icon: Icons.camera_alt, category: 'Other'),
  CatalogItem(label: 'Watch', icon: Icons.watch, category: 'Other'),
  CatalogItem(label: 'Phone', icon: Icons.phone_iphone, category: 'Other'),
  CatalogItem(label: 'Tablet', icon: Icons.tablet_mac, category: 'Other'),
  CatalogItem(label: 'Books', icon: Icons.menu_book, category: 'Other'),
  CatalogItem(
    label: 'Gym Equipment',
    icon: Icons.fitness_center,
    category: 'Other',
  ),
  CatalogItem(label: 'Luggage', icon: Icons.luggage, category: 'Other'),
  CatalogItem(label: 'Musical Instrument', icon: Icons.piano, category: 'Other'),
];
