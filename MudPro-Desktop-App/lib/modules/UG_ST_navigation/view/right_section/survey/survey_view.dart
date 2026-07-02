import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_3d_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_data_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_dogleg_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_plan_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_section_tab.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_setup_ui_pattern.dart';

class SurveyView extends StatelessWidget {
  SurveyView({super.key});

  final SurveyController controller = Get.isRegistered<SurveyController>()
      ? Get.find<SurveyController>()
      : Get.put(SurveyController());

  static const _tabs = ['Data', 'Section', 'Plan', 'Dogleg', '3D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: wellSetupPageBackground,
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
                  Text(
                    'Planned Survey',
                    style: AppTheme.wellLikeBodyText.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: wellSetupColumnHeader,
              border: Border.all(color: wellSetupBorder),
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
                        color: active
                            ? wellSetupSectionHeader
                            : wellSetupColumnHeader,
                        border: Border(
                          right: const BorderSide(color: wellSetupBorder),
                          bottom: BorderSide(
                            color: active
                                ? wellSetupSectionHeader
                                : wellSetupBorder,
                          ),
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        style: AppTheme.wellLikeBodyText.copyWith(
                          fontSize: 11,
                          color: active ? Colors.white : Colors.black,
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
                border: Border.all(color: wellSetupBorder),
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
