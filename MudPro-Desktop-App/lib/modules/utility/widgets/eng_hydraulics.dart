import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/utility/subtabs/eng_hydraulics_compact.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';
import '../controller/engineering_tools_controller.dart';

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
        // ================= HYDRAULICS SUB TABS =================
        Container(
          height: 36,
          decoration: const BoxDecoration(
            color: engineeringColumn,
            border: Border(bottom: BorderSide(color: engineeringGrid)),
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
                              subTabs[index],
                              style: engineeringDataText.copyWith(
                                color: isActive ? Colors.white : Colors.black,
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
            return HydraulicsCompactTool(
              tabIndex: c.activeHydraulicsTab.value,
            );
          }),
        ),
      ],
    );
  }
}
