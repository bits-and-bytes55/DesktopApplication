import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_graph_utils.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SurveyPlanTab extends StatelessWidget {
  SurveyPlanTab({super.key});

  final SurveyController controller = Get.find<SurveyController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final points = controller.plotPoints;
      final markers = controller.annotationMarkers
          .map((marker) {
            final point = controller.pointForAnnotationMd(marker.md);
            if (point == null) return null;
            return _PlanMarker(
              x: point.eastWest,
              y: point.northSouth,
              label: marker.label,
              symbol: marker.symbol,
            );
          })
          .whereType<_PlanMarker>()
          .toList();

      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              'Plan View',
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'N+/S- ${AppUnits.unitText('(ft)')}',
                      style: AppTheme.wellLikeBodyText.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomPaint(
                      painter: _PlanGraphPainter(
                        points: points,
                        markers: markers,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'E+/W- ${AppUnits.unitText('(ft)')}',
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 14),
            ),
          ],
        ),
      );
    });
  }
}

class _PlanMarker {
  const _PlanMarker({
    required this.x,
    required this.y,
    required this.label,
    required this.symbol,
  });

  final double x;
  final double y;
  final String label;
  final String symbol;
}

class _PlanGraphPainter extends CustomPainter {
  _PlanGraphPainter({required this.points, required this.markers});

  static const double _axisMin = 0;
  static const double _axisMinMax = 1200;
  static const double _axisStep = 200;
  static const int _gridDivisions = 12;

  final List<dynamic> points;
  final List<_PlanMarker> markers;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(56, 18, size.width - 74, size.height - 50);
    final border = Paint()
      ..color = const Color(0xFF303030)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final grid = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 1;
    final line = Paint()
      ..color = Colors.red
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawRect(plot, border);
    for (var i = 0; i <= _gridDivisions; i++) {
      final x = plot.left + (plot.width * i / _gridDivisions);
      drawDashedLine(canvas, Offset(x, plot.top), Offset(x, plot.bottom), grid);
      final y = plot.top + (plot.height * i / _gridDivisions);
      drawDashedLine(canvas, Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    if (points.isEmpty) {
      drawSurveyText(
        canvas,
        'No survey data',
        Offset(plot.center.dx - 34, plot.center.dy - 8),
      );
      return;
    }

    const minX = _axisMin;
    const minY = _axisMin;
    final maxX = _planAxisMaxFor(
      points.fold<double>(0, (maxValue, point) {
        return math.max(maxValue, _numberValue(point.eastWest).abs());
      }),
    );
    final maxY = _planAxisMaxFor(
      points.fold<double>(0, (maxValue, point) {
        return math.max(maxValue, _numberValue(point.northSouth).abs());
      }),
    );
    final xRange = maxX - _axisMin;
    final yRange = maxY - _axisMin;
    final xLabelDivisions = (maxX / _axisStep).round();
    final yLabelDivisions = (maxY / _axisStep).round();

    for (var i = 0; i <= yLabelDivisions; i++) {
      final value = minY + (_axisStep * i);
      final py = plot.bottom - (plot.height * (value - minY) / yRange);
      _drawLeftAxisLabel(canvas, value.toStringAsFixed(0), plot.left, py);
    }
    for (var i = 0; i <= xLabelDivisions; i++) {
      final value = minX + (_axisStep * i);
      final px = plot.left + (plot.width * (value - minX) / xRange);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(px - 10, plot.bottom + 8),
      );
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final xRatio = ((_numberValue(point.eastWest) - minX) / xRange)
          .clamp(0.0, 1.0)
          .toDouble();
      final yRatio = ((_numberValue(point.northSouth) - minY) / yRange)
          .clamp(0.0, 1.0)
          .toDouble();
      final px = plot.left + xRatio * plot.width;
      final py = plot.bottom - yRatio * plot.height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, line);

    for (final marker in markers) {
      final xRatio = ((marker.x - minX) / xRange).clamp(0.0, 1.0).toDouble();
      final yRatio = ((marker.y - minY) / yRange).clamp(0.0, 1.0).toDouble();
      final px = plot.left + xRatio * plot.width;
      final py = plot.bottom - yRatio * plot.height;
      drawSurveyMarker(canvas, Offset(px, py), marker.symbol);
      drawSurveyText(canvas, marker.label, Offset(px + 8, py - 10));
    }
  }

  double _planAxisMaxFor(double value) {
    if (value <= 0) return _axisMinMax;

    final roundedMax = (value / _axisStep).ceil() * _axisStep;
    return math.max(roundedMax, _axisMinMax);
  }

  double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _drawLeftAxisLabel(
    Canvas canvas,
    String text,
    double plotLeft,
    double centerY,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTheme.wellLikeBodyText.copyWith(fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(plotLeft - 10 - painter.width, centerY - (painter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant _PlanGraphPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.markers != markers;
  }
}
