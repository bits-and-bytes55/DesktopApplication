import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/controller/wbm_report_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/base_secondary_tababr.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_home_page.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/report_manager_view.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/view/well_comparision_view.dart';

class ReportSecondaryTabbar extends StatelessWidget {
  ReportSecondaryTabbar({super.key});

  final controller = Get.find<DashboardController>();

  final tabs = const [
    {"title": "Report Manager", "icon": Icons.assignment},
    {"title": "Well Comparison", "icon": Icons.compare},
    {"title": "Recap", "icon": Icons.refresh},
    {"title": "Cost of Pad", "icon": Icons.attach_money},
  ];

  @override
  Widget build(BuildContext context) {
    return BaseSecondaryTabBar(
      tabs: tabs,
      activeIndex: controller.activeReportTab,
      onTap: (i) async {
        controller.activeReportTab.value = i;

        switch (i) {
          case 0:
            controller.openOverlay(ReportManagerPage());
            break;
          case 1:
            controller.openOverlay(WellComparisonPage());
            break;
          case 2:
            Get.to(() => RecapHomePage());
            break;
          case 3:
            controller.closeOverlay();
            await _openCostOfPadExport();
            break;
        }
      },
    );
  }

  Future<void> _openCostOfPadExport() async {
    try {
      await ExportController.downloadAndOpenCostOfPadReport();
    } catch (e) {
      Get.snackbar(
        'Cost of Pad',
        e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
