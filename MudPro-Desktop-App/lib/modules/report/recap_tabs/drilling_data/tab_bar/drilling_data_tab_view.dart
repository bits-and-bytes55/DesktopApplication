import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/drilling_data/controller/drilling_data_controller.dart';

const Color _drillingOuterBorder = Color(0xFFB8D0EA);
const Color _drillingCanvas = Color(0xFFF4F6FA);
const Color _drillingPanelBorder = Color(0xFFB8D0EA);
const Color _drillingHeaderFill = Color(0xFFEAF3FC);
const Color _drillingText = Color(0xFF1C1C1C);
const Color _drillingGrid = Color(0xFFCFE0F2);
const Color _drillingTabFill = Color(0xFFEAF3FC);
const Color _drillingMudStrip = Color(0xFFB5B2E5);
const Color _drillingLine = Color(0xFF94B7E8);

class DrillingDataTabView extends StatefulWidget {
  const DrillingDataTabView({super.key});

  @override
  State<DrillingDataTabView> createState() => _DrillingDataTabViewState();
}

class _DrillingDataTabViewState extends State<DrillingDataTabView> {
  int _selectedTab = 0;

  RecapDrillingDataController get _controller =>
      Get.isRegistered<RecapDrillingDataController>()
      ? Get.find<RecapDrillingDataController>()
      : Get.put(RecapDrillingDataController());

  static const _tabs = [
    _DrillingTabMeta(title: 'Graph'),
    _DrillingTabMeta(title: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _drillingCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _drillingOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapDrillingDataController controller) {
    AppUnits.signature;

    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _DrillingMessageState(
        title: 'Drilling Data',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty) {
      return _DrillingMessageState(
        title: 'Drilling Data',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live drilling history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _DrillingGraphTab(controller: controller);
      case 1:
        return _DrillingTableTab(rows: controller.rows.toList());
      default:
        return _DrillingGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _drillingCanvas,
        border: Border(left: BorderSide(color: _drillingPanelBorder)),
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
                  color: selected ? Colors.white : _drillingTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _drillingPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _drillingOuterBorder
                          : _drillingPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _drillingPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _drillingPanelBorder)
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
                        color: _drillingText,
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

class _DrillingGraphTab extends StatelessWidget {
  final RecapDrillingDataController controller;

  const _DrillingGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final metricSections = [
      _DrillingMetricSection(
        label: 'WOB',
        unit: _unitSuffix(AppUnits.force),
        values: controller.wobSeries,
      ),
      _DrillingMetricSection(
        label: 'S/O Wt.',
        unit: _unitSuffix(AppUnits.force),
        values: controller.soWtSeries,
      ),
      _DrillingMetricSection(
        label: 'P/U Wt.',
        unit: _unitSuffix(AppUnits.force),
        values: controller.puWtSeries,
      ),
      _DrillingMetricSection(
        label: 'RPM',
        unit: _unitSuffix(AppUnits.rotation),
        values: controller.rpmSeries,
      ),
      _DrillingMetricSection(
        label: 'ROP',
        unit: _unitSuffix(AppUnits.rop),
        values: controller.ropSeries,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _drillingPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Drilling Data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _drillingText,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              child: _MudTypeLegend(rows: controller.rows.toList()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: _MudTypeBand(rows: controller.rows.toList()),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 8),
                child: CustomPaint(
                  painter: _LegacyDrillingGraphPainter(
                    sections: metricSections,
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

class _MudTypeLegend extends StatelessWidget {
  final List<DrillingDataHistoryRow> rows;

  const _MudTypeLegend({required this.rows});

  @override
  Widget build(BuildContext context) {
    final uniqueMudTypes = <String>[];
    for (final row in rows) {
      final mudType = row.mudType.trim().isEmpty ? 'Unspecified' : row.mudType;
      if (!uniqueMudTypes.contains(mudType)) {
        uniqueMudTypes.add(mudType);
      }
    }

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: List.generate(uniqueMudTypes.length, (index) {
        final mudType = uniqueMudTypes[index];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              color: _mudTypeColor(mudType, index),
            ),
            const SizedBox(width: 6),
            Text(
              mudType,
              style: const TextStyle(fontSize: 11, color: _drillingText),
            ),
          ],
        );
      }),
    );
  }
}

class _MudTypeBand extends StatelessWidget {
  final List<DrillingDataHistoryRow> rows;

  const _MudTypeBand({required this.rows});

  @override
  Widget build(BuildContext context) {
    final slotCount = math.max(5, rows.length);

    return Container(
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: _drillingPanelBorder),
      ),
      child: Row(
        children: List.generate(slotCount, (index) {
          final mudType = index < rows.length
              ? (rows[index].mudType.trim().isEmpty
                    ? 'Unspecified'
                    : rows[index].mudType)
              : '';
          final color = mudType.isEmpty
              ? _drillingMudStrip.withValues(alpha: 0.35)
              : _mudTypeColor(mudType, index);

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: Border(
                  right: index == slotCount - 1
                      ? BorderSide.none
                      : const BorderSide(color: _drillingPanelBorder, width: 0.8),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DrillingTableTab extends StatelessWidget {
  final List<DrillingDataHistoryRow> rows;

  const _DrillingTableTab({required this.rows});

  @override
  Widget build(BuildContext context) {
    final columns = [
      _DrillingTableColumn(
        title: 'TVD (${_unitSuffix(AppUnits.length)})',
        valueFor: (row) => _formatMetric(row.tvd),
      ),
      const _DrillingTableColumn(
        title: 'Inc.',
        valueFor: _angleValue,
      ),
      const _DrillingTableColumn(
        title: 'Azi.',
        valueFor: _aziValue,
      ),
      _DrillingTableColumn(
        title: 'WOB (${_unitSuffix(AppUnits.force)})',
        valueFor: (row) => _formatMetric(row.wob),
      ),
      _DrillingTableColumn(
        title: 'Rot. Wt. (${_unitSuffix(AppUnits.force)})',
        valueFor: (row) => _formatMetric(row.rotWt),
      ),
      _DrillingTableColumn(
        title: 'S/O Wt. (${_unitSuffix(AppUnits.force)})',
        valueFor: (row) => _formatMetric(row.soWt),
      ),
      _DrillingTableColumn(
        title: 'P/U Wt. (${_unitSuffix(AppUnits.force)})',
        valueFor: (row) => _formatMetric(row.puWt),
      ),
      _DrillingTableColumn(
        title: 'RPM (${_unitSuffix(AppUnits.rotation)})',
        valueFor: (row) => _formatMetric(row.rpm),
      ),
      _DrillingTableColumn(
        title: 'ROP (${_unitSuffix(AppUnits.rop)})',
        valueFor: (row) => _formatMetric(row.rop),
      ),
      _DrillingTableColumn(
        title: 'Depth Drilled (${_unitSuffix(AppUnits.length)})',
        valueFor: (row) => _formatMetric(row.depthDrilled),
      ),
      const _DrillingTableColumn(title: 'Activity', valueFor: _activityValue),
      const _DrillingTableColumn(title: 'Interval', valueFor: _intervalValue),
      const _DrillingTableColumn(title: 'Formation', valueFor: _formationValue),
      const _DrillingTableColumn(title: 'Mud Type', valueFor: _mudTypeValue),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _drillingPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Drilling Data - Table',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _drillingText,
                ),
              ),
            ),
            Expanded(
              child: _LegacyDrillingDataTable(
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

class _LegacyDrillingDataTable extends StatefulWidget {
  final List<DrillingDataHistoryRow> rows;
  final List<_DrillingTableColumn> columns;

  const _LegacyDrillingDataTable({
    required this.rows,
    required this.columns,
  });

  @override
  State<_LegacyDrillingDataTable> createState() => _LegacyDrillingDataTableState();
}

class _LegacyDrillingDataTableState extends State<_LegacyDrillingDataTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  static const double _rowHeight = 31;
  static const double _indexWidth = 52;
  static const double _dateWidth = 100;
  static const double _mdWidth = 82;
  static const double _reportWidth = 70;
  static const double _columnWidth = 122;

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
            color: _drillingHeaderFill,
            child: Row(
              children: [
                _headerCell('No', _indexWidth),
                _headerCell('Date', _dateWidth),
                _headerCell('MD (${_unitSuffix(AppUnits.length)})', _mdWidth),
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
                            _dataCell(_formatMetric(row.md), _mdWidth, index),
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
        color: _drillingHeaderFill,
        border: Border.all(color: _drillingPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _drillingText,
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
        border: Border.all(color: _drillingPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _drillingText),
      ),
    );
  }
}

class _LegacyDrillingGraphPainter extends CustomPainter {
  final List<_DrillingMetricSection> sections;
  final int slotCount;

  const _LegacyDrillingGraphPainter({
    required this.sections,
    required this.slotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftLabelWidth = 66.0;
    const yAxisWidth = 38.0;
    const footerHeight = 30.0;
    const sectionGap = 3.0;

    final usableHeight =
        size.height - footerHeight - (sections.length - 1) * sectionGap;
    final sectionHeight = usableHeight / sections.length;
    final plotLeft = leftLabelWidth + yAxisWidth;
    final plotRight = size.width - 8;
    final slotWidth = slotCount <= 0 ? 0.0 : (plotRight - plotLeft) / slotCount;

    final borderPaint = Paint()
      ..color = _drillingPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _drillingGrid
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = _drillingLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final pointPaint = Paint()
      ..color = _drillingLine
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int index = 0; index < sections.length; index++) {
      final section = sections[index];
      final top = index * (sectionHeight + sectionGap);
      final bottom = top + sectionHeight;
      final plotRect = Rect.fromLTRB(plotLeft, top, plotRight, bottom);
      final maxValue = _niceMax(section.values);

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

      for (int tick = 0; tick <= 2; tick++) {
        final factor = 1 - (tick / 2);
        final value = maxValue * factor;
        final y = plotRect.bottom - plotRect.height * factor;
        textPainter.text = TextSpan(
          text: _formatAxisTick(value, maxValue),
          style: const TextStyle(fontSize: 10, color: _drillingText),
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

      final path = Path();
      bool hasPoint = false;
      for (int pointIndex = 0; pointIndex < section.values.length; pointIndex++) {
        final value = section.values[pointIndex];
        final x = plotRect.left + slotWidth * pointIndex + slotWidth / 2;
        final y = plotRect.bottom -
            (plotRect.height * (value / maxValue).clamp(0.0, 1.0));

        if (!hasPoint) {
          path.moveTo(x, y);
          hasPoint = true;
        } else {
          path.lineTo(x, y);
        }

        canvas.drawCircle(Offset(x, y), 2.4, pointPaint);
      }

      if (hasPoint) {
        canvas.drawPath(path, linePaint);
      }
    }

    final footerTop = size.height - footerHeight + 4;
    for (int column = 0; column < slotCount; column++) {
      final x = plotLeft + slotWidth * column + slotWidth / 2;
      textPainter.text = TextSpan(
        text: '${column + 1}',
        style: const TextStyle(fontSize: 10, color: _drillingText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, footerTop));
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _drillingText),
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
      style: const TextStyle(fontSize: 11, color: _drillingText),
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
        ..color = _drillingPanelBorder
        ..strokeWidth = 1,
    );
  }

  double _niceMax(List<double> values) {
    final maxValue = values.fold<double>(0, math.max);
    if (maxValue <= 0) return 1;
    if (maxValue <= 1) return 1;
    if (maxValue <= 2) return 2;
    if (maxValue <= 5) return 5;
    if (maxValue <= 10) return 10;
    if (maxValue <= 50) return 50;
    if (maxValue <= 100) return 100;
    if (maxValue <= 1000) return 1000;

    final exponent = math
        .pow(10, (math.log(maxValue) / math.ln10).floor())
        .toDouble();
    final scaled = maxValue / exponent;
    if (scaled <= 2) return 2 * exponent;
    if (scaled <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  String _formatAxisTick(double value, double maxValue) {
    if (maxValue <= 2) {
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
    }
    if (maxValue < 10) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(value >= 100 ? 0 : 1).replaceAll('.0', '');
  }

  @override
  bool shouldRepaint(covariant _LegacyDrillingGraphPainter oldDelegate) {
    return oldDelegate.sections != sections || oldDelegate.slotCount != slotCount;
  }
}

class _DrillingMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _DrillingMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _drillingPanelBorder),
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
                  color: _drillingText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _drillingText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrillingMetricSection {
  final String label;
  final String unit;
  final List<double> values;

  const _DrillingMetricSection({
    required this.label,
    required this.unit,
    required this.values,
  });
}

class _DrillingTableColumn {
  final String title;
  final String Function(DrillingDataHistoryRow row) valueFor;

  const _DrillingTableColumn({
    required this.title,
    required this.valueFor,
  });
}

class _DrillingTabMeta {
  final String title;

  const _DrillingTabMeta({required this.title});
}

String _unitSuffix(String unit) => AppUnits.strip(unit);

Color _mudTypeColor(String mudType, int index) {
  final palette = [
    const Color(0xFFB5B2E5),
    const Color(0xFF9BC7E8),
    const Color(0xFFB8D9B8),
    const Color(0xFFE7C3A7),
    const Color(0xFFD9B8D3),
  ];
  final normalized = mudType.trim().toLowerCase();
  if (normalized.contains('water')) return palette[0];
  if (normalized.contains('oil')) return palette[1];
  if (normalized.contains('synthetic')) return palette[2];
  return palette[index % palette.length];
}

String _formatMetric(double value) {
  if (value == 0) return '0';
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(
    RegExp(r'\.$'),
    '',
  );
}

String _formatDate(String raw, String createdAt) {
  final source = raw.trim().isNotEmpty ? raw.trim() : createdAt.trim();
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source.isEmpty ? '-' : source;
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}

String _angleValue(DrillingDataHistoryRow row) => _formatMetric(row.inc);
String _aziValue(DrillingDataHistoryRow row) => _formatMetric(row.azi);
String _activityValue(DrillingDataHistoryRow row) =>
    row.activity.isEmpty ? '-' : row.activity;
String _intervalValue(DrillingDataHistoryRow row) =>
    row.interval.isEmpty ? '-' : row.interval;
String _formationValue(DrillingDataHistoryRow row) =>
    row.formation.isEmpty ? '-' : row.formation;
String _mudTypeValue(DrillingDataHistoryRow row) =>
    row.mudType.isEmpty ? '-' : row.mudType;
