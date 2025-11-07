import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';
import '../core/utils/app_localizations.dart';

typedef ColorSelectedCallback = void Function(Color color);

class ColorPickerSheet extends StatelessWidget {
  const ColorPickerSheet({super.key, required this.onColorSelected});

  final ColorSelectedCallback onColorSelected;

  static const _colors = [
    DesignTokens.primary,
    Color(0xFF512DA8),
    Color(0xFF2E5AD6),
    Color(0xFF1ABC9C),
    Color(0xFFE53935),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('primaryColor'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: _colors
                .map(
                  (color) => GestureDetector(
                    onTap: () {
                      onColorSelected(color);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: DesignTokens.strokeThin,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
