import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../widgets/item_card_3d.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.itemsController});

  final ItemsController itemsController;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _queryController = TextEditingController();
  List<Item> _results = [];

  void _onSearch(String value) {
    setState(() {
      _results = widget.itemsController.search(value);
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = _results;
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
              onChanged: _onSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(_queryController.text.isEmpty
                          ? loc.translate('searchAnything')
                          : loc.translate('emptyState')),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return SizedBox(
                          height: 220,
                          child: ItemCard3D(item: item, itemsController: widget.itemsController),
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
