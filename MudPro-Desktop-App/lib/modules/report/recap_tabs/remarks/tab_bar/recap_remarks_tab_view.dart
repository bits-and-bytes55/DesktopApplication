import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/remarks/controller/recap_remarks_controller.dart';

const Color _remarksOuterBorder = Color(0xFFB8D0EA);
const Color _remarksCanvas = Color(0xFFF4F6FA);
const Color _remarksPanelBorder = Color(0xFFB8D0EA);
const Color _remarksHeaderFill = Color(0xFFEAF3FC);
const Color _remarksText = Color(0xFF1C1C1C);
const Color _remarksGrid = Color(0xFFCFE0F2);
const Color _remarksTabFill = Color(0xFFEAF3FC);
const Color _remarksBar = Color(0xFFD3D3D3);
const Color _remarksSelectedRow = Color(0xFFEAF4FF);

class RecapRemarksTabView extends StatefulWidget {
  const RecapRemarksTabView({super.key});

  @override
  State<RecapRemarksTabView> createState() => _RecapRemarksTabViewState();
}

class _RecapRemarksTabViewState extends State<RecapRemarksTabView> {
  int _selectedTab = 0;

  RecapRemarksController get _controller =>
      Get.isRegistered<RecapRemarksController>()
      ? Get.find<RecapRemarksController>()
      : Get.put(RecapRemarksController());

  static const _tabs = [
    _RemarksTabMeta(title: 'Graph'),
    _RemarksTabMeta(title: 'Table'),
    _RemarksTabMeta(title: 'Keywords - Manual'),
    _RemarksTabMeta(title: 'Keywords - Automatic'),
    _RemarksTabMeta(title: 'Keywords - NLP'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _remarksCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _remarksOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapRemarksController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _RemarksMessageState(
        title: 'Remarks',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty) {
      return _RemarksMessageState(
        title: 'Remarks',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live remarks history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _RemarksGraphTab(controller: controller);
      case 1:
        return _RemarksTableTab(controller: controller);
      case 2:
        return _RemarksKeywordTab(
          title: 'Keywords - Manual',
          rows: controller.manualKeywords.toList(growable: false),
        );
      case 3:
        return _RemarksKeywordTab(
          title: 'Keywords - Automatic',
          rows: controller.automaticKeywords.toList(growable: false),
        );
      case 4:
        return _RemarksKeywordTab(
          title: 'Keywords - NLP',
          rows: controller.nlpKeywords.toList(growable: false),
        );
      default:
        return _RemarksGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 36,
      decoration: const BoxDecoration(
        color: _remarksCanvas,
        border: Border(left: BorderSide(color: _remarksPanelBorder)),
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
                  color: selected ? Colors.white : _remarksTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _remarksPanelBorder),
                    left: BorderSide(
                      color: selected ? _remarksOuterBorder : _remarksPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _remarksPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _remarksPanelBorder)
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
                        color: _remarksText,
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

class _RemarksGraphTab extends StatelessWidget {
  final RecapRemarksController controller;

  const _RemarksGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rows = controller.rows.toList(growable: false);
    final sections = [
      _RemarksMetricSection(
        label: 'Recommended Tour\nTreatment',
        values: rows
            .map((row) => row.recommendedWordCount.toDouble())
            .toList(growable: false),
      ),
      _RemarksMetricSection(
        label: 'Remarks',
        values: rows
            .map((row) => row.remarksWordCount.toDouble())
            .toList(growable: false),
      ),
      _RemarksMetricSection(
        label: 'Recap Remarks',
        values: rows
            .map((row) => row.recapWordCount.toDouble())
            .toList(growable: false),
      ),
      _RemarksMetricSection(
        label: 'Internal Notes',
        values: rows
            .map((row) => row.internalWordCount.toDouble())
            .toList(growable: false),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _remarksPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: Text(
                'Number of Words in Remarks',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _remarksText,
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
                  painter: _LegacyRemarksGraphPainter(
                    sections: sections,
                    slotCount: math.max(5, rows.length),
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

class _RemarksTableTab extends StatelessWidget {
  final RecapRemarksController controller;

  const _RemarksTableTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _remarksPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Remarks Table',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _remarksText,
                ),
              ),
            ),
            Expanded(
              child: _LegacyRemarksHistoryTable(
                rows: controller.rows.toList(growable: false),
                selectedReportId: controller.selectedReportId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemarksKeywordTab extends StatelessWidget {
  final String title;
  final List<RemarksKeywordRow> rows;

  const _RemarksKeywordTab({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _remarksPanelBorder),
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
                  color: _remarksText,
                ),
              ),
            ),
            Expanded(child: _LegacyRemarksKeywordTable(rows: rows)),
          ],
        ),
      ),
    );
  }
}

class _LegacyRemarksHistoryTable extends StatelessWidget {
  final List<RemarksHistoryRow> rows;
  final String selectedReportId;

  const _LegacyRemarksHistoryTable({
    required this.rows,
    required this.selectedReportId,
  });

  static const double _rowHeight = 31;
  static const double _noWidth = 48;
  static const double _dateWidth = 104;
  static const double _reportWidth = 60;
  static const double _metricWidth = 76;
  static const double _totalWidth = 78;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Container(
            height: _rowHeight,
            color: _remarksHeaderFill,
            child: const Row(
              children: [
                _RemarksHeaderCell('No', width: _noWidth),
                _RemarksHeaderCell('Date', width: _dateWidth),
                _RemarksHeaderCell('Rpt #', width: _reportWidth),
                _RemarksHeaderCell('Rec. Tour', width: _metricWidth),
                _RemarksHeaderCell('Remarks', width: _metricWidth),
                _RemarksHeaderCell('Recap', width: _metricWidth),
                _RemarksHeaderCell('Internal', width: _metricWidth),
                _RemarksHeaderCell('Total', width: _totalWidth),
                _RemarksHeaderCell('Preview'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final selected = row.reportId == selectedReportId;
                return Container(
                  height: _rowHeight,
                  color: selected
                      ? _remarksSelectedRow
                      : index.isOdd
                          ? const Color(0xFFF8F8F8)
                          : Colors.white,
                  child: Row(
                    children: [
                      _RemarksDataCell('${index + 1}', width: _noWidth),
                      _RemarksDataCell(
                        _formatDate(row.reportDate, row.createdAt),
                        width: _dateWidth,
                      ),
                      _RemarksDataCell(row.reportLabel, width: _reportWidth),
                      _RemarksDataCell(
                        '${row.recommendedWordCount}',
                        width: _metricWidth,
                        alignRight: true,
                      ),
                      _RemarksDataCell(
                        '${row.remarksWordCount}',
                        width: _metricWidth,
                        alignRight: true,
                      ),
                      _RemarksDataCell(
                        '${row.recapWordCount}',
                        width: _metricWidth,
                        alignRight: true,
                      ),
                      _RemarksDataCell(
                        '${row.internalWordCount}',
                        width: _metricWidth,
                        alignRight: true,
                      ),
                      _RemarksDataCell(
                        '${row.totalWordCount}',
                        width: _totalWidth,
                        alignRight: true,
                      ),
                      _RemarksDataCell(row.preview),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyRemarksKeywordTable extends StatelessWidget {
  final List<RemarksKeywordRow> rows;

  const _LegacyRemarksKeywordTable({required this.rows});

  static const double _rowHeight = 31;
  static const double _noWidth = 48;
  static const double _keywordWidth = 220;
  static const double _countWidth = 76;
  static const double _reportsWidth = 76;
  static const double _sourcesWidth = 190;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No keywords could be derived from live remarks history yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _remarksText),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Container(
            height: _rowHeight,
            color: _remarksHeaderFill,
            child: const Row(
              children: [
                _RemarksHeaderCell('No', width: _noWidth),
                _RemarksHeaderCell('Keyword', width: _keywordWidth),
                _RemarksHeaderCell('Count', width: _countWidth),
                _RemarksHeaderCell('Reports', width: _reportsWidth),
                _RemarksHeaderCell('Sources', width: _sourcesWidth),
                _RemarksHeaderCell('Context'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return Container(
                  height: _rowHeight,
                  color: index.isOdd ? const Color(0xFFF8F8F8) : Colors.white,
                  child: Row(
                    children: [
                      _RemarksDataCell('${index + 1}', width: _noWidth),
                      _RemarksDataCell(row.keyword, width: _keywordWidth),
                      _RemarksDataCell(
                        '${row.occurrences}',
                        width: _countWidth,
                        alignRight: true,
                      ),
                      _RemarksDataCell(
                        '${row.reportsCount}',
                        width: _reportsWidth,
                        alignRight: true,
                      ),
                      _RemarksDataCell(
                        row.sources.join(', '),
                        width: _sourcesWidth,
                      ),
                      _RemarksDataCell(row.example.isEmpty ? '-' : row.example),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RemarksHeaderCell extends StatelessWidget {
  final String text;
  final double? width;

  const _RemarksHeaderCell(this.text, {this.width});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _remarksHeaderFill,
        border: Border.all(color: _remarksPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _remarksText,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(child: child);
  }
}

class _RemarksDataCell extends StatelessWidget {
  final String text;
  final double? width;
  final bool alignRight;

  const _RemarksDataCell(
    this.text, {
    this.width,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: _remarksPanelBorder, width: 0.8),
      ),
      child: Text(
        text.trim().isEmpty ? '-' : text.trim(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _remarksText),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(child: child);
  }
}

class _LegacyRemarksGraphPainter extends CustomPainter {
  final List<_RemarksMetricSection> sections;
  final int slotCount;

  const _LegacyRemarksGraphPainter({
    required this.sections,
    required this.slotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftLabelWidth = 78.0;
    const yAxisWidth = 38.0;
    const footerHeight = 32.0;
    const sectionGap = 3.0;

    final usableHeight =
        size.height - footerHeight - (sections.length - 1) * sectionGap;
    final sectionHeight = usableHeight / sections.length;
    final plotLeft = leftLabelWidth + yAxisWidth;
    final plotRight = size.width - 8;
    final slotWidth = slotCount <= 0 ? 0.0 : (plotRight - plotLeft) / slotCount;

    final borderPaint = Paint()
      ..color = _remarksPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _remarksGrid
      ..strokeWidth = 1;
    final barPaint = Paint()
      ..color = _remarksBar
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int index = 0; index < sections.length; index++) {
      final section = sections[index];
      final top = index * (sectionHeight + sectionGap);
      final bottom = top + sectionHeight;
      final plotRect = Rect.fromLTRB(plotLeft, top, plotRight, bottom);
      final maxValue = _niceMax(section.values);

      canvas.drawRect(plotRect, borderPaint);

      for (int line = 1; line < 8; line++) {
        final y = plotRect.top + plotRect.height * line / 8;
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
        final factor = 1 - (tick / 4);
        final value = maxValue * factor;
        final y = plotRect.top + plotRect.height * tick / 4;
        textPainter.text = TextSpan(
          text: _formatAxisTick(value, maxValue),
          style: const TextStyle(fontSize: 9.5, color: _remarksText),
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
        label: section.label,
        top: top,
        height: sectionHeight,
        width: leftLabelWidth,
      );

      if (section.values.isNotEmpty) {
        final barWidth = math.min(38.0, math.max(14.0, slotWidth * 0.36));
        for (int pointIndex = 0; pointIndex < section.values.length; pointIndex++) {
          final value = section.values[pointIndex];
          if (value <= 0 || slotWidth <= 0) continue;

          final normalized = (value / maxValue).clamp(0.0, 1.0);
          final barHeight = plotRect.height * normalized;
          final rect = Rect.fromLTWH(
            plotRect.left + slotWidth * pointIndex + (slotWidth - barWidth) / 2,
            plotRect.bottom - barHeight,
            barWidth,
            barHeight,
          );
          canvas.drawRect(rect, barPaint);
          canvas.drawRect(rect, borderPaint);
        }
      }
    }

    final footerTop = size.height - footerHeight + 6;
    for (int column = 0; column < slotCount; column++) {
      final label = '${column + 1}';
      final x = plotLeft + slotWidth * column + slotWidth / 2;
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 10, color: _remarksText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, footerTop));
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _remarksText),
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
      style: const TextStyle(fontSize: 11, color: _remarksText),
    );
    textPainter.layout(maxWidth: height - 8);

    canvas.save();
    canvas.translate(16, top + height / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    canvas.drawLine(
      Offset(width, top),
      Offset(width, top + height),
      Paint()
        ..color = _remarksPanelBorder
        ..strokeWidth = 1,
    );
  }

  double _niceMax(List<double> values) {
    final cleaned = values.where((value) => value > 0).toList(growable: false);
    if (cleaned.isEmpty) return 1;

    final maxValue = cleaned.reduce(math.max);
    if (maxValue <= 1) return 1;
    if (maxValue <= 2) return 2;
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

  String _formatAxisTick(double value, double maxValue) {
    if (maxValue <= 5) {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    if (maxValue < 50) {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _LegacyRemarksGraphPainter oldDelegate) {
    return oldDelegate.sections != sections || oldDelegate.slotCount != slotCount;
  }
}

class _RemarksMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _RemarksMessageState({
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
          border: Border.all(color: _remarksPanelBorder),
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
                  color: _remarksText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _remarksText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemarksMetricSection {
  final String label;
  final List<double> values;

  const _RemarksMetricSection({
    required this.label,
    required this.values,
  });
}

class _RemarksTabMeta {
  final String title;

  const _RemarksTabMeta({required this.title});
}

String _formatDate(String raw, String createdAt) {
  final source = raw.trim().isNotEmpty ? raw.trim() : createdAt.trim();
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source.isEmpty ? '-' : source;
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}
