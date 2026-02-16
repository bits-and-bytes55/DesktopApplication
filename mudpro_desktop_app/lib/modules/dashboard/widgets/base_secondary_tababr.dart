import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import '../controller/dashboard_controller.dart';

class BaseSecondaryTabBar extends StatelessWidget {
  final List<Map<String, dynamic>> tabs;
  final Function(int) onTap;
  final RxInt activeIndex;

  const BaseSecondaryTabBar({
    super.key,
    required this.tabs,
    required this.onTap,
    required this.activeIndex,
  });

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
          children: List.generate(tabs.length, (index) {
            final isActive = activeIndex.value == index;

            return Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isActive ? AppTheme.primaryGradient : null,
                      border: Border(
                        bottom: BorderSide(
                          color: isActive
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tabs[index]["icon"],
                          size: 15,
                          color:
                              isActive ? Colors.white : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tabs[index]["title"],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.normal,
                            color:
                                isActive ? Colors.white : AppTheme.textPrimary,
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
}
