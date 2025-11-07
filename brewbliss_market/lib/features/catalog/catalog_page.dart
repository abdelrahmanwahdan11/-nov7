import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../controllers/search_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../data/models/saved_search.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/item_card_3d.dart';
import '../../widgets/skeleton_box.dart';
import '../cart/cart_controller.dart';
import '../cart/widgets/cart_icon_badge.dart';
import 'widgets/saved_filters_row.dart';
import 'widgets/sticky_filter_bar.dart';
import 'widgets/tag_bar.dart';
import 'widgets/view_toggle.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.itemsController,
    required this.searchController,
    required this.cartController,
  });

  final ItemsController itemsController;
  final SearchController searchController;
  final CartController cartController;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  final _selectedFilters = <String>{};
  late final ScrollController _scrollController;
  bool _showSkeleton = false;
  CatalogViewMode _viewMode = CatalogViewMode.grid;
  String? _activeTag;
  SavedSearchFilters? _activeSavedFilters;
  String? _activeSavedId;

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

  void _applySavedSearch(SavedSearch saved) {
    setState(() {
      _activeSavedId = saved.id;
      _activeSavedFilters = saved.filters;
      _searchController.text = saved.query;
      _selectedFilters
        ..clear();
      if (saved.filters.category != null && saved.filters.category!.isNotEmpty) {
        _selectedFilters.add(saved.filters.category!);
      }
    });
  }

  Future<void> _deleteSavedSearch(SavedSearch saved) async {
    await widget.searchController.deleteSavedSearch(saved.id);
    if (_activeSavedId == saved.id) {
      setState(() {
        _activeSavedId = null;
        _activeSavedFilters = null;
      });
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
      final matchesTag = _activeTag == null || item.tags.contains(_activeTag);
      final saved = _activeSavedFilters;
      final matchesSavedCategory = saved?.category == null || saved!.category!.isEmpty
          ? true
          : item.category == saved.category;
      final price = item.price;
      final matchesMin = saved?.minPrice == null || price == null || price >= saved!.minPrice!;
      final matchesMax = saved?.maxPrice == null || price == null || price <= saved!.maxPrice!;
      final matchesCondition = saved?.condition == null || saved!.condition!.isEmpty
          ? true
          : item.condition == saved.condition;
      final matchesOffers = saved?.allowOffers == null || item.allowOffers == saved!.allowOffers;
      return matchesQuery &&
          matchesFilter &&
          matchesTag &&
          matchesSavedCategory &&
          matchesMin &&
          matchesMax &&
          matchesCondition &&
          matchesOffers;
    }).toList();
  }

  List<String> _availableTags(List<Item> items) {
    final tags = <String>{};
    for (final item in items) {
      tags.addAll(item.tags.take(6));
    }
    final sorted = tags.toList()..sort();
    return sorted.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('catalog')),
        actions: [
          CartIconBadge(
            cartController: widget.cartController,
            onPressed: () => Navigator.of(context).pushNamed('/cart'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ValueListenableBuilder<List<Item>>(
          valueListenable: widget.itemsController.visibleItemsListenable,
          builder: (context, items, _) {
            final tags = _availableTags(items);
            final filtered = _applyFilters(items);
            return CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          onChanged: (_) => setState(() {
                                _activeSavedFilters = null;
                                _activeSavedId = null;
                              }),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(loc.translate('view'),
                                style: Theme.of(context).textTheme.labelLarge),
                            ViewToggle(
                              mode: _viewMode,
                              onChanged: (mode) => setState(() => _viewMode = mode),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<List<SavedSearch>>(
                          valueListenable: widget.searchController.savedSearchesListenable,
                          builder: (context, filters, __) {
                            return SavedFiltersRow(
                              filters: filters,
                              selectedId: _activeSavedId,
                              onSelected: _applySavedSearch,
                              onDelete: _deleteSavedSearch,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyFilterBar(
                    child: FilterChips(
                      labels: const ['Mugs', 'Beans', 'Accessories'],
                      selectedValues: _selectedFilters,
                      onSelected: (values) => setState(() {
                            _selectedFilters
                              ..clear()
                              ..addAll(values);
                            _activeSavedId = null;
                            _activeSavedFilters = null;
                          }),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TagBar(
                      tags: tags,
                      activeTag: _activeTag,
                      onSelected: (tag) => setState(() {
                        _activeTag = _activeTag == tag ? null : tag;
                        _activeSavedId = null;
                        _activeSavedFilters = null;
                      }),
                    ),
                  ),
                ),
                if (_showSkeleton)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const SkeletonBox(),
                        childCount: 6,
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Center(child: Text(loc.translate('emptyState'))),
                    ),
                  )
                else if (_viewMode == CatalogViewMode.grid)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filtered[index];
                          return ItemCard3D(item: item, itemsController: widget.itemsController);
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ItemCard3D(
                                    item: item,
                                    itemsController: widget.itemsController,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
