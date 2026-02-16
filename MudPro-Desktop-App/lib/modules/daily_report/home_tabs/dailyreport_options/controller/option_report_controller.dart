import 'package:get/get.dart';

class ReportOptionSummaryController extends GetxController {
  // Dashboard (Up to 3)
  RxList<String> dashboardItems = [
    'Depth with Target',
    'Cost with Budget',
    'Day with Goal',
    'Depth',
    'Cost',
    'Day',
    'Avg. Cost per Unit Length',
    'Avg. Daily Cost',
    'Cost vs. Mud Type',
    'Daily Footage',
    'Calendar',
  ].obs;

  RxSet<String> dashboardSelected = {
    'Depth with Target',
    'Cost with Budget',
    'Day with Goal'
  }.obs;

  // Cost Distribution (Up to 2)
  RxBool top10Product = true.obs;
  RxBool product = false.obs;
  RxBool package = false.obs;
  RxBool service = false.obs;
  RxBool premixedMud = false.obs;
  RxBool engineering = false.obs;
  RxBool allCategories = true.obs;

  RxList<String> groupDropdownValues =
      List.generate(4, (_) => 'Weight Material').obs;

  final List<String> groupList = [
    'Weight Material',
    'Alkalinity',
    'Common Chemical',
    'Emulsifier',
    'Filtration Control',
    'Lubricant / Surfactant',
    'Others',
    'Viscosifier',
    'Wetting Agent',
    'LCM',
    'Defoamer',
    'Wellbore Strengthening',
    'OBM Viscosifier',
    'WBM Thinner',
    'Corrosion Inhibitor',
    'Surfactant / Solvent',
    'OBM Thinner',
    'Biocide',
  ];

  // Progress (Up to 3)
  RxList<String> progressItems = [
    'Depth',
    'Cum. Product Cost',
    'Cum. Package Cost',
    'Cum. Service Cost',
    'Cum. Engineering Cost',
    'Cum. Premixed Mud Cost',
    'Cum. Total Cost',
    'Mud Weight',
    'Funnel Visc.',
    'PV',
    'YP',
    'ROP',
    'RPM',
    'BH ECD',
    'LGS %',
    'LGS',
    'HGS %',
    'HGS',
  ].obs;

  RxSet<String> progressSelected = {
    'Depth',
    'Cum. Total Cost',
    'Mud Weight',
  }.obs;

  void resetDefault() {
    dashboardSelected.clear();
    dashboardSelected.addAll([
      'Depth with Target',
      'Cost with Budget',
      'Day with Goal'
    ]);

    top10Product.value = true;
    allCategories.value = true;

    for (int i = 0; i < groupDropdownValues.length; i++) {
      groupDropdownValues[i] = 'Weight Material';
    }

    progressSelected.clear();
    progressSelected.addAll([
      'Depth',
      'Cum. Total Cost',
      'Mud Weight',
    ]);
  }
}
