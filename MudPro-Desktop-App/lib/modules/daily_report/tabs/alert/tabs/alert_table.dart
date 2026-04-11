import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_alert_prediction_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertUsagePredictionPage extends StatelessWidget {
  const AlertUsagePredictionPage({super.key});

  static const double rowH = 36;

  Widget cell(
    String text, {
    double w = 100,
    bool bold = false,
    bool isHeader = false,
    bool isSubHeader = false,
    Alignment align = Alignment.center,
    Color? bgColor,
  }) {
    return Container(
      width: w,
      height: rowH,
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isHeader
              ? AppTheme.primaryColor
              : isSubHeader
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.grey.shade300,
          width: 0.5,
        ),
        color: isHeader
            ? AppTheme.primaryColor
            : isSubHeader
                ? AppTheme.primaryColor.withOpacity(0.08)
                : bgColor ?? Colors.white,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: isHeader || isSubHeader ? 11 : 12,
          fontWeight: bold || isHeader || isSubHeader
              ? FontWeight.w600
              : FontWeight.normal,
          color: isHeader
              ? Colors.white
              : isSubHeader
                  ? AppTheme.primaryColor
                  : AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget group(String title, double width, {bool isHeader = false}) {
    return cell(
      title,
      w: width,
      bold: true,
      isHeader: isHeader,
      align: Alignment.center,
    );
  }

  Widget productTable(List<AlertPredictionRow> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Usage Prediction - Product, Premixed Mud and Package',
            badge: '${rows.length} Products',
            badgeColor: AppTheme.primaryColor,
          ),
          SizedBox(
            height: 450,
            child: Scrollbar(
              thumbVisibility: true,
              interactive: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1250,
                  child: Scrollbar(
                    thumbVisibility: true,
                    interactive: true,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              group('Description', 220, isHeader: true),
                              group('Unit', 80, isHeader: true),
                              group('Price', 90, isHeader: true),
                              group('Usage', 240, isHeader: true),
                              group('Current Inventory', 130, isHeader: true),
                              group(
                                'Daily Usage Prediction',
                                240,
                                isHeader: true,
                              ),
                              group('Zero Inventory in D', 150, isHeader: true),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            cell('', w: 220, isSubHeader: true),
                            cell('', w: 80, isSubHeader: true),
                            cell('', w: 90, isSubHeader: true),
                            cell('-2', w: 80, isSubHeader: true, bold: true),
                            cell('-1', w: 80, isSubHeader: true, bold: true),
                            cell(
                              'Today',
                              w: 80,
                              isSubHeader: true,
                              bold: true,
                            ),
                            cell('', w: 130, isSubHeader: true),
                            cell(
                              'Tomorrow',
                              w: 80,
                              isSubHeader: true,
                              bold: true,
                            ),
                            cell('+1', w: 80, isSubHeader: true, bold: true),
                            cell('+2', w: 80, isSubHeader: true, bold: true),
                            cell('', w: 150, isSubHeader: true),
                          ],
                        ),
                        if (rows.isEmpty)
                          _emptyWideRow(
                            message: 'No product/package inventory snapshot available',
                            widths: const [220, 80, 90, 80, 80, 80, 130, 80, 80, 80, 150],
                          ),
                        ...rows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          return _wideRow(
                            index: index,
                            widths: const [
                              220,
                              80,
                              90,
                              80,
                              80,
                              80,
                              130,
                              80,
                              80,
                              80,
                              150,
                            ],
                            values: [
                              row.description,
                              _dash(row.unit),
                              _formatNumber(row.price),
                              _formatNumber(row.previousDayTwoUsage),
                              _formatNumber(row.previousDayOneUsage),
                              _formatNumber(row.todayUsage),
                              _formatNumber(row.currentInventory),
                              _formatNumber(row.tomorrowUsage),
                              _formatNumber(row.plusOneUsage),
                              _formatNumber(row.plusTwoUsage),
                              _formatDays(row.zeroInventoryDays),
                            ],
                            aligns: const [
                              Alignment.centerLeft,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget serviceTable(List<AlertPredictionRow> rows) {
    return Container(
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Usage Prediction - Service and Engineering',
            badge: '${rows.length} Services',
            badgeColor: AppTheme.secondaryColor,
          ),
          SizedBox(
            height: 450,
            child: Scrollbar(
              thumbVisibility: true,
              interactive: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1100,
                  child: Scrollbar(
                    thumbVisibility: true,
                    interactive: true,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              group('Description', 260, isHeader: true),
                              group('Unit', 80, isHeader: true),
                              group('Price', 100, isHeader: true),
                              group('Usage', 240, isHeader: true),
                              group(
                                'Daily Usage Prediction',
                                240,
                                isHeader: true,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            cell('', w: 260, isSubHeader: true),
                            cell('', w: 80, isSubHeader: true),
                            cell('', w: 100, isSubHeader: true),
                            cell('-2', w: 80, isSubHeader: true, bold: true),
                            cell('-1', w: 80, isSubHeader: true, bold: true),
                            cell(
                              'Today',
                              w: 80,
                              isSubHeader: true,
                              bold: true,
                            ),
                            cell(
                              'Tomorrow',
                              w: 80,
                              isSubHeader: true,
                              bold: true,
                            ),
                            cell('+1', w: 80, isSubHeader: true, bold: true),
                            cell('+2', w: 80, isSubHeader: true, bold: true),
                          ],
                        ),
                        if (rows.isEmpty)
                          _emptyWideRow(
                            message: 'No service/engineering snapshot available',
                            widths: const [260, 80, 100, 80, 80, 80, 80, 80, 80],
                          ),
                        ...rows.asMap().entries.map((entry) {
                          final row = entry.value;
                          return _wideRow(
                            index: entry.key,
                            widths: const [260, 80, 100, 80, 80, 80, 80, 80, 80],
                            values: [
                              row.description,
                              _dash(row.unit),
                              _formatNumber(row.price),
                              _formatNumber(row.previousDayTwoUsage),
                              _formatNumber(row.previousDayOneUsage),
                              _formatNumber(row.todayUsage),
                              _formatNumber(row.tomorrowUsage),
                              _formatNumber(row.plusOneUsage),
                              _formatNumber(row.plusTwoUsage),
                            ],
                            aligns: const [
                              Alignment.centerLeft,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                              Alignment.center,
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.titleMedium.copyWith(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withOpacity(0.3)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideRow({
    required int index,
    required List<double> widths,
    required List<String> values,
    required List<Alignment> aligns,
  }) {
    final background = index.isEven
        ? Colors.white
        : AppTheme.backgroundColor.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        color: background,
      ),
      child: Row(
        children: List.generate(values.length, (cellIndex) {
          return cell(
            values[cellIndex],
            w: widths[cellIndex],
            align: aligns[cellIndex],
            bgColor: Colors.transparent,
          );
        }),
      ),
    );
  }

  Widget _emptyWideRow({
    required String message,
    required List<double> widths,
  }) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          cell(
            message,
            w: widths.first,
            align: Alignment.centerLeft,
            bgColor: Colors.transparent,
          ),
          ...widths.skip(1).map(
                (width) => cell('-', w: width, bgColor: Colors.transparent),
              ),
        ],
      ),
    );
  }

  String _dash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _formatNumber(double? value) {
    if (value == null) {
      return '-';
    }
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _formatDays(double? value) {
    if (value == null || value <= 0) {
      return '-';
    }
    return '${_formatNumber(value)} d';
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

  Widget _summaryFooter(ReportAlertPredictionController controller) {
    final totalRows =
        controller.productRows.length + controller.serviceRows.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 16,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live snapshot summary',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        controller.summaryText.value.isEmpty
                            ? 'Prediction uses today usage as forward estimate.'
                            : controller.summaryText.value,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
            ),
            child: Text(
              'Total: $totalRows Records',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.infoColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportAlertPredictionController>()
        ? Get.find<ReportAlertPredictionController>()
        : Get.put(ReportAlertPredictionController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                    Text(
                      'Usage Prediction Dashboard',
                      style: AppTheme.titleMedium.copyWith(
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.1),
                                AppTheme.secondaryColor.withOpacity(0.1),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.analytics,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Predictive Analysis',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: controller.refreshData,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh snapshot',
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
                      ? 'Loading alert prediction snapshot...'
                      : controller.errorMessage.value,
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      productTable(controller.productRows.toList()),
                      const SizedBox(height: 20),
                      serviceTable(controller.serviceRows.toList()),
                      const SizedBox(height: 20),
                      _summaryFooter(controller),
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
}
