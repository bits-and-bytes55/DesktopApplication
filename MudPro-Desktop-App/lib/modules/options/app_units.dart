import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/unit_conversion_service.dart';
import 'package:mudpro_desktop_app/modules/options/unit_label_formatter.dart';

class AppUnits {
  AppUnits._();

  static final UnitConversionService _conversion = UnitConversionService.instance;

  static OptionsController? get _options =>
      Get.isRegistered<OptionsController>() ? Get.find<OptionsController>() : null;

  static String displayUnit(String paramNumber, {String fallback = '-'}) {
    final unit = _options?.getUnitForParameter(paramNumber) ?? fallback;
    if (unit.trim().isEmpty) {
      return fallback;
    }
    return unit;
  }

  static String stripBrackets(String unit) {
    final trimmed = unit.trim();
    if (trimmed.startsWith('(') && trimmed.endsWith(')') && trimmed.length > 1) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool sameUnit(String left, String right) {
    return UnitLabelFormatter.canonicalize(left) ==
        UnitLabelFormatter.canonicalize(right);
  }

  static String activeSystemLabel() {
    return _options?.activeUnitSystemLabel ?? 'US Oil Field';
  }

  static Map<String, String> snapshotUnits(Iterable<String> paramNumbers) {
    final controller = _options;
    if (controller == null) {
      return {
        for (final paramNumber in paramNumbers) paramNumber: displayUnit(paramNumber),
      };
    }
    return controller.snapshotUnits(paramNumbers);
  }

  static double? convertValue(
    double value, {
    required String fromUnit,
    required String toUnit,
  }) {
    if (sameUnit(fromUnit, toUnit)) {
      return value;
    }
    return _conversion.convertValue(value, fromUnit, toUnit);
  }

  static double? parameterToBase(
    double value, {
    required String paramNumber,
    required String baseUnit,
  }) {
    return convertValue(
      value,
      fromUnit: displayUnit(paramNumber, fallback: baseUnit),
      toUnit: baseUnit,
    );
  }

  static double? parameterFromBase(
    double value, {
    required String paramNumber,
    required String baseUnit,
  }) {
    return convertValue(
      value,
      fromUnit: baseUnit,
      toUnit: displayUnit(paramNumber, fallback: baseUnit),
    );
  }

  static double? convertRatioValue({
    required double value,
    required String numeratorFromUnit,
    required String denominatorFromUnit,
    required String numeratorToUnit,
    required String denominatorToUnit,
  }) {
    final numeratorFactor = convertValue(
      1,
      fromUnit: numeratorFromUnit,
      toUnit: numeratorToUnit,
    );
    final denominatorFactor = convertValue(
      1,
      fromUnit: denominatorFromUnit,
      toUnit: denominatorToUnit,
    );

    if (numeratorFactor == null ||
        denominatorFactor == null ||
        denominatorFactor == 0) {
      return null;
    }

    return value * numeratorFactor / denominatorFactor;
  }

  static String convertText({
    required String rawValue,
    required String fromUnit,
    required String toUnit,
    int precision = 4,
  }) {
    if (rawValue.trim().isEmpty || rawValue.trim() == '-') {
      return rawValue;
    }

    final parsed = double.tryParse(rawValue);
    if (parsed == null) {
      return rawValue;
    }

    final converted = convertValue(parsed, fromUnit: fromUnit, toUnit: toUnit);
    if (converted == null) {
      return rawValue;
    }

    return formatNumber(converted, precision: precision);
  }

  static String convertParameterText({
    required String rawValue,
    required String paramNumber,
    required String fromUnit,
    int precision = 4,
  }) {
    return convertText(
      rawValue: rawValue,
      fromUnit: fromUnit,
      toUnit: displayUnit(paramNumber, fallback: fromUnit),
      precision: precision,
    );
  }

  static String formatNumber(
    double value, {
    int precision = 2,
    bool trimTrailingZeros = true,
  }) {
    final text = value.toStringAsFixed(precision);
    if (!trimTrailingZeros) {
      return text;
    }

    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String label(String title, String paramNumber) {
    final unit = displayUnit(paramNumber);
    if (unit == '-' || unit.isEmpty) {
      return title;
    }
    return '$title $unit';
  }

  static String ratioUnit({
    required String numeratorUnit,
    required String denominatorUnit,
  }) {
    return '${stripBrackets(numeratorUnit)}/${stripBrackets(denominatorUnit)}';
  }
}
