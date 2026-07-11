import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pump_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import '../controller/pump_controller.dart';
import '../controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/ug_ui_pattern.dart';

class PumpView extends StatefulWidget {
  const PumpView({super.key});

  @override
  State<PumpView> createState() => _PumpViewState();
}

class _PumpViewState extends State<PumpView> {
  late final UgController ugController;
  late final PumpController pumpController;
  late final PadWellController padWellC;
  Worker? _wellWorker;
  final List<Worker> _unitWorkers = <Worker>[];
  late String _diameterUnit;
  late String _lengthUnit;
  late String _displacementUnit;
  late String _pressureUnit;
  late String _powerUnit;
  PumpModel? _pumpClipboard;

  @override
  void initState() {
    super.initState();
    ugController = Get.find<UgController>();
    pumpController = Get.put(PumpController());
    padWellC = padWellContext;
    _diameterUnit = AppUnits.diameter;
    _lengthUnit = AppUnits.length;
    _displacementUnit = AppUnits.strokeDisplacement;
    _pressureUnit = AppUnits.pressure;
    _powerUnit = AppUnits.power;
    _wellWorker = ever<String>(padWellC.selectedWellId, (wellId) {
      if (wellId.isNotEmpty) pumpController.setWellId(wellId);
    });
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPumpsIfNeeded();
    });
  }

  void _loadPumpsIfNeeded() {
    final wellId = padWellC.selectedWellId.value;
    if (wellId.isNotEmpty) {
      pumpController.setWellId(wellId);
    } else {
      Get.snackbar(
        'Error',
        'No well selected.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _wellWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    super.dispose();
  }

  void _handleUnitChange() {
    final nextDiameterUnit = AppUnits.diameter;
    final nextLengthUnit = AppUnits.length;
    final nextDisplacementUnit = AppUnits.strokeDisplacement;
    final nextPressureUnit = AppUnits.pressure;
    final nextPowerUnit = AppUnits.power;
    if (_diameterUnit == nextDiameterUnit &&
        _lengthUnit == nextLengthUnit &&
        _displacementUnit == nextDisplacementUnit &&
        _pressureUnit == nextPressureUnit &&
        _powerUnit == nextPowerUnit) {
      return;
    }

    for (final pump in pumpController.pumps) {
      pump.linerId.value = _convertText(
        pump.linerId.value,
        _diameterUnit,
        nextDiameterUnit,
      );
      pump.rodOd.value = _convertText(
        pump.rodOd.value,
        _diameterUnit,
        nextDiameterUnit,
      );
      pump.strokeLength.value = _convertText(
        pump.strokeLength.value,
        _lengthUnit,
        nextLengthUnit,
      );
      pump.displacement.value = _convertText(
        pump.displacement.value,
        _displacementUnit,
        nextDisplacementUnit,
      );
      pump.maxPumpP.value = _convertText(
        pump.maxPumpP.value,
        _pressureUnit,
        nextPressureUnit,
      );
      pump.maxHp.value = _convertText(
        pump.maxHp.value,
        _powerUnit,
        nextPowerUnit,
      );
      pump.surfaceLen.value = _convertText(
        pump.surfaceLen.value,
        _lengthUnit,
        nextLengthUnit,
      );
      pump.surfaceId.value = _convertText(
        pump.surfaceId.value,
        _diameterUnit,
        nextDiameterUnit,
      );
    }
    pumpController.pumps.refresh();

    _diameterUnit = nextDiameterUnit;
    _lengthUnit = nextLengthUnit;
    _displacementUnit = nextDisplacementUnit;
    _pressureUnit = nextPressureUnit;
    _powerUnit = nextPowerUnit;
  }

  String _convertText(String rawValue, String fromUnit, String toUnit) {
    if (rawValue.trim().isEmpty || fromUnit == toUnit) {
      return rawValue;
    }
    final parsed = double.tryParse(rawValue);
    if (parsed == null) {
      return rawValue;
    }
    final result = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (result == null) {
      return rawValue;
    }
    return formatOperationNumber(
      result,
      fallbackDecimals: 4,
      trimFallback: true,
    );
  }

  String _formatPumpNumberText(String value) {
    return formatOperationInputText(
      value,
      fallbackDecimals: 3,
      trimFallback: true,
    );
  }

  TextEditingController _pumpTextController(String value) {
    final formatted = _formatPumpNumberText(value);
    return TextEditingController(text: formatted)
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      );
  }

  void _showAlert(String message, {bool isSuccess = true}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  static const rowH = 32.0;

  final List<String> pumpTypes = [
    '',
    'Triplex',
    'Duplex',
    'Quintuplex',
    'Quadplex',
  ];

  bool get _canEditPumpRows => !ugController.isLocked.value;

  PopupMenuItem<String> _pumpMenuItem(
    String value,
    String label, {
    required bool enabled,
  }) {
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      height: 32,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? const Color(0xFF2F2F2F) : const Color(0xFF9EA4AD),
        ),
      ),
    );
  }

  PumpModel _cloneForClipboard(PumpModel source) {
    final copy = source.clone();
    copy.id = null;
    return copy;
  }

  void _applyPumpRow(PumpModel target, PumpModel source) {
    target.type.value = source.type.value;
    target.model.value = source.model.value;
    target.linerId.value = source.linerId.value;
    target.rodOd.value = source.rodOd.value;
    target.strokeLength.value = source.strokeLength.value;
    target.efficiency.value = source.efficiency.value;
    target.spm.value = source.spm.value;
    target.maxPumpP.value = source.maxPumpP.value;
    target.maxHp.value = source.maxHp.value;
    target.surfaceLen.value = source.surfaceLen.value;
    target.surfaceId.value = source.surfaceId.value;
    target.recalculateDisplacement();
  }

  void _clearPumpRowValues(PumpModel pump, {bool clearId = true}) {
    if (clearId) pump.id = null;
    pump.type.value = '';
    pump.model.value = '';
    pump.linerId.value = '';
    pump.rodOd.value = '';
    pump.strokeLength.value = '';
    pump.efficiency.value = '';
    pump.spm.value = '';
    pump.displacement.value = '';
    pump.rate.value = '';
    pump.maxPumpP.value = '';
    pump.maxHp.value = '';
    pump.surfaceLen.value = '';
    pump.surfaceId.value = '';
  }

  void _renumberPumpRows() {
    for (int i = 0; i < pumpController.pumps.length; i++) {
      pumpController.pumps[i].rowNumber.value = i + 1;
    }
  }

  Future<void> _savePumpRowIfNeeded(int index) async {
    if (index < 0 || index >= pumpController.pumps.length) return;
    final pump = pumpController.pumps[index];
    if (!pump.hasData) return;
    await pumpController.savePump(index);
    pumpController.pumps.refresh();
  }

  Future<void> _clearPumpRow(int index) async {
    if (index < 0 || index >= pumpController.pumps.length) return;
    final pump = pumpController.pumps[index];
    final id = pump.id;
    if (id != null && id.isNotEmpty) {
      await pumpController.repository.deletePump(id, includeReportScope: false);
    }
    _clearPumpRowValues(pump);
    pumpController.pumps.refresh();
  }

  Future<void> _movePumpRow(int index, {required bool toTop}) async {
    if (index < 0 || index >= pumpController.pumps.length) return;
    final row = pumpController.pumps.removeAt(index);
    pumpController.pumps.insert(toTop ? 0 : pumpController.pumps.length, row);
    _renumberPumpRows();
    pumpController.pumps.refresh();
    await pumpController.saveAllPumps();
  }

  Future<void> _showPumpRowMenu(
    TapDownDetails details,
    PumpModel pump,
    int index,
  ) async {
    final hasData = pump.hasData;
    final canEdit = _canEditPumpRows;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _pumpMenuItem('cut', 'Cut', enabled: canEdit && hasData),
        _pumpMenuItem('copy', 'Copy', enabled: hasData),
        _pumpMenuItem(
          'paste',
          'Paste',
          enabled: canEdit && _pumpClipboard != null,
        ),
        _pumpMenuItem('delete', 'Delete', enabled: canEdit && hasData),
        _pumpMenuItem('clear', 'Clear', enabled: canEdit && hasData),
        _pumpMenuItem(
          'top',
          'To the Top',
          enabled: canEdit && hasData && index > 0,
        ),
        _pumpMenuItem(
          'bottom',
          'To the Bottom',
          enabled: canEdit && hasData && index < pumpController.pumps.length - 1,
        ),
      ],
    );

    if (!mounted || action == null) return;

    try {
      switch (action) {
        case 'cut':
          _pumpClipboard = _cloneForClipboard(pump);
          await pumpController.deletePump(index);
          break;
        case 'copy':
          _pumpClipboard = _cloneForClipboard(pump);
          await Clipboard.setData(ClipboardData(text: pump.model.value));
          break;
        case 'paste':
          final clip = _pumpClipboard;
          if (clip == null) return;
          _applyPumpRow(pump, clip);
          pumpController.checkAndAddNewRow();
          pumpController.pumps.refresh();
          await _savePumpRowIfNeeded(index);
          break;
        case 'delete':
          await pumpController.deletePump(index);
          break;
        case 'clear':
          await _clearPumpRow(index);
          break;
        case 'top':
          await _movePumpRow(index, toTop: true);
          break;
        case 'bottom':
          await _movePumpRow(index, toTop: false);
          break;
      }
    } catch (e) {
      if (mounted) {
        _showAlert('Pump action failed: $e', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AppUnits.signature;
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: ugBorder, width: 1),
          ),
          child: Column(
            children: [
              _headerRow(),
              Expanded(child: _tableBody()),
            ],
          ),
        ),
      );
    });
  }

  Widget _headerRow() {
    return Column(
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: ugSectionHeader,
            borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(
                Icons.precision_manufacturing,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                "Pump Configuration",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${pumpController.pumpCount} pumps",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        Container(
          height: rowH,
          decoration: BoxDecoration(
            color: ugColumnHeader,
            border: Border(
              bottom: BorderSide(color: ugGrid, width: 1),
            ),
          ),
          child: Row(
            children: _addDividers([
              const _HCell('#', flex: 1),
              const _HCell('Type', flex: 2),
              const _HCell('Model', flex: 3),
              _HCell('Liner ID\n${AppUnits.diameter}', flex: 2),
              _HCell('Rod OD\n${AppUnits.diameter}', flex: 2),
              _HCell('Stk. Length\n${AppUnits.length}', flex: 2),
              const _HCell('Efficiency\n(%)', flex: 2),
              _HCell('Disp.\n${AppUnits.strokeDisplacement}', flex: 2),
              _HCell('Max. Pump P.\n${AppUnits.pressure}', flex: 2),
              _HCell('Max. HP\n${AppUnits.power}', flex: 2),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: ugGrid, width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: rowH / 2,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: ugGrid,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Surface Line',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: ugGrid,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Length\n${AppUnits.length}',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'ID\n${AppUnits.diameter}',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _tableBody() {
    return Obx(() {
      if (pumpController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        itemCount: pumpController.pumps.length,
        itemBuilder: (_, i) {
          final p = pumpController.pumps[i];

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: (details) => _showPumpRowMenu(details, p, i),
            child: Container(
              height: rowH,
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : const Color(0xfffafafa),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: Row(
                children: _addDividers([
                _cellText('${i + 1}', flex: 1),

                // Type dropdown
                _typeDropdown(p, i, flex: 2),

                // Model
                _editableField(p.model, i, (val) {
                  p.model.value = val;
                  pumpController.onFieldChanged(i);
                }, flex: 3),

                // Liner ID — triggers displacement calc
                _editableField(p.linerId, i, (val) {
                  p.linerId.value = val;
                  p.recalculateDisplacement();
                  pumpController.onFieldChanged(i);
                }, flex: 2, formatNumber: true),

                // AFTER — Rod OD locked for all except Duplex
                Expanded(
                  flex: 2,
                  child: Obx(() {
                    final isDuplex = p.type.value == 'Duplex';
                    final isLocked =
                        ugController.isLocked.value ||
                        !isDuplex; // ✅ locked if not Duplex

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      color: !isDuplex
                          ? ugReadOnlyFill
                          : ugController.isLocked.value
                          ? ugLockedEditable
                          : Colors.white,
                      child: isLocked
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isDuplex
                                    ? _formatPumpNumberText(p.rodOd.value)
                                    : '', // non-Duplex shows empty
                                textAlign: TextAlign.left,
                                style: AppTheme.wellLikeBodyText,
                              ),
                            )
                          : TextField(
                              controller: _pumpTextController(p.rodOd.value),
                              onChanged: (val) {
                                p.rodOd.value = val;
                                p.recalculateDisplacement(); // always safe, only Duplex reaches here
                                pumpController.onFieldChanged(i);
                              },
                              textAlign: TextAlign.left,
                              style: AppTheme.wellLikeBodyText,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                    );
                  }),
                ),

                // Stroke Length — triggers displacement calc
                _editableField(p.strokeLength, i, (val) {
                  p.strokeLength.value = val;
                  p.recalculateDisplacement();
                  pumpController.onFieldChanged(i);
                }, flex: 2, formatNumber: true),

                // Efficiency
                _editableField(p.efficiency, i, (val) {
                  p.efficiency.value = val;
                  p.recalculateDisplacement();
                  pumpController.onFieldChanged(i);
                }, flex: 2, formatNumber: true),

                // Displacement — READ ONLY, auto-calculated
                _displacementCell(p, flex: 2),

                // Max Pump Pressure
                _editableField(p.maxPumpP, i, (val) {
                  p.maxPumpP.value = val;
                  pumpController.onFieldChanged(i);
                }, flex: 2, formatNumber: true),

                // Max HP
                _editableField(p.maxHp, i, (val) {
                  p.maxHp.value = val;
                  pumpController.onFieldChanged(i);
                }, flex: 2, formatNumber: true),

                // Surface Line (Length + ID)
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: ugController.isLocked.value
                                  ? ugLockedEditable
                                  : Colors.white,
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Obx(
                              () => ugController.isLocked.value
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _formatPumpNumberText(
                                          p.surfaceLen.value,
                                        ),
                                        textAlign: TextAlign.left,
                                        style: AppTheme.wellLikeBodyText,
                                      ),
                                    )
                                  : TextField(
                                      controller: _pumpTextController(
                                        p.surfaceLen.value,
                                      ),
                                      onChanged: (v) {
                                        p.surfaceLen.value = v;
                                        pumpController.onFieldChanged(i);
                                      },
                                      textAlign: TextAlign.left,
                                      style: AppTheme.wellLikeBodyText,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            color: ugController.isLocked.value
                                ? ugLockedEditable
                                : Colors.white,
                            child: Obx(
                              () => ugController.isLocked.value
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _formatPumpNumberText(
                                          p.surfaceId.value,
                                        ),
                                        textAlign: TextAlign.left,
                                        style: AppTheme.wellLikeBodyText,
                                      ),
                                    )
                                  : TextField(
                                      controller: _pumpTextController(
                                        p.surfaceId.value,
                                      ),
                                      onChanged: (v) {
                                        p.surfaceId.value = v;
                                        pumpController.onFieldChanged(i);
                                      },
                                      textAlign: TextAlign.left,
                                      style: AppTheme.wellLikeBodyText,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
          );
        },
      );
    });
  }

  /// Displacement cell — read-only, green background when calculated
  Widget _displacementCell(PumpModel pump, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Obx(() {
        final val = pump.displacement.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: val.isNotEmpty
              ? const Color(0xffe8f5e9)
              : const Color(0xfff5f5f5),
          alignment: Alignment.centerLeft,
          child: Text(
            val.isEmpty ? '-' : _formatPumpNumberText(val),
            textAlign: TextAlign.left,
            style: AppTheme.wellLikeBodyText,
          ),
        );
      }),
    );
  }

  List<Widget> _addDividers(List<Widget> widgets) {
    final List<Widget> result = [];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(
          Container(
            width: 1,
            color: Colors.grey.shade200,
            height: double.infinity,
          ),
        );
      }
    }
    return result;
  }

  Widget _cellText(String t, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          t,
          textAlign: TextAlign.left,
          style: AppTheme.wellLikeBodyText,
        ),
      ),
    );
  }

  Widget _typeDropdown(PumpModel pump, int index, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        color: ugController.isLocked.value
            ? ugLockedEditable
            : Colors.white,
        child: Obx(
          () => ugController.isLocked.value
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pump.type.value,
                    textAlign: TextAlign.left,
                    style: AppTheme.wellLikeBodyText,
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: pumpTypes.contains(pump.type.value)
                        ? pump.type.value
                        : '',
                    isExpanded: true,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    items: pumpTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type.isEmpty ? 'Select' : type,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: type.isEmpty ? Colors.grey : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        pump.type.value = newValue;
                        pump.recalculateDisplacement();
                        pumpController.onFieldChanged(index);
                      }
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _editableField(
    RxString value,
    int index,
    Function(String) onChanged, {
    required int flex,
    bool formatNumber = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        color: ugController.isLocked.value
            ? ugLockedEditable
            : Colors.white,
        child: Obx(
          () => ugController.isLocked.value
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatNumber
                        ? _formatPumpNumberText(value.value)
                        : value.value,
                    textAlign: TextAlign.left,
                    style: AppTheme.wellLikeBodyText,
                  ),
                )
              : TextField(
                  controller: formatNumber
                      ? _pumpTextController(value.value)
                      : (TextEditingController(text: value.value)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: value.value.length),
                          )),
                  onChanged: (v) => onChanged(v),
                  textAlign: TextAlign.left,
                  style: AppTheme.wellLikeBodyText,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    border: InputBorder.none,
                  ),
                ),
        ),
      ),
    );
  }

}

class _HCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

