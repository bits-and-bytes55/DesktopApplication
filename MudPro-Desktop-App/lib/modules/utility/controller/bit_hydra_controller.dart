import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

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
  var _unitSyncScheduled = false;
  late String _mudWeightUnit;
  late String _flowUnit;
  late String _pressureUnit;
  late String _diameterUnit;
  late String _nozzleUnit;

  @override
  void onInit() {
    super.onInit();
    _mudWeightUnit = AppUnits.mudWeight;
    _flowUnit = AppUnits.drillingFlowRate;
    _pressureUnit = AppUnits.pressure;
    _diameterUnit = AppUnits.diameter;
    _nozzleUnit = AppUnits.nozzleDiameter;
    _unitWorkers.addAll([
      ever(_options.unitSystem, (_) => _scheduleUnitChange()),
      ever(_options.selectedCustomSystemId, (_) => _scheduleUnitChange()),
      ever(_options.customUnits, (_) => _scheduleUnitChange()),
    ]);
  }

  @override
  void onClose() {
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    super.onClose();
  }

  void _scheduleUnitChange() {
    if (_unitSyncScheduled) return;
    _unitSyncScheduled = true;
    scheduleMicrotask(() {
      _unitSyncScheduled = false;
      if (!isClosed) _handleUnitChange();
    });
  }

  void _handleUnitChange() {
    final nextMudWeight = AppUnits.mudWeight;
    final nextFlow = AppUnits.drillingFlowRate;
    final nextPressure = AppUnits.pressure;
    final nextDiameter = AppUnits.diameter;
    final nextNozzle = AppUnits.nozzleDiameter;
    if (_mudWeightUnit == nextMudWeight &&
        _flowUnit == nextFlow &&
        _pressureUnit == nextPressure &&
        _diameterUnit == nextDiameter &&
        _nozzleUnit == nextNozzle) {
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
    for (final jet in jetNozzles) {
      jet.value = _convertText(jet.value, _nozzleUnit, nextNozzle);
    }

    _mudWeightUnit = nextMudWeight;
    _flowUnit = nextFlow;
    _pressureUnit = nextPressure;
    _diameterUnit = nextDiameter;
    _nozzleUnit = nextNozzle;

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

    if (mwPpg <= 0 || gpm <= 0 || spp <= 0 || bitIn <= 0) {
      resetBitHydraulics();
      Get.snackbar('Invalid Inputs', 'All input values must be greater than 0');
      return;
    }

    double totalJetArea = 0;
    for (final jet in jetNozzles) {
      if (jet.value.isEmpty) {
        continue;
      }
      final nozzleInput = double.tryParse(jet.value);
      if (nozzleInput == null || nozzleInput <= 0) {
        continue;
      }
      final diaIn =
          AppUnits.convertValue(
            nozzleInput,
            AppUnits.nozzleDiameter,
            '(in)',
          ) ??
          nozzleInput;
      totalJetArea += (math.pi / 4) * diaIn * diaIn;
    }

    if (totalJetArea == 0) {
      Get.snackbar(
        'Jet Nozzles Missing',
        'Please enter at least one jet nozzle size',
      );
      return;
    }

    final nozzleVelocityBase = (0.32086 * gpm) / totalJetArea;
    final bitPressureDropBase =
        (mwPpg * gpm * gpm) / (10858 * totalJetArea * totalJetArea);
    final hydraulicHpBase = (bitPressureDropBase * gpm) / 1714;
    final hhpPerAreaBase = (1.27314 * hydraulicHpBase) / (bitIn * bitIn);
    final pressureDropPct = (bitPressureDropBase / spp) * 100;
    final jetImpactBase = (mwPpg * gpm * nozzleVelocityBase) / 1932;

    nozzleArea.value =
        AppUnits.convertValue(totalJetArea, '(in2)', AppUnits.crossSection) ??
        totalJetArea;
    nozzleVelocity.value =
        AppUnits.convertValue(
          nozzleVelocityBase,
          '(ft/s)',
          AppUnits.nozzleVelocity,
        ) ??
        nozzleVelocityBase;
    bitPressureDrop.value =
        AppUnits.convertValue(
          bitPressureDropBase,
          '(psi)',
          AppUnits.pressure,
        ) ??
        bitPressureDropBase;
    hydraulicHP.value =
        AppUnits.convertValue(hydraulicHpBase, '(HP)', AppUnits.power) ??
        hydraulicHpBase;
    hhpPerArea.value = _convertPowerPerArea(
      hhpPerAreaBase,
      AppUnits.power,
      AppUnits.crossSection,
    );
    pressureDropPercent.value = pressureDropPct;
    jetImpactForce.value =
        AppUnits.convertValue(jetImpactBase, '(lbf)', AppUnits.force) ??
        jetImpactBase;
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
    return formatOperationNumber(
      value,
      fallbackDecimals: 4,
      trimFallback: true,
    );
  }
}
