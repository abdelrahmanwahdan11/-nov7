import 'package:flutter/material.dart';

class ThreeDControls extends StatelessWidget {
  const ThreeDControls({
    super.key,
    required this.autoRotateNotifier,
    required this.speedNotifier,
    required this.onReset,
  });

  final ValueNotifier<bool> autoRotateNotifier;
  final ValueNotifier<double> speedNotifier;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: onReset,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text('Reset'),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: autoRotateNotifier,
          builder: (context, value, _) {
            return FilterChip(
              label: Text(value ? 'Auto rotate' : 'Manual'),
              selected: value,
              onSelected: (selected) => autoRotateNotifier.value = selected,
            );
          },
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Speed',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: speedNotifier,
                  builder: (context, value, _) {
                    return Slider(
                      min: 0.2,
                      max: 2.0,
                      divisions: 9,
                      value: value,
                      onChanged: (next) => speedNotifier.value = next,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
