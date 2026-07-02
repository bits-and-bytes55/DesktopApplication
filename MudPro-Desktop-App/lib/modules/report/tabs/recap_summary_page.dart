import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/widgets/wellbore_controller.dart';

const Color _summaryPageBackground = Color(0xFFF4F6FA);
const Color _summaryPanelBorder = Color(0xFFB8D0EA);
const Color _summaryHeaderFill = Color(0xFF6C9BCF);
const Color _summaryTextColor = Colors.black;
const Color _summaryGridColor = Color(0xFFCFE0F2);
const Color _summaryLineColor = Color(0xFF9FD8EC);
const Color _summaryDepthColor = Color(0xFFC9CA4E);
const Color _summaryCostColor = Color(0xFFFF160C);
const Color _summaryDayColor = Color(0xFFC9CA4E);
const Color _summaryCategoryPrimary = Color(0xFF8AC6D8);
const Color _summaryCategorySecondary = Color(0xFFC3B4DF);

class RecapSummaryPage extends StatelessWidget {
  const RecapSummaryPage({super.key});

  WellboreController get _controller =>
      Get.isRegistered<WellboreController>(tag: 'recap-summary')
      ? Get.find<WellboreController>(tag: 'recap-summary')
      : Get.put(WellboreController(), tag: 'recap-summary');

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _summaryPageBackground,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 34, child: _buildWellboreSection()),
                const SizedBox(width: 4),
                Expanded(flex: 31, child: _buildKpiSection(controller)),
                const SizedBox(width: 4),
                Expanded(
                  flex: 28,
                  child: _buildCostDistributionSection(controller),
                ),
                const SizedBox(width: 4),
                Expanded(flex: 19, child: _buildProgressSection()),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'Well Name: Mudpro well',
                style: TextStyle(fontSize: 11, color: _summaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellboreSection() {
    return _mainPanel(
      title: 'Wellbore Schematic',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'MD/TVD (ft)',
                    style: TextStyle(fontSize: 12, color: _summaryTextColor),
                  ),
                ),
                Text(
                  'Shoe (ft)',
                  style: TextStyle(fontSize: 12, color: _summaryTextColor),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              '0.0   0.0',
              style: TextStyle(fontSize: 11, color: _summaryTextColor),
            ),
            SizedBox(height: 6),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white),
                child: CustomPaint(painter: _RecapSummaryWellborePainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSection(WellboreController controller) {
    return _mainPanel(
      title: 'KPI',
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          children: [
            Expanded(
              child: Obx(
                () => _gaugePanel(
                  title: 'Depth',
                  value: controller.depthKPI.value,
                  maxValue: controller.maxDepthKPI.value,
                  minLabel: '0ft',
                  maxLabel:
                      '${controller.maxDepthKPI.value.toStringAsFixed(1)}ft',
                  valueLabel:
                      '${controller.depthKPI.value.toStringAsFixed(1)}ft : ${(controller.depthKPI.value / controller.maxDepthKPI.value * 100).toStringAsFixed(1)}%',
                  gaugeColor: _summaryDepthColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Obx(
                () => _gaugePanel(
                  title: 'Cost',
                  value: controller.costKPI.value,
                  maxValue: controller.maxCostKPI.value,
                  minLabel: 'Kwd0',
                  maxLabel:
                      'Kwd${controller.maxCostKPI.value.toStringAsFixed(3)}',
                  valueLabel:
                      'Kwd${controller.costKPI.value.toStringAsFixed(3)} : ${(controller.costKPI.value / controller.maxCostKPI.value * 100).toStringAsFixed(1)}%',
                  gaugeColor: _summaryCostColor,
                  footer: 'Plan: Kwd1000.000',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Obx(
                () => _gaugePanel(
                  title: 'Day',
                  value: controller.dayKPI.value,
                  maxValue: controller.maxDayKPI.value,
                  minLabel: '1',
                  maxLabel: controller.maxDayKPI.value.toStringAsFixed(0),
                  valueLabel:
                      '${controller.dayKPI.value.toStringAsFixed(0)} : ${(controller.dayKPI.value / controller.maxDayKPI.value * 100).toStringAsFixed(1)}%',
                  gaugeColor: _summaryDayColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostDistributionSection(WellboreController controller) {
    return _mainPanel(
      title: 'Cost Distribution',
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          children: [
            Expanded(
              flex: 10,
              child: _subPanel(
                title: 'Top 10 Products',
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: CustomPaint(
                    painter: _RecapTopProductsPainter(),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              flex: 9,
              child: _subPanel(
                title: 'All Categories',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Obx(
                    () => _categoryBars(
                      controller.categories
                          .map(
                            (entry) => _SummaryBarItem(
                              label: '${entry['name'] ?? '-'}',
                              value: ((entry['percentage'] as num?) ?? 0)
                                  .toDouble(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return _mainPanel(
      title: 'Progress',
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          children: [
            Expanded(
              child: _subPanel(
                title: 'Depth',
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: CustomPaint(
                    painter: _RecapProgressChartPainter(
                      data: [20, 10],
                      yMin: 10,
                      yMax: 20,
                      yTickLabels: ['10', '12', '14', '16', '18', '20'],
                      xTickLabels: ['1', '2', '3', '4', '5', '6'],
                      xAxisLabel: 'Day',
                      yAxisLabel: 'Depth (ft)',
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _subPanel(
                title: 'Cum. Total Cost',
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: CustomPaint(
                    painter: _RecapProgressChartPainter(
                      data: [0, 6.7, 6.7, 6.7, 6.7],
                      yMin: 0,
                      yMax: 7,
                      yTickLabels: ['0', '2', '4', '6'],
                      xTickLabels: ['0', '1', '2', '3', '4', '5'],
                      xAxisLabel: 'Day',
                      yAxisLabel: 'Cost (1000Kwd)',
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _subPanel(
                title: 'Mud Weight',
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: CustomPaint(
                    painter: _RecapProgressChartPainter(
                      data: [5.0, 5.0, 5.0, 5.0],
                      yMin: 5.0,
                      yMax: 6.0,
                      yTickLabels: ['6', '5.8', '5.6', '5.4', '5.2', '5'],
                      xTickLabels: ['1', '2', '3', '4', '5', '6'],
                      xAxisLabel: 'Day',
                      yAxisLabel: 'MW (ppg)',
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainPanel({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _summaryPanelBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              color: _summaryHeaderFill,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _subPanel({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _summaryPanelBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            alignment: Alignment.center,
            color: _summaryHeaderFill,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _gaugePanel({
    required String title,
    required double value,
    required double maxValue,
    required String minLabel,
    required String maxLabel,
    required String valueLabel,
    required Color gaugeColor,
    String? footer,
  }) {
    return _subPanel(
      title: title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: _RecapGaugePainter(
                  value: value,
                  maxValue: maxValue,
                  minLabel: minLabel,
                  maxLabel: maxLabel,
                  color: gaugeColor,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Text(
              valueLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: _summaryTextColor),
            ),
            if (footer != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: _summaryDepthColor),
                  const SizedBox(width: 6),
                  Text(
                    footer,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _summaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryBars(List<_SummaryBarItem> items) {
    final safeItems = items.isEmpty
        ? const <_SummaryBarItem>[_SummaryBarItem(label: 'No data', value: 0)]
        : items;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            for (int i = 0; i < safeItems.length; i++) ...[
              _categoryBarRow(
                item: safeItems[i],
                width: constraints.maxWidth,
                color: i.isEven
                    ? _summaryCategoryPrimary
                    : _summaryCategorySecondary,
              ),
              if (i != safeItems.length - 1) const SizedBox(height: 12),
            ],
            const Spacer(),
            const Text(
              '(%)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: _summaryTextColor),
            ),
          ],
        );
      },
    );
  }

  Widget _categoryBarRow({
    required _SummaryBarItem item,
    required double width,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: width,
          decoration: BoxDecoration(
            border: Border.all(color: _summaryPanelBorder),
            color: Colors.white,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (item.value / 100).clamp(0.0, 1.0),
              child: Container(
                height: double.infinity,
                color: color,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${item.label}, ${item.value.toStringAsFixed(1)}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _summaryTextColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryBarItem {
  final String label;
  final double value;

  const _SummaryBarItem({required this.label, required this.value});
}

class _RecapSummaryWellborePainter extends CustomPainter {
  const _RecapSummaryWellborePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 1;
    final guidePaint = Paint()
      ..color = const Color(0xFF505050)
      ..strokeWidth = 1;
    final markerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final pipeFill = Paint()
      ..color = const Color(0xFFB8B8B8)
      ..style = PaintingStyle.fill;
    final pipeStroke = Paint()
      ..color = const Color(0xFF3C3C3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisX = size.width * 0.11;
    final startY = size.height * 0.05;
    final endY = size.height * 0.96;

    canvas.drawLine(Offset(axisX, startY), Offset(axisX, endY), axisPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 10; i++) {
      final progress = i / 10;
      final y = startY + (endY - startY) * progress;
      final label = i == 10 ? '10.0' : i.toDouble().toStringAsFixed(1);

      canvas.drawLine(Offset(axisX - 4, y), Offset(axisX + 4, y), guidePaint);
      if (i < 10) {
        final midY = y + (endY - startY) / 20;
        canvas.drawLine(
          Offset(axisX - 3, midY),
          Offset(axisX + 3, midY),
          guidePaint,
        );
      }

      canvas.drawCircle(Offset(axisX, y), 4, markerPaint);

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 11, color: _summaryTextColor),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(axisX - textPainter.width - 10, y - 7));
      textPainter.paint(canvas, Offset(axisX + 10, y - 7));
    }

    final leftPipe = Rect.fromLTWH(
      size.width * 0.42,
      size.height * 0.05,
      size.width * 0.05,
      size.height * 0.91,
    );
    final rightPipe = Rect.fromLTWH(
      size.width * 0.90,
      size.height * 0.05,
      size.width * 0.05,
      size.height * 0.91,
    );

    for (final rect in [leftPipe, rightPipe]) {
      canvas.drawRect(rect, pipeFill);
      canvas.drawRect(rect, pipeStroke);

      final leftShoe = Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left - 8, rect.bottom)
        ..lineTo(rect.left, rect.bottom - 6)
        ..close();
      final rightShoe = Path()
        ..moveTo(rect.right, rect.bottom)
        ..lineTo(rect.right + 8, rect.bottom)
        ..lineTo(rect.right, rect.bottom - 6)
        ..close();

      canvas.drawPath(leftShoe, Paint()..color = Colors.black);
      canvas.drawPath(rightShoe, Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecapGaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final String minLabel;
  final String maxLabel;
  final Color color;

  const _RecapGaugePainter({
    required this.value,
    required this.maxValue,
    required this.minLabel,
    required this.maxLabel,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clampedMax = maxValue <= 0 ? 1.0 : maxValue;
    final ratio = (value / clampedMax).clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height - 12);
    final radius = math.min(size.width * 0.34, size.height * 0.72);
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = const Color(0xFFE5E5E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(arcRect, math.pi, math.pi, false, backgroundPaint);
    canvas.drawArc(arcRect, math.pi, math.pi * ratio, false, valuePaint);

    final needleAngle = math.pi + math.pi * ratio;
    final needleEnd = Offset(
      center.dx + (radius - 10) * math.cos(needleAngle),
      center.dy + (radius - 10) * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = const Color(0xFF334159)
      ..strokeWidth = 3;

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 7, Paint()..color = const Color(0xFF334159));

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: minLabel,
      style: const TextStyle(fontSize: 10, color: _summaryTextColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(14, size.height - textPainter.height - 4));

    textPainter.text = TextSpan(
      text: maxLabel,
      style: const TextStyle(fontSize: 10, color: _summaryTextColor),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width - textPainter.width - 14,
        size.height - textPainter.height - 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RecapGaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.minLabel != minLabel ||
        oldDelegate.maxLabel != maxLabel ||
        oldDelegate.color != color;
  }
}

class _RecapTopProductsPainter extends CustomPainter {
  const _RecapTopProductsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final left = 10.0;
    final top = 8.0;
    final right = size.width - 10;
    final bottom = size.height - 30;
    final frame = Rect.fromLTRB(left, top, right, bottom);

    final borderPaint = Paint()
      ..color = _summaryPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _summaryGridColor
      ..strokeWidth = 1;
    final centerLinePaint = Paint()
      ..color = const Color(0xFF8CB6F0)
      ..strokeWidth = 1.5;

    canvas.drawRect(frame, borderPaint);

    for (int i = 1; i < 4; i++) {
      final x = frame.left + frame.width * i / 4;
      canvas.drawLine(Offset(x, frame.top), Offset(x, frame.bottom), gridPaint);
    }
    final midY = frame.top + frame.height / 2;
    canvas.drawLine(
      Offset(frame.left, midY),
      Offset(frame.right, midY),
      gridPaint,
    );

    final centerX = frame.left + frame.width / 2;
    canvas.drawLine(
      Offset(centerX, frame.top + 20),
      Offset(centerX, frame.bottom - 20),
      centerLinePaint,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const tickLabels = ['-2', '-1', '0', '1', '2'];
    for (int i = 0; i < tickLabels.length; i++) {
      final x = frame.left + frame.width * i / 4;
      textPainter.text = TextSpan(
        text: tickLabels[i],
        style: const TextStyle(fontSize: 10, color: _summaryTextColor),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, frame.bottom + 6),
      );
    }

    textPainter.text = const TextSpan(
      text: '(%)',
      style: TextStyle(fontSize: 11, color: _summaryTextColor),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(frame.center.dx - textPainter.width / 2, size.height - 16),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecapProgressChartPainter extends CustomPainter {
  final List<double> data;
  final double yMin;
  final double yMax;
  final List<String> yTickLabels;
  final List<String> xTickLabels;
  final String xAxisLabel;
  final String yAxisLabel;

  const _RecapProgressChartPainter({
    required this.data,
    required this.yMin,
    required this.yMax,
    required this.yTickLabels,
    required this.xTickLabels,
    required this.xAxisLabel,
    required this.yAxisLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = 38.0;
    final top = 10.0;
    final right = size.width - 8;
    final bottom = size.height - 26;
    final chart = Rect.fromLTRB(left, top, right, bottom);

    final borderPaint = Paint()
      ..color = _summaryPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _summaryGridColor
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = _summaryLineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(chart, borderPaint);

    for (int i = 1; i < xTickLabels.length; i++) {
      final x = chart.left + chart.width * i / (xTickLabels.length - 1);
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), gridPaint);
    }

    final yDivisions = math.max(1, yTickLabels.length - 1);
    for (int i = 1; i < yTickLabels.length; i++) {
      final y = chart.top + chart.height * i / yDivisions;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    if (data.isNotEmpty) {
      final path = Path();
      final range = (yMax - yMin).abs() < 0.0001 ? 1.0 : (yMax - yMin);
      for (int i = 0; i < data.length; i++) {
        final x = data.length == 1
            ? chart.left
            : chart.left + chart.width * i / (data.length - 1);
        final normalized = ((data[i] - yMin) / range).clamp(0.0, 1.0);
        final y = chart.bottom - chart.height * normalized;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < yTickLabels.length; i++) {
      final y = chart.top + chart.height * i / yDivisions;
      textPainter.text = TextSpan(
        text: yTickLabels[i],
        style: const TextStyle(fontSize: 10, color: _summaryTextColor),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, y - textPainter.height / 2));
    }

    final xDivisions = math.max(1, xTickLabels.length - 1);
    for (int i = 0; i < xTickLabels.length; i++) {
      final x = chart.left + chart.width * i / xDivisions;
      textPainter.text = TextSpan(
        text: xTickLabels[i],
        style: const TextStyle(fontSize: 10, color: _summaryTextColor),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chart.bottom + 4),
      );
    }

    textPainter.text = TextSpan(
      text: xAxisLabel,
      style: const TextStyle(fontSize: 11, color: _summaryTextColor),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(chart.center.dx - textPainter.width / 2, size.height - 14),
    );

    textPainter.text = TextSpan(
      text: yAxisLabel,
      style: const TextStyle(fontSize: 11, color: _summaryTextColor),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(12, chart.center.dy + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RecapProgressChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.yMin != yMin ||
        oldDelegate.yMax != yMax ||
        oldDelegate.yTickLabels != yTickLabels ||
        oldDelegate.xTickLabels != xTickLabels ||
        oldDelegate.xAxisLabel != xAxisLabel ||
        oldDelegate.yAxisLabel != yAxisLabel;
  }
}
