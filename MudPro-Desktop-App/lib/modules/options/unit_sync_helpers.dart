import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class UnitSyncHelpers {
  UnitSyncHelpers._();

  static void convertTextController(
    TextEditingController controller, {
    required String fromUnit,
    required String toUnit,
    int precision = 4,
  }) {
    final converted = AppUnits.convertText(
      rawValue: controller.text,
      fromUnit: fromUnit,
      toUnit: toUnit,
      precision: precision,
    );
    if (converted == controller.text) {
      return;
    }

    controller.value = TextEditingValue(
      text: converted,
      selection: TextSelection.collapsed(offset: converted.length),
    );
  }

  static void convertRxString(
    RxString value, {
    required String fromUnit,
    required String toUnit,
    int precision = 4,
  }) {
    value.value = AppUnits.convertText(
      rawValue: value.value,
      fromUnit: fromUnit,
      toUnit: toUnit,
      precision: precision,
    );
  }

  static void convertRxDouble(
    RxDouble value, {
    required String fromUnit,
    required String toUnit,
  }) {
    final converted = AppUnits.convertValue(
      value.value,
      fromUnit: fromUnit,
      toUnit: toUnit,
    );
    if (converted != null) {
      value.value = converted;
    }
  }

  static String convertRawText(
    String rawValue, {
    required String fromUnit,
    required String toUnit,
    int precision = 4,
  }) {
    return AppUnits.convertText(
      rawValue: rawValue,
      fromUnit: fromUnit,
      toUnit: toUnit,
      precision: precision,
    );
  }
}
