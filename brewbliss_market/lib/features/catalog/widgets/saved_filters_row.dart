import 'package:flutter/material.dart';

import '../../../data/models/saved_search.dart';

class SavedFiltersRow extends StatelessWidget {
  const SavedFiltersRow({
    super.key,
    required this.filters,
    this.onSelected,
    this.onDelete,
    this.selectedId,
  });

  final List<SavedSearch> filters;
  final ValueChanged<SavedSearch>? onSelected;
  final ValueChanged<SavedSearch>? onDelete;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return InputChip(
            label: Text(filter.name),
            selected: selectedId == filter.id,
            onPressed: onSelected == null ? null : () => onSelected?.call(filter),
            onDeleted: onDelete == null ? null : () => onDelete?.call(filter),
            backgroundColor: colorScheme.surface,
            selectedColor: colorScheme.primary.withOpacity(0.12),
            shape: StadiumBorder(
              side: BorderSide(color: colorScheme.primary.withOpacity(0.25)),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: filters.length,
      ),
    );
  }
}
