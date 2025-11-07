import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/item_card_3d.dart';
import '../../widgets/skeleton_box.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.itemsController});

  final ItemsController itemsController;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  final _selectedFilters = <String>{};
  late final ScrollController _scrollController;
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      widget.itemsController.fetchNextPage();
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _showSkeleton = true);
    await widget.itemsController.refresh(resetPage: true);
    if (mounted) {
      setState(() => _showSkeleton = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  List<Item> _applyFilters(List<Item> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.condition.toLowerCase().contains(query);
      final matchesFilter = _selectedFilters.isEmpty || _selectedFilters.contains(item.category);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('catalog')),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(IconlyLight.search),
                  hintText: loc.translate('search'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChips(
                  labels: const ['Mugs', 'Beans', 'Accessories'],
                  selectedValues: _selectedFilters,
                  onSelected: (values) => setState(() => _selectedFilters
                    ..clear()
                    ..addAll(values)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<List<Item>>(
                  valueListenable: widget.itemsController.visibleItemsListenable,
                  builder: (context, items, _) {
                    final filtered = _applyFilters(items);
                    if (filtered.isEmpty && !_showSkeleton) {
                      return Center(
                        child: Text(loc.translate('emptyState')),
                      );
                    }
                    if (_showSkeleton) {
                      return GridView.builder(
                        controller: _scrollController,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: 6,
                        itemBuilder: (_, __) => const SkeletonBox(),
                      );
                    }
                    return GridView.builder(
                      controller: _scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ItemCard3D(item: item, itemsController: widget.itemsController);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
