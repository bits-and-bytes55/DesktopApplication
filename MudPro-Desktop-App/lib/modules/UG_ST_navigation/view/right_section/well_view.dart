import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class WellView extends StatefulWidget {
  const WellView({super.key});

  static final GlobalKey<_WellViewState> _viewKey = GlobalKey<_WellViewState>();
  static Key get mountKey => _viewKey;

  static Future<Map<String, dynamic>> saveActiveWell({
    bool showFeedback = false,
  }) async {
    final state = _viewKey.currentState;
    if (state == null) {
      return {'success': true, 'message': 'Well editor is not mounted.'};
    }

    return state._saveWell(showFeedback: showFeedback);
  }

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
  Timer? _autosaveTimer;
  Map<String, String>? _wellClipboard;

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
    _autosaveTimer?.cancel();
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

  Future<Map<String, dynamic>> _saveWell({
    bool showFeedback = true,
    bool syncAfterSave = true,
  }) async {
    if (_selectedPadId.isEmpty) {
      const message = 'Select a pad first.';
      if (showFeedback) {
        _showFeedback(message, isSuccess: false);
      }
      return {'success': false, 'message': message};
    }

    final wellName = _controllers['wellNameNo']!.text.trim();
    if (wellName.isEmpty) {
      const message = 'Well name is required.';
      if (showFeedback) {
        _showFeedback(message, isSuccess: false);
      }
      return {'success': false, 'message': message};
    }

    final payload = <String, dynamic>{
      'padId': _selectedPadId,
      for (final field in _wellFields)
        field.key: _controllers[field.key]!.text.trim(),
    };

    try {
      final result = await padWellC
          .updateSelectedWell(payload)
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              return {'success': false, 'message': 'Well save timed out (12s)'};
            },
          );
      if (syncAfterSave) {
        _loadSelectedWell();
      }
      final wellId = _extractEntityId(result['data']);
      if (wellId.isNotEmpty) {
        padWellC.selectWell(wellId);
        dashboardC?.navigate('well:$wellId');
      }
      final isSuccess = result['success'] == true;
      if (showFeedback) {
        _showFeedback(
          result['message']?.toString() ??
              (isSuccess ? 'Well saved successfully' : 'Well save failed'),
          isSuccess: isSuccess,
        );
      }
      return {
        'success': isSuccess,
        'message':
            result['message']?.toString() ??
            (isSuccess ? 'Well saved successfully' : 'Well save failed'),
        'data': result['data'],
      };
    } catch (e) {
      final message = _cleanError(e);
      if (showFeedback) {
        _showFeedback(message, isSuccess: false);
      }
      return {'success': false, 'message': message};
    }
  }

  void _scheduleAutosave() {
    if (ugStController.isLocked.value || _activeWell == null) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 900), () {
      _saveWell(showFeedback: false, syncAfterSave: false);
    });
  }

  Map<String, String> _currentFormValues() {
    return {
      for (final field in _wellFields)
        field.key: _controllers[field.key]!.text.trim(),
    };
  }

  bool get _hasAnyFormData =>
      _currentFormValues().values.any((value) => value.trim().isNotEmpty);

  Future<void> _showWellMenu(TapDownDetails details) async {
    final canEdit = !ugStController.isLocked.value;
    final hasWell = _activeWell != null;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'cut',
          enabled: false,
          child: _WellMenuRow(label: 'Cut', shortcut: 'Ctrl+X', enabled: false),
        ),
        PopupMenuItem<String>(
          value: 'copy',
          enabled: _hasAnyFormData,
          child: _WellMenuRow(
            label: 'Copy',
            shortcut: 'Ctrl+C',
            enabled: _hasAnyFormData,
          ),
        ),
        PopupMenuItem<String>(
          value: 'paste',
          enabled: canEdit && _wellClipboard != null,
          child: _WellMenuRow(
            label: 'Paste',
            shortcut: 'Ctrl+V',
            enabled: canEdit && _wellClipboard != null,
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          enabled: canEdit && hasWell,
          child: _WellMenuRow(
            label: 'Delete',
            shortcut: 'Delete',
            enabled: canEdit && hasWell,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'top',
          enabled: false,
          child: _WellMenuRow(
            label: 'To the Top',
            shortcut: 'Ctrl+Up',
            enabled: false,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'bottom',
          enabled: false,
          child: _WellMenuRow(
            label: 'To the Bottom',
            shortcut: 'Ctrl+Down',
            enabled: false,
          ),
        ),
      ],
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'copy':
        _wellClipboard = _currentFormValues();
        await Clipboard.setData(
          ClipboardData(text: _wellClipboard!.values.join('\n')),
        );
        break;
      case 'paste':
        if (_wellClipboard == null) return;
        for (final field in _wellFields) {
          _controllers[field.key]!.text = _wellClipboard![field.key] ?? '';
        }
        setState(() {});
        _scheduleAutosave();
        break;
      case 'delete':
        await _deleteWell();
        break;
    }
  }

  // ignore: unused_element
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
      final activePad = _selectedPadId.isEmpty
          ? null
          : _firstWhereOrNull(padWellC.pads, (pad) => pad.id == _selectedPadId);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 780,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClassicWellTable(isLocked: isLocked),
                  const SizedBox(height: 12),
                  _buildClassicMemoPanel(activePad?.memo ?? ''),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildClassicWellTable({required bool isLocked}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: _showWellMenu,
      child: Container(
        width: 604,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFBFC4CC)),
        ),
        child: Table(
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFD4D8DE)),
            verticalInside: BorderSide(color: Color(0xFFD4D8DE)),
          ),
          columnWidths: const {
            0: FixedColumnWidth(360),
            1: FixedColumnWidth(152),
            2: FixedColumnWidth(90),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            for (final field in _wellFields)
              _buildClassicFieldRow(
                field: field,
                isLocked: isLocked,
                valueController: _controllers[field.key]!,
              ),
          ],
        ),
      ),
    );
  }

  TableRow _buildClassicFieldRow({
    required _WellField field,
    required bool isLocked,
    required TextEditingController valueController,
  }) {
    return TableRow(
      children: [
        _classicLabelCell(field.label),
        _classicValueCell(
          controller: valueController,
          readOnly: isLocked,
          hint: field.hint,
        ),
        _classicUnitCell(field.unit),
      ],
    );
  }

  Widget _classicLabelCell(String text) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
      ),
    );
  }

  Widget _classicValueCell({
    required TextEditingController controller,
    required bool readOnly,
    required String hint,
  }) {
    return Container(
      height: 31,
      color: const Color(0xFFFFF6C7),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onChanged: (_) => _scheduleAutosave(),
        style: const TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _classicUnitCell(String unit) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: Text(
        unit,
        style: const TextStyle(fontSize: 10, color: Color(0xFF4A4F57)),
      ),
    );
  }

  Widget _buildClassicMemoPanel(String memoText) {
    return SizedBox(
      width: 724,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              'Memo',
              style: TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
            ),
          ),
          Container(
            height: 208,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFBFC4CC)),
            ),
            child: Scrollbar(
              controller: _tableScrollCtrl,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _tableScrollCtrl,
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    memoText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2F2F2F),
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

class _WellMenuRow extends StatelessWidget {
  final String label;
  final String shortcut;
  final bool enabled;

  const _WellMenuRow({
    required this.label,
    required this.shortcut,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF2F2F2F) : const Color(0xFF9EA4AD);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(width: 20),
        Text(shortcut, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
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
  final String unit;

  const _WellField({
    required this.key,
    required this.label,
    required this.hint,
    this.unit = '',
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
  _WellField(key: 'kop', label: 'KOP', hint: 'Enter KOP', unit: '(ft)'),
  _WellField(key: 'lp', label: 'LP', hint: 'Enter LP', unit: '(ft)'),
  _WellField(
    key: 'bulkTankSetupFee',
    label: 'Bulk Tank Setup Fee',
    hint: 'Enter bulk tank setup fee',
    unit: '(Kwd)',
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
