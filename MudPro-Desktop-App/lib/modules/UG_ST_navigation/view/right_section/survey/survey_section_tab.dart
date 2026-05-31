import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_graph_utils.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class SurveySectionTab extends StatelessWidget {
  SurveySectionTab({super.key});

  final SurveyController controller = Get.find<SurveyController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final points = controller.plotPoints;
      final markers = controller.annotationMarkers
          .map((marker) {
            final point = controller.pointForAnnotationMd(marker.md);
            if (point == null) return null;
            return _SectionMarker(
              x: point.vsec,
              y: point.tvd,
              label: marker.label,
              symbol: marker.symbol,
            );
          })
          .whereType<_SectionMarker>()
          .toList();

      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Text(
              'Section View',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'TVD ${AppUnits.unitText('(ft)')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomPaint(
                      painter: _SectionGraphPainter(
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
              'Horizontal Displacement ${AppUnits.unitText('(ft)')}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionMarker {
  const _SectionMarker({
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

class _SectionGraphPainter extends CustomPainter {
  _SectionGraphPainter({required this.points, required this.markers});

  static const double _axisMin = 0;
  static const double _axisMinMax = 12000;
  static const double _axisStep = 2000;
  static const int _gridDivisions = 12;

  final List<dynamic> points;
  final List<_SectionMarker> markers;

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

    final maxTvd = _tvdAxisMaxFor(
      points.fold<double>(0, (maxValue, point) {
        return math.max(maxValue, _numberValue(point.tvd));
      }),
    );
    final maxX = _sectionAxisMaxFor(
      points.fold<double>(0, (maxValue, point) {
        return math.max(maxValue, _numberValue(point.vsec));
      }),
    );
    const minX = _axisMin;
    final xRange = maxX - _axisMin;
    final tvdLabelDivisions = (maxTvd / _axisStep).round();
    final xLabelDivisions = (maxX / _axisStep).round();

    for (var i = 0; i <= tvdLabelDivisions; i++) {
      final value = _axisStep * i;
      final py = plot.top + (plot.height * value / maxTvd);
      _drawLeftAxisLabel(
        canvas,
        value.toStringAsFixed(0),
        plot.left,
        py,
      );
    }
    for (var i = 0; i <= xLabelDivisions; i++) {
      final value = minX + (_axisStep * i);
      final px = plot.left + (plot.width * (value - minX) / xRange);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(px - 8, plot.bottom + 8),
      );
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final xRatio = ((_numberValue(point.vsec) - minX) / xRange)
          .clamp(0.0, 1.0)
          .toDouble();
      final yRatio =
          (_numberValue(point.tvd) / maxTvd).clamp(0.0, 1.0).toDouble();
      final px = plot.left + xRatio * plot.width;
      final py = plot.top + yRatio * plot.height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, line);

    for (final marker in markers) {
      final xRatio =
          ((marker.x - minX) / xRange).clamp(0.0, 1.0).toDouble();
      final yRatio = (marker.y / maxTvd).clamp(0.0, 1.0).toDouble();
      final px = plot.left + xRatio * plot.width;
      final py = plot.top + yRatio * plot.height;
      drawSurveyMarker(canvas, Offset(px, py), marker.symbol);
      drawSurveyText(canvas, marker.label, Offset(px + 8, py - 10));
    }
  }

  double _tvdAxisMaxFor(double maxTvd) {
    return _sectionAxisMaxFor(maxTvd);
  }

  double _sectionAxisMaxFor(double value) {
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
        style: const TextStyle(fontSize: 12, color: Color(0xFF2F2F2F)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(plotLeft - 10 - painter.width, centerY - (painter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant _SectionGraphPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.markers != markers;
  }
}
