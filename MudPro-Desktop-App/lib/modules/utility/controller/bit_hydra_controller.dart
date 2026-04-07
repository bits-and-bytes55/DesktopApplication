import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class BitHydraulicsController extends GetxController {
  final mw = ''.obs;
  final pumpOutput = ''.obs;
  final standpipePressure = ''.obs;
  final bitSize = ''.obs;
  final jetNozzles = List.generate(10, (_) => ''.obs);

  final nozzleArea = RxnDouble();
  final nozzleVelocity = RxnDouble();
  final bitPressureDrop = RxnDouble();
  final hydraulicHP = RxnDouble();
  final hhpPerArea = RxnDouble();
  final pressureDropPercent = RxnDouble();
  final jetImpactForce = RxnDouble();

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

  void calculateBitHydraulics() {
    if (mw.value.isEmpty ||
        pumpOutput.value.isEmpty ||
        standpipePressure.value.isEmpty ||
        bitSize.value.isEmpty) {
      Get.snackbar(
        'Missing Inputs',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    final mwDisplay = double.tryParse(mw.value);
    final pumpOutputDisplay = double.tryParse(pumpOutput.value);
    final standpipePressureDisplay = double.tryParse(standpipePressure.value);
    final bitSizeDisplay = double.tryParse(bitSize.value);

    if (mwDisplay == null ||
        pumpOutputDisplay == null ||
        standpipePressureDisplay == null ||
        bitSizeDisplay == null) {
      return;
    }

    final mwBase = AppUnits.parameterToBase(
      mwDisplay,
      paramNumber: '33',
      baseUnit: '(ppg)',
    );
    final pumpOutputBase = AppUnits.parameterToBase(
      pumpOutputDisplay,
      paramNumber: '17',
      baseUnit: '(gpm)',
    );
    final standpipePressureBase = AppUnits.parameterToBase(
      standpipePressureDisplay,
      paramNumber: '22',
      baseUnit: '(psi)',
    );
    final bitSizeBase = AppUnits.parameterToBase(
      bitSizeDisplay,
      paramNumber: '2',
      baseUnit: '(in)',
    );

    if (mwBase == null ||
        pumpOutputBase == null ||
        standpipePressureBase == null ||
        bitSizeBase == null) {
      return;
    }

    double totalJetAreaBase = 0;
    final nozzleDisplayUnit = AppUnits.displayUnit('3', fallback: '(1/32in)');

    for (final nozzle in jetNozzles) {
      if (nozzle.value.isEmpty) {
        continue;
      }

      final nozzleDisplayValue = double.tryParse(nozzle.value);
      if (nozzleDisplayValue == null) {
        continue;
      }

      final nozzleDiameterIn = AppUnits.convertValue(
            nozzleDisplayValue,
            fromUnit: nozzleDisplayUnit,
            toUnit: '(in)',
          ) ??
          (AppUnits.sameUnit(nozzleDisplayUnit, '(1/32in)')
              ? nozzleDisplayValue / 32
              : null);

      if (nozzleDiameterIn == null || nozzleDiameterIn <= 0) {
        continue;
      }

      totalJetAreaBase += 0.785 * nozzleDiameterIn * nozzleDiameterIn;
    }

    if (totalJetAreaBase == 0) {
      Get.snackbar(
        'Jet Nozzles Missing',
        'Please enter at least one jet nozzle size',
      );
      return;
    }

    final nozzleVelocityBase = (0.408 * pumpOutputBase) / totalJetAreaBase;
    final bitPressureDropBase = standpipePressureBase * 0.65;
    final hydraulicHpBase = (bitPressureDropBase * pumpOutputBase) / 1714;
    final bitAreaBase = 0.785 * bitSizeBase * bitSizeBase;
    final hhpPerAreaBase = hydraulicHpBase / bitAreaBase;
    final pressureDropPercentBase = (bitPressureDropBase / standpipePressureBase) * 100;
    final jetImpactForceBase = 0.01823 * mwBase * pumpOutputBase * nozzleVelocityBase;

    nozzleArea.value = AppUnits.parameterFromBase(
          totalJetAreaBase,
          paramNumber: '5',
          baseUnit: '(in2)',
        ) ??
        totalJetAreaBase;
    nozzleVelocity.value = AppUnits.parameterFromBase(
          nozzleVelocityBase,
          paramNumber: '14',
          baseUnit: '(ft/s)',
        ) ??
        nozzleVelocityBase;
    bitPressureDrop.value = AppUnits.parameterFromBase(
          bitPressureDropBase,
          paramNumber: '22',
          baseUnit: '(psi)',
        ) ??
        bitPressureDropBase;
    hydraulicHP.value = AppUnits.parameterFromBase(
          hydraulicHpBase,
          paramNumber: '26',
          baseUnit: '(HP)',
        ) ??
        hydraulicHpBase;
    hhpPerArea.value = AppUnits.convertRatioValue(
          value: hhpPerAreaBase,
          numeratorFromUnit: '(HP)',
          denominatorFromUnit: '(in2)',
          numeratorToUnit: AppUnits.displayUnit('26', fallback: '(HP)'),
          denominatorToUnit: AppUnits.displayUnit('5', fallback: '(in2)'),
        ) ??
        hhpPerAreaBase;
    pressureDropPercent.value = pressureDropPercentBase;
    jetImpactForce.value = AppUnits.parameterFromBase(
          jetImpactForceBase,
          paramNumber: '20',
          baseUnit: '(lbf)',
        ) ??
        jetImpactForceBase;
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

  String get hhpPerAreaUnit {
    return AppUnits.ratioUnit(
      numeratorUnit: AppUnits.displayUnit('26', fallback: '(HP)'),
      denominatorUnit: AppUnits.displayUnit('5', fallback: '(in2)'),
    );
  }

  Map<String, String> _snapshotUnits() {
    return AppUnits.snapshotUnits(
      const ['33', '17', '22', '2', '3', '5', '14', '26', '20'],
    );
  }

  void _syncUnits() {
    final nextUnits = _snapshotUnits();
    if (_knownUnits.isEmpty) {
      _knownUnits = nextUnits;
      return;
    }

    mw.value = AppUnits.convertText(
      rawValue: mw.value,
      fromUnit: _knownUnits['33'] ?? '(ppg)',
      toUnit: nextUnits['33'] ?? '(ppg)',
      precision: 4,
    );
    pumpOutput.value = AppUnits.convertText(
      rawValue: pumpOutput.value,
      fromUnit: _knownUnits['17'] ?? '(gpm)',
      toUnit: nextUnits['17'] ?? '(gpm)',
      precision: 4,
    );
    standpipePressure.value = AppUnits.convertText(
      rawValue: standpipePressure.value,
      fromUnit: _knownUnits['22'] ?? '(psi)',
      toUnit: nextUnits['22'] ?? '(psi)',
      precision: 4,
    );
    bitSize.value = AppUnits.convertText(
      rawValue: bitSize.value,
      fromUnit: _knownUnits['2'] ?? '(in)',
      toUnit: nextUnits['2'] ?? '(in)',
      precision: 4,
    );

    for (final nozzle in jetNozzles) {
      nozzle.value = AppUnits.convertText(
        rawValue: nozzle.value,
        fromUnit: _knownUnits['3'] ?? '(1/32in)',
        toUnit: nextUnits['3'] ?? '(1/32in)',
        precision: 4,
      );
    }

    final currentNozzleArea = nozzleArea.value;
    if (currentNozzleArea != null) {
      nozzleArea.value = AppUnits.convertValue(
            currentNozzleArea,
            fromUnit: _knownUnits['5'] ?? '(in2)',
            toUnit: nextUnits['5'] ?? '(in2)',
          ) ??
          currentNozzleArea;
    }

    final currentNozzleVelocity = nozzleVelocity.value;
    if (currentNozzleVelocity != null) {
      nozzleVelocity.value = AppUnits.convertValue(
            currentNozzleVelocity,
            fromUnit: _knownUnits['14'] ?? '(ft/s)',
            toUnit: nextUnits['14'] ?? '(ft/s)',
          ) ??
          currentNozzleVelocity;
    }

    final currentPressureDrop = bitPressureDrop.value;
    if (currentPressureDrop != null) {
      bitPressureDrop.value = AppUnits.convertValue(
            currentPressureDrop,
            fromUnit: _knownUnits['22'] ?? '(psi)',
            toUnit: nextUnits['22'] ?? '(psi)',
          ) ??
          currentPressureDrop;
    }

    final currentHydraulicHP = hydraulicHP.value;
    if (currentHydraulicHP != null) {
      hydraulicHP.value = AppUnits.convertValue(
            currentHydraulicHP,
            fromUnit: _knownUnits['26'] ?? '(HP)',
            toUnit: nextUnits['26'] ?? '(HP)',
          ) ??
          currentHydraulicHP;
    }

    final currentHhpPerArea = hhpPerArea.value;
    if (currentHhpPerArea != null) {
      hhpPerArea.value = AppUnits.convertRatioValue(
            value: currentHhpPerArea,
            numeratorFromUnit: _knownUnits['26'] ?? '(HP)',
            denominatorFromUnit: _knownUnits['5'] ?? '(in2)',
            numeratorToUnit: nextUnits['26'] ?? '(HP)',
            denominatorToUnit: nextUnits['5'] ?? '(in2)',
          ) ??
          currentHhpPerArea;
    }

    final currentImpactForce = jetImpactForce.value;
    if (currentImpactForce != null) {
      jetImpactForce.value = AppUnits.convertValue(
            currentImpactForce,
            fromUnit: _knownUnits['20'] ?? '(lbf)',
            toUnit: nextUnits['20'] ?? '(lbf)',
          ) ??
          currentImpactForce;
    }

    _knownUnits = nextUnits;
  }
}
