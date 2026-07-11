import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_controller.dart';

const Color operationPageBackground = Color(0xFFEAF3FC);
const Color operationLockedEditableColor = Color(0xFFFFF7CC);

const TextStyle operationDataTextStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Colors.black,
);

int? operationCompanyFormatDigits() {
  if (!Get.isRegistered<CompanyController>()) return null;
  final format = Get.find<CompanyController>().currencyFormat.value.trim();
  if (format.isEmpty || format == 'Default') return null;
  final dot = format.indexOf('.');
  return dot < 0 ? 0 : (format.length - dot - 1).clamp(0, 6).toInt();
}

String _trimOperationFixedZeros(String value) =>
    value.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

String formatOperationNumber(
  double value, {
  int fallbackDecimals = 2,
  bool trimFallback = false,
}) {
  if (value.isNaN || value.isInfinite) return '';
  final digits = operationCompanyFormatDigits();
  if (digits != null) return value.toStringAsFixed(digits);
  final fixed = value.toStringAsFixed(fallbackDecimals);
  return trimFallback ? _trimOperationFixedZeros(fixed) : fixed;
}

String formatOperationInputText(
  String value, {
  int fallbackDecimals = 2,
  bool trimFallback = false,
}) {
  final text = value.trim();
  if (text.isEmpty) return '';
  final parsed = double.tryParse(text.replaceAll(',', ''));
  if (parsed == null) return value;
  return formatOperationNumber(
    parsed,
    fallbackDecimals: fallbackDecimals,
    trimFallback: trimFallback,
  );
}

double roundOperationNumber(double value, {int fallbackDecimals = 2}) {
  final formatted = formatOperationNumber(
    value,
    fallbackDecimals: fallbackDecimals,
  );
  return double.tryParse(formatted) ?? value;
}
