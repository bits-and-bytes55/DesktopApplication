import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_graph_utils.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

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
            const Text(
              'Plan View',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'N+/S- ${AppUnits.unitText('(ft)')}',
                      style: const TextStyle(fontSize: 14),
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
              style: const TextStyle(fontSize: 14),
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
  static const double _axisMax = 1200;
  static const int _gridDivisions = 12;
  static const int _labelDivisions = 6;

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

    const minX = _axisMin;
    const minY = _axisMin;
    const xRange = _axisMax - _axisMin;
    const yRange = _axisMax - _axisMin;

    for (var i = 0; i <= _labelDivisions; i++) {
      final value = minY + (yRange * i / _labelDivisions);
      final py = plot.bottom - (plot.height * i / _labelDivisions);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(plot.left - 28, py - 7),
      );
    }
    for (var i = 0; i <= _labelDivisions; i++) {
      final value = minX + (xRange * i / _labelDivisions);
      final px = plot.left + (plot.width * i / _labelDivisions);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(px - 10, plot.bottom + 8),
      );
    }

    if (points.isEmpty) {
      drawSurveyText(
        canvas,
        'No survey data',
        Offset(plot.center.dx - 34, plot.center.dy - 8),
      );
      return;
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final px = plot.left + ((point.eastWest - minX) / xRange) * plot.width;
      final py =
          plot.bottom - ((point.northSouth - minY) / yRange) * plot.height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, line);

    for (final marker in markers) {
      final px = plot.left + ((marker.x - minX) / xRange) * plot.width;
      final py = plot.bottom - ((marker.y - minY) / yRange) * plot.height;
      drawSurveyMarker(canvas, Offset(px, py), marker.symbol);
      drawSurveyText(canvas, marker.label, Offset(px + 8, py - 10));
    }
  }

  @override
  bool shouldRepaint(covariant _PlanGraphPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.markers != markers;
  }
}
