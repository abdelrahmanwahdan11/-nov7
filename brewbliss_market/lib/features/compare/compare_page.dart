import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../widgets/price_badge.dart';
import 'widgets/compare_delta_summary.dart';
import '../cart/cart_controller.dart';
import '../cart/widgets/cart_icon_badge.dart';

class ComparePage extends StatelessWidget {
  const ComparePage({
    super.key,
    required this.itemsController,
    this.cartController,
  });

  final ItemsController itemsController;
  final CartController? cartController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('compare')),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _exportCompare(context),
          ),
          if (cartController != null)
            CartIconBadge(
              cartController: cartController!,
              onPressed: () => Navigator.of(context).pushNamed('/cart'),
            ),
        ],
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
                CompareDeltaSummary(items: items),
                const SizedBox(height: 16),
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

  void _exportCompare(BuildContext context) {
    final compareItems = itemsController.compareItems;
    if (compareItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export')),
      );
      return;
    }
    final buffer = StringBuffer('Compare summary\n');
    for (final item in compareItems) {
      buffer
        ..writeln(item.name)
        ..writeln('Category: ${item.category}')
        ..writeln('Condition: ${item.condition}')
        ..writeln('Price: ${item.price != null ? '\$${item.price!.toStringAsFixed(2)}' : '--'}')
        ..writeln('---');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comparison copied to clipboard')),
    );
  }
}

class _SpecsTable extends StatelessWidget {
  const _SpecsTable({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final headers = ['category', 'condition', 'price'];
    final valuesByHeader = {
      for (final header in headers)
        header: items.map((item) => _valueFor(item, header)).toList(),
    };
    return Table(
      border: TableBorder.all(color: DesignTokens.muted.withOpacity(0.4)),
      columnWidths: const {
        0: FixedColumnWidth(120),
      },
      children: [
        for (final header in headers)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(loc.translate(header), style: Theme.of(context).textTheme.labelMedium),
              ),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    valuesByHeader[header]![i],
                    style: _cellStyle(context, valuesByHeader[header]!),
                  ),
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
      case 'price':
        return item.price != null ? '\$${item.price!.toStringAsFixed(2)}' : '--';
      default:
        return '';
    }
  }

  TextStyle? _cellStyle(BuildContext context, List<String> values) {
    final unique = values.toSet();
    if (unique.length > 1) {
      return Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: Colors.orangeAccent.shade700);
    }
    return Theme.of(context).textTheme.bodyMedium;
  }
}
