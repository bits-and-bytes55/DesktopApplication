import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class IntervalLeftPanel extends StatelessWidget {
  const IntervalLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<UgStController>();

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.list, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "Intervals",
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${c.intervals.length} items",
                    style: AppTheme.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ],
            ),
          ),

          // INTERVALS LIST
          Expanded(
            child: Obx(() => ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: c.intervals.length,
              itemBuilder: (_, i) {
                final selected = c.selectedIndex.value == i;
                return GestureDetector(
                  onTap: () => c.select(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: selected 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected 
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: selected 
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: AppTheme.caption.copyWith(
                                color: selected 
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.intervals[i],
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: selected 
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected 
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                      ],
                    ),
                  ),
                );
              },
            )),
          ),

          // BUTTONS SECTION
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                _actionButton(
                  Icons.add_circle_outline,
                  "Insert Before",
                  c.insertBefore,
                ),
                const SizedBox(height: 8),
                _actionButton(
                  Icons.add_circle_outline,
                  "Insert After",
                  c.insertAfter,
                ),
                const SizedBox(height: 8),
                _actionButton(
                  Icons.remove_circle_outline,
                  "Remove Interval",
                  c.removeInterval,
                  danger: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String text,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: danger 
              ? AppTheme.errorColor.withOpacity(0.1)
              : AppTheme.primaryColor.withOpacity(0.1),
          foregroundColor: danger 
              ? AppTheme.errorColor
              : AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: danger 
                  ? AppTheme.errorColor.withOpacity(0.3)
                  : AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}