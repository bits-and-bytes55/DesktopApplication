import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/time_distribution/controller/recap_time_distribution_controller.dart';

const Color _timeOuterBorder = Color(0xFF2F92E8);
const Color _timeCanvas = Color(0xFFF4F4F4);
const Color _timePanelBorder = Color(0xFFC8C8C8);
const Color _timeHeaderFill = Color(0xFFF7F7F7);
const Color _timeText = Color(0xFF1C1C1C);
const Color _timeGrid = Color(0xFFD6D6D6);
const Color _timeTabFill = Color(0xFFEAEAEA);

class RecapTimeDistributionTabView extends StatefulWidget {
  const RecapTimeDistributionTabView({super.key});

  @override
  State<RecapTimeDistributionTabView> createState() =>
      _RecapTimeDistributionTabViewState();
}

class _RecapTimeDistributionTabViewState
    extends State<RecapTimeDistributionTabView> {
  int _selectedTab = 0;

  RecapTimeDistributionController get _controller =>
      Get.isRegistered<RecapTimeDistributionController>()
      ? Get.find<RecapTimeDistributionController>()
      : Get.put(RecapTimeDistributionController());

  static const _tabs = [
    _TimeTabMeta(title: 'Graph'),
    _TimeTabMeta(title: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _timeCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _timeOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapTimeDistributionController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _TimeMessageState(
        title: 'Time Distribution',
        message: controller.errorMessage.value,
      );
    }

    switch (_selectedTab) {
      case 0:
        return _TimeGraphTab(controller: controller);
      case 1:
        if (controller.rows.isEmpty || controller.activities.isEmpty) {
          return _TimeMessageState(
            title: 'Time Distribution',
            message: controller.emptyMessage.value.isNotEmpty
                ? controller.emptyMessage.value
                : 'No live time-distribution history is available for the selected well.',
          );
        }
        return _TimeTableTab(controller: controller);
      default:
        return _TimeGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _timeCanvas,
        border: Border(left: BorderSide(color: _timePanelBorder)),
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
                  color: selected ? Colors.white : _timeTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _timePanelBorder),
                    left: BorderSide(
                      color: selected ? _timeOuterBorder : _timePanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _timePanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _timePanelBorder)
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
                        color: _timeText,
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

class _TimeGraphTab extends StatelessWidget {
  final RecapTimeDistributionController controller;

  const _TimeGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.rows.toList(growable: false);
    final activities = controller.activities.toList(growable: false);
    final percentBars = _buildPercentBars(activities);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _timePanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: Text(
                'Time Distribution',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _timeText,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 60,
                      child: _TimeGraphCanvasFrame(
                        child: CustomPaint(
                          painter: _TimeHoursGraphPainter(
                            rows: rows,
                            activities: activities,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 40,
                      child: _TimeGraphCanvasFrame(
                        child: CustomPaint(
                          painter: _TimePercentGraphPainter(
                            bars: percentBars,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeTableTab extends StatelessWidget {
  final RecapTimeDistributionController controller;

  const _TimeTableTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _timePanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Time Distribution Table',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _timeText,
                ),
              ),
            ),
            Expanded(
              child: _LegacyTimeDistributionTable(
                rows: controller.rows.toList(growable: false),
                activities: controller.activities.toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeGraphCanvasFrame extends StatelessWidget {
  final Widget child;

  const _TimeGraphCanvasFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _timePanelBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: child,
      ),
    );
  }
}

class _TimeDistributionPercentBar {
  final String label;
  final double percent;
  final Color color;

  const _TimeDistributionPercentBar({
    required this.label,
    required this.percent,
    required this.color,
  });
}

List<_TimeDistributionPercentBar> _buildPercentBars(
  List<TimeDistributionActivityMeta> activities,
) {
  if (activities.isEmpty) return const <_TimeDistributionPercentBar>[];

  final totalHours = activities.fold<double>(
    0,
    (sum, item) => sum + item.totalHours,
  );
  if (totalHours <= 0) return const <_TimeDistributionPercentBar>[];

  final sorted = [...activities]
    ..sort((left, right) {
      final byHours = right.totalHours.compareTo(left.totalHours);
      if (byHours != 0) return byHours;
      return left.activity.toLowerCase().compareTo(
        right.activity.toLowerCase(),
      );
    });

  const visibleCount = 7;
  final bars = <_TimeDistributionPercentBar>[];
  for (final item in sorted.take(visibleCount)) {
    bars.add(
      _TimeDistributionPercentBar(
        label: item.activity,
        percent: (item.totalHours / totalHours) * 100,
        color: item.color,
      ),
    );
  }

  if (sorted.length > visibleCount) {
    final otherHours = sorted
        .skip(visibleCount)
        .fold<double>(0, (sum, item) => sum + item.totalHours);
    if (otherHours > 0) {
      bars.add(
        _TimeDistributionPercentBar(
          label: 'Others',
          percent: (otherHours / totalHours) * 100,
          color: const Color(0xFFC3CBD3),
        ),
      );
    }
  }

  return bars;
}

class _LegacyTimeDistributionTable extends StatefulWidget {
  final List<TimeDistributionHistoryRow> rows;
  final List<TimeDistributionActivityMeta> activities;

  const _LegacyTimeDistributionTable({
    required this.rows,
    required this.activities,
  });

  @override
  State<_LegacyTimeDistributionTable> createState() =>
      _LegacyTimeDistributionTableState();
}

class _LegacyTimeDistributionTableState
    extends State<_LegacyTimeDistributionTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  static const double _rowHeight = 31;
  static const double _indexWidth = 48;
  static const double _dateWidth = 102;
  static const double _reportWidth = 64;
  static const double _mdWidth = 82;
  static const double _totalHoursWidth = 78;
  static const double _totalPercentWidth = 70;
  static const double _columnWidth = 134;

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
    final dynamicWidth = widget.activities.length * _columnWidth;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Container(
            height: _rowHeight,
            color: _timeHeaderFill,
            child: Row(
              children: [
                _headerCell('No', _indexWidth),
                _headerCell('Date', _dateWidth),
                _headerCell('Rpt #', _reportWidth),
                _headerCell('MD (ft)', _mdWidth),
                _headerCell('Total Hr', _totalHoursWidth),
                _headerCell('% Day', _totalPercentWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dynamicWidth,
                      child: Row(
                        children: widget.activities
                            .map((activity) => _activityHeaderCell(activity))
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
                  width: _indexWidth +
                      _dateWidth +
                      _reportWidth +
                      _mdWidth +
                      _totalHoursWidth +
                      _totalPercentWidth,
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
                            _dataCell(row.reportLabel, _reportWidth, index),
                            _dataCell(_formatNumber(row.md), _mdWidth, index),
                            _dataCell(
                              _formatNumber(row.totalHours),
                              _totalHoursWidth,
                              index,
                              alignRight: true,
                            ),
                            _dataCell(
                              _formatNumber(row.totalPercent),
                              _totalPercentWidth,
                              index,
                              alignRight: true,
                            ),
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
                              children: widget.activities.map((activity) {
                                final hours = row.entryFor(activity.key)?.hours;
                                return _dataCell(
                                  _formatNumber(hours, zeroAsDash: true),
                                  _columnWidth,
                                  index,
                                  alignRight: true,
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
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _timeHeaderFill,
        border: Border.all(color: _timePanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _timeText,
        ),
      ),
    );
  }

  Widget _activityHeaderCell(TimeDistributionActivityMeta activity) {
    return Container(
      width: _columnWidth,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _timeHeaderFill,
        border: Border.all(color: _timePanelBorder, width: 0.8),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, color: activity.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              activity.activity,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _timeText,
              ),
            ),
          ),
        ],
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
        border: Border.all(color: _timePanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _timeText),
      ),
    );
  }
}

class _TimeHoursGraphPainter extends CustomPainter {
  final List<TimeDistributionHistoryRow> rows;
  final List<TimeDistributionActivityMeta> activities;

  const _TimeHoursGraphPainter({
    required this.rows,
    required this.activities,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 46.0;
    const topPad = 12.0;
    const rightPad = 10.0;
    const bottomPad = 38.0;
    const axisLabelGap = 24.0;
    const maxHours = 24.0;

    final plotRect = Rect.fromLTWH(
      leftPad,
      topPad,
      math.max(0, size.width - leftPad - rightPad),
      math.max(0, size.height - topPad - bottomPad),
    );

    final borderPaint = Paint()
      ..color = _timePanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _timeGrid
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    canvas.drawRect(plotRect, borderPaint);

    for (int tick = 0; tick <= 4; tick++) {
      final y = plotRect.bottom - (plotRect.height * tick / 4);
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
    }

    final verticalDivisions = rows.isEmpty ? 4 : math.min(math.max(rows.length, 1), 10);
    for (int index = 1; index < verticalDivisions; index++) {
      final x = plotRect.left + (plotRect.width * index / verticalDivisions);
      canvas.drawLine(
        Offset(x, plotRect.top),
        Offset(x, plotRect.bottom),
        gridPaint,
      );
    }

    _paintText(
      canvas,
      textPainter,
      '24',
      const TextStyle(fontSize: 11, color: _timeText),
      Offset(10, plotRect.top - 8),
      width: 24,
    );
    _paintText(
      canvas,
      textPainter,
      '0',
      const TextStyle(fontSize: 11, color: _timeText),
      Offset(14, plotRect.bottom - 9),
      width: 16,
    );

    if (rows.isNotEmpty) {
      final step = plotRect.width / rows.length;
      final barWidth = math.min(30.0, math.max(12.0, step * 0.38));

      for (int index = 0; index < rows.length; index++) {
        final row = rows[index];
        final centerX = plotRect.left + (step * index) + (step / 2);
        double currentBottom = plotRect.bottom;

        for (final activity in activities) {
          final hours = row.entryFor(activity.key)?.hours ?? 0;
          if (hours <= 0) continue;
          final normalizedHours = row.totalHours > maxHours && row.totalHours > 0
              ? (hours / row.totalHours) * maxHours
              : hours;
          final height = plotRect.height * (normalizedHours / maxHours);
          if (height <= 0) continue;

          final rect = Rect.fromLTWH(
            centerX - (barWidth / 2),
            currentBottom - height,
            barWidth,
            height,
          );

          canvas.drawRect(
            rect,
            Paint()
              ..color = activity.color
              ..style = PaintingStyle.fill,
          );
          canvas.drawRect(rect, borderPaint);
          currentBottom -= height;
        }

        final label = int.tryParse(row.reportLabel.trim()) != null
            ? row.reportLabel.trim()
            : '${index + 1}';
        _paintText(
          canvas,
          textPainter,
          label,
          const TextStyle(fontSize: 11, color: _timeText),
          Offset(centerX - 10, plotRect.bottom + 6),
          width: 20,
        );
      }
    }

    _paintCenteredText(
      canvas,
      textPainter,
      'Day',
      const TextStyle(fontSize: 12, color: _timeText),
      Rect.fromLTWH(
        plotRect.left,
        size.height - 24,
        plotRect.width,
        18,
      ),
    );
    _paintVerticalText(
      canvas,
      textPainter,
      '(hr)',
      const TextStyle(fontSize: 11, color: _timeText),
      Offset(12, plotRect.top + (plotRect.height / 2) + axisLabelGap),
    );
  }

  @override
  bool shouldRepaint(covariant _TimeHoursGraphPainter oldDelegate) {
    return oldDelegate.rows != rows || oldDelegate.activities != activities;
  }
}

class _TimePercentGraphPainter extends CustomPainter {
  final List<_TimeDistributionPercentBar> bars;

  const _TimePercentGraphPainter({required this.bars});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 10.0;
    const topPad = 12.0;
    const rightPad = 8.0;
    const bottomPad = 38.0;

    final plotRect = Rect.fromLTWH(
      leftPad,
      topPad,
      math.max(0, size.width - leftPad - rightPad),
      math.max(0, size.height - topPad - bottomPad),
    );

    final borderPaint = Paint()
      ..color = _timePanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _timeGrid
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    canvas.drawRect(plotRect, borderPaint);

    final maxPercent = bars.isEmpty
        ? 10.0
        : math.max(
            10.0,
            (bars
                        .map((item) => item.percent)
                        .fold<double>(0, (max, value) => math.max(max, value)) /
                    10)
                .ceil() *
                10,
          );

    for (int tick = 0; tick <= 5; tick++) {
      final x = plotRect.left + (plotRect.width * tick / 5);
      canvas.drawLine(
        Offset(x, plotRect.top),
        Offset(x, plotRect.bottom),
        gridPaint,
      );

      final labelValue = (maxPercent * tick / 5).round();
      _paintText(
        canvas,
        textPainter,
        '$labelValue',
        const TextStyle(fontSize: 11, color: _timeText),
        Offset(x - 10, plotRect.bottom + 6),
        width: 24,
      );
    }

    if (bars.isNotEmpty) {
      final rowHeight = plotRect.height / bars.length;
      final barHeight = math.min(24.0, math.max(16.0, rowHeight * 0.48));

      for (int index = 0; index < bars.length; index++) {
        final bar = bars[index];
        final centerY = plotRect.top + (rowHeight * index) + (rowHeight / 2);
        final width = plotRect.width * (bar.percent / maxPercent);
        final rect = Rect.fromLTWH(
          plotRect.left,
          centerY - (barHeight / 2),
          width,
          barHeight,
        );

        canvas.drawRect(
          rect,
          Paint()
            ..color = bar.color
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(rect, borderPaint);

        final textColor = width > 110 ? Colors.white : _timeText;
        final textX = width > 110 ? rect.left + 6 : rect.left + width + 6;
        _paintText(
          canvas,
          textPainter,
          '${bar.label}, ${_formatNumber(bar.percent)}%',
          TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          Offset(textX, centerY - 8),
          width: math.max(60, plotRect.right - textX - 4),
        );
      }
    }

    _paintCenteredText(
      canvas,
      textPainter,
      '(%)',
      const TextStyle(fontSize: 12, color: _timeText),
      Rect.fromLTWH(
        plotRect.left,
        size.height - 24,
        plotRect.width,
        18,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _TimePercentGraphPainter oldDelegate) {
    return oldDelegate.bars != bars;
  }
}

class _TimeMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _TimeMessageState({
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
          border: Border.all(color: _timePanelBorder),
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
                  color: _timeText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _timeText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeTabMeta {
  final String title;

  const _TimeTabMeta({required this.title});
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
