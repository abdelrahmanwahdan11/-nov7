import 'package:flutter/material.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../widgets/price_badge.dart';

class ComparePage extends StatelessWidget {
  const ComparePage({super.key, required this.itemsController});

  final ItemsController itemsController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('compare')),
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: itemsController.compareListenable,
        builder: (context, compareIds, _) {
          final items = itemsController.compareItems;
          if (items.isEmpty) {
            return Center(child: Text(loc.translate('emptyState')));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        width: 200,
                        margin: EdgeInsets.only(right: index == items.length - 1 ? 0 : 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                child: Image.network(item.images.first, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            if (item.price != null)
                              PriceBadge(label: '\$${item.price!.toStringAsFixed(2)}'),
                            TextButton(
                              onPressed: () => itemsController.toggleCompare(item.id),
                              child: Text(loc.translate('removeFromCompare')), // to add key
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _SpecsTable(items: items),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SpecsTable extends StatelessWidget {
  const _SpecsTable({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final headers = ['category', 'condition'];
    return Table(
      border: TableBorder.all(color: DesignTokens.muted.withOpacity(0.4)),
      columnWidths: {
        0: const FixedColumnWidth(120),
      },
      children: [
        for (final header in headers)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(loc.translate(header), style: Theme.of(context).textTheme.labelMedium),
              ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_valueFor(item, header)),
                ),
            ],
          ),
      ],
    );
  }

  String _valueFor(Item item, String key) {
    switch (key) {
      case 'category':
        return item.category;
      case 'condition':
        return item.condition;
      default:
        return '';
    }
  }
}
