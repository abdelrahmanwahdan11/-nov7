import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Reset 3D rotation',
                child: IconButton(
                  icon: const Icon(IconlyBold.refresh),
                  color: colorScheme.primary,
                  tooltip: 'Reset',
                  onPressed: onReset,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: autoRotateNotifier,
                  builder: (context, autoRotate, _) {
                    return SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Auto rotate',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      value: autoRotate,
                      onChanged: (value) => autoRotateNotifier.value = value,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: speedNotifier,
            builder: (context, speed, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rotation speed',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: speed,
                    min: 0.2,
                    max: 2.0,
                    divisions: 9,
                    label: speed.toStringAsFixed(1),
                    onChanged: (value) => speedNotifier.value = value,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
