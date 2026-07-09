import 'package:flutter/material.dart';
import 'dart:math';
import '../core/theme/app_theme.dart';

class HealthGauge extends StatelessWidget {
  final int score;
  final double size;

  const HealthGauge({
    super.key,
    required this.score,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    if (score >= 90) {
      gaugeColor = AppTheme.success;
    } else if (score >= 70) {
      gaugeColor = AppTheme.warning;
    } else {
      gaugeColor = AppTheme.critical;
    }

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: score.toDouble()),
        duration: const Duration(seconds: 2),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _GaugePainter(
              score: value,
              color: gaugeColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.toInt()}%',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: gaugeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Health Score',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Background track
    final bgPaint = Paint()
      ..color = AppTheme.cardColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Foreground track
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      // Add subtle glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    const startAngle = 3 * pi / 4;
    const sweepAngle = 6 * pi / 4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final currentSweep = sweepAngle * (score / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
