import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class EngineeringToolsController extends GetxController {
  var activeMainTab = 0.obs;
  var activeHydraulicsTab = 0.obs;

  var pumpOutput = ''.obs;
  var holeSize = ''.obs;
  var pipeOD = ''.obs;

  var annularVelocity = RxnDouble();

  OptionsController? _optionsController;
  Worker? _unitSystemWorker;
  Worker? _customUnitsWorker;
  Map<String, String> _knownUnits = const {};

  @override
  void onInit() {
    super.onInit();

    if (Get.isRegistered<OptionsController>()) {
      _optionsController = Get.find<OptionsController>();
      _knownUnits = _snapshotUnits();
      _unitSystemWorker = ever(_optionsController!.unitSystem, (_) => _syncUnits());
      _customUnitsWorker = ever<Map<String, String>>(
        _optionsController!.customUnits,
        (_) => _syncUnits(),
      );
    }
  }

  @override
  void onClose() {
    _unitSystemWorker?.dispose();
    _customUnitsWorker?.dispose();
    super.onClose();
  }

  void calculateAnnularVelocity() {
    if (pumpOutput.value.isEmpty || holeSize.value.isEmpty || pipeOD.value.isEmpty) {
      Get.snackbar('Error', 'All fields are required');
      return;
    }

    final qDisplay = double.tryParse(pumpOutput.value);
    final dhDisplay = double.tryParse(holeSize.value);
    final dpDisplay = double.tryParse(pipeOD.value);

    if (qDisplay == null || dhDisplay == null || dpDisplay == null) {
      annularVelocity.value = null;
      return;
    }

    final q = AppUnits.parameterToBase(
      qDisplay,
      paramNumber: '18',
      baseUnit: '(bpm)',
    );
    final dh = AppUnits.parameterToBase(
      dhDisplay,
      paramNumber: '2',
      baseUnit: '(in)',
    );
    final dp = AppUnits.parameterToBase(
      dpDisplay,
      paramNumber: '2',
      baseUnit: '(in)',
    );

    if (q == null || dh == null || dp == null) {
      annularVelocity.value = null;
      return;
    }

    if (dh <= dp || q <= 0) {
      annularVelocity.value = null;
      return;
    }

    final denominator = (dh * dh) - (dp * dp);
    if (denominator <= 0) {
      annularVelocity.value = null;
      return;
    }

    final annularVelocityBase = (24.51 * q) / denominator;
    annularVelocity.value = AppUnits.parameterFromBase(
          annularVelocityBase,
          paramNumber: '13',
          baseUnit: '(ft/min)',
        ) ??
        annularVelocityBase;
  }

  void resetAnnularVelocity() {
    pumpOutput.value = '';
    holeSize.value = '';
    pipeOD.value = '';
    annularVelocity.value = null;
  }

  Map<String, String> _snapshotUnits() {
    return AppUnits.snapshotUnits(const ['18', '2', '13']);
  }

  void _syncUnits() {
    final nextUnits = _snapshotUnits();
    if (_knownUnits.isEmpty) {
      _knownUnits = nextUnits;
      return;
    }

    pumpOutput.value = AppUnits.convertText(
      rawValue: pumpOutput.value,
      fromUnit: _knownUnits['18'] ?? '(bpm)',
      toUnit: nextUnits['18'] ?? '(bpm)',
      precision: 4,
    );
    holeSize.value = AppUnits.convertText(
      rawValue: holeSize.value,
      fromUnit: _knownUnits['2'] ?? '(in)',
      toUnit: nextUnits['2'] ?? '(in)',
      precision: 4,
    );
    pipeOD.value = AppUnits.convertText(
      rawValue: pipeOD.value,
      fromUnit: _knownUnits['2'] ?? '(in)',
      toUnit: nextUnits['2'] ?? '(in)',
      precision: 4,
    );

    final currentVelocity = annularVelocity.value;
    if (currentVelocity != null) {
      annularVelocity.value = AppUnits.convertValue(
            currentVelocity,
            fromUnit: _knownUnits['13'] ?? '(ft/min)',
            toUnit: nextUnits['13'] ?? '(ft/min)',
          ) ??
          currentVelocity;
    }

    _knownUnits = nextUnits;
  }
}
