class UnitDefinitions {
  UnitDefinitions._();

  static const List<Map<String, String>> parameters = [
    {'number': '1', 'name': 'Length'},
    {'number': '2', 'name': 'Pipe diameter'},
    {'number': '3', 'name': 'Nozzle diameter'},
    {'number': '4', 'name': 'Surface area'},
    {'number': '5', 'name': 'Cross section'},
    {'number': '6', 'name': 'Fluid volume'},
    {'number': '7', 'name': 'Pipe capacity (volume/length)'},
    {'number': '8', 'name': 'Pipe capacity (length/volume)'},
    {'number': '9', 'name': 'Solid volume'},
    {'number': '10', 'name': 'Small volume'},
    {'number': '11', 'name': 'Stroke displacement'},
    {'number': '12', 'name': 'Gas volume'},
    {'number': '13', 'name': 'Velocity'},
    {'number': '14', 'name': 'Nozzle velocity'},
    {'number': '15', 'name': 'ROP'},
    {'number': '16', 'name': 'Rotation'},
    {'number': '17', 'name': 'Liquid flow rate for drilling'},
    {'number': '18', 'name': 'Liquid flow rate for cementing'},
    {'number': '19', 'name': 'Stroke rate'},
    {'number': '20', 'name': 'Force'},
    {'number': '21', 'name': 'Torque'},
    {'number': '22', 'name': 'Pressure'},
    {'number': '23', 'name': 'Pressure gradient'},
    {'number': '24', 'name': 'Stress'},
    {'number': '25', 'name': 'Yield point'},
    {'number': '26', 'name': 'Power'},
    {'number': '27', 'name': 'Viscosity'},
    {'number': '28', 'name': 'Consistency'},
    {'number': '29', 'name': 'Weight'},
    {'number': '30', 'name': 'Mass rate'},
    {'number': '31', 'name': 'Line density'},
    {'number': '32', 'name': 'Density'},
    {'number': '33', 'name': 'Mud weight'},
    {'number': '34', 'name': 'Temperature'},
    {'number': '35', 'name': 'Temperature gradient'},
    {'number': '36', 'name': 'Schedule time'},
    {'number': '37', 'name': 'Dogleg'},
    {'number': '38', 'name': 'Degree'},
    {'number': '39', 'name': 'Mass - volume ratio'},
    {'number': '40', 'name': 'Volume - volume ratio'},
    {'number': '41', 'name': 'Cement/solid additive Wt/sk'},
    {'number': '42', 'name': 'Cement slurry yield'},
    {'number': '43', 'name': 'Cement liquid additive/water requirement'},
    {'number': '44', 'name': 'Concentration'},
    {'number': '45', 'name': 'Conductivity'},
    {'number': '46', 'name': 'Heat Capacity'},
    {'number': '47', 'name': 'Heat transfer coefficient'},
    {'number': '48', 'name': 'Temperature Drop'},
    {'number': '49', 'name': 'Funnel viscosity'},
  ];

  static const Map<String, List<String>> parameterUnits = {
    '1': ['(ft)', '(m)'],
    '2': ['(in)', '(mm)', '(cm)', '(dm)', '(m)', '(ft)'],
    '3': ['(1/32in)', '(mm)', '(in)'],
    '4': ['(ft2)', '(m2)'],
    '5': ['(in2)', '(mm2)', '(cm2)', '(dm2)', '(m2)', '(ft2)'],
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
    ],
    '7': ['(bbl/ft)', '(m3/m)', '(ft3/m)', '(bbl/m)', '(L/m)', '(gal/ft)'],
    '8': ['(ft/bbl)', '(m/m3)', '(ft/gal)', '(m/bbl)', '(m/ft3)', '(m/L)'],
    '9': [
      '(ft3)',
      '(m3)',
      '(mL)',
      '(L)',
      '(in3)',
      '(bbl)',
      '(pt)',
      '(qt)',
      '(gal)',
    ],
    '10': [
      '(in3)',
      '(L)',
      '(pt)',
      '(qt)',
      '(mL)',
      '(bbl)',
      '(gal)',
      '(ft3)',
      '(m3)',
    ],
    '11': ['(bbl/stk)', '(m3/stk)', '(L/stk)', '(gal/stk)'],
    '12': ['(scf)', '(m3)', '(MMscf)', '(Mscf)'],
    '13': [
      '(ft/min)',
      '(m/min)',
      '(m/d)',
      '(m/h)',
      '(m/s)',
      '(ft/d)',
      '(ft/h)',
      '(ft/s)',
    ],
    '14': ['(ft/s)', '(m/s)'],
    '15': ['(ft/hr)', '(m/hr)', '(ft/day)', '(m/day)'],
    '16': ['(rpm)'],
    '17': [
      '(gpm)',
      '(m3/min)',
      '(bbl/min)',
      '(gal/h)',
      '(L/min)',
      '(bbl/hr)',
      '(L/h)',
      '(m3/h)',
      '(ft3/min)',
    ],
    '18': [
      '(bpm)',
      '(m3/min)',
      '(gpm)',
      '(L/h)',
      '(L/min)',
      '(m3/h)',
      '(bbl/hr)',
      '(gal/h)',
      '(ft3/min)',
    ],
    '19': ['(stk/min)'],
    '20': ['(lbf)', '(N)', '(ton)', '(Kip)', '(kN)', '(T)', '(daN)', '(kg)'],
    '21': ['(ft-lb)', '(N-m)', '(kg-m)', '(kN-m)', '(Kip-ft)'],
    '22': [
      '(psi)',
      '(kPa)',
      '(MPa)',
      '(bar)',
      '(kpsi)',
      '(Pa)',
      '(kg/cm2)',
      '(ATM)',
    ],
    '23': [
      '(psi/ft)',
      '(kPa/m)',
      '(MPa/m)',
      '(Pa/m)',
      '(ppg)',
      '(S.G.)',
      '(kg/L)',
      '(bar/10m)',
    ],
    '24': ['(psi)', '(kPa)', '(kg/cm2)', '(Pa)', '(MPa)'],
    '25': ['(lbf/100ft2)', '(Pa)', '(dyne/cm2)', '(kPa)', '(MPa)'],
    '26': [
      '(HP)',
      '(KW)',
      '(ft-lb/sec)',
      '(Btu/sec)',
      '(ft-lb/min)',
      '(W)',
      '(kg-m/min)',
      '(Btu/min)',
    ],
    '27': ['(cP)', '(dyne-s/cm2)', '(kPa-s)', '(lbf-s/ft2)', '(Pa-s)'],
    '28': ['(lbf-s^n/100ft2)', '(Pa-s^n)', '(dyne-s^n/cm2)', '(eq.cp)'],
    '29': ['(lbm)', '(kg)', '(ton)', '(oz)', '(mg)', '(g)'],
    '30': ['(lbm/min)', '(kg/min)', '(lbm/s)', '(lbm/d)', '(kg/s)', '(kg/d)'],
    '31': ['(lb/ft)', '(kg/m)', '(kg/cm)', '(lb/in)'],
    '32': ['(lb/ft3)', '(kg/m3)'],
    '33': [
      '(ppg)',
      '(kg/m3)',
      '(kPa/m)',
      '(lb/ft3)',
      '(psi/100ft)',
      '(S.G.)',
      '(kg/L)',
      '(g/cm3)',
      '(bar/10m)',
    ],
    '34': ['(°F)', '(°C)', '(K)', '(R)'],
    '35': ['(°F/100ft)', '(°C/100m)', '(°F/ft)', '(°C/m)', '(R/ft)', '(K/m)'],
    '36': ['(min)', '(year)', '(day)', '(sec)', '(hour)'],
    '37': ['(°/100ft)', '(°/30m)'],
    '38': ['(°)', '(rad)'],
    '39': ['(lb/bbl)', '(kg/m3)'],
    '40': ['(gal/bbl)', '(L/m3)', '(bbl/bbl)', '(m3/m3)'],
    '41': ['(lb/sk)', '(kg/sk)', '(kg/kg)', '(kg/ton)'],
    '42': [
      '(ft3/sk)',
      '(m3/sk)',
      '(m3/kg)',
      '(bbl/lb)',
      '(L/kg)',
      '(L/ton)',
      '(m3/ton)',
      '(gal/sk)',
      '(gal/lb)',
      '(ft3/lb)',
      '(L/sk)',
      '(gphs)',
      '(bbl/sk)',
    ],
    '43': [
      '(gal/sk)',
      '(m3/sk)',
      '(L/kg)',
      '(m3/kg)',
      '(bbl/lb)',
      '(L/sk)',
      '(gphs)',
      '(bbl/sk)',
      '(ft3/lb)',
      '(ft3/sk)',
      '(gal/lb)',
      '(m3/ton)',
      '(L/ton)',
    ],
    '44': ['(mg/L)'],
    '45': [
      '(Btu/hr/ft/°F)',
      '(W/m/K)',
      '(Btu-in/hr/ft2/°F)',
      '(Cal/s/m/°C)',
      '(Cal/s/cm/°C)',
    ],
    '46': [
      '(Btu/lbm/°F)',
      '(KJ/kg/K)',
      '(Btu/lbm/°C)',
      '(Btu/lbm/R)',
      '(Cal/g/°C)',
      '(CHU/lbm/°C)',
      '(J/g/°C)',
      '(J/kg/K)',
      '(J/kg/°C)',
      '(KCal/kg/°C)',
      '(KJ/kg/°C)',
    ],
    '47': [
      '(Btu/hr/ft2/°F)',
      '(W/m2/K)',
      '(W/m2/°C)',
      '(J/s/m2/K)',
      '(Cal/s/cm2/°C)',
      '(KCal/hr/m2/°C)',
      '(KCal/hr/ft2/°C)',
      '(Btu/s/ft2/°F)',
      '(CHU/hr/ft2/°C)',
    ],
    '48': ['(°F)', '(°C)', '(K)', '(R)'],
    '49': ['(sec/qt)', '(sec/L)'],
  };

  static const Map<String, String> usDefaults = {
    '1': '(ft)',
    '2': '(in)',
    '3': '(1/32in)',
    '4': '(ft2)',
    '5': '(in2)',
    '6': '(bbl)',
    '7': '(bbl/ft)',
    '8': '(ft/bbl)',
    '9': '(ft3)',
    '10': '(in3)',
    '11': '(bbl/stk)',
    '12': '(scf)',
    '13': '(ft/min)',
    '14': '(ft/s)',
    '15': '(ft/hr)',
    '16': '(rpm)',
    '17': '(gpm)',
    '18': '(bpm)',
    '19': '(stk/min)',
    '20': '(lbf)',
    '21': '(ft-lb)',
    '22': '(psi)',
    '23': '(psi/ft)',
    '24': '(psi)',
    '25': '(lbf/100ft2)',
    '26': '(HP)',
    '27': '(cP)',
    '28': '(lbf-s^n/100ft2)',
    '29': '(lbm)',
    '30': '(lbm/min)',
    '31': '(lb/ft)',
    '32': '(lb/ft3)',
    '33': '(ppg)',
    '34': '(°F)',
    '35': '(°F/100ft)',
    '36': '(min)',
    '37': '(°/100ft)',
    '38': '(°)',
    '39': '(lb/bbl)',
    '40': '(gal/bbl)',
    '41': '(lb/sk)',
    '42': '(ft3/sk)',
    '43': '(gal/sk)',
    '44': '(mg/L)',
    '45': '(Btu/hr/ft/°F)',
    '46': '(Btu/lbm/°F)',
    '47': '(Btu/hr/ft2/°F)',
    '48': '(°F)',
    '49': '(sec/qt)',
  };

  static const Map<String, String> siDefaults = {
    '1': '(m)',
    '2': '(mm)',
    '3': '(mm)',
    '4': '(m2)',
    '5': '(mm2)',
    '6': '(m3)',
    '7': '(m3/m)',
    '8': '(m/m3)',
    '9': '(m3)',
    '10': '(L)',
    '11': '(m3/stk)',
    '12': '(m3)',
    '13': '(m/min)',
    '14': '(m/s)',
    '15': '(m/hr)',
    '16': '(rpm)',
    '17': '(m3/min)',
    '18': '(m3/min)',
    '19': '(stk/min)',
    '20': '(N)',
    '21': '(N-m)',
    '22': '(kPa)',
    '23': '(kPa/m)',
    '24': '(kPa)',
    '25': '(Pa)',
    '26': '(KW)',
    '27': '(cP)',
    '28': '(Pa-s^n)',
    '29': '(kg)',
    '30': '(kg/min)',
    '31': '(kg/m)',
    '32': '(kg/m3)',
    '33': '(kg/m3)',
    '34': '(°C)',
    '35': '(°C/100m)',
    '36': '(min)',
    '37': '(°/30m)',
    '38': '(°)',
    '39': '(kg/m3)',
    '40': '(L/m3)',
    '41': '(kg/sk)',
    '42': '(m3/sk)',
    '43': '(m3/sk)',
    '44': '(mg/L)',
    '45': '(W/m/K)',
    '46': '(KJ/kg/K)',
    '47': '(W/m2/K)',
    '48': '(°C)',
    '49': '(sec/L)',
  };

  static final Map<String, String> pegasusDefault1Defaults = {
    ...usDefaults,
    '2': '(mm)',
  };

  static final Map<String, String> pegasusDefault3Defaults = {
    ...usDefaults,
    '1': '(m)',
  };

  static String normalizeText(String text) {
    return text
        .replaceAll('Ã‚', '')
        .replaceAll('Â²', '2')
        .replaceAll('Â³', '3')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .replaceAll('Â°', '°')
        .replaceAll('–', '-')
        .replaceAll('—', '-');
  }

  static String normalizeUnitKey(String unit) {
    return normalizeText(unit)
        .trim()
        .replaceAll(RegExp(r'[()]'), '')
        .replaceAll('°', 'deg')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .toLowerCase();
  }

  static final Map<String, String> _canonicalUnitsByKey =
      _buildCanonicalUnitsByKey();

  static Map<String, String> _buildCanonicalUnitsByKey() {
    final map = <String, String>{};

    void addUnit(String unit) {
      final wrapped = unit.startsWith('(') && unit.endsWith(')')
          ? unit
          : '($unit)';
      map[normalizeUnitKey(wrapped)] = wrapped;
      map[normalizeUnitKey(unit)] = wrapped;
    }

    void addAlias(String alias, String canonical) {
      map[normalizeUnitKey(alias)] = canonical;
      map[normalizeUnitKey('($alias)')] = canonical;
    }

    for (final units in parameterUnits.values) {
      for (final unit in units) {
        addUnit(unit);
      }
    }
    for (final unit in usDefaults.values) {
      addUnit(unit);
    }
    for (final unit in siDefaults.values) {
      addUnit(unit);
    }
    for (final unit in pegasusDefault1Defaults.values) {
      addUnit(unit);
    }
    for (final unit in pegasusDefault3Defaults.values) {
      addUnit(unit);
    }
    addAlias('atm', '(ATM)');
    addAlias('sg', '(S.G.)');
    addAlias('hr', '(hour)');
    addAlias('s/L', '(sec/L)');
    addAlias('lb/100ft2', '(lbf/100ft2)');
    addAlias('lbs/100ft2', '(lbf/100ft2)');
    addAlias('btu/lb/°f', '(Btu/lbm/°F)');
    return map;
  }

  static String canonicalizeDisplayUnit(String unit) {
    final cleaned = normalizeText(unit).trim();
    if (cleaned.isEmpty || cleaned == '-') {
      return cleaned;
    }
    final canonical = _canonicalUnitsByKey[normalizeUnitKey(cleaned)];
    if (canonical != null) {
      return canonical;
    }
    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      return cleaned;
    }
    return '($cleaned)';
  }

  static bool isAllowedUnit(String paramNumber, String unit) {
    final canonical = canonicalizeDisplayUnit(unit);
    return parameterUnits[paramNumber]?.contains(canonical) ?? false;
  }

  static Map<String, String>? templateDefaultsForName(String name) {
    switch (name.trim().toLowerCase()) {
      case 'pegasus default':
      case 'us oil field':
      case 'us':
        return usDefaults;
      case 'si':
      case 'metric':
      case 'si metric':
        return siDefaults;
      case 'pegasus default 1':
        return pegasusDefault1Defaults;
      case 'pegasus default 3':
        return pegasusDefault3Defaults;
      default:
        return null;
    }
  }

  static String defaultUnitFor(
    String paramNumber, {
    String? baseTemplate,
    String? systemName,
  }) {
    final namedDefaults = systemName == null
        ? null
        : templateDefaultsForName(systemName);
    if (namedDefaults != null && namedDefaults.containsKey(paramNumber)) {
      return namedDefaults[paramNumber]!;
    }
    if ((baseTemplate ?? '').toLowerCase() == 'si') {
      return siDefaults[paramNumber] ?? '-';
    }
    return usDefaults[paramNumber] ?? '-';
  }
}
