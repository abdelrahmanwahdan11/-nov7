import 'package:flutter/material.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.points,
    this.color,
    this.strokeWidth = 2,
    this.minHeight = 64,
    this.onPointSelected,
  });

  final List<double> points;
  final Color? color;
  final double strokeWidth;
  final double minHeight;
  final void Function(int index, double value)? onPointSelected;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox();
    }
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: minHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (details) {
              final width = constraints.maxWidth;
              if (width == 0 || points.length <= 1) {
                return;
              }
              final relative = (details.localPosition.dx / width)
                  .clamp(0.0, 1.0 - 1e-6);
              final index = (relative * (points.length - 1)).round();
              onPointSelected?.call(index, points[index]);
            },
            child: CustomPaint(
              painter: _SparklinePainter(
                points: points,
                color: resolvedColor,
                strokeWidth: strokeWidth,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> points;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }
    final minValue = points.reduce((a, b) => a < b ? a : b);
    final maxValue = points.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.0001
        ? 1.0
        : (maxValue - minValue);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final normalized = (points[i] - minValue) / range;
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final markerPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    final minIndex = points.indexOf(minValue);
    final maxIndex = points.indexOf(maxValue);
    final minOffset = Offset(
      minIndex / (points.length - 1) * size.width,
      size.height - ((points[minIndex] - minValue) / range) * size.height,
    );
    final maxOffset = Offset(
      maxIndex / (points.length - 1) * size.width,
      size.height - ((points[maxIndex] - minValue) / range) * size.height,
    );
    canvas.drawCircle(minOffset, strokeWidth * 1.2, markerPaint);
    canvas.drawCircle(maxOffset, strokeWidth * 1.2, markerPaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
