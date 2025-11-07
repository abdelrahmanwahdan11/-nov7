import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.color,
    this.strokeWidth = 2.5,
    this.height = 72,
    this.onPointSelected,
  });

  final List<double> values;
  final Color? color;
  final double strokeWidth;
  final double height;
  final ValueChanged<int>? onPointSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (values.isEmpty) {
      return SizedBox(height: height);
    }
    final paintColor = color ?? theme.colorScheme.primary;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: 500.ms,
            curve: Curves.easeOutCubic,
            builder: (context, progress, child) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: onPointSelected == null
                    ? null
                    : (details) {
                        final ratio = (details.localPosition.dx /
                                constraints.maxWidth)
                            .clamp(0.0, 1.0);
                        final raw = (ratio * (values.length - 1)).round();
                        final index = raw.clamp(0, values.length - 1) as int;
                        onPointSelected?.call(index);
                      },
                child: CustomPaint(
                  painter: _SparklinePainter(
                    values: values,
                    color: paintColor,
                    strokeWidth: strokeWidth,
                    progress: progress,
                    minValueColor: paintColor.withOpacity(0.45),
                    maxValueColor: paintColor,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.progress,
    required this.minValueColor,
    required this.maxValueColor,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final double progress;
  final Color minValueColor;
  final Color maxValueColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs();
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final ratioX = values.length == 1 ? 0.0 : i / (values.length - 1);
      final value = range == 0 ? 0.5 : (values[i] - minValue) / range;
      final dx = ratioX * size.width;
      final dy = size.height - (value * size.height);
      points.add(Offset(dx, dy));
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final effectiveX = point.dx.clamp(0.0, size.width * progress);
      final effectivePoint = Offset(effectiveX, point.dy);
      if (i == 0) {
        path.moveTo(effectivePoint.dx, effectivePoint.dy);
      } else {
        path.lineTo(effectivePoint.dx, effectivePoint.dy);
      }
      if (effectiveX >= size.width * progress) {
        break;
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    final minIndex = values.indexOf(minValue);
    final maxIndex = values.indexOf(maxValue);
    final minOffset = points[minIndex];
    final maxOffset = points[maxIndex];

    final circleRadius = strokeWidth * 1.6;
    canvas.drawCircle(
      Offset(minOffset.dx, minOffset.dy),
      circleRadius,
      Paint()..color = minValueColor,
    );
    canvas.drawCircle(
      Offset(maxOffset.dx, maxOffset.dy),
      circleRadius,
      Paint()..color = maxValueColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
