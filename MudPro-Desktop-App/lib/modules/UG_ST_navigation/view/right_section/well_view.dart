import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class WellView extends StatefulWidget {
  const WellView({super.key});

  @override
  State<WellView> createState() => _WellViewState();
}

class _WellViewState extends State<WellView> {
  final UgStController ugStController = Get.find<UgStController>();
  final PadWellController padWellC = padWellContext;
  final DashboardController? dashboardC =
      Get.isRegistered<DashboardController>()
      ? Get.find<DashboardController>()
      : null;

  final ScrollController _tableScrollCtrl = ScrollController();
  Worker? _wellWorker;
  String _selectedPadId = '';

  late final Map<String, TextEditingController> _controllers = {
    for (final field in _wellFields) field.key: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadSelectedWell();
    _wellWorker = ever<String>(padWellC.selectedWellId, (_) {
      if (mounted) {
        _loadSelectedWell();
      }
    });
  }

  @override
  void dispose() {
    _wellWorker?.dispose();
    _tableScrollCtrl.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AppWell? get _activeWell => padWellC.selectedWell;

  void _loadSelectedWell() {
    final well = padWellC.selectedWell;
    if (well == null) {
      _clearFields();
      setState(() {
        _selectedPadId = padWellC.selectedPadId.value;
      });
      return;
    }

    for (final field in _wellFields) {
      _controllers[field.key]!.text = _wellValue(well, field.key);
    }

    setState(() {
      _selectedPadId = well.padId;
    });
  }

  void _clearFields() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  Future<void> _saveWell() async {
    if (_selectedPadId.isEmpty) {
      _showFeedback('Select a pad first.', isSuccess: false);
      return;
    }

    final wellName = _controllers['wellNameNo']!.text.trim();
    if (wellName.isEmpty) {
      _showFeedback('Well name is required.', isSuccess: false);
      return;
    }

    final payload = <String, dynamic>{
      'padId': _selectedPadId,
      for (final field in _wellFields)
        field.key: _controllers[field.key]!.text.trim(),
    };

    try {
      final result = await padWellC.updateSelectedWell(payload);
      _loadSelectedWell();
      final wellId = _extractEntityId(result['data']);
      if (wellId.isNotEmpty) {
        padWellC.selectWell(wellId);
        dashboardC?.navigate('well:$wellId');
      }
      _showFeedback(result['message']?.toString() ?? 'Well saved successfully');
    } catch (e) {
      _showFeedback(_cleanError(e), isSuccess: false);
    }
  }

  Future<void> _deleteWell() async {
    final activeWell = _activeWell;
    if (activeWell == null) {
      _showFeedback('No well selected.', isSuccess: false);
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Well'),
        content: Text('Delete "${activeWell.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await padWellC.deleteSelectedWell();
      _loadSelectedWell();
      _showFeedback(
        result['message']?.toString() ?? 'Well deleted successfully',
      );
    } catch (e) {
      _showFeedback(_cleanError(e), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLocked = ugStController.isLocked.value;
      final activeWell = _activeWell;
      final activePad = _selectedPadId.isEmpty
          ? null
          : _firstWhereOrNull(padWellC.pads, (pad) => pad.id == _selectedPadId);
      final siblingWells = activePad == null
          ? const <AppWell>[]
          : padWellC.wellsForPad(activePad.id);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 760,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildHeader(
                        title: activeWell?.displayName ?? 'Well Information',
                        subtitle: activeWell == null
                            ? 'Create a well from the top toolbar + button after pad setup is complete'
                            : 'Selected well data from backend',
                        isLocked: isLocked,
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: Scrollbar(
                          controller: _tableScrollCtrl,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _tableScrollCtrl,
                            padding: const EdgeInsets.all(12),
                            child: Table(
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                                verticalInside: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              columnWidths: const {0: FixedColumnWidth(240)},
                              children: [
                                _buildPadRow(isLocked),
                                for (final field in _wellFields)
                                  _buildFieldRow(field, isLocked),
                                _buildReadOnlyRow(
                                  'Operator',
                                  activePad?.operator ?? '',
                                ),
                                _buildReadOnlyRow('Rig', activePad?.rig ?? ''),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildWellSummaryCard(activeWell, activePad),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPadWellsCard(siblingWells)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
    required bool isLocked,
  }) {
    final canEdit = !isLocked;
    final hasExistingWell = _activeWell != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.oil_barrel, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          _headerButton(
            icon: Icons.refresh,
            tooltip: 'Reload wells',
            onTap: padWellC.reloadData,
          ),
          const SizedBox(width: 6),
          _headerButton(
            icon: Icons.save,
            tooltip: 'Save well',
            onTap: canEdit && hasExistingWell ? _saveWell : null,
          ),
          const SizedBox(width: 6),
          _headerButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete well',
            onTap: canEdit && hasExistingWell ? _deleteWell : null,
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: onTap == null
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Icon(
            icon,
            size: 15,
            color: onTap == null ? Colors.white54 : Colors.white,
          ),
        ),
      ),
    );
  }

  TableRow _buildPadRow(bool isLocked) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xfff8f9fa)),
      children: [
        _labelCell('Pad'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: isLocked
              ? Text(
                  padWellC.selectedPadName.isEmpty
                      ? '-'
                      : padWellC.selectedPadName,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedPadId.isEmpty ? null : _selectedPadId,
                  isExpanded: true,
                  items: padWellC.pads
                      .map(
                        (pad) => DropdownMenuItem<String>(
                          value: pad.id,
                          child: Text(
                            pad.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedPadId = value;
                    });
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  TableRow _buildFieldRow(_WellField field, bool isLocked) {
    final controller = _controllers[field.key]!;
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _labelCell(field.label),
        isLocked
            ? _readOnlyValueCell(controller.text)
            : _editableValueCell(controller, field.hint),
      ],
    );
  }

  TableRow _buildReadOnlyRow(String label, String value) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xfffcfcfc)),
      children: [_labelCell(label), _readOnlyValueCell(value)],
    );
  }

  Widget _labelCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xfff8f9fa),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _readOnlyValueCell(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        value.isEmpty ? '-' : value,
        style: AppTheme.bodySmall.copyWith(
          color: value.isEmpty ? Colors.grey.shade400 : AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _editableValueCell(TextEditingController controller, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: controller,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTheme.caption.copyWith(color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildWellSummaryCard(AppWell? well, AppPad? pad) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Well Summary',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Well', well?.displayName ?? '-'),
          _summaryRow(
            'API',
            well?.apiWellNo ?? _controllers['apiWellNo']!.text,
          ),
          _summaryRow('Pad', pad?.displayName ?? '-'),
          _summaryRow('Operator', pad?.operator ?? '-'),
          _summaryRow('Rig', pad?.rig ?? '-'),
          _summaryRow(
            'Spud Date',
            well?.spudDate ?? _controllers['spudDate']!.text,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPadWellsCard(List<AppWell> wells) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffF8FAFC), Color(0xffEEF2F7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Other Wells In Pad',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (wells.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No wells found for this pad.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.all(10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wells.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final well = wells[index];
                final selected = padWellC.selectedWellId.value == well.id;
                return InkWell(
                  onTap: () {
                    padWellC.selectWell(well.id);
                    dashboardC?.navigate('well:${well.id}');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor.withValues(alpha: 0.12)
                          : const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primaryColor.withValues(alpha: 0.3)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            well.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodySmall.copyWith(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showFeedback(String message, {bool isSuccess = true}) {
    Get.snackbar(
      isSuccess ? 'Success' : 'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isSuccess ? AppTheme.successColor : AppTheme.errorColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

String _wellValue(AppWell well, String key) {
  switch (key) {
    case 'wellNameNo':
      return well.wellNameNo;
    case 'apiWellNo':
      return well.apiWellNo;
    case 'spudDate':
      return well.spudDate;
    case 'sectionTownshipRange':
      return well.sectionTownshipRange;
    case 'longitude':
      return well.longitude;
    case 'latitude':
      return well.latitude;
    case 'kop':
      return well.kop;
    case 'lp':
      return well.lp;
    case 'bulkTankSetupFee':
      return well.bulkTankSetupFee;
    default:
      return '';
  }
}

class _WellField {
  final String key;
  final String label;
  final String hint;

  const _WellField({
    required this.key,
    required this.label,
    required this.hint,
  });
}

const List<_WellField> _wellFields = [
  _WellField(
    key: 'wellNameNo',
    label: 'Well Name/No.',
    hint: 'Enter well name',
  ),
  _WellField(
    key: 'apiWellNo',
    label: 'API Well No.',
    hint: 'Enter API well number',
  ),
  _WellField(key: 'spudDate', label: 'Spud Date', hint: 'Enter spud date'),
  _WellField(
    key: 'sectionTownshipRange',
    label: 'Section/Township/Range',
    hint: 'Enter section/township/range',
  ),
  _WellField(key: 'longitude', label: 'Longitude', hint: 'Enter longitude'),
  _WellField(key: 'latitude', label: 'Latitude', hint: 'Enter latitude'),
  _WellField(key: 'kop', label: 'KOP', hint: 'Enter KOP'),
  _WellField(key: 'lp', label: 'LP', hint: 'Enter LP'),
  _WellField(
    key: 'bulkTankSetupFee',
    label: 'Bulk Tank Setup Fee',
    hint: 'Enter bulk tank setup fee',
  ),
];

String _extractEntityId(dynamic data) {
  if (data is Map<String, dynamic>) {
    return (data['_id'] ?? data['id'] ?? '').toString();
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    return (map['_id'] ?? map['id'] ?? '').toString();
  }
  return '';
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
