import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/customized/controller/recap_customized_controller.dart';

const Color _customizedOuterBorder = Color(0xFFB8D0EA);
const Color _customizedCanvas = Color(0xFFF4F6FA);
const Color _customizedPanelBorder = Color(0xFFB8D0EA);
const Color _customizedText = Color(0xFF1C1C1C);
const Color _customizedGrid = Color(0xFFCFE0F2);
const Color _customizedLine = Color(0xFF84D0F4);
const Color _customizedTabFill = Color(0xFFEAF3FC);
const Color _customizedHeaderFill = Color(0xFFEAF3FC);

class RecapCustomizedTabView extends StatefulWidget {
  const RecapCustomizedTabView({super.key});

  @override
  State<RecapCustomizedTabView> createState() => _RecapCustomizedTabViewState();
}

class _RecapCustomizedTabViewState extends State<RecapCustomizedTabView> {
  int _selectedTab = 0;

  RecapCustomizedController get _controller =>
      Get.isRegistered<RecapCustomizedController>()
      ? Get.find<RecapCustomizedController>()
      : Get.put(RecapCustomizedController());

  static const _tabs = [
    _CustomizedTabMeta(title: 'Graph'),
    _CustomizedTabMeta(title: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _customizedCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _customizedOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapCustomizedController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _CustomizedMessageState(
        title: 'Customized Graph',
        message: controller.errorMessage.value,
      );
    }

    switch (_selectedTab) {
      case 0:
        return _CustomizedGraphTab(controller: controller);
      case 1:
        return _CustomizedTableTab(controller: controller);
      default:
        return _CustomizedGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 34,
      decoration: const BoxDecoration(
        color: _customizedCanvas,
        border: Border(left: BorderSide(color: _customizedPanelBorder)),
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
                  color: selected ? Colors.white : _customizedTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _customizedPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _customizedOuterBorder
                          : _customizedPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _customizedPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _customizedPanelBorder)
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
                        color: _customizedText,
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

class _CustomizedGraphTab extends StatelessWidget {
  final RecapCustomizedController controller;

  const _CustomizedGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.rows.toList(growable: false);

    final panels = [
      _CustomizedGraphPanel(
        label: 'Mw\n(ppg)',
        values: rows.map((row) => row.mw).toList(growable: false),
        fallbackMin: 5,
        fallbackMax: 6,
        decimals: 1,
      ),
      _CustomizedGraphPanel(
        label: 'Total\n(Kwd)',
        values: rows.map((row) => row.totalKwd).toList(growable: false),
        fallbackMin: 0,
        fallbackMax: 1,
        decimals: 1,
      ),
      _CustomizedGraphPanel(
        label: 'P/U Wt.\n(lbf)',
        values: rows.map((row) => row.puWt).toList(growable: false),
        fallbackMin: 0,
        fallbackMax: 1,
        decimals: 1,
      ),
      _CustomizedGraphPanel(
        label: 'RPM\n(rpm)',
        values: rows.map((row) => row.rpm).toList(growable: false),
        fallbackMin: 0,
        fallbackMax: 1,
        decimals: 1,
      ),
      _CustomizedGraphPanel(
        label: 'ROP\n(ft/hr)',
        values: rows.map((row) => row.rop).toList(growable: false),
        fallbackMin: 0,
        fallbackMax: 1,
        decimals: 1,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _customizedPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: Text(
                'Customized Graph',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _customizedText,
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
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                child: CustomPaint(
                  painter: _CustomizedGraphPainter(rows: rows, panels: panels),
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

class _CustomizedTableTab extends StatelessWidget {
  final RecapCustomizedController controller;

  const _CustomizedTableTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.rows.toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _customizedPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: Text(
                'Customized Graph',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _customizedText,
                ),
              ),
            ),
            Expanded(
              child: _CustomizedHistoryTable(
                rows: rows,
                emptyMessage: controller.emptyMessage.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomizedHistoryTable extends StatelessWidget {
  final List<RecapCustomizedHistoryRow> rows;
  final String emptyMessage;

  const _CustomizedHistoryTable({
    required this.rows,
    required this.emptyMessage,
  });

  static const _columns = [
    _CustomizedColumn(title: 'Day', width: 54),
    _CustomizedColumn(title: 'Report', width: 70),
    _CustomizedColumn(title: 'Date', width: 108),
    _CustomizedColumn(title: 'Mw', width: 86),
    _CustomizedColumn(title: 'Total (Kwd)', width: 110),
    _CustomizedColumn(title: 'P/U Wt.', width: 96),
    _CustomizedColumn(title: 'RPM', width: 86),
    _CustomizedColumn(title: 'ROP', width: 86),
  ];

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            emptyMessage.isNotEmpty
                ? emptyMessage
                : 'No customized graph history is available yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
        ),
      );
    }

    final baseTableWidth = _columns.fold<double>(
      0,
      (sum, column) => sum + column.width,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(
          baseTableWidth,
          (constraints.maxWidth - 16).clamp(0, double.infinity).toDouble(),
        );
        final scale =
            baseTableWidth <= 0 ? 1.0 : tableWidth / baseTableWidth;

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CustomizedTableRow(
                      cells: _columns
                          .map(
                            (column) => _CustomizedCellData(
                              text: column.title,
                              width: column.width * scale,
                              alignment: Alignment.center,
                              isHeader: true,
                            ),
                          )
                          .toList(growable: false),
                    ),
                    ...rows.map((row) => _buildRow(row, scale)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(RecapCustomizedHistoryRow row, double scale) {
    return _CustomizedTableRow(
      cells: [
        _CustomizedCellData(
          text: '${row.dayNumber}',
          width: _columns[0].width * scale,
          alignment: Alignment.center,
        ),
        _CustomizedCellData(
          text: row.reportLabel.isNotEmpty ? row.reportLabel : '-',
          width: _columns[1].width * scale,
          alignment: Alignment.centerLeft,
        ),
        _CustomizedCellData(
          text: row.reportDate.isNotEmpty ? row.reportDate : '-',
          width: _columns[2].width * scale,
          alignment: Alignment.centerLeft,
        ),
        _CustomizedCellData(
          text: _formatValue(row.mw, decimals: 2),
          width: _columns[3].width * scale,
          alignment: Alignment.centerRight,
        ),
        _CustomizedCellData(
          text: _formatValue(row.totalKwd, decimals: 2),
          width: _columns[4].width * scale,
          alignment: Alignment.centerRight,
        ),
        _CustomizedCellData(
          text: _formatValue(row.puWt, decimals: 2),
          width: _columns[5].width * scale,
          alignment: Alignment.centerRight,
        ),
        _CustomizedCellData(
          text: _formatValue(row.rpm, decimals: 2),
          width: _columns[6].width * scale,
          alignment: Alignment.centerRight,
        ),
        _CustomizedCellData(
          text: _formatValue(row.rop, decimals: 2),
          width: _columns[7].width * scale,
          alignment: Alignment.centerRight,
        ),
      ],
    );
  }
}

class _CustomizedGraphPainter extends CustomPainter {
  final List<RecapCustomizedHistoryRow> rows;
  final List<_CustomizedGraphPanel> panels;

  const _CustomizedGraphPainter({required this.rows, required this.panels});

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 66.0;
    const rightMargin = 18.0;
    const topMargin = 4.0;
    const bottomMargin = 30.0;
    const gap = 14.0;

    if (panels.isEmpty) return;

    final plotWidth = size.width - leftMargin - rightMargin;
    final plotHeight =
        size.height - topMargin - bottomMargin - gap * (panels.length - 1);
    final panelHeight = plotHeight / panels.length;
    final maxDay = math.max(
      5,
      rows.isEmpty
          ? 5
          : rows.map((row) => row.dayNumber).fold<int>(1, math.max),
    );

    for (int index = 0; index < panels.length; index++) {
      final panel = panels[index];
      final top = topMargin + index * (panelHeight + gap);
      final rect = Rect.fromLTWH(leftMargin, top, plotWidth, panelHeight);
      final bounds = _resolveBounds(panel);

      _drawPanelFrame(canvas, rect);
      _drawYScale(canvas, rect, bounds, panel.decimals);
      _drawVerticalLabel(canvas, rect, panel.label);
      _drawSeries(canvas, rect, panel.values, bounds, maxDay);

      if (index == panels.length - 1) {
        _drawDayScale(canvas, rect, maxDay);
      }
    }
  }

  void _drawPanelFrame(Canvas canvas, Rect rect) {
    final borderPaint = Paint()
      ..color = _customizedPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _customizedGrid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(rect, borderPaint);

    for (int step = 1; step < 5; step++) {
      final dy = rect.top + rect.height * step / 5;
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), gridPaint);
    }

    for (int step = 1; step < 4; step++) {
      final dx = rect.left + rect.width * step / 4;
      canvas.drawLine(Offset(dx, rect.top), Offset(dx, rect.bottom), gridPaint);
    }
  }

  void _drawYScale(
    Canvas canvas,
    Rect rect,
    _CustomizedBounds bounds,
    int decimals,
  ) {
    for (int step = 0; step <= 5; step++) {
      final ratio = step / 5;
      final value = bounds.max - (bounds.span * ratio);
      final dy = rect.top + rect.height * ratio;
      _paintText(
        canvas,
        _formatScaledValue(value, decimals),
        Offset(rect.left - 8, dy),
        const TextStyle(fontSize: 10, color: _customizedText),
        textAlign: TextAlign.right,
      );
    }
  }

  void _drawVerticalLabel(Canvas canvas, Rect rect, String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 11, color: _customizedText),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: rect.height);

    canvas.save();
    canvas.translate(rect.left - 42, rect.top + rect.height / 2);
    canvas.rotate(-math.pi / 2);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  void _drawSeries(
    Canvas canvas,
    Rect rect,
    List<double?> values,
    _CustomizedBounds bounds,
    int maxDay,
  ) {
    final linePaint = Paint()
      ..color = _customizedLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pointPaint = Paint()
      ..color = _customizedLine
      ..style = PaintingStyle.fill;

    Path? segment;
    Offset? onlyPoint;
    int pointCount = 0;

    final total = math.min(values.length, rows.length);
    for (int index = 0; index < total; index++) {
      final value = values[index];
      if (value == null || !value.isFinite) {
        if (segment != null && pointCount > 1) {
          canvas.drawPath(segment, linePaint);
        } else if (onlyPoint != null) {
          canvas.drawCircle(onlyPoint, 2.5, pointPaint);
        }
        segment = null;
        onlyPoint = null;
        pointCount = 0;
        continue;
      }

      final day = rows[index].dayNumber.toDouble();
      final x = rect.left + ((day - 1) / (maxDay - 1)) * rect.width;
      final y =
          rect.bottom -
          ((value - bounds.min) / bounds.span).clamp(0.0, 1.0) * rect.height;
      final point = Offset(x, y);

      if (segment == null) {
        segment = Path()..moveTo(point.dx, point.dy);
        onlyPoint = point;
        pointCount = 1;
      } else {
        segment.lineTo(point.dx, point.dy);
        onlyPoint = null;
        pointCount++;
      }
    }

    if (segment != null && pointCount > 1) {
      canvas.drawPath(segment, linePaint);
    } else if (onlyPoint != null) {
      canvas.drawCircle(onlyPoint, 2.5, pointPaint);
    }
  }

  void _drawDayScale(Canvas canvas, Rect rect, int maxDay) {
    for (int day = 1; day <= maxDay; day++) {
      final x = rect.left + ((day - 1) / (maxDay - 1)) * rect.width;
      _paintText(
        canvas,
        '$day',
        Offset(x, rect.bottom + 6),
        const TextStyle(fontSize: 10, color: _customizedText),
      );
    }

    _paintText(
      canvas,
      'Day',
      Offset(rect.center.dx, rect.bottom + 22),
      const TextStyle(fontSize: 11, color: _customizedText),
    );
  }

  _CustomizedBounds _resolveBounds(_CustomizedGraphPanel panel) {
    final values = panel.values
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();
    if (values.isEmpty) {
      return _CustomizedBounds(
        min: panel.fallbackMin,
        max: panel.fallbackMax > panel.fallbackMin
            ? panel.fallbackMax
            : panel.fallbackMin + 1,
      );
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    if ((maxValue - minValue).abs() < 0.0001) {
      final pad = minValue == 0 ? 1.0 : minValue.abs() * 0.08;
      return _CustomizedBounds(min: minValue - pad, max: maxValue + pad);
    }

    final pad = (maxValue - minValue) * 0.08;
    return _CustomizedBounds(min: minValue - pad, max: maxValue + pad);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    TextAlign textAlign = TextAlign.center,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    )..layout();

    double dx = anchor.dx - painter.width / 2;
    if (textAlign == TextAlign.right) {
      dx = anchor.dx - painter.width;
    } else if (textAlign == TextAlign.left) {
      dx = anchor.dx;
    }

    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CustomizedGraphPainter oldDelegate) {
    return oldDelegate.rows != rows || oldDelegate.panels != panels;
  }
}

class _CustomizedTableRow extends StatelessWidget {
  final List<_CustomizedCellData> cells;

  const _CustomizedTableRow({required this.cells});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: cells
            .map(
              (cell) => Container(
                width: cell.width,
                alignment: cell.alignment,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: cell.isHeader ? _customizedHeaderFill : Colors.white,
                  border: Border.all(color: _customizedPanelBorder),
                ),
                child: Text(
                  cell.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: cell.isHeader
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _customizedText,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _CustomizedMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _CustomizedMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _customizedPanelBorder),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _customizedText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomizedTabMeta {
  final String title;

  const _CustomizedTabMeta({required this.title});
}

class _CustomizedGraphPanel {
  final String label;
  final List<double?> values;
  final double fallbackMin;
  final double fallbackMax;
  final int decimals;

  const _CustomizedGraphPanel({
    required this.label,
    required this.values,
    required this.fallbackMin,
    required this.fallbackMax,
    required this.decimals,
  });
}

class _CustomizedBounds {
  final double min;
  final double max;

  const _CustomizedBounds({required this.min, required this.max});

  double get span => math.max(0.0001, max - min);
}

class _CustomizedColumn {
  final String title;
  final double width;

  const _CustomizedColumn({required this.title, required this.width});
}

class _CustomizedCellData {
  final String text;
  final double width;
  final Alignment alignment;
  final bool isHeader;

  const _CustomizedCellData({
    required this.text,
    required this.width,
    required this.alignment,
    this.isHeader = false,
  });
}

String _formatValue(double? value, {int decimals = 2}) {
  if (value == null) return '-';
  return value.toStringAsFixed(decimals);
}

String _formatScaledValue(double value, int decimals) {
  if (value.abs() >= 1000) {
    return value.toStringAsFixed(0);
  }
  if (value.abs() >= 100) {
    return value.toStringAsFixed(math.min(1, decimals));
  }
  return value.toStringAsFixed(decimals);
}
