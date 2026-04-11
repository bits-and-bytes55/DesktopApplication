import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/utility/utils/bit_hydraulics_calculator.dart'
    as bit_hydraulics;

class BitHydraulicsController extends GetxController {
  final OptionsController _options = AppUnits.controller;

  // ================= INPUTS =================
  final mw = ''.obs;
  final pumpOutput = ''.obs;
  final standpipePressure = ''.obs;
  final bitSize = ''.obs;

  // Jet nozzles (optional but shown)
  final jetNozzles = List.generate(10, (_) => ''.obs);

  // ================= OUTPUTS =================
  final nozzleArea = RxnDouble();
  final nozzleVelocity = RxnDouble();
  final bitPressureDrop = RxnDouble();
  final hydraulicHP = RxnDouble();
  final hhpPerArea = RxnDouble();
  final pressureDropPercent = RxnDouble();
  final jetImpactForce = RxnDouble();

  final List<Worker> _unitWorkers = <Worker>[];
  late String _mudWeightUnit;
  late String _flowUnit;
  late String _pressureUnit;
  late String _diameterUnit;

  @override
  void onInit() {
    super.onInit();
    _mudWeightUnit = AppUnits.mudWeight;
    _flowUnit = AppUnits.drillingFlowRate;
    _pressureUnit = AppUnits.pressure;
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
    final nextMudWeight = AppUnits.mudWeight;
    final nextFlow = AppUnits.drillingFlowRate;
    final nextPressure = AppUnits.pressure;
    final nextDiameter = AppUnits.diameter;
    if (_mudWeightUnit == nextMudWeight &&
        _flowUnit == nextFlow &&
        _pressureUnit == nextPressure &&
        _diameterUnit == nextDiameter) {
      return;
    }

    mw.value = _convertText(mw.value, _mudWeightUnit, nextMudWeight);
    pumpOutput.value = _convertText(pumpOutput.value, _flowUnit, nextFlow);
    standpipePressure.value = _convertText(
      standpipePressure.value,
      _pressureUnit,
      nextPressure,
    );
    bitSize.value = _convertText(bitSize.value, _diameterUnit, nextDiameter);

    _mudWeightUnit = nextMudWeight;
    _flowUnit = nextFlow;
    _pressureUnit = nextPressure;
    _diameterUnit = nextDiameter;

    if (_hasCompleteInputs()) {
      calculateBitHydraulics();
    } else {
      resetBitHydraulics();
    }
  }

  // ================= CALCULATION =================
  void calculateBitHydraulics() {
    if (!_hasCompleteInputs()) {
      Get.snackbar(
        'Missing Inputs',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    final mwValue = double.tryParse(mw.value);
    final flowValue = double.tryParse(pumpOutput.value);
    final sppValue = double.tryParse(standpipePressure.value);
    final bitSizeValue = double.tryParse(bitSize.value);

    if (mwValue == null ||
        flowValue == null ||
        sppValue == null ||
        bitSizeValue == null) {
      resetBitHydraulics();
      return;
    }

    final mwPpg =
        AppUnits.convertValue(mwValue, AppUnits.mudWeight, '(ppg)') ?? mwValue;
    final gpm =
        AppUnits.convertValue(flowValue, AppUnits.drillingFlowRate, '(gpm)') ??
        flowValue;
    final spp =
        AppUnits.convertValue(sppValue, AppUnits.pressure, '(psi)') ?? sppValue;
    final bitIn =
        AppUnits.convertValue(bitSizeValue, AppUnits.diameter, '(in)') ??
        bitSizeValue;

    double totalJetArea = 0;
    for (final jet in jetNozzles) {
      if (jet.value.isEmpty) {
        continue;
      }
      final size32 = double.tryParse(jet.value);
      if (size32 == null) {
        continue;
      }
      final diaIn = size32 / 32;
      totalJetArea += 0.785 * diaIn * diaIn;
    }

    if (totalJetArea == 0) {
      Get.snackbar(
        'Jet Nozzles Missing',
        'Please enter at least one jet nozzle size',
      );
      return;
    }

    final snapshot = bit_hydraulics.calculateBitHydraulics(
      bit_hydraulics.BitHydraulicsInputs(
        mudWeightPpg: mwPpg,
        flowRateGpm: gpm,
        standpipePressurePsi: spp,
        totalFlowAreaIn2: totalJetArea,
        bitSizeIn: bitIn,
      ),
    );

    if (snapshot == null) {
      resetBitHydraulics();
      return;
    }

    nozzleArea.value =
        AppUnits.convertValue(totalJetArea, '(in2)', AppUnits.crossSection) ??
        totalJetArea;
    nozzleVelocity.value =
        AppUnits.convertValue(
          snapshot.nozzleVelocityFtPerSec,
          '(ft/s)',
          AppUnits.nozzleVelocity,
        ) ??
        snapshot.nozzleVelocityFtPerSec;
    bitPressureDrop.value =
        AppUnits.convertValue(
          snapshot.bitPressureDropPsi,
          '(psi)',
          AppUnits.pressure,
        ) ??
        snapshot.bitPressureDropPsi;
    hydraulicHP.value =
        AppUnits.convertValue(snapshot.hydraulicHp, '(HP)', AppUnits.power) ??
        snapshot.hydraulicHp;
    hhpPerArea.value = _convertPowerPerArea(
      snapshot.hydraulicHpPerArea ?? 0,
      AppUnits.power,
      AppUnits.crossSection,
    );
    pressureDropPercent.value = snapshot.pressureDropPercent;
    jetImpactForce.value =
        AppUnits.convertValue(
          snapshot.jetImpactForceLbf ?? 0,
          '(lbf)',
          AppUnits.force,
        ) ??
        (snapshot.jetImpactForceLbf ?? 0);
  }

  void resetBitHydraulics() {
    nozzleArea.value = null;
    nozzleVelocity.value = null;
    bitPressureDrop.value = null;
    hydraulicHP.value = null;
    hhpPerArea.value = null;
    pressureDropPercent.value = null;
    jetImpactForce.value = null;
  }

  bool _hasCompleteInputs() {
    return mw.value.isNotEmpty &&
        pumpOutput.value.isNotEmpty &&
        standpipePressure.value.isNotEmpty &&
        bitSize.value.isNotEmpty;
  }

  double _convertPowerPerArea(
    double value,
    String targetPowerUnit,
    String targetAreaUnit,
  ) {
    final powerFactor = AppUnits.convertValue(1, '(HP)', targetPowerUnit) ?? 1;
    final areaFactor = AppUnits.convertValue(1, '(in2)', targetAreaUnit) ?? 1;
    if (areaFactor == 0) {
      return value;
    }
    return value * powerFactor / areaFactor;
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
