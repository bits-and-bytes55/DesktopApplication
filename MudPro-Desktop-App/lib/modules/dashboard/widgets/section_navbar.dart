import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F4F4),
        border: Border(bottom: BorderSide(color: Color(0xFFC8CCD1))),
      ),
      child: Obx(
        () => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(tabs.length, (i) {
            final isActive = c.activeSectionTab.value == i;
            final isEnabled = i == 0 || reportC.hasSelectedReport;

            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: MouseRegion(
                cursor: isEnabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.forbidden,
                child: Tooltip(
                  message: isEnabled
                      ? tabs[i]
                      : 'Create and select a report first.',
                  child: GestureDetector(
                    onTap: isEnabled
                        ? () => c.activeSectionTab.value = i
                        : null,
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : const Color(0xFFF4F4F4),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFC8CCD1)
                              : Colors.transparent,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        tabs[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: !isEnabled
                              ? Colors.grey.shade400
                              : Colors.black,
                        ),
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
