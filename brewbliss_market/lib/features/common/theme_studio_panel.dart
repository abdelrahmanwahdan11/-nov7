import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';

class ThemeStudioPanel extends StatelessWidget {
  const ThemeStudioPanel({
    super.key,
    required this.state,
    required this.onChanged,
  });

  final ThemeStudioState state;
  final ValueChanged<ThemeStudioState> onChanged;

  @override
  Widget build(BuildContext context) {
    final palettes = <List<Color>>[
      [const Color(0xFF193B8C), Colors.white],
      [const Color(0xFF2E5AD6), const Color(0xFFE9ECF7)],
      [const Color(0xFF0E2248), const Color(0xFFF4F4F2)],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Palette', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: List.generate(palettes.length, (index) {
            final colors = palettes[index];
            final selected = state.paletteIndex == index;
            return GestureDetector(
              onTap: () => onChanged(
                state.copyWith(paletteIndex: index),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: colors
                      .map((color) => Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ))
                      .toList(),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text('Typography scale: ${state.typographyScale.toStringAsFixed(1)}'),
        Slider(
          value: state.typographyScale,
          min: 0.8,
          max: 1.4,
          divisions: 6,
          onChanged: (value) => onChanged(
            state.copyWith(typographyScale: double.parse(value.toStringAsFixed(1))),
          ),
        ),
      ],
    );
  }
}
