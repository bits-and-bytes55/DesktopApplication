import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import '../controller/dashboard_controller.dart';

class PrimaryTabBar extends StatelessWidget {
  PrimaryTabBar({super.key});

  final controller = Get.find<DashboardController>();
  final tabs = ["Home", "Report", "Utility", "Help"];

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
          mainAxisAlignment: MainAxisAlignment.start, // Changed from default
          children: List.generate(tabs.length, (index) {
            final isActive = controller.activePrimaryTab.value == index;

            return Container( // Changed from Expanded to Container
              margin: EdgeInsets.only(left: index == 0 ? 8 : 4, right: 4), // Added margin
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => controller.activePrimaryTab.value = index,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Adjusted padding
                    decoration: BoxDecoration(
                      gradient: isActive ? AppTheme.primaryGradient : null,
                      color: isActive ? null : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? AppTheme.primaryColor : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ] : null,
                      borderRadius: BorderRadius.only( // Added rounded corners
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Changed to min
                      children: [
                        Icon(
                          _getTabIcon(index),
                          size: 16,
                          color: isActive ? Colors.white : AppTheme.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: isActive ? Colors.white : AppTheme.textPrimary,
                            letterSpacing: 0.3,
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

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0: return Icons.home;
      case 1: return Icons.assignment;
      case 2: return Icons.build;
      case 3: return Icons.help;
      default: return Icons.circle;
    }
  }
}