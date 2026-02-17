import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/utility/subtabs/eng_bit_hydra_view.dart';
import 'package:mudpro_desktop_app/modules/utility/subtabs/eng_hydraulics_annularvelocity.dart';
import '../controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class HydraulicsPage extends StatelessWidget {
  HydraulicsPage({super.key});

  final c = Get.find<EngineeringToolsController>();

  final subTabs = const [
    "Annular Velocity",
    "Bit Hydraulics",
    "Critical Velocity (Annulus)",
    "Critical Velocity (Pipe)",
    "ECD",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= HYDRAULICS HEADER =================
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.speed, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                "Hydraulics Tools",
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subTabs[c.activeHydraulicsTab.value],
                      style: AppTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )),
            ],
          ),
        ),

        // ================= HYDRAULICS SUB TABS =================
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Obx(() => Row(
                children: List.generate(subTabs.length, (index) {
                  final isActive = c.activeHydraulicsTab.value == index;
                  return Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => c.activeHydraulicsTab.value = index,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isActive ? AppTheme.primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              subTabs[index],
                              style: AppTheme.caption.copyWith(
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              )),
        ),

        // ================= SUB TAB CONTENT =================
        Expanded(
          child: Obx(() {
            switch (c.activeHydraulicsTab.value) {
              case 0:
                return const HydraulicsAnnularVelocity();
              case 1:
                return const BitHydraulicsPage();
              case 2:
                return _emptyContent("Critical Velocity (Pipe)");
              case 3:
                return _emptyContent("ECD");
              default:
                return const SizedBox();
            }
          }),
        ),
      ],
    );
  }

  Widget _emptyContent(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "UI will be added soon",
            style: AppTheme.caption.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}