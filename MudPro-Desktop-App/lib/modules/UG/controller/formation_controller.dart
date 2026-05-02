import 'dart:async';

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/formation_row_model.dart';
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

  bool get _hasWellId => currentWellId != null && currentWellId!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
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

    if (_hasWellId) {
      loadFormationData();
    }
  }

  @override
  void onClose() {
    _autosaveTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
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
        rows: rows.map((row) => row.toJson()).toList(),
      );
    } finally {
      isSaving.value = false;
    }
  }

  List<FormationGraphPoint> graphPoints({required bool pore}) {
    final points = <FormationGraphPoint>[];
    for (final row in rows) {
      final tvd = _toDouble(row.tvd.value);
      final grad = _toDouble(pore ? row.poreGrad.value : row.fracGrad.value);
      if (tvd <= 0 || grad <= 0) continue;
      points.add(FormationGraphPoint(gradient: grad, tvd: tvd));
    }
    points.sort((a, b) => a.tvd.compareTo(b.tvd));
    return points;
  }

  bool _validIndex(int index) => index >= 0 && index < rows.length;

  void _syncUgController() {
    ugController.poreFromTop.value = poreFromTop.value;
    ugController.formationMode.value = mode.value;
    ugController.formations.assignAll(rows.map((row) => row.clone()).toList());
  }

  void _recalculateRow(FormationRow row) {
    final tvd = _toDouble(row.tvd.value);
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
    double densityValue = _toDouble(ppg.value);
    double gradientValue = _toDouble(grad.value);
    double pressureValue = _toDouble(psi.value);

    switch (mode.value) {
      case 'Density':
        if (densityValue <= 0) {
          grad.value = '';
          psi.value = '';
          return;
        }
        gradientValue = densityValue * _psiPerFootPerPpg;
        pressureValue = tvd > 0 ? gradientValue * tvd : 0;
        grad.value = _formatFixed(gradientValue, 3);
        psi.value = _formatFixed(pressureValue, 0);
        ppg.value = _formatFixed(densityValue, 2);
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
        ppg.value = _formatFixed(densityValue, 2);
        grad.value = _formatFixed(gradientValue, 3);
        psi.value = _formatFixed(pressureValue, 0);
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
        ppg.value = _formatFixed(densityValue, 2);
        psi.value = _formatFixed(pressureValue, 0);
        grad.value = _formatFixed(gradientValue, 3);
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

  String _formatFixed(double value, int fractionDigits) {
    if (value <= 0) return '';
    return value.toStringAsFixed(fractionDigits);
  }
}

class FormationGraphPoint {
  final double gradient;
  final double tvd;

  FormationGraphPoint({required this.gradient, required this.tvd});
}
