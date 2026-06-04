import 'dart:async';
import 'dart:convert';
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

class MudController extends GetxController {
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
  final oilSgController = TextEditingController(text: '0.81');
  final hgsSgController = TextEditingController(text: '4.10');
  final lgsSgController = TextEditingController(text: '2.40');
  final shaleCecController = TextEditingController(text: '15.00');
  final bentCecController = TextEditingController(text: '65.00');

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
  final RxString _stateScopeKey = ''.obs;
  final Map<String, Map<String, dynamic>> _stateCache = {};

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
    try {
      final cachedState = applySavedState
          ? _stateCache[_mudStateCacheKey]
          : null;
      final savedState =
          cachedState ??
          (applySavedState ? await _fetchMudReportState() : null);
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
        'Synthetic' => selected.synthetic,
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
        'Synthetic' => selected.synthetic,
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
      if (changed) propertyUnits.refresh();
    } catch (e) {
      debugPrint('[MudController] refresh mud property units ERROR: $e');
    }
  }

  Future<void> _loadDropdownFromOthers() async {
    try {
      final data = switch (selectedFluidType.value) {
        'Water-based' => await othersController.getWaterBased(),
        'Oil-based' => await othersController.getOilBased(),
        'Synthetic' => await othersController.getSynthetic(),
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
    if (selectedFluidType.value == 'Oil-based') {
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
        key.contains('oil/sodium formate') ||
        key.contains('sodium formate brine') ||
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
          MudPropertyItem(name: 'Water Activity', unit: 'aw'),
          MudPropertyItem(name: 'Water Phase Salinity (mg/L)', unit: 'mg/L'),
          MudPropertyItem(name: 'Brine Phase Salinity (mg/L)', unit: 'mg/L'),
          MudPropertyItem(name: 'Oil/Sodium Formate Brine', unit: 'ratio'),
          MudPropertyItem(name: 'Sodium Formate Brine Phase (%)', unit: '%'),
          MudPropertyItem(name: 'Dissolved Sodium Formate (%)', unit: '%'),
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
      if (selectedFluidType.value == 'Oil-based' &&
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
      if (selectedFluidType.value == 'Oil-based' &&
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
    'isWeightedMud': isWeightedMud.value,
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
    _mudStateSaveTimer?.cancel();
    _mudStateSaveTimer = Timer(
      _kSaveDebounce,
      () => saveMudReportState(force: true),
    );
  }

  Future<void> saveMudReportState({bool force = false}) async {
    if (_wellId.isEmpty) return;
    if (!force && _isApplyingSavedState) return;
    _mudStateSaveTimer?.cancel();
    _cacheCurrentMudState();
    try {
      await http.put(
        _mudReportUri(),
        headers: ApiEndpoint.jsonHeaders,
        body: jsonEncode(_buildMudReportPayload()),
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
        return (r600 - r300).toStringAsFixed(1);
      });

      // ── 2. YP = R300 − PV ─────────────────────────────────────────────────
      _watchTwoOpt(i, _r300Key, _pvPropKey, _ypPropKey, (a, b) {
        final r300 = double.tryParse(a) ?? 0;
        final pv = double.tryParse(b) ?? 0;
        if (r300 == 0 && pv == 0) return '';
        return (r300 - pv).toStringAsFixed(1);
      });

      // ── 3. LSRYP = 2×R3 − R6 ─────────────────────────────────────────────
      _watchTwoOpt(i, _r3Key, _r6Key, _lsrypKey, (a, b) {
        final r3 = double.tryParse(a) ?? 0;
        final r6 = double.tryParse(b) ?? 0;
        if (r3 == 0 && r6 == 0) return '';
        return (2 * r3 - r6).toStringAsFixed(1);
      });

      // ── 4. Oil/Water Ratio ────────────────────────────────────────────────
      final owTarget = _owRatioKey ?? 'Oil/water Ratio';
      _watchTwoOpt(i, _oilKey, _waterKey, owTarget, (a, b) {
        final oil = double.tryParse(a) ?? 0;
        final water = double.tryParse(b) ?? 0;
        if (oil == 0 && water == 0) return '';
        final total = oil + water;
        if (total == 0) return '';
        final oilPct = (100 * oil / total).round();
        final waterPct = 100 - oilPct;
        return '$oilPct/$waterPct';
      });

      // ── 5. Solids (% vol) = 100 − (Oil% + Water%) ───────────────────────────
      //    Excel: =IF(100-(L46+L47)<100, 100-(L46+L47), "")
      //    Writes to BOTH "*Solids (% vol)" and "Total Solids" rows if they exist
      //    This is how Excel works — solids is derived from oil+water retort readings
      void calcSolids(String a, String b, String targetKey) {
        final oil = double.tryParse(a) ?? 0;
        final water = double.tryParse(b) ?? 0;
        if (oil == 0 && water == 0) {
          propertyTable[targetKey]?[i].value = '';
          return;
        }
        final solids = 100 - (oil + water);
        propertyTable[targetKey]?[i].value = solids < 100
            ? solids.toStringAsFixed(2)
            : '';
      }

      // Write to "*Solids (% vol)" row
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
          tsTarget != solidsTarget &&
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
              ? (double.tryParse(solidsVals[i].value) ?? 0.0)
              : 0.0;
          final waterVals = _waterKey != null
              ? propertyTable[_waterKey!]
              : null;
          final water = (waterVals != null && i < waterVals.length)
              ? (double.tryParse(waterVals[i].value) ?? 0.0)
              : 0.0;
          final chlorideVals = _chloridesForSolidsKey != null
              ? propertyTable[_chloridesForSolidsKey!]
              : null;
          final chlorides = (chlorideVals != null && i < chlorideVals.length)
              ? (double.tryParse(chlorideVals[i].value) ?? 0.0)
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
            if (isOilMud && selectedSaltType.value == 'Sodium Formate') {
              dissolvedSolids = dissolvedSodiumFormate;
            } else if (isOilMud) {
              final rawMixed = selectedSaltType.value == 'NaCl + CaCl2'
                  ? _mixedSaltValues(chlorides, calcium, water)
                  : null;
              final rawNaclPct = selectedSaltType.value == 'NaCl'
                  ? _naclWtFromChlorideWater(chlorides, water)
                  : 0.0;
              final saltWtPct = selectedSaltType.value == 'NaCl + CaCl2'
                  ? (rawMixed?.saltContent ?? (cacl2Pct + naclPct))
                  : selectedSaltType.value == 'NaCl'
                  ? (rawNaclPct > 0
                        ? rawNaclPct
                        : (naclPct > 0 ? naclPct : wpsPpm / 10000))
                  : (cacl2Pct > 0
                        ? cacl2Pct
                        : (naclPct > 0 ? naclPct : wpsPpm / 10000));
              if (saltWtPct > 0 && water > 0) {
                final brineSG = selectedSaltType.value == 'NaCl + CaCl2'
                    ? (rawMixed?.brineSg ?? _mixedBrineSg(cacl2Pct, naclPct))
                    : selectedSaltType.value == 'NaCl'
                    ? _naclBrineSg(saltWtPct)
                    : _cacl2BrineSg(saltWtPct);
                final brine = water / ((1 - saltWtPct / 100) * brineSG);
                dissolvedSolids = brine - water;
              } else {
                dissolvedSolids = 0.0;
              }
            } else {
              final saltMassFraction = (chlorides * 1.65) / 1000000;
              dissolvedSolids = water * saltMassFraction * (1.0 / 2.16);
            }
            final solidsAdjusted = retortSolids - dissolvedSolids;
            tgt[i].value = (solidsAdjusted < 0 ? 0.0 : solidsAdjusted)
                .toStringAsFixed(1);
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
        if (_chloridesForSolidsKey != null) {
          final chlorideList = propertyTable[_chloridesForSolidsKey!];
          if (chlorideList != null && i < chlorideList.length) {
            ever(chlorideList[i], (_) => recalcCorrectedSolids());
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

      // ── 7. Excess Lime = 0.26 × (Pm - Fw × Pf) ──────────────
      final elTarget = _excessLimeKey;
      final pmKey = _wholeMudAlkKey;
      final pfKey = _filtAlkPfKey;
      if (elTarget != null &&
          (pmKey != null || pfKey != null || _waterKey != null)) {
        final pmList = pmKey != null ? propertyTable[pmKey] : null;
        final pfList = pfKey != null ? propertyTable[pfKey] : null;
        final waterList = _waterKey != null ? propertyTable[_waterKey!] : null;
        final elList = propertyTable[elTarget];
        if (elList != null && i < elList.length) {
          double valueAt(List<RxString>? list) {
            if (list == null || i >= list.length) return 0.0;
            return double.tryParse(list[i].value) ?? 0.0;
          }

          void recalcExcessLime() {
            final pm = valueAt(pmList);
            final pf = valueAt(pfList);
            final water = valueAt(waterList);
            if (pm == 0 && pf == 0 && water == 0) {
              elList[i].value = '';
              return;
            }
            final isOilMud =
                selectedFluidType.value == 'Oil-based' ||
                selectedFluidType.value == 'Synthetic';
            final fw = water / 100;
            final rawExcessLime = isOilMud ? pm * 1.295 : 0.26 * (pm - fw * pf);
            final excessLime = rawExcessLime < 0 ? 0.0 : rawExcessLime;
            elList[i].value = excessLime.toStringAsFixed(2);
          }

          recalcExcessLime();
          if (pmList != null && i < pmList.length) {
            ever(pmList[i], (_) => recalcExcessLime());
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
            selectedSaltType.value == 'NaCl + CaCl2' &&
            _wholeMudCaKey != null) {
          _watchOneOpt(i, _wholeMudCaKey, cacl2ConcTarget, (a) {
            final calcium = double.tryParse(a) ?? 0;
            return calcium == 0
                ? ''
                : _cacl2MgFromCalcium(calcium).toStringAsFixed(0);
          });
        } else if (isOilMud &&
            selectedSaltType.value != 'NaCl' &&
            _cacl2PctWtKey != null) {
          _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, cacl2ConcTarget, (
            a,
            b,
          ) {
            final chlorides = double.tryParse(a) ?? 0;
            final water = double.tryParse(b) ?? 0;
            if (chlorides == 0 || water == 0) return '';
            final frac = 1.565 * chlorides / 10000;
            final cacl2Wt = 100 * frac / (frac + water);
            final brineSG = _cacl2BrineSg(cacl2Wt);
            return (cacl2Wt * 10000 * brineSG).toStringAsFixed(0);
          });
        } else {
          _watchOneOpt(i, _wholeMudChlorideKey, cacl2ConcTarget, (a) {
            final v = double.tryParse(a) ?? 0;
            return v == 0 ? '' : (v * 1.565).toStringAsFixed(2);
          });
        }
      }

      // ── 9. CaCl2 (% wt) = 100*(1.565*WMChl/10000)/((1.565*WMChl/10000)+Water%)
      final cacl2WtTarget = _cacl2PctWtKey;
      if (cacl2WtTarget != null &&
          selectedSaltType.value == 'NaCl + CaCl2' &&
          _wholeMudCaKey != null &&
          _waterKey != null) {
        _watchTwoOpt(i, _wholeMudCaKey, _waterKey, cacl2WtTarget, (a, b) {
          final calcium = double.tryParse(a) ?? 0;
          final water = double.tryParse(b) ?? 0;
          if (calcium == 0 || water == 0) return '';
          final cacl2Mg = _cacl2MgFromCalcium(calcium);
          final naclMg = _naclMgForMixedSalt(i);
          final denominator = cacl2Mg + naclMg + (10000 * water);
          if (denominator <= 0) return '';
          return (100 * cacl2Mg / denominator).toStringAsFixed(1);
        });
      } else if (cacl2WtTarget != null && selectedSaltType.value != 'NaCl') {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, cacl2WtTarget, (a, b) {
          final chlorides = double.tryParse(a) ?? 0;
          final water = double.tryParse(b) ?? 0;
          if (chlorides == 0) return '';
          final factor = selectedSaltType.value == 'NaCl' ? 1.648 : 1.565;
          final frac = factor * chlorides / 10000;
          if (frac + water == 0) return '';
          return (100 * frac / (frac + water)).toStringAsFixed(1);
        });
      }

      // ── 10. Water Phase Salinity ppm = CaCl2(% wt) × 10000 ───────────────
      //    FIX: _wpsSaltPercentKey now matches ANY "water phase salinity" row
      //    (field name is "Water phase Salinity (WPS)" — no 'ppm' in it)
      final saltContentTarget = _saltContentWaterPhaseKey;
      if (saltContentTarget != null &&
          selectedSaltType.value != 'Sodium Formate') {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, saltContentTarget, (
          a,
          b,
        ) {
          final chlorides = double.tryParse(a) ?? 0;
          final water = double.tryParse(b) ?? 0;
          if (chlorides == 0 || water == 0) return '';
          final factor = selectedSaltType.value == 'NaCl' ? 1.648 : 1.565;
          final frac = factor * chlorides / 10000;
          if (frac + water == 0) return '';
          return (100 * frac / (frac + water)).toStringAsFixed(1);
        });
      }

      final naclWtTarget = _naclPctWtKey;
      if (naclWtTarget != null && selectedSaltType.value == 'NaCl + CaCl2') {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, naclWtTarget, (a, b) {
          final water = double.tryParse(b) ?? 0;
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
          return (naclWt > maxNacl ? maxNacl : naclWt).toStringAsFixed(1);
        });
      } else if (naclWtTarget != null && selectedSaltType.value != 'CaCl2') {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, naclWtTarget, (a, b) {
          final chlorides = double.tryParse(a) ?? 0;
          final water = double.tryParse(b) ?? 0;
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
          final nacl = selectedSaltType.value == 'NaCl + CaCl2'
              ? totalSalt - cacl2
              : totalSalt;
          return (nacl < 0 ? 0.0 : nacl).toStringAsFixed(1);
        });
      }

      final naclConcTarget = _naclConcKey;
      if (naclConcTarget != null && _naclPctWtKey != null) {
        if (selectedSaltType.value == 'NaCl + CaCl2') {
          _watchOneOpt(i, _wholeMudChlorideKey, naclConcTarget, (a) {
            final naclMg = _naclMgForMixedSalt(i);
            return naclMg == 0 ? '' : naclMg.toStringAsFixed(0);
          });
        } else if (selectedSaltType.value == 'NaCl') {
          _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, naclConcTarget, (
            a,
            b,
          ) {
            final naclWt = _naclWtFromChlorideWater(
              double.tryParse(a) ?? 0,
              double.tryParse(b) ?? 0,
            );
            if (naclWt == 0) return '';
            return (naclWt * 10000 * _naclBrineSg(naclWt)).toStringAsFixed(0);
          });
        } else {
          _watchOneOpt(i, _naclPctWtKey, naclConcTarget, (a) {
            final naclWt = double.tryParse(a) ?? 0;
            if (naclWt == 0) return '';
            return (naclWt * 10000 * _naclBrineSg(naclWt)).toStringAsFixed(0);
          });
        }
      }

      final insolubleNaclTarget = _insolubleNaclKey;
      if (insolubleNaclTarget != null && _naclConcKey != null) {
        if (selectedSaltType.value == 'NaCl + CaCl2') {
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
                ? (naclWt - maxNacl).toStringAsFixed(1)
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
          selectedSaltType.value != 'NaCl + CaCl2' &&
          selectedSaltType.value != 'Sodium Formate') {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, waterActivityTarget, (
          a,
          b,
        ) {
          final chlorides = double.tryParse(a) ?? 0;
          final water = double.tryParse(b) ?? 0;
          if (chlorides == 0 || water == 0) return '';
          final factor = selectedSaltType.value == 'NaCl' ? 1.648 : 1.565;
          final frac = factor * chlorides / 10000;
          if (frac + water == 0) return '';
          final saltWtPct = 100 * frac / (frac + water);
          final activity = selectedSaltType.value == 'NaCl'
              ? _naclWaterActivity(saltWtPct)
              : 1 - (0.0101626 * saltWtPct);
          return (activity < 0 ? 0.0 : activity).toStringAsFixed(2);
        });
      }

      final wpsTarget = _wpsSaltPercentKey;
      if (wpsTarget != null &&
          selectedSaltType.value == 'NaCl' &&
          _wholeMudChlorideKey != null &&
          _waterKey != null) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, wpsTarget, (a, b) {
          final naclWt = _naclWtFromChlorideWater(
            double.tryParse(a) ?? 0,
            double.tryParse(b) ?? 0,
          );
          if (naclWt == 0) return '';
          return (10000 * naclWt).toStringAsFixed(0);
        });
      } else if (wpsTarget != null &&
          selectedSaltType.value != 'Sodium Formate' &&
          selectedSaltType.value != 'NaCl + CaCl2' &&
          _wholeMudChlorideKey != null &&
          _waterKey != null) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, wpsTarget, (a, b) {
          final chlorides = double.tryParse(a) ?? 0;
          final water = double.tryParse(b) ?? 0;
          if (chlorides == 0 || water == 0) return '';
          final frac = 1.565 * chlorides / 10000;
          if (frac + water == 0) return '';
          return (100 * frac / (frac + water) * 10000).toStringAsFixed(0);
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
          wpsList[i].value = s0 == 0 ? '' : (s0 * 10000).toStringAsFixed(0);
          // Watch changes
          ever(cacl2List[i], (_) {
            final s = double.tryParse(cacl2List[i].value) ?? 0;
            wpsList[i].value = s == 0 ? '' : (s * 10000).toStringAsFixed(0);
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
            wpsLList[i].value = (s * 10000 * bSG).toStringAsFixed(0);
          }

          calcWpsMgl();
          ever(cacl2List[i], (_) => calcWpsMgl());
        }
      }

      // ── 12. Brine Density (SG) row ────────────────────────────────────────
      final bdTarget = _brineDensitySgKey;
      if (bdTarget != null && selectedSaltType.value != 'NaCl + CaCl2') {
        if (selectedSaltType.value == 'NaCl' &&
            _wholeMudChlorideKey != null &&
            _waterKey != null) {
          _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, bdTarget, (a, b) {
            final naclWt = _naclWtFromChlorideWater(
              double.tryParse(a) ?? 0,
              double.tryParse(b) ?? 0,
            );
            if (naclWt == 0) return '';
            return (_naclBrineSg(naclWt) * 8.345).toStringAsFixed(2);
          });
        } else {
          final densitySource = selectedSaltType.value == 'NaCl + CaCl2'
              ? (_naclPctWtKey ?? _cacl2PctWtKey)
              : (_cacl2PctWtKey ?? _naclPctWtKey);
          _watchOneOpt(i, densitySource, bdTarget, (a) {
            final s = double.tryParse(a) ?? 0;
            if (s == 0) return '';
            final brineSG = densitySource == _naclPctWtKey
                ? _naclBrineSg(s)
                : _cacl2BrineSg(s);
            return (brineSG * 8.345).toStringAsFixed(2);
          });
        }
      }

      // ── WBM-only ──────────────────────────────────────────────────────────
      final brineContentTarget = _brineContentKey;
      if (brineContentTarget != null &&
          selectedSaltType.value != 'NaCl + CaCl2') {
        if (selectedSaltType.value == 'NaCl' &&
            _wholeMudChlorideKey != null &&
            _waterKey != null) {
          _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, brineContentTarget, (
            a,
            b,
          ) {
            final water = double.tryParse(b) ?? 0;
            final saltWtPct = _naclWtFromChlorideWater(
              double.tryParse(a) ?? 0,
              water,
            );
            if (saltWtPct == 0 || water == 0) return '';
            final waterFraction =
                (1 - saltWtPct / 100) * _naclBrineSg(saltWtPct);
            if (waterFraction <= 0) return '';
            return (water / waterFraction).toStringAsFixed(1);
          });
        } else {
          final brineSource = selectedSaltType.value == 'NaCl + CaCl2'
              ? (_naclPctWtKey ?? _cacl2PctWtKey)
              : (_cacl2PctWtKey ?? _naclPctWtKey);
          _watchTwoOpt(i, brineSource, _waterKey, brineContentTarget, (a, b) {
            final saltWtPct = double.tryParse(a) ?? 0;
            final water = double.tryParse(b) ?? 0;
            if (saltWtPct == 0 || water == 0) return '';
            final brineSG = brineSource == _naclPctWtKey
                ? _naclBrineSg(saltWtPct)
                : _cacl2BrineSg(saltWtPct);
            final waterFraction = (1 - saltWtPct / 100) * brineSG;
            if (waterFraction <= 0) return '';
            return (water / waterFraction).toStringAsFixed(1);
          });
        }
      }

      if (selectedSaltType.value == 'NaCl + CaCl2') {
        _setupMixedSaltCalculations(i);
      }

      if (selectedFluidType.value == 'Water-based') {
        // Mud Chlorides = 10000 × CaCl2%
        final mudChlTarget = _mudChloridesMglKey;
        if (mudChlTarget != null) {
          _watchOneOpt(i, _cacl2PctWtKey, mudChlTarget, (a) {
            final v = double.tryParse(a) ?? 0;
            return v == 0 ? '' : (v * 10000).toStringAsFixed(0);
          });
        }

        // KCl = 10000 × CaCl2% × BrineSG
        final kclTarget = _kclKey;
        if (kclTarget != null) {
          _watchOneOpt(i, _cacl2PctWtKey, kclTarget, (a) {
            final s = double.tryParse(a) ?? 0;
            if (s == 0) return '';
            final bSG = _cacl2BrineSg(s);
            return (s * 10000 * bSG).toStringAsFixed(0);
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
      final water = double.tryParse(waterList[sampleIndex].value) ?? 0;
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

      setValue(_cacl2ConcKey, mixed.cacl2AqMgL.toStringAsFixed(0));
      setValue(_cacl2PctWtKey, mixed.cacl2Wt.toStringAsFixed(1));
      setValue(_naclConcKey, mixed.naclAqMgL.toStringAsFixed(0));
      setValue(_naclPctWtKey, mixed.naclWt.toStringAsFixed(1));
      setValue(_insolubleNaclKey, mixed.insolubleNaclMgL.toStringAsFixed(0));
      setValue(
        _wpsSaltPercentKey,
        (10000 * mixed.saltContent).toStringAsFixed(0),
      );
      setValue(_brineDensitySgKey, (mixed.brineSg * 8.345).toStringAsFixed(2));
      setValue(
        _brineContentKey,
        mixed.brineContent == 0 ? '' : mixed.brineContent.toStringAsFixed(1),
      );
      setValue(_saltContentWaterPhaseKey, mixed.saltContent.toStringAsFixed(1));
      setValue(
        _waterActivityKey,
        (mixed.waterActivity < 0 ? 0.0 : mixed.waterActivity).toStringAsFixed(
          2,
        ),
      );
    }

    recalc();
    ever(chlorideList[sampleIndex], (_) => recalc());
    ever(calciumList[sampleIndex], (_) => recalc());
    ever(waterList[sampleIndex], (_) => recalc());
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
    if (selectedSaltType.value == 'Sodium Formate' &&
        (k.contains('water activity') ||
            k.contains('water phase salinity') ||
            k.contains('brine phase salinity') ||
            k.contains('oil/sodium formate') ||
            k.contains('sodium formate brine') ||
            k.contains('dissolved sodium formate'))) {
      return false;
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

  void _setupSolidAnalysisWatchers() {
    for (int si = 0; si < 3; si++) {
      final sampleIdx = si;
      final sourceKeys = [
        _mwKey,
        _solidsKey,
        _oilKey,
        _waterKey,
        _bariteKey,
        _bentoniteKey,
        _mbtKey,
        _cacl2PctWtKey,
        _naclPctWtKey,
        _dissolvedSodiumFormateKey,
        _chloridesForSolidsKey,
        _brineVolPctKey,
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
        'brineVolPct': vals['brineVolPct'], // L62 Brine % vol
        'corrSolidsPct': vals['corrSolidsPct'], // L45 Corrected Solids %
        'oilSG': vals['oilSG'],
        'hgsSG': vals['hgsSG'], // L58 HGS density
        'lgsSG': vals['lgsSG'], // L57 LGS density
        if (localResult != null) ...localResult,
        'sampleIndex': sampleIdx,
        'fluidType': selectedFluidType.value,
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
    final bariteLb = vals['bariteLb'] ?? 0;
    final inputBentoniteLb = vals['bentoniteLb'] ?? 0;
    final mbt = vals['mbt'] ?? 0;
    final chloridesMgl = vals['chloridesMgl'] ?? 0;
    final wpsPpm = vals['wpsPpm'] ?? 0;
    final cacl2Pct = vals['cacl2Pct'] ?? 0;
    final naclPct = vals['naclPct'] ?? 0;
    final oilSG = vals['oilSG'] ?? 0.81;
    final hgsSG = vals['hgsSG'] ?? 4.20;
    final lgsSG = vals['lgsSG'] ?? 2.60;
    final shaleCec = vals['shaleCec'] ?? 15.0;
    final bentCec = vals['bentCec'] ?? 65.0;
    final fluid = selectedFluidType.value.toLowerCase();
    final isOilMud = fluid.contains('oil') || fluid.contains('synthetic');
    final weightedMud = isOilMud || (vals['isWeightedMud'] ?? 0) > 0;
    final wbmSaltMassFraction = (chloridesMgl * 1.65) / 1000000;
    final oilSalt = isOilMud
        ? _oilSaltResult(
            chloridesMgl: chloridesMgl,
            calciumMgl: vals['calciumMgl'] ?? 0,
            waterVol: waterVol,
            retortSolids: retortSolids,
            cacl2Pct: cacl2Pct,
            naclPct: naclPct,
            wpsPpm: wpsPpm,
          )
        : null;
    final brineSG = isOilMud
        ? (oilSalt?.brineSG ?? 1.0)
        : 1.0 + wbmSaltMassFraction;

    double brineVol;
    if (isOilMud && oilSalt != null) {
      brineVol = oilSalt.brineVolPct;
    } else {
      final brineVolPct = vals['brineVolPct'] ?? 0;
      brineVol = brineVolPct > 0 ? brineVolPct : waterVol;
    }

    final dissolvedSolids = isOilMud
        ? (brineVol - waterVol)
        : waterVol * wbmSaltMassFraction * (1.0 / 2.16);
    final roundedDissolvedSolids = double.parse(
      dissolvedSolids.toStringAsFixed(1),
    );
    final corrSolidsPct = vals['corrSolidsPct'] ?? 0;
    final rawCorrectedSolids = isOilMud
        ? (oilSalt?.correctedSolidsPct ??
              (corrSolidsPct > 0
                  ? corrSolidsPct
                  : (retortSolids - roundedDissolvedSolids)))
        : (retortSolids - roundedDissolvedSolids);
    final correctedSolids = rawCorrectedSolids;
    final safeCorrected = correctedSolids < 0 ? 0 : correctedSolids;
    final totalSolids = retortSolids > 0
        ? retortSolids
        : (100 - (oilVol + waterVol));

    var hgsPercent = 0.0;
    var lgsPercent = safeCorrected;
    var avgSG = safeCorrected > 0 ? lgsSG : 0.0;
    if (weightedMud && hgsSG != lgsSG && safeCorrected > 0) {
      hgsPercent =
          ((mw * 42 / 3.5) -
              oilVol * oilSG -
              brineVol * brineSG -
              safeCorrected * lgsSG) /
          (hgsSG - lgsSG);
      lgsPercent = safeCorrected - hgsPercent;
      avgSG = (lgsPercent * lgsSG + hgsPercent * hgsSG) / safeCorrected;
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

    double fmt(num v, [int digits = 2]) {
      final value = v.toDouble();
      if (value.isNaN || value.isInfinite) return 0;
      return double.parse(value.toStringAsFixed(digits));
    }

    return {
      'mudWeight': fmt(mw),
      'retortSolids': fmt(totalSolids < 0 ? 0 : totalSolids),
      'bariteLb': fmt(bariteLb),
      'bentoniteLb': fmt(bentoniteLb),
      'brineSG': fmt(brineSG, 4),
      'brineVol': fmt(brineVol),
      'totalSolids': fmt(totalSolids < 0 ? 0 : totalSolids),
      'correctedSolids': fmt(safeCorrected, isOilMud ? 1 : 2),
      'dissolvedSolids': fmt(
        roundedDissolvedSolids < 0 ? 0 : roundedDissolvedSolids,
      ),
      'avgSG': fmt(avgSG),
      'hgsPercent': fmt(hgsPercent),
      'hgsLb': fmt(hgsLb),
      'lgsPercent': fmt(lgsPercent),
      'lgsLb': fmt(lgsLb),
      'bentPercent': fmt(bentPercent),
      'drillSolidsPercent': fmt(drillSolidsPercent),
      'drillSolidsLb': fmt(drillSolidsLb),
      if (obmChemicalsPercent != null)
        'obmChemicalsPercent': fmt(obmChemicalsPercent),
      if (obmChemicalsLb != null) 'obmChemicalsLb': fmt(obmChemicalsLb),
      'dsBentRatio': dsBentRatio == null ? null : fmt(dsBentRatio),
    };
  }

  bool _hasSolidAnalysisInputs(Map<String, double> vals) {
    final mw = vals['mudWeight'] ?? 0;
    final retortSolids = vals['retortSolids'] ?? 0;
    final water = vals['waterVol'] ?? 0;
    return mw > 0 && retortSolids > 0 && water > 0;
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
      list[sampleIdx] = d == null ? _fmt(val) : d.toStringAsFixed(digits);
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
      return double.tryParse(vals[index].value) ?? 0;
    }

    // LGS/HGS SG: prefer table row values (L57/L58 in Excel),
    // fall back to Specific Gravity panel controllers
    final lgsTableSG = readField(_lgsTableDensityKey);
    final hgsTableSG = readField(_hgsTableDensityKey);
    final lgsUsed = lgsTableSG > 0
        ? lgsTableSG
        : (double.tryParse(lgsSgController.text) ?? 2.60);
    final hgsUsed = hgsTableSG > 0
        ? hgsTableSG
        : (double.tryParse(hgsSgController.text) ?? 4.10);
    final chloridesMgl = readField(_chloridesForSolidsKey);
    final waterVol = readField(_waterKey);
    final mixedSalt = selectedSaltType.value == 'NaCl + CaCl2'
        ? _mixedSaltValues(chloridesMgl, readField(_wholeMudCaKey), waterVol)
        : null;
    final cacl2Pct = mixedSalt?.cacl2Wt ?? readField(_cacl2PctWtKey);
    final rawNaclPct = selectedSaltType.value == 'NaCl'
        ? _naclWtFromChlorideWater(chloridesMgl, waterVol)
        : 0.0;
    final naclPct =
        mixedSalt?.naclWt ??
        (rawNaclPct > 0 ? rawNaclPct : readField(_naclPctWtKey));
    final wpsPpm = readField(_wpsSaltPercentKey);
    final saltPctForSolids = selectedSaltType.value == 'NaCl + CaCl2'
        ? cacl2Pct
        : (cacl2Pct > 0
              ? cacl2Pct
              : (naclPct > 0 ? naclPct : (wpsPpm > 0 ? wpsPpm / 10000 : 0.0)));

    return {
      'mudWeight': readField(_mwKey),
      'retortSolids': readField(_solidsKey), // Total Solids % (L44)
      'oilVol': readField(_oilKey), // Oil % vol (L46)
      'waterVol': waterVol, // Water % vol
      'bariteLb': readField(_bariteKey),
      'bentoniteLb': readField(_bentoniteKey),
      'mbt': readField(_mbtKey),
      'chloridesMgl': chloridesMgl,
      'calciumMgl': readField(_wholeMudCaKey),
      'wpsPpm': wpsPpm,
      'cacl2Pct': saltPctForSolids, // CaCl2 % wt, or derived from chlorides
      'naclPct': naclPct,
      'brineVolPct': readField(_brineVolPctKey), // Brine % vol (L62) if exists
      'corrSolidsPct': readField(
        _corrSolidsValueKey,
      ), // Corrected Solids % (L45)
      'oilSG': double.tryParse(oilSgController.text) ?? 0.81,
      'hgsSG': hgsUsed, // L58 — HGS density
      'lgsSG': lgsUsed, // L57 — LGS density
      'shaleCec': double.tryParse(shaleCecController.text) ?? 15.0,
      'bentCec': double.tryParse(bentCecController.text) ?? 65.0,
      'isWeightedMud': isWeightedMud.value ? 1.0 : 0.0,
    };
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    final d = double.tryParse(v.toString());
    return d == null ? v.toString() : d.toStringAsFixed(2);
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
    _mudStateSaveTimer?.cancel();
    _isApplyingSavedState = true;
    selectedFluidType.value = normalized;
    await loadFluidTypeData(applySavedState: false);
    _scheduleMudReportSave();
  }

  Future<void> changeSaltType(String type) async {
    final normalized = type.trim();
    if (normalized.isEmpty || normalized == selectedSaltType.value) return;
    selectedSaltType.value = normalized;
    if (selectedFluidType.value != 'Oil-based') {
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

  void _initRheologyTable() => _updateRheologyRows();

  void changeModel(String model) {
    rheologyModel.value = model;
    _updateRheologyRows();
    _setupMudStateWatchers();
    _scheduleMudReportSave();
  }

  void _updateRheologyRows() {
    final rows = _rheologyRowsForModel(rheologyModel.value);
    rheologyTable.clear();
    for (var r in rows) {
      rheologyTable[r] = List.generate(samples.length, (_) => ''.obs);
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
            rheologyTable['PV (cP)']?[i].value = pv.toStringAsFixed(1);
            rheologyTable['YP (lbf/100ft2)']?[i].value = (r300 - pv)
                .toStringAsFixed(1);
          }
          break;
        case 'Power Law':
          if (r600 <= 0 || r300 <= 0) {
            _clearRheologyRows(i, const ['n', 'K (lbf-s^n/100ft2)']);
          } else {
            final n = 3.32 * _log10(r600 / r300);
            final k = r300 / _pow(511, n);
            rheologyTable['n']?[i].value = n.toStringAsFixed(3);
            rheologyTable['K (lbf-s^n/100ft2)']?[i].value = k.toStringAsFixed(
              3,
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
            rheologyTable['Yield Stress (lbf/100ft2)']?[i].value = yieldStress
                .toStringAsFixed(2);
          }
          final adjusted600 = r600 - yieldStress;
          final adjusted300 = r300 - yieldStress;
          if (r600 <= 0 || r300 <= 0 || adjusted600 <= 0 || adjusted300 <= 0) {
            _clearRheologyRows(i, const ['n', 'K (lbf-s^n/100ft2)']);
          } else {
            final n = 3.32 * _log10(adjusted600 / adjusted300);
            final k = adjusted300 / _pow(511, n);
            rheologyTable['n']?[i].value = n.toStringAsFixed(3);
            rheologyTable['K (lbf-s^n/100ft2)']?[i].value = k.toStringAsFixed(
              3,
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
    rheologyTable.refresh();
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

  double _log10(double x) => x > 0 ? 0.4342944819 * _ln(x) : 0;

  double _cacl2BrineSg(double saltWtPct) =>
      0.99707 + (0.007923 * saltWtPct) + (0.00004964 * saltWtPct * saltWtPct);

  double _naclBrineSg(double saltWtPct) => 1 + (0.0075127 * saltWtPct);

  double _naclWaterActivity(double saltWtPct) => 1 - (0.0094 * saltWtPct);

  double _mixedBrineSg(double cacl2Wt, double naclWt) =>
      1 +
      (0.0075127 * naclWt) +
      (0.007923 * cacl2Wt) +
      (0.000008334 * naclWt * cacl2Wt) +
      (0.00004964 * cacl2Wt * cacl2Wt);

  _OilSaltResult? _oilSaltResult({
    required double chloridesMgl,
    required double calciumMgl,
    required double waterVol,
    required double retortSolids,
    required double cacl2Pct,
    required double naclPct,
    required double wpsPpm,
  }) {
    if (waterVol <= 0) return null;

    final saltType = selectedSaltType.value;
    double saltWtPct = 0;
    double brineSG = 1;
    double waterActivity = 0;

    if (saltType == 'NaCl + CaCl2') {
      final mixed = _mixedSaltValues(chloridesMgl, calciumMgl, waterVol);
      if (mixed != null) {
        saltWtPct = mixed.saltContent;
        brineSG = mixed.brineSg;
        waterActivity = mixed.waterActivity;
      } else {
        saltWtPct = cacl2Pct + naclPct;
        brineSG = _mixedBrineSg(cacl2Pct, naclPct);
        waterActivity = _naclWaterActivity(saltWtPct);
      }
    } else if (saltType == 'NaCl') {
      saltWtPct = _naclWtFromChlorideWater(chloridesMgl, waterVol);
      if (saltWtPct <= 0) {
        saltWtPct = naclPct > 0 ? naclPct : (wpsPpm > 0 ? wpsPpm / 10000 : 0);
      }
      brineSG = saltWtPct > 0 ? _naclBrineSg(saltWtPct) : 1;
      waterActivity = _naclWaterActivity(saltWtPct);
    } else if (saltType == 'Sodium Formate') {
      saltWtPct = cacl2Pct > 0 ? cacl2Pct : (wpsPpm > 0 ? wpsPpm / 10000 : 0);
      brineSG = saltWtPct > 0 ? (1 + (0.00640 * saltWtPct)) : 1;
      waterActivity =
          1 - (0.00150 * saltWtPct) - (0.00007 * saltWtPct * saltWtPct);
    } else {
      if (chloridesMgl > 0) {
        final frac = 1.565 * chloridesMgl / 10000;
        saltWtPct = frac + waterVol == 0 ? 0 : 100 * frac / (frac + waterVol);
      }
      if (saltWtPct <= 0) {
        saltWtPct = cacl2Pct > 0 ? cacl2Pct : (wpsPpm > 0 ? wpsPpm / 10000 : 0);
      }
      brineSG = saltWtPct > 0 ? _cacl2BrineSg(saltWtPct) : 1;
      waterActivity = 1 - (0.0101626 * saltWtPct);
    }

    if (saltWtPct <= 0 || brineSG <= 0) return null;
    final waterFraction = (1 - saltWtPct / 100) * brineSG;
    if (waterFraction <= 0) return null;
    final brineVolPct = waterVol / waterFraction;
    final dissolvedSolidsPct = brineVolPct - waterVol;
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
    final cacl2WholeMudMg = calcium > 0 ? _cacl2MgFromCalcium(calcium) : 0.0;
    final chlorideFromNacl = chlorides - _cacl2ChlorideFromCalcium(calcium);
    final naclWholeMudMg = chlorideFromNacl <= 0
        ? 0.0
        : 1.648 * chlorideFromNacl;
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
      waterActivity: _naclWaterActivity(saltContent),
    );
  }

  double _cacl2MgFromCalcium(double calciumMgL) => calciumMgL * 2.769;

  double _cacl2ChlorideFromCalcium(double calciumMgL) => calciumMgL * 1.769;

  double _maxSolubleNaclWt(double cacl2Wt) =>
      26.432 -
      (1.0472 * cacl2Wt) +
      (0.00798191 * cacl2Wt * cacl2Wt) +
      (0.000052238 * cacl2Wt * cacl2Wt * cacl2Wt);

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

  double _ln(double x) {
    if (x <= 0) return 0;
    double r = 0, y = (x - 1) / (x + 1), y2 = y * y, t = y;
    for (int i = 0; i < 50; i++) {
      r += t / (2 * i + 1);
      t *= y2;
    }
    return 2 * r;
  }

  double _pow(double base, double exp) =>
      base <= 0 ? 0 : _expM(exp * _ln(base));
  double _expM(double x) {
    double r = 1, t = 1;
    for (int i = 1; i <= 50; i++) {
      t *= x / i;
      r += t;
    }
    return r;
  }

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
