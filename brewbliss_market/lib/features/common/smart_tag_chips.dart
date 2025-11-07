import 'package:flutter/material.dart';

class SmartTagChips extends StatelessWidget {
  const SmartTagChips({
    super.key,
    required this.tags,
    this.onSelected,
  });

  final List<String> tags;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      children: tags
          .map(
            (tag) => ChoiceChip(
              label: Text(tag),
              selected: false,
              onSelected: (_) => onSelected?.call(tag),
            ),
          )
          .toList(),
    );
  }
}
