import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/base_secondary_tababr.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import '../controller/dashboard_controller.dart';

class HelpSecondaryTabbar extends StatelessWidget {
  HelpSecondaryTabbar({super.key});

  final controller = Get.find<DashboardController>();

  final tabs = const [
    {"title": "User Manual", "icon": Icons.menu_book},
    {"title": "About", "icon": Icons.info},
    {"title": "Disclaimer", "icon": Icons.warning},
    {"title": "Abbreviation", "icon": Icons.short_text},
  ];

  @override
  Widget build(BuildContext context) {
    return BaseSecondaryTabBar(
      tabs: tabs,
      onTap: (index) {
        controller.activeSecondaryTab.value = index;

        // 🔹 Overlay pages later
        // controller.openOverlay(UserManualPage());
      }, activeIndex: controller.activeHelpTab,
    );
  }
}
