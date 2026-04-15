import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/base_secondary_tababr.dart';
import 'package:mudpro_desktop_app/modules/utility/view/engineering_tools.dart';
import 'package:mudpro_desktop_app/modules/utility/view/unit_Conversion.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import '../controller/dashboard_controller.dart';

class UtilitySecondaryTabbar extends StatelessWidget {
  UtilitySecondaryTabbar({super.key});

  final controller = Get.find<DashboardController>();

  final tabs = const [
    {"title": "Engineering Tools", "icon": Icons.handyman},
    {"title": "Unit Conversion", "icon": Icons.swap_horiz},
    {"title": "Calculator", "icon": Icons.calculate},
    {"title": "Notepad", "icon": Icons.note},
  ];

  @override
  Widget build(BuildContext context) {
    return BaseSecondaryTabBar(
      tabs: tabs,
      activeIndex: controller.activeUtilityTab,
      onTap: (i) {
        controller.activeUtilityTab.value = i;

        switch (i) {
          case 0:
            controller.openOverlay(EngineeringToolsPage());
            break;
          case 1:
            controller.openOverlay(UnitConversionView());
            break;
          case 2:
            controller.openOverlay(const Text("Calculator Page"));
            break;
          case 3:
            controller.openOverlay(const Text("Notepad Page"));
            break;
        }
      },
    );
  }
}
