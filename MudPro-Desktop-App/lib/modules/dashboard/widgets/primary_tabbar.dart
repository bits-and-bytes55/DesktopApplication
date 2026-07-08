import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/admin_control/admin_control_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

import '../controller/dashboard_controller.dart';

class PrimaryTabBar extends StatelessWidget {
  PrimaryTabBar({super.key});

  final controller = Get.find<DashboardController>();
  final adminC = Get.isRegistered<AdminControlController>()
      ? Get.find<AdminControlController>()
      : Get.put(AdminControlController(), permanent: true);
  final reportC = reportContext;
  final tabs = const ["Home", "Report", "Utility", "Help", "Admin Control"];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FBFD),
        border: Border(bottom: BorderSide(color: Color(0xFFD9E3EE))),
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(tabs.length, (index) {
            final isActive = controller.activePrimaryTab.value == index;
            final isAuthorized = adminC.isDeviceAllowed.value;
            final isEnabled =
                index == 4 || (isAuthorized && (index == 0 || reportC.hasSelectedReport));

            return Container(
              margin: EdgeInsets.only(left: index == 0 ? 8 : 2),
              child: MouseRegion(
                cursor: isEnabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.forbidden,
                child: Tooltip(
                  message: isEnabled
                      ? tabs[index]
                      : isAuthorized
                          ? 'Create and select a report first.'
                          : 'Device authorization required. Open Admin Control.',
                  child: GestureDetector(
                    onTap: isEnabled
                        ? () => controller.activePrimaryTab.value = index
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      alignment: Alignment.center,
                      height: 44,
                      constraints: const BoxConstraints(minWidth: 106),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled && isActive
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        boxShadow: isEnabled && isActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.18),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTabIcon(index),
                            size: 16,
                            color: !isEnabled
                                ? Colors.grey.shade400
                                : isActive
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tabs[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: !isEnabled
                                  ? Colors.grey.shade400
                                  : isActive
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
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

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.assignment;
      case 2:
        return Icons.build;
      case 3:
        return Icons.help;
      case 4:
        return Icons.admin_panel_settings;
      default:
        return Icons.circle;
    }
  }
}
