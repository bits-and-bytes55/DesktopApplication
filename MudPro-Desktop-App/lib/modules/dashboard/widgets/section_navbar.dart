import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_setup_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';

class SectionNavBar extends StatelessWidget {
  SectionNavBar({super.key});

  final tabs = const [
    'Well',
    'Mud',
    'Pump',
    'Operation',
    'Pit',
    'Remarks',
  ];
  final c = Get.find<DashboardController>();
  final reportC = reportContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: wellSetupPageBackground,
        border: Border(bottom: BorderSide(color: wellSetupBorder)),
      ),
      child: Obx(
        () => Row(
          children: List.generate(tabs.length, (i) {
            final isActive = c.activeSectionTab.value == i;
            final isEnabled = i == 0 || reportC.hasSelectedReport;

            return MouseRegion(
              cursor: isEnabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.forbidden,
              child: Tooltip(
                message: isEnabled
                    ? tabs[i]
                    : 'Create and select a report first.',
                child: GestureDetector(
                  onTap: isEnabled ? () => c.activeSectionTab.value = i : null,
                  child: Container(
                    width: 92,
                    height: 31,
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(
                      left: i == 0 ? 6 : 0,
                      right: 2,
                      top: 2,
                      bottom: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? wellSetupSectionHeader
                          : wellSetupColumnHeader,
                      border: Border.all(color: wellSetupBorder),
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isEnabled
                            ? isActive
                                  ? Colors.white
                                  : Colors.black
                            : const Color(0xFFB8BDC6),
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
}
