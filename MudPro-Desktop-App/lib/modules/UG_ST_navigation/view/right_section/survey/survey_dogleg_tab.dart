import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_graph_utils.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class SurveyDoglegTab extends StatelessWidget {
  SurveyDoglegTab({super.key});

  final SurveyController controller = Get.find<SurveyController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final points = controller.plotPoints;
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Text(
              'Dogleg',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'MD ${AppUnits.unitText('(ft)')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomPaint(
                      painter: _DoglegGraphPainter(points: points),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Dogleg Severity ${AppUnits.dogleg}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    });
  }
}

class _DoglegGraphPainter extends CustomPainter {
  _DoglegGraphPainter({required this.points});

  static const double _maxMd = 12000;
  static const double _maxDogleg = 2;
  static const int _gridDivisions = 12;
  static const int _mdLabelDivisions = 6;
  static const int _doglegLabelDivisions = 4;

  final List<dynamic> points;

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
      ..style = PaintingStyle.stroke;

    canvas.drawRect(plot, border);
    for (var i = 0; i <= _gridDivisions; i++) {
      final x = plot.left + (plot.width * i / _gridDivisions);
      drawDashedLine(canvas, Offset(x, plot.top), Offset(x, plot.bottom), grid);
      final y = plot.top + (plot.height * i / _gridDivisions);
      drawDashedLine(canvas, Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    for (var i = 0; i <= _mdLabelDivisions; i++) {
      final value = _maxMd * i / _mdLabelDivisions;
      final py = plot.top + (plot.height * i / _mdLabelDivisions);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(plot.left - 24, py - 7),
      );
    }
    for (var i = 0; i <= _doglegLabelDivisions; i++) {
      final value = _maxDogleg * i / _doglegLabelDivisions;
      final px = plot.left + (plot.width * i / _doglegLabelDivisions);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
        Offset(px - 8, plot.bottom + 8),
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
      final px = plot.left + (point.dogleg / _maxDogleg) * plot.width;
      final py = plot.top + (point.md / _maxMd) * plot.height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _DoglegGraphPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
