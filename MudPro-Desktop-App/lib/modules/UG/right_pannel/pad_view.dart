import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PadView extends StatefulWidget {
  const PadView({super.key});

  @override
  State<PadView> createState() => _PadViewState();
}

class _PadViewState extends State<PadView> {
  final UgController ugController = Get.find<UgController>();
  final PadWellController padWellC = padWellContext;
  final DashboardController? dashboardC = Get.isRegistered<DashboardController>()
      ? Get.find<DashboardController>()
      : null;

  final ScrollController _tableScrollController = ScrollController();
  Worker? _padWorker;
  bool _isCreatingNewPad = false;
  String _locationType = 'Land';

  late final Map<String, TextEditingController> _controllers = {
    for (final field in _padFields) field.key: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadSelectedPad();
    _padWorker = ever<String>(padWellC.selectedPadId, (_) {
      if (!_isCreatingNewPad && mounted) {
        _loadSelectedPad();
      }
    });
  }

  @override
  void dispose() {
    _padWorker?.dispose();
    _tableScrollController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AppPad? get _activePad => _isCreatingNewPad ? null : padWellC.selectedPad;

  void _loadSelectedPad() {
    final pad = padWellC.selectedPad;
    if (pad == null) {
      _clearFields();
      setState(() {
        _locationType = 'Land';
      });
      return;
    }

    for (final field in _padFields) {
      _controllers[field.key]!.text = _padValue(pad, field.key);
    }

    setState(() {
      _locationType = pad.locationType.isEmpty ? 'Land' : pad.locationType;
      ugController.location.value = _locationType;
    });
  }

  void _clearFields() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  void _startNewPad() {
    _clearFields();
    setState(() {
      _isCreatingNewPad = true;
      _locationType = 'Land';
      ugController.location.value = _locationType;
    });
  }

  void _cancelNewPad() {
    setState(() {
      _isCreatingNewPad = false;
    });
    _loadSelectedPad();
  }

  Future<void> _savePad() async {
    final payload = <String, dynamic>{
      'locationType': _locationType,
      for (final field in _padFields)
        field.key: _controllers[field.key]!.text.trim(),
    };

    if (!_hasMeaningfulData(payload)) {
      _showFeedback('Enter pad details before saving.', isSuccess: false);
      return;
    }

    try {
      final result = _isCreatingNewPad
          ? await padWellC.createPad(payload)
          : await padWellC.updateSelectedPad(payload);
      setState(() {
        _isCreatingNewPad = false;
      });
      _loadSelectedPad();
      _showFeedback(result['message']?.toString() ?? 'Pad saved successfully');
    } catch (e) {
      _showFeedback(_cleanError(e), isSuccess: false);
    }
  }

  Future<void> _deletePad() async {
    final activePad = _activePad;
    if (activePad == null) {
      _showFeedback('No pad selected.', isSuccess: false);
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Pad'),
        content: Text(
          'Delete "${activePad.displayName}"? Linked wells must be removed first.',
        ),
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
      final result = await padWellC.deleteSelectedPad();
      _loadSelectedPad();
      _showFeedback(
        result['message']?.toString() ?? 'Pad deleted successfully',
      );
    } catch (e) {
      _showFeedback(_cleanError(e), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLocked = ugController.isLocked.value;
      final activePad = _activePad;
      final wells = activePad == null ? const <AppWell>[] : padWellC.wellsForPad(activePad.id);

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      title: _isCreatingNewPad
                          ? 'Create Pad'
                          : (activePad?.displayName ?? 'Pad Details'),
                      subtitle: _isCreatingNewPad
                          ? 'Enter pad information and save'
                          : 'Selected pad data from backend',
                      isLocked: isLocked,
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _tableScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _tableScrollController,
                          padding: const EdgeInsets.all(12),
                          child: Table(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                              verticalInside: BorderSide(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            columnWidths: const {0: FixedColumnWidth(220)},
                            children: [
                              _buildLocationRow(isLocked),
                              for (final field in _padFields)
                                _buildFieldRow(field, isLocked),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildSummaryCard(activePad, wells),
                  const SizedBox(height: 12),
                  _buildWellsCard(wells),
                ],
              ),
            ),
          ],
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
    final hasExistingPad = _activePad != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                tooltip: 'Reload pads',
                onTap: padWellC.reloadData,
              ),
              const SizedBox(width: 6),
              _headerButton(
                icon: _isCreatingNewPad ? Icons.close : Icons.add,
                tooltip: _isCreatingNewPad ? 'Cancel new pad' : 'Create pad',
                onTap: canEdit ? (_isCreatingNewPad ? _cancelNewPad : _startNewPad) : null,
              ),
              const SizedBox(width: 6),
              _headerButton(
                icon: Icons.save,
                tooltip: _isCreatingNewPad ? 'Create pad' : 'Save pad',
                onTap: canEdit ? _savePad : null,
              ),
              const SizedBox(width: 6),
              _headerButton(
                icon: Icons.delete_outline,
                tooltip: 'Delete pad',
                onTap: canEdit && hasExistingPad && !_isCreatingNewPad ? _deletePad : null,
              ),
            ],
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

  TableRow _buildLocationRow(bool isLocked) {
    final enabled = !isLocked;
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xfff8f9fa)),
      children: [
        _labelCell('Location'),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _radioOption('Land', enabled),
              const SizedBox(width: 20),
              _radioOption('Offshore', enabled),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildFieldRow(_PadField field, bool isLocked) {
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

  Widget _labelCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fa),
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _readOnlyValueCell(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        value.isEmpty ? '-' : value,
        style: TextStyle(
          fontSize: 11,
          color: value.isEmpty ? Colors.grey.shade400 : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _editableValueCell(
    TextEditingController controller,
    String hint,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        ),
      ),
    );
  }

  Widget _radioOption(String value, bool enabled) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white.withOpacity(0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _locationType,
            onChanged: enabled
                ? (next) {
                    if (next == null) return;
                    setState(() {
                      _locationType = next;
                      ugController.location.value = next;
                    });
                  }
                : null,
            visualDensity: VisualDensity.compact,
            activeColor: Colors.white,
            fillColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => states.contains(WidgetState.disabled)
                  ? Colors.white54
                  : Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppPad? pad, List<AppWell> wells) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Pad Summary',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Name', _isCreatingNewPad ? 'New pad' : (pad?.displayName ?? '-')),
          _summaryRow('Operator', pad?.operator ?? '-'),
          _summaryRow('Rig', pad?.rig ?? '-'),
          _summaryRow('Country', pad?.country ?? '-'),
          _summaryRow('Location', _locationType),
          _summaryRow('Linked Wells', '${wells.length}'),
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

  Widget _buildWellsCard(List<AppWell> wells) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  Icon(Icons.location_on, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Wells Under This Pad',
                    style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: wells.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _isCreatingNewPad
                              ? 'Save the pad first, then create wells.'
                              : 'No wells linked to this pad yet.',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(10),
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
            ),
          ],
        ),
      ),
    );
  }

  bool _hasMeaningfulData(Map<String, dynamic> payload) {
    return payload.entries.any((entry) {
      if (entry.key == 'locationType') return false;
      return entry.value.toString().trim().isNotEmpty;
    });
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
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
}

String _padValue(AppPad pad, String key) {
  switch (key) {
    case 'fieldBlock':
      return pad.fieldBlock;
    case 'rig':
      return pad.rig;
    case 'countyParishOffshoreArea':
      return pad.countyParishOffshoreArea;
    case 'stateProvince':
      return pad.stateProvince;
    case 'country':
      return pad.country;
    case 'stockPoint':
      return pad.stockPoint;
    case 'phone':
      return pad.phone;
    case 'operator':
      return pad.operator;
    case 'operatorRep':
      return pad.operatorRep;
    case 'contractor':
      return pad.contractor;
    case 'contractorRep':
      return pad.contractorRep;
    case 'sl':
      return pad.sl;
    case 'airGap':
      return pad.airGap;
    case 'waterDepth':
      return pad.waterDepth;
    case 'riserOD':
      return pad.riserOD;
    case 'riserID':
      return pad.riserID;
    case 'chokeLineID':
      return pad.chokeLineID;
    case 'killLineID':
      return pad.killLineID;
    case 'boostLineID':
      return pad.boostLineID;
    default:
      return '';
  }
}

class _PadField {
  final String key;
  final String label;
  final String hint;

  const _PadField({
    required this.key,
    required this.label,
    required this.hint,
  });
}

const List<_PadField> _padFields = [
  _PadField(key: 'fieldBlock', label: 'Field/Block', hint: 'Enter field/block'),
  _PadField(key: 'rig', label: 'Rig', hint: 'Enter rig'),
  _PadField(
    key: 'countyParishOffshoreArea',
    label: 'County/Parish/Offshore Area',
    hint: 'Enter county/parish/offshore area',
  ),
  _PadField(
    key: 'stateProvince',
    label: 'State/Province',
    hint: 'Enter state or province',
  ),
  _PadField(key: 'country', label: 'Country', hint: 'Enter country'),
  _PadField(key: 'stockPoint', label: 'Stock Point', hint: 'Enter stock point'),
  _PadField(key: 'phone', label: 'Phone', hint: 'Enter phone'),
  _PadField(key: 'operator', label: 'Operator', hint: 'Enter operator'),
  _PadField(key: 'operatorRep', label: 'Operator Rep.', hint: 'Enter operator representative'),
  _PadField(key: 'contractor', label: 'Contractor', hint: 'Enter contractor'),
  _PadField(
    key: 'contractorRep',
    label: 'Contractor Rep.',
    hint: 'Enter contractor representative',
  ),
  _PadField(key: 'sl', label: 'SL', hint: 'Enter SL'),
  _PadField(key: 'airGap', label: 'Air Gap', hint: 'Enter air gap'),
  _PadField(key: 'waterDepth', label: 'Water Depth', hint: 'Enter water depth'),
  _PadField(key: 'riserOD', label: 'Riser OD', hint: 'Enter riser OD'),
  _PadField(key: 'riserID', label: 'Riser ID', hint: 'Enter riser ID'),
  _PadField(key: 'chokeLineID', label: 'Choke Line ID', hint: 'Enter choke line ID'),
  _PadField(key: 'killLineID', label: 'Kill Line ID', hint: 'Enter kill line ID'),
  _PadField(key: 'boostLineID', label: 'Boost Line ID', hint: 'Enter boost line ID'),
];
