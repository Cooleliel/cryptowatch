import 'package:flutter/material.dart';
import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/crypto_detail/domain/price_point.dart';

class WeekLineChart extends StatelessWidget {
  const WeekLineChart({
    super.key,
    this.points = const [],
    this.values = const [],
  });

  final List<PricePoint> points;
  final List<double> values;

  static const _dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  static String _dayLabel(DateTime date) {
    return _dayNames[(date.weekday - 1) % 7];
  }

  List<double> get _resolvedValues {
    if (points.isNotEmpty) {
      return points.map((p) => p.price).toList();
    }
    return values;
  }

  List<String> get _resolvedLabels {
    if (points.isNotEmpty) {
      if (points.length <= 7) {
        return points.map((p) => _dayLabel(p.time)).toList();
      }
      const count = 7;
      return List.generate(count, (i) {
        final index = (i * (points.length - 1) / (count - 1)).round();
        return _dayLabel(points[index].time);
      });
    }

    if (values.isNotEmpty) {
      final now = DateTime.now();
      const count = 7;
      return List.generate(count, (i) {
        final date = now.subtract(Duration(days: (count - 1) - i));
        return _dayLabel(date);
      });
    }

    return _dayNames;
  }

  @override
  Widget build(BuildContext context) {
    final chartValues = _resolvedValues;
    final labels = _resolvedLabels;

    return Column(
      children: [
        Container(
          height: 190,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: CustomPaint(
            painter: _WeekLinePainter(values: chartValues),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in labels)
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
      final usableHeight = size.height * 0.75;
      final y = size.height * 0.85 - (t * usableHeight);
      return Offset(dx * i, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    final fillPath = Path()..moveTo(pointAt(0).dx, size.height);
    fillPath.lineTo(pointAt(0).dx, pointAt(0).dy);

    for (var i = 1; i < values.length; i++) {
      final prev = pointAt(i - 1);
      final curr = pointAt(i);
      final midX = (prev.dx + curr.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
      fillPath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    fillPath.lineTo(pointAt(values.length - 1).dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withAlpha(50),
          AppColors.primary.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final end = pointAt(values.length - 1);
    final haloPaint = Paint()
      ..color = AppColors.primary.withAlpha(60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, 9.0, haloPaint);

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, 5.0, dotPaint);

    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, 2.5, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _WeekLinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}


