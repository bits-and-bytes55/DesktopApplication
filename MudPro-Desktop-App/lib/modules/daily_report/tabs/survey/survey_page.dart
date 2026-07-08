import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_view.dart';

class SurveyPage extends StatelessWidget {
  const SurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UgStController>()) {
      Get.put(UgStController());
    }
    if (Get.isRegistered<SurveyController>()) {
      Get.find<SurveyController>().forceEditable.value = true;
    } else {
      Get.put(SurveyController()).forceEditable.value = true;
    }
    return SurveyView();
  }
}
