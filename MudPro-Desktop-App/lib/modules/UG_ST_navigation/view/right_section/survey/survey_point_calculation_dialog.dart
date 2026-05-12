import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_graph_utils.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class SurveyPointCalculationDialog extends StatefulWidget {
  const SurveyPointCalculationDialog({super.key});

  @override
  State<SurveyPointCalculationDialog> createState() =>
      _SurveyPointCalculationDialogState();
}

class _SurveyPointCalculationDialogState
    extends State<SurveyPointCalculationDialog> {
  final SurveyController controller = Get.find<SurveyController>();
  double poiMd = 0;

  @override
  void initState() {
    super.initState();
    if (controller.plotPoints.isNotEmpty) {
      poiMd = controller.plotPoints.first.md;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxMd = controller.plotPoints.isEmpty
        ? 0.0
        : controller.plotPoints.last.md;
    final point = controller.pointAtMd(poiMd);
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: Container(
        width: 1480,
        height: 1010,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC3C9D1)),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _titleBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 670, child: _summaryTable(point)),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            _button('Calculate', () => setState(() {})),
                            const SizedBox(height: 12),
                            _button('Close', () => Navigator.of(context).pop()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Move slide bar to select the MD of point of interest',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Slider(
                      value: poiMd.clamp(0, maxMd <= 0 ? 1 : maxMd),
                      min: 0,
                      max: maxMd <= 0 ? 1 : maxMd,
                      onChanged: maxMd <= 0
                          ? null
                          : (value) => setState(() => poiMd = value),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _sectionMiniChart(point)),
                          const SizedBox(width: 18),
                          Expanded(child: _planMiniChart(point)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleBar(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFC3C9D1))),
      ),
      child: Row(
        children: [
          const Text('Point Calculation', style: TextStyle(fontSize: 14)),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _summaryTable(dynamic point) {
    final rows = [
      ['MD of POI', point.md.toStringAsFixed(1), AppUnits.unitText('(ft)')],
      ['Inc', point.inc.toStringAsFixed(2), AppUnits.unitText('(°)')],
      ['Azi', point.azi.toStringAsFixed(2), AppUnits.unitText('(°)')],
      ['TVD', point.tvd.toStringAsFixed(1), AppUnits.unitText('(ft)')],
      ['Vsec', point.vsec.toStringAsFixed(1), AppUnits.unitText('(ft)')],
      ['N+/S-', point.northSouth.toStringAsFixed(1), AppUnits.unitText('(ft)')],
      ['E+/W-', point.eastWest.toStringAsFixed(1), AppUnits.unitText('(ft)')],
      ['Dogleg', point.dogleg.toStringAsFixed(2), AppUnits.dogleg],
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB9BEC7)),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          return SizedBox(
            height: 42,
            child: Row(
              children: [
                Container(
                  width: 230,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? const Color(0xFF1278D2)
                        : const Color(0xFFF2F2F2),
                    border: const Border(
                      right: BorderSide(color: Color(0xFFB9BEC7)),
                      bottom: BorderSide(color: Color(0xFFB9BEC7)),
                    ),
                  ),
                  child: Text(
                    rows[index][0],
                    style: TextStyle(
                      fontSize: 13,
                      color: index == 0
                          ? Colors.white
                          : const Color(0xFF2F2F2F),
                    ),
                  ),
                ),
                Container(
                  width: 150,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8C9),
                    border: Border(
                      right: BorderSide(color: Color(0xFFB9BEC7)),
                      bottom: BorderSide(color: Color(0xFFB9BEC7)),
                    ),
                  ),
                  child: Text(
                    rows[index][1],
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFB9BEC7)),
                      ),
                    ),
                    child: Text(
                      rows[index][2],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionMiniChart(dynamic point) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB9BEC7)),
      ),
      child: CustomPaint(
        painter: _PointMiniPainter(
          title: 'Section View',
          xLabel: 'Horizontal Displacement ${AppUnits.unitText('(ft)')}',
          yLabel: 'TVD ${AppUnits.unitText('(ft)')}',
          pointX: point.vsec,
          pointY: point.tvd,
          xMax: 500,
          yMax: 500,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _planMiniChart(dynamic point) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB9BEC7)),
      ),
      child: CustomPaint(
        painter: _PointMiniPainter(
          title: 'Plan View',
          xLabel: 'E+/W- ${AppUnits.unitText('(ft)')}',
          yLabel: 'N+/S- ${AppUnits.unitText('(ft)')}',
          pointX: point.eastWest,
          pointY: point.northSouth,
          xMax: 500,
          yMax: 500,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _button(String text, VoidCallback onTap) {
    return SizedBox(
      width: 130,
      height: 42,
      child: OutlinedButton(onPressed: onTap, child: Text(text)),
    );
  }
}

class _PointMiniPainter extends CustomPainter {
  _PointMiniPainter({
    required this.title,
    required this.xLabel,
    required this.yLabel,
    required this.pointX,
    required this.pointY,
    required this.xMax,
    required this.yMax,
  });

  final String title;
  final String xLabel;
  final String yLabel;
  final double pointX;
  final double pointY;
  final double xMax;
  final double yMax;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(74, 70, size.width - 120, size.height - 132);
    final gridPaint = Paint()
      ..color = const Color(0xFF3D3D3D)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF232323)
      ..strokeWidth = 1.1;
    canvas.drawRect(plot, axisPaint);
    for (var i = 0; i <= 10; i++) {
      final x = plot.left + (plot.width * i / 10);
      drawDashedLine(
        canvas,
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        gridPaint,
      );
      final y = plot.top + (plot.height * i / 10);
      drawDashedLine(
        canvas,
        Offset(plot.left, y),
        Offset(plot.right, y),
        gridPaint,
      );
    }
    drawSurveyText(
      canvas,
      title,
      Offset(size.width / 2 - 68, 26),
      fontSize: 20,
    );
    drawSurveyText(
      canvas,
      xLabel,
      Offset(size.width / 2 - 90, size.height - 38),
      fontSize: 14,
      weight: FontWeight.w600,
    );

    canvas.save();
    canvas.translate(22, size.height / 2 + 68);
    canvas.rotate(-1.5708);
    drawSurveyText(
      canvas,
      yLabel,
      Offset(0, 0),
      fontSize: 14,
      weight: FontWeight.w600,
    );
    canvas.restore();

    final clampedX = pointX.clamp(0, xMax);
    final clampedY = pointY.clamp(0, yMax);
    final px = plot.left + (clampedX / xMax) * plot.width;
    final py = plot.bottom - (clampedY / yMax) * plot.height;
    final ring = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(px, py), 9, ring);

    for (var i = 0; i <= 10; i += 2) {
      drawSurveyText(
        canvas,
        ((xMax / 10) * i).toStringAsFixed(0),
        Offset(plot.left + (plot.width * i / 10) - 8, plot.bottom + 10),
        fontSize: 12,
      );
      drawSurveyText(
        canvas,
        ((yMax / 10) * (10 - i)).toStringAsFixed(0),
        Offset(plot.left - 28, plot.top + (plot.height * i / 10) - 8),
        fontSize: 12,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
