import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/utility/widgets/eng_hydraulics.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class EngineeringToolsPage extends StatelessWidget {
  EngineeringToolsPage({super.key});

  final controller = Get.put(EngineeringToolsController());

  final mainTabs = const [
    "Hydraulics",
    "Pressure",
    "Mud Weight",
    "Volume",
    "Pump Out",
    "Oil Mud",
    "Max ROP",
    "Solids Removal",
    "Cost Effectiveness of SCE",
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: engineeringDataText,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: engineeringPage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ================= HEADER =================
       

          // ================= MAIN TABS =================
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: engineeringColumn,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: engineeringBorder),
            ),
            child: Obx(() => Row(
                  children: List.generate(mainTabs.length, (index) {
                    final isActive = controller.activeMainTab.value == index;
                    return Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => controller.activeMainTab.value = index,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? engineeringSection
                                  : engineeringColumn,
                              border: Border(
                                bottom: BorderSide(
                                  color: isActive
                                      ? engineeringSection
                                      : engineeringGrid,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                mainTabs[index],
                                style: engineeringDataText.copyWith(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.black,
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

          const SizedBox(height: 10),

          // ================= CONTENT =================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: engineeringBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Obx(() {
                if (controller.activeMainTab.value == 0) {
                  return HydraulicsPage();
                }
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
                        "${mainTabs[controller.activeMainTab.value]} Tool",
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "UI will be added",
                        style: AppTheme.caption.copyWith(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
