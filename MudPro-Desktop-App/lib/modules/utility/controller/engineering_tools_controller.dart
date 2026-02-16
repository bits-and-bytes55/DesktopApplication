import 'package:get/get.dart';

class EngineeringToolsController extends GetxController {
  // Main Engineering Tabs
  var activeMainTab = 0.obs;

  // Hydraulics Sub Tabs
  var activeHydraulicsTab = 0.obs;

  // Annular Velocity Inputs
  var pumpOutput = ''.obs; // bpm
  var holeSize = ''.obs;   // inches
  var pipeOD = ''.obs;     // inches

  var annularVelocity = RxnDouble();

  void calculateAnnularVelocity() {
    if (pumpOutput.value.isEmpty || holeSize.value.isEmpty || pipeOD.value.isEmpty) {
      Get.snackbar('Error', 'All fields are required');
      return;
    }

    final q = double.tryParse(pumpOutput.value);
    final dh = double.tryParse(holeSize.value);
    final dp = double.tryParse(pipeOD.value);

    if (q == null || dh == null || dp == null) {
      annularVelocity.value = null;
      return;
    }

    if (dh <= dp || q <= 0) {
      annularVelocity.value = null;
      return;
    }

    // Fixed Formula: AV = (24.51 * Pump Output) / (Hole Size² - Pipe OD²)
    final denominator = (dh * dh) - (dp * dp);
    if (denominator <= 0) {
      annularVelocity.value = null;
      return;
    }

    final av = (24.51 * q) / denominator;
    annularVelocity.value = av;
  }

  void resetAnnularVelocity() {
    pumpOutput.value = '';
    holeSize.value = '';
    pipeOD.value = '';
    annularVelocity.value = null;
  }
}