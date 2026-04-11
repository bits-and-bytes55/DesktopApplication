import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_concentration_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConcentrationTableHistory extends StatelessWidget {
  const ConcentrationTableHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportConcentrationController>()
        ? Get.find<ReportConcentrationController>()
        : Get.put(ReportConcentrationController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        final rows = controller.referenceRows;

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
                      ? 'Loading report reference table...'
                      : controller.errorMessage.value,
                ),
              _infoBanner(),
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
                                width: 1160,
                                child: Column(
                                  children: [
                                    _tableHeader(),
                                    ...rows.map(_tableRow),
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
                  'History / Report Reference',
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
            tooltip: 'Refresh report reference',
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF4F8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD7E5FF)),
      ),
      child: Text(
        'This table aligns the live concentration snapshot with the available report list for the selected well.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xff28598E),
        ),
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
          _HistoryCell(text: 'No', width: 60, isHeader: true),
          _HistoryCell(text: 'Date', width: 120, isHeader: true),
          _HistoryCell(text: 'Rpt #', width: 80, isHeader: true),
          _HistoryCell(text: 'Title', width: 260, isHeader: true),
          _HistoryCell(text: 'System', width: 160, isHeader: true),
          _HistoryCell(text: 'Selection', width: 110, isHeader: true),
          _HistoryCell(text: 'Snapshot Type', width: 150, isHeader: true),
          _HistoryCell(text: 'Snapshot State', width: 220, isHeader: true),
        ],
      ),
    );
  }

  Widget _tableRow(ReportConcentrationReferenceRow row) {
    final background = row.isSelected
        ? AppTheme.primaryColor.withOpacity(0.08)
        : row.index.isEven
        ? Colors.white
        : AppTheme.backgroundColor.withOpacity(0.45);

    return Container(
      color: background,
      child: Row(
        children: [
          _HistoryCell(text: '${row.index}', width: 60, background: background),
          _HistoryCell(
            text: row.report.reportDate.isEmpty ? '-' : row.report.reportDate,
            width: 120,
            background: background,
          ),
          _HistoryCell(
            text: row.report.reportNo.isEmpty ? '-' : row.report.reportNo,
            width: 80,
            background: background,
          ),
          _HistoryCell(
            text: row.report.displayName,
            width: 260,
            alignment: Alignment.centerLeft,
            background: background,
          ),
          _HistoryCell(
            text: row.system,
            width: 160,
            alignment: Alignment.centerLeft,
            background: background,
          ),
          _HistoryCell(
            width: 110,
            background: background,
            child: Align(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: row.isSelected
                      ? AppTheme.successColor.withOpacity(0.14)
                      : AppTheme.textSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: row.isSelected
                        ? AppTheme.successColor.withOpacity(0.28)
                        : AppTheme.textSecondary.withOpacity(0.18),
                  ),
                ),
                child: Text(
                  row.isSelected ? 'Active' : 'Reference',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: row.isSelected
                        ? AppTheme.successColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          _HistoryCell(
            text: row.snapshotType,
            width: 150,
            background: background,
          ),
          _HistoryCell(
            text: row.snapshotState,
            width: 220,
            alignment: Alignment.centerLeft,
            background: background,
          ),
        ],
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
            Icons.history_toggle_off,
            size: 52,
            color: AppTheme.textSecondary.withOpacity(0.55),
          ),
          const SizedBox(height: 12),
          Text(
            'No reports available for reference',
            style: AppTheme.titleMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Create or select reports for this well to populate the reference table.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HistoryCell extends StatelessWidget {
  const _HistoryCell({
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
