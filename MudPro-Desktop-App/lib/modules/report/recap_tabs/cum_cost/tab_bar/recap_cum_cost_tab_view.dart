import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cum_cost/controller/recap_cum_cost_controller.dart';

const Color _cumCostOuterBorder = Color(0xFF2F92E8);
const Color _cumCostCanvas = Color(0xFFF4F4F4);
const Color _cumCostPanelBorder = Color(0xFFC8C8C8);
const Color _cumCostHeaderFill = Color(0xFFF7F7F7);
const Color _cumCostText = Color(0xFF1C1C1C);
const Color _cumCostGrid = Color(0xFFD7D7D7);
const Color _cumCostTabFill = Color(0xFFEAEAEA);
const Color _cumCostProductLine = Color(0xFF89ACD9);
const Color _cumCostPremixedLine = Color(0xFF8FD1E3);
const Color _cumCostPackageLine = Color(0xFFB7CAE7);
const Color _cumCostServiceLine = Color(0xFFE2B4B4);
const Color _cumCostEngineeringLine = Color(0xFFC4B2DE);
const Color _cumCostTotalLine = Color(0xFF0F72C4);

class RecapCumcostTabView extends StatefulWidget {
  const RecapCumcostTabView({super.key});

  @override
  State<RecapCumcostTabView> createState() => _RecapCumcostTabViewState();
}

class _RecapCumcostTabViewState extends State<RecapCumcostTabView> {
  int _selectedTab = 1;

  RecapCumCostController get _controller =>
      Get.isRegistered<RecapCumCostController>()
      ? Get.find<RecapCumCostController>()
      : Get.put(RecapCumCostController());

  static const _tabs = [
    _CumCostTabMeta(title: 'Table - Package'),
    _CumCostTabMeta(title: 'Graph'),
    _CumCostTabMeta(title: 'Table - Service'),
    _CumCostTabMeta(title: 'Table - Product'),
    _CumCostTabMeta(title: 'Table - Engineering'),
    _CumCostTabMeta(title: 'Table - Premixed Mud'),
    _CumCostTabMeta(title: 'Table - All Categories'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _cumCostCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cumCostOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapCumCostController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _CumCostMessageState(
        title: 'Cumulative Cost',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty) {
      return _CumCostMessageState(
        title: 'Cumulative Cost',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live cumulative cost history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _CumCostTableTab(
          title: 'Cumulative Cost - Package',
          rows: controller.rows.toList(),
          columns: controller.packageColumns,
          valueForColumn: (row, column) => row.packageItems[column] ?? 0,
        );
      case 1:
        return _CumCostGraphTab(controller: controller);
      case 2:
        return _CumCostTableTab(
          title: 'Cumulative Cost - Service',
          rows: controller.rows.toList(),
          columns: controller.serviceColumns,
          valueForColumn: (row, column) => row.serviceItems[column] ?? 0,
        );
      case 3:
        return _CumCostTableTab(
          title: 'Cumulative Cost - Product',
          rows: controller.rows.toList(),
          columns: controller.productColumns,
          valueForColumn: (row, column) => row.productItems[column] ?? 0,
        );
      case 4:
        return _CumCostTableTab(
          title: 'Cumulative Cost - Engineering',
          rows: controller.rows.toList(),
          columns: controller.engineeringColumns,
          valueForColumn: (row, column) => row.engineeringItems[column] ?? 0,
        );
      case 5:
        return _CumCostTableTab(
          title: 'Cumulative Cost - Premixed Mud',
          rows: controller.rows.toList(),
          columns: controller.premixedColumns,
          valueForColumn: (row, column) => row.premixedMudItems[column] ?? 0,
        );
      case 6:
        return _CumCostTableTab(
          title: 'Cumulative Cost - All Categories',
          rows: controller.rows.toList(),
          columns: controller.allCategoryColumns,
          valueForColumn: controller.allCategoryValueForRow,
        );
      default:
        return _CumCostGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _cumCostCanvas,
        border: Border(left: BorderSide(color: _cumCostPanelBorder)),
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
                  color: selected ? Colors.white : _cumCostTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _cumCostPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _cumCostOuterBorder
                          : _cumCostPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _cumCostPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _cumCostPanelBorder)
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
                        color: _cumCostText,
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

class _CumCostGraphTab extends StatelessWidget {
  final RecapCumCostController controller;

  const _CumCostGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _CumCostGraphSection(
        label: 'Product',
        values: controller.productSeries,
        color: _cumCostProductLine,
      ),
      _CumCostGraphSection(
        label: 'Premixed Mud',
        values: controller.premixedSeries,
        color: _cumCostPremixedLine,
      ),
      _CumCostGraphSection(
        label: 'Package',
        values: controller.packageSeries,
        color: _cumCostPackageLine,
      ),
      _CumCostGraphSection(
        label: 'Service',
        values: controller.serviceSeries,
        color: _cumCostServiceLine,
      ),
      _CumCostGraphSection(
        label: 'Engineering',
        values: controller.engineeringSeries,
        color: _cumCostEngineeringLine,
      ),
      _CumCostGraphSection(
        label: 'Total',
        values: controller.totalSeries,
        color: _cumCostTotalLine,
      ),
    ];

    final maxDay = math.max(5, controller.rows.length);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cumCostPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Cumulative Cost',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _cumCostText,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 8),
                child: CustomPaint(
                  painter: _LegacyCumCostGraphPainter(
                    sections: sections,
                    maxDay: maxDay,
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

class _CumCostTableTab extends StatelessWidget {
  final String title;
  final List<CumulativeCostRow> rows;
  final List<String> columns;
  final double Function(CumulativeCostRow row, String column) valueForColumn;

  const _CumCostTableTab({
    required this.title,
    required this.rows,
    required this.columns,
    required this.valueForColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cumCostPanelBorder),
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
                  color: _cumCostText,
                ),
              ),
            ),
            Expanded(
              child: columns.isEmpty
                  ? const _CumCostMessageBody(
                      message: 'No live category rows are available yet.',
                    )
                  : _LegacyCumCostTable(
                      rows: rows,
                      columns: columns,
                      valueForColumn: valueForColumn,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyCumCostTable extends StatefulWidget {
  final List<CumulativeCostRow> rows;
  final List<String> columns;
  final double Function(CumulativeCostRow row, String column) valueForColumn;

  const _LegacyCumCostTable({
    required this.rows,
    required this.columns,
    required this.valueForColumn,
  });

  @override
  State<_LegacyCumCostTable> createState() => _LegacyCumCostTableState();
}

class _LegacyCumCostTableState extends State<_LegacyCumCostTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  final ScrollController _footerHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  static const double _rowHeight = 31;
  static const double _indexWidth = 52;
  static const double _dateWidth = 100;
  static const double _mdWidth = 80;
  static const double _reportWidth = 70;
  static const double _columnWidth = 116;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(
      () => _syncHorizontal(_headerHorizontalController),
    );
    _bodyHorizontalController.addListener(
      () => _syncHorizontal(_bodyHorizontalController),
    );
    _footerHorizontalController.addListener(
      () => _syncHorizontal(_footerHorizontalController),
    );
  }

  void _syncHorizontal(ScrollController source) {
    if (_syncingHorizontal) return;
    _syncingHorizontal = true;
    for (final controller in [
      _headerHorizontalController,
      _bodyHorizontalController,
      _footerHorizontalController,
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
    _footerHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latestRow = widget.rows.isEmpty ? null : widget.rows.last;

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
            color: _cumCostHeaderFill,
            child: Row(
              children: [
                _fixedHeaderCell('No', _indexWidth),
                _fixedHeaderCell('Date', _dateWidth),
                _fixedHeaderCell('MD (ft)', _mdWidth),
                _fixedHeaderCell('Rpt #', _reportWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dynamicWidth,
                      child: Row(
                        children: widget.columns
                            .map((column) => _headerCell(column, columnWidth))
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
                              _formatDate(row.reportDate),
                              _dateWidth,
                              index,
                            ),
                            _dataCell(
                              row.md.toStringAsFixed(1),
                              _mdWidth,
                              index,
                            ),
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
                                  _formatAmount(
                                    widget.valueForColumn(row, column),
                                  ),
                                  columnWidth,
                                  index,
                                  alignRight: true,
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
          Container(
            height: _rowHeight,
            color: const Color(0xFFF1F1F1),
            child: Row(
              children: [
                _totalLabelCell('Latest', _indexWidth + _dateWidth),
                _totalValueCell(
                  latestRow == null ? '' : latestRow.md.toStringAsFixed(1),
                  _mdWidth,
                ),
                _totalValueCell(latestRow?.reportLabel ?? '', _reportWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _footerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dynamicWidth,
                      child: Row(
                        children: widget.columns.map((column) {
                          final value = latestRow == null
                              ? 0.0
                              : widget.valueForColumn(latestRow, column);
                          return _totalValueCell(
                            _formatAmount(value),
                            columnWidth,
                          );
                        }).toList(),
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

  Widget _fixedHeaderCell(String text, double width) {
    return _cellShell(
      width: width,
      color: _cumCostHeaderFill,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _cumCostText,
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return _cellShell(
      width: width,
      color: _cumCostHeaderFill,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _cumCostText,
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
    return _cellShell(
      width: width,
      color: rowIndex.isOdd ? const Color(0xFFF8F8F8) : Colors.white,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _cumCostText),
      ),
    );
  }

  Widget _totalLabelCell(String text, double width) {
    return _cellShell(
      width: width,
      color: const Color(0xFFF1F1F1),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _cumCostText,
        ),
      ),
    );
  }

  Widget _totalValueCell(String text, double width) {
    return _cellShell(
      width: width,
      color: const Color(0xFFF1F1F1),
      alignment: Alignment.centerRight,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _cumCostText,
        ),
      ),
    );
  }

  Widget _cellShell({
    required double width,
    required Widget child,
    required Color color,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Container(
      width: width,
      height: _rowHeight,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _cumCostPanelBorder, width: 0.8),
      ),
      child: child,
    );
  }
}

class _LegacyCumCostGraphPainter extends CustomPainter {
  final List<_CumCostGraphSection> sections;
  final int maxDay;

  const _LegacyCumCostGraphPainter({
    required this.sections,
    required this.maxDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftAxisWidth = 72.0;
    const sectionGap = 34.0;
    const plotTop = 18.0;
    const plotBottomPadding = 42.0;
    const titleAreaWidth = 8.0;

    final plotBottom = size.height - plotBottomPadding;
    final plotHeight = plotBottom - plotTop;
    final maxY = _niceMax(
      sections.expand((section) => section.values).toList(),
    );
    final yTicks = _buildYTicks(maxY);
    final sectionWidth =
        (size.width -
            leftAxisWidth -
            titleAreaWidth -
            (sectionGap * (sections.length - 1))) /
        sections.length;

    final borderPaint = Paint()
      ..color = _cumCostPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _cumCostGrid
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int tickIndex = 0; tickIndex < yTicks.length; tickIndex++) {
      final value = yTicks[tickIndex];
      final y = _yForValue(value, plotTop, plotBottom, maxY);
      textPainter.text = TextSpan(
        text: _formatTick(value),
        style: const TextStyle(fontSize: 10, color: _cumCostText),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          leftAxisWidth - textPainter.width - 10,
          y - textPainter.height / 2,
        ),
      );
    }

    textPainter.text = const TextSpan(
      text: 'Cost (1000Kwd)',
      style: TextStyle(fontSize: 12, color: _cumCostText),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(16, plotTop + plotHeight / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    for (int index = 0; index < sections.length; index++) {
      final section = sections[index];
      final left = leftAxisWidth + index * (sectionWidth + sectionGap);
      final rect = Rect.fromLTWH(left, plotTop, sectionWidth, plotHeight);

      textPainter.text = TextSpan(
        text: section.label,
        style: const TextStyle(fontSize: 12, color: _cumCostText),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (sectionWidth - textPainter.width) / 2, 0),
      );

      canvas.drawRect(rect, borderPaint);

      for (int tickIndex = 1; tickIndex < yTicks.length - 1; tickIndex++) {
        final y = _yForValue(yTicks[tickIndex], plotTop, plotBottom, maxY);
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      }

      for (int column = 1; column < maxDay; column++) {
        final x = rect.left + rect.width * column / maxDay;
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
      }

      final path = _buildStepPath(section.values, rect, maxY);
      if (path != null) {
        canvas.drawPath(
          path,
          Paint()
            ..color = section.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }

      for (int day = 0; day <= maxDay; day++) {
        final x = rect.left + rect.width * day / maxDay;
        textPainter.text = TextSpan(
          text: '$day',
          style: const TextStyle(fontSize: 10, color: _cumCostText),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, plotBottom + 6),
        );
      }
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _cumCostText),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        leftAxisWidth +
            (size.width - leftAxisWidth - textPainter.width - sectionGap) / 2,
        size.height - textPainter.height,
      ),
    );
  }

  Path? _buildStepPath(List<double> values, Rect rect, double maxY) {
    if (values.isEmpty) return null;

    final bottom = rect.bottom;
    final path = Path()..moveTo(rect.left, bottom);
    var currentY = bottom;

    for (int index = 0; index < values.length; index++) {
      final x = rect.left + rect.width * (index + 1) / maxDay;
      final y = _yForValue(values[index], rect.top, rect.bottom, maxY);
      path.lineTo(x, currentY);
      path.lineTo(x, y);
      currentY = y;
    }

    path.lineTo(rect.right, currentY);
    return path;
  }

  List<double> _buildYTicks(double maxValue) {
    if (maxValue <= 1) {
      return List<double>.generate(6, (index) => maxValue * index / 5);
    }
    final top = maxValue.ceilToDouble();
    return List<double>.generate(top.toInt() + 1, (index) => index.toDouble());
  }

  double _niceMax(List<double> values) {
    final maxValue = values.fold<double>(0, math.max);
    if (maxValue <= 0) return 1;
    if (maxValue <= 1) return 1;
    if (maxValue <= 2) return 2;
    if (maxValue <= 3) return 3;
    if (maxValue <= 5) return 5;
    if (maxValue <= 7) return 7;
    if (maxValue <= 10) return 10;

    final exponent = math
        .pow(10, (math.log(maxValue) / math.ln10).floor())
        .toDouble();
    final scaled = maxValue / exponent;
    if (scaled <= 2) return 2 * exponent;
    if (scaled <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  double _yForValue(double value, double top, double bottom, double maxY) {
    if (maxY <= 0) return bottom;
    return bottom - (bottom - top) * (value / maxY).clamp(0.0, 1.0);
  }

  String _formatTick(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _LegacyCumCostGraphPainter oldDelegate) {
    return oldDelegate.sections != sections || oldDelegate.maxDay != maxDay;
  }
}

class _CumCostMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _CumCostMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cumCostPanelBorder),
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
                  color: _cumCostText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _cumCostText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CumCostMessageBody extends StatelessWidget {
  final String message;

  const _CumCostMessageBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _cumCostText),
        ),
      ),
    );
  }
}

class _CumCostGraphSection {
  final String label;
  final List<double> values;
  final Color color;

  const _CumCostGraphSection({
    required this.label,
    required this.values,
    required this.color,
  });
}

class _CumCostTabMeta {
  final String title;

  const _CumCostTabMeta({required this.title});
}

String _formatDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw.trim().isEmpty ? '-' : raw.trim();
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatAmount(double value) {
  if (value == 0) return '0.00';
  return value.toStringAsFixed(2);
}
