import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/help/view/abbreviation_page.dart';
import 'package:mudpro_desktop_app/modules/help/view/about_page.dart';
import 'package:mudpro_desktop_app/modules/help/view/disclaimer_page.dart';
import 'package:mudpro_desktop_app/modules/help/view/user_manual_page.dart';
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
    return Container(
      height: 42,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(bottom: BorderSide(color: AppTheme.tableBorderBlue)),
      ),
      child: Obx(
        () => Row(
          children: List.generate(tabs.length, (index) {
            final isActive = controller.activeHelpTab.value == index;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: InkWell(
                  onTap: () => _openTab(index),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primaryColor
                          : AppTheme.tableHeaderBlue,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(5)),
                      border: Border.all(color: AppTheme.tableBorderBlue),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tabs[index]["icon"] as IconData,
                          size: 14,
                          color: isActive ? Colors.white : AppTheme.textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tabs[index]["title"].toString(),
                          style: AppTheme.bodyLarge.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color:
                                isActive ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _openTab(int index) {
    controller.activeHelpTab.value = index;

    switch (index) {
      case 0:
        controller.openOverlay(const UserManualPage());
        break;
      case 1:
        controller.openOverlay(const AboutPage());
        break;
      case 2:
        controller.openOverlay(const DisclaimerPage());
        break;
      case 3:
        controller.openOverlay(const AbbreviationPage());
        break;
      default:
        controller.openOverlay(
          Center(
            child: Text(
              tabs[index]["title"].toString(),
              style: AppTheme.titleMedium,
            ),
          ),
        );
    }
  }
}
