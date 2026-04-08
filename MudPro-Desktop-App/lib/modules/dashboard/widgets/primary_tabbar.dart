import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

import '../controller/dashboard_controller.dart';

class PrimaryTabBar extends StatelessWidget {
  PrimaryTabBar({super.key});

  final controller = Get.find<DashboardController>();
  final reportC = reportContext;
  final tabs = const ["Home", "Report", "Utility", "Help"];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(tabs.length, (index) {
            final isActive = controller.activePrimaryTab.value == index;
            final isEnabled = index == 0 || reportC.hasSelectedReport;

            return Container(
              margin: EdgeInsets.only(left: index == 0 ? 8 : 4, right: 4),
              child: MouseRegion(
                cursor: isEnabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.forbidden,
                child: Tooltip(
                  message: isEnabled
                      ? tabs[index]
                      : 'Create and select a report first.',
                  child: GestureDetector(
                    onTap: isEnabled
                        ? () => controller.activePrimaryTab.value = index
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isEnabled && isActive
                            ? AppTheme.primaryGradient
                            : null,
                        color: isEnabled
                            ? (isActive ? null : Colors.transparent)
                            : Colors.grey.withValues(alpha: 0.08),
                        border: Border(
                          bottom: BorderSide(
                            color: isEnabled && isActive
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        boxShadow: isEnabled && isActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
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
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: !isEnabled
                                  ? Colors.grey.shade400
                                  : isActive
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              letterSpacing: 0.3,
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
      default:
        return Icons.circle;
    }
  }
}
