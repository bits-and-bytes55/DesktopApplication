import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/bit/controller/recap_bit_controller.dart';

const Color _bitOuterBorder = Color(0xFF2F92E8);
const Color _bitCanvas = Color(0xFFF4F4F4);
const Color _bitPanelBorder = Color(0xFFC8C8C8);
const Color _bitHeaderFill = Color(0xFFF7F7F7);
const Color _bitText = Color(0xFF1C1C1C);
const Color _bitGrid = Color(0xFFD6D6D6);
const Color _bitLine = Color(0xFF84D0F4);
const Color _bitAccent = Color(0xFFF04BDF);
const Color _bitTabFill = Color(0xFFEAEAEA);

class RecapBitTabView extends StatefulWidget {
  const RecapBitTabView({super.key});

  @override
  State<RecapBitTabView> createState() => _RecapBitTabViewState();
}

class _RecapBitTabViewState extends State<RecapBitTabView> {
  int _selectedTab = 0;

  RecapBitController get _controller => Get.isRegistered<RecapBitController>()
      ? Get.find<RecapBitController>()
      : Get.put(RecapBitController());

  static const _tabs = [
    _BitTabMeta(title: 'Graph'),
    _BitTabMeta(title: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _bitCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _bitOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapBitController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _BitMessageState(
        title: 'Bit',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty && controller.emptyMessage.value.isNotEmpty) {
      return _BitMessageState(
        title: 'Bit',
        message: controller.emptyMessage.value,
      );
    }

    switch (_selectedTab) {
      case 0:
        return _BitGraphTab(controller: controller);
      case 1:
        return _BitTableTab(controller: controller);
      default:
        return _BitGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _bitCanvas,
        border: Border(left: BorderSide(color: _bitPanelBorder)),
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
                  color: selected ? Colors.white : _bitTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _bitPanelBorder),
                    left: BorderSide(
                      color: selected ? _bitOuterBorder : _bitPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _bitPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _bitPanelBorder)
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
                        color: _bitText,
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

class _BitGraphTab extends StatelessWidget {
  final RecapBitController controller;

  const _BitGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.rows.toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _bitPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: Text(
                'Bit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _bitText,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: CustomPaint(
                  painter: _BitGraphPainter(rows: rows),
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

class _BitTableTab extends StatelessWidget {
  final RecapBitController controller;

  const _BitTableTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.rows.toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _bitPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Bit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _bitText,
                ),
              ),
            ),
            Expanded(child: _BitHistoryTable(rows: rows)),
          ],
        ),
      ),
    );
  }
}

class _BitHistoryTable extends StatefulWidget {
  final List<RecapBitHistoryRow> rows;

  const _BitHistoryTable({required this.rows});

  @override
  State<_BitHistoryTable> createState() => _BitHistoryTableState();
}

class _BitHistoryTableState extends State<_BitHistoryTable> {
  final ScrollController _headerController = ScrollController();
  final ScrollController _bodyController = ScrollController();
  bool _syncing = false;

  static const double _rowHeight = 31;
  static const double _dayWidth = 48;
  static const double _reportWidth = 66;
  static const double _dateWidth = 100;
  static const double _mfrWidth = 140;
  static const double _typeWidth = 130;
  static const double _bitNoWidth = 58;
  static const double _sizeInWidth = 80;
  static const double _sizeMmWidth = 84;
  static const double _tfaWidth = 76;
  static const double _depthInWidth = 90;
  static const double _depthWidth = 82;

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
    const baseTotalWidth =
        _dayWidth +
        _reportWidth +
        _dateWidth +
        _mfrWidth +
        _typeWidth +
        _bitNoWidth +
        _sizeInWidth +
        _sizeMmWidth +
        _tfaWidth +
        _depthInWidth +
        _depthWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
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
                  children: [
                    _BitHeaderCell('Day', _dayWidth * scale),
                    _BitHeaderCell('Rpt #', _reportWidth * scale),
                    _BitHeaderCell('Date', _dateWidth * scale),
                    _BitHeaderCell('Mfr', _mfrWidth * scale),
                    _BitHeaderCell('Type', _typeWidth * scale),
                    _BitHeaderCell('Bit #', _bitNoWidth * scale),
                    _BitHeaderCell('Size (in)', _sizeInWidth * scale),
                    _BitHeaderCell('Size (mm)', _sizeMmWidth * scale),
                    _BitHeaderCell('TFA', _tfaWidth * scale),
                    _BitHeaderCell('Depth in', _depthInWidth * scale),
                    _BitHeaderCell('Depth', _depthWidth * scale),
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
                width: totalWidth,
                child: ListView.builder(
                  itemCount: widget.rows.length,
                  itemBuilder: (context, index) {
                    final row = widget.rows[index];
                    return SizedBox(
                      height: _rowHeight,
                      child: Row(
                        children: [
                          _BitDataCell(
                            '${row.dayNumber}',
                            _dayWidth * scale,
                            index,
                          ),
                          _BitDataCell(
                            row.reportLabel,
                            _reportWidth * scale,
                            index,
                          ),
                          _BitDataCell(
                            _formatDate(row.reportDate, row.createdAt),
                            _dateWidth * scale,
                            index,
                          ),
                          _BitDataCell(
                            row.manufacturer,
                            _mfrWidth * scale,
                            index,
                          ),
                          _BitDataCell(row.bitType, _typeWidth * scale, index),
                          _BitDataCell(
                            _formatNumber(
                              row.bitNumber,
                              digits: 0,
                              zeroAsDash: true,
                            ),
                            _bitNoWidth * scale,
                            index,
                            alignRight: true,
                          ),
                          _BitDataCell(
                            row.bitSizeText,
                            _sizeInWidth * scale,
                            index,
                          ),
                          _BitDataCell(
                            _formatNumber(row.bitSizeMm, zeroAsDash: true),
                            _sizeMmWidth * scale,
                            index,
                            alignRight: true,
                          ),
                          _BitDataCell(
                            _formatNumber(row.tfa, zeroAsDash: true, digits: 3),
                            _tfaWidth * scale,
                            index,
                            alignRight: true,
                          ),
                          _BitDataCell(
                            _formatNumber(row.depthInFt, zeroAsDash: true),
                            _depthInWidth * scale,
                            index,
                            alignRight: true,
                          ),
                          _BitDataCell(
                            _formatNumber(row.depthFt, zeroAsDash: true),
                            _depthWidth * scale,
                            index,
                            alignRight: true,
                          ),
                        ],
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

class _BitGraphPainter extends CustomPainter {
  final List<RecapBitHistoryRow> rows;

  const _BitGraphPainter({required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 62.0;
    const topPad = 10.0;
    const rightPad = 10.0;
    const bottomPad = 36.0;
    const gap = 10.0;
    const panelCount = 5;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final borderPaint = Paint()
      ..color = _bitPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _bitGrid
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = _bitLine
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()
      ..color = _bitLine
      ..style = PaintingStyle.fill;

    final panelHeight =
        (size.height - topPad - bottomPad - (gap * (panelCount - 1))) /
        panelCount;
    final plotWidth = size.width - leftPad - rightPad;

    final metrics = [
      _BitMetric(
        label: 'Bit\n#',
        values: rows.map((row) => row.bitNumber).toList(growable: false),
        scaleMax: _niceMax(
          rows
              .map((row) => row.bitNumber)
              .whereType<double>()
              .fold<double>(0, (max, value) => math.max(max, value)),
        ),
      ),
      _BitMetric(
        label: 'Size\n(mm)',
        values: rows.map((row) => row.bitSizeMm).toList(growable: false),
        scaleMax: _niceMax(
          rows
              .map((row) => row.bitSizeMm)
              .whereType<double>()
              .fold<double>(0, (max, value) => math.max(max, value)),
        ),
      ),
      _BitMetric(
        label: 'TFA\n(in2)',
        values: rows.map((row) => row.tfa).toList(growable: false),
        scaleMax: _niceMax(
          rows
              .map((row) => row.tfa)
              .whereType<double>()
              .fold<double>(0, (max, value) => math.max(max, value)),
        ),
      ),
      _BitMetric(
        label: 'Depth in\n(ft)',
        values: rows.map((row) => row.depthInFt).toList(growable: false),
        scaleMax: _niceMax(
          rows
              .map((row) => row.depthInFt)
              .whereType<double>()
              .fold<double>(0, (max, value) => math.max(max, value)),
        ),
      ),
      _BitMetric(
        label: 'Depth\n(ft)',
        values: rows.map((row) => row.depthFt).toList(growable: false),
        scaleMax: _niceMax(
          rows
              .map((row) => row.depthFt)
              .whereType<double>()
              .fold<double>(0, (max, value) => math.max(max, value)),
        ),
      ),
    ];

    for (int panelIndex = 0; panelIndex < metrics.length; panelIndex++) {
      final metric = metrics[panelIndex];
      final top = topPad + (panelIndex * (panelHeight + gap));
      final rect = Rect.fromLTWH(leftPad, top, plotWidth, panelHeight);

      canvas.drawRect(rect, borderPaint);

      for (int tick = 1; tick < 5; tick++) {
        final y = rect.bottom - (rect.height * tick / 4);
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      }

      final dayCount = rows.isEmpty ? 4 : rows.length;
      for (int day = 1; day < dayCount; day++) {
        final x = rect.left + (rect.width * day / math.max(dayCount - 1, 1));
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
      }

      for (int tick = 0; tick <= 4; tick++) {
        final value = metric.scaleMax * (tick / 4);
        final y = rect.bottom - (rect.height * tick / 4);
        _paintText(
          canvas,
          textPainter,
          _formatAxis(value),
          const TextStyle(fontSize: 10, color: _bitText),
          Offset(8, y - 8),
          width: 40,
        );
      }

      _paintVerticalText(
        canvas,
        textPainter,
        metric.label,
        const TextStyle(fontSize: 11, color: _bitText),
        Offset(18, rect.center.dy),
      );

      final points = <Offset>[];
      for (int index = 0; index < metric.values.length; index++) {
        final value = metric.values[index];
        if (value == null || metric.scaleMax <= 0) {
          points.add(const Offset(double.nan, double.nan));
          continue;
        }

        final x = rows.length <= 1
            ? rect.left + (rect.width / 2)
            : rect.left + (rect.width * index / (rows.length - 1));
        final y = rect.bottom - (rect.height * (value / metric.scaleMax));
        points.add(Offset(x, y));
      }

      Path? activePath;
      Offset? lastValidPoint;
      for (final point in points) {
        if (point.dx.isNaN || point.dy.isNaN) {
          if (activePath != null) {
            canvas.drawPath(activePath, linePaint);
            activePath = null;
          }
          continue;
        }

        if (activePath == null) {
          activePath = Path()..moveTo(point.dx, point.dy);
        } else {
          activePath.lineTo(point.dx, point.dy);
        }
        lastValidPoint = point;
      }
      if (activePath != null) {
        canvas.drawPath(activePath, linePaint);
      }

      for (final point in points) {
        if (point.dx.isNaN || point.dy.isNaN) continue;
        canvas.drawCircle(point, 2.8, pointPaint);
      }

      if (panelIndex == 3 && lastValidPoint != null) {
        canvas.drawLine(
          Offset(lastValidPoint.dx, rect.top),
          Offset(lastValidPoint.dx, rect.bottom),
          Paint()
            ..color = _bitAccent
            ..strokeWidth = 1.2,
        );

        final lastIndex = points.lastIndexWhere((point) => !point.dx.isNaN);
        if (lastIndex != -1) {
          final value = metric.values[lastIndex];
          final bubbleRect = Rect.fromLTWH(
            math.min(rect.right - 118, lastValidPoint.dx + 12),
            math.max(rect.top + 6, lastValidPoint.dy - 18),
            100,
            32,
          );
          final bubbleRRect = RRect.fromRectAndRadius(
            bubbleRect,
            const Radius.circular(4),
          );
          canvas.drawRRect(bubbleRRect, Paint()..color = Colors.white);
          canvas.drawRRect(bubbleRRect, borderPaint);
          canvas.drawCircle(
            Offset(bubbleRect.left + 12, bubbleRect.center.dy),
            2.4,
            pointPaint,
          );
          _paintText(
            canvas,
            textPainter,
            '${rows[lastIndex].dayNumber} : ${_formatNumber(value, zeroAsDash: false)}',
            const TextStyle(fontSize: 10.5, color: _bitText),
            Offset(bubbleRect.left + 20, bubbleRect.top + 8),
            width: 74,
          );
        }
      }

      if (panelIndex == metrics.length - 1) {
        for (int index = 0; index < rows.length; index++) {
          final x = rows.length <= 1
              ? rect.left + (rect.width / 2)
              : rect.left + (rect.width * index / (rows.length - 1));
          _paintText(
            canvas,
            textPainter,
            '${rows[index].dayNumber}',
            const TextStyle(fontSize: 11, color: _bitText),
            Offset(x - 6, rect.bottom + 6),
            width: 18,
          );
        }

        _paintCenteredText(
          canvas,
          textPainter,
          'Day',
          const TextStyle(fontSize: 12, color: _bitText),
          Rect.fromLTWH(rect.left, size.height - 22, rect.width, 18),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BitGraphPainter oldDelegate) {
    return oldDelegate.rows != rows;
  }
}

class _BitMetric {
  final String label;
  final List<double?> values;
  final double scaleMax;

  const _BitMetric({
    required this.label,
    required this.values,
    required this.scaleMax,
  });
}

class _BitHeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _BitHeaderCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _bitHeaderFill,
        border: Border.all(color: _bitPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _bitText,
        ),
      ),
    );
  }
}

class _BitDataCell extends StatelessWidget {
  final String text;
  final double width;
  final int rowIndex;
  final bool alignRight;

  const _BitDataCell(
    this.text,
    this.width,
    this.rowIndex, {
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: rowIndex.isOdd ? const Color(0xFFF8F8F8) : Colors.white,
        border: Border.all(color: _bitPanelBorder, width: 0.8),
      ),
      child: Text(
        text.trim().isEmpty ? '-' : text.trim(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _bitText),
      ),
    );
  }
}

class _BitMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _BitMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _bitPanelBorder),
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
                  color: _bitText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _bitText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BitTabMeta {
  final String title;

  const _BitTabMeta({required this.title});
}

double _niceMax(double rawMax) {
  if (rawMax <= 0) return 1;
  if (rawMax <= 1) return 1;
  if (rawMax <= 10) return rawMax.ceilToDouble();
  if (rawMax <= 100) return (rawMax / 10).ceilToDouble() * 10;
  if (rawMax <= 1000) return (rawMax / 100).ceilToDouble() * 100;
  return (rawMax / 1000).ceilToDouble() * 1000;
}

String _formatAxis(double value) {
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

String _formatDate(String raw, String createdAt) {
  final source = raw.trim().isNotEmpty ? raw.trim() : createdAt.trim();
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source.isEmpty ? '-' : source;
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatNumber(double? value, {bool zeroAsDash = false, int digits = 2}) {
  if (value == null) return zeroAsDash ? '-' : '0';
  if (zeroAsDash && value.abs() < 0.0001) return '-';
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(digits)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

void _paintText(
  Canvas canvas,
  TextPainter textPainter,
  String text,
  TextStyle style,
  Offset offset, {
  required double width,
}) {
  textPainter.text = TextSpan(text: text, style: style);
  textPainter.layout(maxWidth: width);
  textPainter.paint(canvas, offset);
}

void _paintCenteredText(
  Canvas canvas,
  TextPainter textPainter,
  String text,
  TextStyle style,
  Rect rect,
) {
  textPainter.text = TextSpan(text: text, style: style);
  textPainter.layout(maxWidth: rect.width);
  final dx = rect.left + ((rect.width - textPainter.width) / 2);
  final dy = rect.top + ((rect.height - textPainter.height) / 2);
  textPainter.paint(canvas, Offset(dx, dy));
}

void _paintVerticalText(
  Canvas canvas,
  TextPainter textPainter,
  String text,
  TextStyle style,
  Offset center,
) {
  textPainter.text = TextSpan(text: text, style: style);
  textPainter.layout();
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(-math.pi / 2);
  textPainter.paint(
    canvas,
    Offset(-(textPainter.width / 2), -(textPainter.height / 2)),
  );
  canvas.restore();
}
