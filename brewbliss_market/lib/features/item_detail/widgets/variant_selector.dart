import 'package:flutter/material.dart';

import '../../../data/models/item.dart';
import '../../../data/models/variant.dart';

class VariantSelector extends StatelessWidget {
  const VariantSelector({
    super.key,
    required this.item,
    required this.selectedId,
    required this.onChanged,
  });

  final Item item;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final variants = item.variants;
    if (variants == null || variants.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: variants.map((variant) => _buildChip(variant, colorScheme, context)).toList(),
    );
  }

  Widget _buildChip(Variant variant, ColorScheme colorScheme, BuildContext context) {
    final selected = variant.id == selectedId;
    final attrs = variant.attrs.entries.map((e) => '${e.key}: ${e.value}').join(' • ');
    return ChoiceChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(variant.name, style: Theme.of(context).textTheme.bodyMedium),
          if (attrs.isNotEmpty)
            Text(
              attrs,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onChanged(variant.id),
      selectedColor: colorScheme.primary,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
    );
  }
}
