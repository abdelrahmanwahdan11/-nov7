import 'package:flutter/material.dart';

import '../../../data/models/item.dart';

class TipsPanel extends StatelessWidget {
  const TipsPanel({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final tips = _tipsFor(item);
    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Care tips', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $tip', style: Theme.of(context).textTheme.bodySmall),
                )),
          ],
        ),
      ),
    );
  }

  List<String> _tipsFor(Item item) {
    switch (item.category.toLowerCase()) {
      case 'mugs':
        return const ['Avoid abrasive scrubbers to keep the glaze glossy.', 'Hand-wash to preserve illustrations.'];
      case 'beans':
        return const ['Store in airtight container away from sunlight.', 'Grind right before brewing for best aroma.'];
      case 'accessories':
        return const ['Rinse after each brew to prevent buildup.', 'Dry completely before storing to avoid patina.'];
      default:
        return const ['Inspect regularly for wear.', 'Document provenance to boost collector value.'];
    }
  }
}
