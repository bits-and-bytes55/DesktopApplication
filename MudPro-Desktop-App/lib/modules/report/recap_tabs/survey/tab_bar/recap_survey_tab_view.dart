import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/survey/controller/recap_survey_controller.dart';

const Color _surveyOuterBorder = Color(0xFFB8D0EA);
const Color _surveyCanvas = Color(0xFFF4F6FA);
const Color _surveyPanelBorder = Color(0xFFB8D0EA);
const Color _surveyText = Color(0xFF1C1C1C);
const Color _surveyGrid = Color(0xFF2B2B2B);
const Color _surveyTabFill = Color(0xFFEAF3FC);
const Color _surveyAxisRed = Color(0xFFFF2B2B);
const Color _surveyPlotFill = Color(0xFFF4F6FA);
const Color _surveyLine = Color(0xFFFF2B2B);

class RecapSurveyTabView extends StatefulWidget {
  const RecapSurveyTabView({super.key});

  @override
  State<RecapSurveyTabView> createState() => _RecapSurveyTabViewState();
}

class _RecapSurveyTabViewState extends State<RecapSurveyTabView> {
  int _selectedTab = 0;

  RecapSurveyController get _controller =>
      Get.isRegistered<RecapSurveyController>()
      ? Get.find<RecapSurveyController>()
      : Get.put(RecapSurveyController());

  static const _tabs = [
    _SurveyTabMeta(title: 'Graph'),
    _SurveyTabMeta(title: 'Graph 3D'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _surveyCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _surveyOuterBorder, width: 1.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: Obx(() => _buildContent(controller))),
            _buildVerticalTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RecapSurveyController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _SurveyMessageState(
        title: 'Survey',
        message: controller.errorMessage.value,
      );
    }

    switch (_selectedTab) {
      case 0:
        return _SurveyGraphTab(controller: controller);
      case 1:
        return _Survey3DTab(controller: controller);
      default:
        return _SurveyGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 34,
      decoration: const BoxDecoration(
        color: _surveyCanvas,
        border: Border(left: BorderSide(color: _surveyPanelBorder)),
      ),
      child: Column(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final selected = index == _selectedTab;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? Colors.white : _surveyTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _surveyPanelBorder),
                    left: BorderSide(
                      color: selected ? _surveyOuterBorder : _surveyPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _surveyPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _surveyPanelBorder)
                        : BorderSide.none,
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      tab.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _surveyText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SurveyGraphTab extends StatelessWidget {
  final RecapSurveyController controller;

  const _SurveyGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _surveyPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.emptyMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  controller.emptyMessage.value,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 10, 8),
                child: CustomPaint(
                  painter: _LegacySurveyGraphPainter(
                    rows: controller.rows.toList(growable: false),
                    wellName: controller.wellName,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Survey3DTab extends StatelessWidget {
  final RecapSurveyController controller;

  const _Survey3DTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _surveyPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: Text(
                'Survey 3D View',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _surveyText,
                ),
              ),
            ),
            if (controller.emptyMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: Text(
                  controller.emptyMessage.value,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                child: CustomPaint(
                  painter: _LegacySurvey3DPainter(
                    rows: controller.rows.toList(growable: false),
                    wellName: controller.wellName,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacySurveyGraphPainter extends CustomPainter {
  final List<SurveyHistoryRow> rows;
  final String wellName;

  const _LegacySurveyGraphPainter({
    required this.rows,
    required this.wellName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topMargin = 16.0;
    const leftMargin = 28.0;
    const rightMargin = 18.0;
    const bottomMargin = 28.0;
    const panelGapX = 42.0;
    const panelGapY = 52.0;
    const tabReserve = 26.0;

    final topPanelHeight = (size.height * 0.38).clamp(170.0, 230.0);
    final bottomPanelHeight =
        size.height - topMargin - topPanelHeight - panelGapY - bottomMargin;
    final topPanelWidth =
        ((size.width - leftMargin - rightMargin - tabReserve - panelGapX) / 2)
            .clamp(240.0, 420.0);

    final sectionRect = Rect.fromLTWH(
      leftMargin + 120,
      topMargin + 24,
      topPanelWidth * 0.58,
      topPanelHeight * 0.78,
    );
    final planRect = Rect.fromLTWH(
      size.width - rightMargin - tabReserve - (topPanelWidth * 0.58) - 80,
      topMargin + 24,
      topPanelWidth * 0.58,
      topPanelHeight * 0.78,
    );
    final doglegRect = Rect.fromLTWH(
      leftMargin + 52,
      sectionRect.bottom + panelGapY,
      size.width - leftMargin - rightMargin - tabReserve - 60,
      math.max(180.0, bottomPanelHeight - 12),
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final titleStyle = const TextStyle(fontSize: 16, color: _surveyText);
    final labelStyle = const TextStyle(fontSize: 12, color: _surveyText);
    final tickStyle = const TextStyle(fontSize: 11, color: _surveyText);
    final gridPaint = Paint()
      ..color = _surveyGrid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = _surveyAxisRed
      ..strokeWidth = 2;
    final linePaint = Paint()
      ..color = _surveyLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final legendPaint = Paint()
      ..color = _surveyLine
      ..strokeWidth = 2.5;

    final usableRows = rows.where((row) => row.hasAnySurveyData).toList(growable: false);

    textPainter.text = TextSpan(text: 'Section View', style: titleStyle);
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(sectionRect.center.dx - (textPainter.width / 2), topMargin),
    );

    textPainter.text = TextSpan(text: 'Plan View', style: titleStyle);
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(planRect.center.dx - (textPainter.width / 2), topMargin),
    );

    textPainter.text = TextSpan(text: 'Dogleg', style: titleStyle);
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(doglegRect.center.dx - (textPainter.width / 2), doglegRect.top - 28),
    );

    final sectionBounds = _sectionBounds(usableRows);
    final planBounds = _planBounds(usableRows);
    final doglegBounds = _doglegBounds(usableRows);

    _drawGridPanel(
      canvas: canvas,
      rect: sectionRect,
      xTicks: sectionBounds.xTicks,
      yTicks: sectionBounds.yTicks,
      xLabel: 'Horizontal Displacement (ft)',
      yLabel: 'TVD (ft)',
      xLabelStyle: labelStyle,
      yLabelStyle: labelStyle,
      tickStyle: tickStyle,
      textPainter: textPainter,
      gridPaint: gridPaint,
      axisPaint: axisPaint,
      invertYLabels: false,
      leftAxisOnly: true,
      xFormatter: _formatTickCompact,
      yFormatter: _formatTickCompact,
    );

    _drawGridPanel(
      canvas: canvas,
      rect: planRect,
      xTicks: planBounds.xTicks,
      yTicks: planBounds.yTicks,
      xLabel: 'E+/W- (ft)',
      yLabel: 'N+/S- (ft)',
      xLabelStyle: labelStyle,
      yLabelStyle: labelStyle,
      tickStyle: tickStyle,
      textPainter: textPainter,
      gridPaint: gridPaint,
      axisPaint: axisPaint,
      invertYLabels: false,
      leftAxisOnly: false,
      xFormatter: _formatTickCompact,
      yFormatter: _formatTickCompact,
    );

    _drawGridPanel(
      canvas: canvas,
      rect: doglegRect,
      xTicks: doglegBounds.xTicks,
      yTicks: doglegBounds.yTicks,
      xLabel: 'Dogleg Severity (°/100ft)',
      yLabel: 'MD (ft)',
      xLabelStyle: labelStyle,
      yLabelStyle: labelStyle,
      tickStyle: tickStyle,
      textPainter: textPainter,
      gridPaint: gridPaint,
      axisPaint: axisPaint,
      invertYLabels: false,
      leftAxisOnly: true,
      xFormatter: _formatTickCompact,
      yFormatter: _formatTickCompact,
    );

    _drawSectionPath(
      canvas: canvas,
      rect: sectionRect,
      rows: usableRows,
      bounds: sectionBounds,
      paint: linePaint,
    );
    _drawPlanPath(
      canvas: canvas,
      rect: planRect,
      rows: usableRows,
      bounds: planBounds,
      paint: linePaint,
    );
    _drawDoglegPath(
      canvas: canvas,
      rect: doglegRect,
      rows: usableRows,
      bounds: doglegBounds,
      paint: linePaint,
    );

    final legendY = size.height - 18;
    final lineStartX = doglegRect.center.dx - 80;
    canvas.drawLine(
      Offset(lineStartX, legendY),
      Offset(lineStartX + 32, legendY),
      legendPaint,
    );

    textPainter.text = TextSpan(
      text: wellName,
      style: const TextStyle(fontSize: 12, color: _surveyText),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(lineStartX + 40, legendY - 8));
  }

  void _drawSectionPath({
    required Canvas canvas,
    required Rect rect,
    required List<SurveyHistoryRow> rows,
    required _SectionBounds bounds,
    required Paint paint,
  }) {
    final points = rows
        .where((row) => row.tvd > 0 || row.horizontalDisplacement > 0)
        .map((row) => Offset(row.horizontalDisplacement, row.tvd))
        .toList(growable: false);
    _drawPolyline(
      canvas: canvas,
      rect: rect,
      points: points,
      xMin: bounds.minX,
      xMax: bounds.maxX,
      yMin: 0,
      yMax: bounds.maxY,
      invertY: true,
      paint: paint,
    );
  }

  void _drawPlanPath({
    required Canvas canvas,
    required Rect rect,
    required List<SurveyHistoryRow> rows,
    required _PlanBounds bounds,
    required Paint paint,
  }) {
    final points = rows
        .map((row) => Offset(row.eastWest, row.northSouth))
        .toList(growable: false);
    _drawPolyline(
      canvas: canvas,
      rect: rect,
      points: points,
      xMin: bounds.minX,
      xMax: bounds.maxX,
      yMin: bounds.minY,
      yMax: bounds.maxY,
      invertY: true,
      paint: paint,
    );
  }

  void _drawDoglegPath({
    required Canvas canvas,
    required Rect rect,
    required List<SurveyHistoryRow> rows,
    required _DoglegBounds bounds,
    required Paint paint,
  }) {
    final points = rows
        .where((row) => row.md > 0 || row.doglegSeverity > 0)
        .map((row) => Offset(row.doglegSeverity, row.md))
        .toList(growable: false);
    _drawPolyline(
      canvas: canvas,
      rect: rect,
      points: points,
      xMin: 0,
      xMax: bounds.maxX,
      yMin: 0,
      yMax: bounds.maxY,
      invertY: true,
      paint: paint,
    );
  }

  void _drawPolyline({
    required Canvas canvas,
    required Rect rect,
    required List<Offset> points,
    required double xMin,
    required double xMax,
    required double yMin,
    required double yMax,
    required bool invertY,
    required Paint paint,
  }) {
    if (points.isEmpty) return;

    final path = Path();
    for (int index = 0; index < points.length; index++) {
      final point = points[index];
      final dx = _mapValue(point.dx, xMin, xMax, rect.left, rect.right);
      final dy = invertY
          ? _mapValue(point.dy, yMin, yMax, rect.top, rect.bottom)
          : _mapValue(point.dy, yMin, yMax, rect.bottom, rect.top);
      if (index == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawGridPanel({
    required Canvas canvas,
    required Rect rect,
    required List<double> xTicks,
    required List<double> yTicks,
    required String xLabel,
    required String yLabel,
    required TextStyle xLabelStyle,
    required TextStyle yLabelStyle,
    required TextStyle tickStyle,
    required TextPainter textPainter,
    required Paint gridPaint,
    required Paint axisPaint,
    required bool invertYLabels,
    required bool leftAxisOnly,
    required String Function(double) xFormatter,
    required String Function(double) yFormatter,
  }) {
    canvas.drawRect(
      rect,
      Paint()
        ..color = _surveyPlotFill
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(rect, gridPaint);

    final verticalDivisions = math.max(1, xTicks.length - 1);
    for (int i = 0; i <= verticalDivisions; i++) {
      final x = rect.left + (rect.width * i / verticalDivisions);
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }

    final horizontalDivisions = math.max(1, yTicks.length - 1);
    for (int i = 0; i <= horizontalDivisions; i++) {
      final y = rect.top + (rect.height * i / horizontalDivisions);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }

    if (leftAxisOnly) {
      canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, rect.bottom), axisPaint);
    }

    for (int i = 0; i < xTicks.length; i++) {
      final x = rect.left + (rect.width * i / math.max(1, xTicks.length - 1));
      textPainter.text = TextSpan(text: xFormatter(xTicks[i]), style: tickStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), rect.bottom + 8),
      );
    }

    for (int i = 0; i < yTicks.length; i++) {
      final y = rect.top + (rect.height * i / math.max(1, yTicks.length - 1));
      final value = invertYLabels ? yTicks.reversed.toList()[i] : yTicks[i];
      textPainter.text = TextSpan(text: yFormatter(value), style: tickStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(rect.left - textPainter.width - 8, y - (textPainter.height / 2)),
      );
    }

    textPainter.text = TextSpan(text: xLabel, style: xLabelStyle);
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(rect.center.dx - (textPainter.width / 2), rect.bottom + 36),
    );

    textPainter.text = TextSpan(text: yLabel, style: yLabelStyle);
    textPainter.layout();
    canvas.save();
    canvas.translate(rect.left - 52, rect.center.dy + (textPainter.width / 2));
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  _SectionBounds _sectionBounds(List<SurveyHistoryRow> rows) {
    final maxHd = rows.fold<double>(
      0,
      (maxValue, row) => math.max(maxValue, row.horizontalDisplacement),
    );
    final maxTvd = rows.fold<double>(
      0,
      (maxValue, row) => math.max(maxValue, math.max(row.tvd, row.md)),
    );
    final xMax = _nicePositiveMax(maxHd, fallback: 10);
    final yMax = _nicePositiveMax(maxTvd, fallback: 10);
    return _SectionBounds(
      minX: 0,
      maxX: xMax,
      maxY: yMax,
      xTicks: _positiveTicks(0, xMax, 5),
      yTicks: _positiveTicks(0, yMax, 6),
    );
  }

  _PlanBounds _planBounds(List<SurveyHistoryRow> rows) {
    final eastValues = rows.map((row) => row.eastWest).toList(growable: false);
    final northValues = rows.map((row) => row.northSouth).toList(growable: false);

    if (eastValues.isEmpty || northValues.isEmpty) {
      return const _PlanBounds(
        minX: 0,
        maxX: 4,
        minY: -2,
        maxY: 2,
        xTicks: [0, 1, 2, 3, 4],
        yTicks: [-2, -1, 0, 1, 2],
      );
    }

    final minX = eastValues.reduce(math.min);
    final maxX = eastValues.reduce(math.max);
    final minY = northValues.reduce(math.min);
    final maxY = northValues.reduce(math.max);

    final resolvedX = _niceRange(minX, maxX, fallbackMin: 0, fallbackMax: 4);
    final resolvedY = _niceRange(minY, maxY, fallbackMin: -2, fallbackMax: 2);

    return _PlanBounds(
      minX: resolvedX.$1,
      maxX: resolvedX.$2,
      minY: resolvedY.$1,
      maxY: resolvedY.$2,
      xTicks: _rangeTicks(resolvedX.$1, resolvedX.$2, 5),
      yTicks: _rangeTicks(resolvedY.$1, resolvedY.$2, 5),
    );
  }

  _DoglegBounds _doglegBounds(List<SurveyHistoryRow> rows) {
    final maxDogleg = rows.fold<double>(
      0,
      (maxValue, row) => math.max(maxValue, row.doglegSeverity),
    );
    final maxDepth = rows.fold<double>(
      0,
      (maxValue, row) => math.max(maxValue, row.md),
    );
    final xMax = _nicePositiveMax(maxDogleg, fallback: 1);
    final yMax = _nicePositiveMax(maxDepth, fallback: 10);
    return _DoglegBounds(
      maxX: xMax,
      maxY: yMax,
      xTicks: _positiveTicks(0, xMax, 6),
      yTicks: _positiveTicks(0, yMax, 6),
    );
  }

  double _nicePositiveMax(double value, {required double fallback}) {
    if (value <= 0) return fallback;
    if (value <= 1) return 1;
    if (value <= 2) return 2;
    if (value <= 4) return 4;
    if (value <= 5) return 5;
    if (value <= 10) return 10;
    if (value <= 20) return 20;
    if (value <= 50) return 50;
    if (value <= 100) return 100;
    if (value <= 500) return 500;
    if (value <= 1000) return 1000;

    final exponent = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();
    final scaled = value / exponent;
    if (scaled <= 2) return 2 * exponent;
    if (scaled <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  (double, double) _niceRange(
    double minValue,
    double maxValue, {
    required double fallbackMin,
    required double fallbackMax,
  }) {
    if (minValue == 0 && maxValue == 0) {
      return (fallbackMin, fallbackMax);
    }

    if ((maxValue - minValue).abs() < 0.001) {
      final pad = math.max(1.0, maxValue.abs() * 0.25);
      return (minValue - pad, maxValue + pad);
    }

    final pad = (maxValue - minValue) * 0.12;
    return (minValue - pad, maxValue + pad);
  }

  List<double> _positiveTicks(double min, double max, int count) {
    if (count <= 1) return [min, max];
    final step = (max - min) / (count - 1);
    return List<double>.generate(count, (index) => min + (step * index));
  }

  List<double> _rangeTicks(double min, double max, int count) {
    if (count <= 1) return [min, max];
    final step = (max - min) / (count - 1);
    return List<double>.generate(count, (index) => min + (step * index));
  }

  double _mapValue(double value, double min, double max, double start, double end) {
    if ((max - min).abs() < 0.00001) {
      return start + ((end - start) / 2);
    }
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return start + ((end - start) * normalized);
  }

  @override
  bool shouldRepaint(covariant _LegacySurveyGraphPainter oldDelegate) {
    return oldDelegate.rows != rows || oldDelegate.wellName != wellName;
  }
}

class _LegacySurvey3DPainter extends CustomPainter {
  final List<SurveyHistoryRow> rows;
  final String wellName;

  const _LegacySurvey3DPainter({
    required this.rows,
    required this.wellName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final framePaint = Paint()
      ..color = _surveyGrid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = _surveyLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final box = Rect.fromLTWH(40, 40, size.width - 80, size.height - 110);
    final depth = math.min(box.width, box.height) * 0.18;

    final front = box;
    final back = Rect.fromLTWH(
      box.left + depth,
      box.top - depth * 0.55,
      box.width,
      box.height,
    );

    canvas.drawRect(front, framePaint);
    canvas.drawRect(back, framePaint);
    canvas.drawLine(front.topLeft, back.topLeft, framePaint);
    canvas.drawLine(front.topRight, back.topRight, framePaint);
    canvas.drawLine(front.bottomLeft, back.bottomLeft, framePaint);
    canvas.drawLine(front.bottomRight, back.bottomRight, framePaint);

    for (int i = 1; i < 5; i++) {
      final t = i / 5;
      canvas.drawLine(
        Offset(front.left + (front.width * t), front.top),
        Offset(front.left + (front.width * t), front.bottom),
        framePaint,
      );
      canvas.drawLine(
        Offset(front.left, front.top + (front.height * t)),
        Offset(front.right, front.top + (front.height * t)),
        framePaint,
      );
    }

    final usableRows = rows.where((row) => row.hasAnySurveyData).toList(growable: false);
    if (usableRows.isNotEmpty) {
      final minX = usableRows.map((row) => row.eastWest).reduce(math.min);
      final maxX = usableRows.map((row) => row.eastWest).reduce(math.max);
      final minY = usableRows.map((row) => row.northSouth).reduce(math.min);
      final maxY = usableRows.map((row) => row.northSouth).reduce(math.max);
      final maxZ = usableRows
          .map((row) => math.max(row.tvd, row.md))
          .fold<double>(0, math.max);

      final path = Path();
      for (int index = 0; index < usableRows.length; index++) {
        final row = usableRows[index];
        final point = _project3D(
          x: row.eastWest,
          y: row.northSouth,
          z: math.max(row.tvd, row.md),
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          maxZ: maxZ <= 0 ? 1 : maxZ,
          front: front,
          depth: depth,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    textPainter.text = const TextSpan(
      text: 'Projected well path',
      style: TextStyle(fontSize: 12, color: _surveyText),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height - 58),
    );

    canvas.drawLine(
      Offset((size.width / 2) - 70, size.height - 28),
      Offset((size.width / 2) - 34, size.height - 28),
      linePaint,
    );
    textPainter.text = TextSpan(
      text: wellName,
      style: const TextStyle(fontSize: 12, color: _surveyText),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width / 2) - 24, size.height - 36));
  }

  Offset _project3D({
    required double x,
    required double y,
    required double z,
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
    required double maxZ,
    required Rect front,
    required double depth,
  }) {
    final safeX = (maxX - minX).abs() < 0.001 ? 0.5 : (x - minX) / (maxX - minX);
    final safeY = (maxY - minY).abs() < 0.001 ? 0.5 : (y - minY) / (maxY - minY);
    final safeZ = maxZ <= 0 ? 0 : (z / maxZ).clamp(0.0, 1.0);

    final baseX = front.left + (front.width * safeX);
    final baseY = front.bottom - (front.height * safeZ);
    final offsetX = depth * (safeY - 0.5) * 0.9;
    final offsetY = depth * (safeY - 0.5) * 0.45;
    return Offset(baseX + offsetX, baseY - offsetY);
  }

  @override
  bool shouldRepaint(covariant _LegacySurvey3DPainter oldDelegate) {
    return oldDelegate.rows != rows || oldDelegate.wellName != wellName;
  }
}

class _SurveyMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _SurveyMessageState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _surveyPanelBorder),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _surveyText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _surveyText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurveyTabMeta {
  final String title;

  const _SurveyTabMeta({required this.title});
}

class _SectionBounds {
  final double minX;
  final double maxX;
  final double maxY;
  final List<double> xTicks;
  final List<double> yTicks;

  const _SectionBounds({
    required this.minX,
    required this.maxX,
    required this.maxY,
    required this.xTicks,
    required this.yTicks,
  });
}

class _PlanBounds {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final List<double> xTicks;
  final List<double> yTicks;

  const _PlanBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.xTicks,
    required this.yTicks,
  });
}

class _DoglegBounds {
  final double maxX;
  final double maxY;
  final List<double> xTicks;
  final List<double> yTicks;

  const _DoglegBounds({
    required this.maxX,
    required this.maxY,
    required this.xTicks,
    required this.yTicks,
  });
}

String _formatTickCompact(double value) {
  if (value.abs() >= 1000) {
    return value.toStringAsFixed(0);
  }
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
