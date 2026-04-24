import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mudpro_desktop_app/modules/report/controller/cost_of_pad_controller.dart';
import 'package:mudpro_desktop_app/modules/report/model/cost_of_pad_model.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class CostOfPadPage extends StatefulWidget {
  const CostOfPadPage({super.key});

  @override
  State<CostOfPadPage> createState() => _CostOfPadPageState();
}

class _CostOfPadPageState extends State<CostOfPadPage> {
  final CostOfPadController controller = Get.isRegistered<CostOfPadController>()
      ? Get.find<CostOfPadController>()
      : Get.put(CostOfPadController());

  final NumberFormat _currency = NumberFormat.currency(symbol: '\$');
  final NumberFormat _decimal = NumberFormat('#,##0.00');
  String _selectedWellId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.syncWithCurrentPad();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final snapshot = controller.snapshot.value;
      final pads = controller.padWellController.pads;
      final selectedPadId = controller.selectedPadId.value;
      final activeWellId = _resolveWellFilter(snapshot);
      final filteredReports = _filteredReports(snapshot, activeWellId);

      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(pads, selectedPadId, snapshot),
              const SizedBox(height: 16),
              if (snapshot != null) _buildSummaryCards(snapshot),
              if (snapshot != null) const SizedBox(height: 16),
              if (controller.errorMessage.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _banner(
                    message: controller.errorMessage.value,
                    color: AppTheme.warningColor,
                  ),
                ),
              Expanded(
                child: _buildBody(snapshot, filteredReports, activeWellId),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(
    List<AppPad> pads,
    String selectedPadId,
    PadCostSnapshot? snapshot,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.elevatedCardDecoration.copyWith(color: Colors.white),
      child: Row(
        children: [
          Icon(Icons.attach_money, size: 22, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cost of Pad',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  snapshot == null
                      ? 'Pad-level cost rollup from report summaries.'
                      : 'Tracking ${snapshot.totalReports} reports across ${snapshot.totalWells} wells.',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Pad:',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: pads.any((pad) => pad.id == selectedPadId)
                  ? selectedPadId
                  : null,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
              hint: Text('Select pad', style: AppTheme.bodySmall),
              items: pads
                  .map<DropdownMenuItem<String>>(
                    (AppPad pad) => DropdownMenuItem<String>(
                      value: pad.id,
                      child: Text(
                        pad.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                setState(() {
                  _selectedWellId = '';
                });
                await controller.selectPad(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : controller.refreshPadData,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Refresh'),
            style: AppTheme.secondaryButtonStyle.copyWith(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(PadCostSnapshot snapshot) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard(
          title: 'Wells',
          value: '${snapshot.totalWells}',
          subtitle: '${snapshot.activeWellCount} active',
          color: AppTheme.primaryColor,
        ),
        _summaryCard(
          title: 'Reports',
          value: '${snapshot.totalReports}',
          subtitle: snapshot.latestReportDate.isEmpty
              ? 'No report date'
              : _formatDate(snapshot.latestReportDate),
          color: AppTheme.infoColor,
        ),
        _summaryCard(
          title: 'Total Daily Cost',
          value: _formatCurrency(snapshot.totalDailyCost),
          subtitle: 'Across all reports',
          color: AppTheme.successColor,
        ),
        _summaryCard(
          title: 'Latest Cum. Cost',
          value: _formatCurrency(snapshot.latestCumulativeCost),
          subtitle: 'Latest report per well',
          color: AppTheme.warningColor,
        ),
        _summaryCard(
          title: 'Avg Daily Cost',
          value: _formatCurrency(snapshot.averageDailyCost),
          subtitle: snapshot.topActivity == '-'
              ? 'No activity data'
              : 'Top activity: ${snapshot.topActivity}',
          color: AppTheme.secondaryColor,
        ),
        _summaryCard(
          title: 'Bulk Setup Fee',
          value: _formatCurrency(snapshot.totalBulkSetupFee),
          subtitle: snapshot.topMudType == '-'
              ? 'No mud type data'
              : 'Top mud type: ${snapshot.topMudType}',
          color: AppTheme.accentColor,
        ),
      ],
    );
  }

  Widget _buildBody(
    PadCostSnapshot? snapshot,
    List<PadCostReportRow> filteredReports,
    String activeWellId,
  ) {
    if (controller.isLoading.value && snapshot == null) {
      return _stateCard(
        icon: Icons.hourglass_top,
        title: 'Loading Cost of Pad',
        message: 'Pad totals and report summaries are being collected.',
        loading: true,
      );
    }

    if (controller.padWellController.isLoading.value && snapshot == null) {
      return _stateCard(
        icon: Icons.sync,
        title: 'Loading pads',
        message: 'Pad and well data is being refreshed from backend.',
        loading: true,
      );
    }

    if (controller.padWellController.errorMessage.value.isNotEmpty &&
        snapshot == null) {
      return _stateCard(
        icon: Icons.cloud_off,
        title: 'Unable to load pads',
        message: controller.padWellController.errorMessage.value,
      );
    }

    if (controller.padWellController.pads.isEmpty) {
      return _stateCard(
        icon: Icons.folder_off,
        title: 'No pads available',
        message: 'Create pads and wells first, then reopen Cost of Pad.',
      );
    }

    if (snapshot == null) {
      return _stateCard(
        icon: Icons.attach_money,
        title: 'Select a pad',
        message: 'Choose a pad to roll up well costs and report totals.',
      );
    }

    if (snapshot.totalWells == 0) {
      return _stateCard(
        icon: Icons.water_drop_outlined,
        title: 'No wells under this pad',
        message: 'This pad has no wells yet, so there is nothing to aggregate.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1200;

        if (isCompact) {
          return Column(
            children: [
              SizedBox(height: 280, child: _wellPanel(snapshot, activeWellId)),
              const SizedBox(height: 16),
              Expanded(
                child: _rightPanel(snapshot, filteredReports, activeWellId),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 330, child: _wellPanel(snapshot, activeWellId)),
            const SizedBox(width: 16),
            Expanded(
              child: _rightPanel(snapshot, filteredReports, activeWellId),
            ),
          ],
        );
      },
    );
  }

  Widget _wellPanel(PadCostSnapshot snapshot, String activeWellId) {
    return Container(
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.format_list_bulleted,
            title: 'Well Breakdown',
            subtitle:
                'Pick a well to focus the ledger without changing global well selection.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _wellFilterCard(
                  title: 'All Wells',
                  subtitle: '${snapshot.totalReports} reports in this pad',
                  selected: activeWellId.isEmpty,
                  badge: _formatCurrency(snapshot.totalDailyCost),
                  onTap: () {
                    setState(() {
                      _selectedWellId = '';
                    });
                  },
                ),
                const SizedBox(height: 10),
                ...snapshot.wells.map(
                  (well) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _wellFilterCard(
                      title: well.well.displayName,
                      subtitle: well.reportCount == 0
                          ? 'No reports yet'
                          : '${well.reportCount} reports • ${well.latestReportDate.isEmpty ? 'No date' : _formatDate(well.latestReportDate)}',
                      selected: activeWellId == well.well.id,
                      badge: _formatCurrency(well.latestCumulativeCost),
                      secondaryBadge:
                          'Avg ${_formatCurrency(well.averageDailyCost)}',
                      footer: [
                        _metaPill(
                          'API',
                          well.well.apiWellNo.isEmpty
                              ? '-'
                              : well.well.apiWellNo,
                        ),
                        _metaPill('MD', _formatNumber(well.maxMeasuredDepth)),
                        _metaPill(
                          'Mud',
                          _shortText(well.latestRow?.mudType ?? '-'),
                        ),
                      ],
                      onTap: () {
                        setState(() {
                          _selectedWellId = activeWellId == well.well.id
                              ? ''
                              : well.well.id;
                        });
                      },
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

  Widget _rightPanel(
    PadCostSnapshot snapshot,
    List<PadCostReportRow> filteredReports,
    String activeWellId,
  ) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stackCards = constraints.maxWidth < 980;
            if (stackCards) {
              return Column(
                children: [
                  _padProfileCard(snapshot),
                  const SizedBox(height: 16),
                  _costDriversCard(snapshot),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _padProfileCard(snapshot)),
                const SizedBox(width: 16),
                Expanded(child: _costDriversCard(snapshot)),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(child: _ledgerCard(filteredReports, activeWellId)),
      ],
    );
  }

  Widget _padProfileCard(PadCostSnapshot snapshot) {
    final pad = snapshot.pad;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Pad Profile'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _profileField('Field / Block', pad.fieldBlock),
              _profileField('Operator', pad.operator),
              _profileField('Rig', pad.rig),
              _profileField('Country', pad.country),
              _profileField('Stock Point', pad.stockPoint),
              _profileField(
                'Latest Report',
                snapshot.latestReportDate.isEmpty
                    ? '-'
                    : _formatDate(snapshot.latestReportDate),
              ),
              _profileField('Max MD', _formatNumber(snapshot.maxMeasuredDepth)),
              _profileField(
                'Bulk Setup Fee',
                _formatCurrency(snapshot.totalBulkSetupFee),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _costDriversCard(PadCostSnapshot snapshot) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Cost Drivers'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _breakdownList(
                  title: 'By Activity',
                  items: snapshot.activityBreakdown,
                  accentColor: AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _breakdownList(
                  title: 'By Mud Type',
                  items: snapshot.mudTypeBreakdown,
                  accentColor: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ledgerCard(List<PadCostReportRow> reports, String activeWellId) {
    return Container(
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.table_chart_outlined,
            title: 'Report Ledger',
            subtitle: activeWellId.isEmpty
                ? 'Showing every report available in this pad.'
                : 'Filtered to one well without changing current app context.',
          ),
          Expanded(
            child: reports.isEmpty
                ? _stateCard(
                    icon: Icons.description_outlined,
                    title: 'No reports to show',
                    message: activeWellId.isEmpty
                        ? 'This pad has wells, but no report summaries are available yet.'
                        : 'The selected well has no report summaries to list.',
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 980),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowHeight: 42,
                            dataRowMinHeight: 42,
                            dataRowMaxHeight: 52,
                            headingTextStyle: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Well')),
                              DataColumn(label: Text('Report')),
                              DataColumn(label: Text('Activity')),
                              DataColumn(label: Text('Mud')),
                              DataColumn(
                                label: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('MD'),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('MW'),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('Daily Cost'),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('Cum. Cost'),
                                ),
                                numeric: true,
                              ),
                            ],
                            rows: reports.map((report) {
                              final rowColor = report.isLatestForWell
                                  ? AppTheme.primaryColor.withValues(
                                      alpha: 0.06,
                                    )
                                  : null;

                              return DataRow(
                                color: rowColor == null
                                    ? null
                                    : WidgetStateProperty.all(rowColor),
                                cells: [
                                  DataCell(
                                    Text(_formatDate(report.row.reportDate)),
                                  ),
                                  DataCell(
                                    Text(
                                      report.well.displayName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DataCell(Text(report.row.reportLabel)),
                                  DataCell(
                                    Text(_shortText(report.row.activity)),
                                  ),
                                  DataCell(
                                    Text(_shortText(report.row.mudType)),
                                  ),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(_formatNumber(report.row.md)),
                                    ),
                                  ),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(_formatNumber(report.row.mw)),
                                    ),
                                  ),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _formatCurrency(report.row.dailyCost),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _formatCurrency(
                                          report.row.cumulativeCost,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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

  Widget _breakdownList({
    required String title,
    required List<CostBucketSummary> items,
    required Color accentColor,
  }) {
    final visibleItems = items.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (visibleItems.isEmpty)
          Text(
            'No data available',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          )
        else
          ...visibleItems.map((item) {
            final progressDenominator = visibleItems.first.totalDailyCost <= 0
                ? 1.0
                : visibleItems.first.totalDailyCost;
            final ratio = (item.totalDailyCost / progressDenominator).clamp(
              0.0,
              1.0,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatCurrency(item.totalDailyCost),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 7,
                      backgroundColor: accentColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.reportCount} reports • ${item.wellCount} wells • avg ${_formatCurrency(item.averageDailyCost)}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: 208,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.insights_outlined, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _wellFilterCard({
    required String title,
    required String subtitle,
    required bool selected,
    required String badge,
    String? secondaryBadge,
    List<Widget> footer = const <Widget>[],
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.35)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            if (secondaryBadge != null) ...[
              const SizedBox(height: 8),
              Text(
                secondaryBadge,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (footer.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: footer),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metaPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: AppTheme.caption.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.bodyLarge.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _banner({required String message, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    bool loading = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppTheme.primaryColor,
                  ),
                )
              else
                Icon(icon, size: 34, color: AppTheme.primaryColor),
              const SizedBox(height: 14),
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveWellFilter(PadCostSnapshot? snapshot) {
    if (snapshot == null) return '';
    final exists = snapshot.wells.any(
      (well) => well.well.id == _selectedWellId,
    );
    return exists ? _selectedWellId : '';
  }

  List<PadCostReportRow> _filteredReports(
    PadCostSnapshot? snapshot,
    String activeWellId,
  ) {
    if (snapshot == null) return const <PadCostReportRow>[];
    if (activeWellId.isEmpty) return snapshot.reports;
    return snapshot.reports
        .where((report) => report.well.id == activeWellId)
        .toList();
  }

  String _formatCurrency(double value) => _currency.format(value);

  String _formatNumber(double value) => _decimal.format(value);

  String _formatDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return '-';

    final direct = DateTime.tryParse(text);
    if (direct != null) {
      return DateFormat('dd MMM yyyy').format(direct);
    }

    for (final pattern in const [
      'MM/dd/yyyy',
      'M/d/yyyy',
      'dd/MM/yyyy',
      'd/M/yyyy',
      'MM-dd-yyyy',
      'M-d-yyyy',
      'dd-MM-yyyy',
      'd-M-yyyy',
      'yyyy/MM/dd',
    ]) {
      try {
        return DateFormat(
          'dd MMM yyyy',
        ).format(DateFormat(pattern).parseStrict(text));
      } catch (_) {}
    }

    return text;
  }

  String _shortText(String value) {
    final text = value.trim();
    if (text.isEmpty) return '-';
    if (text.length <= 24) return text;
    return '${text.substring(0, 21)}...';
  }
}
