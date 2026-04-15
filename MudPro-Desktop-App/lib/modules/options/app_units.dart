import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/unit_conversion_service.dart';

class AppUnits {
  AppUnits._();

  static final UnitConversionService _conversion =
      UnitConversionService.instance;

  static OptionsController get controller =>
      Get.isRegistered<OptionsController>()
      ? Get.find<OptionsController>()
      : Get.put(OptionsController(), permanent: true);

  static String clean(String unit) => unit.replaceAll('Â', '');

  static String _canonicalUnit(String unit) {
    final normalized = clean(unit)
        .replaceAll('Â', '')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .trim();
    if (normalized.isEmpty || normalized == '-') return normalized;
    if (normalized.startsWith('(') && normalized.endsWith(')')) {
      return normalized;
    }
    return '($normalized)';
  }

  static String strip(String unit) =>
      clean(unit).replaceAll(RegExp(r'[()]'), '');

  static String rawUnit(String paramNumber) =>
      controller.unitForNumber(paramNumber);

  static String unit(String paramNumber) => _canonicalUnit(rawUnit(paramNumber));

  static String get signature => controller.activeUnitSignature;

  static String get systemLabel => controller.activeUnitSystemLabel;

  static String get length => unit('1');
  static String get diameter => unit('2');
  static String get nozzleDiameter => unit('3');
  static String get crossSection => unit('5');
  static String get fluidVolume => unit('6');
  static String get strokeDisplacement => unit('11');
  static String get velocity => unit('13');
  static String get nozzleVelocity => unit('14');
  static String get rop => unit('15');
  static String get drillingFlowRate => unit('17');
  static String get cementingFlowRate => unit('18');
  static String get force => unit('20');
  static String get torque => unit('21');
  static String get pressure => unit('22');
  static String get power => unit('26');
  static String get weight => unit('29');
  static String get lineDensity => unit('31');
  static String get mudWeight => unit('33');
  static String get temperature => unit('34');

  static double? convertValue(double value, String fromUnit, String toUnit) {
    return _conversion.convertValue(value, fromUnit, toUnit);
  }

  static String unitText(String rawUnit) {
    final normalized = clean(rawUnit).trim();
    switch (normalized) {
      case 'ft':
      case 'm':
      case '(ft)':
      case '(m)':
        return length;
      case 'in':
      case 'mm':
      case 'cm':
      case 'dm':
      case '(in)':
      case '(mm)':
      case '(cm)':
      case '(dm)':
        return diameter;
      case '(1/32in)':
        return nozzleDiameter;
      case 'bbl':
      case 'm3':
      case 'L':
      case 'gal':
      case '(bbl)':
      case '(m3)':
      case '(L)':
      case '(gal)':
        return fluidVolume;
      case 'bbl/stk':
      case 'm3/stk':
      case 'gal/stk':
      case 'L/stk':
      case '(bbl/stk)':
      case '(m3/stk)':
      case '(gal/stk)':
      case '(L/stk)':
        return strokeDisplacement;
      case 'gpm':
      case 'm3/min':
      case 'L/min':
      case 'L/s':
      case '(gpm)':
      case '(m3/min)':
      case '(L/min)':
      case '(L/s)':
        return drillingFlowRate;
      case 'bpm':
      case '(bpm)':
        return cementingFlowRate;
      case 'ft/min':
      case 'm/min':
      case '(ft/min)':
      case '(m/min)':
        return velocity;
      case 'ft/s':
      case 'm/s':
      case 'mph':
      case 'km/h':
      case '(ft/s)':
      case '(m/s)':
      case '(mph)':
      case '(km/h)':
        return nozzleVelocity;
      case 'ft/hr':
      case 'm/hr':
      case 'm/day':
      case 'ft/day':
      case '(ft/hr)':
      case '(m/hr)':
      case '(m/day)':
      case '(ft/day)':
        return rop;
      case 'ppg':
      case 'kg/m3':
      case 'g/cm3':
      case 'lb/ft3':
      case 'sg':
      case '(ppg)':
      case '(kg/m3)':
      case '(g/cm3)':
      case '(lb/ft3)':
      case '(sg)':
        return mudWeight;
      case 'psi':
      case 'kPa':
      case 'MPa':
      case 'bar':
      case 'atm':
      case 'kgf/cm2':
      case '(psi)':
      case '(kPa)':
      case '(MPa)':
      case '(bar)':
      case '(atm)':
      case '(kgf/cm2)':
        return pressure;
      case 'lbf':
      case 'N':
      case 'kN':
      case '(lbf)':
      case '(N)':
      case '(kN)':
        return force;
      case 'ft-lb':
      case 'N-m':
      case 'J':
      case '(ft-lb)':
      case '(N-m)':
      case '(J)':
        return torque;
      case 'HP':
      case 'KW':
      case 'W':
      case '(HP)':
      case '(KW)':
      case '(W)':
        return power;
      case 'lbm':
      case 'kg':
      case 'g':
      case '(lbm)':
      case '(kg)':
      case '(g)':
        return weight;
      case 'lb/ft':
      case 'kg/m':
      case '(lb/ft)':
      case '(kg/m)':
        return lineDensity;
      case '°F':
      case '°C':
      case 'K':
      case '(°F)':
      case '(°C)':
      case '(K)':
        return temperature;
      case '(ft2)':
      case '(m2)':
      case '(in2)':
      case '(mm2)':
      case '(cm2)':
      case '(dm2)':
        return crossSection;
      default:
        return clean(rawUnit);
    }
  }

  static String unitSuffix(String rawUnit) => strip(unitText(rawUnit));

  static String label(String text) {
    var output = clean(text);
    final replacements = <String, String>{
      '(bbl/stk)': strokeDisplacement,
      '(m3/stk)': strokeDisplacement,
      '(gal/stk)': strokeDisplacement,
      '(L/stk)': strokeDisplacement,
      '(ft/min)': velocity,
      '(m/min)': velocity,
      '(ft/s)': nozzleVelocity,
      '(m/s)': nozzleVelocity,
      '(ft/hr)': rop,
      '(m/hr)': rop,
      '(gpm)': drillingFlowRate,
      '(m3/min)': drillingFlowRate,
      '(L/min)': drillingFlowRate,
      '(L/s)': drillingFlowRate,
      '(bpm)': cementingFlowRate,
      '(ppg)': mudWeight,
      '(kg/m3)': mudWeight,
      '(lb/ft3)': mudWeight,
      '(psi)': pressure,
      '(kPa)': pressure,
      '(MPa)': pressure,
      '(lbf)': force,
      '(N)': force,
      '(kN)': force,
      '(ft-lb)': torque,
      '(N-m)': torque,
      '(HP)': power,
      '(KW)': power,
      '(lbm)': weight,
      '(kg)': weight,
      '(lb/ft)': lineDensity,
      '(kg/m)': lineDensity,
      '(ft2)': crossSection,
      '(m2)': crossSection,
      '(in2)': crossSection,
      '(mm2)': crossSection,
      '(cm2)': crossSection,
      '(dm2)': crossSection,
      '(bbl)': fluidVolume,
      '(m3)': fluidVolume,
      '(L)': fluidVolume,
      '(gal)': fluidVolume,
      '(ft)': length,
      '(m)': length,
      '(in)': diameter,
      '(mm)': diameter,
      '(cm)': diameter,
      '(dm)': diameter,
      '(°F)': temperature,
      '(°C)': temperature,
    };

    final sortedKeys = replacements.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      output = output.replaceAll(key, replacements[key]!);
    }
    return output;
  }

  static String formatValue(
    dynamic value,
    String fromUnit, {
    int? fractionDigits,
  }) {
    if (value == null) return '';
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) return raw;

    final toUnit = unitText(fromUnit);
    final converted = convertValue(parsed, fromUnit, toUnit) ?? parsed;
    if (fractionDigits == null) {
      return converted
          .toStringAsFixed(4)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    return converted.toStringAsFixed(fractionDigits);
  }
}
