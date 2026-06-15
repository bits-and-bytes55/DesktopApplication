import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
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
  final DashboardController dashboardController =
      Get.find<DashboardController>();
  final PadWellController padWellC = padWellContext;

  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _memoScrollController = ScrollController();
  final FocusNode _logoFocusNode = FocusNode(debugLabel: 'pad-client-logo');

  Worker? _padWorker;
  Worker? _newPadRequestWorker;
  final List<Worker> _unitWorkers = <Worker>[];
  bool _isCreatingNewPad = false;
  bool _isLogoDragging = false;
  String _locationType = 'Land';
  late String _lengthUnit;
  late String _diameterUnit;

  late final Map<String, TextEditingController> _controllers = {
    for (final field in _padFields) field.key: TextEditingController(),
  };
  final TextEditingController _memoController = TextEditingController();
  String _clientLogoUrl = '';
  String _clientLogoBase64 = '';
  String _pendingClientLogoPin = '';

  @override
  void initState() {
    super.initState();
    _lengthUnit = AppUnits.length;
    _diameterUnit = AppUnits.diameter;
    _loadSelectedPad();
    _padWorker = ever<String>(padWellC.selectedPadId, (_) {
      if (!_isCreatingNewPad && mounted) {
        _loadSelectedPad();
      }
    });
    _newPadRequestWorker = ever<int>(dashboardController.newPadRequestToken, (
      token,
    ) {
      if (token <= 0 || !mounted) return;
      _startNewPad();
      dashboardController.consumeNewPadRequest();
    });
    if (dashboardController.newPadRequestToken.value > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || dashboardController.newPadRequestToken.value <= 0) {
          return;
        }
        _startNewPad();
        dashboardController.consumeNewPadRequest();
      });
    }
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
  }

  @override
  void dispose() {
    _padWorker?.dispose();
    _newPadRequestWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    _leftScrollController.dispose();
    _memoScrollController.dispose();
    _logoFocusNode.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _memoController.dispose();
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
      _controllers[field.key]!.text = _displayFieldValue(
        _padValue(pad, field.key),
        field.unit,
      );
    }
    _memoController.text = pad.memo;
    _clientLogoUrl = pad.clientLogoUrl;
    _clientLogoBase64 = '';
    _pendingClientLogoPin = '';

    setState(() {
      _locationType = pad.locationType.isEmpty ? 'Land' : pad.locationType;
      ugController.location.value = _locationType;
    });
  }

  void _clearFields() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
    _memoController.clear();
    _clientLogoUrl = '';
    _clientLogoBase64 = '';
    _pendingClientLogoPin = '';
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

  void _handleUnitChange() {
    final nextLengthUnit = AppUnits.length;
    final nextDiameterUnit = AppUnits.diameter;
    if (_lengthUnit == nextLengthUnit && _diameterUnit == nextDiameterUnit) {
      return;
    }

    for (final field in _padFields) {
      final controller = _controllers[field.key]!;
      if (_isLengthUnit(field.unit)) {
        controller.text = _convertText(
          controller.text,
          _lengthUnit,
          nextLengthUnit,
        );
      } else if (_isDiameterUnit(field.unit)) {
        controller.text = _convertText(
          controller.text,
          _diameterUnit,
          nextDiameterUnit,
        );
      }
    }
    _lengthUnit = nextLengthUnit;
    _diameterUnit = nextDiameterUnit;
    if (mounted) setState(() {});
  }

  bool _isLengthUnit(String unit) =>
      unit.trim().isNotEmpty && AppUnits.unitText(unit) == AppUnits.length;

  bool _isDiameterUnit(String unit) =>
      unit.trim().isNotEmpty && AppUnits.unitText(unit) == AppUnits.diameter;

  String _displayFieldValue(String value, String baseUnit) {
    if (_isLengthUnit(baseUnit)) {
      return _convertText(value, baseUnit, _lengthUnit);
    }
    if (_isDiameterUnit(baseUnit)) {
      return _convertText(value, baseUnit, _diameterUnit);
    }
    return value;
  }

  String _storeFieldValue(String value, String baseUnit) {
    if (_isLengthUnit(baseUnit)) {
      return _convertText(value, _lengthUnit, baseUnit);
    }
    if (_isDiameterUnit(baseUnit)) {
      return _convertText(value, _diameterUnit, baseUnit);
    }
    return value;
  }

  String _displayUnit(String unit) =>
      unit.trim().isEmpty ? unit : AppUnits.unitText(unit);

  String _convertText(String rawValue, String fromUnit, String toUnit) {
    if (rawValue.trim().isEmpty || fromUnit == toUnit) return rawValue;
    final parsed = double.tryParse(rawValue.replaceAll(',', '').trim());
    if (parsed == null) return rawValue;
    final converted = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (converted == null) return rawValue;
    return converted
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _savePad() async {
    final payload = <String, dynamic>{
      'locationType': _locationType,
      'memo': _memoController.text.trim(),
      for (final field in _padFields)
        field.key: _storeFieldValue(
          _controllers[field.key]!.text.trim(),
          field.unit,
        ),
    };

    if (_clientLogoBase64.isNotEmpty) {
      payload['clientLogoBase64'] = _clientLogoBase64;
      if (_pendingClientLogoPin.isNotEmpty) {
        payload['clientLogoPin'] = _pendingClientLogoPin;
      }
    }

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

  Future<void> _pickClientLogo() async {
    if (!await _ensureLogoChangeAllowed()) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes == null || bytes.isEmpty) return;

    _setClientLogoBytes(bytes, file?.extension ?? 'png');
  }

  Future<void> _pasteClientLogo() async {
    if (!await _ensureLogoChangeAllowed()) return;

    final path = await _clipboardImagePath();
    if (path.isEmpty) {
      _showFeedback('Copy an image file first, then paste here.', isSuccess: false);
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      _showFeedback('Copied image file was not found.', isSuccess: false);
      return;
    }

    final ext = path.split('.').last.toLowerCase();
    if (!_isSupportedImageExtension(ext)) {
      _showFeedback('Only PNG, JPG, JPEG, or WEBP images are supported.', isSuccess: false);
      return;
    }

    _setClientLogoBytes(await file.readAsBytes(), ext);
  }

  Future<void> _dropClientLogo(DropDoneDetails detail) async {
    if (detail.files.isEmpty) return;
    if (!await _ensureLogoChangeAllowed()) return;

    final file = detail.files.first;
    final name = file.name.isNotEmpty ? file.name : file.path;
    final ext = name.split('.').last.toLowerCase();
    if (!_isSupportedImageExtension(ext)) {
      _showFeedback('Only PNG, JPG, JPEG, or WEBP images are supported.', isSuccess: false);
      return;
    }

    _setClientLogoBytes(await file.readAsBytes(), ext);
  }

  Future<String> _clipboardImagePath() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          r'$files=Get-Clipboard -Format FileDropList; if($files){$files | Select-Object -First 1 -ExpandProperty FullName}',
        ]);
        final path = result.stdout.toString().trim().split(RegExp(r'\r?\n')).first.trim();
        if (path.isNotEmpty) return path;
      }
    } catch (_) {
      // Fall back to text clipboard below.
    }

    final textData = await Clipboard.getData(Clipboard.kTextPlain);
    return textData?.text?.trim().replaceAll('"', '') ?? '';
  }

  bool _isSupportedImageExtension(String ext) {
    return const {'png', 'jpg', 'jpeg', 'webp'}.contains(ext.toLowerCase());
  }

  void _setClientLogoBytes(Uint8List bytes, String extension) {
    final ext = extension.toLowerCase() == 'jpeg'
        ? 'jpg'
        : extension.toLowerCase();
    final mime = ext == 'webp' ? 'webp' : (ext == 'png' ? 'png' : 'jpeg');
    setState(() {
      _clientLogoBase64 = 'data:image/$mime;base64,${base64Encode(bytes)}';
      _clientLogoUrl = _clientLogoBase64;
    });
  }

  Future<bool> _ensureLogoChangeAllowed() async {
    if (ugController.isLocked.value) return false;
    final activePad = _activePad;
    final savedPin = activePad?.clientLogoPin ?? '';

    if (savedPin.isEmpty && _pendingClientLogoPin.isEmpty) {
      final pin = await _askLogoPin(
        title: 'Set Logo PIN',
        label: 'New PIN',
      );
      if (pin == null || pin.trim().isEmpty) return false;
      _pendingClientLogoPin = pin.trim();
      return true;
    }

    if (savedPin.isEmpty) return true;

    final enteredPin = await _askLogoPin(
      title: 'Logo PIN',
      label: 'Enter PIN',
    );
    if (enteredPin == null) return false;
    if (enteredPin.trim() != savedPin) {
      _showFeedback('Invalid PIN.', isSuccess: false);
      return false;
    }
    return true;
  }

  Future<String?> _askLogoPin({
    required String title,
    required String label,
  }) {
    final controller = TextEditingController();
    return Get.dialog<String>(
      AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 280,
          child: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => Get.back(result: controller.text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLocked = ugController.isLocked.value;
      final activePad = _activePad;
      final wells = activePad == null
          ? const <AppWell>[]
          : padWellC.wellsForPad(activePad.id);

      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          children: [
            _buildActionStrip(isLocked, activePad, wells.length),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1180;
                  final leftWidth = compact
                      ? constraints.maxWidth * 0.54
                      : constraints.maxWidth * 0.51;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: leftWidth,
                        child: _buildLeftPanel(isLocked),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRightPanel(
                          isLocked: isLocked,
                          activePad: activePad,
                          linkedWellCount: wells.length,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionStrip(bool isLocked, AppPad? activePad, int wellCount) {
    final canEdit = !isLocked;
    final hasExistingPad = activePad != null;

    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Text(
            _isCreatingNewPad ? 'Pad - New Pad' : 'Pad',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2F2F2F),
            ),
          ),
          const Spacer(),
          if (!_isCreatingNewPad && activePad != null)
            Text(
              '${activePad.displayName}  |  Wells: $wellCount',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF5F6B7A)),
            ),
          if (!_isCreatingNewPad && activePad != null)
            const SizedBox(width: 12),
          _stripButton(
            icon: Icons.refresh,
            tooltip: 'Reload pads',
            onTap: padWellC.reloadData,
          ),
          const SizedBox(width: 4),
          _stripButton(
            icon: _isCreatingNewPad ? Icons.close : Icons.add,
            tooltip: _isCreatingNewPad
                ? 'Cancel new pad'
                : 'Use New Pad from the left panel',
            onTap: canEdit && _isCreatingNewPad ? _cancelNewPad : null,
          ),
          const SizedBox(width: 4),
          _stripButton(
            icon: Icons.save_outlined,
            tooltip: _isCreatingNewPad ? 'Create pad' : 'Save pad',
            onTap: canEdit ? _savePad : null,
          ),
          const SizedBox(width: 4),
          _stripButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete pad',
            onTap: canEdit && hasExistingPad && !_isCreatingNewPad
                ? _deletePad
                : null,
          ),
        ],
      ),
    );
  }

  Widget _stripButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(
              color: onTap == null
                  ? const Color(0xFFE2E5E9)
                  : const Color(0xFFC9CDD3),
            ),
            color: Colors.white,
          ),
          child: Icon(
            icon,
            size: 15,
            color: onTap == null
                ? const Color(0xFFB6BDC7)
                : const Color(0xFF2E74C9),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(bool isLocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationBar(isLocked),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC9CDD3)),
              color: Colors.white,
            ),
            child: Scrollbar(
              controller: _leftScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _leftScrollController,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final labelWidth = constraints.maxWidth > 650
                        ? 360.0
                        : constraints.maxWidth * 0.54;
                    final unitWidth = 88.0;

                    return Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder.all(
                        color: const Color(0xFFD5D9DE),
                        width: 1,
                      ),
                      columnWidths: {
                        0: FixedColumnWidth(labelWidth),
                        1: FlexColumnWidth(),
                        2: FixedColumnWidth(unitWidth),
                      },
                      children: [
                        for (final field in _padFields)
                          _buildFieldRow(field, isLocked),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBar(bool isLocked) {
    final enabled = !isLocked;
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          const SizedBox(
            width: 94,
            child: Text(
              'Location',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2F2F2F),
              ),
            ),
          ),
          _radioOption('Land', enabled),
          const SizedBox(width: 26),
          _radioOption('Offshore', enabled),
        ],
      ),
    );
  }

  TableRow _buildFieldRow(_PadField field, bool isLocked) {
    final controller = _controllers[field.key]!;
    final fieldReadOnly =
        isLocked || (_locationType == 'Land' && field.offshoreOnly);
    return TableRow(
      children: [
        _labelCell(field.label),
        fieldReadOnly
            ? _readOnlyValueCell(controller.text)
            : _editableValueCell(controller, field.hint),
        _unitCell(_displayUnit(field.unit)),
      ],
    );
  }

  Widget _labelCell(String text) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      color: const Color(0xFFF8F8F8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.8,
          fontWeight: FontWeight.w400,
          color: Color(0xFF2F2F2F),
        ),
      ),
    );
  }

  Widget _readOnlyValueCell(String value) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: Text(
        value,
        style: const TextStyle(fontSize: 10.8, color: Color(0xFF2F2F2F)),
      ),
    );
  }

  Widget _editableValueCell(TextEditingController controller, String hint) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      color: Colors.white,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 10.8, color: Color(0xFF2F2F2F)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 7,
          ),
        ),
      ),
    );
  }

  Widget _unitCell(String unit) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      color: const Color(0xFFF8F8F8),
      child: Text(
        unit,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF2F2F2F)),
      ),
    );
  }

  Widget _radioOption(String value, bool enabled) {
    return InkWell(
      onTap: enabled
          ? () {
              setState(() {
                _locationType = value;
                ugController.location.value = value;
              });
            }
          : null,
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
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: const Color(0xFF2E74C9),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.8,
              color: enabled ? const Color(0xFF2F2F2F) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel({
    required bool isLocked,
    required AppPad? activePad,
    required int linkedWellCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Client Logo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F2F2F),
            ),
          ),
        ),
        _buildClientLogoBox(isLocked, activePad, linkedWellCount),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Memo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2F2F2F),
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC9CDD3)),
              color: Colors.white,
            ),
            child: Scrollbar(
              controller: _memoScrollController,
              thumbVisibility: true,
              child: TextField(
                controller: _memoController,
                readOnly: isLocked,
                maxLines: null,
                expands: true,
                scrollController: _memoScrollController,
                style: const TextStyle(
                  fontSize: 10.8,
                  color: Color(0xFF2F2F2F),
                ),
                decoration: InputDecoration(
                  hintText: isLocked ? '' : 'Enter memo...',
                  hintStyle: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientLogoBox(
    bool isLocked,
    AppPad? activePad,
    int linkedWellCount,
  ) {
    final hasLogo = _clientLogoUrl.trim().isNotEmpty;

    return DropTarget(
      enable: !isLocked,
      onDragEntered: (_) => setState(() => _isLogoDragging = true),
      onDragExited: (_) => setState(() => _isLogoDragging = false),
      onDragDone: isLocked
          ? null
          : (detail) async {
              setState(() => _isLogoDragging = false);
              await _dropClientLogo(detail);
            },
      child: KeyboardListener(
        focusNode: _logoFocusNode,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          final isPaste = HardwareKeyboard.instance.isControlPressed &&
              event.logicalKey == LogicalKeyboardKey.keyV;
          if (isPaste) {
            _pasteClientLogo();
          }
        },
        child: InkWell(
          onTap: isLocked
              ? null
              : () {
                  _logoFocusNode.requestFocus();
                  _pickClientLogo();
                },
          child: Container(
          width: 290,
          height: 210,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isLogoDragging
                  ? const Color(0xFF2E74C9)
                  : const Color(0xFF8E959D),
              width: _isLogoDragging ? 2 : 1,
            ),
            color: _isLogoDragging ? const Color(0xFFEAF3FF) : Colors.white,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: hasLogo
                      ? _buildLogoPreview(_clientLogoUrl)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activePad?.displayName ?? 'No logo selected',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (activePad != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Linked Wells: $linkedWellCount',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFD5D9DE)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasLogo
                            ? 'Click, paste, or drop to change'
                            : 'Click, paste, or drop image',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isLocked
                              ? Colors.grey.shade500
                              : const Color(0xFF5F6B7A),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Upload logo',
                      icon: const Icon(Icons.upload_file, size: 16),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: isLocked ? null : _pickClientLogo,
                    ),
                    IconButton(
                      tooltip: 'Paste copied image file',
                      icon: const Icon(Icons.content_paste, size: 16),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: isLocked ? null : _pasteClientLogo,
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
      ),
      ),
    );
  }

  Widget _buildLogoPreview(String logoUrl) {
    final image = logoUrl.startsWith('data:image')
        ? Image.memory(
            base64Decode(logoUrl.split(',').last),
            fit: BoxFit.contain,
          )
        : Image.network(
            logoUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image_outlined,
              size: 34,
              color: Colors.grey.shade400,
            ),
          );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRect(
        child: SizedBox.expand(child: image),
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
  final String unit;
  final bool offshoreOnly;

  const _PadField({
    required this.key,
    required this.label,
    required this.hint,
    this.unit = '',
    this.offshoreOnly = false,
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
  _PadField(
    key: 'operatorRep',
    label: 'Operator Rep.',
    hint: 'Enter operator representative',
  ),
  _PadField(key: 'contractor', label: 'Contractor', hint: 'Enter contractor'),
  _PadField(
    key: 'contractorRep',
    label: 'Contractor Rep.',
    hint: 'Enter contractor representative',
  ),
  _PadField(key: 'sl', label: 'S/L', hint: 'Enter S/L'),
  _PadField(
    key: 'airGap',
    label: 'Air Gap',
    hint: 'Enter air gap',
    unit: '(ft)',
    offshoreOnly: true,
  ),
  _PadField(
    key: 'waterDepth',
    label: 'Water Depth',
    hint: 'Enter water depth',
    unit: '(ft)',
    offshoreOnly: true,
  ),
  _PadField(
    key: 'riserOD',
    label: 'Riser OD',
    hint: 'Enter riser OD',
    unit: '(mm)',
    offshoreOnly: true,
  ),
  _PadField(
    key: 'riserID',
    label: 'Riser ID',
    hint: 'Enter riser ID',
    unit: '(mm)',
    offshoreOnly: true,
  ),
  _PadField(
    key: 'chokeLineID',
    label: 'Choke Line ID',
    hint: 'Enter choke line ID',
    unit: '(mm)',
    offshoreOnly: true,
  ),
  _PadField(
    key: 'killLineID',
    label: 'Kill Line ID',
    hint: 'Enter kill line ID',
    unit: '(mm)',
    offshoreOnly: true,
  ),
  _PadField(
    key: 'boostLineID',
    label: 'Boost Line ID',
    hint: 'Enter boost line ID',
    unit: '(mm)',
    offshoreOnly: true,
  ),
];
