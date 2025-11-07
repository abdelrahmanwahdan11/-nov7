import 'package:flutter/material.dart';

import '../../../data/models/item.dart';
import '../../../core/utils/formatters.dart';

class CompareDeltaSummary extends StatelessWidget {
  const CompareDeltaSummary({super.key, required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final prices = items
        .where((item) => item.price != null)
        .map((item) => item.price!)
        .toList()
      ..sort();
    if (prices.isEmpty) {
      return const SizedBox.shrink();
    }
    final cheapest = prices.first;
    final priciest = prices.last;
    final delta = priciest - cheapest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _Badge(
            label: 'Best value',
            value: formatPrice(cheapest),
            color: Colors.greenAccent.withOpacity(0.2),
            textColor: Colors.green.shade800,
          ),
          const SizedBox(width: 12),
          _Badge(
            label: 'Premium',
            value: formatPrice(priciest),
            color: Colors.orangeAccent.withOpacity(0.2),
            textColor: Colors.orange.shade800,
          ),
          const Spacer(),
          Text('Δ ${formatPrice(delta)}', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor)),
        ],
      ),
    );
  }
}
