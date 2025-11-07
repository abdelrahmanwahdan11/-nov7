import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/item_card_3d.dart';
import '../../widgets/skeleton_box.dart';
import '../../core/utils/responsive.dart';

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

  List<Item> _applyFilters(List<Item> items, Set<String> activeFilters) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.condition.toLowerCase().contains(query);
      final matchesFilter = activeFilters.isEmpty || activeFilters.contains(item.category);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Widget _buildGrid(List<Item> items, {bool showSkeleton = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = responsiveCrossAxisCount(constraints.maxWidth);
        final aspectRatio = responsiveChildAspectRatio(crossAxisCount);
        final delegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: aspectRatio,
        );
        if (showSkeleton) {
          final skeletonCount = (crossAxisCount * 3).clamp(4, 12);
          return GridView.builder(
            controller: _scrollController,
            gridDelegate: delegate,
            itemCount: skeletonCount,
            itemBuilder: (_, __) => const SkeletonBox(),
          );
        }
        return GridView.builder(
          controller: _scrollController,
          gridDelegate: delegate,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ItemCard3D(item: item, itemsController: widget.itemsController);
          },
        );
      },
    );
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
              Expanded(
                child: ValueListenableBuilder<List<Item>>(
                  valueListenable: widget.itemsController.visibleItemsListenable,
                  builder: (context, items, _) {
                    final categories = items.map((e) => e.category).toSet().toList()
                      ..sort();
                    final activeFilters = _selectedFilters
                        .where((element) => categories.contains(element))
                        .toSet();
                    final filtered = _applyFilters(items, activeFilters);
                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilterChips(
                            labels: categories,
                            selectedValues: activeFilters,
                            onSelected: (values) => setState(() => _selectedFilters
                              ..clear()
                              ..addAll(values)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: filtered.isEmpty && !_showSkeleton
                              ? Center(child: Text(loc.translate('emptyState')))
                              : _showSkeleton
                                  ? _buildGrid(filtered.isEmpty ? items : filtered, showSkeleton: true)
                                  : _buildGrid(filtered),
                        ),
                      ],
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
