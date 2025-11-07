import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../controllers/search_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../widgets/item_card_3d.dart';

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
