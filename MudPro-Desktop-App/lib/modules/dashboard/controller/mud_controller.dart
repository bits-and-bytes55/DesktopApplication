import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/mud_properties_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/mud_properties_model.dart';
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

const String _kBaseUrl = ApiEndpoint.baseUrl;
const Duration _kSaveDebounce = Duration(milliseconds: 800);

class _MixedSaltResult {
  const _MixedSaltResult({
    required this.cacl2Wt,
    required this.naclWt,
    required this.saltContent,
    required this.brineSg,
    required this.brineContent,
    required this.cacl2AqMgL,
    required this.naclAqMgL,
    required this.insolubleNaclMgL,
    required this.waterActivity,
  });

  final double cacl2Wt;
  final double naclWt;
  final double saltContent;
  final double brineSg;
  final double brineContent;
  final double cacl2AqMgL;
  final double naclAqMgL;
  final double insolubleNaclMgL;
  final double waterActivity;
}

class _OilSaltResult {
  const _OilSaltResult({
    required this.saltWtPct,
    required this.brineSG,
    required this.brineVolPct,
    required this.dissolvedSolidsPct,
    required this.correctedSolidsPct,
    required this.waterActivity,
  });

  final double saltWtPct;
  final double brineSG;
  final double brineVolPct;
  final double dissolvedSolidsPct;
  final double correctedSolidsPct;
  final double waterActivity;
}

class _SodiumFormateResult {
  const _SodiumFormateResult({
    required this.brinePhaseChlorides,
    required this.saltContent,
    required this.wpsPpm,
    required this.formateWt,
    required this.formateMgL,
    required this.brineDensityPpg,
    required this.brineSg,
    required this.dissolvedSolidsPct,
    required this.waterActivity,
  });

  final double brinePhaseChlorides;
  final double saltContent;
  final double wpsPpm;
  final double formateWt;
  final double formateMgL;
  final double brineDensityPpg;
  final double brineSg;
  final double dissolvedSolidsPct;
  final double waterActivity;
}

class MudController extends GetxController {
  static const double _negativeHgsLgsFactor = 0.679;
  static const double _cacl2ChlorideConversionFactor = 1.8779963086;
  static const double _pureCacl2ChlorideConversionFactor = 1.565;
  static const double _cacl2DissolvedSolidsBaseSg = 4.091;
  static const double _cacl2DissolvedSolidsSgSlope = 0.00169;
  static const double _cacl2MinimumDissolvedSolidsForBalance = 0.06;
  static const double _pureCacl2OilExcessLimeFactor = 0.26 / 75.0;
  static final Map<double, double> _sodiumFormateMgLByWt = {
    1.0: 3397.0,
    2.0: 6829.0,
    3.0: 10301.0,
    4.0: 13813.0,
    5.0: 17367.0,
    6.0: 20966.0,
    7.0: 24609.0,
    8.0: 28297.0,
    9.0: 32030.0,
    10.0: 35808.0,
    11.0: 39631.0,
    12.0: 43600.0,
    13.0: 47413.0,
    14.0: 51372.0,
    15.0: 55375.0,
    16.0: 59424.0,
    17.0: 63519.0,
    18.0: 67660.0,
    19.0: 71848.0,
    20.0: 76084.0,
    21.0: 80369.0,
    22.0: 84704.0,
    23.0: 89092.0,
    24.0: 93532.0,
    25.0: 98027.0,
    26.0: 102579.0,
    27.0: 107188.0,
    28.0: 111857.0,
    29.0: 116586.0,
    30.0: 121376.0,
    31.0: 126228.0,
    32.0: 131143.0,
    33.0: 136119.0,
    34.0: 141157.0,
    35.0: 146253.0,
    36.0: 151407.0,
    37.0: 156613.0,
    38.0: 161868.0,
    39.0: 167165.0,
    40.0: 172497.0,
    41.0: 177855.0,
    42.0: 183227.0,
    43.0: 188601.0,
    44.0: 193962.0,
    45.0: 199293.0,
    46.0: 204574.0,
    47.0: 209782.0,
    48.0: 214891.0,
    49.0: 219874.0,
    49.5: 222307.0,
  };
  static final Map<double, double> _sodiumFormateSgByWt = {
    1.0: 1.0049,
    2.0: 1.0102,
    3.0: 1.0157,
    4.0: 1.0215,
    5.0: 1.0275,
    6.0: 1.0337,
    7.0: 1.0400,
    8.0: 1.0464,
    9.0: 1.0528,
    10.0: 1.0593,
    11.0: 1.0668,
    12.0: 1.0724,
    13.0: 1.0789,
    14.0: 1.0855,
    15.0: 1.0921,
    16.0: 1.0987,
    17.0: 1.1053,
    18.0: 1.1120,
    19.0: 1.1187,
    20.0: 1.1254,
    21.0: 1.1322,
    22.0: 1.1390,
    23.0: 1.1459,
    24.0: 1.1529,
    25.0: 1.1600,
    26.0: 1.1671,
    27.0: 1.1744,
    28.0: 1.1818,
    29.0: 1.1893,
    30.0: 1.1969,
    31.0: 1.2046,
    32.0: 1.2124,
    33.0: 1.2202,
    34.0: 1.2282,
    35.0: 1.2362,
    36.0: 1.2442,
    37.0: 1.2522,
    38.0: 1.2601,
    39.0: 1.2680,
    40.0: 1.2757,
    41.0: 1.2833,
    42.0: 1.2906,
    43.0: 1.2975,
    44.0: 1.3041,
    45.0: 1.3101,
    46.0: 1.3156,
    47.0: 1.3204,
    48.0: 1.3244,
    49.0: 1.3274,
    49.5: 1.3286,
  };
  static final Map<double, double> _sodiumFormateAwByWt = {
    1.0: 0.99,
    2.0: 0.99,
    3.0: 0.98,
    4.0: 0.97,
    5.0: 0.97,
    6.0: 0.96,
    7.0: 0.95,
    8.0: 0.95,
    9.0: 0.94,
    10.0: 0.93,
    11.0: 0.93,
    12.0: 0.92,
    13.0: 0.91,
    14.0: 0.91,
    15.0: 0.90,
    16.0: 0.89,
    17.0: 0.89,
    18.0: 0.88,
    19.0: 0.87,
    20.0: 0.87,
    21.0: 0.86,
    22.0: 0.85,
    23.0: 0.84,
    24.0: 0.84,
    25.0: 0.83,
    26.0: 0.82,
    27.0: 0.81,
    28.0: 0.80,
    29.0: 0.79,
    30.0: 0.78,
    31.0: 0.77,
    32.0: 0.76,
    33.0: 0.75,
    34.0: 0.74,
    35.0: 0.73,
    36.0: 0.71,
    37.0: 0.70,
    38.0: 0.69,
    39.0: 0.68,
    40.0: 0.67,
    41.0: 0.66,
    42.0: 0.65,
    43.0: 0.64,
    44.0: 0.64,
    45.0: 0.63,
    46.0: 0.63,
    47.0: 0.62,
    48.0: 0.62,
    49.0: 0.62,
    49.5: 0.62,
  };
  final samples = ['1', '2', '3', 'Plan-L', 'Plan-H'];

  static final List<MudPropertyItem> _legacyWaterBasedRows = [
    MudPropertyItem(name: 'Flowline T.', unit: 'F'),
    MudPropertyItem(name: 'Depth', unit: 'ft'),
    MudPropertyItem(name: '*MW', unit: 'ppg'),
    MudPropertyItem(name: 'Funnel Visc.', unit: 'sec/qt'),
    MudPropertyItem(name: 'T. for PV', unit: 'F'),
    MudPropertyItem(name: '*PV', unit: 'cP'),
    MudPropertyItem(name: '*YP', unit: 'lbf/100ft2'),
    MudPropertyItem(name: 'Gel str. 10s', unit: 'lbf/100ft2'),
    MudPropertyItem(name: 'Gel str. 10m', unit: 'lbf/100ft2'),
    MudPropertyItem(name: 'Gel str. 30m', unit: 'lbf/100ft2'),
    MudPropertyItem(name: 'API Filtrate', unit: 'mL/30min'),
    MudPropertyItem(name: 'API Cake Thickness', unit: '1/32in'),
    MudPropertyItem(name: 'T. for HTHP', unit: 'F'),
    MudPropertyItem(name: 'HTHP Filtrate', unit: 'mL/30min'),
    MudPropertyItem(name: 'HTHP Cake Thickness', unit: '1/32in'),
    MudPropertyItem(name: 'Solids', unit: '%'),
    MudPropertyItem(name: '*Oil', unit: '%'),
    MudPropertyItem(name: '*Water', unit: '%'),
    MudPropertyItem(name: 'Sand Content', unit: '%'),
    MudPropertyItem(name: 'MBT Capacity', unit: 'lb/bbl'),
    MudPropertyItem(name: 'pH', unit: ''),
    MudPropertyItem(name: 'Mud Alkalinity (Pm)', unit: 'mL'),
    MudPropertyItem(name: 'Filtrate Alkalinity (Pf)', unit: 'mL'),
    MudPropertyItem(name: 'Filtrate Alkalinity (Mf)', unit: 'mL'),
    MudPropertyItem(name: 'Calcium', unit: 'mg/L'),
    MudPropertyItem(name: '*Chlorides', unit: 'mg/L'),
    MudPropertyItem(name: 'Total Hardness', unit: 'mg/L'),
    MudPropertyItem(name: 'Excess Lime', unit: 'lb/bbl'),
    MudPropertyItem(name: 'K+', unit: 'mg/L'),
    MudPropertyItem(name: 'Make up Water: Chlorides', unit: 'mg/L'),
    MudPropertyItem(name: 'Solids Adjusted for Salt', unit: '%'),
    MudPropertyItem(name: 'Fine LCM', unit: 'lb/bbl'),
    MudPropertyItem(name: 'Coarse LCM', unit: 'lb/bbl'),
  ];

  final _mudPropsCtrl = MudPropertiesController();
  final othersController = OthersController();

  var selectedFluidType = 'Water-based'.obs;

  final propertyTable = <String, List<RxString>>{}.obs;
  final propertyUnits = <String, String>{}.obs;
  final availableProperties = <String>[].obs;
  final rheologyTable = <String, List<RxString>>{}.obs;
  final Set<String> _basePropertyNames = <String>{};

  var rheologyModel = 'Bingham'.obs;
  var rheologyCalculation = 'API (RP 13D)'.obs;
  var isCompletionFluid = false.obs;
  var isWeightedMud = false.obs;
  var selectedSaltType = 'CaCl2'.obs;

  final fluidnameController = TextEditingController();
  final oilSgController = TextEditingController();
  final hgsSgController = TextEditingController();
  final lgsSgController = TextEditingController();
  final shaleCecController = TextEditingController();
  final bentCecController = TextEditingController();

  var sampleForCalculation = '1'.obs;
  var isLoading = false.obs;

  final solidAnalysisResult = <String, List<String>>{}.obs;
  var isSolidAnalysisLoading = false.obs;
  var solidAnalysisError = ''.obs;

  final _solidAnalysisIds = <int, String?>{0: null, 1: null, 2: null};
  final _debounceTimers = <int, Timer?>{};
  final _stateWorkers = <Worker>[];
  Timer? _mudStateSaveTimer;
  Worker? _wellWorker;
  Worker? _reportWorker;
  bool _isApplyingSavedState = false;
  bool _cleanNextReportLoad = false;
  final RxString _stateScopeKey = ''.obs;
  final Map<String, Map<String, dynamic>> _stateCache = {};
  final Set<String> _cleanNewReportIds = <String>{};

  final solidSaveStatus = <String, RxString>{
    '0': 'idle'.obs,
    '1': 'idle'.obs,
    '2': 'idle'.obs,
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FIELD KEY GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _normalizedKey(String key) => key
      .toLowerCase()
      .replaceAll('*', '')
      .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String? _findKey(bool Function(String) test) {
    for (final key in propertyTable.keys) {
      if (test(_normalizedKey(key))) return key;
    }
    return null;
  }

  // Matches: "MW (ppg)", "*MW (ppg)", "Mud Weight", "Mud Weight (ppg)"
  String? get _mwKey => _findKey(
    (k) =>
        k == 'mw' ||
        k.startsWith('mw') ||
        k.contains('mud weight') ||
        k.contains('mud wt') ||
        k.contains('mud density') ||
        (k.startsWith('density') && k.contains('ppg')),
  );

  // Retort solids — "*Solids (% vol)" USER INPUT. NOT auto-calc.
  // Must NOT match Total Solids, Corrected Solids, Drill Solids
  String? get _solidsKey => _findKey(
    (k) =>
        (k == 'solids' || k.startsWith('solids') || k == 'retort solids') &&
        !k.contains('total') &&
        !k.contains('corr') &&
        !k.contains('drill') &&
        !k.contains('adj') &&
        !k.contains('salt'),
  );

  String? get _oilKey => _findKey(
    (k) =>
        (k == 'oil' ||
            k == 'oil (% vol)' ||
            k == 'oil%' ||
            k.startsWith('oil ')) &&
        !k.contains('ratio') &&
        !k.contains('sg') &&
        !k.contains('water') &&
        !k.contains('density'),
  );

  String? get _waterKey => _findKey(
    (k) =>
        (k == 'water' ||
            k == 'water (% vol)' ||
            k == 'water%' ||
            k.startsWith('water ')) &&
        !k.contains('activity') &&
        !k.contains('sg') &&
        !k.contains('oil') &&
        !k.contains('phase') &&
        !k.contains('salinity'),
  );

  String? get _brinePercentKey => _findKey(
    (k) =>
        k == 'brine' ||
        k == 'brine (% vol)' ||
        k == 'brine%' ||
        (k.startsWith('brine') &&
            !k.contains('density') &&
            !k.contains('sg') &&
            !k.contains('salt') &&
            !k.contains('water')),
  );

  String? get _alkalinityKey => _findKey(
    (k) =>
        k.contains('whole mud alkalinity') ||
        k.contains('alkalinity (pom)') ||
        k.contains('alkalinity(pom)'),
  );

  String? get _wholeMudChlorideKey => _findKey(
    (k) =>
        k.contains('whole mud chloride') ||
        k == 'whole mud chlorides' ||
        (k.contains('chloride') && k.contains('mud') && !k.contains('calcium')),
  );

  String? get _mbtKey => _findKey(
    (k) =>
        k == 'mbt' ||
        k.startsWith('mbt') ||
        k.contains('methylene blue') ||
        k.contains('mbt (') ||
        k == 'mbt (ppb)',
  );

  String? get _cacl2PctWtKey => _findKey(
    (k) =>
        k == 'cacl2 (% wt)' ||
        k == 'cacl2 % wt' ||
        k.contains('cacl2 wt') ||
        (k.startsWith('cacl2') && (k.contains('wt') || k.contains('%'))),
  );

  String? get _saltContentWaterPhaseKey =>
      _findKey((k) => k.contains('salt content') && k.contains('water phase'));

  String? get _waterActivityKey =>
      _findKey((k) => k.contains('water activity'));

  String? get _cacl2ConcKey => _findKey(
    (k) =>
        k == 'cacl2' ||
        k.contains('cacl2 concentration') ||
        k.contains('cacl2 conc') ||
        k.contains('calcium chloride') ||
        (k.startsWith('cacl2') && k.contains('mg')) ||
        (k.startsWith('cacl2') && k.contains('concentration')),
  );

  String? get _naclPctWtKey => _findKey(
    (k) =>
        k == 'nacl (% wt)' ||
        k == 'nacl % wt' ||
        k.contains('nacl wt') ||
        (k.startsWith('nacl') && (k.contains('wt') || k.contains('%'))),
  );

  String? get _naclConcKey => _findKey(
    (k) =>
        k == 'nacl' ||
        (k.startsWith('nacl') && k.contains('mg')) ||
        k.contains('sodium chloride'),
  );

  String? get _insolubleNaclKey =>
      _findKey((k) => k.contains('insoluble') && k.contains('nacl'));

  String? get _wholeMudCaKey =>
      _findKey((k) => k.contains('whole mud ca') || k.contains('caom'));

  String? get _dissolvedSodiumFormateKey =>
      _findKey((k) => k.contains('dissolved') && k.contains('sodium formate'));

  String? get _sodiumFormateWtKey => _findKey(
    (k) =>
        k.contains('sodium formate') &&
        (k.contains('wt') || k.contains('%')) &&
        !k.contains('brine phase') &&
        !k.contains('dissolved'),
  );

  String? get _sodiumFormateConcKey => _findKey(
    (k) =>
        k.contains('sodium formate') &&
        (k.contains('mg') || k == 'sodium formate') &&
        !k.contains('brine phase') &&
        !k.contains('dissolved'),
  );

  String? get _brinePhaseChlorideSalinityKey => _findKey(
    (k) =>
        k.contains('brine phase') &&
        k.contains('chloride') &&
        k.contains('salinity'),
  );

  String? get _chloridesForSolidsKey => _findKey(
    (k) =>
        (k == 'chlorides' ||
            k.contains('chloride') ||
            k.contains('chlorides')) &&
        !k.contains('make up') &&
        !k.contains('makeup') &&
        !k.contains('calcium') &&
        !k.contains('cacl2') &&
        !k.contains('water phase'),
  );

  String? get _makeupWaterChloridesKey => _findKey(
    (k) =>
        (k.contains('make up') || k.contains('makeup')) &&
        k.contains('chloride'),
  );

  String? get _r600Key => _findKey((k) => k == 'r600' || k == 'r600 (rpm)');
  String? get _r300Key => _findKey((k) => k == 'r300' || k == 'r300 (rpm)');
  String? get _r6Key => _findKey((k) => k == 'r6' || k == 'r6 (rpm)');
  String? get _r3Key => _findKey((k) => k == 'r3' || k == 'r3 (rpm)');

  String? get _pvPropKey => _findKey(
    (k) =>
        (k == 'pv' || k == 'pv (cp)') &&
        !k.contains('t.') &&
        !k.contains('t for'),
  );

  String? get _ypPropKey =>
      _findKey((k) => k == 'yp' || k == 'yp (lbf/100ft2)');

  String? get _lsrypKey => _findKey((k) => k == 'lsryp' || k.contains('lsryp'));

  String? get _owRatioKey => _findKey(
    (k) => k.contains('oil') && k.contains('water') && k.contains('ratio'),
  );

  // "Total Solids" OUTPUT row only — NOT "*Solids" retort input
  String? get _totalSolidsKey => _findKey(
    (k) =>
        (k == 'total solids' || k.contains('total solids')) &&
        !k.contains('corr') &&
        !k.contains('drill'),
  );

  String? get _correctedSolidsKey {
    final adjustedForSalt = _findKey(
      (k) => k.contains('solids adjusted') || k.contains('adjusted for salt'),
    );
    if (adjustedForSalt != null) return adjustedForSalt;
    return _findKey(
      (k) => k.contains('corrected solids') || k.contains('corr. solids'),
    );
  }

  String? get _excessLimeKey => _findKey((k) => k.contains('excess lime'));

  String? get _wholeMudAlkKey => _findKey(
    (k) =>
        k == 'mud alkalinity' ||
        k == 'pm' ||
        k.contains('alkalinity mud') ||
        k.contains('whole mud alkalinity') ||
        k.contains('alkalinity (pom)') ||
        k.contains('alkalinity(pom)') ||
        k.contains('mud alkalinity (pm)'),
  );

  String? get _mudAlkalinityPmKey => _findKey(
    (k) =>
        k == 'mud alkalinity' ||
        k == 'pm' ||
        k.contains('mud alkalinity (pm)'),
  );

  // FIX: Match any "water phase salinity" row — field name does NOT contain 'ppm'
  String? get _wpsSaltPercentKey => _findKey(
    (k) =>
        k == 'wps' ||
        k.startsWith('wps ') ||
        k.contains('water phase salinity') ||
        k.contains('water phase sal'),
  );

  // Second WPS row (mg/l) — has 'mg' in name
  String? get _wpsSaltPpmKey => _findKey(
    (k) =>
        (k.contains('water phase salinity') || k.contains('water phase sal')) &&
        (k.contains('mg') || k.contains('mg/l') || k.contains('ppm')),
  );

  String? get _brineDensitySgKey => _findKey(
    (k) =>
        k == 'brine density' ||
        k.contains('brine density') ||
        k == 'brine density (sg)' ||
        k == 'brine sg',
  );

  String? get _brineContentKey => _findKey(
    (k) =>
        k == 'brine content' ||
        k == 'brine content (%)' ||
        (k.contains('brine') && k.contains('content')),
  );

  // LGS Density row in table (L57 in Excel) — different from panel lgsSgController
  String? get _lgsTableDensityKey => _findKey(
    (k) =>
        (k == 'lgs density' || k.startsWith('lgs density') || k == 'lgs') &&
        !k.contains('%') &&
        !k.contains('lb'),
  );

  // HGS Density row in table (L58)
  String? get _hgsTableDensityKey => _findKey(
    (k) =>
        (k == 'hgs density' || k.startsWith('hgs density') || k == 'hgs') &&
        !k.contains('%') &&
        !k.contains('lb'),
  );

  // Corrected Solids value row (L45) — for passing to backend
  String? get _corrSolidsValueKey {
    final adjustedForSalt = _findKey(
      (k) => k.contains('solids adjusted') || k.contains('adjusted for salt'),
    );
    if (adjustedForSalt != null) return adjustedForSalt;
    return _findKey(
      (k) => k.contains('corrected solids') || k.contains('corr. solids'),
    );
  }

  // Brine % vol row (L62) — from Solid Analysis section
  String? get _brineVolPctKey => _findKey(
    (k) =>
        k == 'brine' ||
        k == 'brine (% vol)' ||
        k == 'brine%' ||
        (k.startsWith('brine') &&
            !k.contains('density') &&
            !k.contains('sg') &&
            !k.contains('salt') &&
            !k.contains('water')),
  );

  String? get _bariteKey => _findKey(
    (k) => k == 'barite' || (k.contains('barite') && !k.contains('brine')),
  );

  String? get _bentoniteKey =>
      _findKey((k) => k == 'bentonite' || k.contains('bentonite'));

  String? get _brineDensityKey =>
      _findKey((k) => k == 'brine density' || k.contains('brine density'));

  // WBM-specific
  String? get _sandContentKey =>
      _findKey((k) => k == 'sand content' || k.contains('sand content'));
  String? get _filtAlkPfKey => _findKey(
    (k) =>
        k == 'pf' ||
        k == 'filtrate pf' ||
        (k.contains('filtrate alkalinity') &&
            (k.contains('pf') || k.contains('(pf)'))),
  );
  String? get _filtAlkMfKey => _findKey(
    (k) =>
        k == 'mf' ||
        k == 'filtrate mf' ||
        (k.contains('filtrate alkalinity') &&
            (k.contains('mf') || k.contains('(mf)'))),
  );
  String? get _calciumKey => _findKey(
    (k) =>
        k == 'calcium' || (k.startsWith('calcium') && !k.contains('chloride')),
  );
  String? get _mudChloridesMglKey => _findKey(
    (k) =>
        (k.contains('mud chloride') || k == 'mud chlorides') &&
        !k.contains('whole'),
  );
  String? get _kclKey => _findKey((k) => k == 'kcl' || k.startsWith('kcl'));
  String? get _apiFiltratePfKey => _findKey(
    (k) =>
        k.contains('api filtrate') ||
        (k.contains('filtrate') &&
            !k.contains('alkalinity') &&
            !k.contains('hthp')),
  );
  String? get _mbtAlkKey => _findKey(
    (k) => k == 'mbt' || k.startsWith('mbt') || k.contains('methylene blue'),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    _initRheologyTable();
    _attachTextControllerListeners();
    _wellWorker = ever<String>(
      padWellContext.selectedWellId,
      (_) => loadFluidTypeData(applySavedState: true),
    );
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => loadFluidTypeData(applySavedState: true),
    );
    loadFluidTypeData();
    super.onInit();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> loadFluidTypeData({bool applySavedState = true}) async {
    isLoading.value = true;
    _isApplyingSavedState = true;
    final reportIdForLoad = _reportId;
    final forceCleanState =
        applySavedState &&
        reportIdForLoad.isNotEmpty &&
        (_cleanNewReportIds.remove(reportIdForLoad) || _cleanNextReportLoad);
    if (forceCleanState) {
      _cleanNextReportLoad = false;
    }
    try {
      final cachedState = applySavedState && !forceCleanState
          ? _stateCache[_mudStateCacheKey]
          : null;
      final savedState =
          cachedState ??
          (applySavedState && !forceCleanState
              ? await _fetchMudReportState()
              : null);
      if (applySavedState && (savedState == null || forceCleanState)) {
        _resetMudStateDefaults();
      }
      final savedFluidType = (savedState?['fluidType'] ?? '').toString().trim();
      if (savedFluidType.isNotEmpty) {
        selectedFluidType.value = savedFluidType;
      }
      final savedSaltType = (savedState?['saltType'] ?? '').toString().trim();
      if (savedSaltType.isNotEmpty) {
        selectedSaltType.value = savedSaltType;
      }

      _clearMudBottomSections();
      propertyTable.clear();
      propertyUnits.clear();
      availableProperties.clear();
      solidAnalysisResult.clear();
      for (int i = 0; i < 3; i++) {
        _solidAnalysisIds[i] = null;
      }

      await Future.wait([
        _loadLeftTableFromMudProperties(),
        _loadDropdownFromOthers(),
      ]);
      _basePropertyNames
        ..clear()
        ..addAll(propertyTable.keys);

      _setupAutoCalculations();
      if (savedState != null) {
        _applyMudReportState(savedState);
        await refreshMudPropertyUnitsFromSetup();
        _setupAutoCalculations();
      }
      _setupSolidAnalysisWatchers();
      _setupMudStateWatchers();
      if (forceCleanState) {
        await saveMudReportState(force: true);
      }
    } catch (e) {
      debugPrint('[MudController] loadFluidTypeData error: $e');
    } finally {
      _isApplyingSavedState = false;
      isLoading.value = false;
    }
  }

  Future<void> _loadLeftTableFromMudProperties() async {
    try {
      final selected = await _mudPropsCtrl.getSelectedMudProperties();
      final selectedProps = switch (selectedFluidType.value) {
        'Water-based' => selected.waterBased,
        'Oil-based' => selected.oilBased,
        'Synthetic' => selected.oilBased,
        _ => <MudPropertyItem>[],
      };
      final props = _normalizeMudProperties(selectedProps);
      _addCommonFields();
      for (final item in props) {
        if (item.name.isNotEmpty) {
          propertyTable[item.name] = List.generate(
            samples.length,
            (_) => ''.obs,
          );
          propertyUnits[item.name] = item.unit;
        }
      }
    } catch (e) {
      debugPrint('[MudController] Left table fetch ERROR: $e');
      _addCommonFields();
    }
  }

  Future<void> refreshMudPropertyUnitsFromSetup() async {
    try {
      final selected = await _mudPropsCtrl.getSelectedMudProperties();
      final selectedProps = switch (selectedFluidType.value) {
        'Water-based' => selected.waterBased,
        'Oil-based' => selected.oilBased,
        'Synthetic' => selected.oilBased,
        _ => <MudPropertyItem>[],
      };
      final props = _normalizeMudProperties(selectedProps);
      var changed = false;
      for (final item in props) {
        if (item.name.isEmpty || !propertyTable.containsKey(item.name)) {
          continue;
        }
        if (propertyUnits[item.name] != item.unit) {
          propertyUnits[item.name] = item.unit;
          changed = true;
        }
      }
      if (changed) {
        propertyUnits.refresh();
      }
    } catch (e) {
      debugPrint('[MudController] refresh mud property units ERROR: $e');
    }
  }

  Future<void> _loadDropdownFromOthers() async {
    try {
      final data = switch (selectedFluidType.value) {
        'Water-based' => await othersController.getWaterBased(),
        'Oil-based' => await othersController.getOilBased(),
        'Synthetic' => await othersController.getOilBased(),
        _ => <dynamic>[],
      };
      availableProperties.value = data
          .where(
            (item) => item.name != null && (item.name as String).isNotEmpty,
          )
          .map<String>((item) => item.name as String)
          .toList();
    } catch (e) {
      debugPrint('[MudController] Dropdown fetch ERROR: $e');
      availableProperties.value = [];
    }
  }

  Future<void> refreshAvailablePropertiesFromOthers() async {
    await _loadDropdownFromOthers();
  }

  void _addCommonFields() {
    for (final field in [
      'Description',
      'Sample from',
      'Time Sample Taken (hh:mm)',
    ]) {
      propertyTable[field] = List.generate(samples.length, (_) => ''.obs);
      propertyUnits[field] = '';
    }
  }

  List<MudPropertyItem> _normalizeMudProperties(List<MudPropertyItem> props) {
    if (selectedFluidType.value == 'Oil-based' ||
        selectedFluidType.value == 'Synthetic') {
      return _normalizeOilBasedProperties(props);
    }
    if (selectedFluidType.value != 'Water-based') return props;

    final byName = <String, MudPropertyItem>{};
    for (final item in props) {
      final canonical = _canonicalWaterBasedProperty(
        item.name,
        unit: item.unit,
      );
      byName[canonical.name] = canonical;
    }

    final ordered = <MudPropertyItem>[];
    for (final row in _legacyWaterBasedRows) {
      ordered.add(byName.remove(row.name) ?? row);
    }
    ordered.addAll(
      byName.values.where((item) => _shouldKeepExtraWaterBasedRow(item.name)),
    );
    return ordered;
  }

  List<MudPropertyItem> _normalizeOilBasedProperties(
    List<MudPropertyItem> props,
  ) {
    final cleaned = props
        .where((item) => !_isOilSaltManagedRow(item.name))
        .toList(growable: true);
    final rows = _oilSaltRowsForType(selectedSaltType.value);
    final insertAt = cleaned.indexWhere(
      (item) => _normalizeLabel(item.name).contains('solids adjusted'),
    );
    if (insertAt == -1) {
      cleaned.addAll(rows);
    } else {
      cleaned.insertAll(insertAt + 1, rows);
    }
    return cleaned;
  }

  bool _isOilSaltManagedRow(String name) {
    final key = _normalizeLabel(name);
    return key.contains('salt content water phase') ||
        key == 'wps' ||
        key.contains('whole mud ca') ||
        key.contains('caom') ||
        key.contains('cacl2') ||
        key.contains('nacl') ||
        key.contains('brine density') ||
        key.contains('brine content') ||
        key.contains('water activity') ||
        key.contains('water phase salinity') ||
        key.contains('brine phase salinity') ||
        key.contains('brine phase chlorides salinity') ||
        key.contains('oil/sodium formate') ||
        key.contains('sodium formate brine') ||
        key.contains('sodium formate wt') ||
        key == 'sodium formate' ||
        key.contains('dissolved sodium formate');
  }

  List<MudPropertyItem> _oilSaltRowsForType(String saltType) {
    switch (saltType) {
      case 'NaCl':
        return [
          MudPropertyItem(name: 'Salt Content Water Phase (%)', unit: '% wt'),
          MudPropertyItem(name: 'WPS', unit: 'ppm'),
          MudPropertyItem(name: 'NaCl Wt. (%)', unit: '% wt'),
          MudPropertyItem(name: 'NaCl', unit: 'mg/L'),
          MudPropertyItem(name: 'Brine Density', unit: 'ppg'),
          MudPropertyItem(name: 'Brine Content (%)', unit: '%'),
          MudPropertyItem(name: 'Electrical Stability', unit: 'volts'),
          MudPropertyItem(name: 'Water Activity', unit: 'aw'),
        ];
      case 'NaCl + CaCl2':
        return [
          MudPropertyItem(name: 'Salt Content Water Phase (%)', unit: '% wt'),
          MudPropertyItem(name: 'WPS', unit: 'ppm'),
          MudPropertyItem(name: 'Whole Mud Ca (CaOM)', unit: 'mg/L'),
          MudPropertyItem(name: 'CaCl2 Wt. (%)', unit: '% wt'),
          MudPropertyItem(name: 'CaCl2', unit: 'mg/L'),
          MudPropertyItem(name: 'NaCl Wt. (%)', unit: '% wt'),
          MudPropertyItem(name: 'NaCl', unit: 'mg/L'),
          MudPropertyItem(name: 'Insoluble NaCl (mg/L)', unit: 'mg/L'),
          MudPropertyItem(name: 'Brine Density', unit: 'ppg'),
          MudPropertyItem(name: 'Brine Content (%)', unit: '%'),
          MudPropertyItem(name: 'Electrical Stability', unit: 'volts'),
          MudPropertyItem(name: 'Water Activity', unit: 'aw'),
        ];
      case 'Sodium Formate':
        return [
          MudPropertyItem(
            name: 'Brine Phase Chlorides Salinity',
            unit: 'mg/L',
          ),
          MudPropertyItem(name: 'Salt Content Water Phase (%)', unit: '%'),
          MudPropertyItem(name: 'WPS', unit: 'ppm'),
          MudPropertyItem(name: 'Sodium Formate Wt. (%)', unit: '% wt'),
          MudPropertyItem(name: 'Sodium Formate', unit: 'mg/L'),
          MudPropertyItem(name: 'Brine Density', unit: 'ppg'),
        ];
      case 'CaCl2':
      default:
        return [
          MudPropertyItem(name: 'Salt Content Water Phase (%)', unit: '% wt'),
          MudPropertyItem(name: 'WPS', unit: 'ppm'),
          MudPropertyItem(name: 'CaCl2 Wt. (%)', unit: '% wt'),
          MudPropertyItem(name: 'CaCl2', unit: 'mg/L'),
          MudPropertyItem(name: 'Brine Density', unit: 'ppg'),
          MudPropertyItem(name: 'Brine Content (%)', unit: '%'),
          MudPropertyItem(name: 'Electrical Stability', unit: 'volts'),
          MudPropertyItem(name: 'Water Activity', unit: 'aw'),
        ];
    }
  }

  MudPropertyItem _canonicalWaterBasedProperty(String name, {String? unit}) {
    final key = _normalizeLabel(name);
    MudPropertyItem? row;
    for (final item in _legacyWaterBasedRows) {
      if (_matchesWaterBasedRow(key, item.name)) {
        row = item;
        break;
      }
    }
    final dynamicUnit = (unit ?? '').trim();
    if (row == null) {
      return MudPropertyItem(name: name, unit: dynamicUnit);
    }
    return MudPropertyItem(
      name: row.name,
      unit: dynamicUnit.isNotEmpty ? dynamicUnit : row.unit,
    );
  }

  bool _matchesWaterBasedRow(String key, String rowName) {
    final row = _normalizeLabel(rowName);
    if (key == row) return true;
    if (row == 't. for pv' &&
        (key.contains('rheology temp') ||
            key.contains('temp for pv') ||
            key.contains('temperature for pv'))) {
      return true;
    }
    if (row == 't. for hthp' &&
        (key.contains('hthp temp') ||
            key.contains('temp for hthp') ||
            key.contains('temperature for hthp'))) {
      return true;
    }
    if (row == 'gel str. 10s' && key.contains('gel') && key.contains('10s'))
      return true;
    if (row == 'gel str. 10m' && key.contains('gel') && key.contains('10m'))
      return true;
    if (row == 'gel str. 30m' && key.contains('gel') && key.contains('30m'))
      return true;
    if (row == 'solids' &&
        (key == 'solids' ||
            key == '*solids' ||
            key == 'solids (%)' ||
            key.contains('solids %'))) {
      return true;
    }
    if (row.startsWith('mud alkalinity') &&
        (key.contains('mud alkalinity') ||
            key.contains('alkalinity (pm)') ||
            key.contains('alkalinity (pom)'))) {
      return true;
    }
    if (row == 'k+' && (key == 'k' || key == 'k+' || key.startsWith('k+ ')))
      return true;
    if (row == 'make up water: chlorides' &&
        key.contains('make') &&
        key.contains('chloride'))
      return true;
    if (row == 'solids adjusted for salt' && key.contains('solids adjusted'))
      return true;
    if (row == 'chlorides' &&
        key.contains('chloride') &&
        !key.contains('make') &&
        !key.contains('calcium'))
      return true;
    return false;
  }

  bool _shouldKeepExtraWaterBasedRow(String name) {
    final key = _normalizeLabel(name);
    final oilOnlyRows = [
      'r600',
      'r300',
      'r200',
      'r100',
      'r6',
      'r3',
      'corrected solids',
      'oil/water ratio',
      'whole mud alkalinity',
      'whole mud alkalinity (pom)',
      'electrical stability',
      'whole mud chlorides',
      'cacl2 concentration',
      'cacl2',
      'water phase salinity',
      'water phase salinity (wps)',
      'brine density',
      'water activity',
      'salt content water phase',
      'wps',
      'nacl2 wt.',
      'nacl2',
    ];
    if (oilOnlyRows.any((row) => key == row || key.startsWith('$row '))) {
      return false;
    }
    if (key.contains('oil/water ratio') ||
        key.contains('water phase salinity')) {
      return false;
    }
    return true;
  }

  bool _isLegacyWaterBasedRow(String name) =>
      _legacyWaterBasedRows.any((row) => row.name == name);

  String _normalizeLabel(String value) => value
      .toLowerCase()
      .replaceAll('*', '')
      .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _saltTypeFormulaKey([String? value]) {
    return (value ?? selectedSaltType.value)
        .toLowerCase()
        .replaceAll('₂', '2')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  bool _isPureCacl2SaltType([String? value]) {
    final key = _saltTypeFormulaKey(value);
    return key == 'cacl2' || key == 'calciumchloride';
  }

  bool _isNaclSaltType([String? value]) {
    final key = _saltTypeFormulaKey(value);
    return key == 'nacl' || key == 'sodiumchloride';
  }

  bool _isMixedSaltType([String? value]) {
    final key = _saltTypeFormulaKey(value);
    return key == 'naclcacl2' ||
        key == 'cacl2nacl' ||
        key == 'sodiumchloridecalciumchloride' ||
        key == 'calciumchloridesodiumchloride';
  }

  bool _isSodiumFormateSaltType([String? value]) {
    final key = _saltTypeFormulaKey(value);
    return key == 'sodiumformate';
  }

  String get _wellId => currentBackendWellId.trim();
  String get _reportId => reportContext.selectedReportId.value.trim();
  String get _effectiveReportId {
    return _effectiveReportIdForScope(_stateScopeKey.value);
  }

  String _effectiveReportIdForScope(String scopeKey) {
    final normalizedScope = scopeKey.trim();
    if (normalizedScope.isEmpty) return _reportId;
    final base = _reportId.isEmpty ? 'well' : _reportId;
    return '$base::$normalizedScope';
  }

  String get _mudStateCacheKey {
    return _mudStateCacheKeyForReportId(_effectiveReportId);
  }

  String _mudStateCacheKeyForReportId(String reportId) {
    final well = _wellId.isEmpty ? 'well' : _wellId;
    final report = reportId.trim().isEmpty ? 'default' : reportId.trim();
    return '$well::$report';
  }

  Uri _mudReportUri({String? reportIdOverride}) {
    final base = Uri.parse('${_kBaseUrl}mud-report/$_wellId');
    final reportId = (reportIdOverride ?? _effectiveReportId).trim();
    return reportId.isEmpty
        ? base
        : base.replace(queryParameters: {'reportId': reportId});
  }

  Future<void> useMudStateScope(String scopeKey) async {
    final normalized = scopeKey.trim();
    if (_stateScopeKey.value == normalized) return;
    _cacheCurrentMudState();
    if (!_isApplyingSavedState && _wellId.isNotEmpty) {
      await saveMudReportState(force: true);
    }
    _isApplyingSavedState = true;
    _resetMudStateDefaults();
    _stateScopeKey.value = normalized;
    _isApplyingSavedState = false;
    await loadFluidTypeData(applySavedState: true);
  }

  void _resetMudStateDefaults() {
    selectedFluidType.value = 'Water-based';
    rheologyModel.value = 'Bingham';
    rheologyCalculation.value = 'API (RP 13D)';
    isCompletionFluid.value = false;
    isWeightedMud.value = false;
    selectedSaltType.value = 'CaCl2';
    sampleForCalculation.value = '1';
    fluidnameController.clear();
    _clearMudBottomSections();
    solidAnalysisResult.clear();
    _initRheologyTable();
  }

  void markNewReportMudStateClean(String reportId) {
    final normalized = reportId.trim();
    if (normalized.isEmpty) return;
    _cleanNewReportIds.add(normalized);
    _stateCache.remove(_mudStateCacheKeyForReportId(normalized));
  }

  void markNextReportMudStateClean() {
    _cleanNextReportLoad = true;
  }

  void cancelNextReportMudStateClean() {
    _cleanNextReportLoad = false;
  }

  void _clearMudBottomSections() {
    oilSgController.clear();
    hgsSgController.clear();
    lgsSgController.clear();
    shaleCecController.clear();
    bentCecController.clear();
  }

  void _cacheCurrentMudState() {
    if (_isApplyingSavedState) return;
    _stateCache[_mudStateCacheKey] = _buildMudReportPayload();
  }

  Future<Map<String, dynamic>?> _fetchMudReportState({
    String? reportIdOverride,
  }) async {
    if (_wellId.isEmpty) return null;
    try {
      final response = await http.get(
        _mudReportUri(reportIdOverride: reportIdOverride),
        headers: ApiEndpoint.jsonHeaders,
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('[MudController] mud report load error: $e');
    }
    return null;
  }

  void _applyMudPropertyState(Map<String, dynamic> data) {
    final units = _mapFromDynamic(data['propertyUnits']);
    units.forEach((key, value) {
      final targetKey = selectedFluidType.value == 'Water-based'
          ? _canonicalWaterBasedProperty(key, unit: value.toString()).name
          : key;
      if ((selectedFluidType.value == 'Oil-based' ||
              selectedFluidType.value == 'Synthetic') &&
          _isOilSaltManagedRow(targetKey) &&
          !propertyTable.containsKey(targetKey)) {
        return;
      }
      final unitValue = value.toString();
      if (unitValue.trim().isNotEmpty) {
        propertyUnits[targetKey] = unitValue;
      }
    });

    final savedProperties = _mapFromDynamic(data['propertyTable']);
    savedProperties.forEach((key, value) {
      final targetKey = selectedFluidType.value == 'Water-based'
          ? _canonicalWaterBasedProperty(key).name
          : key;
      if (selectedFluidType.value == 'Water-based' &&
          !_isLegacyWaterBasedRow(targetKey) &&
          !_shouldKeepExtraWaterBasedRow(key)) {
        return;
      }
      if ((selectedFluidType.value == 'Oil-based' ||
              selectedFluidType.value == 'Synthetic') &&
          _isOilSaltManagedRow(targetKey) &&
          !propertyTable.containsKey(targetKey)) {
        return;
      }
      propertyTable.putIfAbsent(
        targetKey,
        () => List.generate(samples.length, (_) => ''.obs),
      );
      final values = _listFromDynamic(value);
      final row = propertyTable[targetKey]!;
      for (int i = 0; i < row.length && i < values.length; i++) {
        row[i].value = values[i];
      }
    });
  }

  void _applyMudReportState(Map<String, dynamic> data) {
    fluidnameController.text = (data['fluidName'] ?? '').toString();
    isCompletionFluid.value = data['isCompletionFluid'] == true;
    isWeightedMud.value = data['isWeightedMud'] == true;
    final savedSaltType = (data['saltType'] ?? '').toString().trim();
    if (savedSaltType.isNotEmpty) selectedSaltType.value = savedSaltType;

    final savedModel = (data['rheologyModel'] ?? '').toString().trim();
    if (savedModel.isNotEmpty) rheologyModel.value = savedModel;
    final savedCalculation = (data['rheologyCalculation'] ?? '')
        .toString()
        .trim();
    if (savedCalculation.isNotEmpty) {
      rheologyCalculation.value = savedCalculation;
    }
    final savedSample = (data['sampleForCalculation'] ?? '').toString().trim();
    if (savedSample.isNotEmpty) sampleForCalculation.value = savedSample;

    oilSgController.text = (data['oilSg'] ?? '').toString();
    hgsSgController.text = (data['hgsSg'] ?? '').toString();
    lgsSgController.text = (data['lgsSg'] ?? '').toString();
    shaleCecController.text = (data['shaleCec'] ?? '').toString();
    bentCecController.text = (data['bentCec'] ?? '').toString();

    _applyMudPropertyState(data);

    final savedRheology = _mapFromDynamic(data['rheologyTable']);
    if (savedRheology.isNotEmpty) {
      rheologyTable.clear();
      final canonicalRows = _rheologyRowsForModel(rheologyModel.value);
      final orderedKeys = <String>[
        ...canonicalRows,
        ...savedRheology.keys
            .map((key) => key.toString())
            .where((key) => !canonicalRows.contains(key)),
      ];
      for (final key in orderedKeys) {
        final value = savedRheology[key];
        final values = _listFromDynamic(value);
        rheologyTable[key] = List.generate(
          samples.length,
          (index) => (index < values.length ? values[index] : '').obs,
        );
      }
    }
  }

  Map<String, dynamic> _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<String> _listFromDynamic(dynamic value) {
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').toList();
    }
    return <String>[];
  }

  Map<String, Map<int, String>> _captureSampleValues(
    Map<String, List<RxString>> table,
    List<int> indices,
  ) {
    final snapshot = <String, Map<int, String>>{};
    for (final entry in table.entries) {
      final rowSnapshot = <int, String>{};
      for (final index in indices) {
        if (index >= 0 && index < entry.value.length) {
          rowSnapshot[index] = entry.value[index].value;
        }
      }
      if (rowSnapshot.isNotEmpty) {
        snapshot[entry.key] = rowSnapshot;
      }
    }
    return snapshot;
  }

  void _restoreSampleValues(
    Map<String, List<RxString>> table,
    Map<String, Map<int, String>> snapshot,
  ) {
    snapshot.forEach((rowKey, valuesByIndex) {
      final row = table[rowKey];
      if (row == null) return;
      valuesByIndex.forEach((index, value) {
        if (index >= 0 && index < row.length) {
          row[index].value = value;
        }
      });
    });
  }

  Map<String, List<String>> _stringTable(Map<String, List<RxString>> table) {
    return table.map(
      (key, value) => MapEntry(
        key,
        value.map((cell) => cell.value).toList(growable: false),
      ),
    );
  }

  Map<String, dynamic> _buildMudReportPayload() => {
    'wellId': _wellId,
    if (_effectiveReportId.isNotEmpty) 'reportId': _effectiveReportId,
    'fluidName': fluidnameController.text.trim(),
    'fluidType': selectedFluidType.value,
    'isCompletionFluid': isCompletionFluid.value,
    'isWeightedMud': _effectiveWeightedMudForSolids(),
    'saltType': selectedSaltType.value,
    'samples': samples,
    'propertyTable': _stringTable(propertyTable),
    'propertyUnits': Map<String, String>.from(propertyUnits),
    'rheologyModel': rheologyModel.value,
    'rheologyCalculation': rheologyCalculation.value,
    'rheologyTable': _stringTable(rheologyTable),
    'sampleForCalculation': sampleForCalculation.value,
    'oilSg': oilSgController.text.trim(),
    'hgsSg': hgsSgController.text.trim(),
    'lgsSg': lgsSgController.text.trim(),
    'shaleCec': shaleCecController.text.trim(),
    'bentCec': bentCecController.text.trim(),
  };

  void _scheduleMudReportSave() {
    if (_isApplyingSavedState || _wellId.isEmpty) return;
    _cacheCurrentMudState();
    final reportId = _effectiveReportId;
    final payload = _buildMudReportPayload();
    _mudStateSaveTimer?.cancel();
    _mudStateSaveTimer = Timer(
      _kSaveDebounce,
      () => _saveMudReportPayload(reportId: reportId, payload: payload),
    );
  }

  Future<void> saveMudReportState({bool force = false}) async {
    if (_wellId.isEmpty) return;
    if (!force && _isApplyingSavedState) return;
    _mudStateSaveTimer?.cancel();
    _cacheCurrentMudState();
    await _saveMudReportPayload(
      reportId: _effectiveReportId,
      payload: _buildMudReportPayload(),
    );
  }

  Future<void> _saveMudReportPayload({
    required String reportId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await http.put(
        _mudReportUri(reportIdOverride: reportId),
        headers: ApiEndpoint.jsonHeaders,
        body: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('[MudController] mud report save error: $e');
    }
  }

  void _setupMudStateWatchers() {
    for (final worker in _stateWorkers) {
      worker.dispose();
    }
    _stateWorkers.clear();

    void watch(RxInterface rx) {
      _stateWorkers.add(ever(rx, (_) => _scheduleMudReportSave()));
    }

    watch(selectedFluidType);
    watch(rheologyModel);
    watch(rheologyCalculation);
    watch(isCompletionFluid);
    watch(isWeightedMud);
    watch(selectedSaltType);
    watch(sampleForCalculation);
    for (final row in propertyTable.values) {
      for (final cell in row) {
        watch(cell);
      }
    }
    for (final row in rheologyTable.values) {
      for (final cell in row) {
        watch(cell);
      }
    }
  }

  void _attachTextControllerListeners() {
    for (final controller in [
      fluidnameController,
      oilSgController,
      hgsSgController,
      lgsSgController,
      shaleCecController,
      bentCecController,
    ]) {
      controller.addListener(_scheduleMudReportSave);
    }
    for (final controller in [
      oilSgController,
      hgsSgController,
      lgsSgController,
      shaleCecController,
      bentCecController,
    ]) {
      controller.addListener(_scheduleAllSolidAnalysisSamples);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTO CALCULATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupAutoCalculations() {
    debugPrint('[AutoCalc] keys: ${propertyTable.keys.toList()}');
    debugPrint(
      '[AutoCalc] _solidsKey=$_solidsKey (retort INPUT - NOT auto-calc target)',
    );
    debugPrint(
      '[AutoCalc] _totalSolidsKey=$_totalSolidsKey (auto-calc OUTPUT)',
    );
    debugPrint(
      '[AutoCalc] _wpsSaltPercentKey=$_wpsSaltPercentKey _wpsSaltPpmKey=$_wpsSaltPpmKey',
    );
    debugPrint(
      '[AutoCalc] _cacl2PctWtKey=$_cacl2PctWtKey _cacl2ConcKey=$_cacl2ConcKey',
    );

    for (int i = 0; i < samples.length; i++) {
      // ── 1. PV = R600 − R300 ───────────────────────────────────────────────
      _watchTwoOpt(i, _r600Key, _r300Key, _pvPropKey, (a, b) {
        final r600 = double.tryParse(a) ?? 0;
        final r300 = double.tryParse(b) ?? 0;
        if (r600 == 0 && r300 == 0) return '';
        return _formatMudPropertyValue(
          _pvPropKey,
          r600 - r300,
          fallbackDigits: 1,
        );
      });

      // ── 2. YP = R300 − PV ─────────────────────────────────────────────────
      _watchTwoOpt(i, _r300Key, _pvPropKey, _ypPropKey, (a, b) {
        final r300 = double.tryParse(a) ?? 0;
        final pv = double.tryParse(b) ?? 0;
        if (r300 == 0 && pv == 0) return '';
        return _formatMudPropertyValue(
          _ypPropKey,
          r300 - pv,
          fallbackDigits: 1,
        );
      });

      // ── 3. LSRYP = 2×R3 − R6 ─────────────────────────────────────────────
      _watchTwoOpt(i, _r3Key, _r6Key, _lsrypKey, (a, b) {
        final r3 = double.tryParse(a) ?? 0;
        final r6 = double.tryParse(b) ?? 0;
        if (r3 == 0 && r6 == 0) return '';
        return _formatMudPropertyValue(
          _lsrypKey,
          2 * r3 - r6,
          fallbackDigits: 1,
        );
      });

      // ── 4. Oil/Water Ratio ────────────────────────────────────────────────
      final owTarget = _owRatioKey ?? 'Oil/water Ratio';
      _watchTwoOpt(i, _oilKey, _waterKey, owTarget, (a, b) {
        final oil = double.tryParse(a) ?? 0;
        final water = double.tryParse(b) ?? 0;
        final isOilMud =
            selectedFluidType.value == 'Oil-based' ||
            selectedFluidType.value == 'Synthetic';
        if (oil == 0 && water == 0) return '';
        final total = oil + water;
        if (total == 0) return '';
        final rawOilPct = isOilMud && oil == 0
            ? (water > 50 ? water : 100 - water)
            : 100 * oil / total;
        final oilPct = isOilMud && !_isSodiumFormateSaltType()
            ? ((rawOilPct / 5).round() * 5).clamp(0, 100).toInt()
            : rawOilPct.round().clamp(0, 100).toInt();
        final waterPct = 100 - oilPct;
        return '$oilPct/$waterPct';
      });

      // ── 5. Solids (% vol) = 100 - (Oil% + Water%) ────────────────────────
      void calcSolids(String a, String b, String targetKey) {
        final oil = double.tryParse(a) ?? 0;
        final water = double.tryParse(b) ?? 0;
        if (oil == 0 && water == 0) {
          propertyTable[targetKey]?[i].value = '';
          return;
        }
        final solids = 100 - (oil + water);
        propertyTable[targetKey]?[i].value = solids < 100
            ? _formatMudPropertyValue(targetKey, solids, fallbackDigits: 2)
            : '';
      }

      final solidsTarget = _solidsKey;
      if (solidsTarget != null && _oilKey != null && _waterKey != null) {
        final oilL = propertyTable[_oilKey!];
        final watL = propertyTable[_waterKey!];
        final solL = propertyTable[solidsTarget];
        if (oilL != null &&
            watL != null &&
            solL != null &&
            i < oilL.length &&
            i < watL.length &&
            i < solL.length) {
          calcSolids(oilL[i].value, watL[i].value, solidsTarget);
          ever(
            oilL[i],
            (_) => calcSolids(oilL[i].value, watL[i].value, solidsTarget),
          );
          ever(
            watL[i],
            (_) => calcSolids(oilL[i].value, watL[i].value, solidsTarget),
          );
        }
      }

      // Also write to "Total Solids" named row if it exists and is different
      final tsTarget = _totalSolidsKey;
      if (tsTarget != null &&
          tsTarget != _solidsKey &&
          _oilKey != null &&
          _waterKey != null) {
        final oilL = propertyTable[_oilKey!];
        final watL = propertyTable[_waterKey!];
        final tsL = propertyTable[tsTarget];
        if (oilL != null &&
            watL != null &&
            tsL != null &&
            i < oilL.length &&
            i < watL.length &&
            i < tsL.length) {
          calcSolids(oilL[i].value, watL[i].value, tsTarget);
          ever(
            oilL[i],
            (_) => calcSolids(oilL[i].value, watL[i].value, tsTarget),
          );
          ever(
            watL[i],
            (_) => calcSolids(oilL[i].value, watL[i].value, tsTarget),
          );
        }
      }

      // ── 6. Solids Adjusted for Salt = Retort Solids% - Dissolved Solids% ──
      final csTarget = _correctedSolidsKey;
      if (csTarget != null && (_solidsKey != null || _waterKey != null)) {
        void recalcCorrectedSolids() {
          final tgt = propertyTable[csTarget];
          if (tgt == null || i >= tgt.length) return;

          final solidsVals = _solidsKey != null
              ? propertyTable[_solidsKey!]
              : null;
          final retortSolids = (solidsVals != null && i < solidsVals.length)
              ? _parseMudNumber(solidsVals[i].value)
              : 0.0;
          final waterVals = _waterKey != null
              ? propertyTable[_waterKey!]
              : null;
          final water = (waterVals != null && i < waterVals.length)
              ? _parseMudNumber(waterVals[i].value)
              : 0.0;
          final chlorideVals = _chloridesForSolidsKey != null
              ? propertyTable[_chloridesForSolidsKey!]
              : null;
          final chlorides = (chlorideVals != null && i < chlorideVals.length)
              ? _parseMudNumber(chlorideVals[i].value)
              : 0.0;
          final makeupChlorideVals = _makeupWaterChloridesKey != null
              ? propertyTable[_makeupWaterChloridesKey!]
              : null;
          final makeupChlorides =
              (makeupChlorideVals != null && i < makeupChlorideVals.length)
              ? _parseMudNumber(makeupChlorideVals[i].value)
              : 0.0;

          final isOilMud =
              selectedFluidType.value == 'Oil-based' ||
              selectedFluidType.value == 'Synthetic';
          final cacl2Vals = _cacl2PctWtKey != null
              ? propertyTable[_cacl2PctWtKey!]
              : null;
          final cacl2Pct = (cacl2Vals != null && i < cacl2Vals.length)
              ? (double.tryParse(cacl2Vals[i].value) ?? 0.0)
              : 0.0;
          final naclVals = _naclPctWtKey != null
              ? propertyTable[_naclPctWtKey!]
              : null;
          final naclPct = (naclVals != null && i < naclVals.length)
              ? (double.tryParse(naclVals[i].value) ?? 0.0)
              : 0.0;
          final wpsVals = _wpsSaltPercentKey != null
              ? propertyTable[_wpsSaltPercentKey!]
              : null;
          final wpsPpm = (wpsVals != null && i < wpsVals.length)
              ? (double.tryParse(wpsVals[i].value) ?? 0.0)
              : 0.0;
          final calciumVals = _wholeMudCaKey != null
              ? propertyTable[_wholeMudCaKey!]
              : null;
          final calcium = (calciumVals != null && i < calciumVals.length)
              ? (double.tryParse(calciumVals[i].value) ?? 0.0)
              : 0.0;
          final sodiumFormateVals = _dissolvedSodiumFormateKey != null
              ? propertyTable[_dissolvedSodiumFormateKey!]
              : null;
          final dissolvedSodiumFormate =
              (sodiumFormateVals != null && i < sodiumFormateVals.length)
              ? (double.tryParse(sodiumFormateVals[i].value) ?? 0.0)
              : 0.0;

          if (retortSolids == 0 &&
              water == 0 &&
              chlorides == 0 &&
              cacl2Pct == 0 &&
              naclPct == 0 &&
              wpsPpm == 0 &&
              dissolvedSodiumFormate == 0) {
            tgt[i].value = '';
          } else {
            double dissolvedSolids;
            if (isOilMud && _isPureCacl2SaltType()) {
              dissolvedSolids = water * chlorides * 0.0000012;
            } else if (isOilMud) {
              final pmVals = _wholeMudAlkKey != null
                  ? propertyTable[_wholeMudAlkKey!]
                  : null;
              final pm = (pmVals != null && i < pmVals.length)
                  ? (double.tryParse(pmVals[i].value) ?? 0.0)
                  : 0.0;
              final saltWater = _isSodiumFormateSaltType()
                  ? water
                  : _oilSaltWaterBasisForSample(i, water);
              final oilSalt = _oilSaltResult(
                chloridesMgl: chlorides,
                calciumMgl: calcium,
                waterVol: saltWater,
                retortSolids: retortSolids,
                cacl2Pct: cacl2Pct,
                naclPct: naclPct,
                wpsPpm: wpsPpm,
                pm: pm,
              );
              dissolvedSolids = oilSalt?.dissolvedSolidsPct ?? 0.0;
            } else {
              final chlorideBasis = math.max(0.0, chlorides - makeupChlorides);
              dissolvedSolids = water * chlorideBasis * 0.0000012;
            }
            final solidsAdjusted = retortSolids - dissolvedSolids;
            tgt[i].value = _formatMudPropertyValue(
              csTarget,
              solidsAdjusted < 0 ? 0.0 : solidsAdjusted,
              fallbackDigits: 1,
            );
          }
        }

        recalcCorrectedSolids();
        if (_solidsKey != null) {
          final solidsList = propertyTable[_solidsKey!];
          if (solidsList != null && i < solidsList.length) {
            ever(solidsList[i], (_) => recalcCorrectedSolids());
          }
        }
        if (_waterKey != null) {
          final waterList = propertyTable[_waterKey!];
          if (waterList != null && i < waterList.length) {
            ever(waterList[i], (_) => recalcCorrectedSolids());
          }
        }
        if (_oilKey != null) {
          final oilList = propertyTable[_oilKey!];
          if (oilList != null && i < oilList.length) {
            ever(oilList[i], (_) => recalcCorrectedSolids());
          }
        }
        if (_chloridesForSolidsKey != null) {
          final chlorideList = propertyTable[_chloridesForSolidsKey!];
          if (chlorideList != null && i < chlorideList.length) {
            ever(chlorideList[i], (_) => recalcCorrectedSolids());
          }
        }
        if (_makeupWaterChloridesKey != null) {
          final makeupChlorideList = propertyTable[_makeupWaterChloridesKey!];
          if (makeupChlorideList != null && i < makeupChlorideList.length) {
            ever(makeupChlorideList[i], (_) => recalcCorrectedSolids());
          }
        }
        if (_cacl2PctWtKey != null) {
          final cacl2List = propertyTable[_cacl2PctWtKey!];
          if (cacl2List != null && i < cacl2List.length) {
            ever(cacl2List[i], (_) => recalcCorrectedSolids());
          }
        }
        if (_naclPctWtKey != null) {
          final naclList = propertyTable[_naclPctWtKey!];
          if (naclList != null && i < naclList.length) {
            ever(naclList[i], (_) => recalcCorrectedSolids());
          }
        }
        if (_wpsSaltPercentKey != null) {
          final wpsList = propertyTable[_wpsSaltPercentKey!];
          if (wpsList != null && i < wpsList.length) {
            ever(wpsList[i], (_) => recalcCorrectedSolids());
          }
        }
        if (_dissolvedSodiumFormateKey != null) {
          final formateList = propertyTable[_dissolvedSodiumFormateKey!];
          if (formateList != null && i < formateList.length) {
            ever(formateList[i], (_) => recalcCorrectedSolids());
          }
        }
      }

      // ── 7. Excess Lime from mud alkalinity (legacy WBM behavior) ───────
      final elTarget = _excessLimeKey;
      final pmKey = _wholeMudAlkKey;
      if (elTarget != null && pmKey != null) {
        final pmList = pmKey != null ? propertyTable[pmKey] : null;
        final exactPmList = _mudAlkalinityPmKey != null
            ? propertyTable[_mudAlkalinityPmKey!]
            : null;
        final pfList = _filtAlkPfKey != null
            ? propertyTable[_filtAlkPfKey!]
            : null;
        final waterList = _waterKey != null ? propertyTable[_waterKey!] : null;
        final elList = propertyTable[elTarget];
        if (elList != null && i < elList.length) {
          double valueAt(List<RxString>? list) {
            if (list == null || i >= list.length) return 0.0;
            return double.tryParse(list[i].value) ?? 0.0;
          }

          void recalcExcessLime() {
            final pm = valueAt(pmList);
            if (pm == 0) {
              elList[i].value = '';
              return;
            }
            final isOilMud =
                selectedFluidType.value == 'Oil-based' ||
                selectedFluidType.value == 'Synthetic';
            final saltType = selectedSaltType.value;
            final mixedOrNacl =
                _isNaclSaltType(saltType) || _isMixedSaltType(saltType);
            final sodiumFormate = _isSodiumFormateSaltType(saltType);
            final pureCacl2Oil = isOilMud && _isPureCacl2SaltType(saltType);
            final exactPm = valueAt(exactPmList);
            final pf = valueAt(pfList);
            final pureNaclOil = isOilMud && _isNaclSaltType(saltType);
            final mixedOil = isOilMud && _isMixedSaltType(saltType);
            final rawExcessLime = pureCacl2Oil || pureNaclOil || mixedOil
                ? (exactPm > 0 && pf > 0
                      ? 0.26 * (exactPm - ((valueAt(waterList) / 100) * pf))
                      : pm * _pureCacl2OilExcessLimeFactor)
                : isOilMud
                ? pm * (mixedOrNacl || sodiumFormate ? 1.299 : 1.295)
                : 0.26 * (pm - ((valueAt(waterList) / 100) * valueAt(pfList)));
            final excessLime = rawExcessLime < 0 ? 0.0 : rawExcessLime;
            elList[i].value = _formatMudPropertyValue(
              elTarget,
              excessLime,
              fallbackDigits: isOilMud && !pureNaclOil && !mixedOil && (mixedOrNacl || sodiumFormate)
                  ? 1
                  : 2,
            );
          }

          recalcExcessLime();
          if (pmList != null && i < pmList.length) {
            ever(pmList[i], (_) => recalcExcessLime());
          }
          if (exactPmList != null && i < exactPmList.length) {
            ever(exactPmList[i], (_) => recalcExcessLime());
          }
          if (pfList != null && i < pfList.length) {
            ever(pfList[i], (_) => recalcExcessLime());
          }
          if (waterList != null && i < waterList.length) {
            ever(waterList[i], (_) => recalcExcessLime());
          }
        }
      }

      // ── 8. CaCl2 Concentration (mg/l) = 1.565 × Whole Mud Chlorides ───────
      final cacl2ConcTarget = _cacl2ConcKey;
      if (cacl2ConcTarget != null) {
        final isOilMud =
            selectedFluidType.value == 'Oil-based' ||
            selectedFluidType.value == 'Synthetic';
        if (isOilMud &&
            _isMixedSaltType() &&
            _wholeMudCaKey != null) {
          _watchOneOpt(i, _wholeMudCaKey, cacl2ConcTarget, (a) {
            final calcium = double.tryParse(a) ?? 0;
            return calcium == 0
                ? ''
                : _formatMudPropertyValue(
                    cacl2ConcTarget,
                    _cacl2MgFromCalcium(calcium),
                    fallbackDigits: 0,
                  );
          });
        } else if (isOilMud &&
            !_isNaclSaltType() &&
            _cacl2PctWtKey != null) {
          _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, cacl2ConcTarget, (
            a,
            b,
          ) {
            final chlorides = double.tryParse(a) ?? 0;
            final water = _pureCacl2WaterBasisForSample(
              i,
              double.tryParse(b) ?? 0,
            );
            if (chlorides == 0 || water == 0) return '';
            final frac =
                _pureCacl2ChlorideConversionFactor * chlorides / 10000;
            final cacl2Wt = 100 * frac / (frac + water);
            final brineSG = _cacl2BrineSg(cacl2Wt);
            return _formatMudPropertyValue(
              cacl2ConcTarget,
              cacl2Wt * 10000 * brineSG,
              fallbackDigits: 0,
            );
          });
        } else {
          _watchOneOpt(i, _wholeMudChlorideKey, cacl2ConcTarget, (a) {
            final v = double.tryParse(a) ?? 0;
            return v == 0
                ? ''
                : _formatMudPropertyValue(
                    cacl2ConcTarget,
                    v * 1.565,
                    fallbackDigits: 2,
                  );
          });
        }
      }

      // ── 9. CaCl2 (% wt) = 100*(1.565*WMChl/10000)/((1.565*WMChl/10000)+Water%)
      final cacl2WtTarget = _cacl2PctWtKey;
      if (cacl2WtTarget != null &&
          _isMixedSaltType() &&
          _wholeMudCaKey != null &&
          _waterKey != null) {
        _watchTwoOpt(i, _wholeMudCaKey, _waterKey, cacl2WtTarget, (a, b) {
          final calcium = double.tryParse(a) ?? 0;
          final rawWater = double.tryParse(b) ?? 0;
          final water = (_isNaclSaltType() || _isMixedSaltType())
              ? _oilSaltWaterBasisForSample(i, rawWater)
              : _pureCacl2WaterBasisForSample(i, rawWater);
          if (calcium == 0 || water == 0) return '';
          final cacl2Mg = _cacl2MgFromCalcium(calcium);
          final naclMg = _naclMgForMixedSalt(i);
          final denominator = cacl2Mg + naclMg + (10000 * water);
          if (denominator <= 0) return '';
          return _formatMudPropertyValue(
            cacl2WtTarget,
            100 * cacl2Mg / denominator,
            fallbackDigits: 1,
          );
        });
      } else if (cacl2WtTarget != null && !_isNaclSaltType()) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, cacl2WtTarget, (a, b) {
          final chlorides = double.tryParse(a) ?? 0;
          final rawWater = double.tryParse(b) ?? 0;
          final water = (_isNaclSaltType() || _isMixedSaltType())
              ? _oilSaltWaterBasisForSample(i, rawWater)
              : _pureCacl2WaterBasisForSample(i, rawWater);
          if (chlorides == 0) return '';
          final factor = _isNaclSaltType()
              ? 1.648
              : _isPureCacl2SaltType()
              ? _pureCacl2ChlorideConversionFactor
              : _cacl2ChlorideConversionFactor;
          final frac = factor * chlorides / 10000;
          if (frac + water == 0) return '';
          return _formatMudPropertyValue(
            cacl2WtTarget,
            100 * frac / (frac + water),
            fallbackDigits: 1,
          );
        });
      }

      // ── 10. Water Phase Salinity ppm = CaCl2(% wt) × 10000 ───────────────
      //    FIX: _wpsSaltPercentKey now matches ANY "water phase salinity" row
      //    (field name is "Water phase Salinity (WPS)" — no 'ppm' in it)
      final saltContentTarget = _saltContentWaterPhaseKey;
      if (saltContentTarget != null &&
          !_isSodiumFormateSaltType()) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, saltContentTarget, (
          a,
          b,
        ) {
          final chlorides = double.tryParse(a) ?? 0;
          final rawWater = double.tryParse(b) ?? 0;
          final water = (_isNaclSaltType() || _isMixedSaltType())
              ? _oilSaltWaterBasisForSample(i, rawWater)
              : _pureCacl2WaterBasisForSample(i, rawWater);
          if (chlorides == 0 || water == 0) return '';
          final factor = _isNaclSaltType()
              ? 1.648
              : _isPureCacl2SaltType()
              ? _pureCacl2ChlorideConversionFactor
              : _cacl2ChlorideConversionFactor;
          final frac = factor * chlorides / 10000;
          if (frac + water == 0) return '';
          return _formatMudPropertyValue(
            saltContentTarget,
            100 * frac / (frac + water),
            fallbackDigits: 1,
          );
        });
      }

      final naclWtTarget = _naclPctWtKey;
      if (naclWtTarget != null && _isMixedSaltType()) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, naclWtTarget, (a, b) {
          final water = _oilSaltWaterBasisForSample(
            i,
            double.tryParse(b) ?? 0,
          );
          if (water == 0) return '';
          final naclMg = _naclMgForMixedSalt(i);
          if (naclMg == 0) return '';
          final calciumVals = _wholeMudCaKey != null
              ? propertyTable[_wholeMudCaKey!]
              : null;
          final calcium = calciumVals != null && i < calciumVals.length
              ? double.tryParse(calciumVals[i].value) ?? 0
              : 0.0;
          final cacl2Mg = _cacl2MgFromCalcium(calcium);
          final denominator = cacl2Mg + naclMg + (10000 * water);
          if (denominator <= 0) return '';
          final cacl2Wt = 100 * cacl2Mg / denominator;
          final naclWt = 100 * naclMg / denominator;
          final maxNacl = _maxSolubleNaclWt(cacl2Wt);
          return _formatMudPropertyValue(
            naclWtTarget,
            naclWt > maxNacl ? maxNacl : naclWt,
            fallbackDigits: 1,
          );
        });
      } else if (naclWtTarget != null && !_isPureCacl2SaltType()) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, naclWtTarget, (a, b) {
          final chlorides = double.tryParse(a) ?? 0;
          final water = _oilSaltWaterBasisForSample(
            i,
            double.tryParse(b) ?? 0,
          );
          if (chlorides == 0 || water == 0) return '';
          final frac = 1.648 * chlorides / 10000;
          if (frac + water == 0) return '';
          final totalSalt = 100 * frac / (frac + water);
          final cacl2Vals = _cacl2PctWtKey != null
              ? propertyTable[_cacl2PctWtKey!]
              : null;
          final cacl2 = cacl2Vals != null && i < cacl2Vals.length
              ? double.tryParse(cacl2Vals[i].value) ?? 0
              : 0;
          final nacl = _isMixedSaltType()
              ? totalSalt - cacl2
              : totalSalt;
          return _formatMudPropertyValue(
            naclWtTarget,
            nacl < 0 ? 0.0 : nacl,
            fallbackDigits: 1,
          );
        });
      }

      final naclConcTarget = _naclConcKey;
      if (naclConcTarget != null && _naclPctWtKey != null) {
        if (_isMixedSaltType()) {
          _watchOneOpt(i, _wholeMudChlorideKey, naclConcTarget, (a) {
            final naclMg = _naclMgForMixedSalt(i);
            return naclMg == 0
                ? ''
                : _formatMudPropertyValue(
                    naclConcTarget,
                    naclMg,
                    fallbackDigits: 0,
                  );
          });
        } else if (_isNaclSaltType()) {
          _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, naclConcTarget, (
            a,
            b,
          ) {
            final naclWt = _naclWtFromChlorideWater(
              double.tryParse(a) ?? 0,
              _oilSaltWaterBasisForSample(i, double.tryParse(b) ?? 0),
            );
            if (naclWt == 0) return '';
            return _formatMudPropertyValue(
              naclConcTarget,
              naclWt * 10000 * _naclBrineSg(naclWt),
              fallbackDigits: 0,
            );
          });
        } else {
          _watchOneOpt(i, _naclPctWtKey, naclConcTarget, (a) {
            final naclWt = double.tryParse(a) ?? 0;
            if (naclWt == 0) return '';
            return _formatMudPropertyValue(
              naclConcTarget,
              naclWt * 10000 * _naclBrineSg(naclWt),
              fallbackDigits: 0,
            );
          });
        }
      }

      final insolubleNaclTarget = _insolubleNaclKey;
      if (insolubleNaclTarget != null && _naclConcKey != null) {
        if (_isMixedSaltType()) {
          _watchOneOpt(i, _naclPctWtKey, insolubleNaclTarget, (a) {
            final naclWt = double.tryParse(a) ?? 0;
            if (naclWt == 0) return '';
            final cacl2Vals = _cacl2PctWtKey != null
                ? propertyTable[_cacl2PctWtKey!]
                : null;
            final cacl2Wt = cacl2Vals != null && i < cacl2Vals.length
                ? double.tryParse(cacl2Vals[i].value) ?? 0
                : 0.0;
            final maxNacl = _maxSolubleNaclWt(cacl2Wt);
            return naclWt > maxNacl
                ? _formatMudPropertyValue(
                    insolubleNaclTarget,
                    naclWt - maxNacl,
                    fallbackDigits: 1,
                  )
                : '0';
          });
        } else {
          _watchOneOpt(i, _naclConcKey, insolubleNaclTarget, (a) {
            final v = double.tryParse(a) ?? 0;
            return v == 0 ? '' : '0';
          });
        }
      }

      final waterActivityTarget = _waterActivityKey;
      if (waterActivityTarget != null &&
          !_isMixedSaltType() &&
          !_isSodiumFormateSaltType()) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, waterActivityTarget, (
          a,
          b,
        ) {
          final chlorides = double.tryParse(a) ?? 0;
          final rawWater = double.tryParse(b) ?? 0;
          final water = _isNaclSaltType()
              ? _oilSaltWaterBasisForSample(i, rawWater)
              : _pureCacl2WaterBasisForSample(i, rawWater);
          if (chlorides == 0 || water == 0) return '';
          final factor = _isNaclSaltType()
              ? 1.648
              : _isPureCacl2SaltType()
              ? _pureCacl2ChlorideConversionFactor
              : _cacl2ChlorideConversionFactor;
          final frac = factor * chlorides / 10000;
          if (frac + water == 0) return '';
          final saltWtPct = 100 * frac / (frac + water);
          final activity = _isNaclSaltType()
              ? _naclWaterActivity(saltWtPct)
              : _cacl2WaterActivity(saltWtPct);
          return _formatMudPropertyValue(
            waterActivityTarget,
            activity < 0 ? 0.0 : activity,
            fallbackDigits: 2,
          );
        });
      }

      final wpsTarget = _wpsSaltPercentKey;
      if (wpsTarget != null &&
          _isNaclSaltType() &&
          _wholeMudChlorideKey != null &&
          _waterKey != null) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, wpsTarget, (a, b) {
          final naclWt = _naclWtFromChlorideWater(
            double.tryParse(a) ?? 0,
            _oilSaltWaterBasisForSample(i, double.tryParse(b) ?? 0),
          );
          if (naclWt == 0) return '';
          return _formatMudPropertyValue(
            wpsTarget,
            10000 * naclWt,
            fallbackDigits: 0,
          );
        });
      } else if (wpsTarget != null &&
          !_isSodiumFormateSaltType() &&
          !_isMixedSaltType() &&
          _wholeMudChlorideKey != null &&
          _waterKey != null) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, wpsTarget, (a, b) {
          final chlorides = double.tryParse(a) ?? 0;
          final water = _pureCacl2WaterBasisForSample(
            i,
            double.tryParse(b) ?? 0,
          );
          if (chlorides == 0 || water == 0) return '';
          final frac =
              _pureCacl2ChlorideConversionFactor * chlorides / 10000;
          if (frac + water == 0) return '';
          return _formatMudPropertyValue(
            wpsTarget,
            100 * frac / (frac + water) * 10000,
            fallbackDigits: 0,
          );
        });
      } else if (wpsTarget != null && _cacl2PctWtKey != null) {
        final cacl2List = propertyTable[_cacl2PctWtKey!];
        final wpsList = propertyTable[wpsTarget];
        if (cacl2List != null &&
            wpsList != null &&
            i < cacl2List.length &&
            i < wpsList.length) {
          // Set initial value
          final s0 = double.tryParse(cacl2List[i].value) ?? 0;
          wpsList[i].value = s0 == 0
              ? ''
              : _formatMudPropertyValue(
                  wpsTarget,
                  s0 * 10000,
                  fallbackDigits: 0,
                );
          // Watch changes
          ever(cacl2List[i], (_) {
            final s = double.tryParse(cacl2List[i].value) ?? 0;
            wpsList[i].value = s == 0
                ? ''
                : _formatMudPropertyValue(
                    wpsTarget,
                    s * 10000,
                    fallbackDigits: 0,
                  );
          });
        }
      }

      // ── 11. Water Phase Salinity mg/l = CaCl2(% wt) × 10000 × BrineSG ────
      final wpsMglTarget = _wpsSaltPpmKey;
      if (wpsMglTarget != null &&
          wpsMglTarget != wpsTarget &&
          _cacl2PctWtKey != null) {
        final cacl2List = propertyTable[_cacl2PctWtKey!];
        final wpsLList = propertyTable[wpsMglTarget];
        if (cacl2List != null &&
            wpsLList != null &&
            i < cacl2List.length &&
            i < wpsLList.length) {
          void calcWpsMgl() {
            final s = double.tryParse(cacl2List[i].value) ?? 0;
            if (s == 0) {
              wpsLList[i].value = '';
              return;
            }
            final bSG = _cacl2BrineSg(s);
            wpsLList[i].value = _formatMudPropertyValue(
              wpsMglTarget,
              s * 10000 * bSG,
              fallbackDigits: 0,
            );
          }

          calcWpsMgl();
          ever(cacl2List[i], (_) => calcWpsMgl());
        }
      }

      // ── 12. Brine Density (SG) row ────────────────────────────────────────
      final bdTarget = _brineDensitySgKey;
      if (bdTarget != null && !_isMixedSaltType()) {
        if (_isNaclSaltType() &&
            _wholeMudChlorideKey != null &&
            _waterKey != null) {
          _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, bdTarget, (a, b) {
            final naclWt = _naclWtFromChlorideWater(
              double.tryParse(a) ?? 0,
              _oilSaltWaterBasisForSample(i, double.tryParse(b) ?? 0),
            );
            if (naclWt == 0) return '';
            return _formatMudPropertyValue(
              bdTarget,
              _naclBrineSg(naclWt) * 8.345,
              fallbackDigits: 2,
            );
          });
        } else {
          final densitySource = _isMixedSaltType()
              ? (_naclPctWtKey ?? _cacl2PctWtKey)
              : (_cacl2PctWtKey ?? _naclPctWtKey);
          _watchOneOpt(i, densitySource, bdTarget, (a) {
            final s = double.tryParse(a) ?? 0;
            if (s == 0) return '';
            final brineSG = densitySource == _naclPctWtKey
                ? _naclBrineSg(s)
                : _cacl2BrineSg(s);
            return _formatMudPropertyValue(
              bdTarget,
              brineSG * 8.345,
              fallbackDigits: 2,
            );
          });
        }
      }

      // ── WBM-only ──────────────────────────────────────────────────────────
      final brineContentTarget = _brineContentKey;
      if (brineContentTarget != null &&
          !_isMixedSaltType()) {
        if (_isNaclSaltType() &&
            _wholeMudChlorideKey != null &&
            _waterKey != null) {
          _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, brineContentTarget, (
            a,
            b,
          ) {
            final water = _oilSaltWaterBasisForSample(
              i,
              double.tryParse(b) ?? 0,
            );
            final saltWtPct = _naclWtFromChlorideWater(
              double.tryParse(a) ?? 0,
              water,
            );
            if (saltWtPct == 0 || water == 0) return '';
            final waterFraction =
                (1 - saltWtPct / 100) * _naclBrineSg(saltWtPct);
            if (waterFraction <= 0) return '';
            return _formatMudPropertyValue(
              brineContentTarget,
              water / waterFraction,
              fallbackDigits: 1,
            );
          });
        } else {
          final brineSource = _isMixedSaltType()
              ? (_naclPctWtKey ?? _cacl2PctWtKey)
              : (_cacl2PctWtKey ?? _naclPctWtKey);
          _watchTwoOpt(i, brineSource, _waterKey, brineContentTarget, (a, b) {
            final saltWtPct = double.tryParse(a) ?? 0;
            final water = _pureCacl2WaterBasisForSample(
              i,
              double.tryParse(b) ?? 0,
            );
            if (saltWtPct == 0 || water == 0) return '';
            final brineSG = brineSource == _naclPctWtKey
                ? _naclBrineSg(saltWtPct)
                : _cacl2BrineSg(saltWtPct);
            final waterFraction = (1 - saltWtPct / 100) * brineSG;
            if (waterFraction <= 0) return '';
            return _formatMudPropertyValue(
              brineContentTarget,
              water / waterFraction,
              fallbackDigits: 1,
            );
          });
        }
      }

      if (_isMixedSaltType()) {
        _setupMixedSaltCalculations(i);
      }
      if (_isSodiumFormateSaltType()) {
        _setupSodiumFormateCalculations(i);
      }

      if (selectedFluidType.value == 'Water-based') {
        // Mud Chlorides = 10000 × CaCl2%
        final mudChlTarget = _mudChloridesMglKey;
        if (mudChlTarget != null) {
          _watchOneOpt(i, _cacl2PctWtKey, mudChlTarget, (a) {
            final v = double.tryParse(a) ?? 0;
            return v == 0
                ? ''
                : _formatMudPropertyValue(
                    mudChlTarget,
                    v * 10000,
                    fallbackDigits: 0,
                  );
          });
        }

        // KCl = 10000 × CaCl2% × BrineSG
        final kclTarget = _kclKey;
        if (kclTarget != null) {
          _watchOneOpt(i, _cacl2PctWtKey, kclTarget, (a) {
            final s = double.tryParse(a) ?? 0;
            if (s == 0) return '';
            final bSG = _cacl2BrineSg(s);
            return _formatMudPropertyValue(
              kclTarget,
              s * 10000 * bSG,
              fallbackDigits: 0,
            );
          });
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // isAutoCalc
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupMixedSaltCalculations(int sampleIndex) {
    final chlorideList = _wholeMudChlorideKey != null
        ? propertyTable[_wholeMudChlorideKey!]
        : null;
    final calciumList = _wholeMudCaKey != null
        ? propertyTable[_wholeMudCaKey!]
        : null;
    final waterList = _waterKey != null ? propertyTable[_waterKey!] : null;
    if (chlorideList == null ||
        calciumList == null ||
        waterList == null ||
        sampleIndex >= chlorideList.length ||
        sampleIndex >= calciumList.length ||
        sampleIndex >= waterList.length) {
      return;
    }

    void setValue(String? key, String value) {
      final list = key == null ? null : propertyTable[key];
      if (list != null && sampleIndex < list.length) {
        list[sampleIndex].value = value;
      }
    }

    void recalc() {
      final chlorides = double.tryParse(chlorideList[sampleIndex].value) ?? 0;
      final calcium = double.tryParse(calciumList[sampleIndex].value) ?? 0;
      final rawWater = double.tryParse(waterList[sampleIndex].value) ?? 0;
      final water = _oilSaltWaterBasisForSample(sampleIndex, rawWater);
      if (chlorides == 0 || water == 0) {
        for (final key in [
          _cacl2ConcKey,
          _cacl2PctWtKey,
          _naclConcKey,
          _naclPctWtKey,
          _insolubleNaclKey,
          _wpsSaltPercentKey,
          _brineDensitySgKey,
          _brineContentKey,
          _saltContentWaterPhaseKey,
          _waterActivityKey,
        ]) {
          setValue(key, '');
        }
        return;
      }

      final mixed = _mixedSaltValues(chlorides, calcium, water);
      if (mixed == null) return;

      setValue(
        _cacl2ConcKey,
        _formatMudPropertyValue(
          _cacl2ConcKey,
          mixed.cacl2AqMgL,
          fallbackDigits: 0,
        ),
      );
      setValue(
        _cacl2PctWtKey,
        _formatMudPropertyValue(
          _cacl2PctWtKey,
          mixed.cacl2Wt,
          fallbackDigits: 1,
        ),
      );
      setValue(
        _naclConcKey,
        _formatMudPropertyValue(
          _naclConcKey,
          mixed.naclAqMgL,
          fallbackDigits: 0,
        ),
      );
      setValue(
        _naclPctWtKey,
        _formatMudPropertyValue(_naclPctWtKey, mixed.naclWt, fallbackDigits: 1),
      );
      setValue(
        _insolubleNaclKey,
        _formatMudPropertyValue(
          _insolubleNaclKey,
          mixed.insolubleNaclMgL,
          fallbackDigits: 0,
        ),
      );
      setValue(
        _wpsSaltPercentKey,
        _formatMudPropertyValue(
          _wpsSaltPercentKey,
          10000 * mixed.saltContent,
          fallbackDigits: 0,
        ),
      );
      setValue(
        _brineDensitySgKey,
        _formatMudPropertyValue(
          _brineDensitySgKey,
          mixed.brineSg * 8.345,
          fallbackDigits: 2,
        ),
      );
      setValue(
        _brineContentKey,
        mixed.brineContent == 0
            ? ''
            : _formatMudPropertyValue(
                _brineContentKey,
                mixed.brineContent,
                fallbackDigits: 1,
              ),
      );
      setValue(
        _saltContentWaterPhaseKey,
        _formatMudPropertyValue(
          _saltContentWaterPhaseKey,
          mixed.saltContent,
          fallbackDigits: 1,
        ),
      );
      setValue(
        _waterActivityKey,
        _formatMudPropertyValue(
          _waterActivityKey,
          mixed.waterActivity < 0 ? 0.0 : mixed.waterActivity,
          fallbackDigits: 2,
        ),
      );
    }

    recalc();
    ever(chlorideList[sampleIndex], (_) => recalc());
    ever(calciumList[sampleIndex], (_) => recalc());
    ever(waterList[sampleIndex], (_) => recalc());
  }

  void _setupSodiumFormateCalculations(int sampleIndex) {
    final chlorideList = _wholeMudChlorideKey != null
        ? propertyTable[_wholeMudChlorideKey!]
        : null;
    final waterList = _waterKey != null ? propertyTable[_waterKey!] : null;
    final pmList = _wholeMudAlkKey != null ? propertyTable[_wholeMudAlkKey!] : null;
    if (chlorideList == null ||
        waterList == null ||
        sampleIndex >= chlorideList.length ||
        sampleIndex >= waterList.length) {
      return;
    }

    void setValue(String? key, String value) {
      final list = key == null ? null : propertyTable[key];
      if (list != null && sampleIndex < list.length) {
        list[sampleIndex].value = value;
      }
    }

    void recalc() {
      final chlorides = double.tryParse(chlorideList[sampleIndex].value) ?? 0;
      final water = double.tryParse(waterList[sampleIndex].value) ?? 0;
      final pm = pmList != null && sampleIndex < pmList.length
          ? double.tryParse(pmList[sampleIndex].value) ?? 0
          : 0.0;
      if (water <= 0) {
        for (final key in [
          _brinePhaseChlorideSalinityKey,
          _saltContentWaterPhaseKey,
          _wpsSaltPercentKey,
          _sodiumFormateWtKey,
          _sodiumFormateConcKey,
          _brineDensitySgKey,
          _waterActivityKey,
        ]) {
          setValue(key, '');
        }
        return;
      }

      final data = _sodiumFormateValues(
        chloridesMgl: chlorides,
        waterVol: water,
        pm: pm,
      );

      setValue(
        _brinePhaseChlorideSalinityKey,
        _formatMudPropertyValue(
          _brinePhaseChlorideSalinityKey,
          data.brinePhaseChlorides,
          fallbackDigits: 0,
        ),
      );
      setValue(
        _saltContentWaterPhaseKey,
        _formatMudPropertyValue(
          _saltContentWaterPhaseKey,
          data.saltContent,
          fallbackDigits: 1,
        ),
      );
      setValue(
        _wpsSaltPercentKey,
        _formatMudPropertyValue(_wpsSaltPercentKey, data.wpsPpm, fallbackDigits: 0),
      );
      setValue(
        _sodiumFormateWtKey,
        _formatMudPropertyValue(
          _sodiumFormateWtKey,
          data.formateWt,
          fallbackDigits: 0,
        ),
      );
      setValue(
        _sodiumFormateConcKey,
        _formatMudPropertyValue(
          _sodiumFormateConcKey,
          data.formateMgL,
          fallbackDigits: 0,
        ),
      );
      setValue(
        _brineDensitySgKey,
        _formatMudPropertyValue(
          _brineDensitySgKey,
          data.brineDensityPpg,
          fallbackDigits: 5,
        ),
      );
      setValue(
        _waterActivityKey,
        _formatMudPropertyValue(
          _waterActivityKey,
          data.waterActivity,
          fallbackDigits: 2,
        ),
      );
    }

    recalc();
    ever(chlorideList[sampleIndex], (_) => recalc());
    ever(waterList[sampleIndex], (_) => recalc());
    if (pmList != null && sampleIndex < pmList.length) {
      ever(pmList[sampleIndex], (_) => recalc());
    }
  }

  bool isAutoCalc(String fieldName) {
    final k = fieldName.toLowerCase().replaceAll('*', '').trim();
    if (k == 'lsryp' || k.contains('lsryp')) return true;
    if (k.contains('oil') && k.contains('water') && k.contains('ratio'))
      return true;
    // Solids row (auto-calculated from Oil+Water) — grey read-only
    if ((k == 'solids' ||
            k.startsWith('solids') ||
            k == 'total solids' ||
            k.contains('total solids')) &&
        !k.contains('corr') &&
        !k.contains('drill') &&
        !k.contains('adj') &&
        !k.contains('salt'))
      return true;
    if (k.contains('corrected solids') ||
        k.contains('corr. solids') ||
        k.contains('solids adjusted') ||
        k.contains('adjusted for salt'))
      return true;
    if (k.contains('excess lime')) return true;
    if (k.contains('cacl2 concentration') ||
        k.contains('cacl2 conc') ||
        (k.startsWith('cacl2') && k.contains('mg')))
      return true;
    if (k.startsWith('cacl2') && (k.contains('wt') || k.contains('%')))
      return true;
    if ((k.startsWith('nacl') && (k.contains('wt') || k.contains('%'))) ||
        (k.startsWith('nacl') && k.contains('mg')) ||
        (k.contains('insoluble') && k.contains('nacl')))
      return true;
    if (_isSodiumFormateSaltType() &&
        (k.contains('water activity') ||
            k.contains('water phase salinity') ||
            k.contains('brine phase salinity') ||
            k.contains('brine phase chlorides salinity') ||
            k.contains('oil/sodium formate') ||
            k.contains('sodium formate brine') ||
            k.contains('sodium formate wt') ||
            k == 'sodium formate' ||
            k.contains('dissolved sodium formate'))) {
      return true;
    }
    if (k.contains('salt content') && k.contains('water phase')) return true;
    if (k.contains('brine density') || k.contains('brine content')) return true;
    if (k.contains('water activity')) return true;
    // FIX: match any water phase salinity row (no 'ppm' requirement)
    if (k.contains('water phase salinity') || k.contains('water phase sal'))
      return true;
    if ((k.contains('mud chloride') || k == 'mud chlorides') &&
        !k.contains('whole'))
      return true;
    if (k == 'kcl' || k.startsWith('kcl')) return true;
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOLID ANALYSIS WATCHERS & SAVE
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatMudPropertyValue(
    String? propertyKey,
    num value, {
    int fallbackDigits = 2,
  }) {
    final numeric = value.toDouble();
    if (numeric.isNaN || numeric.isInfinite) return '';
    return numeric.toStringAsFixed(fallbackDigits);
  }

  double _parseMudNumber(String value) {
    final clean = value.trim().replaceAll(',', '');
    if (clean.isEmpty) return 0.0;
    return double.tryParse(clean) ?? 0.0;
  }

  double _oilWaterRatioWaterPercent(int sampleIndex) {
    final ratioKey = _owRatioKey;
    if (ratioKey != null) {
      final row = propertyTable[ratioKey];
      if (row != null && sampleIndex < row.length) {
        final text = row[sampleIndex].value.trim();
        if (text.isNotEmpty) {
          final parts = text.split(RegExp(r'[/:\-]'));
          if (parts.length >= 2) {
            final ratioWater = _parseMudNumber(parts[1]);
            if (ratioWater > 0 && ratioWater <= 100) return ratioWater;
          }
        }
      }
    }

    final oilRow = _oilKey == null ? null : propertyTable[_oilKey!];
    final waterRow = _waterKey == null ? null : propertyTable[_waterKey!];
    final oil = oilRow != null && sampleIndex < oilRow.length
        ? _parseMudNumber(oilRow[sampleIndex].value)
        : 0.0;
    final water = waterRow != null && sampleIndex < waterRow.length
        ? _parseMudNumber(waterRow[sampleIndex].value)
        : 0.0;
    final total = oil + water;
    if (total > 0) {
      final oilPct = oil == 0
          ? (water > 50 ? water : 100 - water)
          : 100 * oil / total;
      final roundedOil = ((oilPct / 5).round() * 5).clamp(0, 100).toDouble();
      final ratioWater = 100 - roundedOil;
      if (ratioWater > 0 && ratioWater <= 100) return ratioWater;
    }
    return 0.0;
  }

  double _pureCacl2WaterBasisForSample(int sampleIndex, double fallbackWater) {
    final isOilMud =
        selectedFluidType.value == 'Oil-based' ||
        selectedFluidType.value == 'Synthetic';
    if (!isOilMud || !_isPureCacl2SaltType()) return fallbackWater;
    final ratioWater = _oilWaterRatioWaterPercent(sampleIndex);
    return ratioWater > 0 ? ratioWater : fallbackWater;
  }

  double _oilSaltWaterBasisForSample(int sampleIndex, double fallbackWater) {
    final isOilMud =
        selectedFluidType.value == 'Oil-based' ||
        selectedFluidType.value == 'Synthetic';
    if (!isOilMud) return fallbackWater;
    final ratioWater = _oilWaterRatioWaterPercent(sampleIndex);
    return ratioWater > 0 ? ratioWater : fallbackWater;
  }

  String _formatManualInputValue(num value, {int fallbackDigits = 2}) {
    final numeric = value.toDouble();
    if (numeric.isNaN || numeric.isInfinite) return '';
    return numeric.toStringAsFixed(fallbackDigits);
  }

  String formatMudNumericValue(num value, {int fallbackDigits = 2}) {
    return _formatManualInputValue(value, fallbackDigits: fallbackDigits);
  }

  String formatManualMudValue(String fieldName, String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    final key = _normalizeLabel(fieldName);
    if (key.contains('description') ||
        key.contains('sample from') ||
        key.contains('time sample') ||
        key.contains('oil/water ratio')) {
      return value;
    }
    final numeric = double.tryParse(text);
    if (numeric == null) return value;
    return _formatManualInputValue(numeric, fallbackDigits: 2);
  }

  void _setupSolidAnalysisWatchers() {
    for (int si = 0; si < 3; si++) {
      final sampleIdx = si;
      final sourceKeys = [
        _mwKey,
        _solidsKey,
        _oilKey,
        _waterKey,
        _owRatioKey,
        _bariteKey,
        _bentoniteKey,
        _mbtKey,
        _wholeMudChlorideKey,
        _wholeMudCaKey,
        _wholeMudAlkKey,
        _cacl2PctWtKey,
        _cacl2ConcKey,
        _naclPctWtKey,
        _naclConcKey,
        _sodiumFormateWtKey,
        _sodiumFormateConcKey,
        _dissolvedSodiumFormateKey,
        _chloridesForSolidsKey,
        _saltContentWaterPhaseKey,
        _brineContentKey,
        _brineDensitySgKey,
        _brineVolPctKey,
        _correctedSolidsKey,
        _corrSolidsValueKey,
      ];
      for (final key in sourceKeys) {
        if (key == null) continue;
        final list = propertyTable[key];
        if (list == null || sampleIdx >= list.length) continue;
        ever(list[sampleIdx], (_) => _scheduleSolidAnalysisSave(sampleIdx));
      }
    }
  }

  void _scheduleSolidAnalysisSave(int sampleIdx) {
    _debounceTimers[sampleIdx]?.cancel();
    final vals = _extractSampleValues(sampleIdx);
    if (!_hasSolidAnalysisInputs(vals)) {
      _clearSolidAnalysisSample(sampleIdx);
      solidSaveStatus['$sampleIdx']?.value = 'idle';
      return;
    }
    solidSaveStatus['$sampleIdx']?.value = 'idle';
    _debounceTimers[sampleIdx] = Timer(
      _kSaveDebounce,
      () => _saveSolidAnalysis(sampleIdx),
    );
  }

  void _scheduleAllSolidAnalysisSamples() {
    for (int i = 0; i < 3; i++) {
      _scheduleSolidAnalysisSave(i);
    }
  }

  Future<void> _saveSolidAnalysis(int sampleIdx) async {
    final vals = _extractSampleValues(sampleIdx);
    if (!_hasSolidAnalysisInputs(vals)) {
      _clearSolidAnalysisSample(sampleIdx);
      solidSaveStatus['$sampleIdx']?.value = 'idle';
      return;
    }

    solidSaveStatus['$sampleIdx']?.value = 'saving';
    try {
      final localResult = _computeSolidsAnalysis(vals);
      if (localResult != null) {
        _updateResultFromData(sampleIdx, localResult);
      }

      final body = jsonEncode({
        'mudWeight': vals['mudWeight'],
        'retortSolids': vals['retortSolids'],
        'oilVol': vals['oilVol'],
        'waterVol': vals['waterVol'],
        'bariteLb': vals['bariteLb'],
        'bentoniteLb': localResult?['bentoniteLb'] ?? vals['bentoniteLb'],
        'cacl2Pct': vals['cacl2Pct'],
        'naclPct': vals['naclPct'],
        'wpsPpm': vals['wpsPpm'],
        'calciumMgl': vals['calciumMgl'],
        'saltWaterVol': vals['saltWaterVol'],
        'chloridesMgl': vals['chloridesMgl'],
        'makeupChloridesMgl': vals['makeupChloridesMgl'],
        'brineVolPct': localResult?['brineVol'] ?? vals['brineVolPct'], // L62 Brine % vol
        'brineDensityPpg': localResult?['brineDensityPpg'] ?? vals['brineDensityPpg'],
        'corrSolidsPct': vals['corrSolidsPct'], // L45 Corrected Solids %
        'oilSG': vals['oilSG'],
        'hgsSG': vals['hgsSG'], // L58 HGS density
        'lgsSG': vals['lgsSG'], // L57 LGS density
        if (localResult != null) ...localResult,
        'sampleIndex': sampleIdx,
        'fluidType': selectedFluidType.value,
        'saltType': selectedSaltType.value,
        'isWeightedMud': (vals['isWeightedMud'] ?? 0) > 0,
        'wellId': _wellId,
        if (_reportId.isNotEmpty) 'reportId': _reportId,
      });

      final existingId = _solidAnalysisIds[sampleIdx];
      http.Response response;

      if (existingId == null) {
        response = await http.post(
          Uri.parse('${_kBaseUrl}solids'),
          headers: ApiEndpoint.jsonHeaders,
          body: body,
        );
        if (response.statusCode == 201) {
          final data = jsonDecode(response.body)['data'];
          _solidAnalysisIds[sampleIdx] = data['_id'] as String?;
        }
      } else {
        response = await http.put(
          Uri.parse('${_kBaseUrl}solids/$existingId'),
          headers: ApiEndpoint.jsonHeaders,
          body: body,
        );
      }

      if (localResult != null) {
        _updateResultFromData(sampleIdx, localResult);
      }

      solidSaveStatus['$sampleIdx']?.value =
          (response.statusCode == 200 || response.statusCode == 201)
          ? 'saved'
          : 'error';
    } catch (e) {
      debugPrint('[SolidsAnalysis] Save error (sample $sampleIdx): $e');
      solidSaveStatus['$sampleIdx']?.value = 'error';
    }
  }

  Map<String, dynamic>? _computeSolidsAnalysis(Map<String, double> vals) {
    final mw = vals['mudWeight'] ?? 0;
    if (mw <= 0) return null;

    final retortSolids = vals['retortSolids'] ?? 0;
    final oilVol = vals['oilVol'] ?? 0;
    final waterVol = vals['waterVol'] ?? 0;
    final saltWaterVol = vals['saltWaterVol'] ?? waterVol;
    final bariteLb = vals['bariteLb'] ?? 0;
    final inputBentoniteLb = vals['bentoniteLb'] ?? 0;
    final mbt = vals['mbt'] ?? 0;
    final chloridesMgl = vals['chloridesMgl'] ?? 0;
    final wpsPpm = vals['wpsPpm'] ?? 0;
    final cacl2Pct = vals['cacl2Pct'] ?? 0;
    final naclPct = vals['naclPct'] ?? 0;
    final makeupChloridesMgl = vals['makeupChloridesMgl'] ?? 0;
    final brineDensityPpg = vals['brineDensityPpg'] ?? 0;
    final oilSG = vals['oilSG'] ?? 0.0;
    final hgsSG = vals['hgsSG'] ?? 0.0;
    final lgsSG = vals['lgsSG'] ?? 0.0;
    final shaleCec = vals['shaleCec'] ?? 0.0;
    final bentCec = vals['bentCec'] ?? 0.0;
    final fluid = selectedFluidType.value.toLowerCase();
    final isOilMud = fluid.contains('oil') || fluid.contains('synthetic');
    final weightedMud = (vals['isWeightedMud'] ?? 0) > 0;
    final wbmChlorideBasis = math.max(0.0, chloridesMgl - makeupChloridesMgl);
    final oilSaltWaterVol = isOilMud && _isSodiumFormateSaltType()
        ? waterVol
        : saltWaterVol;
    final oilSalt = isOilMud
        ? _oilSaltResult(
            chloridesMgl: chloridesMgl,
            calciumMgl: vals['calciumMgl'] ?? 0,
            waterVol: oilSaltWaterVol,
            retortSolids: retortSolids,
            cacl2Pct: cacl2Pct,
            naclPct: naclPct,
            wpsPpm: wpsPpm,
            pm: vals['pm'] ?? 0,
          )
        : null;
    final brineSG = isOilMud
        ? (brineDensityPpg > 0
              ? brineDensityPpg / 8.345
              : (oilSalt?.brineSG ?? 1.0))
        : 1.0;

    double brineVol;
    final brineVolPct = vals['brineVolPct'] ?? 0;
    if (isOilMud && brineVolPct > 0) {
      brineVol = brineVolPct;
    } else if (isOilMud && oilSalt != null) {
      brineVol = oilSalt.brineVolPct;
    } else {
      brineVol = brineVolPct > 0 ? brineVolPct : waterVol;
    }

    final corrSolidsPct = vals['corrSolidsPct'] ?? 0;
    final dissolvedSolids = isOilMud
        ? (corrSolidsPct > 0
              ? retortSolids - corrSolidsPct
              : (oilSalt?.dissolvedSolidsPct ?? (brineVol - waterVol)))
        : waterVol * wbmChlorideBasis * 0.0000012;
    final safeDissolvedSolids = dissolvedSolids < 0 ? 0.0 : dissolvedSolids;
    final rawCorrectedSolids = isOilMud
        ? (corrSolidsPct > 0
              ? corrSolidsPct
              : (oilSalt?.correctedSolidsPct ??
                    (retortSolids - safeDissolvedSolids)))
        : (retortSolids - safeDissolvedSolids);
    final correctedSolids = rawCorrectedSolids;
    final safeCorrected = correctedSolids < 0 ? 0 : correctedSolids;
    final totalSolids = retortSolids > 0
        ? retortSolids
        : (100 - (oilVol + waterVol));

    final balanceSolids = safeCorrected;
    final brineMassForBalance = isOilMud
        ? (_oilMudBrineMassForSolidsBalance(
              waterVol: waterVol,
              saltWaterVol: saltWaterVol,
              dissolvedSolidsPct: safeDissolvedSolids,
              chloridesMgl: chloridesMgl,
              calciumMgl: vals['calciumMgl'] ?? 0,
              cacl2Pct: cacl2Pct,
              naclPct: naclPct,
              wpsPpm: wpsPpm,
              pm: vals['pm'] ?? 0,
              fallbackBrineSG: brineSG,
              lgsSG: lgsSG,
            ) ??
            (brineVol * brineSG))
        : (weightedMud
              ? ((brineVol * brineSG) + (safeDissolvedSolids * 0.54))
              : (brineVol * brineSG));

    var hgsPercent = 0.0;
    var lgsPercent = balanceSolids;
    var avgSG = balanceSolids > 0 ? lgsSG : 0.0;
    if (weightedMud && hgsSG != lgsSG && balanceSolids > 0) {
      final mudVolumeDensity = mw * 42 / 3.5;
      final lgsMassBalanceSolids = isOilMud ? balanceSolids : totalSolids;
      hgsPercent =
          (mudVolumeDensity -
              oilVol * oilSG -
              brineMassForBalance -
              lgsMassBalanceSolids * lgsSG) /
          (hgsSG - lgsSG);
      lgsPercent = balanceSolids - hgsPercent;
      avgSG = (lgsPercent * lgsSG + hgsPercent * hgsSG) / balanceSolids;
    }

    final lgsLb = 3.5 * lgsSG * lgsPercent;
    final hgsLb = 3.5 * hgsSG * hgsPercent;
    double bentoniteLb;
    double drillSolidsLb;
    if (!isOilMud && mbt > 0 && bentCec != shaleCec) {
      bentoniteLb = ((mbt * 70) - (lgsLb * shaleCec)) / (bentCec - shaleCec);
      drillSolidsLb = lgsLb - bentoniteLb;
    } else if (!isOilMud && inputBentoniteLb > 0) {
      bentoniteLb = inputBentoniteLb;
      drillSolidsLb = lgsLb - bentoniteLb;
    } else {
      bentoniteLb = 0;
      drillSolidsLb = lgsLb;
    }
    final bentPercent = lgsSG > 0 ? bentoniteLb / (3.5 * lgsSG) : 0;
    final drillSolidsPercent = lgsSG > 0 ? drillSolidsLb / (3.5 * lgsSG) : 0;
    final obmChemicalsPercent = isOilMud ? 0.0 : null;
    final obmChemicalsLb = isOilMud ? 0.0 : null;
    final dsBentRatio = bentoniteLb != 0 ? drillSolidsLb / bentoniteLb : null;

    return {
      'mudWeight': mw,
      'retortSolids': totalSolids < 0 ? 0 : totalSolids,
      'bariteLb': bariteLb,
      'bentoniteLb': bentoniteLb,
      'brineSG': brineSG,
      'brineDensityPpg': brineSG * 8.345,
      'brineVol': brineVol,
      'totalSolids': totalSolids < 0 ? 0 : totalSolids,
      'correctedSolids': safeCorrected,
      'dissolvedSolids': safeDissolvedSolids,
      'avgSG': avgSG,
      'hgsPercent': hgsPercent,
      'hgsLb': hgsLb,
      'lgsPercent': lgsPercent,
      'lgsLb': lgsLb,
      'bentPercent': bentPercent,
      'drillSolidsPercent': drillSolidsPercent,
      'drillSolidsLb': drillSolidsLb,
      if (obmChemicalsPercent != null)
        'obmChemicalsPercent': obmChemicalsPercent,
      if (obmChemicalsLb != null) 'obmChemicalsLb': obmChemicalsLb,
      'dsBentRatio': dsBentRatio,
      'oilSG': oilSG,
      'hgsSG': hgsSG,
      'lgsSG': lgsSG,
      'isWeightedMud': weightedMud ? 1 : 0,
    };
  }

  bool _hasSolidAnalysisInputs(Map<String, double> vals) {
    final mw = vals['mudWeight'] ?? 0;
    final retortSolids = vals['retortSolids'] ?? 0;
    final water = vals['waterVol'] ?? 0;
    return mw > 0 && retortSolids > 0 && water > 0;
  }

  double? _oilMudBrineMassForSolidsBalance({
    required double waterVol,
    required double saltWaterVol,
    required double dissolvedSolidsPct,
    required double chloridesMgl,
    required double calciumMgl,
    required double cacl2Pct,
    required double naclPct,
    required double wpsPpm,
    required double pm,
    required double fallbackBrineSG,
    required double lgsSG,
  }) {
    if (waterVol <= 0) {
      return null;
    }

    final saltBasisWater = saltWaterVol > 0 ? saltWaterVol : waterVol;

    if (_isSodiumFormateSaltType()) {
      final formate = _sodiumFormateValues(
        chloridesMgl: chloridesMgl,
        waterVol: waterVol,
        pm: pm,
      );
      final solidSg = lgsSG > 0 ? lgsSG : 2.6;
      return waterVol + (formate.dissolvedSolidsPct * solidSg);
    }

    if (!_isPureCacl2SaltType()) {
      double saltWtPct = 0;
      double brineSG = fallbackBrineSG > 0 ? fallbackBrineSG : 1.0;

      if (_isMixedSaltType()) {
        final mixed = _mixedSaltValues(chloridesMgl, calciumMgl, saltBasisWater);
        if (mixed != null) {
          saltWtPct = mixed.saltContent;
          brineSG = fallbackBrineSG > 0 ? fallbackBrineSG : mixed.brineSg;
        } else {
          saltWtPct = cacl2Pct > 0 ? cacl2Pct : naclPct;
        }
      } else if (_isNaclSaltType()) {
        saltWtPct = _naclWtFromChlorideWater(chloridesMgl, saltBasisWater);
        if (saltWtPct <= 0) {
          saltWtPct = naclPct > 0 ? naclPct : (wpsPpm > 0 ? wpsPpm / 10000 : 0);
        }
        brineSG = fallbackBrineSG > 0
            ? fallbackBrineSG
            : (saltWtPct > 0 ? _naclBrineSg(saltWtPct) : brineSG);
      } else {
        saltWtPct = cacl2Pct > 0
            ? cacl2Pct
            : (wpsPpm > 0 ? wpsPpm / 10000 : naclPct);
      }

      if (saltWtPct <= 0 || brineSG <= 0) return null;
      if (_isNaclSaltType() || _isMixedSaltType()) {
        final dissolved = dissolvedSolidsPct > 0 ? dissolvedSolidsPct : 0.0;
        return (waterVol + dissolved) * brineSG;
      }
      final waterFraction = (1 - saltWtPct / 100) * brineSG;
      if (waterFraction <= 0) return null;
      final rawBrineVol = waterVol / waterFraction;
      return rawBrineVol * brineSG;
    }

    double saltWtPct = 0;
    if (cacl2Pct > 0 && cacl2Pct < 100) {
      saltWtPct = cacl2Pct;
    } else if (chloridesMgl > 0) {
      final frac = _pureCacl2ChlorideConversionFactor * chloridesMgl / 10000;
      saltWtPct = frac + saltBasisWater == 0
          ? 0
          : 100 * frac / (frac + saltBasisWater);
    }

    if (saltWtPct <= 0) return null;
    if (waterVol > 50) {
      return waterVol + (waterVol * saltWtPct / 100 * 0.84);
    }

    final brineSG = _cacl2BrineSg(saltWtPct);
    final waterFraction = (1 - saltWtPct / 100) * brineSG;
    final preciseDissolvedSolids = waterFraction > 0
        ? (waterVol / waterFraction) - waterVol
        : 0.0;
    final effectiveDissolvedSolids = dissolvedSolidsPct > 0
        ? dissolvedSolidsPct
        : math.max(
            preciseDissolvedSolids,
            chloridesMgl > 0 ? _cacl2MinimumDissolvedSolidsForBalance : 0.0,
          );
    final dissolvedSolidsSg =
        (_cacl2DissolvedSolidsBaseSg -
                (_cacl2DissolvedSolidsSgSlope * saltWtPct))
            .clamp(4.0, 4.1)
            .toDouble();
    var brineMass = waterVol + (effectiveDissolvedSolids * dissolvedSolidsSg);

    // The reference DMR engine applies a small CaCl2 balance correction in the
    // mid-high salinity range before solving LGS/HGS. Keep it on mass only so
    // the displayed Mud table values remain unchanged.
    if (saltWtPct > 25 && saltWtPct < 31) {
      brineMass += (31 - saltWtPct) * (saltWtPct - 25) * 0.01053;
    }

    return brineMass;
  }

  bool _effectiveWeightedMudForSolids() {
    final fluid = selectedFluidType.value.toLowerCase();
    return fluid.contains('oil') ||
        fluid.contains('synthetic') ||
        isWeightedMud.value;
  }

  void _clearSolidAnalysisSample(int sampleIdx) {
    if (sampleIdx < 0 || sampleIdx > 2) return;
    final result = Map<String, List<String>>.from(solidAnalysisResult);
    for (final entry in result.entries) {
      final list = List<String>.from(entry.value);
      while (list.length < 3) {
        list.add('-');
      }
      list[sampleIdx] = '-';
      result[entry.key] = list;
    }
    solidAnalysisResult.value = result;
  }

  void _updateResultFromData(int sampleIdx, Map<String, dynamic> data) {
    final result = Map<String, List<String>>.from(solidAnalysisResult);
    void set(String key, dynamic val) {
      result.putIfAbsent(key, () => ['-', '-', '-']);
      final list = List<String>.from(result[key]!);
      while (list.length < 3) {
        list.add('-');
      }
      list[sampleIdx] = _fmt(val);
      result[key] = list;
    }

    void setDigits(String key, dynamic val, int digits) {
      result.putIfAbsent(key, () => ['-', '-', '-']);
      final list = List<String>.from(result[key]!);
      while (list.length < 3) {
        list.add('-');
      }
      final d = val == null ? null : double.tryParse(val.toString());
      list[sampleIdx] = d == null
          ? _fmt(val)
          : formatMudNumericValue(d, fallbackDigits: digits);
      result[key] = list;
    }

    final fluid = selectedFluidType.value.toLowerCase();
    final isOilMud = fluid.contains('oil') || fluid.contains('synthetic');
    if (isOilMud) {
      setDigits('LGS (%)', data['lgsPercent'], 1);
      setDigits('LGS (lb/bbl)', data['lgsLb'], 2);
      setDigits('HGS (%)', data['hgsPercent'], 1);
      setDigits('HGS (lb/bbl)', data['hgsLb'], 2);
      setDigits('OBM Chemicals (%)', data['obmChemicalsPercent'], 2);
      setDigits('OBM Chemicals (lb/bbl)', data['obmChemicalsLb'], 2);
    } else {
      set('LGS (%)', data['lgsPercent']);
      set('LGS (lb/bbl)', data['lgsLb']);
      set('HGS (%)', data['hgsPercent']);
      set('HGS (lb/bbl)', data['hgsLb']);
      set('Diss Solids (%)', data['dissolvedSolids']);
      set('Corr. Solids (%)', data['correctedSolids']);
      set('Brine SG', data['brineSG']);
      set('Bentonite (%)', data['bentPercent']);
      set('Bentonite (lb/bbl)', data['bentoniteLb']);
    }
    if (isOilMud) {
      setDigits('Drill Solids (%)', data['drillSolidsPercent'], 1);
      setDigits('Drill Solids (lb/bbl)', data['drillSolidsLb'], 2);
    } else {
      set('Drill Solids (%)', data['drillSolidsPercent']);
      set('Drill Solids (lb/bbl)', data['drillSolidsLb']);
    }
    set('DS/Bent Ratio', data['dsBentRatio']);
    setDigits('Avg. SG of Solids', data['avgSG'], 2);
    solidAnalysisResult.value = result;
  }

  Future<void> _loadSavedSolidAnalysis() async {
    if (_wellId.isEmpty) return;
    try {
      Future<List<dynamic>> fetchRows({required bool includeReport}) async {
        final uri = Uri.parse('${_kBaseUrl}solids').replace(
          queryParameters: {
            'wellId': _wellId,
            'limit': '30',
            if (includeReport && _reportId.isNotEmpty) 'reportId': _reportId,
          },
        );
        final response = await http.get(uri, headers: ApiEndpoint.jsonHeaders);
        if (response.statusCode != 200) return [];
        final decoded = jsonDecode(response.body);
        final rawData = decoded is Map ? decoded['data'] : null;
        return rawData is List ? rawData : (rawData == null ? [] : [rawData]);
      }

      final rows = await fetchRows(includeReport: true);
      final latestBySample = <int, Map<String, dynamic>>{};

      for (final item in rows) {
        if (item is! Map) continue;
        final data = Map<String, dynamic>.from(item);
        final sampleIdx = int.tryParse('${data['sampleIndex'] ?? 0}') ?? 0;
        if (sampleIdx < 0 || sampleIdx > 2) continue;
        latestBySample.putIfAbsent(sampleIdx, () => data);
      }

      latestBySample.forEach((sampleIdx, data) {
        if (!_hasSolidAnalysisInputs(_extractSampleValues(sampleIdx))) {
          _clearSolidAnalysisSample(sampleIdx);
          return;
        }
        _solidAnalysisIds[sampleIdx] = data['_id']?.toString();
        _updateResultFromData(sampleIdx, data);
      });
    } catch (e) {
      debugPrint('[SolidsAnalysis] Load saved error: $e');
    }
  }

  Future<void> fetchSolidAnalysis() async {
    isSolidAnalysisLoading.value = true;
    solidAnalysisError.value = '';
    try {
      await _loadSavedSolidAnalysis();
      for (int i = 0; i < 3; i++) {
        if (_hasSolidAnalysisInputs(_extractSampleValues(i))) {
          await _saveSolidAnalysis(i);
        } else {
          _clearSolidAnalysisSample(i);
        }
      }
    } catch (e) {
      solidAnalysisError.value = e.toString();
    } finally {
      isSolidAnalysisLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // _extractSampleValues
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, double> _extractSampleValues(int index) {
    double readField(String? key) {
      if (key == null) return 0;
      final vals = propertyTable[key];
      if (vals == null || index >= vals.length) return 0;
      return _parseMudNumber(vals[index].value);
    }

    double? readLastMatchingField(bool Function(String normalizedKey) test) {
      double? value;
      for (final entry in propertyTable.entries) {
        if (!test(_normalizedKey(entry.key))) continue;
        final vals = entry.value;
        if (index >= vals.length) continue;
        final text = vals[index].value.trim();
        if (text.isEmpty) continue;
        final parsed = double.tryParse(text.replaceAll(',', ''));
        if (parsed != null) value = parsed;
      }
      return value;
    }

    // LGS/HGS SG: prefer table row values (L57/L58 in Excel),
    // fall back to Specific Gravity panel controllers
    final lgsTableSG = readField(_lgsTableDensityKey);
    final hgsTableSG = readField(_hgsTableDensityKey);
    final lgsPanelSG = double.tryParse(lgsSgController.text) ?? 0.0;
    final hgsPanelSG = double.tryParse(hgsSgController.text) ?? 0.0;
    final isOilMudForSg =
        selectedFluidType.value == 'Oil-based' ||
        selectedFluidType.value == 'Synthetic';
    final lgsUsed = isOilMudForSg
        ? (lgsPanelSG > 0 ? lgsPanelSG : lgsTableSG)
        : (lgsTableSG > 0 ? lgsTableSG : lgsPanelSG);
    final hgsUsed = isOilMudForSg
        ? (hgsPanelSG > 0 ? hgsPanelSG : hgsTableSG)
        : (hgsTableSG > 0 ? hgsTableSG : hgsPanelSG);
    final chloridesMgl = readField(_chloridesForSolidsKey);
    final waterVol = readField(_waterKey);
    final saltWaterVol = _oilSaltWaterBasisForSample(index, waterVol);
    final calciumMgl = readField(_wholeMudCaKey);
    final mixedSalt = _isMixedSaltType()
        ? _mixedSaltValues(chloridesMgl, calciumMgl, saltWaterVol)
        : null;
    final cacl2Pct = mixedSalt?.cacl2Wt ?? readField(_cacl2PctWtKey);
    final sodiumFormateWt = readField(_sodiumFormateWtKey);
    final rawNaclPct = _isNaclSaltType()
        ? _naclWtFromChlorideWater(chloridesMgl, saltWaterVol)
        : 0.0;
    final naclPct =
        mixedSalt?.naclWt ??
        (rawNaclPct > 0 ? rawNaclPct : readField(_naclPctWtKey));
    final wpsPpm = readField(_wpsSaltPercentKey);
    final saltPctForSolids = _isMixedSaltType()
        ? (mixedSalt?.saltContent ?? (cacl2Pct + naclPct))
        : _isSodiumFormateSaltType()
        ? sodiumFormateWt
        : (cacl2Pct > 0
              ? cacl2Pct
              : (naclPct > 0 ? naclPct : (wpsPpm > 0 ? wpsPpm / 10000 : 0.0)));
    final displayedBrineContent = readLastMatchingField(
      (k) =>
          k == 'brine content' ||
          k == 'brine content (%)' ||
          (k.contains('brine') && k.contains('content')),
    );
    final displayedBrineDensity = readLastMatchingField(
      (k) =>
          k == 'brine density' ||
          k.contains('brine density') ||
          k == 'brine density (sg)' ||
          k == 'brine sg',
    );
    final displayedCorrectedSolids = readLastMatchingField(
      (k) =>
          k.contains('solids adjusted') ||
          k.contains('adjusted for salt') ||
          k.contains('corrected solids') ||
          k.contains('corr. solids'),
    );

    return {
      'mudWeight': readField(_mwKey),
      'retortSolids': readField(_solidsKey), // Total Solids % (L44)
      'oilVol': readField(_oilKey), // Oil % vol (L46)
      'waterVol': waterVol, // Water % vol
      'bariteLb': readField(_bariteKey),
      'bentoniteLb': readField(_bentoniteKey),
      'mbt': readField(_mbtKey),
      'chloridesMgl': chloridesMgl,
      'makeupChloridesMgl': readField(_makeupWaterChloridesKey),
      'calciumMgl': calciumMgl,
      'pm': readField(_wholeMudAlkKey),
      'wpsPpm': wpsPpm,
      'saltWaterVol': saltWaterVol,
      'cacl2Pct': saltPctForSolids, // CaCl2 % wt, or derived from chlorides
      'naclPct': naclPct,
      'brineVolPct':
          displayedBrineContent ??
          readField(_brineVolPctKey), // Brine % vol (L62) if exists
      'brineDensityPpg':
          displayedBrineDensity ?? readField(_brineDensitySgKey),
      'corrSolidsPct':
          displayedCorrectedSolids ??
          readField(_corrSolidsValueKey), // Corrected Solids % (L45)
      'oilSG': double.tryParse(oilSgController.text) ?? 0.0,
      'hgsSG': hgsUsed, // L58 — HGS density
      'lgsSG': lgsUsed, // L57 — LGS density
      'shaleCec': double.tryParse(shaleCecController.text) ?? 0.0,
      'bentCec': double.tryParse(bentCecController.text) ?? 0.0,
      'isWeightedMud': _effectiveWeightedMudForSolids() ? 1.0 : 0.0,
    };
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    final d = double.tryParse(v.toString());
    return d == null ? v.toString() : formatMudNumericValue(d);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD / REMOVE ROWS
  // ═══════════════════════════════════════════════════════════════════════════

  void addPropertyRow(String name) {
    if (name.isEmpty || propertyTable.containsKey(name)) return;
    propertyTable[name] = List.generate(samples.length, (_) => ''.obs);
    _setupAutoCalculations();
    _setupSolidAnalysisWatchers();
    _setupMudStateWatchers();
    _scheduleAllSolidAnalysisSamples();
    _scheduleMudReportSave();
  }

  void removeAddedPropertyRow(String name) {
    if (name.isEmpty) return;
    propertyTable.remove(name);
    _setupMudStateWatchers();
    _scheduleMudReportSave();
  }

  bool isPropertyRemovable(String name) => !_basePropertyNames.contains(name);

  Future<void> changeFluidType(String type) async {
    final normalized = type.trim();
    if (normalized.isEmpty || normalized == selectedFluidType.value) return;
    final previousTable = _stringTable(propertyTable);
    final previousUnits = Map<String, String>.from(propertyUnits);
    _mudStateSaveTimer?.cancel();
    _isApplyingSavedState = true;
    try {
      selectedFluidType.value = normalized;
      await loadFluidTypeData(applySavedState: false);
      _restorePropertyValues(previousTable, previousUnits);
      _setupAutoCalculations();
      _setupSolidAnalysisWatchers();
      _setupMudStateWatchers();
    } finally {
      _isApplyingSavedState = false;
    }
    _scheduleAllSolidAnalysisSamples();
    _scheduleMudReportSave();
  }

  Future<void> changeSaltType(String type) async {
    final normalized = type.trim();
    if (normalized.isEmpty || normalized == selectedSaltType.value) return;
    selectedSaltType.value = normalized;
    if (selectedFluidType.value != 'Oil-based' &&
        selectedFluidType.value != 'Synthetic') {
      _scheduleMudReportSave();
      return;
    }

    final previousTable = _stringTable(propertyTable);
    final previousUnits = Map<String, String>.from(propertyUnits);
    _mudStateSaveTimer?.cancel();
    _isApplyingSavedState = true;
    try {
      propertyTable.clear();
      propertyUnits.clear();
      availableProperties.clear();
      solidAnalysisResult.clear();
      for (int i = 0; i < 3; i++) {
        _solidAnalysisIds[i] = null;
      }

      await Future.wait([
        _loadLeftTableFromMudProperties(),
        _loadDropdownFromOthers(),
      ]);
      _basePropertyNames
        ..clear()
        ..addAll(propertyTable.keys);
      _restorePropertyValues(previousTable, previousUnits);
      _setupAutoCalculations();
      _setupSolidAnalysisWatchers();
      _setupMudStateWatchers();
    } finally {
      _isApplyingSavedState = false;
    }
    _scheduleAllSolidAnalysisSamples();
    _scheduleMudReportSave();
  }

  Future<void> changeWeightedMud(bool value) async {
    if (isWeightedMud.value == value) return;
    isWeightedMud.value = value;
    _setupAutoCalculations();
    await fetchSolidAnalysis();
    _scheduleMudReportSave();
  }

  void _restorePropertyValues(
    Map<String, List<String>> previousTable,
    Map<String, String> previousUnits,
  ) {
    for (final entry in propertyTable.entries) {
      final values = previousTable[entry.key];
      if (values == null) continue;
      for (int i = 0; i < entry.value.length && i < values.length; i++) {
        entry.value[i].value = values[i];
      }
    }
    for (final entry in previousUnits.entries) {
      if (propertyUnits.containsKey(entry.key) && entry.value.isNotEmpty) {
        propertyUnits[entry.key] = entry.value;
      }
    }
  }

  Future<bool> importMudPlanPropertiesFromInterval(String intervalId) async {
    final cleanIntervalId = intervalId.trim();
    if (_wellId.isEmpty || cleanIntervalId.isEmpty) return false;

    final preservedPropertySamples = _captureSampleValues(
      propertyTable,
      const [0, 1, 2],
    );
    final preservedRheologySamples = _captureSampleValues(
      rheologyTable,
      const [0, 1, 2],
    );

    final sourceReportId = _effectiveReportIdForScope(
      'interval:$cleanIntervalId',
    );
    final sourceCacheKey = _mudStateCacheKeyForReportId(sourceReportId);
    final sourceState =
        _stateCache[sourceCacheKey] ??
        await _fetchMudReportState(reportIdOverride: sourceReportId);
    if (sourceState == null) return false;

    final sourceProperties = _mapFromDynamic(sourceState['propertyTable']);
    if (sourceProperties.isEmpty) return false;

    final sourceFluidType = (sourceState['fluidType'] ?? '').toString().trim();
    final nextFluidType = sourceFluidType.isEmpty
        ? selectedFluidType.value
        : sourceFluidType;
    final sourceSaltType = (sourceState['saltType'] ?? '').toString().trim();

    isLoading.value = true;
    _mudStateSaveTimer?.cancel();
    _isApplyingSavedState = true;
    try {
      selectedFluidType.value = nextFluidType;
      if (sourceSaltType.isNotEmpty) {
        selectedSaltType.value = sourceSaltType;
      }
      _clearMudBottomSections();
      propertyTable.clear();
      propertyUnits.clear();
      availableProperties.clear();
      solidAnalysisResult.clear();
      for (int i = 0; i < 3; i++) {
        _solidAnalysisIds[i] = null;
      }

      await Future.wait([
        _loadLeftTableFromMudProperties(),
        _loadDropdownFromOthers(),
      ]);
      _basePropertyNames
        ..clear()
        ..addAll(propertyTable.keys);

      _applyMudPropertyState(sourceState);
      _restoreSampleValues(propertyTable, preservedPropertySamples);
      _restoreSampleValues(rheologyTable, preservedRheologySamples);
      _setupAutoCalculations();
      _setupSolidAnalysisWatchers();
      _setupMudStateWatchers();
    } finally {
      _isApplyingSavedState = false;
      isLoading.value = false;
    }

    _cacheCurrentMudState();
    await saveMudReportState(force: true);
    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RHEOLOGY
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> importMudPlanRheologyFromInterval(String intervalId) async {
    final cleanIntervalId = intervalId.trim();
    if (_wellId.isEmpty || cleanIntervalId.isEmpty) return false;

    final preservedRheologySamples = _captureSampleValues(
      rheologyTable,
      const [0, 1, 2],
    );

    final sourceReportId = _effectiveReportIdForScope(
      'interval:$cleanIntervalId',
    );
    final sourceCacheKey = _mudStateCacheKeyForReportId(sourceReportId);
    final sourceState =
        _stateCache[sourceCacheKey] ??
        await _fetchMudReportState(reportIdOverride: sourceReportId);
    if (sourceState == null) return false;

    final sourceRheology = _mapFromDynamic(sourceState['rheologyTable']);
    if (sourceRheology.isEmpty) return false;

    final sourceModel = (sourceState['rheologyModel'] ?? '').toString().trim();
    final sourceCalculation = (sourceState['rheologyCalculation'] ?? '')
        .toString()
        .trim();

    isLoading.value = true;
    _mudStateSaveTimer?.cancel();
    _isApplyingSavedState = true;
    try {
      if (sourceModel.isNotEmpty) {
        rheologyModel.value = sourceModel;
      }
      if (sourceCalculation.isNotEmpty) {
        rheologyCalculation.value = sourceCalculation;
      }

      rheologyTable.clear();
      final canonicalRows = _rheologyRowsForModel(rheologyModel.value);
      final orderedKeys = <String>[
        ...canonicalRows,
        ...sourceRheology.keys
            .map((key) => key.toString())
            .where((key) => !canonicalRows.contains(key)),
      ];
      for (final key in orderedKeys) {
        final value = sourceRheology[key];
        final values = _listFromDynamic(value);
        rheologyTable[key] = List.generate(
          samples.length,
          (index) => (index < values.length ? values[index] : '').obs,
        );
      }
      _restoreSampleValues(rheologyTable, preservedRheologySamples);
      calculateRheology();
      rheologyTable.refresh();
    } finally {
      _isApplyingSavedState = false;
      isLoading.value = false;
    }

    _cacheCurrentMudState();
    await saveMudReportState(force: true);
    return true;
  }

  void _initRheologyTable() => _updateRheologyRows(preserveValues: false);

  void changeModel(String model) {
    rheologyModel.value = model;
    _updateRheologyRows();
    calculateRheology();
    _setupMudStateWatchers();
    _scheduleMudReportSave();
  }

  void _updateRheologyRows({bool preserveValues = true}) {
    final rows = _rheologyRowsForModel(rheologyModel.value);
    final previousValues = <String, List<String>>{};
    if (preserveValues) {
      for (final entry in rheologyTable.entries) {
        previousValues[entry.key] = entry.value
            .map((cell) => cell.value)
            .toList();
      }
    }
    rheologyTable.clear();
    for (var r in rows) {
      final previousRow = previousValues[r];
      rheologyTable[r] = List.generate(
        samples.length,
        (index) =>
            (previousRow != null && index < previousRow.length
                    ? previousRow[index]
                    : '')
                .obs,
      );
    }
    _setupMudStateWatchers();
  }

  List<String> _rheologyRowsForModel(String model) {
    if (model == 'Bingham') {
      return const [
        '600',
        '300',
        '200',
        '100',
        '6',
        '3',
        'PV (cP)',
        'YP (lbf/100ft2)',
      ];
    }
    if (model == 'Power Law') {
      return const [
        '600',
        '300',
        '200',
        '100',
        '6',
        '3',
        'n',
        'K (lbf-s^n/100ft2)',
      ];
    }
    return const [
      '600',
      '300',
      '200',
      '100',
      '6',
      '3',
      'Yield Stress (lbf/100ft2)',
      'n',
      'K (lbf-s^n/100ft2)',
    ];
  }

  void calculateRheology() {
    for (int i = 0; i < samples.length; i++) {
      final r600 = double.tryParse(rheologyTable['600']?[i].value ?? '') ?? 0;
      final r300 = double.tryParse(rheologyTable['300']?[i].value ?? '') ?? 0;
      final r3 = double.tryParse(rheologyTable['3']?[i].value ?? '') ?? 0;
      final r6 = double.tryParse(rheologyTable['6']?[i].value ?? '') ?? 0;
      switch (rheologyModel.value) {
        case 'Bingham':
          if (r600 <= 0 || r300 <= 0) {
            _clearRheologyRows(i, const ['PV (cP)', 'YP (lbf/100ft2)']);
          } else {
            final pv = r600 - r300;
            rheologyTable['PV (cP)']?[i].value = formatMudNumericValue(
              pv,
              fallbackDigits: 1,
            );
            rheologyTable['YP (lbf/100ft2)']?[i].value =
                formatMudNumericValue(r300 - pv, fallbackDigits: 1);
          }
          break;
        case 'Power Law':
          if (r600 <= 0 || r300 <= 0) {
            _clearRheologyRows(i, const ['n', 'K (lbf-s^n/100ft2)']);
          } else {
            final n = 3.32 * _log10(r600 / r300);
            final k = r600 / _pow(1022, n);
            rheologyTable['n']?[i].value = formatMudNumericValue(
              n,
              fallbackDigits: 3,
            );
            rheologyTable['K (lbf-s^n/100ft2)']?[i].value =
                formatMudNumericValue(
              k,
              fallbackDigits: 3,
            );
          }
          break;
        case 'HB':
          final yieldStress = r3 > 0 && r6 > 0
              ? (2 * r3 - r6).clamp(0.0, double.infinity).toDouble()
              : 0.0;
          if (r3 <= 0 || r6 <= 0) {
            _clearRheologyRows(i, const ['Yield Stress (lbf/100ft2)']);
          } else {
            rheologyTable['Yield Stress (lbf/100ft2)']?[i].value =
                formatMudNumericValue(yieldStress, fallbackDigits: 2);
          }
          final adjusted600 = r600 - yieldStress;
          final adjusted300 = r300 - yieldStress;
          if (r600 <= 0 || r300 <= 0 || adjusted600 <= 0 || adjusted300 <= 0) {
            _clearRheologyRows(i, const ['n', 'K (lbf-s^n/100ft2)']);
          } else {
            final n = 3.32 * _log10(adjusted600 / adjusted300);
            final k = adjusted600 / _pow(1022, n);
            rheologyTable['n']?[i].value = formatMudNumericValue(
              n,
              fallbackDigits: 3,
            );
            rheologyTable['K (lbf-s^n/100ft2)']?[i].value =
                formatMudNumericValue(
              k,
              fallbackDigits: 3,
            );
          }
          break;
      }
    }
    rheologyTable.refresh();
  }

  void handleRheologyInputChanged(int sampleIndex) {
    final r600 = rheologyTable['600']?[sampleIndex].value.trim() ?? '';
    final r300 = rheologyTable['300']?[sampleIndex].value.trim() ?? '';
    final r3 = rheologyTable['3']?[sampleIndex].value.trim() ?? '';
    final r6 = rheologyTable['6']?[sampleIndex].value.trim() ?? '';
    switch (rheologyModel.value) {
      case 'Bingham':
        if (r600.isEmpty || r300.isEmpty) {
          _clearRheologyRows(sampleIndex, const ['PV (cP)', 'YP (lbf/100ft2)']);
        }
        break;
      case 'Power Law':
        if (r600.isEmpty || r300.isEmpty) {
          _clearRheologyRows(sampleIndex, const ['n', 'K (lbf-s^n/100ft2)']);
        }
        break;
      case 'HB':
        if (r3.isEmpty || r6.isEmpty) {
          _clearRheologyRows(sampleIndex, const ['Yield Stress (lbf/100ft2)']);
        }
        if (r600.isEmpty || r300.isEmpty) {
          _clearRheologyRows(sampleIndex, const ['n', 'K (lbf-s^n/100ft2)']);
        }
        break;
    }
    calculateRheology();
    _scheduleMudReportSave();
  }

  void _clearRheologyRows(int sampleIndex, List<String> rows) {
    for (final row in rows) {
      final values = rheologyTable[row];
      if (values != null && sampleIndex < values.length) {
        values[sampleIndex].value = '';
      }
    }
  }

  void transferRheologyToPropertyTable() {
    for (final entry in rheologyTable.entries) {
      if (double.tryParse(entry.key) != null) continue;
      for (final propKey in propertyTable.keys) {
        if (_rowMatches(propKey, entry.key)) {
          final propList = propertyTable[propKey]!;
          for (int j = 0; j < entry.value.length && j < propList.length; j++) {
            final val = entry.value[j].value;
            if (val.isNotEmpty) propList[j].value = val;
          }
        }
      }
    }
    propertyTable.refresh();
  }

  bool _rowMatches(String rowName, String rheologyKey) {
    final rn = rowName.toLowerCase().replaceAll('*', '').trim();
    final rk = rheologyKey.toLowerCase().trim();
    if (rk == 'pv (cp)' || rk == 'pv') return rn == 'pv' || rn == 'pv (cp)';
    if (rk == 'yp (lbf/100ft2)' || rk == 'yp')
      return rn == 'yp' || rn == 'yp (lbf/100ft2)';
    if (rk == 'n' && rn == 'n') return true;
    if (rk.contains('yield stress') && rn.contains('yield')) return true;
    if (rk.contains('k (') && rn.contains('k (')) return true;
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REACTIVE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _watchOneOpt(
    int si,
    String? src,
    String? target,
    String Function(String) fn,
  ) {
    if (src == null || target == null) return;
    final s = propertyTable[src];
    final t = propertyTable[target];
    if (s == null || t == null || si >= s.length || si >= t.length) return;
    t[si].value = fn(s[si].value);
    ever(s[si], (_) => t[si].value = fn(s[si].value));
  }

  void _watchTwoOpt(
    int si,
    String? srcA,
    String? srcB,
    String? target,
    String Function(String, String) fn,
  ) {
    if (srcA == null || srcB == null || target == null) return;
    final a = propertyTable[srcA];
    final b = propertyTable[srcB];
    final t = propertyTable[target];
    if (a == null ||
        b == null ||
        t == null ||
        si >= a.length ||
        si >= b.length ||
        si >= t.length)
      return;
    t[si].value = fn(a[si].value, b[si].value);
    ever(a[si], (_) => t[si].value = fn(a[si].value, b[si].value));
    ever(b[si], (_) => t[si].value = fn(a[si].value, b[si].value));
  }

  void _watchOne(
    int si,
    String? src,
    String target,
    String Function(String) fn,
  ) => _watchOneOpt(si, src, target, fn);
  void _watchTwo(
    int si,
    String? srcA,
    String? srcB,
    String target,
    String Function(String, String) fn,
  ) => _watchTwoOpt(si, srcA, srcB, target, fn);

  // ═══════════════════════════════════════════════════════════════════════════
  // MATH HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  double _log10(double x) => x > 0 ? math.log(x) / math.ln10 : 0;

  double _cacl2BrineSg(double saltWtPct) =>
      0.99707 + (0.007923 * saltWtPct) + (0.00004964 * saltWtPct * saltWtPct);

  double _naclBrineSg(double saltWtPct) => 1 + (0.0075127 * saltWtPct);

  double _naclWaterActivity(double saltWtPct) => 1 - (0.0094 * saltWtPct);

  double _cacl2WaterActivity(double saltWtPct) {
    const a = -3.5566e-3;
    const b = -2.3126e-4;
    const c = -1.4330e-6;
    final aw =
        1 +
        (a * saltWtPct) +
        (b * saltWtPct * saltWtPct) +
        (c * saltWtPct * saltWtPct * saltWtPct);
    return aw.clamp(0.0, 1.0).toDouble();
  }

  double _mixedBrineSg(double cacl2Wt, double naclWt) {
    if (cacl2Wt <= 0) return _naclBrineSg(naclWt);
    if (naclWt <= 0) return _cacl2BrineSg(cacl2Wt);
    return 0.99707 +
        (0.0006504 * naclWt) +
        (0.007923 * cacl2Wt) +
        (0.000008334 * naclWt * cacl2Wt) +
        (0.000004395 * naclWt * naclWt) +
        (0.00004964 * cacl2Wt * cacl2Wt);
  }

  double _interpolateTable(Map<double, double> table, double x) {
    if (table.isEmpty) return 0.0;
    final keys = table.keys.toList()..sort();
    if (keys.length == 1) return table[keys.first] ?? 0.0;

    double interpolate(double lo, double hi) {
      final loValue = table[lo] ?? 0.0;
      final hiValue = table[hi] ?? loValue;
      final t = hi == lo ? 0.0 : (x - lo) / (hi - lo);
      return loValue + ((hiValue - loValue) * t);
    }

    if (x <= keys.first) return interpolate(keys[0], keys[1]);
    if (x >= keys.last) {
      return interpolate(keys[keys.length - 2], keys.last);
    }

    for (var i = 1; i < keys.length; i++) {
      if (x <= keys[i]) return interpolate(keys[i - 1], keys[i]);
    }
    return table[keys.last] ?? 0.0;
  }

  double _inverseInterpolateTable(Map<double, double> table, double y) {
    if (table.isEmpty) return 0.0;
    final keys = table.keys.toList()..sort();
    if (keys.length == 1) return keys.first;

    double interpolateKey(double lo, double hi) {
      final loValue = table[lo] ?? 0.0;
      final hiValue = table[hi] ?? loValue;
      final t = hiValue == loValue ? 0.0 : (y - loValue) / (hiValue - loValue);
      return lo + ((hi - lo) * t);
    }

    final firstValue = table[keys.first] ?? 0.0;
    final lastValue = table[keys.last] ?? firstValue;
    if (y <= firstValue) return interpolateKey(keys[0], keys[1]);
    if (y >= lastValue) {
      return interpolateKey(keys[keys.length - 2], keys.last);
    }

    for (var i = 1; i < keys.length; i++) {
      final hiValue = table[keys[i]] ?? 0.0;
      if (y <= hiValue) return interpolateKey(keys[i - 1], keys[i]);
    }
    return keys.last;
  }

  _SodiumFormateResult _sodiumFormateValues({
    required double chloridesMgl,
    required double waterVol,
    required double pm,
  }) {
    final cleanWater = waterVol <= 0 ? 0.0 : waterVol;
    final waterPhaseSalinity = cleanWater <= 0
        ? 0.0
        : chloridesMgl * 100 / cleanWater;
    const brinePhaseCorrection = 0.9981;
    final brinePhaseChlorides = waterPhaseSalinity * brinePhaseCorrection;
    final formateWt = _inverseInterpolateTable(
      _sodiumFormateMgLByWt,
      waterPhaseSalinity,
    ).clamp(0.0, 49.5).toDouble();
    final formateMgL = _interpolateTable(_sodiumFormateMgLByWt, formateWt);
    final brineSg = _interpolateTable(_sodiumFormateSgByWt, formateWt);
    final brineDensityPpg = brineSg * 8.345;
    final dissolvedSolidsPct = math.max(0.0, (0.1 * formateWt) + 0.4);
    final saltContent = cleanWater + dissolvedSolidsPct;
    final waterActivity = _sodiumFormateWaterActivity(formateWt);

    return _SodiumFormateResult(
      brinePhaseChlorides: brinePhaseChlorides,
      saltContent: saltContent,
      wpsPpm: waterPhaseSalinity,
      formateWt: formateWt,
      formateMgL: formateMgL,
      brineDensityPpg: brineDensityPpg,
      brineSg: brineSg,
      dissolvedSolidsPct: dissolvedSolidsPct,
      waterActivity: waterActivity,
    );
  }

  double _sodiumFormateWaterActivity(double wtPercent) {
    return _interpolateTable(_sodiumFormateAwByWt, wtPercent)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  _OilSaltResult? _oilSaltResult({
    required double chloridesMgl,
    required double calciumMgl,
    required double waterVol,
    required double retortSolids,
    required double cacl2Pct,
    required double naclPct,
    required double wpsPpm,
    required double pm,
  }) {
    if (waterVol <= 0) return null;

    double saltWtPct = 0;
    double brineSG = 1;
    double waterActivity = 0;

    if (_isMixedSaltType()) {
      final mixed = _mixedSaltValues(chloridesMgl, calciumMgl, waterVol);
      if (mixed != null) {
        saltWtPct = mixed.saltContent;
        brineSG = mixed.brineSg;
        waterActivity = mixed.waterActivity;
      } else {
        saltWtPct = cacl2Pct > 0 ? cacl2Pct : naclPct;
        brineSG = cacl2Pct > 0 ? _cacl2BrineSg(cacl2Pct) : _naclBrineSg(naclPct);
        waterActivity = _naclWaterActivity(saltWtPct);
      }
    } else if (_isNaclSaltType()) {
      saltWtPct = _naclWtFromChlorideWater(chloridesMgl, waterVol);
      if (saltWtPct <= 0) {
        saltWtPct = naclPct > 0 ? naclPct : (wpsPpm > 0 ? wpsPpm / 10000 : 0);
      }
      brineSG = saltWtPct > 0 ? _naclBrineSg(saltWtPct) : 1;
      waterActivity = _naclWaterActivity(saltWtPct);
    } else if (_isSodiumFormateSaltType()) {
      final formate = _sodiumFormateValues(
        chloridesMgl: chloridesMgl,
        waterVol: waterVol,
        pm: pm,
      );
      saltWtPct = formate.formateWt;
      brineSG = formate.brineSg;
      waterActivity = formate.waterActivity;
      final correctedSolidsPct = retortSolids - formate.dissolvedSolidsPct;
      return _OilSaltResult(
        saltWtPct: saltWtPct,
        brineSG: brineSG,
        brineVolPct: formate.saltContent,
        dissolvedSolidsPct: formate.dissolvedSolidsPct,
        correctedSolidsPct: correctedSolidsPct < 0 ? 0 : correctedSolidsPct,
        waterActivity: waterActivity < 0 ? 0 : waterActivity,
      );
    } else {
      if (cacl2Pct > 0) {
        saltWtPct = cacl2Pct;
      } else if (wpsPpm > 0) {
        saltWtPct = wpsPpm / 10000;
      } else if (chloridesMgl > 0) {
        final frac =
            _pureCacl2ChlorideConversionFactor * chloridesMgl / 10000;
        saltWtPct = frac + waterVol == 0 ? 0 : 100 * frac / (frac + waterVol);
      }
      brineSG = saltWtPct > 0 ? _cacl2BrineSg(saltWtPct) : 1;
      waterActivity = _cacl2WaterActivity(saltWtPct);
    }

    if (saltWtPct <= 0 || brineSG <= 0) return null;
    final waterFraction = (1 - saltWtPct / 100) * brineSG;
    if (waterFraction <= 0) return null;
    final calculatedBrineVolPct = waterVol / waterFraction;
    final brineVolPct = calculatedBrineVolPct;
    final dissolvedSolidsPct = (_isNaclSaltType() || _isMixedSaltType())
        ? brineVolPct * saltWtPct / 100
        : brineVolPct - waterVol;
    final correctedSolidsPct = retortSolids - dissolvedSolidsPct;

    return _OilSaltResult(
      saltWtPct: saltWtPct,
      brineSG: brineSG,
      brineVolPct: brineVolPct,
      dissolvedSolidsPct: dissolvedSolidsPct,
      correctedSolidsPct: correctedSolidsPct < 0 ? 0 : correctedSolidsPct,
      waterActivity: waterActivity < 0 ? 0 : waterActivity,
    );
  }

  double _naclWtFromChlorideWater(double chlorides, double water) {
    if (chlorides <= 0 || water <= 0) return 0.0;
    final frac = 1.648 * chlorides / 10000;
    final denominator = frac + water;
    return denominator <= 0 ? 0.0 : (100 * frac / denominator);
  }

  _MixedSaltResult? _mixedSaltValues(
    double chlorides,
    double calcium,
    double water,
  ) {
    if (chlorides <= 0 || water <= 0) return null;
    final chlorideFromNacl = chlorides - _cacl2ChlorideFromCalcium(calcium);
    final hasNacl = calcium > 0 && chlorideFromNacl > 0;
    final cacl2WholeMudMg = hasNacl
        ? (calcium > 0 ? _cacl2MgFromCalcium(calcium) : 0.0)
        : _pureCacl2ChlorideConversionFactor * chlorides;
    final naclWholeMudMg = hasNacl ? 1.648 * chlorideFromNacl : 0.0;
    final denominator = cacl2WholeMudMg + naclWholeMudMg + (10000 * water);
    if (denominator <= 0) return null;

    final cacl2Wt = 100 * cacl2WholeMudMg / denominator;
    final rawNaclWt = 100 * naclWholeMudMg / denominator;
    final maxNacl = _maxSolubleNaclWt(cacl2Wt);
    final naclWt = rawNaclWt > maxNacl ? maxNacl : rawNaclWt;
    final insolubleNaclMgL = rawNaclWt > maxNacl
        ? (rawNaclWt - maxNacl) * 10000
        : 0.0;
    final brineSg = _mixedBrineSg(cacl2Wt, naclWt);
    final saltContent = cacl2Wt + naclWt;
    final waterFraction = brineSg * (100 - saltContent);
    final brineContent = waterFraction <= 0
        ? 0.0
        : (100 * water / waterFraction);

    return _MixedSaltResult(
      cacl2Wt: cacl2Wt,
      naclWt: naclWt,
      saltContent: saltContent,
      brineSg: brineSg,
      brineContent: brineContent,
      cacl2AqMgL: 10000 * cacl2Wt * brineSg,
      naclAqMgL: 10000 * naclWt * brineSg,
      insolubleNaclMgL: insolubleNaclMgL,
      waterActivity: _mixedWaterActivity(cacl2Wt, naclWt),
    );
  }

  double _cacl2MgFromCalcium(double calciumMgL) => calciumMgL * 2.769;

  double _cacl2ChlorideFromCalcium(double calciumMgL) => calciumMgL * 1.769;

  double _maxSolubleNaclWt(double cacl2Wt) =>
      26.432 -
      (1.0472 * cacl2Wt) +
      (0.00798191 * cacl2Wt * cacl2Wt) +
      (0.000052238 * cacl2Wt * cacl2Wt * cacl2Wt);

  double _mixedWaterActivity(double cacl2Wt, double naclWt) {
    final cacl2Aw = _cacl2WaterActivity(cacl2Wt);
    final naclAw = _naclWaterActivity(naclWt);
    final total = cacl2Wt + naclWt;
    if (total <= 0) return 0;
    return ((cacl2Aw * cacl2Wt) + (naclAw * naclWt)) / total;
  }

  double _naclMgForMixedSalt(int sampleIndex) {
    final chlorideVals = _wholeMudChlorideKey != null
        ? propertyTable[_wholeMudChlorideKey!]
        : null;
    final calciumVals = _wholeMudCaKey != null
        ? propertyTable[_wholeMudCaKey!]
        : null;
    final chlorides = chlorideVals != null && sampleIndex < chlorideVals.length
        ? double.tryParse(chlorideVals[sampleIndex].value) ?? 0
        : 0;
    final calcium = calciumVals != null && sampleIndex < calciumVals.length
        ? double.tryParse(calciumVals[sampleIndex].value) ?? 0
        : 0.0;
    final chlorideFromNacl = chlorides - _cacl2ChlorideFromCalcium(calcium);
    return chlorideFromNacl <= 0 ? 0 : 1.648 * chlorideFromNacl;
  }

  double _pow(double base, double exp) =>
      base <= 0 ? 0 : math.pow(base, exp).toDouble();

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onClose() {
    for (final t in _debounceTimers.values) {
      t?.cancel();
    }
    _mudStateSaveTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _stateWorkers) {
      worker.dispose();
    }
    fluidnameController.dispose();
    oilSgController.dispose();
    hgsSgController.dispose();
    lgsSgController.dispose();
    shaleCecController.dispose();
    bentCecController.dispose();
    super.onClose();
  }
}
