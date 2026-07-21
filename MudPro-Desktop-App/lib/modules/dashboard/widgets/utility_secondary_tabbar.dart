import 'dart:io';

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
            controller.closeOverlay();
            _openSystemCalculator();
            break;
          case 3:
            controller.closeOverlay();
            _openSystemNotepad();
            break;
        }
      },
    );
  }

  Future<void> _openSystemCalculator() async {
    try {
      await Process.start('calc.exe', const []);
    } catch (_) {
      try {
        await Process.start('explorer.exe', const ['calculator:']);
      } catch (_) {
        Get.snackbar(
          'Calculator',
          'Unable to open system calculator.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _openSystemNotepad() async {
    try {
      await Process.start('notepad.exe', const []);
    } catch (_) {
      Get.snackbar(
        'Notepad',
        'Unable to open system notepad.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
