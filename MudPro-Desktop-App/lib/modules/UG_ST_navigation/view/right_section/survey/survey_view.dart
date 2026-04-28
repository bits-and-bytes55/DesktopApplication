import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_3d_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_data_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_dogleg_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_plan_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_section_tab.dart';

class SurveyView extends StatelessWidget {
  SurveyView({super.key});

  final SurveyController controller = Get.isRegistered<SurveyController>()
      ? Get.find<SurveyController>()
      : Get.put(SurveyController());

  static const _tabs = ['Data', 'Section', 'Plan', 'Dogleg', '3D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F2),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 28,
            child: Obx(
              () => Row(
                children: [
                  Checkbox(
                    value: controller.plannedSurvey.value,
                    onChanged: controller.isLocked
                        ? null
                        : (value) =>
                              controller.setPlannedSurvey(value ?? false),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Text(
                    'Planned Survey',
                    style: TextStyle(fontSize: 13, color: Color(0xFF2F2F2F)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              border: Border.all(color: const Color(0xFFC3C9D1)),
            ),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                return Obx(() {
                  final active = controller.selectedTab.value == index;
                  return GestureDetector(
                    onTap: () => controller.setSelectedTab(index),
                    child: Container(
                      width: index == 4 ? 54 : 62,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : const Color(0xFFF2F2F2),
                        border: Border(
                          right: const BorderSide(color: Color(0xFFC3C9D1)),
                          bottom: BorderSide(
                            color: active
                                ? Colors.white
                                : const Color(0xFFC3C9D1),
                          ),
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF2F2F2F),
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                });
              }),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFC3C9D1)),
              ),
              child: Obx(() {
                switch (controller.selectedTab.value) {
                  case 0:
                    return SurveyDataTab();
                  case 1:
                    return SurveySectionTab();
                  case 2:
                    return SurveyPlanTab();
                  case 3:
                    return SurveyDoglegTab();
                  case 4:
                    return Survey3DTab();
                  default:
                    return SurveyDataTab();
                }
              }),
            ),
          ),
        ],
      ),
    );
  }
}
