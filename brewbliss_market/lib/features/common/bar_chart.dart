import 'package:flutter/material.dart';

class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.data,
    this.barColor,
  });

  final Map<String, double> data;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 120);
    }
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _BarChartPainter(data: data, color: barColor ?? Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.data, required this.color});

  final Map<String, double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final labels = data.keys.toList();
    final values = data.values.toList();
    if (values.isEmpty) return;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final barWidth = size.width / (labels.length * 2);
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (var i = 0; i < labels.length; i++) {
      final value = values[i];
      final barHeight = maxValue == 0 ? 0 : (value / maxValue) * (size.height - 32);
      final dx = (i * 2 + 0.5) * barWidth;
      final rect = Rect.fromLTWH(dx, size.height - barHeight - 24, barWidth, barHeight);
      final radius = Radius.circular(barWidth * 0.4);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      );
      textPainter.layout(maxWidth: barWidth * 1.5);
      textPainter.paint(
        canvas,
        Offset(dx - (textPainter.width - barWidth) / 2, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
