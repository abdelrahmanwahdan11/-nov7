import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) {
    final color = strength >= 0.7
        ? DesignTokens.success
        : strength >= 0.4
            ? DesignTokens.accent
            : DesignTokens.danger;
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: DesignTokens.muted.withOpacity(0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: strength.clamp(0.05, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
        ),
      ),
    );
  }
}
