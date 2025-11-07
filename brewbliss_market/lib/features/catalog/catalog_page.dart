import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../widgets/item_card_3d.dart';
import '../../widgets/skeleton_box.dart';
import 'filters_sheet.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.itemsController});

  final ItemsController itemsController;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  late final ScrollController _scrollController;
  late FilterOptions _filters;
  late SortMode _sortMode;

  @override
  void initState() {
    super.initState();
    _filters = widget.itemsController.filters;
    _sortMode = widget.itemsController.sortMode;
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 220) {
      widget.itemsController.paginate();
    }
  }

  Future<void> _onRefresh() => widget.itemsController.refresh(resetPage: true);

  Future<void> _openFilters() async {
    final items = widget.itemsController.allItems;
    final categories = items.map((item) => item.category).toSet().toList()..sort();
    final conditions = items.map((item) => item.condition).toSet().toList()..sort();
    final prices = items.where((item) => item.price != null).map((item) => item.price!).toList();
    final minPrice = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.isEmpty ? minPrice + 1 : prices.reduce((a, b) => a > b ? a : b);
    final result = await showFiltersSheet(
      context: context,
      current: _filters,
      categories: categories,
      conditions: conditions,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    if (result != null) {
      setState(() => _filters = result);
      widget.itemsController.updateFilters(result);
    }
  }

  void _changeSort(SortMode mode) {
    setState(() => _sortMode = mode);
    widget.itemsController.setSortMode(mode);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('catalog')),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.filter),
            onPressed: _openFilters,
            tooltip: loc.translate('filters'),
          ),
          PopupMenuButton<SortMode>(
            icon: const Icon(IconlyLight.arrow_down_2),
            initialValue: _sortMode,
            onSelected: _changeSort,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortMode.newest,
                child: Text(loc.translate('newCollection')),
              ),
              PopupMenuItem(
                value: SortMode.priceLowToHigh,
                child: Text('${loc.translate('price')} ↑'),
              ),
              PopupMenuItem(
                value: SortMode.priceHighToLow,
                child: Text('${loc.translate('price')} ↓'),
              ),
            ],
          ),
        ],
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
                onChanged: widget.itemsController.search,
              ),
              const SizedBox(height: 12),
              _ActiveFiltersBanner(filters: _filters, onClear: () {
                setState(() => _filters = FilterOptions.empty());
                widget.itemsController.clearFilters();
              }),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<List<Item>>(
                  valueListenable: widget.itemsController.visibleItemsListenable,
                  builder: (context, items, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: widget.itemsController.loadingListenable,
                      builder: (context, loading, __) {
                        if (loading && items.isEmpty) {
                          return _SkeletonGrid(controller: _scrollController);
                        }
                        if (items.isEmpty) {
                          return Center(child: Text(loc.translate('emptyState')));
                        }
                        return GridView.builder(
                          controller: _scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ItemCard3D(item: item, itemsController: widget.itemsController);
                          },
                        );
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

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
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
}

class _ActiveFiltersBanner extends StatelessWidget {
  const _ActiveFiltersBanner({required this.filters, required this.onClear});

  final FilterOptions filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final chips = <Widget>[];
    if (filters.categories.isNotEmpty) {
      chips.addAll(filters.categories.map((cat) => Chip(label: Text(cat))));
    }
    if (filters.conditions.isNotEmpty) {
      chips.addAll(filters.conditions.map((cond) => Chip(label: Text(cond))));
    }
    if (filters.allowOffersOnly) {
      chips.add(Chip(label: Text(loc.translate('keepOffers'))));
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ),
        TextButton(onPressed: onClear, child: Text(loc.translate('clearFilters'))),
      ],
    );
  }
}
