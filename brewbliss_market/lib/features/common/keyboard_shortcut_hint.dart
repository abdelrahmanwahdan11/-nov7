import 'package:flutter/material.dart';

class KeyboardShortcutHint extends StatelessWidget {
  const KeyboardShortcutHint({
    super.key,
    required this.shortcuts,
  });

  final Map<String, String> shortcuts;

  @override
  Widget build(BuildContext context) {
    if (shortcuts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: shortcuts.entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(entry.value),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
