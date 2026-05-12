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
    for (var i = 0; i <= 10; i++) {
      final x = plot.left + (plot.width * i / 10);
      drawDashedLine(canvas, Offset(x, plot.top), Offset(x, plot.bottom), grid);
      final y = plot.top + (plot.height * i / 10);
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

    final maxTvd = math.max(
      1,
      points.map((e) => e.tvd as double).reduce(math.max),
    );
    final minX = math.min(
      0,
      points.map((e) => e.vsec as double).reduce(math.min),
    );
    final maxX = math.max(
      0.5,
      points.map((e) => e.vsec as double).reduce(math.max),
    );
    final xRange = (maxX - minX).abs() < 0.001 ? 1.0 : (maxX - minX);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final px = plot.left + ((point.vsec - minX) / xRange) * plot.width;
      final py = plot.top + (point.tvd / maxTvd) * plot.height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, line);

    for (final marker in markers) {
      final px = plot.left + ((marker.x - minX) / xRange) * plot.width;
      final py = plot.top + (marker.y / maxTvd) * plot.height;
      drawSurveyMarker(canvas, Offset(px, py), marker.symbol);
      drawSurveyText(canvas, marker.label, Offset(px + 8, py - 10));
    }

    for (var i = 0; i <= 5; i++) {
      final value = maxTvd * i / 5;
      final py = plot.top + (plot.height * i / 5);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(plot.left - 24, py - 7),
      );
    }
    for (var i = 0; i <= 5; i++) {
      final value = minX + (xRange * i / 5);
      final px = plot.left + (plot.width * i / 5);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(px - 8, plot.bottom + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SectionGraphPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.markers != markers;
  }
}
