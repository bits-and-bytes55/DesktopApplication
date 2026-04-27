import 'package:mudpro_desktop_app/modules/options/unit_definitions.dart';

class UnitConversionService {
  UnitConversionService._();
  static final UnitConversionService instance = UnitConversionService._();

  static const double _cementSackKg = 94.0 * 0.45359237;

  static Map<String, List<String>> get parameterUnits =>
      UnitDefinitions.parameterUnits;

  static String _canonical(String unit) =>
      UnitDefinitions.canonicalizeDisplayUnit(unit);

  static String _normalized(String unit) =>
      UnitDefinitions.normalizeUnitKey(unit);

  double? convertNormalizedTemp(double value, String fromUnit, String toUnit) {
    final from = _normalized(fromUnit);
    final to = _normalized(toUnit);

    if (from == to) {
      return value;
    }

    if (const {'degf', 'degc', 'k', 'r'}.contains(from) &&
        const {'degf', 'degc', 'k', 'r'}.contains(to)) {
      return _convertTemperature(value, from, to);
    }

    return null;
  }

  double? _convertTemperature(double value, String from, String to) {
    double kelvin;

    switch (from) {
      case 'degf':
        kelvin = (value - 32) * 5 / 9 + 273.15;
        break;
      case 'degc':
        kelvin = value + 273.15;
        break;
      case 'k':
        kelvin = value;
        break;
      case 'r':
        kelvin = value * 5 / 9;
        break;
      default:
        return null;
    }

    switch (to) {
      case 'degf':
        return (kelvin - 273.15) * 9 / 5 + 32;
      case 'degc':
        return kelvin - 273.15;
      case 'k':
        return kelvin;
      case 'r':
        return kelvin * 9 / 5;
      default:
        return null;
    }
  }

  double? convert(double value, String fromUnit, String toUnit) {
    final from = _canonical(fromUnit);
    final to = _canonical(toUnit);

    if (from == to) {
      return value;
    }

    final pressureGradientResult = _convertPressureGradient(value, from, to);
    if (pressureGradientResult != null) {
      return pressureGradientResult;
    }

    for (final group in _conversionGroups.values) {
      final matchedFrom = _findMatchingKey(group, from);
      final matchedTo = _findMatchingKey(group, to);
      if (matchedFrom == null || matchedTo == null) {
        continue;
      }
      return value * group[matchedFrom]! / group[matchedTo]!;
    }

    return null;
  }

  String? _findMatchingKey(Map<String, double> group, String unit) {
    final normalizedUnit = _normalized(unit);
    for (final key in group.keys) {
      if (_normalized(key) == normalizedUnit) {
        return key;
      }
    }
    return null;
  }

  double? _convertPressureGradient(double value, String from, String to) {
    final fromKey = _findMatchingKey(_pressureGradientUnits, from);
    final toKey = _findMatchingKey(_pressureGradientUnits, to);
    if (fromKey == null || toKey == null) {
      return null;
    }

    final fromExclusive = _exclusivePressureGradientUnits.contains(fromKey);
    final toExclusive = _exclusivePressureGradientUnits.contains(toKey);
    if (!fromExclusive && !toExclusive) {
      return null;
    }

    return value *
        _pressureGradientUnits[fromKey]! /
        _pressureGradientUnits[toKey]!;
  }

  static const Map<String, double> _pressureGradientUnits = {
    '(psi/ft)': 22.620595449,
    '(kPa/m)': 1.0,
    '(MPa/m)': 1000.0,
    '(Pa/m)': 0.001,
    '(ppg)': 1.176270963,
    '(S.G.)': 9.80665,
    '(kg/L)': 9.80665,
    '(bar/10m)': 10.0,
  };

  static const Set<String> _exclusivePressureGradientUnits = {
    '(psi/ft)',
    '(kPa/m)',
    '(MPa/m)',
    '(Pa/m)',
    '(bar/10m)',
  };

  static const Map<String, Map<String, double>> _conversionGroups = {
    'length': {
      '(ft)': 0.3048,
      '(m)': 1.0,
      '(in)': 0.0254,
      '(mm)': 0.001,
      '(cm)': 0.01,
      '(dm)': 0.1,
      '(1/32in)': 0.00079375,
    },
    'area': {
      '(ft2)': 0.09290304,
      '(m2)': 1.0,
      '(in2)': 0.00064516,
      '(mm2)': 0.000001,
      '(cm2)': 0.0001,
      '(dm2)': 0.01,
    },
    'volume': {
      '(bbl)': 0.158987294928,
      '(m3)': 1.0,
      '(mL)': 0.000001,
      '(L)': 0.001,
      '(in3)': 0.000016387064,
      '(ft3)': 0.028316846592,
      '(oz)': 0.0000295735295625,
      '(gal)': 0.003785411784,
      '(qt)': 0.000946352946,
      '(pt)': 0.000473176473,
      '(scf)': 0.028316846592,
      '(Mscf)': 28.316846592,
      '(MMscf)': 28316.846592,
    },
    'pipeCapacityVolumeLength': {
      '(bbl/ft)': 0.5216118599999999,
      '(m3/m)': 1.0,
      '(ft3/m)': 0.028316846592,
      '(bbl/m)': 0.158987294928,
      '(L/m)': 0.001,
      '(gal/ft)': 0.01241933065616798,
    },
    'pipeCapacityLengthVolume': {
      '(ft/bbl)': 1.917126996,
      '(m/m3)': 1.0,
      '(ft/gal)': 80.51584041755888,
      '(m/bbl)': 6.289810770432105,
      '(m/ft3)': 35.31466672148859,
      '(m/L)': 1000.0,
    },
    'strokeDisplacement': {
      '(bbl/stk)': 0.158987294928,
      '(m3/stk)': 1.0,
      '(L/stk)': 0.001,
      '(gal/stk)': 0.003785411784,
    },
    'velocity': {
      '(ft/min)': 0.00508,
      '(m/min)': 1 / 60,
      '(m/d)': 1 / 86400,
      '(m/h)': 1 / 3600,
      '(m/s)': 1.0,
      '(ft/d)': 0.3048 / 86400,
      '(ft/h)': 0.3048 / 3600,
      '(ft/s)': 0.3048,
    },
    'flowRate': {
      '(gpm)': 0.003785411784,
      '(m3/min)': 1.0,
      '(bbl/min)': 0.158987294928,
      '(gal/h)': 0.003785411784 / 60,
      '(L/min)': 0.001,
      '(bbl/hr)': 0.158987294928 / 60,
      '(L/h)': 0.001 / 60,
      '(m3/h)': 1 / 60,
      '(ft3/min)': 0.028316846592,
      '(bpm)': 0.158987294928,
    },
    'rop': {
      '(ft/hr)': 0.3048,
      '(m/hr)': 1.0,
      '(ft/day)': 0.0127,
      '(m/day)': 1 / 24,
    },
    'pressure': {
      '(psi)': 6.894757293168,
      '(kPa)': 1.0,
      '(MPa)': 1000.0,
      '(bar)': 100.0,
      '(kpsi)': 6894.757293168,
      '(Pa)': 0.001,
      '(kg/cm2)': 98.0665,
      '(ATM)': 101.325,
    },
    'yieldPoint': {
      '(lbf/100ft2)': 0.4788025898033584,
      '(Pa)': 1.0,
      '(dyne/cm2)': 0.1,
      '(kPa)': 1000.0,
      '(MPa)': 1000000.0,
      '(lb/100ft2)': 0.4788025898033584,
      '(lbs/100ft2)': 0.4788025898033584,
    },
    'density': {
      '(ppg)': 119.826427316,
      '(kg/m3)': 1.0,
      '(kPa/m)': 101.9716212978,
      '(lb/ft3)': 16.01846337396014,
      '(psi/100ft)': 23.043543714615384,
      '(S.G.)': 1000.0,
      '(kg/L)': 1000.0,
      '(g/cm3)': 1000.0,
      '(bar/10m)': 1019.716212978,
    },
    'massVolumeRatio': {
      '(lb/bbl)': 2.853010969,
      '(kg/m3)': 1.0,
      '(lb/gal)': 119.826427316,
      '(lb/ft3)': 16.01846337396014,
      '(g/L)': 1.0,
    },
    'mass': {
      '(lbm)': 0.45359237,
      '(lb)': 0.45359237,
      '(kg)': 1.0,
      '(ton)': 1000.0,
      '(oz)': 0.028349523125,
      '(mg)': 0.000001,
      '(g)': 0.001,
    },
    'massRate': {
      '(lbm/min)': 0.45359237,
      '(kg/min)': 1.0,
      '(lbm/s)': 27.2155422,
      '(lbm/d)': 0.0003149947013888889,
      '(kg/s)': 60.0,
      '(kg/d)': 1 / 1440,
    },
    'lineDensity': {
      '(lb/ft)': 1.4881639435695537,
      '(kg/m)': 1.0,
      '(kg/cm)': 100.0,
      '(lb/in)': 17.857967322834646,
    },
    'force': {
      '(lbf)': 4.44822161526,
      '(N)': 1.0,
      '(ton)': 8896.44323052,
      '(Kip)': 4448.22161526,
      '(kN)': 1000.0,
      '(T)': 9806.65,
      '(daN)': 10.0,
      '(kg)': 9.80665,
    },
    'torque': {
      '(ft-lb)': 1.3558179483314004,
      '(N-m)': 1.0,
      '(kg-m)': 9.80665,
      '(kN-m)': 1000.0,
      '(Kip-ft)': 1355.8179483314004,
    },
    'power': {
      '(HP)': 745.6998715822701,
      '(KW)': 1000.0,
      '(ft-lb/sec)': 1.3558179483314004,
      '(Btu/sec)': 1055.05585262,
      '(ft-lb/min)': 0.02259696580552334,
      '(W)': 1.0,
      '(kg-m/min)': 0.16344416666666668,
      '(Btu/min)': 17.584264210333334,
    },
    'viscosity': {
      '(cP)': 0.001,
      '(dyne-s/cm2)': 0.1,
      '(kPa-s)': 1000.0,
      '(lbf-s/ft2)': 47.88025898033584,
      '(Pa-s)': 1.0,
    },
    'consistency': {
      '(lbf-s^n/100ft2)': 0.4788025898033584,
      '(Pa-s^n)': 1.0,
      '(dyne-s^n/cm2)': 0.1,
      '(eq.cp)': 0.001,
    },
    'time': {
      '(min)': 1.0,
      '(sec)': 1 / 60,
      '(hour)': 60.0,
      '(hr)': 60.0,
      '(day)': 1440.0,
      '(year)': 525600.0,
    },
    'dogleg': {
      '(°/100ft)': 3.2808398950131235,
      '(°/30m)': 3.3333333333333335,
      '(°/10m)': 10.0,
      '(°/m)': 100.0,
      '(°/100m)': 1.0,
    },
    'degree': {'(°)': 1.0, '(rad)': 57.29577951308232},
    'volumeVolumeRatio': {
      '(gal/bbl)': 23.80952380951205,
      '(L/m3)': 1.0,
      '(bbl/bbl)': 1000.0,
      '(m3/m3)': 1000.0,
      '(mL/m3)': 0.001,
    },
    'perSk': {
      '(lb/sk)': 0.45359237,
      '(kg/sk)': 1.0,
      '(kg/kg)': _cementSackKg,
      '(kg/ton)': _cementSackKg / 1000,
      '(kg/bag)': 1.0,
    },
    'slurryYield': {
      '(ft3/sk)': 0.028316846592,
      '(m3/sk)': 1.0,
      '(m3/kg)': _cementSackKg,
      '(bbl/lb)': 14.944805723232001,
      '(L/kg)': _cementSackKg * 0.001,
      '(L/ton)': _cementSackKg / 1000000,
      '(m3/ton)': _cementSackKg / 1000,
      '(gal/sk)': 0.003785411784,
      '(gal/lb)': 0.355828707696,
      '(ft3/lb)': 2.661783559648,
      '(L/sk)': 0.001,
      '(gphs)': 0.00003785411784,
      '(bbl/sk)': 0.158987294928,
      '(m3/bag)': 1.0,
    },
    'liquidPerSk': {
      '(gal/sk)': 0.003785411784,
      '(m3/sk)': 1.0,
      '(L/kg)': _cementSackKg * 0.001,
      '(m3/kg)': _cementSackKg,
      '(bbl/lb)': 14.944805723232001,
      '(L/sk)': 0.001,
      '(gphs)': 0.00003785411784,
      '(bbl/sk)': 0.158987294928,
      '(ft3/lb)': 2.661783559648,
      '(ft3/sk)': 0.028316846592,
      '(gal/lb)': 0.355828707696,
      '(m3/ton)': _cementSackKg / 1000,
      '(L/ton)': _cementSackKg / 1000000,
      '(L/bag)': 0.001,
      '(mL/sk)': 0.000001,
    },
    'conductivity': {
      '(Btu/hr/ft/°F)': 1.73073466637,
      '(W/m/K)': 1.0,
      '(Btu-in/hr/ft2/°F)': 0.144227888864,
      '(Cal/s/m/°C)': 4.1868,
      '(Cal/s/cm/°C)': 418.68,
      '(kcal/hr/m/°C)': 1.163,
    },
    'heatCapacity': {
      '(Btu/lbm/°F)': 4186.80058485,
      '(KJ/kg/K)': 1000.0,
      '(Btu/lbm/°C)': 2326.0003249166666,
      '(Btu/lbm/R)': 4186.80058485,
      '(Cal/g/°C)': 4186.8,
      '(CHU/lbm/°C)': 4186.80058485,
      '(J/g/°C)': 1000.0,
      '(J/kg/K)': 1.0,
      '(J/kg/°C)': 1.0,
      '(KCal/kg/°C)': 4186.8,
      '(KJ/kg/°C)': 1000.0,
      '(Btu/lb/°F)': 4186.80058485,
    },
    'heatTransferCoefficient': {
      '(Btu/hr/ft2/°F)': 5.678263337,
      '(W/m2/K)': 1.0,
      '(W/m2/°C)': 1.0,
      '(J/s/m2/K)': 1.0,
      '(Cal/s/cm2/°C)': 41868.0,
      '(KCal/hr/m2/°C)': 1.163,
      '(KCal/hr/ft2/°C)': 12.5184278204158,
      '(Btu/s/ft2/°F)': 20441.7480132,
      '(CHU/hr/ft2/°C)': 12.5184278204158,
    },
    'temperatureGradient': {
      '(°F/100ft)': 1.8228346456692914,
      '(°C/100m)': 1.0,
      '(°F/ft)': 182.28346456692915,
      '(°C/m)': 100.0,
      '(R/ft)': 182.28346456692915,
      '(K/m)': 100.0,
    },
    'funnelViscosity': {'(sec/qt)': 0.946352946, '(sec/L)': 1.0, '(s/L)': 1.0},
    'concentration': {'(mg/L)': 1.0, '(ppm)': 1.0},
  };

  double? convertTemp(double value, String fromUnit, String toUnit) {
    return convertNormalizedTemp(value, fromUnit, toUnit);
  }

  double? convertValue(double value, String fromUnit, String toUnit) {
    final from = _canonical(fromUnit);
    final to = _canonical(toUnit);

    if (from == to) {
      return value;
    }

    final tempResult = convertNormalizedTemp(value, from, to);
    if (tempResult != null) {
      return tempResult;
    }

    return convert(value, from, to);
  }

  List<String> getUnitsForParam(String paramNumber) {
    return parameterUnits[paramNumber] ?? const [];
  }
}
