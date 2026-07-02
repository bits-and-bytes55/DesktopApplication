import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_setup_ui_pattern.dart';

class RightTopTabs extends StatelessWidget {
  RightTopTabs({super.key});

  final c = Get.find<UgStController>();
  final reportC = reportContext;

  final List<String> tabs = const [
    'Well',
    'Casing',
    'Interval',
    'Plan',
    'Survey',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: wellSetupPageBackground,
        border: const Border(bottom: BorderSide(color: wellSetupBorder)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          ...List.generate(tabs.length, (i) {
            return Obx(() {
              final active = c.selectedWellTab.value == i;
              final isEnabled = i == 0 || reportC.hasSelectedReport;

              return Tooltip(
                message: isEnabled
                    ? tabs[i]
                    : 'Create and select a report first.',
                child: GestureDetector(
                  onTap: isEnabled ? () => c.switchWellTab(i) : null,
                  child: Container(
                    width: 92,
                    height: 31,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 2, top: 2, bottom: 2),
                    decoration: BoxDecoration(
                      color: active
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
                            ? active
                                  ? Colors.white
                                  : Colors.black
                            : const Color(0xFFB8BDC6),
                      ),
                    ),
                  ),
                ),
              );
            });
          }),
          const Spacer(),
        ],
      ),
    );
  }
}
