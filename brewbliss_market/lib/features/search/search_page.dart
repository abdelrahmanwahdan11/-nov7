import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../controllers/search_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../data/models/saved_filter_adv.dart';
import '../../widgets/item_card_3d.dart';
import '../common/advanced_filter_builder.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.itemsController,
    required this.searchController,
  });

  final ItemsController itemsController;
  final SearchController searchController;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _queryController = TextEditingController();
  late final ScrollController _scrollController;
  bool _loading = false;
  String? _activeAdvancedExpression;
  String? _activeAdvancedId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    widget.searchController.loadingListenable.addListener(_onLoadingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.searchController.run('', reset: true);
    });
  }

  void _onLoadingChanged() {
    final next = widget.searchController.loadingListenable.value;
    if (mounted && next != _loading) {
      setState(() => _loading = next);
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      widget.searchController.fetchNextPage();
    }
  }

  Future<void> _onSearch(String value) async {
    if (_activeAdvancedExpression != null) {
      setState(() {
        _activeAdvancedExpression = null;
        _activeAdvancedId = null;
      });
    }
    await widget.searchController.run(value, reset: true);
  }

  Future<void> _saveCurrentSearch(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController(text: _queryController.text.trim());
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('saveSearch')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: loc.translate('name'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.translate('cancel')),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(loc.translate('save')),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await widget.searchController.saveCurrentQueryAs(id: id, name: name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.translate('savedSearches'))),
    );
  }

  Future<void> _openAdvancedBuilder() async {
    final loc = AppLocalizations.of(context);
    String expression = _activeAdvancedExpression ?? '';
    final nameController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdvancedFilterBuilder(
                      onExpressionChanged: (value) =>
                          setModalState(() => expression = value),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration:
                          InputDecoration(labelText: loc.translate('name')),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(loc.translate('cancel')),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: expression.trim().isEmpty ||
                                  nameController.text.trim().isEmpty
                              ? null
                              : () async {
                                  final filter = SavedFilterAdv(
                                    id: DateTime.now()
                                        .microsecondsSinceEpoch
                                        .toString(),
                                    name: nameController.text.trim(),
                                    expression: expression.trim(),
                                    createdAt: DateTime.now(),
                                  );
                                  await widget.searchController
                                      .saveAdvancedFilter(filter);
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  _applyAdvancedFilter(filter);
                                },
                          child: Text(loc.translate('save')),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: expression.trim().isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  if (mounted) {
                                    _applyAdvancedExpression(expression.trim());
                                  }
                                },
                          child: Text(loc.translate('view')),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _applyAdvancedFilter(SavedFilterAdv filter) {
    setState(() {
      _activeAdvancedExpression = filter.expression;
      _activeAdvancedId = filter.id;
      _queryController.clear();
    });
    widget.searchController.runAdvancedExpression(filter.expression, reset: true);
  }

  void _applyAdvancedExpression(String expression) {
    setState(() {
      _activeAdvancedExpression = expression;
      _activeAdvancedId = null;
      _queryController.clear();
    });
    widget.searchController.runAdvancedExpression(expression, reset: true);
  }

  void _clearAdvancedExpression() {
    setState(() {
      _activeAdvancedExpression = null;
      _activeAdvancedId = null;
    });
    widget.searchController.run('', reset: true);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    widget.searchController.loadingListenable.removeListener(_onLoadingChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('search')),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.filter),
            tooltip: loc.translate('advancedFilters'),
            onPressed: _openAdvancedBuilder,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                prefixIcon: const Icon(IconlyLight.search),
                hintText: loc.translate('search'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _onSearch(value);
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<List<String>>(
              valueListenable: widget.searchController.recentQueriesListenable,
              builder: (context, recent, _) {
                if (recent.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: recent
                        .map(
                          (query) => ActionChip(
                            label: Text(query),
                            onPressed: () {
                              _queryController.text = query;
                              setState(() {});
                              _onSearch(query);
                            },
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
            if (_queryController.text.trim().isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _saveCurrentSearch(context),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(loc.translate('saveSearch')),
                ),
              ),
            const SizedBox(height: 8),
            ValueListenableBuilder<List<SavedFilterAdv>>(
              valueListenable:
                  widget.searchController.advancedFiltersListenable,
              builder: (context, filters, _) {
                if (filters.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: filters
                        .map(
                          (filter) => InputChip(
                            label: Text(filter.name),
                            selected: _activeAdvancedId == filter.id,
                            onPressed: () => _applyAdvancedFilter(filter),
                            onDeleted: () => widget.searchController
                                .deleteAdvancedFilter(filter.id),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
            if (_activeAdvancedExpression != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _clearAdvancedExpression,
                  child: Text(loc.translate('undo')),
                ),
              ),
            Expanded(
              child: ValueListenableBuilder<List<Item>>(
                valueListenable: widget.searchController.resultsListenable,
                builder: (context, results, _) {
                  if (_loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (results.isEmpty) {
                    return Center(
                      child: Text(_queryController.text.isEmpty
                          ? loc.translate('searchAnything')
                          : loc.translate('emptyState')),
                    );
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return SizedBox(
                        height: 220,
                        child: ItemCard3D(
                          item: item,
                          itemsController: widget.itemsController,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
