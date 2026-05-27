import 'dart:async';

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/formation_row_model.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class FormationController extends GetxController {
  static const int rowCount = 23;
  static const double _ppgPerPsiPerFoot = 19.24;
  static const double _psiPerFootPerPpg = 1 / _ppgPerPsiPerFoot;

  final UgController ugController = Get.find<UgController>();
  final AuthRepository _repository = AuthRepository();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final rows = <FormationRow>[].obs;
  final poreFromTop = true.obs;
  final mode = 'Gradient'.obs;
  final isGraphVisible = false.obs;
  final showPoreGraph = true.obs;
  final showFracGraph = true.obs;

  String? currentWellId;
  Timer? _autosaveTimer;
  Worker? _wellWorker;
  Worker? _reportWorker;
  final List<Worker> _unitWorkers = <Worker>[];
  late String _lengthUnit;
  late String _mudWeightUnit;
  late String _pressureGradientUnit;
  late String _pressureUnit;

  bool get _hasWellId => currentWellId != null && currentWellId!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _lengthUnit = AppUnits.length;
    _mudWeightUnit = AppUnits.mudWeight;
    _pressureGradientUnit = AppUnits.pressureGradient;
    _pressureUnit = AppUnits.pressure;
    currentWellId = padWellContext.selectedWellId.value.isNotEmpty
        ? padWellContext.selectedWellId.value
        : currentBackendWellId;
    _ensureRowCount();
    _syncUgController();

    _wellWorker = ever<String>(padWellContext.selectedWellId, (wellId) {
      if (wellId.isEmpty) return;
      currentWellId = wellId;
      loadFormationData();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      loadFormationData();
    });
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);

    if (_hasWellId) {
      loadFormationData();
    }
  }

  @override
  void onClose() {
    _autosaveTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    super.onClose();
  }

  void _ensureRowCount() {
    while (rows.length < rowCount) {
      rows.add(FormationRow());
    }
    if (rows.length > rowCount) {
      rows.removeRange(rowCount, rows.length);
    }
  }

  Future<void> loadFormationData() async {
    if (!_hasWellId) return;
    isLoading.value = true;
    try {
      final result = await _repository.getFormationConfig(currentWellId!);
      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] ?? {});
        poreFromTop.value = data['poreFromTop'] == true;
        final incomingMode = (data['mode'] ?? 'Gradient').toString();
        mode.value = _normalizeMode(incomingMode);

        final incomingRows = (data['rows'] as List? ?? [])
            .map(
              (item) => FormationRow.fromJson(Map<String, dynamic>.from(item)),
            )
            .map(_displayRow)
            .toList();

        rows.assignAll(incomingRows);
        _ensureRowCount();
        for (final row in rows) {
          _recalculateRow(row);
        }
        rows.refresh();
      } else {
        _resetToBlank();
      }
    } catch (_) {
      _resetToBlank();
    } finally {
      _syncUgController();
      isLoading.value = false;
    }
  }

  void _resetToBlank() {
    rows.assignAll(List.generate(rowCount, (_) => FormationRow()));
    poreFromTop.value = true;
    mode.value = 'Gradient';
    _syncUgController();
  }

  void setPoreFromTop(bool value) {
    poreFromTop.value = value;
    _syncUgController();
    scheduleAutosave();
  }

  void setMode(String value) {
    mode.value = _normalizeMode(value);
    for (final row in rows) {
      _recalculateRow(row);
    }
    rows.refresh();
    _syncUgController();
    scheduleAutosave();
  }

  void updateDescription(int index, String value) {
    if (!_validIndex(index)) return;
    rows[index].description.value = value;
    _syncUgController();
    scheduleAutosave();
  }

  void updateTvd(int index, String value) {
    if (!_validIndex(index)) return;
    rows[index].tvd.value = value;
    _recalculateRow(rows[index]);
    _syncUgController();
    scheduleAutosave();
  }

  void updateValue(int index, String field, String value) {
    if (!_validIndex(index)) return;
    final row = rows[index];
    switch (field) {
      case 'porePpg':
        row.porePpg.value = value;
        break;
      case 'poreGrad':
        row.poreGrad.value = value;
        break;
      case 'porePsi':
        row.porePsi.value = value;
        break;
      case 'fracPpg':
        row.fracPpg.value = value;
        break;
      case 'fracGrad':
        row.fracGrad.value = value;
        break;
      case 'fracPsi':
        row.fracPsi.value = value;
        break;
    }

    _recalculateRow(row);
    _syncUgController();
    scheduleAutosave();
  }

  void updateLithology(int index, String value) {
    if (!_validIndex(index)) return;
    rows[index].lithology.value = value;
    rows.refresh();
    _syncUgController();
    scheduleAutosave();
  }

  void clearRow(int index) {
    if (!_validIndex(index)) return;
    rows[index].clearRetainingReadOnlyDefaults();
    rows.refresh();
    _syncUgController();
    scheduleAutosave();
  }

  void pasteRow(int index, FormationRow source) {
    if (!_validIndex(index)) return;
    rows[index] = source.clone();
    _recalculateRow(rows[index]);
    rows.refresh();
    _syncUgController();
    scheduleAutosave();
  }

  void moveRowToTop(int index) {
    if (!_validIndex(index) || !rows[index].hasData || index == 0) return;
    final row = rows.removeAt(index);
    rows.insert(0, row);
    rows.refresh();
    _syncUgController();
    scheduleAutosave();
  }

  void moveRowToBottom(int index) {
    if (!_validIndex(index) ||
        !rows[index].hasData ||
        index == rows.length - 1) {
      return;
    }
    final row = rows.removeAt(index);
    rows.add(row);
    rows.refresh();
    _syncUgController();
    scheduleAutosave();
  }

  void toggleGraph() {
    isGraphVisible.toggle();
  }

  void scheduleAutosave() {
    if (!_hasWellId) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 900), () async {
      await saveFormationData();
    });
  }

  Future<void> saveFormationData() async {
    if (!_hasWellId) return;
    isSaving.value = true;
    try {
      await _repository.saveFormationConfig(
        wellId: currentWellId!,
        mode: mode.value,
        poreFromTop: poreFromTop.value,
        rows: rows.map(_rowBaseJson).toList(),
      );
    } finally {
      isSaving.value = false;
    }
  }

  List<FormationGraphPoint> graphPoints({required bool pore}) {
    final points = <FormationGraphPoint>[];
    for (final row in rows) {
      final tvd = _toDouble(row.tvd.value);
      final value = _toDouble(_graphValue(row, pore: pore));
      if (tvd <= 0 || value <= 0) continue;
      points.add(FormationGraphPoint(value: value, tvd: tvd));
    }
    points.sort((a, b) => a.tvd.compareTo(b.tvd));
    return points;
  }

  String _graphValue(FormationRow row, {required bool pore}) {
    switch (mode.value) {
      case 'Density':
        return pore ? row.porePpg.value : row.fracPpg.value;
      case 'Pressure':
        return pore ? row.porePsi.value : row.fracPsi.value;
      case 'Gradient':
      default:
        return pore ? row.poreGrad.value : row.fracGrad.value;
    }
  }

  bool _validIndex(int index) => index >= 0 && index < rows.length;

  void _syncUgController() {
    ugController.poreFromTop.value = poreFromTop.value;
    ugController.formationMode.value = mode.value;
    ugController.formations.assignAll(rows.map((row) => row.clone()).toList());
  }

  void _recalculateRow(FormationRow row) {
    final tvd = _toBaseDouble(row.tvd.value, AppUnits.length, '(ft)');
    _recalculateGroup(
      ppg: row.porePpg,
      grad: row.poreGrad,
      psi: row.porePsi,
      tvd: tvd,
    );
    _recalculateGroup(
      ppg: row.fracPpg,
      grad: row.fracGrad,
      psi: row.fracPsi,
      tvd: tvd,
    );
  }

  void _recalculateGroup({
    required RxString ppg,
    required RxString grad,
    required RxString psi,
    required double tvd,
  }) {
    double densityValue = _toBaseDouble(ppg.value, AppUnits.mudWeight, '(ppg)');
    double gradientValue = _toBaseDouble(
      grad.value,
      AppUnits.pressureGradient,
      '(psi/ft)',
    );
    double pressureValue = _toBaseDouble(psi.value, AppUnits.pressure, '(psi)');

    switch (mode.value) {
      case 'Density':
        if (densityValue <= 0) {
          grad.value = '';
          psi.value = '';
          return;
        }
        gradientValue = densityValue * _psiPerFootPerPpg;
        pressureValue = tvd > 0 ? gradientValue * tvd : 0;
        grad.value = _formatDisplay(
          gradientValue,
          '(psi/ft)',
          AppUnits.pressureGradient,
          3,
        );
        psi.value = _formatDisplay(
          pressureValue,
          '(psi)',
          AppUnits.pressure,
          _pressureFractionDigits,
        );
        ppg.value = _formatDisplay(
          densityValue,
          '(ppg)',
          AppUnits.mudWeight,
          2,
        );
        return;
      case 'Pressure':
        if (pressureValue <= 0) {
          ppg.value = '';
          grad.value = '';
          return;
        }
        gradientValue = tvd > 0 ? pressureValue / tvd : 0;
        densityValue = gradientValue > 0
            ? gradientValue / _psiPerFootPerPpg
            : 0;
        ppg.value = _formatDisplay(
          densityValue,
          '(ppg)',
          AppUnits.mudWeight,
          2,
        );
        grad.value = _formatDisplay(
          gradientValue,
          '(psi/ft)',
          AppUnits.pressureGradient,
          3,
        );
        psi.value = _formatDisplay(
          pressureValue,
          '(psi)',
          AppUnits.pressure,
          _pressureFractionDigits,
        );
        return;
      case 'Gradient':
      default:
        if (gradientValue <= 0) {
          ppg.value = '';
          psi.value = '';
          return;
        }
        densityValue = gradientValue / _psiPerFootPerPpg;
        pressureValue = tvd > 0 ? gradientValue * tvd : 0;
        ppg.value = _formatDisplay(
          densityValue,
          '(ppg)',
          AppUnits.mudWeight,
          2,
        );
        psi.value = _formatDisplay(
          pressureValue,
          '(psi)',
          AppUnits.pressure,
          _pressureFractionDigits,
        );
        grad.value = _formatDisplay(
          gradientValue,
          '(psi/ft)',
          AppUnits.pressureGradient,
          3,
        );
        return;
    }
  }

  String _normalizeMode(String value) {
    switch (value.trim()) {
      case 'Density':
      case 'Pressure':
      case 'Gradient':
        return value.trim();
      default:
        return 'Gradient';
    }
  }

  double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0.0;
  }

  int get _pressureFractionDigits =>
      AppUnits.clean(AppUnits.pressure) == AppUnits.clean('(psi)') ? 0 : 2;

  String _formatFixed(double value, int fractionDigits) {
    if (value <= 0) return '';
    return value.toStringAsFixed(fractionDigits);
  }

  void _handleUnitChange() {
    final nextLengthUnit = AppUnits.length;
    final nextMudWeightUnit = AppUnits.mudWeight;
    final nextPressureGradientUnit = AppUnits.pressureGradient;
    final nextPressureUnit = AppUnits.pressure;

    if (_lengthUnit == nextLengthUnit &&
        _mudWeightUnit == nextMudWeightUnit &&
        _pressureGradientUnit == nextPressureGradientUnit &&
        _pressureUnit == nextPressureUnit) {
      return;
    }

    for (final row in rows) {
      row.tvd.value = _convertText(row.tvd.value, _lengthUnit, nextLengthUnit);
      row.porePpg.value = _convertText(
        row.porePpg.value,
        _mudWeightUnit,
        nextMudWeightUnit,
      );
      row.fracPpg.value = _convertText(
        row.fracPpg.value,
        _mudWeightUnit,
        nextMudWeightUnit,
      );
      row.poreGrad.value = _convertText(
        row.poreGrad.value,
        _pressureGradientUnit,
        nextPressureGradientUnit,
      );
      row.fracGrad.value = _convertText(
        row.fracGrad.value,
        _pressureGradientUnit,
        nextPressureGradientUnit,
      );
      row.porePsi.value = _convertText(
        row.porePsi.value,
        _pressureUnit,
        nextPressureUnit,
      );
      row.fracPsi.value = _convertText(
        row.fracPsi.value,
        _pressureUnit,
        nextPressureUnit,
      );
    }

    _lengthUnit = nextLengthUnit;
    _mudWeightUnit = nextMudWeightUnit;
    _pressureGradientUnit = nextPressureGradientUnit;
    _pressureUnit = nextPressureUnit;

    for (final row in rows) {
      _recalculateRow(row);
    }
    rows.refresh();
    _syncUgController();
  }

  FormationRow _displayRow(FormationRow row) {
    return FormationRow(
      description: row.description.value,
      tvd: _convertText(row.tvd.value, '(ft)', AppUnits.length),
      porePpg: _convertText(row.porePpg.value, '(ppg)', AppUnits.mudWeight),
      poreGrad: _convertText(
        row.poreGrad.value,
        '(psi/ft)',
        AppUnits.pressureGradient,
      ),
      porePsi: _convertText(row.porePsi.value, '(psi)', AppUnits.pressure),
      fracPpg: _convertText(row.fracPpg.value, '(ppg)', AppUnits.mudWeight),
      fracGrad: _convertText(
        row.fracGrad.value,
        '(psi/ft)',
        AppUnits.pressureGradient,
      ),
      fracPsi: _convertText(row.fracPsi.value, '(psi)', AppUnits.pressure),
      lithology: row.lithology.value,
    );
  }

  Map<String, dynamic> _rowBaseJson(FormationRow row) => {
    'description': row.description.value.trim(),
    'tvd': _convertText(row.tvd.value, AppUnits.length, '(ft)').trim(),
    'porePpg': _convertText(
      row.porePpg.value,
      AppUnits.mudWeight,
      '(ppg)',
    ).trim(),
    'poreGrad': _convertText(
      row.poreGrad.value,
      AppUnits.pressureGradient,
      '(psi/ft)',
    ).trim(),
    'porePsi': _convertText(
      row.porePsi.value,
      AppUnits.pressure,
      '(psi)',
    ).trim(),
    'fracPpg': _convertText(
      row.fracPpg.value,
      AppUnits.mudWeight,
      '(ppg)',
    ).trim(),
    'fracGrad': _convertText(
      row.fracGrad.value,
      AppUnits.pressureGradient,
      '(psi/ft)',
    ).trim(),
    'fracPsi': _convertText(
      row.fracPsi.value,
      AppUnits.pressure,
      '(psi)',
    ).trim(),
    'lithology': row.lithology.value.trim(),
  };

  double _toBaseDouble(String value, String fromUnit, String baseUnit) {
    final parsed = _toDouble(value);
    if (parsed <= 0) return 0;
    return AppUnits.convertValue(parsed, fromUnit, baseUnit) ?? parsed;
  }

  String _formatDisplay(
    double value,
    String fromUnit,
    String toUnit,
    int fractionDigits,
  ) {
    if (value <= 0) return '';
    final converted = AppUnits.convertValue(value, fromUnit, toUnit) ?? value;
    return _formatFixed(converted, fractionDigits);
  }

  String _convertText(String value, String fromUnit, String toUnit) {
    final raw = value.trim();
    if (raw.isEmpty || fromUnit == toUnit) return value;
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) return value;
    final converted = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (converted == null) return value;
    return converted
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

class FormationGraphPoint {
  final double value;
  final double tvd;

  FormationGraphPoint({required this.value, required this.tvd});
}
