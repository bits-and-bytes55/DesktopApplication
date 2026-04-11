import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_concentration_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConcentrationCurrentTable extends StatelessWidget {
  const ConcentrationCurrentTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportConcentrationController>()
        ? Get.find<ReportConcentrationController>()
        : Get.put(ReportConcentrationController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        final rows = controller.currentRows.toList();

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
                      ? 'Loading concentration snapshot...'
                      : controller.errorMessage.value,
                ),
              _summaryCards(controller),
              const SizedBox(height: 12),
              Expanded(
                child: rows.isEmpty
                    ? _emptyState()
                    : Container(
                        decoration: AppTheme.cardDecoration.copyWith(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(right: 4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 1170,
                                child: Column(
                                  children: [
                                    _tableHeader(),
                                    ...rows.asMap().entries.map((entry) {
                                      return _tableRow(
                                        index: entry.key,
                                        row: entry.value,
                                        system: controller.selectedSystem.value,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
                  'Current Concentration Snapshot',
                  style: AppTheme.titleMedium.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.guidanceText,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: controller.refreshData,
            tooltip: 'Refresh concentration',
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _summaryCards(ReportConcentrationController controller) {
    final cards = <_SummaryCardData>[
      _SummaryCardData(
        title: 'Total Rows',
        value: controller.currentRows.length.toString(),
        color: AppTheme.primaryColor,
      ),
      _SummaryCardData(
        title: 'Premixed',
        value: controller.premixedCount.toString(),
        color: AppTheme.secondaryColor,
      ),
      _SummaryCardData(
        title: 'OBM',
        value: controller.obmCount.toString(),
        color: AppTheme.warningColor,
      ),
      _SummaryCardData(
        title: 'Report',
        value: controller.selectedReportLabel.isEmpty
            ? 'Not selected'
            : controller.selectedReportLabel,
        color: AppTheme.infoColor,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((card) => _summaryCard(card)).toList(),
    );
  }

  Widget _summaryCard(_SummaryCardData card) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: card.color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: card.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: const [
          _TableCell(text: 'No', width: 60, isHeader: true),
          _TableCell(text: 'Source', width: 110, isHeader: true),
          _TableCell(text: 'Product', width: 240, isHeader: true),
          _TableCell(text: 'Code / Mud Type', width: 180, isHeader: true),
          _TableCell(text: 'SG / MW', width: 110, isHeader: true),
          _TableCell(text: 'Value Type', width: 100, isHeader: true),
          _TableCell(text: 'Current Value', width: 120, isHeader: true),
          _TableCell(text: 'Unit', width: 90, isHeader: true),
          _TableCell(text: 'System', width: 160, isHeader: true),
        ],
      ),
    );
  }

  Widget _tableRow({
    required int index,
    required ReportConcentrationRow row,
    required String system,
  }) {
    final background = index.isEven
        ? Colors.white
        : AppTheme.backgroundColor.withOpacity(0.45);
    final sourceColor = row.sourceType == 'Premixed'
        ? AppTheme.secondaryColor
        : AppTheme.warningColor;

    return Container(
      color: background,
      child: Row(
        children: [
          _TableCell(text: '${index + 1}', width: 60, background: background),
          _TableCell(
            width: 110,
            background: background,
            child: Align(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sourceColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sourceColor.withOpacity(0.32)),
                ),
                child: Text(
                  row.sourceType,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: sourceColor,
                  ),
                ),
              ),
            ),
          ),
          _TableCell(
            text: row.product,
            width: 240,
            alignment: Alignment.centerLeft,
            background: background,
          ),
          _TableCell(
            text: row.descriptor,
            width: 180,
            alignment: Alignment.centerLeft,
            background: background,
          ),
          _TableCell(
            text: _metricText(row.secondaryMetricLabel, row.secondaryMetric),
            width: 110,
            background: background,
          ),
          _TableCell(
            text: row.primaryMetricLabel,
            width: 100,
            background: background,
          ),
          _TableCell(
            text: _formatNumber(row.primaryMetric),
            width: 120,
            background: background,
          ),
          _TableCell(text: row.unit, width: 90, background: background),
          _TableCell(
            text: system,
            width: 160,
            alignment: Alignment.centerLeft,
            background: background,
          ),
        ],
      ),
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
            Icons.scatter_plot_outlined,
            size: 48,
            color: AppTheme.textSecondary.withOpacity(0.55),
          ),
          const SizedBox(height: 12),
          Text(
            'No concentration snapshot available',
            style: AppTheme.titleMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Save premixed or OBM inventory rows to populate this table.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _metricText(String label, double? value) {
    if (value == null || value <= 0) {
      return '-';
    }
    return '$label ${_formatNumber(value)}';
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    this.text,
    required this.width,
    this.isHeader = false,
    this.alignment = Alignment.center,
    this.background,
    this.child,
  });

  final String? text;
  final double width;
  final bool isHeader;
  final Alignment alignment;
  final Color? background;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 44,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isHeader ? Colors.transparent : background,
        border: Border.all(
          color: isHeader
              ? Colors.white.withOpacity(0.22)
              : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child:
          child ??
          Text(
            text ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignment == Alignment.centerLeft
                ? TextAlign.left
                : TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
              color: isHeader ? Colors.white : AppTheme.textPrimary,
            ),
          ),
    );
  }
}
