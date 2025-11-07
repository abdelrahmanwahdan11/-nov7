import 'dart:ui';

import 'package:flutter/material.dart';

class CountdownBadge extends StatelessWidget {
  const CountdownBadge({
    super.key,
    required this.duration,
  });

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final text = duration.isNegative
        ? '00:00'
        : '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}';
    final color = duration.inMinutes <= 1
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}
