import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/hydraulics/controller/recap_hydraulics_controller.dart';

const Color _hydraulicsOuterBorder = Color(0xFF2F92E8);
const Color _hydraulicsCanvas = Color(0xFFF4F4F4);
const Color _hydraulicsPanelBorder = Color(0xFFC8C8C8);
const Color _hydraulicsHeaderFill = Color(0xFFF7F7F7);
const Color _hydraulicsText = Color(0xFF1C1C1C);
const Color _hydraulicsGrid = Color(0xFFD6D6D6);
const Color _hydraulicsTabFill = Color(0xFFEAEAEA);
const Color _hydraulicsLine = Color(0xFF94B7E8);
const Color _hydraulicsPumpLine = Color(0xFFB11F1F);
const Color _hydraulicsBhEcdLine = Color(0xFF0F72C4);
const Color _hydraulicsPoreLine = Color(0xFFFF9A1E);
const Color _hydraulicsFracLine = Color(0xFFB11F1F);

class RecapHydraulicsTabView extends StatefulWidget {
  const RecapHydraulicsTabView({super.key});

  @override
  State<RecapHydraulicsTabView> createState() => _RecapHydraulicsTabViewState();
}

class _RecapHydraulicsTabViewState extends State<RecapHydraulicsTabView> {
  int _selectedTab = 0;

  RecapHydraulicsController get _controller =>
      Get.isRegistered<RecapHydraulicsController>()
      ? Get.find<RecapHydraulicsController>()
      : Get.put(RecapHydraulicsController());

  static const _tabs = [
    _HydraulicsTabMeta(title: 'Graph'),
    _HydraulicsTabMeta(title: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _hydraulicsCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _hydraulicsOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapHydraulicsController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _HydraulicsMessageState(
        title: 'Hydraulics',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty) {
      return _HydraulicsMessageState(
        title: 'Hydraulics',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live hydraulics history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _HydraulicsGraphTab(controller: controller);
      case 1:
        return _HydraulicsTableTab(rows: controller.rows.toList());
      default:
        return _HydraulicsGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _hydraulicsCanvas,
        border: Border(left: BorderSide(color: _hydraulicsPanelBorder)),
      ),
      child: Column(
        children: List.generate(_tabs.length, (index) {
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
                  color: selected ? Colors.white : _hydraulicsTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _hydraulicsPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _hydraulicsOuterBorder
                          : _hydraulicsPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _hydraulicsPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _hydraulicsPanelBorder)
                        : BorderSide.none,
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      _tabs[index].title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _hydraulicsText,
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

class _HydraulicsGraphTab extends StatelessWidget {
  final RecapHydraulicsController controller;

  const _HydraulicsGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _HydraulicsMetricSection(
        label: 'Flow Rate',
        unit: 'gpm',
        series: [
          _HydraulicsSeries(
            values: controller.flowRateSeries,
            color: _hydraulicsLine,
          ),
        ],
      ),
      _HydraulicsMetricSection(
        label: 'Pump P.',
        unit: 'psi',
        series: [
          _HydraulicsSeries(
            label: 'Max.',
            values: controller.pumpPressureSeries,
            color: _hydraulicsPumpLine,
            showInLegend: true,
          ),
        ],
      ),
      _HydraulicsMetricSection(
        label: 'Impact F.',
        unit: 'lbf',
        series: [
          _HydraulicsSeries(
            values: controller.impactForceSeries,
            color: _hydraulicsLine,
          ),
        ],
      ),
      _HydraulicsMetricSection(
        label: 'HSI',
        unit: '',
        series: [
          _HydraulicsSeries(
            values: controller.hsiSeries,
            color: _hydraulicsLine,
          ),
        ],
      ),
      _HydraulicsMetricSection(
        label: 'BH ECD',
        unit: 'ppg',
        series: [
          _HydraulicsSeries(
            values: controller.bhEcdSeries,
            color: _hydraulicsBhEcdLine,
          ),
          _HydraulicsSeries(
            label: 'Pore',
            values: controller.poreSeries,
            color: _hydraulicsPoreLine,
            showInLegend: true,
          ),
          _HydraulicsSeries(
            label: 'Frac.',
            values: controller.fracSeries,
            color: _hydraulicsFracLine,
            showInLegend: true,
          ),
        ],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _hydraulicsPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Hydraulics',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _hydraulicsText,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 8),
                child: CustomPaint(
                  painter: _LegacyHydraulicsGraphPainter(
                    sections: sections,
                    slotCount: math.max(5, controller.rows.length),
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

class _HydraulicsTableTab extends StatelessWidget {
  final List<HydraulicsHistoryRow> rows;

  const _HydraulicsTableTab({required this.rows});

  @override
  Widget build(BuildContext context) {
    final columns = [
      _HydraulicsTableColumn(
        title: 'Flow Rate (gpm)',
        valueFor: (row) => _formatNumber(row.flowRateGpm),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Pump P. (psi)',
        valueFor: (row) => _formatNumber(row.pumpPressurePsi),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Impact F. (lbf)',
        valueFor: (row) => _formatNumber(row.impactForceLbf),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'HSI',
        valueFor: (row) => _formatNumber(row.hsi),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'BH ECD (ppg)',
        valueFor: (row) => _formatNumber(row.bhEcdPpg),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Pore (ppg)',
        valueFor: (row) => _formatNumber(row.porePpg),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Frac. (ppg)',
        valueFor: (row) => _formatNumber(row.fracPpg),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'MW (ppg)',
        valueFor: (row) => _formatNumber(row.mudWeightPpg),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'PV (cP)',
        valueFor: (row) => _formatNumber(row.pv),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'YP (lb/100ft2)',
        valueFor: (row) => _formatNumber(row.yp),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'DH Loss (psi)',
        valueFor: (row) => _formatNumber(row.dhToolsPressureLossPsi),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Motor Loss (psi)',
        valueFor: (row) => _formatNumber(row.motorPressureLossPsi),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Bit Loss (psi)',
        valueFor: (row) => _formatNumber(row.bitPressureLossPsi),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Ann. Loss (psi)',
        valueFor: (row) => _formatNumber(row.annularPressureLossPsi),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Nozzle Area (in2)',
        valueFor: (row) => _formatNumber(row.nozzleAreaIn2, digits: 3),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Nozzle Vel. (ft/s)',
        valueFor: (row) => _formatNumber(row.nozzleVelocityFtSec),
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Sections',
        valueFor: (row) => '${row.segmentCount}',
        alignRight: true,
      ),
      _HydraulicsTableColumn(
        title: 'Interval',
        valueFor: (row) => row.interval.isEmpty ? '-' : row.interval,
      ),
      _HydraulicsTableColumn(
        title: 'Activity',
        valueFor: (row) => row.activity.isEmpty ? '-' : row.activity,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _hydraulicsPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Hydraulics - Table',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _hydraulicsText,
                ),
              ),
            ),
            Expanded(
              child: _LegacyHydraulicsTable(
                rows: rows,
                columns: columns,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyHydraulicsTable extends StatefulWidget {
  final List<HydraulicsHistoryRow> rows;
  final List<_HydraulicsTableColumn> columns;

  const _LegacyHydraulicsTable({
    required this.rows,
    required this.columns,
  });

  @override
  State<_LegacyHydraulicsTable> createState() => _LegacyHydraulicsTableState();
}

class _LegacyHydraulicsTableState extends State<_LegacyHydraulicsTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  static const double _rowHeight = 31;
  static const double _indexWidth = 52;
  static const double _dateWidth = 102;
  static const double _mdWidth = 82;
  static const double _reportWidth = 70;
  static const double _columnWidth = 126;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(
      () => _syncHorizontal(_headerHorizontalController),
    );
    _bodyHorizontalController.addListener(
      () => _syncHorizontal(_bodyHorizontalController),
    );
  }

  void _syncHorizontal(ScrollController source) {
    if (_syncingHorizontal) return;
    _syncingHorizontal = true;
    for (final controller in [
      _headerHorizontalController,
      _bodyHorizontalController,
    ]) {
      if (controller == source || !controller.hasClients) continue;
      controller.jumpTo(
        source.offset.clamp(0, controller.position.maxScrollExtent),
      );
    }
    _syncingHorizontal = false;
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicWidth = widget.columns.length * _columnWidth;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Container(
            height: _rowHeight,
            color: _hydraulicsHeaderFill,
            child: Row(
              children: [
                _headerCell('No', _indexWidth),
                _headerCell('Date', _dateWidth),
                _headerCell('MD (ft)', _mdWidth),
                _headerCell('Rpt #', _reportWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dynamicWidth,
                      child: Row(
                        children: widget.columns
                            .map((column) => _headerCell(column.title, _columnWidth))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: _indexWidth + _dateWidth + _mdWidth + _reportWidth,
                  child: ListView.builder(
                    itemCount: widget.rows.length,
                    itemBuilder: (context, index) {
                      final row = widget.rows[index];
                      return SizedBox(
                        height: _rowHeight,
                        child: Row(
                          children: [
                            _dataCell('${index + 1}', _indexWidth, index),
                            _dataCell(
                              _formatDate(row.reportDate, row.createdAt),
                              _dateWidth,
                              index,
                            ),
                            _dataCell(_formatNumber(row.md), _mdWidth, index),
                            _dataCell(row.reportLabel, _reportWidth, index),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _bodyHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dynamicWidth,
                      child: ListView.builder(
                        itemCount: widget.rows.length,
                        itemBuilder: (context, index) {
                          final row = widget.rows[index];
                          return SizedBox(
                            height: _rowHeight,
                            child: Row(
                              children: widget.columns.map((column) {
                                return _dataCell(
                                  column.valueFor(row),
                                  _columnWidth,
                                  index,
                                  alignRight: column.alignRight,
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _hydraulicsHeaderFill,
        border: Border.all(color: _hydraulicsPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _hydraulicsText,
        ),
      ),
    );
  }

  Widget _dataCell(
    String text,
    double width,
    int rowIndex, {
    bool alignRight = false,
  }) {
    return Container(
      width: width,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: rowIndex.isOdd ? const Color(0xFFF8F8F8) : Colors.white,
        border: Border.all(color: _hydraulicsPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _hydraulicsText),
      ),
    );
  }
}

class _LegacyHydraulicsGraphPainter extends CustomPainter {
  final List<_HydraulicsMetricSection> sections;
  final int slotCount;

  const _LegacyHydraulicsGraphPainter({
    required this.sections,
    required this.slotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftLabelWidth = 70.0;
    const yAxisWidth = 42.0;
    const footerHeight = 30.0;
    const sectionGap = 3.0;

    final usableHeight =
        size.height - footerHeight - (sections.length - 1) * sectionGap;
    final sectionHeight = usableHeight / sections.length;
    final plotLeft = leftLabelWidth + yAxisWidth;
    final plotRight = size.width - 8;
    final slotWidth = slotCount <= 0 ? 0.0 : (plotRight - plotLeft) / slotCount;

    final borderPaint = Paint()
      ..color = _hydraulicsPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _hydraulicsGrid
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int index = 0; index < sections.length; index++) {
      final section = sections[index];
      final top = index * (sectionHeight + sectionGap);
      final bottom = top + sectionHeight;
      final plotRect = Rect.fromLTRB(plotLeft, top, plotRight, bottom);
      final maxValue = _niceMax(section.series);

      canvas.drawRect(plotRect, borderPaint);

      for (int line = 1; line < 5; line++) {
        final y = plotRect.top + plotRect.height * line / 5;
        canvas.drawLine(
          Offset(plotRect.left, y),
          Offset(plotRect.right, y),
          gridPaint,
        );
      }

      for (int column = 1; column < slotCount; column++) {
        final x = plotRect.left + slotWidth * column;
        canvas.drawLine(
          Offset(x, plotRect.top),
          Offset(x, plotRect.bottom),
          gridPaint,
        );
      }

      for (int tick = 0; tick <= 5; tick++) {
        final factor = 1 - (tick / 5);
        final value = maxValue * factor;
        final y = plotRect.top + plotRect.height * tick / 5;
        textPainter.text = TextSpan(
          text: _formatAxisTick(value, maxValue),
          style: const TextStyle(fontSize: 9.5, color: _hydraulicsText),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            plotRect.left - textPainter.width - 6,
            y - textPainter.height / 2,
          ),
        );
      }

      _drawVerticalLabel(
        canvas,
        textPainter,
        label: section.unit.isEmpty
            ? section.label
            : '${section.label}\n(${section.unit})',
        top: top,
        height: sectionHeight,
        width: leftLabelWidth,
      );

      for (final series in section.series) {
        final slotValues = series.values.length >= slotCount
            ? series.values.take(slotCount).toList(growable: false)
            : [
                ...series.values,
                ...List<double?>.filled(
                  slotCount - series.values.length,
                  null,
                ),
              ];
        final linePaint = Paint()
          ..color = series.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
        final pointPaint = Paint()
          ..color = series.color
          ..style = PaintingStyle.fill;
        final path = Path();
        var hasSegment = false;

        for (int pointIndex = 0; pointIndex < slotValues.length; pointIndex++) {
          final value = slotValues[pointIndex];
          if (value == null) {
            hasSegment = false;
            continue;
          }

          final x = plotRect.left + slotWidth * pointIndex + slotWidth / 2;
          final y = plotRect.bottom -
              (plotRect.height * (value / maxValue).clamp(0.0, 1.0));

          if (!hasSegment) {
            path.moveTo(x, y);
            hasSegment = true;
          } else {
            path.lineTo(x, y);
          }

          canvas.drawCircle(Offset(x, y), 2.3, pointPaint);
        }

        if (hasSegment) {
          canvas.drawPath(path, linePaint);
        }
      }

      final legendItems = section.series
          .where((series) => series.showInLegend && series.label.isNotEmpty)
          .toList(growable: false);
      if (legendItems.isNotEmpty) {
        _drawLegend(
          canvas,
          textPainter,
          legendItems: legendItems,
          plotRect: plotRect,
        );
      }
    }

    final footerTop = size.height - footerHeight + 4;
    for (int column = 0; column < slotCount; column++) {
      final x = plotLeft + slotWidth * column + slotWidth / 2;
      textPainter.text = TextSpan(
        text: '${column + 1}',
        style: const TextStyle(fontSize: 10, color: _hydraulicsText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, footerTop));
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _hydraulicsText),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        plotLeft + (plotRight - plotLeft - textPainter.width) / 2,
        size.height - textPainter.height,
      ),
    );
  }

  void _drawVerticalLabel(
    Canvas canvas,
    TextPainter textPainter, {
    required String label,
    required double top,
    required double height,
    required double width,
  }) {
    textPainter.text = TextSpan(
      text: label,
      style: const TextStyle(fontSize: 11, color: _hydraulicsText),
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(12, top + height / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    canvas.drawLine(
      Offset(width, top),
      Offset(width, top + height),
      Paint()
        ..color = _hydraulicsPanelBorder
        ..strokeWidth = 1,
    );
  }

  void _drawLegend(
    Canvas canvas,
    TextPainter textPainter, {
    required List<_HydraulicsSeries> legendItems,
    required Rect plotRect,
  }) {
    final startX = plotRect.right - 112;
    final startY = plotRect.top + 10;

    for (int index = 0; index < legendItems.length; index++) {
      final item = legendItems[index];
      final y = startY + index * 24;

      final squareRect = Rect.fromLTWH(startX, y, 10, 10);
      canvas.drawRect(
        squareRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        squareRect,
        Paint()
          ..color = item.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      canvas.drawLine(
        Offset(startX + 14, y + 5),
        Offset(startX + 40, y + 5),
        Paint()
          ..color = item.color
          ..strokeWidth = 1.8,
      );

      textPainter.text = TextSpan(
        text: item.label,
        style: const TextStyle(fontSize: 10, color: _hydraulicsText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(startX + 44, y - 2));
    }
  }

  double _niceMax(List<_HydraulicsSeries> series) {
    final values = <double>[];
    for (final item in series) {
      for (final value in item.values) {
        if (value != null && value > 0) {
          values.add(value);
        }
      }
    }

    if (values.isEmpty) return 1;

    final maxValue = values.reduce(math.max);
    const steps = [
      1.0,
      2.0,
      5.0,
      10.0,
      15.0,
      20.0,
      25.0,
      50.0,
      75.0,
      100.0,
      150.0,
      200.0,
      250.0,
      500.0,
      750.0,
      1000.0,
      1500.0,
      2000.0,
      5000.0,
    ];
    for (final step in steps) {
      if (maxValue <= step) return step;
    }

    final exponent =
        math.pow(10, (math.log(maxValue) / math.ln10).floor()).toDouble();
    final normalized = maxValue / exponent;
    if (normalized <= 2) return 2 * exponent;
    if (normalized <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  String _formatAxisTick(double value, double maxValue) {
    if (maxValue <= 1) {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    if (maxValue <= 10) {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    if (maxValue < 100) {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _LegacyHydraulicsGraphPainter oldDelegate) {
    return oldDelegate.sections != sections || oldDelegate.slotCount != slotCount;
  }
}

class _HydraulicsMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _HydraulicsMessageState({
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
          border: Border.all(color: _hydraulicsPanelBorder),
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
                  color: _hydraulicsText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _hydraulicsText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HydraulicsMetricSection {
  final String label;
  final String unit;
  final List<_HydraulicsSeries> series;

  const _HydraulicsMetricSection({
    required this.label,
    required this.unit,
    required this.series,
  });
}

class _HydraulicsSeries {
  final String label;
  final List<double?> values;
  final Color color;
  final bool showInLegend;

  const _HydraulicsSeries({
    this.label = '',
    required this.values,
    required this.color,
    this.showInLegend = false,
  });
}

class _HydraulicsTableColumn {
  final String title;
  final String Function(HydraulicsHistoryRow row) valueFor;
  final bool alignRight;

  const _HydraulicsTableColumn({
    required this.title,
    required this.valueFor,
    this.alignRight = false,
  });
}

class _HydraulicsTabMeta {
  final String title;

  const _HydraulicsTabMeta({required this.title});
}

String _formatDate(String raw, String createdAt) {
  final source = raw.trim().isNotEmpty ? raw.trim() : createdAt.trim();
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source.isEmpty ? '-' : source;
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatNumber(double? value, {int digits = 2}) {
  if (value == null) return '-';
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(digits)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
