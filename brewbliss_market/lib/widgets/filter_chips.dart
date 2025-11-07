import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.onSelected,
    this.selectedValues = const {},
  });

  final List<String> labels;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final isSelected = selectedValues.contains(label);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) {
            final values = {...selectedValues};
            if (isSelected) {
              values.remove(label);
            } else {
              values.add(label);
            }
            onSelected(values);
          },
        );
      }).toList(),
    );
  }
}
