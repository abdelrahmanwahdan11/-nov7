import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.ratingNotifier,
    this.onChanged,
    this.starSize = 28,
  });

  final ValueNotifier<int> ratingNotifier;
  final ValueChanged<int>? onChanged;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: ratingNotifier,
      builder: (context, value, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= value;
            return Semantics(
              label: 'Star $starIndex',
              button: true,
              selected: isFilled,
              child: InkWell(
                onTap: onChanged == null
                    ? null
                    : () {
                        ratingNotifier.value = starIndex;
                        onChanged?.call(starIndex);
                      },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isFilled ? IconlyBold.star : IconlyLight.star,
                    size: starSize,
                    color: isFilled
                        ? colorScheme.secondary
                        : colorScheme.onSurface.withOpacity(0.35),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
