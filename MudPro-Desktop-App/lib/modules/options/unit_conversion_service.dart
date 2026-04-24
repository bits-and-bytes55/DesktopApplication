// ─────────────────────────────────────────────────────────────────────────────
// unit_conversion_service.dart
// Converts a numeric value from one unit to another.
// Based on the conversion factors table (Excel screenshot).
// ─────────────────────────────────────────────────────────────────────────────

class UnitConversionService {
  UnitConversionService._();
  static final UnitConversionService instance = UnitConversionService._();

  static String _normalizeUnit(String unit) {
    return unit
        .trim()
        .replaceAll('Â', '')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .replaceAll('°', 'deg')
        .replaceAll('Â', '')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .replaceAll('°', 'deg')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .replaceAll('°', 'deg')
        .replaceAll(RegExp(r'[()]'), '')
        .replaceAll(' ', '')
        .toLowerCase();
  }

  double? convertNormalizedTemp(double value, String fromUnit, String toUnit) {
    final from = _normalizeUnit(fromUnit).replaceAll(RegExp(r'[()]'), '');
    final to = _normalizeUnit(toUnit).replaceAll(RegExp(r'[()]'), '');

    if (from == to) return value;
    if (from == 'degf' && to == 'degc') return (value - 32) * 5 / 9;
    if (from == 'degc' && to == 'degf') return value * 9 / 5 + 32;
    if (from == 'degf' && to == 'k') return (value - 32) * 5 / 9 + 273.15;
    if (from == 'degc' && to == 'k') return value + 273.15;
    if (from == 'k' && to == 'degc') return value - 273.15;
    if (from == 'k' && to == 'degf') return (value - 273.15) * 9 / 5 + 32;
    return null;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PARAMETER-SPECIFIC UNIT OPTIONS
  // Each parameter number maps to the list of units available in its dropdown.
  // Derived from the original software screenshots (images 6–13).
  // ════════════════════════════════════════════════════════════════════════════
  static const Map<String, List<String>> parameterUnits = {
    '1': ['(ft)', '(m)'], // Length
    '2': ['(in)', '(mm)', '(cm)', '(dm)', '(m)', '(ft)'], // Pipe diameter
    '3': ['(in)', '(mm)', '(1/32in)'], // Nozzle diameter
    '4': ['(ft2)', '(m2)'], // Surface area
    '5': ['(in2)', '(mm2)', '(cm2)', '(dm2)', '(m2)', '(ft2)'], // Cross section
    '6': [
      '(bbl)',
      '(m3)',
      '(mL)',
      '(L)',
      '(in3)',
      '(ft3)',
      '(oz)',
      '(gal)',
      '(qt)',
    ], // Fluid volume
    '7': [
      '(bbl/ft)',
      '(m3/m)',
      '(ft3/m)',
      '(bbl/m)',
      '(L/m)',
      '(gal/ft)',
    ], // Pipe capacity (vol/len)
    '8': [
      '(ft/bbl)',
      '(m/m3)',
      '(ft/gal)',
      '(m/bbl)',
      '(m/ft3)',
      '(m/L)',
    ], // Pipe capacity (len/vol)
    '9': ['(ft3)', '(in3)', '(m3)'], // Solid volume
    '10': ['(in3)', '(m3)', '(L)'], // Small volume
    '11': [
      '(bbl/stk)',
      '(m3/stk)',
      '(gal/stk)',
      '(L/stk)',
    ], // Stroke displacement
    '12': ['(scf)', '(m3)'], // Gas volume
    '13': [
      '(ft/min)',
      '(m/min)',
      '(ft/s)',
      '(m/s)',
      '(ft/hr)',
      '(m/hr)',
    ], // Velocity
    '14': ['(ft/s)', '(m/s)', '(mph)', '(km/h)'], // Nozzle velocity
    '15': ['(ft/hr)', '(m/hr)', '(m/day)', '(ft/day)'], // ROP
    '16': ['(rpm)'], // Rotation
    '17': [
      '(gpm)',
      '(m3/min)',
      '(bpm)',
      '(L/min)',
      '(L/s)',
    ], // Liquid flow rate for drilling
    '18': [
      '(bpm)',
      '(gpm)',
      '(m3/min)',
      '(L/min)',
    ], // Liquid flow rate for cementing
    '19': ['(stk/min)'], // Stroke rate
    '20': ['(lbf)', '(N)', '(kN)'], // Force
    '21': ['(ft-lb)', '(J)', '(N-m)'], // Torque
    '22': [
      '(psi)',
      '(kPa)',
      '(MPa)',
      '(bar)',
      '(atm)',
      '(kgf/cm2)',
    ], // Pressure
    '23': ['(psi/ft)', '(kPa/m)', '(MPa/m)'], // Pressure gradient
    '24': ['(kPa)', '(MPa)', '(Pa)', '(psi)'], // Stress
    '25': ['(lbf/100ft2)', '(Pa)', '(N/m2)'], // Yield point
    '26': ['(HP)', '(KW)', '(W)'], // Power
    '27': ['(cP)', '(Pa-s)', '(mPa-s)'], // Viscosity
    '28': ['(lbf-s^n/100ft2)', '(Pa-s^n)'], // Consistency
    '29': ['(lbm)', '(kg)', '(g)'], // Weight
    '30': ['(lbm/min)', '(kg/min)', '(kg/s)'], // Mass rate
    '31': ['(lb/ft)', '(kg/m)'], // Line density
    '32': ['(lb/ft3)', '(kg/m3)', '(g/cm3)'], // Density
    '33': ['(ppg)', '(kg/m3)', '(g/cm3)', '(lb/ft3)', '(sg)'], // Mud weight
    '34': ['(°F)', '(°C)', '(K)'], // Temperature
    '35': ['(°F/100ft)', '(°C/100m)', '(°C/m)'], // Temperature gradient
    '36': ['(min)', '(sec)', '(hr)'], // Schedule time
    '37': ['(°/100ft)', '(°/30m)', '(°/10m)', '(°/m)'], // Dogleg
    '38': ['(°)'], // Degree
    '39': [
      '(lb/bbl)',
      '(kg/m3)',
      '(lb/gal)',
      '(lb/ft3)',
    ], // Mass - volume ratio
    '40': ['(gal/bbl)', '(L/m3)', '(mL/m3)'], // Volume - volume ratio
    '41': ['(lb/sk)', '(kg/bag)', '(kg/sk)'], // Cement/solid additive Wt/sk
    '42': ['(ft3/sk)', '(m3/bag)', '(L/sk)', '(gal/sk)'], // Cement slurry yield
    '43': [
      '(gal/sk)',
      '(L/bag)',
      '(L/sk)',
      '(m3/sk)',
    ], // Cement liquid additive/water requirement
    '44': ['(mg/L)', '(ppm)'], // Concentration
    '45': ['(Btu/hr/ft/°F)', '(W/m/K)', '(kcal/hr/m/°C)'], // Conductivity
    '46': ['(Btu/lbm/°F)', '(J/kg/°C)', '(kcal/kg/°C)'], // Heat Capacity
    '47': ['(Btu/hr/ft2/°F)', '(W/m2/K)'], // Heat transfer coefficient
    '48': ['(°F)', '(°C)'], // Temperature Drop
    '49': ['(sec/qt)', '(sec/L)'], // Funnel viscosity
  };

  // ════════════════════════════════════════════════════════════════════════════
  // CONVERSION — convert value from fromUnit to toUnit
  // Returns null if conversion is not defined (unsupported pair).
  // All conversions go through a base SI unit to allow any-to-any.
  // ════════════════════════════════════════════════════════════════════════════

  double? convert(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    final normalizedFrom = _normalizeUnit(fromUnit);
    final normalizedTo = _normalizeUnit(toUnit);
    for (final entry in _conversionGroups.entries) {
      final group = entry.value;
      String? matchedFrom;
      String? matchedTo;
      for (final unit in group.keys) {
        final normalized = _normalizeUnit(unit);
        if (normalized == normalizedFrom) {
          matchedFrom = unit;
        }
        if (normalized == normalizedTo) {
          matchedTo = unit;
        }
      }
      if (matchedFrom != null && matchedTo != null) {
        final toBase = group[matchedFrom]!;
        final fromBase = group[matchedTo]!;
        return value * toBase / fromBase;
      }
    }

    // Find the group that contains both units
    for (final entry in _conversionGroups.entries) {
      final group = entry.value;
      if (group.containsKey(fromUnit) && group.containsKey(toUnit)) {
        // Convert fromUnit → base, then base → toUnit
        final toBase = group[fromUnit]!;
        final fromBase = group[toUnit]!;
        return value * toBase / fromBase;
      }
    }
    return null; // no conversion defined
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CONVERSION GROUPS
  // Each group maps unit → factor to convert TO base (SI or logical base).
  // To convert A → B: value * factor[A] / factor[B]
  //
  // Source: Excel "Conversion Factors" table from image 1 + standard SI.
  // ════════════════════════════════════════════════════════════════════════════
  static const Map<String, Map<String, double>> _conversionGroups = {
    // ── LENGTH (base: m) ───────────────────────────────────────────────────
    'length': {
      '(ft)': 0.3048,
      '(m)': 1.0,
      '(in)': 0.0254,
      '(mm)': 0.001,
      '(cm)': 0.01,
      '(dm)': 0.1,
      '(1/32in)': 0.000793750, // 1/32 inch = 0.03125 in = 0.79375 mm
    },

    // ── AREA (base: m²) ────────────────────────────────────────────────────
    'area': {
      '(ft2)': 0.0929, // ft² → m²
      '(m2)': 1.0,
      '(in2)': 0.000645160, // in² → m²
      '(mm2)': 0.000001,
      '(cm2)': 0.0001,
      '(dm2)': 0.01,
    },

    // ── VOLUME (base: m³) ──────────────────────────────────────────────────
    'volume': {
      '(bbl)': 0.158987, // 1 bbl = 0.158987 m³
      '(m3)': 1.0,
      '(ft3)': 0.0283168,
      '(in3)': 0.0000163871,
      '(gal)': 0.00378541,
      '(L)': 0.001,
      '(mL)': 0.000001,
      '(qt)': 0.000946353,
      '(oz)': 0.0000295735, // fluid oz
      '(scf)': 0.0283168, // standard cubic foot
    },

    // ── VELOCITY (base: m/s) ───────────────────────────────────────────────
    'velocity': {
      '(ft/min)': 0.00508,
      '(m/min)': 0.016667,
      '(ft/s)': 0.3048,
      '(m/s)': 1.0,
      '(ft/hr)': 0.0000847,
      '(m/hr)': 0.000278,
      '(mph)': 0.44704,
      '(km/h)': 0.27778,
      '(knots)': 0.51444,
    },

    // ── PRESSURE (base: kPa) ──────────────────────────────────────────────
    'pressure': {
      '(psi)': 6.89476, // psi → kPa
      '(kPa)': 1.0,
      '(MPa)': 1000.0,
      '(bar)': 100.0,
      '(atm)': 101.325,
      '(kgf/cm2)': 98.0665,
      '(psi/ft)': 22.621, // pressure gradient — treated as pressure ratio
      '(kPa/m)': 1.0,
      '(MPa/m)': 1000.0,
    },

    // ── DENSITY / MUD WEIGHT (base: kg/m³) ────────────────────────────────
    'density': {
      '(ppg)': 119.826, // lb/gal → kg/m³
      '(kg/m3)': 1.0,
      '(g/cm3)': 1000.0,
      '(lb/ft3)': 16.0185,
      '(sg)': 1000.0, // SG × 1000 = kg/m³
    },

    // ── TEMPERATURE — handled specially (non-linear), see convertTemp() ───

    // ── TEMPERATURE GRADIENT (base: °C/100m) ──────────────────────────────
    'tempGradient': {
      '(°F/100ft)': 1.8228, // °F/100ft → °C/100m  (×1.8/0.3048×100)
      '(°C/100m)': 1.0,
      '(°F/1000ft)': 0.18228,
      '(°C/m)': 100.0,
    },

    // ── DOGLEG (base: °/100m) ─────────────────────────────────────────────
    'dogleg': {
      '(°/100ft)': 32.808, // °/100ft → °/100m  (÷0.3048)
      '(°/100m)': 1.0,
      '(°/30m)': 3.3333,
      '(°/10m)': 10.0,
      '(°/m)': 100.0,
    },

    // ── FLOW RATE (base: m³/min) ──────────────────────────────────────────
    'flowRate': {
      '(gpm)': 0.00378541, // gal/min → m³/min
      '(m3/min)': 1.0,
      '(bpm)': 0.158987, // bbl/min → m³/min
      '(L/min)': 0.001,
      '(L/s)': 0.06,
    },

    // ── ROP (base: m/hr) ──────────────────────────────────────────────────
    'rop': {
      '(ft/hr)': 0.3048,
      '(m/hr)': 1.0,
      '(m/day)': 0.041667,
      '(ft/day)': 0.012700,
    },

    // ── PIPE CAPACITY VOL/LEN (base: m³/m) ────────────────────────────────
    'pipeCap_v_l': {
      '(bbl/ft)': 0.52178, // bbl/ft → m³/m  (0.158987/0.3048)
      '(m3/m)': 1.0,
      '(ft3/m)': 0.0929,
      '(bbl/m)': 0.158987,
      '(L/m)': 0.001,
      '(gal/ft)': 0.012419,
    },

    // ── PIPE CAPACITY LEN/VOL (base: m/m³) ────────────────────────────────
    'pipeCap_l_v': {
      '(ft/bbl)': 1.91713, // ft/bbl → m/m³  (0.3048/0.158987)
      '(m/m3)': 1.0,
      '(ft/gal)': 80.52,
      '(m/bbl)': 6.28981,
      '(m/ft3)': 35.3147,
      '(m/L)': 1000.0,
    },

    // ── MASS-VOLUME (solid conc, base: kg/m³) ─────────────────────────────
    'massVolume': {
      '(lb/bbl)': 2.85301, // lb/bbl → kg/m³
      '(kg/m3)': 1.0,
      '(lb/gal)': 119.826,
      '(lb/ft3)': 16.0185,
      '(g/L)': 1.0,
    },

    // ── VOL-VOL (base: L/m³) ──────────────────────────────────────────────
    'viscosity': {'(cP)': 0.001, '(mPa-s)': 0.001, '(Pa-s)': 1.0},

    'yieldPoint': {
      '(lbf/100ft2)': 0.4788026,
      '(lb/100ft2)': 0.4788026,
      '(lbs/100ft2)': 0.4788026,
      '(Pa)': 1.0,
      '(N/m2)': 1.0,
    },

    'concentration': {'(mg/L)': 1.0, '(ppm)': 1.0},

    'volVol': {
      '(gal/bbl)': 23.8095, // gal/bbl → L/m³
      '(L/m3)': 1.0,
      '(mL/m3)': 0.001,
    },

    // ── MASS (base: kg) ────────────────────────────────────────────────────
    'mass': {
      '(sk)': 42.6389, // 1 sk cement ≈ 94 lb = 42.638 kg
      '(bag)': 42.6389,
      '(kg)': 1.0,
      '(lb)': 0.453592,
    },

    'lineDensity': {'(lb/ft)': 1.48816, '(kg/m)': 1.0},

    // ── ADDITIVE PER SK (base: kg/sk) ─────────────────────────────────────
    'perSk': {'(lb/sk)': 0.453592, '(kg/bag)': 1.0, '(kg/sk)': 1.0},

    // ── LIQUID PER SK (base: L/sk) ────────────────────────────────────────
    'liqPerSk': {
      '(gal/sk)': 3.78541,
      '(L/bag)': 1.0,
      '(L/sk)': 1.0,
      '(mL/sk)': 0.001,
    },

    // ── SLURRY YIELD (base: m³/bag) ───────────────────────────────────────
    'slurryYield': {
      '(ft3/sk)': 0.0283168,
      '(m3/bag)': 1.0,
      '(L/sk)': 0.001,
      '(gal/sk)': 0.00378541,
    },

    // ── COST PER VOLUME (base: $/m³) ──────────────────────────────────────
    'cost': {
      r'($/bbl)': 6.28981, // $/bbl → $/m³
      r'($/m3)': 1.0,
      r'($/gal)': 264.172,
    },

    // ── FORCE (base: N) ───────────────────────────────────────────────────
    'force': {'(lbf)': 4.44822, '(N)': 1.0, '(kN)': 1000.0},

    // ── TORQUE / ENERGY (base: J) ─────────────────────────────────────────
    'torque': {'(ft-lb)': 1.35582, '(J)': 1.0, '(N-m)': 1.0},

    // ── HEAT CAPACITY (base: J/kg/°C) ─────────────────────────────────────
    'heatCapacity': {
      '(Btu/lb/°F)': 4186.8,
      '(J/kg/°C)': 1.0,
      '(kcal/kg/°C)': 4186.8,
    },

    // ── THERMAL CONDUCTIVITY (base: W/m/K) ────────────────────────────────
    'thermalConductivity': {
      '(Btu/hr/ft/°F)': 1.73073,
      '(W/m/K)': 1.0,
      '(kcal/hr/m/°C)': 1.16279,
    },

    // ── THERMAL EXPANSION (base: 10⁻⁶/°C) ────────────────────────────────
    'thermalExpansion': {
      '(10-6/°F)': 1.8, // 1 per°F = 1.8 per°C
      '(10-6/°C)': 1.0,
    },

    // ── ELASTIC MODULUS (base: MPa) ───────────────────────────────────────
    'elasticity': {
      '(MPa)': 1.0,
      '(GPa)': 1000.0,
      '(psi)': 0.00689476,
      '(kPa)': 0.001,
    },

    // ── LIQUID VOLUME (base: L) ───────────────────────────────────────────
    'liquidVolume': {
      '(gal)': 3.78541,
      '(L)': 1.0,
      '(bbl)': 158.987,
      '(m3)': 1000.0,
      '(qt)': 0.946353,
      '(oz)': 0.0295735,
    },

    // ── FUNNEL VISCOSITY (base: sec/L) ────────────────────────────────────
    'funnelVisc': {'(sec/qt)': 0.946353, '(sec/L)': 1.0, '(s/L)': 1.0},

    // ── CUTTING TRANSPORT (base: tonne/h) ─────────────────────────────────
    'cuttingTransport': {
      '(US ton/h)': 0.907185,
      '(tonne/h)': 1.0,
      '(kg/h)': 0.001,
      '(lb/h)': 0.000453592,
    },

    // ── STROKE DISPLACEMENT (base: m³/stk) ────────────────────────────────
    'strokeDisp': {
      '(bbl/stk)': 0.158987,
      '(m3/stk)': 1.0,
      '(gal/stk)': 0.00378541,
      '(L/stk)': 0.001,
    },

    // ── SPRING CONSTANT (base: N/m) ────────────────────────────────────────
    'springConst': {'(fbf/ft)': 14.5939, '(N/m)': 1.0, '(lbf/ft)': 14.5939},
  };

  // ════════════════════════════════════════════════════════════════════════════
  // TEMPERATURE — non-linear, handled separately
  // ════════════════════════════════════════════════════════════════════════════

  /// Returns converted temperature value, or null if not a temp pair.
  double? convertTemp(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    // Normalize: strip brackets
    final from = fromUnit.replaceAll(RegExp(r'[()]'), '');
    final to = toUnit.replaceAll(RegExp(r'[()]'), '');

    if (from == '°F' && to == '°C') return (value - 32) * 5 / 9;
    if (from == '°C' && to == '°F') return value * 9 / 5 + 32;
    if (from == '°F' && to == 'K') return (value - 32) * 5 / 9 + 273.15;
    if (from == '°C' && to == 'K') return value + 273.15;
    if (from == 'K' && to == '°C') return value - 273.15;
    if (from == 'K' && to == '°F') return (value - 273.15) * 9 / 5 + 32;
    return null;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MAIN ENTRY POINT
  // Tries temperature first, then generic group-based conversion.
  // ════════════════════════════════════════════════════════════════════════════

  double? convertValue(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    final normalizedTempResult = convertNormalizedTemp(value, fromUnit, toUnit);
    if (normalizedTempResult != null) return normalizedTempResult;

    // Temperature parameters (22 and 36)
    final tempResult = convertTemp(value, fromUnit, toUnit);
    if (tempResult != null) return tempResult;

    // Generic group conversion
    return convert(value, fromUnit, toUnit);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Get allowed units for a parameter number
  // ════════════════════════════════════════════════════════════════════════════
  List<String> getUnitsForParam(String paramNumber) {
    return parameterUnits[paramNumber] ?? [];
  }
}
