import 'package:get/get.dart';

class DetailReportController extends GetxController {
  // Left side
  RxBool summary = true.obs;
  RxBool detail = false.obs;

  RxBool dailyCost = true.obs;
  RxBool productChart = true.obs;
  RxBool othersChart = false.obs;
  RxBool tableUsage = false.obs;
  RxBool table = false.obs;

  RxBool totalCost = true.obs;
  RxBool totalCostGraph = true.obs;
  RxBool totalCostTable = false.obs;

  RxBool concentration = true.obs;
  RxBool concGraph = true.obs;
  RxBool tableCurrent = true.obs;
  RxBool tableHistory = false.obs;

  RxBool timeDistribution = true.obs;
  RxBool timeGraph = true.obs;
  RxBool timeTable = false.obs;

  // Right side
  RxBool survey = true.obs;
  RxBool surveyGraph = true.obs;
  RxBool tableActual = false.obs;
  RxBool tablePlanned = false.obs;

  RxBool alert = true.obs;
  RxBool alertSummary = true.obs;
  RxBool alertUsage = true.obs;
  RxBool alertInventory = true.obs;
  RxBool alertTable = false.obs;

  void resetDefault() {
    summary.value = true;
    detail.value = false;

    dailyCost.value = true;
    productChart.value = true;
    othersChart.value = false;
    tableUsage.value = false;
    table.value = false;

    totalCost.value = true;
    totalCostGraph.value = true;
    totalCostTable.value = false;

    concentration.value = true;
    concGraph.value = true;
    tableCurrent.value = true;
    tableHistory.value = false;

    timeDistribution.value = true;
    timeGraph.value = true;
    timeTable.value = false;

    survey.value = true;
    surveyGraph.value = true;
    tableActual.value = false;
    tablePlanned.value = false;

    alert.value = true;
    alertSummary.value = true;
    alertUsage.value = true;
    alertInventory.value = true;
    alertTable.value = false;
  }
}
