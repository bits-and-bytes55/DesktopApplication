import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_alert_prediction_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertUsagePage extends StatefulWidget {
  const AlertUsagePage({super.key});

  @override
  State<AlertUsagePage> createState() => _AlertUsagePageState();
}

class _AlertUsagePageState extends State<AlertUsagePage> {
  double? hoverX;
  double? hoverY;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportAlertPredictionController>()
        ? Get.find<ReportAlertPredictionController>()
        : Get.put(ReportAlertPredictionController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        final points = _buildPoints(controller);
        final maxY = points.isEmpty
            ? 0.0
            : points.map((point) => point.value).reduce(math.max);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Usage Chart Analysis',
                      style: AppTheme.titleMedium.copyWith(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Top Usage Snapshot',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: controller.refreshData,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh chart',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (controller.isLoading.value || controller.errorMessage.isNotEmpty)
                _statusBanner(
                  isLoading: controller.isLoading.value,
                  message: controller.isLoading.value
                      ? 'Loading usage chart...'
                      : controller.errorMessage.value,
                ),
              Expanded(
                child: Container(
                  decoration: AppTheme.cardDecoration.copyWith(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: MouseRegion(
                    onHover: (event) {
                      setState(() {
                        hoverX = event.localPosition.dx;
                        hoverY = event.localPosition.dy;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        hoverX = null;
                        hoverY = null;
                      });
                    },
                    child: CustomPaint(
                      painter: _EnhancedUsageChartPainter(
                        hoverX: hoverX,
                        hoverY: hoverY,
                        dataPoints: points,
                        maxY: maxY,
                      ),
                      child: Container(),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        points.isEmpty
                            ? 'No usage rows available for charting yet.'
                            : 'Chart uses live usage rows from the alert snapshot controller.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.infoColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${points.length} Data Points',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.infoColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<_UsagePoint> _buildPoints(ReportAlertPredictionController controller) {
    final productRows = controller.productRows
        .where((row) => row.todayUsage > 0)
        .take(7)
        .toList();
    final sourceRows = productRows.isNotEmpty
        ? productRows
        : controller.serviceRows.where((row) => row.todayUsage > 0).take(7).toList();

    return sourceRows.asMap().entries.map((entry) {
      return _UsagePoint(
        x: entry.key.toDouble(),
        value: entry.value.todayUsage,
        label: _shortLabel(entry.value.description, entry.key),
      );
    }).toList();
  }

  String _shortLabel(String value, int index) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Item ${index + 1}';
    }
    if (trimmed.length <= 12) {
      return trimmed;
    }
    return '${trimmed.substring(0, 12)}...';
  }

  Widget _statusBanner({
    required bool isLoading,
    required String message,
  }) {
    final backgroundColor = isLoading
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
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.85)),
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
}

class _UsagePoint {
  const _UsagePoint({
    required this.x,
    required this.value,
    required this.label,
  });

  final double x;
  final double value;
  final String label;
}

class _EnhancedUsageChartPainter extends CustomPainter {
  const _EnhancedUsageChartPainter({
    this.hoverX,
    this.hoverY,
    required this.dataPoints,
    required this.maxY,
  });

  final double? hoverX;
  final double? hoverY;
  final List<_UsagePoint> dataPoints;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 70;
    const double bottomPadding = 58;
    const double topPadding = 30;
    const double rightPadding = 30;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

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
        'No usage data available',
        Offset(size.width / 2 - 60, size.height / 2 - 10),
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      );
      return;
    }

    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 0.8;
    final safeMaxY = maxY <= 0 ? 1.0 : maxY;
    final xDivisions = math.max(1, dataPoints.length - 1);

    for (int i = 0; i <= 5; i++) {
      final y = topPadding + chartHeight * i / 5;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      final labelValue = safeMaxY * (1 - i / 5);
      _drawText(
        canvas,
        _formatNumber(labelValue),
        Offset(18, y - 6),
        TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    for (int i = 0; i < dataPoints.length; i++) {
      final x = leftPadding + (i / xDivisions) * chartWidth;
      canvas.drawLine(
        Offset(x, topPadding),
        Offset(x, topPadding + chartHeight),
        gridPaint,
      );

      _drawText(
        canvas,
        dataPoints[i].label,
        Offset(x - 18, size.height - 36),
        TextStyle(
          fontSize: 10,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final axisPaint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 2;
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

    final linePaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final normalizedY = safeMaxY <= 0 ? 0.0 : point.value / safeMaxY;
      final x = leftPadding + (i / xDivisions) * chartWidth;
      final y = topPadding + chartHeight - (normalizedY * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = AppTheme.primaryColor.withOpacity(0.3),
      );
    }

    if (dataPoints.length > 1) {
      canvas.drawPath(path, linePaint);
    }

    if (hoverX != null && hoverY != null) {
      final cursorX = hoverX!.clamp(leftPadding, leftPadding + chartWidth);
      final cursorY = hoverY!.clamp(topPadding, topPadding + chartHeight);

      final cursorPaint = Paint()
        ..color = AppTheme.secondaryColor.withOpacity(0.7)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(cursorX, topPadding),
        Offset(cursorX, topPadding + chartHeight),
        cursorPaint,
      );
      canvas.drawLine(
        Offset(leftPadding, cursorY),
        Offset(leftPadding + chartWidth, cursorY),
        cursorPaint,
      );
      canvas.drawCircle(
        Offset(cursorX, cursorY),
        6,
        Paint()..color = AppTheme.accentColor,
      );

      final xIndex = ((cursorX - leftPadding) / chartWidth * xDivisions)
          .round()
          .clamp(0, dataPoints.length - 1);
      final hoveredPoint = dataPoints[xIndex];
      final coordText =
          '${hoveredPoint.label}: ${_formatNumber(hoveredPoint.value)}';
      _drawText(
        canvas,
        coordText,
        Offset(cursorX + 10, cursorY - 20),
        const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        background: AppTheme.secondaryColor,
      );
    }

    _drawText(
      canvas,
      'Usage',
      Offset(12, topPadding + chartHeight / 2 - 16),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      rotate: true,
    );
    _drawText(
      canvas,
      'Items',
      Offset(leftPadding + chartWidth / 2 - 12, size.height - 18),
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
    Offset pos,
    TextStyle style, {
    bool rotate = false,
    Color? background,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    if (background != null) {
      final backgroundPaint = Paint()..color = background;
      final rect = Rect.fromCenter(
        center: Offset(pos.dx + painter.width / 2, pos.dy + painter.height / 2),
        width: painter.width + 8,
        height: painter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        backgroundPaint,
      );
    }

    canvas.save();
    if (rotate) {
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(-1.5708);
      painter.paint(canvas, Offset.zero);
    } else {
      painter.paint(canvas, pos);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
