import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/recap_daily_cost/controller/recap_daily_cost_controller.dart';

const Color _dailyCostOuterBorder = Color(0xFF2F92E8);
const Color _dailyCostCanvas = Color(0xFFF4F4F4);
const Color _dailyCostPanelBorder = Color(0xFFC8C8C8);
const Color _dailyCostHeaderFill = Color(0xFFF7F7F7);
const Color _dailyCostText = Color(0xFF1C1C1C);
const Color _dailyCostGrid = Color(0xFFD7D7D7);
const Color _dailyCostTabFill = Color(0xFFEAEAEA);
const Color _dailyCostProductBar = Color(0xFF8DB5E8);
const Color _dailyCostPremixedBar = Color(0xFF8FD1E3);
const Color _dailyCostPackageBar = Color(0xFFB7CAE7);
const Color _dailyCostServiceBar = Color(0xFFE2B4B4);
const Color _dailyCostEngineeringBar = Color(0xFFC4B2DE);

class RecapDailycostTabView extends StatefulWidget {
  const RecapDailycostTabView({super.key});

  @override
  State<RecapDailycostTabView> createState() => _RecapDailycostTabViewState();
}

class _RecapDailycostTabViewState extends State<RecapDailycostTabView> {
  int _selectedTab = 0;

  RecapDailyCostController get _controller =>
      Get.isRegistered<RecapDailyCostController>()
      ? Get.find<RecapDailyCostController>()
      : Get.put(RecapDailyCostController());

  static const _tabs = [
    _DailyCostTabMeta(title: 'Graph'),
    _DailyCostTabMeta(title: 'Table - Service'),
    _DailyCostTabMeta(title: 'Table - Engineering'),
    _DailyCostTabMeta(title: 'Table - Product'),
    _DailyCostTabMeta(title: 'Table - Package'),
    _DailyCostTabMeta(title: 'Table - All Categories'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _dailyCostCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _dailyCostOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapDailyCostController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _DailyCostMessageState(
        title: 'Daily Cost',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty) {
      return _DailyCostMessageState(
        title: 'Daily Cost',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live daily cost history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _DailyCostGraphTab(controller: controller);
      case 1:
        return _DailyCostTableTab(
          title: 'Daily Cost - Service',
          rows: controller.rows,
          columns: controller.serviceColumns,
          valueForColumn: (row, column) => row.serviceItems[column] ?? 0,
        );
      case 2:
        return _DailyCostTableTab(
          title: 'Daily Cost - Engineering',
          rows: controller.rows,
          columns: controller.engineeringColumns,
          valueForColumn: (row, column) => row.engineeringItems[column] ?? 0,
        );
      case 3:
        return _DailyCostTableTab(
          title: 'Daily Cost - Product',
          rows: controller.rows,
          columns: controller.productColumns,
          valueForColumn: (row, column) => row.productItems[column] ?? 0,
        );
      case 4:
        return _DailyCostTableTab(
          title: 'Daily Cost - Package',
          rows: controller.rows,
          columns: controller.packageColumns,
          valueForColumn: (row, column) => row.packageItems[column] ?? 0,
        );
      case 5:
        return _DailyCostTableTab(
          title: 'Daily Cost - All Categories',
          rows: controller.rows,
          columns: controller.allCategoryColumns,
          valueForColumn: (row, column) {
            switch (column) {
              case 'Product':
                return row.productTotal;
              case 'Premixed Mud':
                return row.premixedMudTotal;
              case 'Package':
                return row.packageTotal;
              case 'Service':
                return row.serviceTotal;
              case 'Engineering':
                return row.engineeringTotal;
              case 'Total':
                return row.total;
              default:
                return 0;
            }
          },
        );
      default:
        return _DailyCostGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _dailyCostCanvas,
        border: Border(left: BorderSide(color: _dailyCostPanelBorder)),
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
                  color: selected ? Colors.white : _dailyCostTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _dailyCostPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _dailyCostOuterBorder
                          : _dailyCostPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _dailyCostPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _dailyCostPanelBorder)
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
                        color: _dailyCostText,
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

class _DailyCostGraphTab extends StatelessWidget {
  final RecapDailyCostController controller;

  const _DailyCostGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final slotCount = math.max(5, controller.rows.length);
    final sections = [
      _DailyCostGraphSection(
        label: 'Product',
        values: controller.productSeries,
        color: _dailyCostProductBar,
      ),
      _DailyCostGraphSection(
        label: 'Premixed Mud',
        values: controller.premixedSeries,
        color: _dailyCostPremixedBar,
      ),
      _DailyCostGraphSection(
        label: 'Package',
        values: controller.packageSeries,
        color: _dailyCostPackageBar,
      ),
      _DailyCostGraphSection(
        label: 'Service',
        values: controller.serviceSeries,
        color: _dailyCostServiceBar,
      ),
      _DailyCostGraphSection(
        label: 'Engineering',
        values: controller.engineeringSeries,
        color: _dailyCostEngineeringBar,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _dailyCostPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Daily Cost (Kwd)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _dailyCostText,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 8),
                child: CustomPaint(
                  painter: _LegacyDailyCostGraphPainter(
                    sections: sections,
                    slotCount: slotCount,
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

class _DailyCostTableTab extends StatelessWidget {
  final String title;
  final List<DailyCostHistoryRow> rows;
  final List<String> columns;
  final double Function(DailyCostHistoryRow row, String column) valueForColumn;

  const _DailyCostTableTab({
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
          border: Border.all(color: _dailyCostPanelBorder),
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
                  color: _dailyCostText,
                ),
              ),
            ),
            Expanded(
              child: columns.isEmpty
                  ? const _DailyCostMessageBody(
                      message: 'No live category rows are available yet.',
                    )
                  : _LegacyDailyCostTable(
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

class _LegacyDailyCostTable extends StatefulWidget {
  final List<DailyCostHistoryRow> rows;
  final List<String> columns;
  final double Function(DailyCostHistoryRow row, String column) valueForColumn;

  const _LegacyDailyCostTable({
    required this.rows,
    required this.columns,
    required this.valueForColumn,
  });

  @override
  State<_LegacyDailyCostTable> createState() => _LegacyDailyCostTableState();
}

class _LegacyDailyCostTableState extends State<_LegacyDailyCostTable> {
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
    final dynamicWidth = widget.columns.length * _columnWidth;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Container(
            height: _rowHeight,
            color: _dailyCostHeaderFill,
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
                            .map((column) => _headerCell(column, _columnWidth))
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
                                  _columnWidth,
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
                _totalLabelCell('Total', _indexWidth + _dateWidth),
                _totalValueCell('', _mdWidth),
                _totalValueCell('', _reportWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _footerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dynamicWidth,
                      child: Row(
                        children: widget.columns.map((column) {
                          final total = widget.rows.fold<double>(
                            0,
                            (sum, row) =>
                                sum + widget.valueForColumn(row, column),
                          );
                          return _totalValueCell(
                            _formatAmount(total),
                            _columnWidth,
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
  }

  Widget _fixedHeaderCell(String text, double width) {
    return _cellShell(
      width: width,
      color: _dailyCostHeaderFill,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _dailyCostText,
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return _cellShell(
      width: width,
      color: _dailyCostHeaderFill,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _dailyCostText,
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
        style: const TextStyle(fontSize: 11, color: _dailyCostText),
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
          color: _dailyCostText,
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
          color: _dailyCostText,
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
        border: Border.all(color: _dailyCostPanelBorder, width: 0.8),
      ),
      child: child,
    );
  }
}

class _LegacyDailyCostGraphPainter extends CustomPainter {
  final List<_DailyCostGraphSection> sections;
  final int slotCount;

  const _LegacyDailyCostGraphPainter({
    required this.sections,
    required this.slotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftLabelWidth = 34.0;
    const yAxisWidth = 48.0;
    const footerHeight = 28.0;
    const sectionGap = 2.0;

    final usableHeight =
        size.height - footerHeight - (sections.length - 1) * sectionGap;
    final sectionHeight = usableHeight / sections.length;
    final plotLeft = leftLabelWidth + yAxisWidth;
    final plotRight = size.width - 8;
    final slotSpacing = slotCount <= 0
        ? 0.0
        : (plotRight - plotLeft) / slotCount;

    final borderPaint = Paint()
      ..color = _dailyCostPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _dailyCostGrid
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int index = 0; index < sections.length; index++) {
      final top = index * (sectionHeight + sectionGap);
      final bottom = top + sectionHeight;
      final plotRect = Rect.fromLTRB(plotLeft, top, plotRight, bottom);
      final scaleMax = _niceMax(sections[index].values);

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
        final x = plotRect.left + slotSpacing * column;
        canvas.drawLine(
          Offset(x, plotRect.top),
          Offset(x, plotRect.bottom),
          gridPaint,
        );
      }

      for (int tick = 0; tick <= 4; tick++) {
        final value = scaleMax * (4 - tick) / 4;
        final y = plotRect.top + plotRect.height * tick / 4;
        final label = _formatTick(value, scaleMax);
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(fontSize: 10, color: _dailyCostText),
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

      final barWidth = math.min(18.0, math.max(10.0, slotSpacing * 0.28));
      for (
        int barIndex = 0;
        barIndex < sections[index].values.length;
        barIndex++
      ) {
        final value = sections[index].values[barIndex];
        if (value <= 0) continue;

        final heightFactor = scaleMax <= 0
            ? 0.0
            : (value / scaleMax).clamp(0.0, 1.0);
        final barLeft =
            plotRect.left +
            slotSpacing * barIndex +
            (slotSpacing - barWidth) / 2;
        final barTop = plotRect.bottom - plotRect.height * heightFactor;
        final rect = Rect.fromLTWH(
          barLeft,
          barTop,
          barWidth,
          plotRect.bottom - barTop,
        );

        canvas.drawRect(rect, Paint()..color = sections[index].color);
        canvas.drawRect(
          rect,
          Paint()
            ..color = sections[index].color.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      _drawVerticalLabel(
        canvas,
        section: sections[index],
        left: 0,
        top: top,
        width: leftLabelWidth,
        height: sectionHeight,
      );
    }

    final footerTop = size.height - footerHeight + 2;
    for (int column = 0; column < slotCount; column++) {
      final label = '${column + 1}';
      final x = plotLeft + slotSpacing * column + slotSpacing / 2;
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 10, color: _dailyCostText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, footerTop));
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _dailyCostText),
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
    Canvas canvas, {
    required _DailyCostGraphSection section,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: section.label,
      style: const TextStyle(fontSize: 11, color: _dailyCostText),
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(left + 10, top + height / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  double _niceMax(List<double> values) {
    final maxValue = values.fold<double>(0, math.max);
    if (maxValue <= 0) return 2;
    if (maxValue <= 2) return 2;

    final exponent = math
        .pow(10, (math.log(maxValue) / math.ln10).floor())
        .toDouble();
    final scaled = maxValue / exponent;
    const niceSteps = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0];

    for (final step in niceSteps) {
      if (scaled <= step) {
        return step * exponent;
      }
    }

    return 10 * exponent;
  }

  String _formatTick(double value, double maxValue) {
    if (maxValue <= 2) {
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
    }
    if (maxValue < 10) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _LegacyDailyCostGraphPainter oldDelegate) {
    return oldDelegate.sections != sections ||
        oldDelegate.slotCount != slotCount;
  }
}

class _DailyCostMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _DailyCostMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _dailyCostPanelBorder),
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
                  color: _dailyCostText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _dailyCostText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCostMessageBody extends StatelessWidget {
  final String message;

  const _DailyCostMessageBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _dailyCostText),
        ),
      ),
    );
  }
}

class _DailyCostGraphSection {
  final String label;
  final List<double> values;
  final Color color;

  const _DailyCostGraphSection({
    required this.label,
    required this.values,
    required this.color,
  });
}

class _DailyCostTabMeta {
  final String title;

  const _DailyCostTabMeta({required this.title});
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
