import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class RightTopTabs extends StatelessWidget {
  RightTopTabs({super.key});

  final c = Get.find<UgStController>();
  final reportC = reportContext;

  final List<Map<String, dynamic>> tabs = const [
    {"label": "Well", "icon": Icons.oil_barrel},
    {"label": "Casing", "icon": Icons.pivot_table_chart_outlined},
    {"label": "Interval", "icon": Icons.list},
    {"label": "Plan", "icon": Icons.timeline},
    {"label": "Survey", "icon": Icons.map},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: List.generate(tabs.length, (i) {
                  return Obx(() {
                    final active = c.selectedWellTab.value == i;
                    final isEnabled = i == 0 || reportC.hasSelectedReport;

                    return Expanded(
                      child: Tooltip(
                        message: isEnabled
                            ? tabs[i]['label'] as String
                            : 'Create and select a report first.',
                        child: GestureDetector(
                          onTap: isEnabled ? () => c.switchWellTab(i) : null,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isEnabled && active
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              color: isEnabled
                                  ? Colors.transparent
                                  : Colors.grey.withValues(alpha: 0.08),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      tabs[i]['icon'],
                                      size: 16,
                                      color: !isEnabled
                                          ? Colors.grey.shade400
                                          : active
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tabs[i]['label'],
                                      style: AppTheme.bodySmall.copyWith(
                                        fontWeight: active
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: !isEnabled
                                            ? Colors.grey.shade400
                                            : active
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Obx(
              () => Container(
                decoration: BoxDecoration(
                  color: c.isLocked.value
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: c.isLocked.value
                        ? AppTheme.errorColor.withOpacity(0.3)
                        : AppTheme.successColor.withOpacity(0.3),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    c.isLocked.value ? Icons.lock : Icons.lock_open,
                    size: 18,
                    color: c.isLocked.value
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                  ),
                  onPressed: c.toggleLock,
                  tooltip: c.isLocked.value ? "Unlock" : "Lock",
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            margin: const EdgeInsets.only(right: 12),
            child: Obx(() {
              final activeTabIndex = c.selectedWellTab.value;
              final activeTabName = tabs[activeTabIndex]['label'];
              return Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activeTabName,
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
