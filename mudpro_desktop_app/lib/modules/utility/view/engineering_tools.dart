import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
       

          // ================= MAIN TABS =================
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
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
                              color: isActive ? AppTheme.primaryColor : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: isActive ? AppTheme.primaryColor : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                mainTabs[index],
                                style: AppTheme.caption.copyWith(
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  color: isActive ? Colors.white : AppTheme.textSecondary,
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

          const SizedBox(height: 16),

          // ================= CONTENT =================
          Expanded(
            child: Container(
              decoration: AppTheme.cardDecoration.copyWith(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
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
    );
  }
}