import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
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
  final CompanyController companyC = Get.isRegistered<CompanyController>()
      ? Get.find<CompanyController>()
      : Get.put(CompanyController(), permanent: true);
  final DashboardController dashboardC = Get.find<DashboardController>();

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
      label: 'Depth (ft)',
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
      label: 'Recommended Tour Treatm...',
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
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: isSmallScreen ? constraints.maxWidth * 0.38 : 575,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: _buildSearchCriteria(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: _buildResultsPanel(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final selectedWellId = padWellC.selectedWellId.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MUDPRO+ - Report Manager',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 30,
                height: 30,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                  onPressed: dashboardC.closeOverlay,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: Text(
                  'Current Well',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 310,
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value:
                        padWellC.wells.any((well) => well.id == selectedWellId)
                        ? selectedWellId
                        : null,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textPrimary,
                    ),
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
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildSearchCriteria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text(
            'Search Criteria',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            children: [
              _criteriaHeaderCell('', width: 28),
              _criteriaHeaderCell('', width: 32),
              _criteriaHeaderCell('Variable', flex: 3),
              _criteriaHeaderCell('Min.', flex: 2),
              _criteriaHeaderCell('Max.', flex: 2),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: criteria.length,
            itemBuilder: (_, index) => _criteriaRow(index, criteria[index]),
          ),
        ),
      ],
    );
  }

  Widget _criteriaHeaderCell(String label, {double? width, int flex = 0}) {
    final child = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Text(
        label,
        style: AppTheme.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }

    return Expanded(flex: flex, child: child);
  }

  Widget _criteriaRow(int index, _CriteriaConfig item) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade400),
          right: BorderSide(color: Colors.grey.shade400),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Checkbox(
              visualDensity: VisualDensity.compact,
              value: checked[item.key],
              onChanged: (value) {
                setState(() {
                  checked[item.key] = value ?? false;
                });
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _criteriaLabel(item),
              style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: _criteriaField(
              controller: minCtrl[item.key]!,
              hintText: item.minHint,
              keyboardType: item.keyboardType,
            ),
          ),
          const SizedBox(width: 6),
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
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(rows.length),
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
                : !hasSearched
                ? _stateMessage(
                    icon: Icons.search,
                    title: 'Search reports',
                    message:
                        'Click Search to load all reports for the selected well.',
                  )
                : rows.isEmpty
                ? _stateMessage(
                    icon: Icons.search_off,
                    title: 'No matching reports',
                    message: 'Adjust the search criteria and try again.',
                  )
                : _buildResultsTable(rows),
          ),
        ],
      );
    });
  }

  Widget _buildResultsHeader(int visibleCount) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            'Result',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          if (hasSearched)
            Text(
              '$visibleCount report(s)',
              style: AppTheme.caption.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsTable(List<ReportManagerRow> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 30,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 32,
          dividerThickness: 0.5,
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.primaryColor.withValues(alpha: 0.1);
            }
            return Colors.white;
          }),
          columns: [
            _dataColumn('#'),
            _dataColumn('Date'),
            _dataColumn('Report No'),
            _dataColumn('MD (ft)'),
            _dataColumn('Activity'),
            _dataColumn('Interval'),
            _dataColumn('Mud Type'),
            _dataColumn('MW (ppg)'),
            _dataColumn('Daily Cost (${_currencyLabel()})'),
            _dataColumn('Cum. Cost (${_currencyLabel()})'),
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
                _textCell(row, '${index + 1}', center: true, bold: true),
                _textCell(row, _displayDate(row.reportDate)),
                _textCell(row, row.reportLabel),
                _textCell(row, _formatNumber(row.md), alignRight: true),
                _textCell(row, row.activity),
                _textCell(row, row.interval),
                _textCell(row, row.mudType),
                _textCell(row, _formatNumber(row.mw), alignRight: true),
                _textCell(
                  row,
                  _formatCurrency(row.dailyCost),
                  alignRight: true,
                ),
                _textCell(
                  row,
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

  Widget _buildActionButtons() {
    return Obx(() {
      final selectedRow = _selectedVisibleRow(_visibleRows);
      final isBusy = rmC.isLoading.value || rmC.isDeleting.value;

      return Row(
        children: [
          _actionButton(
            label: 'Clear All',
            width: 128,
            onPressed: isBusy ? null : _clearAll,
          ),
          const Spacer(),
          _actionButton(
            label: 'Search',
            width: 128,
            onPressed: isBusy ? null : _search,
          ),
          const Spacer(),
          _actionButton(
            label: 'Delete',
            width: 96,
            onPressed: selectedRow == null || isBusy ? null : _deleteRow,
            foreground: AppTheme.errorColor,
          ),
          const SizedBox(width: 8),
          _actionButton(
            label: 'Select',
            width: 96,
            onPressed: selectedRow == null || isBusy ? null : _selectRow,
          ),
          const SizedBox(width: 8),
          _actionButton(
            label: 'Close',
            width: 96,
            onPressed: isBusy ? null : dashboardC.closeOverlay,
          ),
        ],
      );
    });
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
    double width = 96,
    Color? foreground,
  }) {
    return SizedBox(
      width: width,
      height: 38,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground ?? AppTheme.textPrimary,
          side: BorderSide(color: Colors.grey.shade500),
          shape: const RoundedRectangleBorder(),
          backgroundColor: Colors.white,
        ),
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: onPressed == null
                ? Colors.grey
                : (foreground ?? AppTheme.textPrimary),
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Obx(
          () => Text(
            AppUnits.label(label),
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  DataCell _textCell(
    ReportManagerRow row,
    String value, {
    bool center = false,
    bool alignRight = false,
    bool bold = false,
  }) {
    final text = value.trim().isEmpty ? '-' : value.trim();

    return DataCell(
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => rmC.selectRow(row.reportId),
        onSecondaryTapDown: (details) => _openRowMenu(row, details),
        child: Container(
          alignment: center
              ? Alignment.center
              : alignRight
              ? Alignment.centerRight
              : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  List<ReportManagerRow> get _visibleRows {
    final source = rmC.rows.toList(growable: false);
    if (!hasSearched) return const <ReportManagerRow>[];
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

  Future<void> _search() async {
    await rmC.refreshRows();
    if (!mounted) return;
    setState(() {
      hasSearched = true;
    });
    rmC.clearSelection();
  }

  Future<void> _deleteRow() async {
    final row = _selectedVisibleRow(_visibleRows);
    if (row == null) return;
    await _deleteSpecificRow(row);
  }

  Future<void> _deleteSpecificRow(ReportManagerRow row) async {
    rmC.selectRow(row.reportId);

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

  Future<void> _openRowMenu(
    ReportManagerRow row,
    TapDownDetails details,
  ) async {
    rmC.selectRow(row.reportId);
    final action = await showMenu<_ReportRowAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(
          value: _ReportRowAction.select,
          child: Text('Select', style: TextStyle(fontSize: 11)),
        ),
        PopupMenuItem(
          value: _ReportRowAction.delete,
          child: Text('Delete', style: TextStyle(fontSize: 11)),
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ReportRowAction.select:
        await _selectRow();
        break;
      case _ReportRowAction.delete:
        await _deleteSpecificRow(row);
        break;
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

  String _formatCurrency(double value) =>
      '${_currencyLabel()}${value.toStringAsFixed(2)}';

  String _criteriaLabel(_CriteriaConfig item) {
    switch (item.key) {
      case 'md':
        return AppUnits.label('Depth (ft)');
      case 'mw':
        return AppUnits.label('MW (ppg)');
      default:
        return item.label;
    }
  }

  String _currencyLabel() {
    final raw = companyC.currencySymbol.value.trim();
    return raw.isEmpty ? '\$' : raw;
  }

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

enum _ReportRowAction { select, delete }

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
