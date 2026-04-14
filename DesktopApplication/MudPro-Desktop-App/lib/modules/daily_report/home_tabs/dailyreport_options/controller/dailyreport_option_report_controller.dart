import 'package:get/get.dart';

class DailyReportOptionController extends GetxController {
  // Daily Report Page
  RxString pageCount = '1 Page'.obs;
  RxBool showUsedOnly = false.obs;

  // Report Page Size
  RxString pageSize = 'Legal'.obs;

  // Daily Report
  RxBool productPrice = false.obs;
  RxBool productCost = true.obs;

  // Total Cost
  RxString totalCostType = 'Previous Total Cost'.obs;
  RxBool cdcAnnularHydraulicTable = true.obs;
  RxBool detailedPitInformation = false.obs;

  void resetDefault() {
    pageCount.value = '1 Page';
    showUsedOnly.value = false;
    pageSize.value = 'Legal';
    productPrice.value = false;
    productCost.value = true;
    totalCostType.value = 'Previous Total Cost';
    cdcAnnularHydraulicTable.value = true;
    detailedPitInformation.value = false;
  }
}
