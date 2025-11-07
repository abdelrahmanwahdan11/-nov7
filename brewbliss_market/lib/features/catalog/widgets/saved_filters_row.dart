import 'package:flutter/material.dart';

import '../../../data/models/saved_search.dart';

class SavedFiltersRow extends StatelessWidget {
  const SavedFiltersRow({
    super.key,
    required this.filters,
    this.onSelected,
    this.onDelete,
  });

  final List<SavedSearch> filters;
  final ValueChanged<SavedSearch>? onSelected;
  final ValueChanged<SavedSearch>? onDelete;

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
            onPressed: onSelected == null ? null : () => onSelected?.call(filter),
            onDeleted: onDelete == null ? null : () => onDelete?.call(filter),
            backgroundColor: colorScheme.surface,
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
