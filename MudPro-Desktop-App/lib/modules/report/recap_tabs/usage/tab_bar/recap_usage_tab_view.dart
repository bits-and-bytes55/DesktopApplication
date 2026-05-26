import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/usage/controller/recap_usage_controller.dart';

const Color _usageOuterBorder = Color(0xFF2F92E8);
const Color _usageCanvas = Color(0xFFF4F4F4);
const Color _usagePanelBorder = Color(0xFFC8C8C8);
const Color _usageHeaderFill = Color(0xFFF7F7F7);
const Color _usageText = Color(0xFF1C1C1C);
const Color _usageGrid = Color(0xFFD6D6D6);
const Color _usageTabFill = Color(0xFFEAEAEA);
const Color _usageRec = Color(0xFF8CBBD0);
const Color _usageUsed = Color(0xFFDCEEF6);
const Color _usageFinal = Color(0xFF87C3DB);
const Color _usageSelectedRow = Color(0xFFE9F5FC);

class RecapUsageTabView extends StatefulWidget {
  const RecapUsageTabView({super.key});

  @override
  State<RecapUsageTabView> createState() => _RecapUsageTabViewState();
}

class _RecapUsageTabViewState extends State<RecapUsageTabView> {
  int _selectedTab = 0;

  RecapUsageController get _controller => Get.isRegistered<RecapUsageController>()
      ? Get.find<RecapUsageController>()
      : Get.put(RecapUsageController());

  static const _tabs = [
    _UsageTabMeta(title: 'Graph'),
    _UsageTabMeta(title: 'Table - Usage'),
    _UsageTabMeta(title: 'Table - Product Inventory'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _usageCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _usageOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapUsageController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _UsageMessageState(
        title: 'Product Usage',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty || controller.emptyMessage.value.isNotEmpty) {
      return _UsageMessageState(
        title: 'Product Usage',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live product-usage history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _UsageGraphTab(controller: controller);
      case 1:
        return _UsageHistoryTab(controller: controller);
      case 2:
        return _ProductInventoryTab(controller: controller);
      default:
        return _UsageGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _usageCanvas,
        border: Border(left: BorderSide(color: _usagePanelBorder)),
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
                  color: selected ? Colors.white : _usageTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _usagePanelBorder),
                    left: BorderSide(
                      color: selected ? _usageOuterBorder : _usagePanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _usagePanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _usagePanelBorder)
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
                        color: _usageText,
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

class _UsageGraphTab extends StatelessWidget {
  final RecapUsageController controller;

  const _UsageGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final product = controller.selectedProduct;
    if (product == null) {
      return const _UsageMessageState(
        title: 'Product Usage',
        message: 'No product inventory is available to plot usage history.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _usagePanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 4),
              child: Text(
                'Product Usage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _usageText,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 10, 8),
                child: CustomPaint(
                  painter: _UsageGraphPainter(
                    axisLabel: controller.selectedProductAxisLabel,
                    recSeries: controller.recSeries(),
                    usedSeries: controller.usedSeries(),
                    finalSeries: controller.finalSeries(),
                    slotCount: math.max(6, controller.rows.length),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _UsageLegend(),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageLegend extends StatelessWidget {
  const _UsageLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendItem(label: 'Rec.', color: _usageRec),
        SizedBox(width: 36),
        _LegendItem(label: 'Used', color: _usageUsed),
        SizedBox(width: 36),
        _LegendLineItem(label: 'Final', color: _usageFinal),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _usageText),
        ),
      ],
    );
  }
}

class _LegendLineItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendLineItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 28, height: 2, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _usageText),
        ),
      ],
    );
  }
}

class _UsageHistoryTab extends StatelessWidget {
  final RecapUsageController controller;

  const _UsageHistoryTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final product = controller.selectedProduct;
    final rows = controller.selectedProductRows();
    final columns = [
      const _UsageTableColumn(label: 'Date', width: 92),
      const _UsageTableColumn(label: 'Rpt #', width: 62),
      const _UsageTableColumn(label: 'MD (ft)', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Initial', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Rec.', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Ret.', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Adj.', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Used', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Final', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Cum Rec', width: 86, alignRight: true),
      const _UsageTableColumn(label: 'Cum Ret', width: 86, alignRight: true),
      const _UsageTableColumn(label: 'Cum Used', width: 90, alignRight: true),
      const _UsageTableColumn(label: 'Price', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Cost (\$)', width: 86, alignRight: true),
    ];

    final tableRows = List<_UsageTableRowData>.generate(rows.length, (index) {
      final row = rows[index];
      return _UsageTableRowData(
        key: '${row.reportId}:${index + 1}',
        cells: [
          _formatDate(row.reportDate, row.createdAt),
          row.reportLabel,
          _formatNumber(row.md),
          _formatNumber(row.initial),
          _formatNumber(row.rec),
          _formatNumber(row.ret),
          _formatNumber(row.adj),
          _formatNumber(row.used),
          _formatNumber(row.finalValue),
          _formatNumber(row.cumulativeRec),
          _formatNumber(row.cumulativeRet),
          _formatNumber(row.cumulativeUsed),
          _formatNumber(row.price),
          _formatNumber(row.costDollar),
        ],
      );
    });

    return _UsageTableShell(
      title: product == null ? 'Usage History' : 'Usage - ${product.itemName}',
      columns: columns,
      rows: tableRows,
      selectedKey: '',
      onRowTap: null,
    );
  }
}

class _ProductInventoryTab extends StatelessWidget {
  final RecapUsageController controller;

  const _ProductInventoryTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.productInventoryRows();
    final columns = [
      const _UsageTableColumn(label: 'Date', width: 92),
      const _UsageTableColumn(label: 'Rpt #', width: 62),
      const _UsageTableColumn(label: 'Product', width: 220),
      const _UsageTableColumn(label: 'Unit', width: 88),
      const _UsageTableColumn(label: 'Code', width: 80),
      const _UsageTableColumn(label: 'Price', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Initial', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Rec.', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Ret.', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Adj.', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Used', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Final', width: 78, alignRight: true),
      const _UsageTableColumn(label: 'Cost (\$)', width: 86, alignRight: true),
    ];

    final tableRows = List<_UsageTableRowData>.generate(rows.length, (index) {
      final row = rows[index];
      return _UsageTableRowData(
        key: row.productKey,
        cells: [
          _formatDate(row.reportDate, row.createdAt),
          row.reportLabel,
          row.itemName,
          row.unit,
          row.code,
          _formatNumber(row.price),
          _formatNumber(row.initial),
          _formatNumber(row.rec),
          _formatNumber(row.ret),
          _formatNumber(row.adj),
          _formatNumber(row.used),
          _formatNumber(row.finalValue),
          _formatNumber(row.costDollar),
        ],
      );
    });

    return _UsageTableShell(
      title: 'Product Inventory',
      columns: columns,
      rows: tableRows,
      selectedKey: controller.selectedProductKey.value,
      onRowTap: controller.selectProduct,
    );
  }
}

class _UsageTableShell extends StatelessWidget {
  final String title;
  final List<_UsageTableColumn> columns;
  final List<_UsageTableRowData> rows;
  final String selectedKey;
  final ValueChanged<String>? onRowTap;

  const _UsageTableShell({
    required this.title,
    required this.columns,
    required this.rows,
    required this.selectedKey,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _usagePanelBorder),
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
                  color: _usageText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: _LegacyUsageTable(
                columns: columns,
                rows: rows,
                selectedKey: selectedKey,
                onRowTap: onRowTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyUsageTable extends StatelessWidget {
  final List<_UsageTableColumn> columns;
  final List<_UsageTableRowData> rows;
  final String selectedKey;
  final ValueChanged<String>? onRowTap;

  const _LegacyUsageTable({
    required this.columns,
    required this.rows,
    required this.selectedKey,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseTotalWidth = columns.fold<double>(
      44,
      (sum, column) => sum + column.width,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = math.max(
          baseTotalWidth,
          (constraints.maxWidth - 16).clamp(0, double.infinity).toDouble(),
        );
        final scale =
            baseTotalWidth <= 0 ? 1.0 : totalWidth / baseTotalWidth;
        final noWidth = 44 * scale;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                child: Column(
                  children: [
                    _buildHeader(scale),
                    Expanded(
                      child: ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          final selected =
                              selectedKey.isNotEmpty &&
                              row.key == selectedKey &&
                              onRowTap != null;

                          final rowWidget = Container(
                            color: selected
                                ? _usageSelectedRow
                                : (index.isOdd
                                      ? const Color(0xFFF8F8F8)
                                      : Colors.white),
                            child: Row(
                              children: [
                                _dataCell(
                                  '${index + 1}',
                                  noWidth,
                                  alignRight: true,
                                  selected: selected,
                                ),
                                ...List.generate(columns.length, (cellIndex) {
                                  final column = columns[cellIndex];
                                  final text = cellIndex < row.cells.length
                                      ? row.cells[cellIndex]
                                      : '';
                                  return _dataCell(
                                    text,
                                    column.width * scale,
                                    alignRight: column.alignRight,
                                    selected: selected,
                                  );
                                }),
                              ],
                            ),
                          );

                          if (onRowTap == null) {
                            return SizedBox(height: 31, child: rowWidget);
                          }

                          return SizedBox(
                            height: 31,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onRowTap!(row.key),
                                child: rowWidget,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double scale) {
    return Container(
      height: 31,
      color: _usageHeaderFill,
      child: Row(
        children: [
          _headerCell('No', 44 * scale),
          ...columns.map(
            (column) => _headerCell(column.label, column.width * scale),
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
        color: _usageHeaderFill,
        border: Border.all(color: _usagePanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _usageText,
        ),
      ),
    );
  }

  Widget _dataCell(
    String text,
    double width, {
    bool alignRight = false,
    bool selected = false,
  }) {
    return Container(
      width: width,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: selected ? _usageSelectedRow : null,
        border: Border.all(color: _usagePanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _usageText),
      ),
    );
  }
}

class _UsageGraphPainter extends CustomPainter {
  final String axisLabel;
  final List<double> recSeries;
  final List<double> usedSeries;
  final List<double> finalSeries;
  final int slotCount;

  const _UsageGraphPainter({
    required this.axisLabel,
    required this.recSeries,
    required this.usedSeries,
    required this.finalSeries,
    required this.slotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftLabelWidth = 98.0;
    const yAxisWidth = 44.0;
    const footerHeight = 34.0;
    const topPadding = 4.0;
    final plotLeft = leftLabelWidth + yAxisWidth;
    final plotTop = topPadding;
    final plotRight = size.width - 8;
    final plotBottom = size.height - footerHeight;
    final plotRect = Rect.fromLTRB(plotLeft, plotTop, plotRight, plotBottom);
    final slotWidth = slotCount <= 0 ? 0.0 : (plotRect.width / slotCount);

    final maxValue = _niceMax([
      ...recSeries,
      ...usedSeries,
      ...finalSeries,
    ]);

    final borderPaint = Paint()
      ..color = _usagePanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _usageGrid
      ..strokeWidth = 1;
    final recPaint = Paint()
      ..color = _usageRec
      ..style = PaintingStyle.fill;
    final usedPaint = Paint()
      ..color = _usageUsed
      ..style = PaintingStyle.fill;
    final finalLinePaint = Paint()
      ..color = _usageFinal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final finalPointPaint = Paint()
      ..color = _usageFinal
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    canvas.drawRect(plotRect, borderPaint);

    for (int line = 1; line < 6; line++) {
      final y = plotRect.top + plotRect.height * line / 6;
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

    for (int tick = 0; tick <= 6; tick++) {
      final factor = 1 - (tick / 6);
      final value = maxValue * factor;
      final y = plotRect.top + plotRect.height * tick / 6;
      textPainter.text = TextSpan(
        text: _formatAxisTick(value),
        style: const TextStyle(fontSize: 9.5, color: _usageText),
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
      label: axisLabel,
      top: plotTop,
      height: plotRect.height,
      width: leftLabelWidth,
    );

    final finalPath = Path();
    var finalPathStarted = false;

    for (int index = 0; index < slotCount; index++) {
      final centerX = plotRect.left + slotWidth * index + slotWidth / 2;
      final recValue = index < recSeries.length ? recSeries[index] : 0;
      final usedValue = index < usedSeries.length ? usedSeries[index] : 0;
      final finalValue = index < finalSeries.length ? finalSeries[index] : 0;

      final recHeight = plotRect.height * (recValue / maxValue).clamp(0.0, 1.0);
      final usedHeight =
          plotRect.height * (usedValue / maxValue).clamp(0.0, 1.0);
      final finalY = plotRect.bottom -
          plotRect.height * (finalValue / maxValue).clamp(0.0, 1.0);

      final recRect = Rect.fromLTWH(
        centerX - slotWidth * 0.16,
        plotRect.bottom - recHeight,
        slotWidth * 0.14,
        recHeight,
      );
      final usedRect = Rect.fromLTWH(
        centerX - slotWidth * 0.01,
        plotRect.bottom - usedHeight,
        slotWidth * 0.14,
        usedHeight,
      );
      canvas.drawRect(recRect, recPaint);
      canvas.drawRect(usedRect, usedPaint);

      if (!finalPathStarted) {
        finalPath.moveTo(centerX, finalY);
        finalPathStarted = true;
      } else {
        finalPath.lineTo(centerX, finalY);
      }
      canvas.drawCircle(Offset(centerX, finalY), 2.4, finalPointPaint);
    }

    if (finalPathStarted) {
      canvas.drawPath(finalPath, finalLinePaint);
    }

    final footerTop = plotRect.bottom + 6;
    for (int column = 0; column < slotCount; column++) {
      final x = plotRect.left + slotWidth * column + slotWidth / 2;
      textPainter.text = TextSpan(
        text: '${column + 1}',
        style: const TextStyle(fontSize: 10, color: _usageText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, footerTop));
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _usageText),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        plotRect.left + (plotRect.width - textPainter.width) / 2,
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
      style: const TextStyle(fontSize: 11, color: _usageText),
    );
    textPainter.layout(maxWidth: height - 20);

    canvas.save();
    canvas.translate(14, top + height / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    canvas.drawLine(
      Offset(width, top),
      Offset(width, top + height),
      Paint()
        ..color = _usagePanelBorder
        ..strokeWidth = 1,
    );
  }

  double _niceMax(List<double> values) {
    final filtered = values.where((value) => value > 0).toList();
    if (filtered.isEmpty) return 1;
    final maxValue = filtered.reduce(math.max);
    if (maxValue <= 5) return 5;
    if (maxValue <= 10) return 10;
    if (maxValue <= 20) return 20;
    if (maxValue <= 50) return 50;
    if (maxValue <= 100) return 100;

    final exponent =
        math.pow(10, (math.log(maxValue) / math.ln10).floor()).toDouble();
    final scaled = maxValue / exponent;
    if (scaled <= 2) return 2 * exponent;
    if (scaled <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  String _formatAxisTick(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _UsageGraphPainter oldDelegate) {
    return oldDelegate.axisLabel != axisLabel ||
        oldDelegate.recSeries != recSeries ||
        oldDelegate.usedSeries != usedSeries ||
        oldDelegate.finalSeries != finalSeries ||
        oldDelegate.slotCount != slotCount;
  }
}

class _UsageMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _UsageMessageState({
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
          border: Border.all(color: _usagePanelBorder),
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
                  color: _usageText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _usageText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageTableColumn {
  final String label;
  final double width;
  final bool alignRight;

  const _UsageTableColumn({
    required this.label,
    required this.width,
    this.alignRight = false,
  });
}

class _UsageTableRowData {
  final String key;
  final List<String> cells;

  const _UsageTableRowData({
    required this.key,
    required this.cells,
  });
}

class _UsageTabMeta {
  final String title;

  const _UsageTabMeta({required this.title});
}

String _formatDate(String raw, String createdAt) {
  final source = raw.trim().isNotEmpty ? raw.trim() : createdAt.trim();
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source.isEmpty ? '-' : source;
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatNumber(double value, {int digits = 2}) {
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(digits)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
