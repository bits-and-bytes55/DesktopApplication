import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/casing_view.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_view.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/plan_view.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/section_bar.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_view.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_view.dart';


class RightPanel extends StatelessWidget {
  final c = Get.find<UgStController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RightTopTabs(),
        Expanded(
          child: Obx(() {
            switch (c.selectedWellTab.value) {
              case 0:
                return WellView();
              case 1:
                return CasingView();
              case 2:
                return IntervalView();
              case 3:
                return PlanPageView();
              case 4:
                return SurveyView();
              default:
                return WellView();
            }
          }),
        ),
      ],
    );
  }
}
