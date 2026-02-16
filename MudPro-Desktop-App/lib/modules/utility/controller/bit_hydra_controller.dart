import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class BitHydraulicsController extends GetxController {
  // ================= INPUTS =================
  final mw = ''.obs;              // Mud weight (ppg)
  final pumpOutput = ''.obs;       // Pump output (gpm)
  final standpipePressure = ''.obs;// Standpipe pressure (psi)
  final bitSize = ''.obs;          // Bit size (in)

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

  // ================= CALCULATION =================
  void calculateBitHydraulics() {
    if (mw.value.isEmpty ||
        pumpOutput.value.isEmpty ||
        standpipePressure.value.isEmpty ||
        bitSize.value.isEmpty) {
      Get.snackbar(
        "Missing Inputs",
        "Please fill all required fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    final mwPpg = double.parse(mw.value);
    final gpm = double.parse(pumpOutput.value);
    final spp = double.parse(standpipePressure.value);
    final bitIn = double.parse(bitSize.value);

    // ---- Jet nozzles sum (1/32 in units) ----
    double totalJetArea = 0;
    for (final j in jetNozzles) {
      if (j.value.isNotEmpty) {
        final size32 = double.parse(j.value);
        final diaIn = size32 / 32;
        totalJetArea += 0.785 * diaIn * diaIn;
      }
    }

    if (totalJetArea == 0) {
      Get.snackbar(
        "Jet Nozzles Missing",
        "Please enter at least one jet nozzle size",
      );
      return;
    }

    // ================= FORMULAS =================
    // Nozzle velocity (ft/s)
    final v = (0.408 * gpm) / totalJetArea;

    // Bit pressure drop (psi)
    final bitDP = spp * 0.65; // standard assumption (as per image)

    // Hydraulic horsepower
    final hhp = (bitDP * gpm) / 1714;

    // HHP per unit bit area
    final bitArea = 0.785 * bitIn * bitIn;
    final hhpArea = hhp / bitArea;

    // Pressure drop %
    final pDropPct = (bitDP / spp) * 100;

    // Jet impact force (lb)
    final impact = (0.01823 * mwPpg * gpm * v);

    // ================= SET OUTPUTS =================
    nozzleArea.value = totalJetArea;
    nozzleVelocity.value = v;
    bitPressureDrop.value = bitDP;
    hydraulicHP.value = hhp;
    hhpPerArea.value = hhpArea;
    pressureDropPercent.value = pDropPct;
    jetImpactForce.value = impact;
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
}
