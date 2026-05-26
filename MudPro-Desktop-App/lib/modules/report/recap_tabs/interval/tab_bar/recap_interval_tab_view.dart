import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/interval/controller/recap_interval_controller.dart';

const Color _intervalOuterBorder = Color(0xFF2F92E8);
const Color _intervalCanvas = Color(0xFFF4F4F4);
const Color _intervalPanelBorder = Color(0xFFC8C8C8);
const Color _intervalHeaderFill = Color(0xFFF7F7F7);
const Color _intervalText = Color(0xFF1C1C1C);
const Color _intervalGrid = Color(0xFFD7D7D7);
const Color _intervalTabFill = Color(0xFFEAEAEA);
const Color _intervalAxisRed = Color(0xFFFF2B2B);
const Color _intervalCasingFill = Color(0xFFF0ECE8);
const Color _intervalLine = Color(0xFF84D0F4);

class RecapIntervalTabView extends StatefulWidget {
  const RecapIntervalTabView({super.key});

  @override
  State<RecapIntervalTabView> createState() => _RecapIntervalTabViewState();
}

class _RecapIntervalTabViewState extends State<RecapIntervalTabView> {
  int _selectedTab = 0;

  RecapIntervalController get _controller =>
      Get.isRegistered<RecapIntervalController>()
      ? Get.find<RecapIntervalController>()
      : Get.put(RecapIntervalController());

  static const _tabs = [
    _IntervalTabMeta(title: 'Graph'),
    _IntervalTabMeta(title: 'Summary'),
    _IntervalTabMeta(title: 'Usage'),
    _IntervalTabMeta(title: 'Group'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _intervalCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _intervalOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapIntervalController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _IntervalMessageState(
        title: 'Interval',
        message: controller.errorMessage.value,
      );
    }

    switch (_selectedTab) {
      case 0:
        return _IntervalGraphTab(controller: controller);
      case 1:
        return _IntervalSummaryTab(controller: controller);
      case 2:
        return _IntervalUsageTab(controller: controller);
      case 3:
        return _IntervalGroupTab(controller: controller);
      default:
        return _IntervalGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _intervalCanvas,
        border: Border(left: BorderSide(color: _intervalPanelBorder)),
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
                  color: selected ? Colors.white : _intervalTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _intervalPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _intervalOuterBorder
                          : _intervalPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _intervalPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _intervalPanelBorder)
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
                        color: _intervalText,
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

class _IntervalGraphTab extends StatelessWidget {
  final RecapIntervalController controller;

  const _IntervalGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _IntervalGraphSection(
        label: 'Mud Treated (bbl)',
        valueForRow: (row) => row.mudTreatedBbl,
      ),
      _IntervalGraphSection(
        label: 'Mud Usage (bbl/ft)',
        valueForRow: (row) => row.mudUsageBblPerFt,
      ),
      _IntervalGraphSection(
        label: 'Cost (Kwd/day)',
        valueForRow: (row) => row.costKwdPerDay,
      ),
      _IntervalGraphSection(
        label: 'Cost (Kwd/ft)',
        valueForRow: (row) => row.costKwdPerFt,
      ),
      _IntervalGraphSection(
        label: 'Cost (Kwd/bbl)',
        valueForRow: (row) => row.costKwdPerBbl,
      ),
      _IntervalGraphSection(
        label: 'Total Cost (Kwd)',
        valueForRow: (row) => row.totalCostKwd,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _intervalPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Interval Overview',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _intervalText,
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
                padding: const EdgeInsets.fromLTRB(8, 2, 10, 8),
                child: CustomPaint(
                  painter: _LegacyIntervalGraphPainter(
                    rows: controller.intervalRows.toList(growable: false),
                    casings: controller.casings.toList(growable: false),
                    maxDepth: controller.maxDepth,
                    sections: sections,
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

class _IntervalSummaryTab extends StatelessWidget {
  final RecapIntervalController controller;

  const _IntervalSummaryTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.intervalRows.toList(growable: false);
    if (rows.isEmpty) {
      return _IntervalMessageState(
        title: 'Interval Summary',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No interval summary data is available yet.',
      );
    }

    const columns = [
      _IntervalTableColumn('No', 46),
      _IntervalTableColumn('Interval', 148),
      _IntervalTableColumn('Group', 112),
      _IntervalTableColumn('Start', 70, alignRight: true),
      _IntervalTableColumn('End', 70, alignRight: true),
      _IntervalTableColumn('Ftg', 70, alignRight: true),
      _IntervalTableColumn('Mud Treated', 86, alignRight: true),
      _IntervalTableColumn('Usage', 76, alignRight: true),
      _IntervalTableColumn('Cost/day', 78, alignRight: true),
      _IntervalTableColumn('Cost/ft', 74, alignRight: true),
      _IntervalTableColumn('Cost/bbl', 78, alignRight: true),
      _IntervalTableColumn('Total Cost', 84, alignRight: true),
      _IntervalTableColumn('Rpts', 54, alignRight: true),
    ];

    final cells = List<List<String>>.generate(rows.length, (index) {
      final row = rows[index];
      return [
        '${index + 1}',
        row.intervalName,
        row.groupName,
        _formatDepth(row.startDepth),
        _formatDepth(row.endDepth),
        _formatMetric(row.footage),
        _formatMetric(row.mudTreatedBbl),
        _formatMetric(row.mudUsageBblPerFt),
        _formatMetric(row.costKwdPerDay),
        _formatMetric(row.costKwdPerFt),
        _formatMetric(row.costKwdPerBbl),
        _formatMetric(row.totalCostKwd),
        '${row.reportCount}',
      ];
    });

    return _IntervalTablePanel(
      title: 'Interval Summary',
      child: _IntervalGridTable(
        columns: columns,
        rows: cells,
      ),
    );
  }
}

class _IntervalUsageTab extends StatelessWidget {
  final RecapIntervalController controller;

  const _IntervalUsageTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.intervalRows.toList(growable: false);
    if (rows.isEmpty) {
      return _IntervalMessageState(
        title: 'Interval Usage',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No interval usage data is available yet.',
      );
    }

    const columns = [
      _IntervalTableColumn('No', 46),
      _IntervalTableColumn('Interval', 168),
      _IntervalTableColumn('Start', 76, alignRight: true),
      _IntervalTableColumn('End', 76, alignRight: true),
      _IntervalTableColumn('Ftg', 76, alignRight: true),
      _IntervalTableColumn('Mud Treated (bbl)', 108, alignRight: true),
      _IntervalTableColumn('Mud Usage (bbl/ft)', 118, alignRight: true),
      _IntervalTableColumn('Reports', 64, alignRight: true),
    ];

    final cells = List<List<String>>.generate(rows.length, (index) {
      final row = rows[index];
      return [
        '${index + 1}',
        row.intervalName,
        _formatDepth(row.startDepth),
        _formatDepth(row.endDepth),
        _formatMetric(row.footage),
        _formatMetric(row.mudTreatedBbl),
        _formatMetric(row.mudUsageBblPerFt),
        '${row.reportCount}',
      ];
    });

    return _IntervalTablePanel(
      title: 'Interval Usage',
      child: _IntervalGridTable(
        columns: columns,
        rows: cells,
      ),
    );
  }
}

class _IntervalGroupTab extends StatelessWidget {
  final RecapIntervalController controller;

  const _IntervalGroupTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.groupRows.toList(growable: false);
    if (rows.isEmpty) {
      return _IntervalMessageState(
        title: 'Interval Group',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No interval group data is available yet.',
      );
    }

    const columns = [
      _IntervalTableColumn('No', 46),
      _IntervalTableColumn('Group', 150),
      _IntervalTableColumn('Intervals', 64, alignRight: true),
      _IntervalTableColumn('Start', 72, alignRight: true),
      _IntervalTableColumn('End', 72, alignRight: true),
      _IntervalTableColumn('Ftg', 72, alignRight: true),
      _IntervalTableColumn('Mud Treated', 88, alignRight: true),
      _IntervalTableColumn('Usage', 76, alignRight: true),
      _IntervalTableColumn('Cost/day', 78, alignRight: true),
      _IntervalTableColumn('Cost/ft', 74, alignRight: true),
      _IntervalTableColumn('Cost/bbl', 78, alignRight: true),
      _IntervalTableColumn('Total Cost', 84, alignRight: true),
      _IntervalTableColumn('Rpts', 54, alignRight: true),
    ];

    final cells = List<List<String>>.generate(rows.length, (index) {
      final row = rows[index];
      return [
        '${index + 1}',
        row.groupName,
        '${row.intervalCount}',
        _formatDepth(row.startDepth),
        _formatDepth(row.endDepth),
        _formatMetric(row.footage),
        _formatMetric(row.mudTreatedBbl),
        _formatMetric(row.mudUsageBblPerFt),
        _formatMetric(row.costKwdPerDay),
        _formatMetric(row.costKwdPerFt),
        _formatMetric(row.costKwdPerBbl),
        _formatMetric(row.totalCostKwd),
        '${row.reportCount}',
      ];
    });

    return _IntervalTablePanel(
      title: 'Interval Group',
      child: _IntervalGridTable(
        columns: columns,
        rows: cells,
      ),
    );
  }
}

class _IntervalTablePanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _IntervalTablePanel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _intervalPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _intervalText,
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _IntervalGridTable extends StatefulWidget {
  final List<_IntervalTableColumn> columns;
  final List<List<String>> rows;

  const _IntervalGridTable({
    required this.columns,
    required this.rows,
  });

  @override
  State<_IntervalGridTable> createState() => _IntervalGridTableState();
}

class _IntervalGridTableState extends State<_IntervalGridTable> {
  final ScrollController _headerController = ScrollController();
  final ScrollController _bodyController = ScrollController();
  bool _syncing = false;

  static const double _rowHeight = 31;

  @override
  void initState() {
    super.initState();
    _headerController.addListener(() => _syncHorizontal(_headerController));
    _bodyController.addListener(() => _syncHorizontal(_bodyController));
  }

  void _syncHorizontal(ScrollController source) {
    if (_syncing) return;
    _syncing = true;
    for (final controller in [_headerController, _bodyController]) {
      if (controller == source || !controller.hasClients) continue;
      controller.jumpTo(
        source.offset.clamp(0, controller.position.maxScrollExtent),
      );
    }
    _syncing = false;
  }

  @override
  void dispose() {
    _headerController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseTotalWidth = widget.columns.fold<double>(
          0,
          (sum, column) => sum + column.width,
        );
        final totalWidth = math.max(
          baseTotalWidth,
          (constraints.maxWidth - 16).clamp(0, double.infinity).toDouble(),
        );
        final scale =
            baseTotalWidth <= 0 ? 1.0 : totalWidth / baseTotalWidth;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          SizedBox(
            height: _rowHeight,
            child: SingleChildScrollView(
              controller: _headerController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                child: Row(
                  children: widget.columns
                      .map(
                        (column) => _IntervalHeaderCell(
                          column.label,
                          column.width * scale,
                          alignRight: column.alignRight,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _bodyController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                child: ListView.builder(
                  itemCount: widget.rows.length,
                  itemBuilder: (context, index) {
                    final row = widget.rows[index];
                    return SizedBox(
                      height: _rowHeight,
                      child: Row(
                        children: List.generate(widget.columns.length, (cellIndex) {
                          final column = widget.columns[cellIndex];
                          final text = cellIndex < row.length ? row[cellIndex] : '';
                          return _IntervalDataCell(
                            text,
                            column.width * scale,
                            index,
                            alignRight: column.alignRight,
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}

class _IntervalHeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final bool alignRight;

  const _IntervalHeaderCell(
    this.text,
    this.width, {
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.fromLTRB(8, 0, alignRight ? 8 : 4, 0),
      decoration: BoxDecoration(
        color: _intervalHeaderFill,
        border: Border(
          top: const BorderSide(color: _intervalPanelBorder),
          left: const BorderSide(color: _intervalPanelBorder),
          right: BorderSide.none,
          bottom: const BorderSide(color: _intervalPanelBorder),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _intervalText,
        ),
      ),
    );
  }
}

class _IntervalDataCell extends StatelessWidget {
  final String text;
  final double width;
  final int rowIndex;
  final bool alignRight;

  const _IntervalDataCell(
    this.text,
    this.width,
    this.rowIndex, {
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = rowIndex.isEven ? Colors.white : const Color(0xFFF8F8F8);
    return Container(
      width: width,
      height: double.infinity,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.fromLTRB(8, 0, alignRight ? 8 : 4, 0),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          left: const BorderSide(color: _intervalPanelBorder),
          bottom: const BorderSide(color: _intervalPanelBorder),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          color: _intervalText,
        ),
      ),
    );
  }
}

class _LegacyIntervalGraphPainter extends CustomPainter {
  final List<RecapIntervalRow> rows;
  final List<RecapIntervalCasing> casings;
  final double maxDepth;
  final List<_IntervalGraphSection> sections;

  const _LegacyIntervalGraphPainter({
    required this.rows,
    required this.casings,
    required this.maxDepth,
    required this.sections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const titleTop = 8.0;
    const plotTop = 40.0;
    const bottomPad = 46.0;
    const axisPaneWidth = 92.0;
    const sectionGap = 10.0;
    const legendTopPadding = 20.0;

    final plotBottom = size.height - bottomPad;
    final plotHeight = plotBottom - plotTop;
    final sectionWidth =
        (size.width - axisPaneWidth - (sectionGap * (sections.length - 1))) /
        sections.length;
    final axisX = 48.0;
    final casingStartX = 60.0;
    final yTicks = _buildDepthTicks(maxDepth);

    final borderPaint = Paint()
      ..color = _intervalPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _intervalGrid
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;
    final redPaint = Paint()
      ..color = _intervalAxisRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: 'MD (ft)',
      style: TextStyle(fontSize: 12, color: _intervalText),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(6, titleTop));

    canvas.drawLine(
      Offset(axisX, plotTop),
      Offset(axisX, plotBottom),
      axisPaint,
    );

    for (final tick in yTicks) {
      final y = _yForDepth(tick, plotTop, plotBottom);
      canvas.drawLine(Offset(axisX - 5, y), Offset(axisX + 5, y), axisPaint);
      canvas.drawCircle(Offset(axisX, y), 4, redPaint);

      textPainter.text = TextSpan(
        text: _formatDepthTick(tick, maxDepth),
        style: const TextStyle(fontSize: 11, color: _intervalText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(6, y - textPainter.height / 2));
    }

    final visibleCasings = casings.take(3).toList();
    for (int index = 0; index < visibleCasings.length; index++) {
      final casing = visibleCasings[index];
      final barLeft = casingStartX + (index * 26);
      final topY = _yForDepth(
        casing.top.clamp(0, maxDepth),
        plotTop,
        plotBottom,
      );
      final shoeY = _yForDepth(
        casing.shoe.clamp(casing.top, maxDepth),
        plotTop,
        plotBottom,
      );

      final rect = Rect.fromLTWH(barLeft, topY, 18, shoeY - topY);
      canvas.drawRect(
        rect,
        Paint()
          ..color = _intervalCasingFill
          ..style = PaintingStyle.fill,
      );
    }

    for (int index = 0; index < sections.length; index++) {
      final left = axisPaneWidth + index * (sectionWidth + sectionGap);
      final rect = Rect.fromLTWH(left, plotTop, sectionWidth, plotHeight);
      final section = sections[index];
      final sectionValues = rows.map(section.valueForRow).toList(growable: false);
      final sectionMax = _niceMetricMax(sectionValues);

      textPainter.text = TextSpan(
        text: section.label,
        style: const TextStyle(fontSize: 12, color: _intervalText),
      );
      textPainter.layout(maxWidth: sectionWidth + 10);
      textPainter.paint(
        canvas,
        Offset(left + (sectionWidth - textPainter.width) / 2, titleTop + 4),
      );

      canvas.drawRect(rect, borderPaint);

      for (int line = 1; line < yTicks.length - 1; line++) {
        final y = _yForDepth(yTicks[line], plotTop, plotBottom);
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      }

      for (int column = 1; column < 5; column++) {
        final x = rect.left + rect.width * column / 5;
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
      }

      _drawSectionSegments(
        canvas: canvas,
        rect: rect,
        section: section,
        sectionMax: sectionMax,
        plotTop: plotTop,
        plotBottom: plotBottom,
      );

      final xTicks = _buildMetricTicks(sectionMax);
      for (int tickIndex = 0; tickIndex < xTicks.length; tickIndex++) {
        final tickValue = xTicks[tickIndex];
        final x = rect.left + rect.width * tickIndex / (xTicks.length - 1);
        textPainter.text = TextSpan(
          text: _formatMetricTick(tickValue, sectionMax),
          style: const TextStyle(fontSize: 10, color: _intervalText),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, plotBottom + 6),
        );
      }
    }

    if (visibleCasings.isNotEmpty) {
      var legendX = 56.0;
      final legendY = size.height - legendTopPadding;
      for (final casing in visibleCasings) {
        canvas.drawRect(
          Rect.fromLTWH(legendX, legendY - 10, 10, 10),
          Paint()..color = _intervalCasingFill,
        );
        textPainter.text = TextSpan(
          text: casing.label,
          style: const TextStyle(fontSize: 11, color: _intervalText),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(legendX + 14, legendY - 12));
        legendX += textPainter.width + 34;
      }
    }
  }

  void _drawSectionSegments({
    required Canvas canvas,
    required Rect rect,
    required _IntervalGraphSection section,
    required double sectionMax,
    required double plotTop,
    required double plotBottom,
  }) {
    final drawableRows = rows.where((row) => row.hasGraphData).toList();
    if (drawableRows.isEmpty) return;

    final paint = Paint()
      ..color = _intervalLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final lastNonZero = drawableRows.lastWhere(
      (row) => section.valueForRow(row) > 0,
      orElse: () => drawableRows.last,
    );

    for (final row in drawableRows) {
      final value = section.valueForRow(row);
      if (value <= 0) continue;

      final startDepth = row.startDepth.clamp(0.0, maxDepth).toDouble();
      final endDepth = row.endDepth.clamp(startDepth, maxDepth).toDouble();
      var yStart = _yForDepth(startDepth, plotTop, plotBottom);
      var yEnd = _yForDepth(endDepth, plotTop, plotBottom);

      if ((yEnd - yStart).abs() < 1) {
        yEnd = math.min(plotBottom, yStart + 20);
      }

      final xEnd = _xForValue(value, rect, sectionMax);
      final path = Path()
        ..moveTo(rect.left, yStart)
        ..lineTo(xEnd, yEnd);

      canvas.drawPath(path, paint);

      if (identical(row, lastNonZero)) {
        canvas.drawLine(Offset(xEnd, yEnd), Offset(xEnd, plotBottom), paint);
      }
    }
  }

  double _xForValue(double value, Rect rect, double sectionMax) {
    if (sectionMax <= 0) return rect.left;
    return rect.left + (rect.width * (value / sectionMax).clamp(0.0, 1.0));
  }

  double _yForDepth(double depth, double plotTop, double plotBottom) {
    if (maxDepth <= 0) return plotTop;
    return plotTop +
        (plotBottom - plotTop) * (depth / maxDepth).clamp(0.0, 1.0);
  }

  List<double> _buildDepthTicks(double maxDepth) {
    if (maxDepth <= 20) return const [0, 5, 10, 15, 20];
    if (maxDepth <= 50) return const [0, 10, 20, 30, 40, 50];
    if (maxDepth <= 100) return const [0, 25, 50, 75, 100];

    final step = maxDepth / 4;
    return List<double>.generate(5, (index) => step * index);
  }

  List<double> _buildMetricTicks(double maxValue) {
    if (maxValue <= 0) return const [0, 1, 2, 3];
    return [0, maxValue / 3, (maxValue * 2) / 3, maxValue];
  }

  double _niceMetricMax(List<double> values) {
    final maxValue = values.fold<double>(0, math.max);
    if (maxValue <= 0) return 1;
    if (maxValue <= 0.001) return 0.001;
    if (maxValue <= 1) return 1;
    if (maxValue <= 10) return 10;
    if (maxValue <= 100) return 100;
    if (maxValue <= 1000) return 1000;
    if (maxValue <= 5000) return 5000;
    if (maxValue <= 10000) return 10000;

    final exponent = math
        .pow(10, (math.log(maxValue) / math.ln10).floor())
        .toDouble();
    final scaled = maxValue / exponent;
    if (scaled <= 2) return 2 * exponent;
    if (scaled <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  String _formatDepthTick(double value, double maxDepth) {
    if (maxDepth <= 20) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  String _formatMetricTick(double value, double maxValue) {
    if (maxValue <= 0.001) {
      return value == 0 ? '0' : value.toStringAsFixed(4);
    }
    if (maxValue <= 10) {
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    }
    return value.toStringAsFixed(value >= 1000 ? 0 : 1).replaceAll('.0', '');
  }

  @override
  bool shouldRepaint(covariant _LegacyIntervalGraphPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.casings != casings ||
        oldDelegate.maxDepth != maxDepth ||
        oldDelegate.sections != sections;
  }
}

class _IntervalMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _IntervalMessageState({
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
          border: Border.all(color: _intervalPanelBorder),
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
                  color: _intervalText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _intervalText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntervalGraphSection {
  final String label;
  final double Function(RecapIntervalRow row) valueForRow;

  const _IntervalGraphSection({
    required this.label,
    required this.valueForRow,
  });
}

class _IntervalTableColumn {
  final String label;
  final double width;
  final bool alignRight;

  const _IntervalTableColumn(
    this.label,
    this.width, {
    this.alignRight = false,
  });
}

class _IntervalTabMeta {
  final String title;

  const _IntervalTabMeta({required this.title});
}

String _formatMetric(double value) {
  if (value == 0) return '0';
  return value.toStringAsFixed(value >= 100 ? 0 : 2).replaceAll('.00', '');
}

String _formatDepth(double value) {
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}
