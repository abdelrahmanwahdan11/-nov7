import 'package:flutter/material.dart';

class UndoBar extends StatelessWidget {
  const UndoBar({
    super.key,
    required this.message,
    this.onUndo,
  });

  final String message;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onUndo != null)
            TextButton(
              onPressed: onUndo,
              child: Text(MaterialLocalizations.of(context).undoButtonLabel),
            ),
        ],
      ),
    );
  }
}
