import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.ratingNotifier,
    this.onChanged,
    this.size = 24,
    this.color,
  });

  final ValueNotifier<int> ratingNotifier;
  final ValueChanged<int>? onChanged;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<int>(
      valueListenable: ratingNotifier,
      builder: (context, value, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final filled = index < value;
            return Semantics(
              button: onChanged != null,
              label: 'star ${index + 1}',
              value: filled ? 'selected' : 'not selected',
              child: IconButton(
                iconSize: size,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: onChanged == null
                    ? null
                    : () {
                        final next = index + 1;
                        ratingNotifier.value = next;
                        onChanged?.call(next);
                      },
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled
                      ? resolvedColor
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
