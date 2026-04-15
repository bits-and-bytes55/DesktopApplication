import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OptionsLeftPanel extends StatelessWidget {
  const OptionsLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OptionsController>();

    final tabs = [
      'Unit',
      'Report',
      'Language',
      'Network',
      'Backup',
    ];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        // Tabs
        Expanded(
          child: Obx(() {
            final selectedIndex = controller.selectedTab.value;

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final selected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: selected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: selected ? AppTheme.primaryColor : Colors.transparent,
                        width: selected ? 1 : 0,
                      ),
                    ),
                    color: selected ? Colors.white : Colors.transparent,
                    child: InkWell(
                      onTap: () => controller.selectedTab.value = index,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              _getTabIcon(index),
                              color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              tabs[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.square_foot_outlined;
      case 1:
        return Icons.description_outlined;
      case 2:
        return Icons.language_outlined;
      case 3:
        return Icons.network_check_outlined;
      case 4:
        return Icons.backup_outlined;
      default:
        return Icons.settings_outlined;
    }
  }
}