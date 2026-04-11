import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_concentration_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConcentrationGraphTab extends StatelessWidget {
  const ConcentrationGraphTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportConcentrationController>()
        ? Get.find<ReportConcentrationController>()
        : Get.put(ReportConcentrationController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        final chartRows = controller.chartRows
            .map(
              (row) => _ConcentrationChartPoint(
                label: _shortLabel(row.product),
                metricLabel: row.primaryMetricLabel,
                value: row.primaryMetric,
                color: row.sourceType == 'Premixed'
                    ? AppTheme.secondaryColor
                    : AppTheme.warningColor,
              ),
            )
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(controller),
              if (controller.isLoading.value ||
                  controller.errorMessage.isNotEmpty)
                _statusBanner(
                  isLoading: controller.isLoading.value,
                  message: controller.isLoading.value
                      ? 'Loading concentration chart...'
                      : controller.errorMessage.value,
                ),
              if (chartRows.isEmpty)
                Expanded(child: _emptyState())
              else
                Expanded(
                  child: Container(
                    decoration: AppTheme.cardDecoration.copyWith(
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top concentration rows',
                          style: AppTheme.titleMedium.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.guidanceText,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: CustomPaint(
                            painter: _ConcentrationBarChartPainter(
                              dataPoints: chartRows,
                            ),
                            child: Container(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _legendItem(
                              'Premixed -> MW (ppg)',
                              AppTheme.secondaryColor,
                            ),
                            _legendItem(
                              'OBM -> Conc (lb/bbl)',
                              AppTheme.warningColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _headerCard(ReportConcentrationController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Concentration Graph',
                  style: AppTheme.titleMedium.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.summaryText,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: controller.refreshData,
            tooltip: 'Refresh graph',
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _statusBanner({required bool isLoading, required String message}) {
    final background = isLoading
        ? const Color(0xffEAF4FF)
        : const Color(0xffFFF4E5);
    final textColor = isLoading
        ? const Color(0xff1F5E9C)
        : const Color(0xff9A5A00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: background.withOpacity(0.9)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 52,
            color: AppTheme.textSecondary.withOpacity(0.55),
          ),
          const SizedBox(height: 12),
          Text(
            'No chartable concentration values found',
            style: AppTheme.titleMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Add MW or concentration values in UG inventory to populate this graph.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _shortLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 12) {
      return trimmed;
    }
    return '${trimmed.substring(0, 12)}...';
  }
}

class _ConcentrationChartPoint {
  const _ConcentrationChartPoint({
    required this.label,
    required this.metricLabel,
    required this.value,
    required this.color,
  });

  final String label;
  final String metricLabel;
  final double value;
  final Color color;
}

class _ConcentrationBarChartPainter extends CustomPainter {
  const _ConcentrationBarChartPainter({required this.dataPoints});

  final List<_ConcentrationChartPoint> dataPoints;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 74.0;
    const bottomPadding = 58.0;
    const topPadding = 28.0;
    const rightPadding = 20.0;

    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    if (dataPoints.isEmpty) {
      _drawText(
        canvas,
        'No concentration values available',
        Offset(size.width / 2 - 92, size.height / 2 - 10),
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      );
      return;
    }

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final maxValue = math.max(
      1,
      dataPoints.map((point) => point.value).reduce(math.max),
    );

    final axisPaint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 2;
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 5; i++) {
      final y = topPadding + chartHeight * i / 5;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      final label = _formatNumber(maxValue * (1 - (i / 5)));
      _drawText(
        canvas,
        label,
        Offset(18, y - 6),
        TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      );
    }

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(leftPadding + chartWidth, topPadding + chartHeight),
      axisPaint,
    );

    final step = chartWidth / dataPoints.length;
    final barWidth = step * 0.58;

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final left = leftPadding + (i * step) + (step - barWidth) / 2;
      final normalizedHeight = point.value / maxValue;
      final barHeight = normalizedHeight * chartHeight;
      final top = topPadding + chartHeight - barHeight;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(6),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: [point.color.withOpacity(0.78), point.color],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(left, top, barWidth, barHeight));

      canvas.drawRRect(barRect, barPaint);

      _drawText(
        canvas,
        point.label,
        Offset(left - 4, size.height - 32),
        TextStyle(fontSize: 10, color: AppTheme.textSecondary),
      );
      _drawText(
        canvas,
        '${_formatNumber(point.value)} ${point.metricLabel}',
        Offset(left - 6, top - 18),
        TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: point.color,
        ),
      );
    }

    _drawText(
      canvas,
      'Current Value',
      Offset(16, topPadding + chartHeight / 2 - 28),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      rotate: true,
    );
    _drawText(
      canvas,
      'Products',
      Offset(leftPadding + chartWidth / 2 - 24, size.height - 12),
      TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    bool rotate = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    canvas.save();
    if (rotate) {
      canvas.translate(position.dx, position.dy);
      canvas.rotate(-1.5708);
      painter.paint(canvas, Offset.zero);
    } else {
      painter.paint(canvas, position);
    }
    canvas.restore();
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  bool shouldRepaint(covariant _ConcentrationBarChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}
