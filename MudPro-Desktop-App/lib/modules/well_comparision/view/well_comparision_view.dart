import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/controller/well_comparision_controller.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/model/well_comparision_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

const Color _comparisonPage = Color(0xFFF4F6FA);
const Color _comparisonSection = Color(0xFF6C9BCF);
const Color _comparisonColumn = Color(0xFFEAF3FC);
const Color _comparisonStatic = Color(0xFFF2F2F2);
const Color _comparisonGrid = Color(0xFFCFE0F2);
const Color _comparisonBorder = Color(0xFFB8D0EA);

class WellComparisonPage extends StatelessWidget {
  WellComparisonPage({super.key});

  final WellComparisonController controller =
      Get.isRegistered<WellComparisonController>()
      ? Get.find<WellComparisonController>()
      : Get.put(WellComparisonController());

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: _comparisonPage,
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 420,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _comparisonBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _leftSection(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _comparisonBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _rightSection(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _bottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _comparisonSection,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.compare, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Well Comparison',
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Obx(
            () => _headerBadge(
              label: '${controller.selectedReportCount} selected',
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              textColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => _headerBadge(
              label: '${controller.comparedReports.length} compared',
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white54),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _leftSection() {
    return Column(
      children: [
        _sectionHeader(
          icon: Icons.account_tree,
          title: 'Pads, Wells & Reports',
          trailing: ElevatedButton.icon(
            onPressed: controller.refreshPads,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Refresh'),
            style: AppTheme.secondaryButtonStyle.copyWith(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return _stateMessage(
                icon: Icons.hourglass_top,
                title: 'Loading comparison data',
                message: 'Pads, wells, and reports are loading from backend.',
                loading: true,
              );
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return _stateMessage(
                icon: Icons.cloud_off,
                title: 'Unable to load data',
                message: controller.errorMessage.value,
              );
            }

            if (controller.pads.isEmpty) {
              return _stateMessage(
                icon: Icons.folder_off,
                title: 'No pads available',
                message:
                    'Create pads, wells, and reports first, then refresh Well Comparison.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: controller.pads.length,
              itemBuilder: (context, index) {
                return _buildPadTile(controller.pads[index]);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPadTile(PadModel pad) {
    final totalReports = pad.wells.fold<int>(
      0,
      (sum, well) => sum + well.reports.length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _comparisonGrid),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        leading: Icon(Icons.folder, size: 18, color: AppTheme.primaryColor),
        title: Text(
          pad.padName,
          style: const TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          '${pad.wells.length} wells • $totalReports reports',
          style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
        ),
        children: pad.wells.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'No wells found for this pad.',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ]
            : pad.wells.map(_buildWellTile).toList(),
      ),
    );
  }

  Widget _buildWellTile(ComparisonWellModel well) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _comparisonStatic,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _comparisonGrid),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
        leading: Icon(Icons.water, size: 18, color: AppTheme.primaryColor),
        title: Text(
          well.wellName,
          style: const TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          '${well.reports.length} ${well.reports.length == 1 ? 'report' : 'reports'} • API ${well.apiWellNo.isEmpty ? '-' : well.apiWellNo}',
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 9,
          ),
        ),
        children: well.reports.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'No reports available for comparison in this well.',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ]
            : well.reports.map(_buildReportRow).toList(),
      ),
    );
  }

  Widget _buildReportRow(ReportModel report) {
    return Obx(() {
      final isSelected = report.isSelected.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.25)
                : _comparisonGrid,
          ),
        ),
        child: CheckboxListTile(
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          value: isSelected,
          onChanged: (value) => controller.toggleReport(report, value ?? false),
          activeColor: AppTheme.primaryColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            'Report ${report.reportLabel} • ${report.dateLabel}',
            style: const TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 11,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            _reportSubtitle(report),
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 9,
            ),
          ),
          secondary: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _valueOrDash(report.activity),
              style: AppTheme.caption.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 9,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _rightSection() {
    return Column(
      children: [
        _sectionHeader(
          icon: Icons.table_chart,
          title: 'Comparison Matrix',
          trailing: Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white54),
              ),
              child: Text(
                '${controller.comparedReports.length} reports',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.comparedReports.isEmpty) {
              return _stateMessage(
                icon: Icons.compare_arrows,
                title: 'No reports compared yet',
                message:
                    'Select one or more reports from the left panel and click Compare Wells.',
              );
            }

            return Column(
              children: [
                _selectedComparisonChips(),
                Expanded(child: _comparisonTable()),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _selectedComparisonChips() {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.comparedReports.map((report) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _comparisonStatic,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _comparisonGrid),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${report.wellName} • ${report.reportLabel}',
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 11,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.deleteComparedReport(report),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _comparisonTable() {
    final reports = controller.comparedReports.toList(growable: false);
    final rows = _comparisonRows(reports);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 56,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 72,
          dividerThickness: 0.6,
          headingRowColor: WidgetStateProperty.all(_comparisonColumn),
          columns: [
            const DataColumn(label: _TableHeaderCell('Metric')),
            ...reports.map(
              (report) => DataColumn(label: _ComparisonReportHeader(report)),
            ),
          ],
          rows: rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final baseColor = index.isEven ? Colors.white : Colors.grey.shade50;
            final rowColor = row.hasDifference
                ? AppTheme.warningColor.withValues(alpha: 0.08)
                : baseColor;

            return DataRow(
              color: WidgetStateProperty.all(rowColor),
              cells: [
                DataCell(_MetricCell(row: row)),
                ...row.values.map(
                  (value) => DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        _valueOrDash(value),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 11,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  List<ComparisonMetricRow> _comparisonRows(List<ReportModel> reports) {
    return [
      _textRow('General', 'Well Name', reports.map((item) => item.wellName)),
      _textRow('General', 'Report No', reports.map((item) => item.reportLabel)),
      _textRow(
        'General',
        'Report Date',
        reports.map((item) => item.reportDate),
      ),
      _textRow('General', 'Operator', reports.map((item) => item.operatorName)),
      _textRow(
        'General',
        'Field/Block',
        reports.map((item) => item.fieldBlock),
      ),
      _textRow(
        'General',
        'API Well No.',
        reports.map((item) => item.apiWellNo),
      ),
      _textRow('General', 'Rig', reports.map((item) => item.rig)),
      _textRow('General', 'Spud Date', reports.map((item) => item.spudDate)),
      _textRow('Report', 'Title', reports.map((item) => item.title)),
      _textRow('Report', 'Activity', reports.map((item) => item.activity)),
      _textRow('Report', 'Interval', reports.map((item) => item.interval)),
      _numberRow('Report', 'MD (m)', reports.map((item) => item.md)),
      _textRow('Mud', 'Mud Type', reports.map((item) => item.mudType)),
      _numberRow('Mud', 'MW (ppg)', reports.map((item) => item.mw)),
      _currencyRow('Cost', 'Daily Cost', reports.map((item) => item.dailyCost)),
      _currencyRow(
        'Cost',
        'Cum. Cost',
        reports.map((item) => item.cumulativeCost),
      ),
      _textRow(
        'Remarks',
        'Recommended Treatment',
        reports.map((item) => item.recommendedTreatment),
      ),
      _textRow('Remarks', 'Remarks', reports.map((item) => item.remarks)),
      _textRow(
        'Remarks',
        'Recap Remarks',
        reports.map((item) => item.recapRemarks),
      ),
      _textRow(
        'Remarks',
        'Internal Notes',
        reports.map((item) => item.internalNotes),
      ),
    ];
  }

  ComparisonMetricRow _textRow(
    String section,
    String label,
    Iterable<String> values,
  ) {
    return ComparisonMetricRow(
      section: section,
      label: label,
      values: values.map(_valueOrDash).toList(),
    );
  }

  ComparisonMetricRow _numberRow(
    String section,
    String label,
    Iterable<double> values,
  ) {
    return ComparisonMetricRow(
      section: section,
      label: AppUnits.label(label),
      values: values.map(_formatComparisonNumber).toList(),
    );
  }

  ComparisonMetricRow _currencyRow(
    String section,
    String label,
    Iterable<double> values,
  ) {
    return ComparisonMetricRow(
      section: section,
      label: label,
      values: values.map((value) => '\$${_formatComparisonNumber(value)}').toList(),
    );
  }

  String _reportSubtitle(ReportModel report) {
    final parts = <String>[
      _valueOrDash(report.mudType),
      'MD ${_formatComparisonNumber(report.md)}',
      'MW ${_formatComparisonNumber(report.mw)}',
    ];
    return parts.join(' • ');
  }

  String _formatComparisonNumber(double value) => formatOperationNumber(
    value,
    fallbackDecimals: 2,
    trimFallback: true,
  );

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _comparisonSection,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
        border: Border(bottom: BorderSide(color: _comparisonGrid)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _stateMessage({
    required IconData icon,
    required String title,
    required String message,
    bool loading = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppTheme.primaryColor,
                ),
              )
            else
              Icon(icon, size: 32, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButtons() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _comparisonBorder),
      ),
      child: Obx(
        () => Row(
          children: [
            ElevatedButton.icon(
              onPressed: controller.comparedReports.isEmpty
                  ? null
                  : controller.clearComparedReports,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear Comparison'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: controller.selectedReportCount == 0
                  ? null
                  : controller.compareSelectedReports,
              icon: const Icon(Icons.compare_arrows, size: 16),
              label: const Text('Compare Wells'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _comparisonSection,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ComparisonReportHeader extends StatelessWidget {
  final ReportModel report;

  const _ComparisonReportHeader(this.report);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            report.wellName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Report ${report.reportLabel} • ${report.dateLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final ComparisonMetricRow row;

  const _MetricCell({required this.row});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.section.toUpperCase(),
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            row.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 11,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _valueOrDash(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '-' : trimmed;
}
