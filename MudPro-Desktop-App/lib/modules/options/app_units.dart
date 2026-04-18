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

  static String normalizedText(String unit) => clean(unit)
      .replaceAll('Â²', '2')
      .replaceAll('Â³', '3')
      .replaceAll('²', '2')
      .replaceAll('³', '3')
      .replaceAll('Â°', '°');

  static String _canonicalUnit(String unit) {
    final normalized = normalizedText(unit)
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
      normalizedText(unit).replaceAll(RegExp(r'[()]'), '');

  static String rawUnit(String paramNumber) =>
      controller.unitForNumber(paramNumber);

  static String unit(String paramNumber) => _canonicalUnit(rawUnit(paramNumber));

  static String get signature => controller.activeUnitSignature;

  static String get systemLabel => controller.activeUnitSystemLabel;

  static String get length => unit('1');
  static String get diameter => unit('2');
  static String get nozzleDiameter => unit('3');
  static String get surfaceArea => unit('4');
  static String get crossSection => unit('5');
  static String get fluidVolume => unit('6');
  static String get pipeCapacityVolumeLength => unit('7');
  static String get pipeCapacityLengthVolume => unit('8');
  static String get solidVolume => unit('9');
  static String get smallVolume => unit('10');
  static String get strokeDisplacement => unit('11');
  static String get gasVolume => unit('12');
  static String get velocity => unit('13');
  static String get nozzleVelocity => unit('14');
  static String get rop => unit('15');
  static String get rotation => unit('16');
  static String get drillingFlowRate => unit('17');
  static String get cementingFlowRate => unit('18');
  static String get strokeRate => unit('19');
  static String get force => unit('20');
  static String get torque => unit('21');
  static String get pressure => unit('22');
  static String get pressureGradient => unit('23');
  static String get stress => unit('24');
  static String get yieldPoint => unit('25');
  static String get power => unit('26');
  static String get viscosity => unit('27');
  static String get consistency => unit('28');
  static String get weight => unit('29');
  static String get massRate => unit('30');
  static String get lineDensity => unit('31');
  static String get density => unit('32');
  static String get mudWeight => unit('33');
  static String get temperature => unit('34');
  static String get temperatureGradient => unit('35');
  static String get scheduleTime => unit('36');
  static String get dogleg => unit('37');
  static String get degree => unit('38');
  static String get massVolumeRatio => unit('39');
  static String get volumeVolumeRatio => unit('40');
  static String get cementSolidAdditiveWeight => unit('41');
  static String get cementSlurryYield => unit('42');
  static String get cementLiquidAdditive => unit('43');
  static String get concentration => unit('44');
  static String get conductivity => unit('45');
  static String get heatCapacity => unit('46');
  static String get heatTransferCoefficient => unit('47');
  static String get temperatureDrop => unit('48');
  static String get funnelViscosity => unit('49');

  static double? convertValue(double value, String fromUnit, String toUnit) {
    return _conversion.convertValue(
      value,
      _canonicalUnit(fromUnit),
      _canonicalUnit(toUnit),
    );
  }

  static String unitText(String rawUnit) {
    final normalized = _canonicalUnit(rawUnit);
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
      case '(mL)':
      case '(L)':
      case '(in3)':
      case '(ft3)':
      case '(oz)':
      case '(gal)':
      case '(qt)':
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
      case 'bbl/ft':
      case 'm3/m':
      case 'ft3/m':
      case 'bbl/m':
      case 'L/m':
      case 'gal/ft':
      case '(bbl/ft)':
      case '(m3/m)':
      case '(ft3/m)':
      case '(bbl/m)':
      case '(L/m)':
      case '(gal/ft)':
        return pipeCapacityVolumeLength;
      case 'ft/bbl':
      case 'm/m3':
      case 'ft/gal':
      case 'm/bbl':
      case 'm/ft3':
      case 'm/L':
      case '(ft/bbl)':
      case '(m/m3)':
      case '(ft/gal)':
      case '(m/bbl)':
      case '(m/ft3)':
      case '(m/L)':
        return pipeCapacityLengthVolume;
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
      case 'stk/min':
      case '(stk/min)':
        return strokeRate;
      case 'rpm':
      case '(rpm)':
        return rotation;
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
      case 'psi/ft':
      case 'kPa/m':
      case 'MPa/m':
      case '(psi/ft)':
      case '(kPa/m)':
      case '(MPa/m)':
        return pressureGradient;
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
      case 'Pa':
      case 'N/m2':
      case '(Pa)':
      case '(N/m2)':
        return stress;
      case 'lbf/100ft2':
      case 'lbf/100ftÂ²':
      case '(lb/100ft2)':
      case '(lbs/100ft2)':
      case '(lbf/100ft2)':
      case '(lbf/100ftÂ²)':
        return yieldPoint;
      case 'cP':
      case 'Pa-s':
      case 'mPa-s':
      case '(cP)':
      case '(Pa-s)':
      case '(mPa-s)':
        return viscosity;
      case 'lbf-s^n/100ft2':
      case 'lbf-s^n/100ftÂ²':
      case 'Pa-s^n':
      case '(lbf-s^n/100ft2)':
      case '(lbf-s^n/100ftÂ²)':
      case '(Pa-s^n)':
        return consistency;
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
      case 'lbm/min':
      case 'kg/min':
      case 'kg/s':
      case '(lbm/min)':
      case '(kg/min)':
      case '(kg/s)':
        return massRate;
      case 'lb/ft':
      case 'kg/m':
      case '(lb/ft)':
      case '(kg/m)':
        return lineDensity;
      case 'lb/bbl':
      case 'lb/gal':
      case '(lb/bbl)':
      case '(lb/gal)':
        return massVolumeRatio;
      case 'gal/bbl':
      case 'L/m3':
      case 'mL/m3':
      case '(gal/bbl)':
      case '(L/m3)':
      case '(mL/m3)':
        return volumeVolumeRatio;
      case '°F':
      case '°C':
      case 'K':
      case '(°F)':
      case '(°C)':
      case '(K)':
        return temperature;
      case 'Â°F/100ft':
      case 'Â°C/100m':
      case 'Â°C/m':
      case '(Â°F/100ft)':
      case '(Â°C/100m)':
      case '(Â°C/m)':
        return temperatureGradient;
      case 'min':
      case 'sec':
      case 'hr':
      case '(min)':
      case '(sec)':
      case '(hr)':
        return scheduleTime;
      case 'Â°/100ft':
      case 'Â°/30m':
      case 'Â°/10m':
      case 'Â°/m':
      case '(Â°/100ft)':
      case '(Â°/30m)':
      case '(Â°/10m)':
      case '(Â°/m)':
        return dogleg;
      case 'Â°':
      case '(Â°)':
        return degree;
      case 'lb/sk':
      case 'kg/bag':
      case 'kg/sk':
      case '(lb/sk)':
      case '(kg/bag)':
      case '(kg/sk)':
        return cementSolidAdditiveWeight;
      case 'ft3/sk':
      case 'm3/bag':
      case 'L/sk':
      case '(ft3/sk)':
      case '(m3/bag)':
      case '(L/sk)':
        return cementSlurryYield;
      case 'gal/sk':
      case 'L/bag':
      case 'm3/sk':
      case '(gal/sk)':
      case '(L/bag)':
      case '(m3/sk)':
        return cementLiquidAdditive;
      case 'mg/L':
      case 'ppm':
      case '(mg/L)':
      case '(ppm)':
        return concentration;
      case 'Btu/hr/ft/Â°F':
      case 'W/m/K':
      case 'kcal/hr/m/Â°C':
      case '(Btu/hr/ft/Â°F)':
      case '(W/m/K)':
      case '(kcal/hr/m/Â°C)':
        return conductivity;
      case 'Btu/lbm/Â°F':
      case 'J/kg/Â°C':
      case 'kcal/kg/Â°C':
      case '(Btu/lbm/Â°F)':
      case '(J/kg/Â°C)':
      case '(kcal/kg/Â°C)':
        return heatCapacity;
      case 'Btu/hr/ft2/Â°F':
      case 'W/m2/K':
      case '(Btu/hr/ft2/Â°F)':
      case '(W/m2/K)':
        return heatTransferCoefficient;
      case 'sec/qt':
      case 'sec/L':
      case '(sec/qt)':
      case '(sec/L)':
        return funnelViscosity;
      case '\u00B0/100ft':
      case '\u00B0/30m':
      case '\u00B0/10m':
      case '\u00B0/m':
      case '(\u00B0/100ft)':
      case '(\u00B0/30m)':
      case '(\u00B0/10m)':
      case '(\u00B0/m)':
        return dogleg;
      case '\u00B0':
      case '(\u00B0)':
        return degree;
      case '(ft2)':
      case '(m2)':
      case '(in2)':
      case '(mm2)':
      case '(cm2)':
      case '(dm2)':
        return crossSection;
      default:
        return normalizedText(rawUnit);
    }
  }

  static String unitSuffix(String rawUnit) => strip(unitText(rawUnit));

  static String label(String text) {
    var output = normalizedText(text);
    final replacements = <String, String>{
      '(bbl/stk)': strokeDisplacement,
      '(m3/stk)': strokeDisplacement,
      '(gal/stk)': strokeDisplacement,
      '(L/stk)': strokeDisplacement,
      '(bbl/ft)': pipeCapacityVolumeLength,
      '(m3/m)': pipeCapacityVolumeLength,
      '(ft3/m)': pipeCapacityVolumeLength,
      '(bbl/m)': pipeCapacityVolumeLength,
      '(L/m)': pipeCapacityVolumeLength,
      '(gal/ft)': pipeCapacityVolumeLength,
      '(ft/bbl)': pipeCapacityLengthVolume,
      '(m/m3)': pipeCapacityLengthVolume,
      '(ft/gal)': pipeCapacityLengthVolume,
      '(m/bbl)': pipeCapacityLengthVolume,
      '(m/ft3)': pipeCapacityLengthVolume,
      '(m/L)': pipeCapacityLengthVolume,
      '(ft/min)': velocity,
      '(m/min)': velocity,
      '(ft/s)': nozzleVelocity,
      '(m/s)': nozzleVelocity,
      '(ft/hr)': rop,
      '(m/hr)': rop,
      '(m/day)': rop,
      '(ft/day)': rop,
      '(gpm)': drillingFlowRate,
      '(m3/min)': drillingFlowRate,
      '(L/min)': drillingFlowRate,
      '(L/s)': drillingFlowRate,
      '(bpm)': cementingFlowRate,
      '(stk/min)': strokeRate,
      '(rpm)': rotation,
      '(ppg)': mudWeight,
      '(kg/m3)': mudWeight,
      '(lb/ft3)': mudWeight,
      '(psi)': pressure,
      '(kPa)': pressure,
      '(MPa)': pressure,
      '(bar)': pressure,
      '(atm)': pressure,
      '(kgf/cm2)': pressure,
      '(psi/ft)': pressureGradient,
      '(kPa/m)': pressureGradient,
      '(MPa/m)': pressureGradient,
      '(Pa)': stress,
      '(N/m2)': stress,
      '(lb/100ft2)': yieldPoint,
      '(lbs/100ft2)': yieldPoint,
      '(lbf/100ft2)': yieldPoint,
      '(lbf/100ftÂ²)': yieldPoint,
      '(cP)': viscosity,
      '(Pa-s)': viscosity,
      '(mPa-s)': viscosity,
      '(lbf-s^n/100ft2)': consistency,
      '(lbf-s^n/100ftÂ²)': consistency,
      '(Pa-s^n)': consistency,
      '(lbf)': force,
      '(N)': force,
      '(kN)': force,
      '(ft-lb)': torque,
      '(N-m)': torque,
      '(HP)': power,
      '(KW)': power,
      '(W)': power,
      '(lbm)': weight,
      '(kg)': weight,
      '(g)': weight,
      '(lbm/min)': massRate,
      '(kg/min)': massRate,
      '(kg/s)': massRate,
      '(lb/ft)': lineDensity,
      '(kg/m)': lineDensity,
      '(lb/bbl)': massVolumeRatio,
      '(lb/gal)': massVolumeRatio,
      '(gal/bbl)': volumeVolumeRatio,
      '(L/m3)': volumeVolumeRatio,
      '(mL/m3)': volumeVolumeRatio,
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
      '(K)': temperature,
      '(min)': scheduleTime,
      '(sec)': scheduleTime,
      '(hr)': scheduleTime,
      '(\u00B0/100ft)': dogleg,
      '(\u00B0/30m)': dogleg,
      '(\u00B0/10m)': dogleg,
      '(\u00B0/m)': dogleg,
      '(\u00B0)': degree,
      '(lb/sk)': cementSolidAdditiveWeight,
      '(kg/bag)': cementSolidAdditiveWeight,
      '(kg/sk)': cementSolidAdditiveWeight,
      '(ft3/sk)': cementSlurryYield,
      '(m3/bag)': cementSlurryYield,
      '(L/sk)': cementSlurryYield,
      '(gal/sk)': cementLiquidAdditive,
      '(L/bag)': cementLiquidAdditive,
      '(m3/sk)': cementLiquidAdditive,
      '(mg/L)': concentration,
      '(ppm)': concentration,
      '(W/m/K)': conductivity,
      '(W/m2/K)': heatTransferCoefficient,
      '(sec/qt)': funnelViscosity,
      '(sec/L)': funnelViscosity,
      '(°F)': temperature,
      '(°C)': temperature,
    };

    final sortedKeys = replacements.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      output = output.replaceAll(key, replacements[key]!);
    }
    output = output.replaceAllMapped(
      RegExp(r'(?<![\w/])lb/bbl(?![\w/])'),
      (_) => strip(massVolumeRatio),
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<![\w/])psi/ft(?![\w/])'),
      (_) => strip(pressureGradient),
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<![\w/])lb[sf]?/100ft2(?![\w/])'),
      (_) => strip(yieldPoint),
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<![\w/])sec/qt(?![\w/])'),
      (_) => strip(funnelViscosity),
    );
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
