import 'package:flutter/material.dart';

class TagBar extends StatelessWidget {
  const TagBar({
    super.key,
    required this.tags,
    required this.onTagSelected,
  });

  final List<String> tags;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox();
    }
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final tag = tags[index];
          return ChoiceChip(
            label: Text(tag),
            selected: false,
            onSelected: (_) => onTagSelected(tag),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: tags.length,
      ),
    );
  }
}
