import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_alert_prediction_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertSummaryPage extends StatelessWidget {
  const AlertSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportAlertPredictionController>()
        ? Get.find<ReportAlertPredictionController>()
        : Get.put(ReportAlertPredictionController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        final products = controller.productRows.toList();
        final services = controller.serviceRows.toList();
        final summary = controller.summaryData;
        final riskRows = products
          ..sort((left, right) {
            final leftValue = left.zeroInventoryDays ?? 999999;
            final rightValue = right.zeroInventoryDays ?? 999999;
            return leftValue.compareTo(rightValue);
          });
        final topUsage = [...products, ...services]
          ..sort((left, right) => right.todayUsage.compareTo(left.todayUsage));

        final criticalCount = products
            .where((row) => (row.zeroInventoryDays ?? 999) <= 1)
            .length;
        final warningCount = products
            .where((row) {
              final days = row.zeroInventoryDays ?? 999;
              return days > 1 && days <= 3;
            })
            .length;
        final stableCount = products.length - criticalCount - warningCount;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(controller),
              if (controller.isLoading.value || controller.errorMessage.isNotEmpty)
                _statusBanner(
                  isLoading: controller.isLoading.value,
                  message: controller.isLoading.value
                      ? 'Loading alert summary...'
                      : controller.errorMessage.value,
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              title: 'Product Rows',
                              value: '${products.length}',
                              subtitle: 'Product + package snapshot lines',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              title: 'Service Rows',
                              value: '${services.length}',
                              subtitle: 'Service + engineering lines',
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              title: 'Stock Balance',
                              value: _format(summary['stockBalance']),
                              subtitle: 'Current stock value snapshot',
                              color: AppTheme.infoColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              title: 'Daily Total',
                              value: _format(summary['dailyTotal']),
                              subtitle: 'Daily cost from snapshot summary',
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _riskOverview(
                              productsCount: products.length,
                              criticalCount: criticalCount,
                              warningCount: warningCount,
                              stableCount: stableCount,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _summaryValues(summary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _topRowsCard(
                              title: 'Top Depletion Risk',
                              emptyMessage: 'No depletion-risk rows available',
                              rows: riskRows.take(6).toList(),
                              valueBuilder: (row) => row.zeroInventoryDays == null
                                  ? '-'
                                  : '${_format(row.zeroInventoryDays)} d',
                              colorBuilder: (row) {
                                final days = row.zeroInventoryDays ?? 999;
                                if (days <= 1) return AppTheme.errorColor;
                                if (days <= 3) return AppTheme.warningColor;
                                return AppTheme.successColor;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _topRowsCard(
                              title: 'Top Usage',
                              emptyMessage: 'No usage rows available',
                              rows: topUsage.take(6).toList(),
                              valueBuilder: (row) => _format(row.todayUsage),
                              colorBuilder: (_) => AppTheme.primaryColor,
                            ),
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

  Widget _header(ReportAlertPredictionController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alert Summary',
                style: AppTheme.titleMedium.copyWith(
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.summaryText.value.isEmpty
                    ? 'Live inventory snapshot overview'
                    : controller.summaryText.value,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Risk Monitoring',
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
                tooltip: 'Refresh summary',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskOverview({
    required int productsCount,
    required int criticalCount,
    required int warningCount,
    required int stableCount,
  }) {
    final total = productsCount == 0 ? 1 : productsCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Risk Overview',
            style: AppTheme.titleMedium.copyWith(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _progressRow(
            label: 'Critical',
            value: criticalCount / total,
            display: '$criticalCount rows',
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 10),
          _progressRow(
            label: 'Warning',
            value: warningCount / total,
            display: '$warningCount rows',
            color: AppTheme.warningColor,
          ),
          const SizedBox(height: 10),
          _progressRow(
            label: 'Stable',
            value: stableCount / total,
            display: '$stableCount rows',
            color: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _progressRow({
    required String label,
    required double value,
    required String display,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              display,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _summaryValues(Map<String, double> summary) {
    final rows = [
      ('Subtotal', summary['subtotal']),
      ('Tax Rate', summary['taxRate']),
      ('Tax Amount', summary['taxAmount']),
      ('Previous Total', summary['prevTotal']),
      ('Cumulative Total', summary['cumTotal']),
      ('Bulk Tank Setup', summary['bulkTankSetupFee']),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Snapshot',
            style: AppTheme.titleMedium.copyWith(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((row) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row.$1,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _format(row.$2),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
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

  Widget _topRowsCard({
    required String title,
    required String emptyMessage,
    required List<AlertPredictionRow> rows,
    required String Function(AlertPredictionRow row) valueBuilder,
    required Color Function(AlertPredictionRow row) colorBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.titleMedium.copyWith(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ...rows.map((row) {
            final color = colorBuilder(row);
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
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                    valueBuilder(row),
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
      margin: const EdgeInsets.only(bottom: 16),
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
