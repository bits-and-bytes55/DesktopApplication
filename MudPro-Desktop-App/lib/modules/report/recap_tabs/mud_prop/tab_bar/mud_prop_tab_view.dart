import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/mud_prop/controller/mud_prop_controller.dart';

const Color _mudPropOuterBorder = Color(0xFFB8D0EA);
const Color _mudPropCanvas = Color(0xFFF4F6FA);
const Color _mudPropPanelBorder = Color(0xFFB8D0EA);
const Color _mudPropHeaderFill = Color(0xFFEAF3FC);
const Color _mudPropText = Color(0xFF1C1C1C);
const Color _mudPropGrid = Color(0xFFCFE0F2);
const Color _mudPropTabFill = Color(0xFFEAF3FC);
const Color _mudPropFluidColor = Color(0xFFB5B2E5);
const Color _mudPropPlanColor = Color(0xFFDDE7F4);
const Color _mudPropActualLine = Color(0xFF8C88D8);
const Color _mudPropPlanLine = Color(0xFFBFCFDF);

class MudPropTabView extends StatefulWidget {
  const MudPropTabView({super.key});

  @override
  State<MudPropTabView> createState() => _MudPropTabViewState();
}

class _MudPropTabViewState extends State<MudPropTabView> {
  int _selectedTab = 0;

  RecapMudPropController get _controller =>
      Get.isRegistered<RecapMudPropController>()
      ? Get.find<RecapMudPropController>()
      : Get.put(RecapMudPropController());

  static const _tabs = [
    _MudPropTabMeta(title: 'Graph'),
    _MudPropTabMeta(title: 'Table - Water'),
    _MudPropTabMeta(title: 'Table - Oil/Synthetic'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _mudPropCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _mudPropOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapMudPropController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _MudPropMessageState(
        title: 'Mud Properties',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty) {
      return _MudPropMessageState(
        title: 'Mud Properties',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live mud-property history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _MudPropGraphTab(controller: controller);
      case 1:
        return _MudPropTableTab(
          title: 'Mud Properties - Water - Sample 1',
          rows: controller.waterRows,
          columns: controller.waterTableMetrics,
        );
      case 2:
        return _MudPropTableTab(
          title: 'Mud Properties - Oil/Synthetic - Sample 1',
          rows: controller.oilSyntheticRows,
          columns: controller.oilSyntheticTableMetrics,
        );
      default:
        return _MudPropGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _mudPropCanvas,
        border: Border(left: BorderSide(color: _mudPropPanelBorder)),
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
                  color: selected ? Colors.white : _mudPropTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _mudPropPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _mudPropOuterBorder
                          : _mudPropPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _mudPropPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _mudPropPanelBorder)
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
                        color: _mudPropText,
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

class _MudPropGraphTab extends StatelessWidget {
  final RecapMudPropController controller;

  const _MudPropGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final metrics = controller.selectedGroupMetrics;
    final slotCount = math.max(5, controller.rows.length);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _mudPropPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const SizedBox(width: 140),
                  const Expanded(
                    child: Text(
                      'Mud Properties - Sample 1',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: _mudPropText,
                      ),
                    ),
                  ),
                  _GroupDropdown(controller: controller),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 18, 8),
              child: Row(
                children: [
                  _LegendItem(
                    color: _mudPropFluidColor,
                    label: controller.primaryFluidLabel,
                  ),
                  const Spacer(),
                  if (controller.hasPlanData)
                    const _LegendItem(
                      color: _mudPropPlanColor,
                      label: 'Plan',
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 8),
                child: CustomPaint(
                  painter: _LegacyMudPropGraphPainter(
                    rows: controller.rows.toList(),
                    metrics: metrics,
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

class _GroupDropdown extends StatelessWidget {
  final RecapMudPropController controller;

  const _GroupDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: _mudPropPanelBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedGroup.id,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: _mudPropText),
          style: const TextStyle(fontSize: 12, color: _mudPropText),
          items: controller.activeGroups
              .map(
                (group) => DropdownMenuItem<String>(
                  value: group.id,
                  child: Text(group.label),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              controller.selectGroup(value);
            }
          },
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _mudPropText),
        ),
      ],
    );
  }
}

class _MudPropTableTab extends StatelessWidget {
  final String title;
  final List<MudPropHistoryRow> rows;
  final List<MudPropertyMetricDefinition> columns;

  const _MudPropTableTab({
    required this.title,
    required this.rows,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _mudPropPanelBorder),
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
                  color: _mudPropText,
                ),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const _MudPropMessageBody(
                      message: 'No rows are available for this fluid family yet.',
                    )
                  : _LegacyMudPropTable(rows: rows, columns: columns),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyMudPropTable extends StatefulWidget {
  final List<MudPropHistoryRow> rows;
  final List<MudPropertyMetricDefinition> columns;

  const _LegacyMudPropTable({
    required this.rows,
    required this.columns,
  });

  @override
  State<_LegacyMudPropTable> createState() => _LegacyMudPropTableState();
}

class _LegacyMudPropTableState extends State<_LegacyMudPropTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  static const double _rowHeight = 31;
  static const double _indexWidth = 52;
  static const double _dateWidth = 100;
  static const double _mdWidth = 82;
  static const double _reportWidth = 70;
  static const double _columnWidth = 128;

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
            color: _mudPropHeaderFill,
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
                            .map(
                              (column) =>
                                  _headerCell(_columnTitle(column), columnWidth),
                            )
                            .toList(growable: false),
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
                                  row.metric(column.id)?.actualText.isNotEmpty == true
                                      ? row.metric(column.id)!.actualText
                                      : '-',
                                  columnWidth,
                                  index,
                                );
                              }).toList(growable: false),
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

  String _columnTitle(MudPropertyMetricDefinition definition) {
    final unit = _resolveUnit(definition);
    return unit.isEmpty ? definition.label : '${definition.label} ($unit)';
  }

  String _resolveUnit(MudPropertyMetricDefinition definition) {
    for (final row in widget.rows) {
      final unit = row.metric(definition.id)?.unit.trim() ?? '';
      if (unit.isNotEmpty) return _cleanUnit(unit);
    }
    return _cleanUnit(definition.defaultUnit);
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _mudPropHeaderFill,
        border: Border.all(color: _mudPropPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _mudPropText,
        ),
      ),
    );
  }

  Widget _dataCell(String text, double width, int rowIndex) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: rowIndex.isOdd ? const Color(0xFFF8F8F8) : Colors.white,
        border: Border.all(color: _mudPropPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _mudPropText),
      ),
    );
  }
}

class _LegacyMudPropGraphPainter extends CustomPainter {
  final List<MudPropHistoryRow> rows;
  final List<MudPropertyMetricDefinition> metrics;
  final int slotCount;

  const _LegacyMudPropGraphPainter({
    required this.rows,
    required this.metrics,
    required this.slotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftLabelWidth = 66.0;
    const yAxisWidth = 38.0;
    const footerHeight = 30.0;
    const sectionGap = 3.0;

    final usableHeight =
        size.height - footerHeight - (metrics.length - 1) * sectionGap;
    final sectionHeight = usableHeight / metrics.length;
    final plotLeft = leftLabelWidth + yAxisWidth;
    final plotRight = size.width - 8;
    final slotWidth = slotCount <= 0 ? 0.0 : (plotRight - plotLeft) / slotCount;

    final borderPaint = Paint()
      ..color = _mudPropPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _mudPropGrid
      ..strokeWidth = 1;
    final actualPaint = Paint()
      ..color = _mudPropActualLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final planPaint = Paint()
      ..color = _mudPropPlanLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final actualPointPaint = Paint()
      ..color = _mudPropActualLine
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int index = 0; index < metrics.length; index++) {
      final metric = metrics[index];
      final top = index * (sectionHeight + sectionGap);
      final bottom = top + sectionHeight;
      final plotRect = Rect.fromLTRB(plotLeft, top, plotRight, bottom);
      final actualValues = rows
          .map((row) => row.metric(metric.id)?.actualNumber)
          .toList(growable: false);
      final planValues = rows
          .map((row) => row.metric(metric.id)?.planNumber)
          .toList(growable: false);
      final range = _niceRange(actualValues, planValues);

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
        final value = range.max - ((range.max - range.min) * tick / 4);
        final y = plotRect.top + plotRect.height * tick / 4;
        textPainter.text = TextSpan(
          text: _formatAxisTick(value, range.max),
          style: const TextStyle(fontSize: 10, color: _mudPropText),
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
        label: '${metric.label}\n(${_metricUnit(rows, metric)})',
        top: top,
        height: sectionHeight,
        width: leftLabelWidth,
      );

      final planPath = _buildSeriesPath(
        values: planValues,
        rect: plotRect,
        min: range.min,
        max: range.max,
        slotWidth: slotWidth,
      );
      if (planPath != null) {
        canvas.drawPath(planPath, planPaint);
      }

      final actualPath = _buildSeriesPath(
        values: actualValues,
        rect: plotRect,
        min: range.min,
        max: range.max,
        slotWidth: slotWidth,
      );
      if (actualPath != null) {
        canvas.drawPath(actualPath, actualPaint);
      }

      for (int pointIndex = 0; pointIndex < actualValues.length; pointIndex++) {
        final value = actualValues[pointIndex];
        if (value == null) continue;
        final x = plotRect.left + slotWidth * pointIndex + slotWidth / 2;
        final y = _yForValue(value, plotRect, range.min, range.max);
        canvas.drawCircle(Offset(x, y), 2.4, actualPointPaint);
      }
    }

    final footerTop = size.height - footerHeight + 4;
    for (int column = 0; column < slotCount; column++) {
      final x = plotLeft + slotWidth * column + slotWidth / 2;
      textPainter.text = TextSpan(
        text: '${column + 1}',
        style: const TextStyle(fontSize: 10, color: _mudPropText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, footerTop));
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _mudPropText),
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
      style: const TextStyle(fontSize: 11, color: _mudPropText),
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
        ..color = _mudPropPanelBorder
        ..strokeWidth = 1,
    );
  }

  String _metricUnit(
    List<MudPropHistoryRow> rows,
    MudPropertyMetricDefinition definition,
  ) {
    for (final row in rows) {
      final unit = row.metric(definition.id)?.unit.trim() ?? '';
      if (unit.isNotEmpty) return _cleanUnit(unit);
    }
    return _cleanUnit(definition.defaultUnit);
  }

  _AxisRange _niceRange(List<double?> actualValues, List<double?> planValues) {
    final values = <double>[
      ...actualValues.whereType<double>(),
      ...planValues.whereType<double>(),
    ];

    if (values.isEmpty) {
      return const _AxisRange(min: 0, max: 1);
    }

    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if ((maxValue - minValue).abs() < 0.0001) {
      final padding = maxValue == 0 ? 1.0 : (maxValue.abs() * 0.1);
      minValue -= padding;
      maxValue += padding;
    }

    final span = maxValue - minValue;
    final padding = span * 0.12;
    minValue -= padding;
    maxValue += padding;

    if (minValue >= 0 && values.every((value) => value >= 0)) {
      minValue = math.max(0, minValue);
    }

    return _AxisRange(min: minValue, max: maxValue);
  }

  Path? _buildSeriesPath({
    required List<double?> values,
    required Rect rect,
    required double min,
    required double max,
    required double slotWidth,
  }) {
    final path = Path();
    var hasPoint = false;

    for (int pointIndex = 0; pointIndex < values.length; pointIndex++) {
      final value = values[pointIndex];
      if (value == null) continue;

      final x = rect.left + slotWidth * pointIndex + slotWidth / 2;
      final y = _yForValue(value, rect, min, max);
      if (!hasPoint) {
        path.moveTo(x, y);
        hasPoint = true;
      } else {
        path.lineTo(x, y);
      }
    }

    return hasPoint ? path : null;
  }

  double _yForValue(double value, Rect rect, double min, double max) {
    if ((max - min).abs() < 0.0001) return rect.center.dy;
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return rect.bottom - rect.height * normalized;
  }

  String _formatAxisTick(double value, double max) {
    if (max.abs() < 10) {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _LegacyMudPropGraphPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.metrics != metrics ||
        oldDelegate.slotCount != slotCount;
  }
}

class _MudPropMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _MudPropMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _mudPropPanelBorder),
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
                  color: _mudPropText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _mudPropText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MudPropMessageBody extends StatelessWidget {
  final String message;

  const _MudPropMessageBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _mudPropText),
        ),
      ),
    );
  }
}

class _MudPropTabMeta {
  final String title;

  const _MudPropTabMeta({required this.title});
}

class _AxisRange {
  final double min;
  final double max;

  const _AxisRange({required this.min, required this.max});
}

String _cleanUnit(String value) {
  return value
      .replaceAll('Ã‚', '')
      .replaceAll('Â²', '2')
      .replaceAll('Â³', '3')
      .trim();
}

String _formatDate(String raw, String createdAt) {
  final source = raw.trim().isNotEmpty ? raw.trim() : createdAt.trim();
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source.isEmpty ? '-' : source;
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatNumber(double value) {
  if (value == 0) return '0';
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
