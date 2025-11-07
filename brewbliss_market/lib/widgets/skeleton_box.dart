import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/design_tokens.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DesignTokens.muted.withOpacity(0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(
          begin: 0.3,
          end: 0.9,
          duration: 900.ms,
        );
  }
}
