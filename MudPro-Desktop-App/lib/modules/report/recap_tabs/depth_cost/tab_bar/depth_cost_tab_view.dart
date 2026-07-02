import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/depth_cost/controller/recap_depth_cost_controller.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/recap_daily_cost/controller/recap_daily_cost_controller.dart';

const Color _depthCostOuterBorder = Color(0xFFB8D0EA);
const Color _depthCostCanvas = Color(0xFFF4F6FA);
const Color _depthCostPanelBorder = Color(0xFFB8D0EA);
const Color _depthCostHeaderFill = Color(0xFFEAF3FC);
const Color _depthCostText = Color(0xFF1C1C1C);
const Color _depthCostGrid = Color(0xFFCFE0F2);
const Color _depthCostTabFill = Color(0xFFEAF3FC);
const Color _depthCostAxisRed = Color(0xFFFF2B2B);
const Color _depthCostCasingFill = Color(0xFFF0ECE8);
const Color _depthCostProductLine = Color(0xFF89ACD9);
const Color _depthCostPremixedLine = Color(0xFF8FD1E3);
const Color _depthCostPackageLine = Color(0xFFA9D1AA);
const Color _depthCostServiceLine = Color(0xFFCFD58A);
const Color _depthCostEngineeringLine = Color(0xFFC5B2E0);
const Color _depthCostTotalLine = Color(0xFF0F72C4);

class DepthCostTabView extends StatefulWidget {
  const DepthCostTabView({super.key});

  @override
  State<DepthCostTabView> createState() => _DepthCostTabViewState();
}

class _DepthCostTabViewState extends State<DepthCostTabView> {
  int _selectedTab = 0;

  RecapDepthCostController get _controller =>
      Get.isRegistered<RecapDepthCostController>()
      ? Get.find<RecapDepthCostController>()
      : Get.put(RecapDepthCostController());

  static const _tabs = [
    _DepthCostTabMeta(title: 'Graph'),
    _DepthCostTabMeta(title: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _depthCostCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _depthCostOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapDepthCostController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _DepthCostMessageState(
        title: 'Depth Cost',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty) {
      return _DepthCostMessageState(
        title: 'Depth Cost',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live depth cost history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _DepthCostGraphTab(controller: controller);
      case 1:
        return _DepthCostTableTab(controller: controller);
      default:
        return _DepthCostGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _depthCostCanvas,
        border: Border(left: BorderSide(color: _depthCostPanelBorder)),
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
                  color: selected ? Colors.white : _depthCostTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _depthCostPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _depthCostOuterBorder
                          : _depthCostPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _depthCostPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _depthCostPanelBorder)
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
                        color: _depthCostText,
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

class _DepthCostGraphTab extends StatelessWidget {
  final RecapDepthCostController controller;

  const _DepthCostGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _DepthCostGraphSection(
        label: 'Product',
        color: _depthCostProductLine,
        valueForRow: (row) => row.productTotal,
      ),
      _DepthCostGraphSection(
        label: 'Premixed Mud',
        color: _depthCostPremixedLine,
        valueForRow: (row) => row.premixedMudTotal,
      ),
      _DepthCostGraphSection(
        label: 'Package',
        color: _depthCostPackageLine,
        valueForRow: (row) => row.packageTotal,
      ),
      _DepthCostGraphSection(
        label: 'Service',
        color: _depthCostServiceLine,
        valueForRow: (row) => row.serviceTotal,
      ),
      _DepthCostGraphSection(
        label: 'Engineering',
        color: _depthCostEngineeringLine,
        valueForRow: (row) => row.engineeringTotal,
      ),
      _DepthCostGraphSection(
        label: 'Total',
        color: _depthCostTotalLine,
        valueForRow: (row) => row.total,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _depthCostPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Depth Cost (Kwd)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _depthCostText,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 10, 8),
                child: CustomPaint(
                  painter: _LegacyDepthCostGraphPainter(
                    rows: controller.graphRows,
                    casings: controller.casings.toList(),
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

class _DepthCostTableTab extends StatelessWidget {
  final RecapDepthCostController controller;

  const _DepthCostTableTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          Expanded(
            child: _DepthCostTablePanel(
              title: 'Depth Cost - All Categories',
              child: _LegacyDepthCostTable(
                rows: controller.rows.toList(),
                columns: controller.allCategoryColumns,
                valueForColumn: controller.allCategoryValueForRow,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _DepthCostTablePanel(
              title: 'Depth Cost - Group',
              child: controller.groupColumns.isEmpty
                  ? const _DepthCostMessageBody(
                      message: 'No live group rows are available yet.',
                    )
                  : _LegacyDepthCostTable(
                      rows: controller.rows.toList(),
                      columns: controller.groupColumns,
                      valueForColumn: controller.groupValueForRow,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepthCostTablePanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _DepthCostTablePanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _depthCostPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _depthCostText,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _LegacyDepthCostTable extends StatefulWidget {
  final List<DailyCostHistoryRow> rows;
  final List<String> columns;
  final double Function(DailyCostHistoryRow row, String column) valueForColumn;

  const _LegacyDepthCostTable({
    required this.rows,
    required this.columns,
    required this.valueForColumn,
  });

  @override
  State<_LegacyDepthCostTable> createState() => _LegacyDepthCostTableState();
}

class _LegacyDepthCostTableState extends State<_LegacyDepthCostTable> {
  final ScrollController _headerController = ScrollController();
  final ScrollController _bodyController = ScrollController();
  final ScrollController _footerController = ScrollController();
  bool _syncing = false;

  static const double _rowHeight = 31;
  static const double _noWidth = 50;
  static const double _mdWidth = 82;
  static const double _reportWidth = 70;
  static const double _columnWidth = 118;

  @override
  void initState() {
    super.initState();
    _headerController.addListener(() => _syncHorizontal(_headerController));
    _bodyController.addListener(() => _syncHorizontal(_bodyController));
    _footerController.addListener(() => _syncHorizontal(_footerController));
  }

  void _syncHorizontal(ScrollController source) {
    if (_syncing) return;
    _syncing = true;
    for (final controller in [
      _headerController,
      _bodyController,
      _footerController,
    ]) {
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
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseTableWidth =
            _noWidth +
            _mdWidth +
            _reportWidth +
            widget.columns.length * _columnWidth;
        final tableWidth = math.max(
          baseTableWidth,
          (constraints.maxWidth - 16).clamp(0, double.infinity).toDouble(),
        );
        final scale = baseTableWidth <= 0 ? 1.0 : tableWidth / baseTableWidth;
        final noWidth = _noWidth * scale;
        final mdWidth = _mdWidth * scale;
        final reportWidth = _reportWidth * scale;
        final columnWidth = _columnWidth * scale;

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
                width: tableWidth,
                child: Row(
                  children: [
                    _headerCell('No', noWidth),
                    _headerCell('MD (ft)', mdWidth),
                    _headerCell('Rpt #', reportWidth),
                    ...widget.columns.map(
                      (column) => _headerCell(column, columnWidth),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _bodyController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: ListView.builder(
                  itemCount: widget.rows.length,
                  itemBuilder: (context, index) {
                    final row = widget.rows[index];
                    return SizedBox(
                      height: _rowHeight,
                      child: Row(
                        children: [
                          _dataCell('${index + 1}', noWidth, index),
                          _dataCell(_formatDepth(row.md), mdWidth, index),
                          _dataCell(row.reportLabel, reportWidth, index),
                          ...widget.columns.map(
                            (column) => _dataCell(
                              _formatTableAmount(
                                widget.valueForColumn(row, column),
                              ),
                              columnWidth,
                              index,
                              alignRight: true,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            height: _rowHeight,
            child: SingleChildScrollView(
              controller: _footerController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Row(
                  children: [
                    _totalCell('Total', noWidth + mdWidth),
                    _totalCell('', reportWidth),
                    ...widget.columns.map((column) {
                      final total = widget.rows.fold<double>(
                        0,
                        (sum, row) => sum + widget.valueForColumn(row, column),
                      );
                      return _totalCell(
                        _formatTableAmount(total),
                        columnWidth,
                        alignRight: true,
                      );
                    }),
                  ],
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

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _depthCostHeaderFill,
        border: Border.all(color: _depthCostPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _depthCostText,
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
        border: Border.all(color: _depthCostPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _depthCostText),
      ),
    );
  }

  Widget _totalCell(String text, double width, {bool alignRight = false}) {
    return Container(
      width: width,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        border: Border.all(color: _depthCostPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _depthCostText,
        ),
      ),
    );
  }
}

class _LegacyDepthCostGraphPainter extends CustomPainter {
  final List<DailyCostHistoryRow> rows;
  final List<DepthCostCasing> casings;
  final double maxDepth;
  final List<_DepthCostGraphSection> sections;

  const _LegacyDepthCostGraphPainter({
    required this.rows,
    required this.casings,
    required this.maxDepth,
    required this.sections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const axisPaneWidth = 120.0;
    const sectionGap = 18.0;
    const titleTop = 12.0;
    const plotTop = 34.0;
    const plotBottomPadding = 44.0;
    const legendTopPadding = 12.0;

    final plotBottom = size.height - plotBottomPadding;
    final plotHeight = plotBottom - plotTop;
    final sectionWidth =
        (size.width -
            axisPaneWidth -
            (sectionGap * (sections.length - 1)) -
            8) /
        sections.length;
    final axisX = 48.0;
    final casingStartX = 60.0;
    final yTicks = _buildDepthTicks(maxDepth);

    final borderPaint = Paint()
      ..color = _depthCostPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _depthCostGrid
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;
    final redPaint = Paint()
      ..color = _depthCostAxisRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: 'MD (ft)',
      style: TextStyle(fontSize: 12, color: _depthCostText),
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
        style: const TextStyle(fontSize: 11, color: _depthCostText),
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
          ..color = _depthCostCasingFill
          ..style = PaintingStyle.fill,
      );
    }

    for (int index = 0; index < sections.length; index++) {
      final left = axisPaneWidth + index * (sectionWidth + sectionGap);
      final rect = Rect.fromLTWH(left, plotTop, sectionWidth, plotHeight);
      final section = sections[index];
      final sectionValues = rows.map(section.valueForRow).toList();
      final sectionMax = _niceCostMax(sectionValues);

      textPainter.text = TextSpan(
        text: section.label,
        style: const TextStyle(fontSize: 12, color: _depthCostText),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (sectionWidth - textPainter.width) / 2, titleTop + 4),
      );

      canvas.drawRect(rect, borderPaint);

      for (int line = 1; line < yTicks.length - 1; line++) {
        final y = _yForDepth(yTicks[line], plotTop, plotBottom);
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      }

      for (int column = 1; column < 6; column++) {
        final x = rect.left + rect.width * column / 6;
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
      }

      final path = _buildSectionPath(
        rect: rect,
        section: section,
        sectionMax: sectionMax,
        plotTop: plotTop,
        plotBottom: plotBottom,
      );

      if (path != null) {
        canvas.drawPath(
          path,
          Paint()
            ..color = section.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }

      final xTicks = _buildCostTicks(sectionMax);
      for (int tickIndex = 0; tickIndex < xTicks.length; tickIndex++) {
        final tickValue = xTicks[tickIndex];
        final x = rect.left + rect.width * tickIndex / (xTicks.length - 1);
        textPainter.text = TextSpan(
          text: _formatCostTick(tickValue, sectionMax),
          style: const TextStyle(fontSize: 10, color: _depthCostText),
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
          Paint()..color = _depthCostCasingFill,
        );
        textPainter.text = TextSpan(
          text: casing.label,
          style: const TextStyle(fontSize: 11, color: _depthCostText),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(legendX + 14, legendY - 12));
        legendX += textPainter.width + 34;
      }
    }
  }

  Path? _buildSectionPath({
    required Rect rect,
    required _DepthCostGraphSection section,
    required double sectionMax,
    required double plotTop,
    required double plotBottom,
  }) {
    final values = rows
        .where((row) => row.md >= 0 && section.valueForRow(row) > 0)
        .toList();
    if (values.isEmpty) return null;

    final path = Path();
    final first = values.first;
    final firstY = _yForDepth(first.md.clamp(0, maxDepth), plotTop, plotBottom);
    path.moveTo(_xForValue(0, rect, sectionMax), firstY);

    var previousValue = 0.0;
    for (int index = 0; index < values.length; index++) {
      final row = values[index];
      final y = _yForDepth(row.md.clamp(0, maxDepth), plotTop, plotBottom);
      final x = _xForValue(section.valueForRow(row), rect, sectionMax);

      if (index > 0) {
        path.lineTo(_xForValue(previousValue, rect, sectionMax), y);
      }

      path.lineTo(x, y);
      previousValue = section.valueForRow(row);
    }

    path.lineTo(_xForValue(previousValue, rect, sectionMax), plotBottom);
    return path;
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

  List<double> _buildCostTicks(double maxValue) {
    if (maxValue <= 0) return const [0, 1, 2, 3];
    return [0, maxValue / 3, (maxValue * 2) / 3, maxValue];
  }

  double _niceCostMax(List<double> values) {
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

  String _formatCostTick(double value, double maxValue) {
    if (maxValue <= 0.001) {
      return value == 0 ? '0' : value.toStringAsFixed(4);
    }
    if (maxValue <= 10) {
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    }
    return value.toStringAsFixed(value >= 1000 ? 0 : 1).replaceAll('.0', '');
  }

  @override
  bool shouldRepaint(covariant _LegacyDepthCostGraphPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.casings != casings ||
        oldDelegate.maxDepth != maxDepth ||
        oldDelegate.sections != sections;
  }
}

class _DepthCostMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _DepthCostMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _depthCostPanelBorder),
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
                  color: _depthCostText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _depthCostText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepthCostMessageBody extends StatelessWidget {
  final String message;

  const _DepthCostMessageBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _depthCostText),
        ),
      ),
    );
  }
}

class _DepthCostGraphSection {
  final String label;
  final Color color;
  final double Function(DailyCostHistoryRow row) valueForRow;

  const _DepthCostGraphSection({
    required this.label,
    required this.color,
    required this.valueForRow,
  });
}

class _DepthCostTabMeta {
  final String title;

  const _DepthCostTabMeta({required this.title});
}

String _formatDepth(double value) {
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}

String _formatTableAmount(double value) {
  if (value == 0) return '0.00';
  return value.toStringAsFixed(2);
}
