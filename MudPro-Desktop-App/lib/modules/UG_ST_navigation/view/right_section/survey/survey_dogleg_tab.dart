import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_graph_utils.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

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
            Text(
              'Dogleg',
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'MD ${AppUnits.unitText('(ft)')}',
                      style: AppTheme.wellLikeBodyText.copyWith(fontSize: 14),
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
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 14),
            ),
          ],
        ),
      );
    });
  }
}

class _DoglegGraphPainter extends CustomPainter {
  _DoglegGraphPainter({required this.points});

  static const double _mdStep = 2000;
  static const double _mdMinorGridStep = 1000;
  static const double _doglegStep = 2;
  static const double _doglegMinorGridStep = 1;

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

    final maxMd = _mdAxisMaxFor(
      points.fold<double>(0, (maxValue, point) {
        return math.max(maxValue, _numberValue(point.md));
      }),
    );
    final maxDogleg = _doglegAxisMaxFor(
      points.fold<double>(0, (maxValue, point) {
        return math.max(maxValue, _numberValue(point.dogleg));
      }),
    );

    canvas.drawRect(plot, border);
    _drawGrid(canvas, plot, grid, maxMd, maxDogleg);

    if (points.isEmpty) {
      drawSurveyText(
        canvas,
        'No survey data',
        Offset(plot.center.dx - 34, plot.center.dy - 8),
      );
      return;
    }

    for (var value = 0.0; value <= maxMd + 0.1; value += _mdStep) {
      final py = plot.top + (plot.height * value / maxMd);
      _drawLeftAxisLabel(canvas, value.toStringAsFixed(0), plot.left, py);
    }
    for (
      var value = 0.0;
      value <= maxDogleg + 0.1;
      value += _doglegStep
    ) {
      final px = plot.left + (plot.width * value / maxDogleg);
      drawSurveyText(
        canvas,
        value.toStringAsFixed(0),
        Offset(px - 8, plot.bottom + 8),
      );
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final xRatio = (_numberValue(point.dogleg) / maxDogleg)
          .clamp(0.0, 1.0)
          .toDouble();
      final yRatio = (_numberValue(point.md) / maxMd)
          .clamp(0.0, 1.0)
          .toDouble();
      final px = plot.left + xRatio * plot.width;
      final py = plot.top + yRatio * plot.height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, line);
  }

  double _mdAxisMaxFor(double value) {
    if (value <= 0) return _mdStep;
    return (value / _mdStep).ceil() * _mdStep;
  }

  double _doglegAxisMaxFor(double value) {
    if (value <= 0) return _doglegStep;
    return (value / _doglegStep).ceil() * _doglegStep;
  }

  void _drawGrid(
    Canvas canvas,
    Rect plot,
    Paint grid,
    double maxMd,
    double maxDogleg,
  ) {
    for (
      var value = 0.0;
      value <= maxDogleg + 0.1;
      value += _doglegMinorGridStep
    ) {
      final x = plot.left + (plot.width * value / maxDogleg);
      drawDashedLine(canvas, Offset(x, plot.top), Offset(x, plot.bottom), grid);
    }
    for (
      var value = 0.0;
      value <= maxMd + 0.1;
      value += _mdMinorGridStep
    ) {
      final y = plot.top + (plot.height * value / maxMd);
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
  bool shouldRepaint(covariant _DoglegGraphPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
