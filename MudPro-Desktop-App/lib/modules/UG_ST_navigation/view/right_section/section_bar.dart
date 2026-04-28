import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';

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
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
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
                      color: active ? Colors.white : const Color(0xFFF7F7F7),
                      border: Border.all(color: const Color(0xFFBFC4CC)),
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isEnabled
                            ? const Color(0xFF2F2F2F)
                            : const Color(0xFFB8BDC6),
                      ),
                    ),
                  ),
                ),
              );
            });
          }),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Obx(
              () => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFBFC4CC)),
                ),
                child: IconButton(
                  icon: Icon(
                    c.isLocked.value ? Icons.lock : Icons.lock_open,
                    size: 15,
                    color: const Color(0xFF5B6470),
                  ),
                  onPressed: c.toggleLock,
                  tooltip: c.isLocked.value ? "Unlock" : "Lock",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
