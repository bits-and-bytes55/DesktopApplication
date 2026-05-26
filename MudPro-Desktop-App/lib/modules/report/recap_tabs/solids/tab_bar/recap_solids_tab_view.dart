import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/solids/controller/recap_solids_controller.dart';

const Color _solidsOuterBorder = Color(0xFF2F92E8);
const Color _solidsCanvas = Color(0xFFF4F4F4);
const Color _solidsPanelBorder = Color(0xFFC8C8C8);
const Color _solidsHeaderFill = Color(0xFFF7F7F7);
const Color _solidsText = Color(0xFF1C1C1C);
const Color _solidsGrid = Color(0xFFD6D6D6);
const Color _solidsTabFill = Color(0xFFEAEAEA);
const Color _solidsSample1 = Color(0xFF8DB5E8);
const Color _solidsSample2 = Color(0xFF8FD1E3);
const Color _solidsSample3 = Color(0xFFC4B2DE);

class RecapSolidsTabView extends StatefulWidget {
  const RecapSolidsTabView({super.key});

  @override
  State<RecapSolidsTabView> createState() => _RecapSolidsTabViewState();
}

class _RecapSolidsTabViewState extends State<RecapSolidsTabView> {
  int _selectedTab = 0;

  RecapSolidsController get _controller =>
      Get.isRegistered<RecapSolidsController>()
      ? Get.find<RecapSolidsController>()
      : Get.put(RecapSolidsController());

  static const _tabs = [
    _SolidsTabMeta(title: 'Graph'),
    _SolidsTabMeta(title: 'Table - Sample 1'),
    _SolidsTabMeta(title: 'Table - Sample 2'),
    _SolidsTabMeta(title: 'Table - Sample 3'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _solidsCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _solidsOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapSolidsController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _SolidsMessageState(
        title: 'Solids Analysis',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty || controller.emptyMessage.value.isNotEmpty) {
      return _SolidsMessageState(
        title: 'Solids Analysis',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live solids-analysis history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _SolidsGraphTab(controller: controller);
      case 1:
        return _SolidsTableTab(rows: controller.rows.toList(), sampleIndex: 0);
      case 2:
        return _SolidsTableTab(rows: controller.rows.toList(), sampleIndex: 1);
      case 3:
        return _SolidsTableTab(rows: controller.rows.toList(), sampleIndex: 2);
      default:
        return _SolidsGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _solidsCanvas,
        border: Border(left: BorderSide(color: _solidsPanelBorder)),
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
                  color: selected ? Colors.white : _solidsTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _solidsPanelBorder),
                    left: BorderSide(
                      color: selected ? _solidsOuterBorder : _solidsPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _solidsPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _solidsPanelBorder)
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
                        color: _solidsText,
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

class _SolidsGraphTab extends StatelessWidget {
  final RecapSolidsController controller;

  const _SolidsGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _SolidsMetricSection(
        label: 'Corr. Solids',
        unit: '%',
        series: [
          _SolidsSeries(
            label: 'Sample 1',
            color: _solidsSample1,
            values: controller.correctedSolidsSeries(0),
          ),
          _SolidsSeries(
            label: 'Sample 2',
            color: _solidsSample2,
            values: controller.correctedSolidsSeries(1),
          ),
          _SolidsSeries(
            label: 'Sample 3',
            color: _solidsSample3,
            values: controller.correctedSolidsSeries(2),
          ),
        ],
      ),
      _SolidsMetricSection(
        label: 'Diss. Solids',
        unit: '%',
        series: [
          _SolidsSeries(
            label: 'Sample 1',
            color: _solidsSample1,
            values: controller.dissolvedSolidsSeries(0),
          ),
          _SolidsSeries(
            label: 'Sample 2',
            color: _solidsSample2,
            values: controller.dissolvedSolidsSeries(1),
          ),
          _SolidsSeries(
            label: 'Sample 3',
            color: _solidsSample3,
            values: controller.dissolvedSolidsSeries(2),
          ),
        ],
      ),
      _SolidsMetricSection(
        label: 'LGS',
        unit: '%',
        series: [
          _SolidsSeries(
            label: 'Sample 1',
            color: _solidsSample1,
            values: controller.lgsPercentSeries(0),
          ),
          _SolidsSeries(
            label: 'Sample 2',
            color: _solidsSample2,
            values: controller.lgsPercentSeries(1),
          ),
          _SolidsSeries(
            label: 'Sample 3',
            color: _solidsSample3,
            values: controller.lgsPercentSeries(2),
          ),
        ],
      ),
      _SolidsMetricSection(
        label: 'HGS',
        unit: '%',
        series: [
          _SolidsSeries(
            label: 'Sample 1',
            color: _solidsSample1,
            values: controller.hgsPercentSeries(0),
          ),
          _SolidsSeries(
            label: 'Sample 2',
            color: _solidsSample2,
            values: controller.hgsPercentSeries(1),
          ),
          _SolidsSeries(
            label: 'Sample 3',
            color: _solidsSample3,
            values: controller.hgsPercentSeries(2),
          ),
        ],
      ),
      _SolidsMetricSection(
        label: 'Avg. SG',
        unit: 'sg',
        series: [
          _SolidsSeries(
            label: 'Sample 1',
            color: _solidsSample1,
            values: controller.avgSgSeries(0),
          ),
          _SolidsSeries(
            label: 'Sample 2',
            color: _solidsSample2,
            values: controller.avgSgSeries(1),
          ),
          _SolidsSeries(
            label: 'Sample 3',
            color: _solidsSample3,
            values: controller.avgSgSeries(2),
          ),
        ],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _solidsPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: Text(
                'Solids Analysis',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _solidsText,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 6),
              child: _SolidsLegend(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 8),
                child: CustomPaint(
                  painter: _LegacySolidsGraphPainter(
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

class _SolidsLegend extends StatelessWidget {
  const _SolidsLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Sample 1', _solidsSample1),
      ('Sample 2', _solidsSample2),
      ('Sample 3', _solidsSample3),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, color: item.$2),
            const SizedBox(width: 6),
            Text(
              item.$1,
              style: const TextStyle(fontSize: 11, color: _solidsText),
            ),
          ],
        );
      }).toList(growable: false),
    );
  }
}

class _SolidsTableTab extends StatelessWidget {
  final List<SolidsHistoryRow> rows;
  final int sampleIndex;

  const _SolidsTableTab({
    required this.rows,
    required this.sampleIndex,
  });

  @override
  Widget build(BuildContext context) {
    final columns = [
      _SolidsTableColumn(
        title: 'LGS (%)',
        valueFor: (row) => _formatNumber(row.sample(sampleIndex)?.lgsPercent),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'LGS (lb/bbl)',
        valueFor: (row) => _formatNumber(row.sample(sampleIndex)?.lgsLb),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'HGS (%)',
        valueFor: (row) => _formatNumber(row.sample(sampleIndex)?.hgsPercent),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Diss Solids (%)',
        valueFor: (row) =>
            _formatNumber(row.sample(sampleIndex)?.dissolvedSolids),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Corr. Solids (%)',
        valueFor: (row) =>
            _formatNumber(row.sample(sampleIndex)?.correctedSolids),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Brine SG',
        valueFor: (row) => _formatNumber(
          row.sample(sampleIndex)?.brineSG,
          digits: 4,
        ),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'HGS (lb/bbl)',
        valueFor: (row) => _formatNumber(row.sample(sampleIndex)?.hgsLb),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Bentonite (%)',
        valueFor: (row) => _formatNumber(row.sample(sampleIndex)?.bentPercent),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Bentonite (lb/bbl)',
        valueFor: (row) =>
            _formatNumber(row.sample(sampleIndex)?.bentoniteLb),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Drill Solids (%)',
        valueFor: (row) =>
            _formatNumber(row.sample(sampleIndex)?.drillSolidsPercent),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Drill Solids (lb/bbl)',
        valueFor: (row) =>
            _formatNumber(row.sample(sampleIndex)?.drillSolidsLb),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'DS/Bent Ratio',
        valueFor: (row) => _formatNumber(row.sample(sampleIndex)?.dsBentRatio),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Avg. SG of Solids',
        valueFor: (row) => _formatNumber(row.sample(sampleIndex)?.avgSG),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Mud Weight',
        valueFor: (row) => _formatNumber(row.sample(sampleIndex)?.mudWeight),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Total Solids (%)',
        valueFor: (row) =>
            _formatNumber(row.sample(sampleIndex)?.retortSolids),
        alignRight: true,
      ),
      _SolidsTableColumn(
        title: 'Barite (lb/bbl)',
        valueFor: (row) => _formatNumber(row.sample(sampleIndex)?.bariteLb),
        alignRight: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _solidsPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Solids Analysis - Sample ${sampleIndex + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _solidsText,
                ),
              ),
            ),
            Expanded(
              child: _LegacySolidsTable(
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

class _LegacySolidsTable extends StatefulWidget {
  final List<SolidsHistoryRow> rows;
  final List<_SolidsTableColumn> columns;

  const _LegacySolidsTable({
    required this.rows,
    required this.columns,
  });

  @override
  State<_LegacySolidsTable> createState() => _LegacySolidsTableState();
}

class _LegacySolidsTableState extends State<_LegacySolidsTable> {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const fixedWidth =
            _indexWidth + _dateWidth + _mdWidth + _reportWidth;
        final baseDynamicWidth = widget.columns.length * _columnWidth;
        final availableDynamicWidth =
            (constraints.maxWidth - 16 - fixedWidth)
                .clamp(0, double.infinity)
                .toDouble();
        final dynamicWidth = math.max(baseDynamicWidth, availableDynamicWidth);
        final columnWidth = widget.columns.isEmpty
            ? _columnWidth
            : dynamicWidth / widget.columns.length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Container(
            height: _rowHeight,
            color: _solidsHeaderFill,
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
                            .map((column) => _headerCell(column.title, columnWidth))
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
                  width: fixedWidth,
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
                                  columnWidth,
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
      },
    );
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _solidsHeaderFill,
        border: Border.all(color: _solidsPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _solidsText,
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
        border: Border.all(color: _solidsPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _solidsText),
      ),
    );
  }
}

class _LegacySolidsGraphPainter extends CustomPainter {
  final List<_SolidsMetricSection> sections;
  final int slotCount;

  const _LegacySolidsGraphPainter({
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
      ..color = _solidsPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _solidsGrid
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int index = 0; index < sections.length; index++) {
      final section = sections[index];
      final top = index * (sectionHeight + sectionGap);
      final bottom = top + sectionHeight;
      final plotRect = Rect.fromLTRB(plotLeft, top, plotRight, bottom);
      final maxValue = _niceMax(section.series);

      canvas.drawRect(plotRect, borderPaint);

      for (int line = 1; line < 4; line++) {
        final y = plotRect.top + plotRect.height * line / 4;
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

      for (int tick = 0; tick <= 4; tick++) {
        final factor = 1 - (tick / 4);
        final value = maxValue * factor;
        final y = plotRect.top + plotRect.height * tick / 4;
        textPainter.text = TextSpan(
          text: _formatAxisTick(value, maxValue),
          style: const TextStyle(fontSize: 9.5, color: _solidsText),
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
        label: '${section.label}\n(${section.unit})',
        top: top,
        height: sectionHeight,
        width: leftLabelWidth,
      );

      for (final series in section.series) {
        final linePaint = Paint()
          ..color = series.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        final pointPaint = Paint()
          ..color = series.color
          ..style = PaintingStyle.fill;
        final values = series.values.length >= slotCount
            ? series.values.take(slotCount).toList(growable: false)
            : [
                ...series.values,
                ...List<double?>.filled(
                  slotCount - series.values.length,
                  null,
                ),
              ];

        final path = Path();
        var hasSegment = false;
        for (int pointIndex = 0; pointIndex < values.length; pointIndex++) {
          final value = values[pointIndex];
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

          canvas.drawCircle(Offset(x, y), 2.2, pointPaint);
        }

        if (hasSegment) {
          canvas.drawPath(path, linePaint);
        }
      }
    }

    final footerTop = size.height - footerHeight + 4;
    for (int column = 0; column < slotCount; column++) {
      final x = plotLeft + slotWidth * column + slotWidth / 2;
      textPainter.text = TextSpan(
        text: '${column + 1}',
        style: const TextStyle(fontSize: 10, color: _solidsText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, footerTop));
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _solidsText),
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
      style: const TextStyle(fontSize: 11, color: _solidsText),
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
        ..color = _solidsPanelBorder
        ..strokeWidth = 1,
    );
  }

  double _niceMax(List<_SolidsSeries> series) {
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
    if (maxValue <= 1) return 1;
    if (maxValue <= 2) return 2;
    if (maxValue <= 5) return 5;
    if (maxValue <= 10) return 10;
    if (maxValue <= 20) return 20;
    if (maxValue <= 50) return 50;
    if (maxValue <= 100) return 100;
    if (maxValue <= 200) return 200;

    final exponent =
        math.pow(10, (math.log(maxValue) / math.ln10).floor()).toDouble();
    final scaled = maxValue / exponent;
    if (scaled <= 2) return 2 * exponent;
    if (scaled <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  String _formatAxisTick(double value, double maxValue) {
    if (maxValue <= 5) {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    if (maxValue < 50) {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _LegacySolidsGraphPainter oldDelegate) {
    return oldDelegate.sections != sections || oldDelegate.slotCount != slotCount;
  }
}

class _SolidsMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _SolidsMessageState({
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
          border: Border.all(color: _solidsPanelBorder),
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
                  color: _solidsText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _solidsText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolidsMetricSection {
  final String label;
  final String unit;
  final List<_SolidsSeries> series;

  const _SolidsMetricSection({
    required this.label,
    required this.unit,
    required this.series,
  });
}

class _SolidsSeries {
  final String label;
  final Color color;
  final List<double?> values;

  const _SolidsSeries({
    required this.label,
    required this.color,
    required this.values,
  });
}

class _SolidsTableColumn {
  final String title;
  final String Function(SolidsHistoryRow row) valueFor;
  final bool alignRight;

  const _SolidsTableColumn({
    required this.title,
    required this.valueFor,
    this.alignRight = false,
  });
}

class _SolidsTabMeta {
  final String title;

  const _SolidsTabMeta({required this.title});
}

String _formatDate(String raw, String createdAt) {
  final source = raw.trim().isNotEmpty ? raw.trim() : createdAt.trim();
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source.isEmpty ? '-' : source;
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatNumber(double? value, {int digits = 2}) {
  if (value == null || value == 0) return '-';
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(digits)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
