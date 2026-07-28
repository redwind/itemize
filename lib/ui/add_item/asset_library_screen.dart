import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:itemize/core/catalog/asset_catalog.dart';
import 'package:itemize/core/theme/app_theme.dart';

/// Grid of stock item pictures. Pops with the chosen [CatalogItem], or null.
class AssetLibraryScreen extends StatefulWidget {
  /// Room the item is being filed under, preselected when it has entries.
  final String? initialCategory;

  const AssetLibraryScreen({super.key, this.initialCategory});

  @override
  State<AssetLibraryScreen> createState() => _AssetLibraryScreenState();
}

class _AssetLibraryScreenState extends State<AssetLibraryScreen> {
  static const _allFilter = 'All';

  final _searchController = TextEditingController();
  late String _filter;
  String _query = '';

  List<String> get _categories => [
    _allFilter,
    ...catalogTints.keys.where(
      (category) => assetCatalog.any((item) => item.category == category),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final requested = widget.initialCategory;
    _filter =
        (requested != null &&
                assetCatalog.any((item) => item.category == requested))
            ? requested
            : _allFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CatalogItem> get _visibleItems {
    final query = _query.trim().toLowerCase();
    return assetCatalog.where((item) {
      // A search should reach the whole catalog, not just the active room.
      if (query.isNotEmpty) {
        return item.label.toLowerCase().contains(query);
      }
      return _filter == _allFilter || item.category == _filter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Photo Library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Search items...',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: _query.isEmpty && _filter == category,
                  onSelected: (_) {
                    setState(() {
                      _filter = category;
                      _query = '';
                      _searchController.clear();
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            child:
                items.isEmpty
                    ? const Center(child: Text('No matching items'))
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: items.length,
                      itemBuilder:
                          (context, index) => _buildTile(items[index]),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(CatalogItem item) {
    final tint = catalogTints[item.category] ?? catalogTints['Other']!;

    return GestureDetector(
      onTap: () => Navigator.pop(context, item),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: tint,
                ),
              ),
              child: Icon(
                item.icon,
                size: 44,
                color: AppTheme.textPrimary.withAlpha(210),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
