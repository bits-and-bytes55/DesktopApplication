import 'package:get/get.dart';

import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/unit_conversion_service.dart';
import 'package:mudpro_desktop_app/modules/options/unit_definitions.dart';


class AppUnits {
  AppUnits._();

  static final UnitConversionService _conversion =
      UnitConversionService.instance;

  static OptionsController get controller =>
      Get.isRegistered<OptionsController>()
      ? Get.find<OptionsController>()
      : Get.put(OptionsController(), permanent: true);

  static String clean(String unit) => UnitDefinitions.normalizeText(unit);

  static String normalizedText(String unit) => clean(unit);

  static String _canonicalUnit(String unit) =>
      UnitDefinitions.canonicalizeDisplayUnit(unit);

  static String strip(String unit) =>
      normalizedText(unit).replaceAll(RegExp(r'[()]'), '');

  static String rawUnit(String paramNumber) =>
      controller.unitForNumber(paramNumber);

  static String unit(String paramNumber) =>
      _canonicalUnit(rawUnit(paramNumber));

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

  static const Map<String, String> _preferredParameterByUnit = {
    '(ft)': '1',
    '(m)': '1',
    '(in)': '2',
    '(mm)': '2',
    '(cm)': '2',
    '(dm)': '2',
    '(1/32in)': '3',
    '(ft2)': '5',
    '(m2)': '5',
    '(in2)': '5',
    '(mm2)': '5',
    '(cm2)': '5',
    '(dm2)': '5',
    '(bbl)': '6',
    '(m3)': '6',
    '(L)': '6',
    '(mL)': '6',
    '(in3)': '10',
    '(ft3)': '9',
    '(pt)': '10',
    '(qt)': '6',
    '(oz)': '6',
    '(gal)': '6',
    '(bbl/ft)': '7',
    '(m3/m)': '7',
    '(ft3/m)': '7',
    '(bbl/m)': '7',
    '(L/m)': '7',
    '(gal/ft)': '7',
    '(ft/bbl)': '8',
    '(m/m3)': '8',
    '(ft/gal)': '8',
    '(m/bbl)': '8',
    '(m/ft3)': '8',
    '(m/L)': '8',
    '(bbl/stk)': '11',
    '(m3/stk)': '11',
    '(L/stk)': '11',
    '(gal/stk)': '11',
    '(scf)': '12',
    '(Mscf)': '12',
    '(MMscf)': '12',
    '(ft/min)': '13',
    '(m/min)': '13',
    '(m/d)': '13',
    '(m/h)': '13',
    '(ft/d)': '13',
    '(ft/h)': '13',
    '(ft/s)': '14',
    '(m/s)': '14',
    '(ft/hr)': '15',
    '(m/hr)': '15',
    '(ft/day)': '15',
    '(m/day)': '15',
    '(rpm)': '16',
    '(gpm)': '17',
    '(m3/min)': '17',
    '(bbl/min)': '17',
    '(gal/h)': '17',
    '(L/min)': '17',
    '(bbl/hr)': '17',
    '(L/h)': '17',
    '(m3/h)': '17',
    '(ft3/min)': '17',
    '(bpm)': '18',
    '(stk/min)': '19',
    '(lbf)': '20',
    '(N)': '20',
    '(ton)': '20',
    '(Kip)': '20',
    '(kN)': '20',
    '(T)': '20',
    '(daN)': '20',
    '(ft-lb)': '21',
    '(N-m)': '21',
    '(kg-m)': '21',
    '(kN-m)': '21',
    '(Kip-ft)': '21',
    '(psi)': '22',
    '(kPa)': '22',
    '(MPa)': '22',
    '(bar)': '22',
    '(kpsi)': '22',
    '(ATM)': '22',
    '(psi/ft)': '23',
    '(kPa/m)': '23',
    '(Pa/m)': '23',
    '(bar/10m)': '23',
    '(lbf/100ft2)': '25',
    '(dyne/cm2)': '25',
    '(HP)': '26',
    '(KW)': '26',
    '(W)': '26',
    '(ft-lb/sec)': '26',
    '(Btu/sec)': '26',
    '(ft-lb/min)': '26',
    '(kg-m/min)': '26',
    '(Btu/min)': '26',
    '(cP)': '27',
    '(dyne-s/cm2)': '27',
    '(kPa-s)': '27',
    '(lbf-s/ft2)': '27',
    '(Pa-s)': '27',
    '(lbf-s^n/100ft2)': '28',
    '(Pa-s^n)': '28',
    '(dyne-s^n/cm2)': '28',
    '(eq.cp)': '28',
    '(lbm)': '29',
    '(kg)': '29',
    '(mg)': '29',
    '(g)': '29',
    '(lbm/min)': '30',
    '(kg/min)': '30',
    '(lbm/s)': '30',
    '(lbm/d)': '30',
    '(kg/s)': '30',
    '(kg/d)': '30',
    '(lb/ft)': '31',
    '(kg/m)': '31',
    '(kg/cm)': '31',
    '(lb/in)': '31',
    '(lb/ft3)': '32',
    '(kg/m3)': '32',
    '(ppg)': '33',
    '(psi/100ft)': '33',
    '(S.G.)': '33',
    '(kg/L)': '33',
    '(g/cm3)': '33',
    '(°F)': '34',
    '(°C)': '34',
    '(K)': '34',
    '(R)': '34',
    '(°F/100ft)': '35',
    '(°C/100m)': '35',
    '(°F/ft)': '35',
    '(°C/m)': '35',
    '(R/ft)': '35',
    '(K/m)': '35',
    '(min)': '36',
    '(sec)': '36',
    '(hour)': '36',
    '(hr)': '36',
    '(day)': '36',
    '(year)': '36',
    '(°/100ft)': '37',
    '(°/30m)': '37',
    '(°)': '38',
    '(rad)': '38',
    '(lb/bbl)': '39',
    '(gal/bbl)': '40',
    '(L/m3)': '40',
    '(bbl/bbl)': '40',
    '(m3/m3)': '40',
    '(lb/sk)': '41',
    '(kg/sk)': '41',
    '(kg/kg)': '41',
    '(kg/ton)': '41',
    '(ft3/sk)': '42',
    '(m3/sk)': '42',
    '(m3/kg)': '42',
    '(bbl/lb)': '42',
    '(L/kg)': '42',
    '(L/ton)': '42',
    '(m3/ton)': '42',
    '(gal/sk)': '43',
    '(gal/lb)': '43',
    '(ft3/lb)': '43',
    '(L/sk)': '43',
    '(gphs)': '43',
    '(bbl/sk)': '43',
    '(mg/L)': '44',
    '(Btu/hr/ft/°F)': '45',
    '(W/m/K)': '45',
    '(Btu-in/hr/ft2/°F)': '45',
    '(Cal/s/m/°C)': '45',
    '(Cal/s/cm/°C)': '45',
    '(Btu/lbm/°F)': '46',
    '(KJ/kg/K)': '46',
    '(Btu/lbm/°C)': '46',
    '(Btu/lbm/R)': '46',
    '(Cal/g/°C)': '46',
    '(CHU/lbm/°C)': '46',
    '(J/g/°C)': '46',
    '(J/kg/K)': '46',
    '(J/kg/°C)': '46',
    '(KCal/kg/°C)': '46',
    '(KJ/kg/°C)': '46',
    '(Btu/hr/ft2/°F)': '47',
    '(W/m2/K)': '47',
    '(W/m2/°C)': '47',
    '(J/s/m2/K)': '47',
    '(Cal/s/cm2/°C)': '47',
    '(KCal/hr/m2/°C)': '47',
    '(KCal/hr/ft2/°C)': '47',
    '(Btu/s/ft2/°F)': '47',
    '(CHU/hr/ft2/°C)': '47',
    '(sec/qt)': '49',
    '(sec/L)': '49',
    '(s/L)': '49',
  };

  static String unitText(String rawUnit) {
    final canonical = _canonicalUnit(rawUnit);
    final preferredParam = _preferredParameterByUnit[canonical];
    if (preferredParam != null) {
      return unit(preferredParam);
    }

    for (final entry in UnitDefinitions.parameterUnits.entries) {
      if (entry.value.contains(canonical)) {
        return unit(entry.key);
      }
    }

    return normalizedText(rawUnit);
  }

  static String unitSuffix(String rawUnit) => strip(unitText(rawUnit));

  static Map<String, String> _labelReplacements() {
    final replacements = <String, String>{};

    for (final entry in UnitDefinitions.parameterUnits.entries) {
      final activeUnit = unit(entry.key);
      for (final option in entry.value) {
        replacements[option] = activeUnit;
      }
    }

    for (final entry in _preferredParameterByUnit.entries) {
      replacements[entry.key] = unit(entry.value);
    }

    replacements['(Pa)'] = stress;
    replacements['(kg/cm2)'] = stress;
    replacements['(MPa)'] = pressure;
    replacements['(kPa)'] = pressure;
    replacements['(°F)'] = temperature;
    replacements['(°C)'] = temperature;
    replacements['(K)'] = temperature;
    replacements['(R)'] = temperature;
    return replacements;
  }

  static String label(String text) {
    var output = normalizedText(text);
    final replacements = _labelReplacements();
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
      RegExp(r'(?<![\w/])lbf/100ft2(?![\w/])'),
      (_) => strip(yieldPoint),
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<![\w/])sec/qt(?![\w/])'),
      (_) => strip(funnelViscosity),
    );
    output = output.replaceAllMapped(
      RegExp(r'(?<![\w/])ppg(?![\w/])'),
      (_) => strip(mudWeight),
    );

    return output;
  }

  static String formatValue(
    dynamic value,
    String fromUnit, {
    int? fractionDigits,
  }) {
    if (value == null) {
      return '';
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) {
      return '';
    }

    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) {
      return raw;
    }

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
