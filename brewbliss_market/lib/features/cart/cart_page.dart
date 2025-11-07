import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_line.dart';
import '../../data/models/variant.dart';
import 'cart_controller.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    super.key,
    required this.itemsController,
    required this.cartController,
  });

  final ItemsController itemsController;
  final CartController cartController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('cart')),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.delete),
            onPressed: () => cartController.clear(),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<CartLine>>(
        valueListenable: cartController.linesListenable,
        builder: (context, lines, _) {
          if (lines.isEmpty) {
            return Center(child: Text(loc.translate('emptyState')));
          }
          final totals = cartController.totals();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...lines.map((line) => _CartLineTile(
                    line: line,
                    itemsController: itemsController,
                    cartController: cartController,
                  )),
              const SizedBox(height: 24),
              _TotalsCard(totals: totals),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.translate('placeOrder'))),
                  );
                },
                child: Text(loc.translate('continueLabel')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.itemsController,
    required this.cartController,
  });

  final CartLine line;
  final ItemsController itemsController;
  final CartController cartController;

  @override
  Widget build(BuildContext context) {
    final item = itemsController.getById(line.itemId);
    Variant? variant;
    final item = itemsController.getById(line.itemId);
    if (line.variantId != null && item?.variants != null) {
      try {
        variant = item!.variants!.firstWhere((element) => element.id == line.variantId);
      } catch (_) {
        variant = null;
      }
    }
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: SizedBox(
                width: 72,
                height: 72,
                child: item?.images.isNotEmpty == true
                    ? Image.network(item!.images.first, fit: BoxFit.cover)
                    : Container(color: Theme.of(context).colorScheme.surfaceVariant),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item?.name ?? line.itemId,
                      style: Theme.of(context).textTheme.titleMedium),
                  if (variant != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(variant.name, style: Theme.of(context).textTheme.bodySmall),
                    ),
                  const SizedBox(height: 8),
                  Text(formatPrice(line.unitPrice)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => cartController.updateQty(line.id, line.qty - 1),
                      ),
                      Text(line.qty.toString()),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => cartController.updateQty(line.id, line.qty + 1),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(IconlyLight.delete),
                        onPressed: () => cartController.remove(line.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final CartTotals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(label: 'Subtotal', value: formatPrice(totals.subtotal)),
            const SizedBox(height: 4),
            _Row(label: 'Tax', value: formatPrice(totals.tax)),
            const Divider(height: 24),
            _Row(label: 'Total', value: formatPrice(totals.total), bold: true),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
