import 'package:get/get.dart';

class OptionsReportController extends GetxController {
  // Carry over
  RxBool mudProperties = true.obs;

  // Operation
  RxBool operationEnabled = false.obs;
  RxString operationType = 'All'.obs;

  // Solids Analysis
  RxBool showNegativeValues = false.obs;

  // Mud Vol.
  RxBool checkMudVol = true.obs;

  // Inventory
  RxBool negativeInventoryWarning = true.obs;

  // Multiple Daily Reports
  RxBool multipleDailyReports = false.obs;

  void onSave() {
    // 🔹 API / Local Save Logic
    Get.snackbar('Saved', 'Options saved successfully');
  }
}
