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

  static const double _axisStep = 500;
  static const double _minorGridStep = 250;

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

    final xBounds = _planAxisBoundsFor(
      points.map((point) => _numberValue(point.eastWest)),
    );
    final yBounds = _planAxisBoundsFor(
      points.map((point) => _numberValue(point.northSouth)),
    );
    final xRange = xBounds.max - xBounds.min;
    final yRange = yBounds.max - yBounds.min;

    canvas.drawRect(plot, border);
    _drawGrid(canvas, plot, grid, xBounds, yBounds);

    if (points.isEmpty) {
      drawSurveyText(
        canvas,
        'No survey data',
        Offset(plot.center.dx - 34, plot.center.dy - 8),
      );
      return;
    }

    for (
      var value = xBounds.min;
      value <= xBounds.max + 0.1;
      value += _axisStep
    ) {
      final px = plot.left + (plot.width * (value - xBounds.min) / xRange);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(px - 10, plot.bottom + 8),
      );
    }
    for (
      var value = yBounds.min;
      value <= yBounds.max + 0.1;
      value += _axisStep
    ) {
      final py = plot.bottom - (plot.height * (value - yBounds.min) / yRange);
      _drawLeftAxisLabel(canvas, value.toStringAsFixed(0), plot.left, py);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final xRatio = ((_numberValue(point.eastWest) - xBounds.min) / xRange)
          .clamp(0.0, 1.0)
          .toDouble();
      final yRatio = ((_numberValue(point.northSouth) - yBounds.min) / yRange)
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
      final xRatio =
          ((marker.x - xBounds.min) / xRange).clamp(0.0, 1.0).toDouble();
      final yRatio =
          ((marker.y - yBounds.min) / yRange).clamp(0.0, 1.0).toDouble();
      final px = plot.left + xRatio * plot.width;
      final py = plot.bottom - yRatio * plot.height;
      drawSurveyMarker(canvas, Offset(px, py), marker.symbol);
      drawSurveyText(canvas, marker.label, Offset(px + 8, py - 10));
    }
  }

  _PlanAxisBounds _planAxisBoundsFor(Iterable<double> values) {
    final valueList = values.toList();
    if (valueList.isEmpty) {
      return const _PlanAxisBounds(min: -_axisStep, max: _axisStep);
    }

    final minValue = valueList.reduce(math.min);
    final maxValue = valueList.reduce(math.max);
    var minAxis = minValue < 0
        ? ((minValue / _axisStep).floor() * _axisStep) - _axisStep
        : -_axisStep;
    var maxAxis = maxValue > 0
        ? ((maxValue / _axisStep).ceil() * _axisStep) + _axisStep
        : _axisStep;

    if (minAxis == maxAxis) {
      minAxis -= _axisStep;
      maxAxis += _axisStep;
    }

    return _PlanAxisBounds(min: minAxis, max: maxAxis);
  }

  void _drawGrid(
    Canvas canvas,
    Rect plot,
    Paint grid,
    _PlanAxisBounds xBounds,
    _PlanAxisBounds yBounds,
  ) {
    final xRange = xBounds.max - xBounds.min;
    final yRange = yBounds.max - yBounds.min;

    for (
      var value = xBounds.min;
      value <= xBounds.max + 0.1;
      value += _minorGridStep
    ) {
      final x = plot.left + (plot.width * (value - xBounds.min) / xRange);
      drawDashedLine(canvas, Offset(x, plot.top), Offset(x, plot.bottom), grid);
    }
    for (
      var value = yBounds.min;
      value <= yBounds.max + 0.1;
      value += _minorGridStep
    ) {
      final y = plot.bottom - (plot.height * (value - yBounds.min) / yRange);
      drawDashedLine(canvas, Offset(plot.left, y), Offset(plot.right, y), grid);
    }
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

class _PlanAxisBounds {
  const _PlanAxisBounds({required this.min, required this.max});

  final double min;
  final double max;
}
