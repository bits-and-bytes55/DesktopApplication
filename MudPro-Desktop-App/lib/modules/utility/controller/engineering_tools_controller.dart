import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class EngineeringToolsController extends GetxController {
  final OptionsController _options = AppUnits.controller;

  // Main Engineering Tabs
  var activeMainTab = 0.obs;

  // Hydraulics Sub Tabs
  var activeHydraulicsTab = 0.obs;

  // Annular Velocity Inputs
  var pumpOutput = ''.obs;
  var holeSize = ''.obs;
  var pipeOD = ''.obs;

  var annularVelocity = RxnDouble();

  final List<Worker> _unitWorkers = <Worker>[];
  late String _flowUnit;
  late String _diameterUnit;

  @override
  void onInit() {
    super.onInit();
    _flowUnit = AppUnits.drillingFlowRate;
    _diameterUnit = AppUnits.diameter;
    _unitWorkers.addAll([
      ever(_options.unitSystem, (_) => _handleUnitChange()),
      ever(_options.selectedCustomSystemId, (_) => _handleUnitChange()),
      ever(_options.customUnits, (_) => _handleUnitChange()),
    ]);
  }

  @override
  void onClose() {
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    super.onClose();
  }

  void _handleUnitChange() {
    final nextFlowUnit = AppUnits.drillingFlowRate;
    final nextDiameterUnit = AppUnits.diameter;
    if (_flowUnit == nextFlowUnit && _diameterUnit == nextDiameterUnit) {
      return;
    }

    pumpOutput.value = _convertText(pumpOutput.value, _flowUnit, nextFlowUnit);
    holeSize.value = _convertText(
      holeSize.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    pipeOD.value = _convertText(pipeOD.value, _diameterUnit, nextDiameterUnit);

    _flowUnit = nextFlowUnit;
    _diameterUnit = nextDiameterUnit;

    if (pumpOutput.value.isNotEmpty &&
        holeSize.value.isNotEmpty &&
        pipeOD.value.isNotEmpty) {
      calculateAnnularVelocity();
    } else {
      annularVelocity.value = null;
    }
  }

  void calculateAnnularVelocity() {
    if (pumpOutput.value.isEmpty ||
        holeSize.value.isEmpty ||
        pipeOD.value.isEmpty) {
      Get.snackbar('Error', 'All fields are required');
      return;
    }

    final qInput = double.tryParse(pumpOutput.value);
    final dhInput = double.tryParse(holeSize.value);
    final dpInput = double.tryParse(pipeOD.value);

    if (qInput == null || dhInput == null || dpInput == null) {
      annularVelocity.value = null;
      return;
    }

    final q =
        AppUnits.convertValue(qInput, AppUnits.drillingFlowRate, '(gpm)') ??
        qInput;
    final dh =
        AppUnits.convertValue(dhInput, AppUnits.diameter, '(in)') ?? dhInput;
    final dp =
        AppUnits.convertValue(dpInput, AppUnits.diameter, '(in)') ?? dpInput;

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
    annularVelocity.value =
        AppUnits.convertValue(
          annularVelocityBase,
          '(ft/min)',
          AppUnits.velocity,
        ) ??
        annularVelocityBase;
  }

  void resetAnnularVelocity() {
    pumpOutput.value = '';
    holeSize.value = '';
    pipeOD.value = '';
    annularVelocity.value = null;
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
    return _format(result);
  }

  String _format(double value) {
    if (value == value.truncateToDouble()) {
      return value.truncate().toString();
    }
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
