import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report/controller/report_manager_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReportManagerPage extends StatefulWidget {
  const ReportManagerPage({super.key});

  @override
  State<ReportManagerPage> createState() => _ReportManagerPageState();
}

class _ReportManagerPageState extends State<ReportManagerPage> {
  final ReportManagerController rmC =
      Get.isRegistered<ReportManagerController>()
      ? Get.find<ReportManagerController>()
      : Get.put(ReportManagerController());
  final PadWellController padWellC = padWellContext;

  final List<_CriteriaConfig> criteria = const [
    _CriteriaConfig(
      key: 'date',
      label: 'Date',
      kind: _CriteriaKind.date,
      textValue: _dateValue,
    ),
    _CriteriaConfig(
      key: 'reportNo',
      label: 'Report No.',
      kind: _CriteriaKind.number,
      numericValue: _reportNoValue,
    ),
    _CriteriaConfig(
      key: 'md',
      label: 'Depth (m)',
      kind: _CriteriaKind.number,
      numericValue: _mdValue,
    ),
    _CriteriaConfig(
      key: 'mw',
      label: 'MW (ppg)',
      kind: _CriteriaKind.number,
      numericValue: _mwValue,
    ),
    _CriteriaConfig(
      key: 'recommendedTreatment',
      label: 'Recommended Tour Treatm.',
      kind: _CriteriaKind.text,
      textValue: _recommendedTreatmentValue,
    ),
    _CriteriaConfig(
      key: 'remarks',
      label: 'Remarks',
      kind: _CriteriaKind.text,
      textValue: _remarksValue,
    ),
    _CriteriaConfig(
      key: 'recapRemarks',
      label: 'Recap Remarks',
      kind: _CriteriaKind.text,
      textValue: _recapRemarksValue,
    ),
    _CriteriaConfig(
      key: 'internalNotes',
      label: 'Internal Notes',
      kind: _CriteriaKind.text,
      textValue: _internalNotesValue,
    ),
  ];

  final Map<String, bool> checked = {};
  final Map<String, TextEditingController> minCtrl = {};
  final Map<String, TextEditingController> maxCtrl = {};
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();
    for (final item in criteria) {
      checked[item.key] = false;
      minCtrl[item.key] = TextEditingController();
      maxCtrl[item.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in minCtrl.values) {
      controller.dispose();
    }
    for (final controller in maxCtrl.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isSmallScreen = constraints.maxWidth < 1200;

        return Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: isSmallScreen ? constraints.maxWidth * 0.36 : 420,
                      child: Container(
                        decoration: AppTheme.cardDecoration.copyWith(
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: _buildSearchCriteria(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: AppTheme.cardDecoration.copyWith(
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: _buildResultsPanel(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.elevatedCardDecoration.copyWith(color: Colors.white),
      child: Obx(() {
        final selectedWellId = padWellC.selectedWellId.value;
        final selectedWellName = padWellC.selectedWellName.isEmpty
            ? 'No well selected'
            : padWellC.selectedWellName;
        final rowCount = rmC.rows.length;

        return Row(
          children: [
            Icon(Icons.folder_open, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Report Manager - $selectedWellName',
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Current Well:',
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
                value: padWellC.wells.any((well) => well.id == selectedWellId)
                    ? selectedWellId
                    : null,
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
                hint: Text('Select well', style: AppTheme.bodySmall),
                items: padWellC.wells
                    .map(
                      (well) => DropdownMenuItem(
                        value: well.id,
                        child: Text(
                          well.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodySmall,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  padWellC.selectWell(value);
                  rmC.clearSelection();
                  setState(() {
                    hasSearched = false;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$rowCount reports loaded',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSearchCriteria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(icon: Icons.search, title: 'Search Criteria'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.tableHeadColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          'Use',
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Variable',
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Min Value',
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Max Value',
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...criteria.map(_criteriaRow),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Tips',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Date expects MM/DD/YYYY. Text filters use contains match. Number filters use min and max range.',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearAll,
                        style: AppTheme.secondaryButtonStyle.copyWith(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.white,
                          ),
                        ),
                        child: Text(
                          'Clear All',
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _search,
                        style: AppTheme.primaryButtonStyle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Search Reports',
                              style: AppTheme.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _criteriaRow(_CriteriaConfig item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: checked[item.key],
              onChanged: (value) {
                setState(() {
                  checked[item.key] = value ?? false;
                });
              },
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryColor;
                }
                return Colors.white;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.label,
              style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: _criteriaField(
              controller: minCtrl[item.key]!,
              hintText: item.minHint,
              keyboardType: item.keyboardType,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _criteriaField(
              controller: maxCtrl[item.key]!,
              hintText: item.maxHint,
              keyboardType: item.keyboardType,
            ),
          ),
        ],
      ),
    );
  }

  Widget _criteriaField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: AppTheme.caption.copyWith(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildResultsPanel() {
    return Obx(() {
      final rows = _visibleRows;
      final selectedRow = _selectedVisibleRow(rows);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(rows.length, selectedRow),
          Expanded(
            child: rmC.isLoading.value
                ? _stateMessage(
                    icon: Icons.hourglass_top,
                    title: 'Loading reports',
                    message:
                        'Report Manager data is loading for the selected well.',
                    loading: true,
                  )
                : rmC.errorMessage.value.isNotEmpty
                ? _stateMessage(
                    icon: Icons.cloud_off,
                    title: 'Unable to load reports',
                    message: rmC.errorMessage.value,
                  )
                : rows.isEmpty
                ? _stateMessage(
                    icon: Icons.search_off,
                    title: hasSearched
                        ? 'No matching reports'
                        : 'No reports found',
                    message: hasSearched
                        ? 'Adjust the search criteria and try again.'
                        : 'Create reports for this well to populate Report Manager.',
                  )
                : Column(
                    children: [
                      Expanded(child: _buildResultsTable(rows)),
                      _buildSelectedDetails(selectedRow),
                    ],
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildResultsHeader(int visibleCount, ReportManagerRow? selectedRow) {
    final totalRows = rmC.rows.length;
    final countLabel = hasSearched
        ? '$visibleCount of $totalRows reports matched'
        : '$visibleCount reports available';

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.tableHeadColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Search Results',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              countLabel,
              style: AppTheme.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (selectedRow != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Selected: ${selectedRow.reportLabel}',
                style: AppTheme.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsTable(List<ReportManagerRow> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 38,
          dataRowMaxHeight: 38,
          dividerThickness: 0.5,
          headingRowColor: WidgetStateProperty.all(AppTheme.tableHeadColor),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.primaryColor.withValues(alpha: 0.1);
            }
            return null;
          }),
          columns: [
            _dataColumn('#'),
            _dataColumn('Date'),
            _dataColumn('Report No'),
            _dataColumn('MD (m)'),
            _dataColumn('Activity'),
            _dataColumn('Interval'),
            _dataColumn('Mud Type'),
            _dataColumn('MW (ppg)'),
            _dataColumn('Daily Cost'),
            _dataColumn('Cum. Cost'),
          ],
          rows: List.generate(rows.length, (index) {
            final row = rows[index];
            final isSelected = rmC.selectedReportId.value == row.reportId;

            return DataRow(
              selected: isSelected,
              onSelectChanged: (selected) {
                if (selected == true) {
                  rmC.selectRow(row.reportId);
                } else if (selected == false && isSelected) {
                  rmC.clearSelection();
                }
              },
              cells: [
                _textCell('${index + 1}', center: true, bold: true),
                _textCell(_displayDate(row.reportDate)),
                _textCell(row.reportLabel),
                _textCell(_formatNumber(row.md), alignRight: true),
                _textCell(row.activity),
                _textCell(row.interval),
                _textCell(row.mudType),
                _textCell(_formatNumber(row.mw), alignRight: true),
                _textCell(_formatCurrency(row.dailyCost), alignRight: true),
                _textCell(
                  _formatCurrency(row.cumulativeCost),
                  alignRight: true,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSelectedDetails(ReportManagerRow? row) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: row == null
            ? Text(
                'Select a report row to review recommended treatment, remarks, recap remarks, and internal notes.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Report ${row.reportLabel}',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          row.title.isEmpty ? 'Untitled report' : row.title,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailBlock(
                    title: 'Recommended Treatment',
                    value: row.recommendedTreatment,
                  ),
                  const SizedBox(height: 8),
                  _detailBlock(title: 'Remarks', value: row.remarks),
                  const SizedBox(height: 8),
                  _detailBlock(title: 'Recap Remarks', value: row.recapRemarks),
                  const SizedBox(height: 8),
                  _detailBlock(
                    title: 'Internal Notes',
                    value: row.internalNotes,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _detailBlock({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.trim().isEmpty ? '-' : value.trim(),
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Obx(() {
      final selectedRow = _selectedVisibleRow(_visibleRows);
      final isBusy = rmC.isLoading.value || rmC.isDeleting.value;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ElevatedButton.icon(
              onPressed: isBusy
                  ? null
                  : () async {
                      rmC.clearSelection();
                      await rmC.refreshRows();
                    },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: AppTheme.secondaryButtonStyle,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: selectedRow == null || isBusy ? null : _deleteRow,
              icon: rmC.isDeleting.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: selectedRow == null || isBusy ? null : _selectRow,
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Select'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      );
    });
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.tableHeadColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
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
              Icon(icon, size: 30, color: AppTheme.textSecondary),
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

  DataColumn _dataColumn(String label) {
    return DataColumn(
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Obx(
          () => Text(
            AppUnits.label(label),
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  DataCell _textCell(
    String value, {
    bool center = false,
    bool alignRight = false,
    bool bold = false,
  }) {
    final text = value.trim().isEmpty ? '-' : value.trim();

    return DataCell(
      Container(
        alignment: center
            ? Alignment.center
            : alignRight
            ? Alignment.centerRight
            : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.caption.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  List<ReportManagerRow> get _visibleRows {
    final source = rmC.rows.toList(growable: false);
    if (!hasSearched) return source;
    return source.where(_matchesAllEnabledCriteria).toList(growable: false);
  }

  bool _matchesAllEnabledCriteria(ReportManagerRow row) {
    for (final item in criteria) {
      final enabled = checked[item.key] ?? false;
      if (!enabled) continue;

      final minValue = minCtrl[item.key]!.text.trim();
      final maxValue = maxCtrl[item.key]!.text.trim();
      if (minValue.isEmpty && maxValue.isEmpty) continue;

      switch (item.kind) {
        case _CriteriaKind.number:
          final value = item.numericValue?.call(row);
          if (value == null) return false;
          final minNumber = double.tryParse(minValue);
          final maxNumber = double.tryParse(maxValue);
          if (minValue.isNotEmpty && minNumber == null) return false;
          if (maxValue.isNotEmpty && maxNumber == null) return false;
          if (minNumber != null && value < minNumber) return false;
          if (maxNumber != null && value > maxNumber) return false;
          break;
        case _CriteriaKind.date:
          final rowDate = _tryParseDate(item.textValue?.call(row) ?? '');
          if (rowDate == null) return false;
          final minDate = minValue.isEmpty ? null : _tryParseDate(minValue);
          final maxDate = maxValue.isEmpty ? null : _tryParseDate(maxValue);
          if (minValue.isNotEmpty && minDate == null) return false;
          if (maxValue.isNotEmpty && maxDate == null) return false;
          if (minDate != null && rowDate.isBefore(minDate)) return false;
          if (maxDate != null && rowDate.isAfter(maxDate)) return false;
          break;
        case _CriteriaKind.text:
          final haystack = (item.textValue?.call(row) ?? '').toLowerCase();
          if (minValue.isNotEmpty &&
              !haystack.contains(minValue.toLowerCase())) {
            return false;
          }
          if (maxValue.isNotEmpty &&
              !haystack.contains(maxValue.toLowerCase())) {
            return false;
          }
          break;
      }
    }

    return true;
  }

  ReportManagerRow? _selectedVisibleRow(List<ReportManagerRow> rows) {
    for (final row in rows) {
      if (row.reportId == rmC.selectedReportId.value) {
        return row;
      }
    }
    return null;
  }

  void _clearAll() {
    setState(() {
      for (final item in criteria) {
        checked[item.key] = false;
        minCtrl[item.key]!.clear();
        maxCtrl[item.key]!.clear();
      }
      hasSearched = false;
    });
    rmC.clearSelection();
  }

  void _search() {
    setState(() {
      hasSearched = true;
    });
    rmC.clearSelection();
  }

  Future<void> _deleteRow() async {
    final row = _selectedVisibleRow(_visibleRows);
    if (row == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Report'),
          content: Text(
            'Delete report ${row.reportLabel} for ${padWellC.selectedWellName}? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await rmC.deleteSelectedReport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report ${row.reportLabel} deleted.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _selectRow() async {
    final row = _selectedVisibleRow(_visibleRows);
    if (row == null) return;

    try {
      await rmC.activateSelectedReport();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  static String _displayDate(String value) {
    final parsed = _tryParseDate(value);
    if (parsed == null) {
      return value.trim().isEmpty ? '-' : value.trim();
    }
    return DateFormat('MM/dd/yyyy').format(parsed);
  }

  static String _formatNumber(double value) => value.toStringAsFixed(2);

  static String _formatCurrency(double value) =>
      '\$${value.toStringAsFixed(2)}';

  static DateTime? _tryParseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    for (final pattern in const ['MM/dd/yyyy', 'yyyy-MM-dd']) {
      try {
        return DateFormat(pattern).parseStrict(trimmed);
      } catch (_) {}
    }

    return DateTime.tryParse(trimmed);
  }
}

enum _CriteriaKind { text, number, date }

class _CriteriaConfig {
  final String key;
  final String label;
  final _CriteriaKind kind;
  final double? Function(ReportManagerRow row)? numericValue;
  final String Function(ReportManagerRow row)? textValue;

  const _CriteriaConfig({
    required this.key,
    required this.label,
    required this.kind,
    this.numericValue,
    this.textValue,
  });

  TextInputType get keyboardType {
    switch (kind) {
      case _CriteriaKind.number:
        return const TextInputType.numberWithOptions(decimal: true);
      case _CriteriaKind.date:
        return TextInputType.datetime;
      case _CriteriaKind.text:
        return TextInputType.text;
    }
  }

  String get minHint {
    switch (kind) {
      case _CriteriaKind.number:
        return 'Min';
      case _CriteriaKind.date:
        return 'From';
      case _CriteriaKind.text:
        return 'Contains';
    }
  }

  String get maxHint {
    switch (kind) {
      case _CriteriaKind.number:
        return 'Max';
      case _CriteriaKind.date:
        return 'To';
      case _CriteriaKind.text:
        return 'Also contains';
    }
  }
}

double? _reportNoValue(ReportManagerRow row) => double.tryParse(row.reportNo);

double? _mdValue(ReportManagerRow row) => row.md;

double? _mwValue(ReportManagerRow row) => row.mw;

String _dateValue(ReportManagerRow row) => row.reportDate;

String _recommendedTreatmentValue(ReportManagerRow row) =>
    row.recommendedTreatment;

String _remarksValue(ReportManagerRow row) => row.remarks;

String _recapRemarksValue(ReportManagerRow row) => row.recapRemarks;

String _internalNotesValue(ReportManagerRow row) => row.internalNotes;

String _cleanError(Object error) {
  return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
