import 'package:flutter/material.dart';

class TagBar extends StatelessWidget {
  const TagBar({
    super.key,
    required this.tags,
    this.activeTag,
    this.onSelected,
  });

  final List<String> tags;
  final String? activeTag;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final selected = tag == activeTag;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(tag),
              selected: selected,
              onSelected: onSelected == null
                  ? null
                  : (_) => onSelected?.call(tag),
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
