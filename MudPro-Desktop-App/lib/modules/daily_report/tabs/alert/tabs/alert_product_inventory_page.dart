import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_alert_prediction_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertProductInventoryPage extends StatelessWidget {
  const AlertProductInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportAlertPredictionController>()
        ? Get.find<ReportAlertPredictionController>()
        : Get.put(ReportAlertPredictionController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        final inventoryRows = controller.productRows
            .where((row) => (row.currentInventory ?? 0) > 0)
            .toList()
          ..sort((left, right) {
            return (right.currentInventory ?? 0).compareTo(
              left.currentInventory ?? 0,
            );
          });

        final topChartRows = inventoryRows.take(8).toList();
        final lowStockRows = [...controller.productRows]
          ..sort((left, right) {
            final leftDays = left.zeroInventoryDays ?? 999999;
            final rightDays = right.zeroInventoryDays ?? 999999;
            return leftDays.compareTo(rightDays);
          });

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(controller, inventoryRows.length),
              if (controller.isLoading.value || controller.errorMessage.isNotEmpty)
                _statusBanner(
                  isLoading: controller.isLoading.value,
                  message: controller.isLoading.value
                      ? 'Loading inventory analysis...'
                      : controller.errorMessage.value,
                ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: AppTheme.cardDecoration.copyWith(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: CustomPaint(
                          painter: _InventoryBarChartPainter(
                            dataPoints: topChartRows
                                .map(
                                  (row) => _InventoryBarPoint(
                                    label: _shortLabel(row.description),
                                    value: row.currentInventory ?? 0,
                                    color: _statusColor(row),
                                  ),
                                )
                                .toList(),
                          ),
                          child: Container(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _legendCard()),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _lowStockCard(lowStockRows.take(6).toList()),
                        ),
                      ],
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

  Widget _header(
    ReportAlertPredictionController controller,
    int inventoryCount,
  ) {
    return Container(
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
            'Product Inventory Analysis',
            style: AppTheme.titleMedium.copyWith(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.secondaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$inventoryCount Inventory Rows',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: controller.refreshData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh inventory',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Status',
            style: AppTheme.titleMedium.copyWith(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _legendRow('Stable', AppTheme.successColor, 'More than 3 days'),
          const SizedBox(height: 8),
          _legendRow('Warning', AppTheme.warningColor, '1-3 days left'),
          const SizedBox(height: 8),
          _legendRow('Critical', AppTheme.errorColor, 'Less than 1 day'),
        ],
      ),
    );
  }

  Widget _legendRow(String title, Color color, String subtitle) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lowStockCard(List<AlertPredictionRow> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Low Stock Focus',
            style: AppTheme.titleMedium.copyWith(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(
              'No inventory rows available.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ...rows.map((row) {
            final color = _statusColor(row);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.description,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _format(row.currentInventory),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    row.zeroInventoryDays == null
                        ? '-'
                        : '${_format(row.zeroInventoryDays)} d',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
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

  Color _statusColor(AlertPredictionRow row) {
    final days = row.zeroInventoryDays ?? 999999;
    if (days <= 1) {
      return AppTheme.errorColor;
    }
    if (days <= 3) {
      return AppTheme.warningColor;
    }
    return AppTheme.successColor;
  }

  String _shortLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 12) {
      return trimmed;
    }
    return '${trimmed.substring(0, 12)}...';
  }

  String _format(double? value) {
    if (value == null) {
      return '-';
    }
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

class _InventoryBarPoint {
  const _InventoryBarPoint({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _InventoryBarChartPainter extends CustomPainter {
  const _InventoryBarChartPainter({required this.dataPoints});

  final List<_InventoryBarPoint> dataPoints;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 70.0;
    const bottomPadding = 50.0;
    const topPadding = 30.0;
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
        'No product inventory data available',
        Offset(size.width / 2 - 90, size.height / 2 - 10),
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
      ..color = Colors.grey.shade100
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 5; i++) {
      final y = topPadding + chartHeight * i / 5;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );
      final label = ((maxValue * (1 - i / 5))).toStringAsFixed(0);
      _drawText(
        canvas,
        label,
        Offset(22, y - 6),
        TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
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
          colors: [point.color.withOpacity(0.82), point.color],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(left, top, barWidth, barHeight));

      canvas.drawRRect(barRect, barPaint);

      _drawText(
        canvas,
        point.label,
        Offset(left - 6, size.height - 30),
        TextStyle(
          fontSize: 10,
          color: AppTheme.textSecondary,
        ),
      );
      _drawText(
        canvas,
        point.value.toStringAsFixed(0),
        Offset(left, top - 16),
        TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: point.color,
        ),
      );
    }

    _drawText(
      canvas,
      'Current Inventory',
      Offset(14, topPadding + chartHeight / 2 - 22),
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
      Offset(leftPadding + chartWidth / 2 - 20, size.height - 14),
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
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    painter.layout();

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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
