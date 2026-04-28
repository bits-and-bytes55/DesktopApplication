import 'dart:math' as math;

import 'package:flutter/material.dart';

void drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint, {
  double dashLength = 4,
  double gapLength = 3,
}) {
  final distance = (end - start).distance;
  if (distance == 0) return;
  final dx = (end.dx - start.dx) / distance;
  final dy = (end.dy - start.dy) / distance;
  double travelled = 0;
  while (travelled < distance) {
    final currentStart = Offset(
      start.dx + (dx * travelled),
      start.dy + (dy * travelled),
    );
    final currentEnd = Offset(
      start.dx + (dx * math.min(travelled + dashLength, distance)),
      start.dy + (dy * math.min(travelled + dashLength, distance)),
    );
    canvas.drawLine(currentStart, currentEnd, paint);
    travelled += dashLength + gapLength;
  }
}

void drawSurveyText(
  Canvas canvas,
  String text,
  Offset offset, {
  double fontSize = 12,
  Color color = const Color(0xFF2F2F2F),
  FontWeight weight = FontWeight.normal,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, color: color, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, offset);
}

void drawSurveyMarker(Canvas canvas, Offset center, String symbol) {
  switch (symbol) {
    case 'circle_open':
      final border = Paint()
        ..color = const Color(0xFF7A7A7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, 8, border);
      break;
    case 'circle':
    case 'circle_filled':
      final circlePaint = Paint()..color = const Color(0xFF8C8C8C);
      canvas.drawCircle(center, 8, circlePaint);
      break;
    case 'square':
    case 'square_cross':
      final rect = Rect.fromCenter(center: center, width: 18, height: 18);
      final border = Paint()
        ..color = const Color(0xFF7A7A7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final line = Paint()
        ..color = const Color(0xFF7A7A7A)
        ..strokeWidth = 1;
      canvas.drawRect(rect, border);
      canvas.drawLine(
        rect.topLeft + const Offset(3, 3),
        rect.bottomRight - const Offset(3, 3),
        line,
      );
      canvas.drawLine(
        rect.topRight + const Offset(-3, 3),
        rect.bottomLeft + const Offset(3, -3),
        line,
      );
      break;
    case 'square_filled':
      final squareFill = Paint()..color = const Color(0xFF8C8C8C);
      canvas.drawRect(
        Rect.fromCenter(center: center, width: 16, height: 16),
        squareFill,
      );
      break;
    case 'square_grid':
      final rect = Rect.fromCenter(center: center, width: 18, height: 18);
      final border = Paint()
        ..color = const Color(0xFF7A7A7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final line = Paint()
        ..color = const Color(0xFF7A7A7A)
        ..strokeWidth = 1;
      canvas.drawRect(rect, border);
      canvas.drawLine(
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        line,
      );
      canvas.drawLine(
        Offset(rect.left, rect.center.dy),
        Offset(rect.right, rect.center.dy),
        line,
      );
      break;
    case 'triangle':
      final path = Path()
        ..moveTo(center.dx - 6, center.dy + 8)
        ..lineTo(center.dx - 6, center.dy - 8)
        ..lineTo(center.dx + 8, center.dy + 8)
        ..close();
      final triPaint = Paint()..color = const Color(0xFF7A7A7A);
      canvas.drawPath(path, triPaint);
      break;
  }
}
