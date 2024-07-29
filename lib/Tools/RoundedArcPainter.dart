import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';

class RoundedArcPainter extends CustomPainter {
  final double startAngle;
  final double sweepAngle;
  final double radius;
  final Color arcColor;
  final Color endShapeColor;
  final double shapeRadius;
  final Offset center;

  RoundedArcPainter({
    required this.startAngle,
    required this.sweepAngle,
    required this.radius,
    required this.arcColor,
    required this.endShapeColor,
    required this.shapeRadius,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    final Paint shapePaint = Paint()
      ..color = endShapeColor
      ..style = PaintingStyle.fill;

    // رسم آرک
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Path path = Path()
      ..arcTo(rect, startAngle, sweepAngle, false);

    canvas.drawPath(path, arcPaint);

    // رسم دایره در دو سر آرک
    double calculateX(double angle) => center.dx + (radius * cos(angle));
    double calculateY(double angle) => center.dy + (radius * sin(angle));

    final Offset startOffset = Offset(calculateX(startAngle), calculateY(startAngle));
    final Offset endOffset = Offset(calculateX(startAngle + sweepAngle), calculateY(startAngle + sweepAngle));

    canvas.drawCircle(startOffset, shapeRadius, shapePaint);
    canvas.drawCircle(endOffset, shapeRadius, shapePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}