import 'package:flutter/material.dart';

import 'package:cryptowatch/app/theme/app_colors.dart';

/// Courbe 7 jours : ligne orange, point final. [values] = prix réels T-10a.
class WeekLineChart extends StatelessWidget {
  const WeekLineChart({super.key, required this.values});

  final List<double> values;

  static const labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          width: double.infinity,
          child: CustomPaint(
            painter: _WeekLinePainter(values: values),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in labels)
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekLinePainter extends CustomPainter {
  _WeekLinePainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min).abs() < 0.001 ? 1.0 : max - min;
    final dx = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final t = (values[i] - min) / span;
      return Offset(dx * i, size.height - t * size.height);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final paint = Paint()
      ..color = AppColors.bitcoin
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    final end = pointAt(values.length - 1);
    canvas.drawCircle(end, 5.5, Paint()..color = AppColors.bitcoin);
  }

  @override
  bool shouldRepaint(covariant _WeekLinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
