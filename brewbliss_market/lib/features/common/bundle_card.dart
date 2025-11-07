import 'package:flutter/material.dart';

import '../../data/models/bundle.dart';
import '../../data/models/item.dart';

class BundleCard extends StatelessWidget {
  const BundleCard({
    super.key,
    required this.bundle,
    required this.items,
    this.onAddToCart,
  });

  final Bundle bundle;
  final List<Item> items;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bundle.name,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Text(
                  '\$${bundle.bundlePrice.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (item.price != null)
                        Text(
                          '\$${item.price!.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                )),
            if (onAddToCart != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: onAddToCart,
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
