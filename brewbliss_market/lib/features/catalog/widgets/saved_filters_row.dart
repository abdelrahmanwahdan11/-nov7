import 'package:flutter/material.dart';

class SavedFilterChipData {
  const SavedFilterChipData({
    required this.id,
    required this.label,
    this.description,
  });

  final String id;
  final String label;
  final String? description;
}

class SavedFiltersRow extends StatelessWidget {
  const SavedFiltersRow({
    super.key,
    required this.filters,
    required this.onFilterSelected,
    this.onRemove,
  });

  final List<SavedFilterChipData> filters;
  final ValueChanged<SavedFilterChipData> onFilterSelected;
  final ValueChanged<SavedFilterChipData>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) {
      return const SizedBox();
    }
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return InputChip(
            label: Text(filter.label),
            tooltip: filter.description,
            onPressed: () => onFilterSelected(filter),
            onDeleted: onRemove == null ? null : () => onRemove!(filter),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}
