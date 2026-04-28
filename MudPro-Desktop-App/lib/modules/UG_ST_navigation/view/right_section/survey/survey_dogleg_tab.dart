import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_graph_utils.dart';

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
                    child: const Text(
                      'MD (ft)',
                      style: TextStyle(fontSize: 14),
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
            const Text(
              'Dogleg Severity (°/100ft)',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    });
  }
}

class _DoglegGraphPainter extends CustomPainter {
  _DoglegGraphPainter({required this.points});

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

    final maxMd = math.max(
      1,
      points.map((e) => e.md as double).reduce(math.max),
    );
    final maxDogleg = math.max(
      5,
      points.map((e) => e.dogleg as double).reduce(math.max),
    );

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final px = plot.left + (point.dogleg / maxDogleg) * plot.width;
      final py = plot.top + (point.md / maxMd) * plot.height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, line);

    for (var i = 0; i <= 5; i++) {
      final value = maxMd * i / 5;
      final py = plot.top + (plot.height * i / 5);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(plot.left - 24, py - 7),
      );
    }
    for (var i = 0; i <= 5; i++) {
      final value = maxDogleg * i / 5;
      final px = plot.left + (plot.width * i / 5);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(px - 8, plot.bottom + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DoglegGraphPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
