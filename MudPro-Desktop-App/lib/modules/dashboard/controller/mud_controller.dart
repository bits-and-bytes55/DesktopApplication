import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/mud_properties_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/mud_properties_model.dart';
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

const String _kBaseUrl = ApiEndpoint.baseUrl;
const Duration _kSaveDebounce = Duration(milliseconds: 800);

class MudController extends GetxController {
  final samples = ['1', '2', '3', 'Plan-L', 'Plan-H'];

  final _mudPropsCtrl    = MudPropertiesController();
  final othersController = OthersController();

  var selectedFluidType = 'Water-based'.obs;

  final propertyTable       = <String, List<RxString>>{}.obs;
  final propertyUnits       = <String, String>{}.obs;
  final availableProperties = <String>[].obs;
  final rheologyTable       = <String, List<RxString>>{}.obs;

  var rheologyModel       = 'Bingham'.obs;
  var rheologyCalculation = 'API (RP 13D)'.obs;
  var isCompletionFluid   = false.obs;
  var isWeightedMud       = false.obs;

  final fluidnameController = TextEditingController();
  final oilSgController     = TextEditingController(text: '0.80');
  final hgsSgController     = TextEditingController(text: '4.20');
  final lgsSgController     = TextEditingController(text: '2.60');
  final shaleCecController  = TextEditingController(text: '15.00');
  final bentCecController   = TextEditingController(text: '65.00');

  var sampleForCalculation = '1'.obs;
  var isLoading            = false.obs;

  // ── Solid Analysis state ──────────────────────────────────────────────────
  final solidAnalysisResult  = <String, List<String>>{}.obs;
  var isSolidAnalysisLoading = false.obs;
  var solidAnalysisError     = ''.obs;

  final _solidAnalysisIds = <int, String?>{0: null, 1: null, 2: null};
  final _debounceTimers   = <int, Timer?>{};

  final solidSaveStatus = <String, RxString>{
    '0': 'idle'.obs,
    '1': 'idle'.obs,
    '2': 'idle'.obs,
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FIELD KEY GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  String? _findKey(bool Function(String) test) {
    for (final key in propertyTable.keys) {
      if (test(key.toLowerCase().replaceAll('*', '').trim())) return key;
    }
    return null;
  }

  String? get _mwKey => _findKey((k) =>
      k == 'mw' || k.contains('mud weight'));

  String? get _solidsKey => _findKey((k) =>
      (k == 'solids' || k == 'total solids') &&
      !k.contains('drill') && !k.contains('adj') &&
      !k.contains('salt') && !k.contains('corr'));

  String? get _oilKey => _findKey((k) =>
      (k == 'oil' || k == 'oil (% vol)' || k == 'oil%') &&
      !k.contains('ratio') && !k.contains('sg') && !k.contains('water') &&
      !k.contains('density'));

  String? get _waterKey => _findKey((k) =>
      (k == 'water' || k == 'water (% vol)' || k == 'water%') &&
      !k.contains('activity') && !k.contains('sg') &&
      !k.contains('oil') && !k.contains('phase') && !k.contains('salinity'));

  // "Brine (% vol)" — L62 in Excel, source for Corrected Solids
  // Must NOT match "Brine Density" (that's a different field)
  String? get _brinePercentKey => _findKey((k) =>
      (k == 'brine' ||
       k == 'brine (% vol)' ||
       k == 'brine%' ||
       k == 'brine (% vol)' ||
       k.startsWith('brine') && !k.contains('density') && !k.contains('sg') &&
       !k.contains('salt') && !k.contains('water')));

  // Source for Excess Lime = "Whole Mud Alkalinity (POM)" — L49 in Excel
  // Excel: =IFERROR(L49*1.295,"") where L49 = Whole Mud Alkalinity (POM)
  // This is the EDITABLE user-input row that drives Excess Lime auto-calc
  String? get _alkalinityKey => _findKey((k) =>
      k.contains('whole mud alkalinity') ||
      k.contains('alkalinity (pom)') ||
      k.contains('alkalinity(pom)'));

  // "Whole Mud Chlorides (mg/l)" — L51 in Excel, source for CaCl2 Concentration
  // Excel: CaCl2 Concentration = 1.565 * L51
  String? get _wholeMudChlorideKey => _findKey((k) =>
      k.contains('whole mud chloride') ||
      k.contains('mud chloride') ||
      k == 'whole mud chlorides');

  // MBT source field
  String? get _mbtKey => _findKey((k) =>
      k == 'mbt' ||
      k.startsWith('mbt') ||
      k.contains('methylene blue') ||
      k.contains('mbt (') ||
      k == 'mbt (ppb)');

  // CaCl2 (% wt) — this is the AUTO-CALC OUTPUT in oil-based (computed from MBT+Water)
  // Formula: =100*(1.565*MBT/10000)/((1.565*MBT/10000)+Water%)
  String? get _cacl2PctWtKey => _findKey((k) =>
      k == 'cacl2' ||
      k == 'cacl2 (% wt)' || k == 'cacl2 % wt' ||
      (k.startsWith('cacl2') && (k.contains('wt') || k.contains('%'))));

  // CaCl2 Concentration (mg/l) — AUTO-CALC target: =1.565 * MBT
  // Also SOURCE for Water Phase Salinity: WPS(ppm) = CaCl2Conc * 10000
  String? get _cacl2ConcKey => _findKey((k) =>
      k.contains('cacl2 concentration') ||
      k.contains('cacl2 conc') ||
      k.contains('calcium chloride') ||
      (k.startsWith('cacl2') && k.contains('mg')) ||
      (k.startsWith('cacl2') && k.contains('concentration')));

  String? get _lgsKey => _findKey((k) =>
      (k == 'lgs' || k == 'lgs density' || k.startsWith('lgs density')) &&
      !k.contains('%') && !k.contains('lb'));

  String? get _r600Key => _findKey((k) => k == 'r600' || k == 'r600 (rpm)');
  String? get _r300Key => _findKey((k) => k == 'r300' || k == 'r300 (rpm)');
  String? get _r6Key   => _findKey((k) => k == 'r6'   || k == 'r6 (rpm)');
  String? get _r3Key   => _findKey((k) => k == 'r3'   || k == 'r3 (rpm)');

  String? get _pvPropKey => _findKey((k) =>
      (k == 'pv' || k == 'pv (cp)') &&
      !k.contains('t.') && !k.contains('t for'));

  String? get _ypPropKey => _findKey((k) =>
      k == 'yp' || k == 'yp (lbf/100ft2)');

  String? get _lsrypKey => _findKey((k) =>
      k == 'lsryp' || k.contains('lsryp'));

  String? get _owRatioKey => _findKey((k) =>
      k.contains('oil') && k.contains('water') && k.contains('ratio'));

  // Matches "*Solids (% vol)" — the retort/total solids INPUT row
  // After _findKey strips '*' prefix: "solids (% vol)"
  String? get _totalSolidsKey => _findKey((k) =>
      (k == 'solids' || k == 'total solids' ||
       k.contains('total solids') ||
       (k.startsWith('solids') && !k.contains('corr') && !k.contains('drill'))) &&
      !k.contains('corr') && !k.contains('drill') && !k.contains('adj'));

  String? get _correctedSolidsKey => _findKey((k) =>
      k.contains('corrected solids') || k.contains('corr. solids'));

  String? get _excessLimeKey => _findKey((k) =>
      k.contains('excess lime'));

  String? get _wholeMudAlkKey => _findKey((k) =>
      (k.contains('whole mud alkalinity') || k.contains('alkalinity (pom)') ||
       k.contains('alkalinity(pom)') || k.contains('mud alkalinity (pm)')));

  // Matches: "Water phase Salinity (WPS)", "Water phase Salinity (VPS)", etc.
  // The output row: single water phase salinity field (% or ppm comes from context)
  String? get _wpsSaltPercentKey => _findKey((k) =>
      k.contains('water phase salinity') || k.contains('water phase sal'));

  // If there's a separate ppm row
  String? get _wpsSaltPpmKey => _findKey((k) =>
      (k.contains('water phase salinity') || k.contains('water phase sal')) &&
      k.contains('ppm'));

  String? get _bariteKey => _findKey((k) =>
      k == 'barite' || (k.contains('barite') && !k.contains('brine')));

  String? get _bentoniteKey => _findKey((k) =>
      k == 'bentonite' || k.contains('bentonite'));

  String? get _brineDensityKey => _findKey((k) =>
      k == 'brine density' || k.contains('brine density'));

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    _initRheologyTable();
    loadFluidTypeData();
    super.onInit();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> loadFluidTypeData() async {
    isLoading.value = true;
    try {
      propertyTable.clear();
      availableProperties.clear();
      solidAnalysisResult.clear();
      for (int i = 0; i < 3; i++) { _solidAnalysisIds[i] = null; }

      await Future.wait([
        _loadLeftTableFromMudProperties(),
        _loadDropdownFromOthers(),
      ]);

      _setupAutoCalculations();
      _setupSolidAnalysisWatchers();
    } catch (e) {
      debugPrint('[MudController] loadFluidTypeData error: $e');
      Get.snackbar('Error', 'Failed to load data: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLeftTableFromMudProperties() async {
    try {
      final selected = await _mudPropsCtrl.getSelectedMudProperties();
      List<MudPropertyItem> props = switch (selectedFluidType.value) {
        'Water-based' => selected.waterBased,
        'Oil-based'   => selected.oilBased,
        'Synthetic'   => selected.synthetic,
        _             => <MudPropertyItem>[],
      };
      _addCommonFields();
      for (final item in props) {
        if (item.name.isNotEmpty) {
          propertyTable[item.name] = List.generate(samples.length, (_) => ''.obs);
          propertyUnits[item.name] = item.unit;
        }
      }
    } catch (e) {
      debugPrint('[MudController] Left table fetch ERROR: $e');
      _addCommonFields();
    }
  }

  Future<void> _loadDropdownFromOthers() async {
    try {
      final data = switch (selectedFluidType.value) {
        'Water-based' => await othersController.getWaterBased(),
        'Oil-based'   => await othersController.getOilBased(),
        'Synthetic'   => await othersController.getSynthetic(),
        _             => <dynamic>[],
      };
      availableProperties.value = data
          .where((item) => item.name != null && (item.name as String).isNotEmpty)
          .map<String>((item) => item.name as String)
          .toList();
    } catch (e) {
      debugPrint('[MudController] Dropdown fetch ERROR: $e');
      availableProperties.value = [];
    }
  }

  void _addCommonFields() {
    for (final field in ['Description', 'Sample from', 'Time Sample Taken (hh:mm)']) {
      propertyTable[field] = List.generate(samples.length, (_) => ''.obs);
      propertyUnits[field] = '';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTO CALCULATIONS
  // All formulas match the Excel DMR sheet exactly.
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupAutoCalculations() {
    debugPrint('[AutoCalc] propertyTable keys: ${propertyTable.keys.toList()}');
    debugPrint('[AutoCalc] _oilKey=$_oilKey  _waterKey=$_waterKey  _brinePercentKey=$_brinePercentKey');
    // Extra: print all keys containing 'brine' to diagnose Corrected Solids issue
    final brineKeys = propertyTable.keys.where((k) => k.toLowerCase().contains('brine')).toList();
    debugPrint('[AutoCalc] All brine keys in table: $brineKeys  <-- Corrected Solids source');
    debugPrint('[AutoCalc] _totalSolidsKey=$_totalSolidsKey  _correctedSolidsKey=$_correctedSolidsKey');
    debugPrint('[AutoCalc] _alkalinityKey=$_alkalinityKey  (Whole Mud Alk POM → Excess Lime)');
    debugPrint('[AutoCalc] _excessLimeKey=$_excessLimeKey');
    debugPrint('[AutoCalc] _wholeMudChlorideKey=$_wholeMudChlorideKey  (→ CaCl2 Conc & CaCl2 wt)');
    debugPrint('[AutoCalc] _cacl2ConcKey=$_cacl2ConcKey  _cacl2PctWtKey=$_cacl2PctWtKey');
    debugPrint('[AutoCalc] _wpsSaltPercentKey=$_wpsSaltPercentKey  _wpsSaltPpmKey=$_wpsSaltPpmKey');

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
        final pv   = double.tryParse(b) ?? 0;
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
      //    =IFERROR(ROUNDUP(100*Oil/(Oil+Water),0) & "/" & ROUNDDOWN(100*Water/(Oil+Water),0),"")
      final owTarget = _owRatioKey ?? 'Oil/water Ratio';
      _watchTwoOpt(i, _oilKey, _waterKey, owTarget, (a, b) {
        final oil   = double.tryParse(a) ?? 0;
        final water = double.tryParse(b) ?? 0;
        if (oil == 0 && water == 0) return '';
        final total = oil + water;
        if (total == 0) return '';
        return '${(100*oil/total).ceil()}/${(100*water/total).floor()}';
      });

      // ── 5. Total Solids = 100 − (Oil% + Water%) ───────────────────────────
      //    Excel: =IF(100-(L46+L47)<100, 100-(L46+L47), "")
      //    L46=Oil(% vol), L47=Water(% vol)
      //    TARGET: "*Solids (% vol)" row — after _findKey strips '*': "solids (% vol)"
      final tsTarget = _totalSolidsKey;
      if (tsTarget != null) {
        _watchTwoOpt(i, _oilKey, _waterKey, tsTarget, (a, b) {
          final oil   = double.tryParse(a) ?? 0;
          final water = double.tryParse(b) ?? 0;
          if (oil == 0 && water == 0) return '';
          final solids = 100 - (oil + water);
          if (solids >= 100) return '';
          return solids.toStringAsFixed(2);
        });
      }

      // ── 6. Corrected Solids = 100 − (Oil% + Brine%) ──────────────────────
      //    Excel: =IFERROR(100-(L46+L62),"")
      //    L46=Oil(% vol), L62=Brine(% vol) row (separate from Water row)
      //    Brine row is added dynamically from API — must be watched separately
      final csTarget = _correctedSolidsKey;
      if (csTarget != null && _oilKey != null) {
        // Helper to recalculate corrected solids using Brine row if it exists,
        // otherwise falls back to Water. Called whenever oil, water, or brine changes.
        void recalcCorrectedSolids() {
          final oilVals   = propertyTable[_oilKey!];
          // Prefer Brine row; fall back to Water if Brine not in table
          final brineK    = _brinePercentKey ?? _waterKey;
          final brineVals = brineK != null ? propertyTable[brineK] : null;
          final tgt       = propertyTable[csTarget];
          if (oilVals == null || brineVals == null || tgt == null) return;
          if (i >= oilVals.length || i >= brineVals.length || i >= tgt.length) return;
          final oil   = double.tryParse(oilVals[i].value) ?? 0;
          final brine = double.tryParse(brineVals[i].value) ?? 0;
          tgt[i].value = (oil == 0 && brine == 0)
              ? ''
              : (100 - (oil + brine)).toStringAsFixed(2);
        }
        // Set initial value
        recalcCorrectedSolids();
        // Watch Oil
        final oilList = propertyTable[_oilKey!];
        if (oilList != null && i < oilList.length) {
          ever(oilList[i], (_) => recalcCorrectedSolids());
        }
        // Watch Water (fallback)
        final waterK = _waterKey;
        if (waterK != null) {
          final waterList = propertyTable[waterK];
          if (waterList != null && i < waterList.length) {
            ever(waterList[i], (_) => recalcCorrectedSolids());
          }
        }
        // Watch Brine (primary) — may be same as Water if Brine not in table
        final brineK2 = _brinePercentKey;
        if (brineK2 != null && brineK2 != _waterKey) {
          final brineList = propertyTable[brineK2];
          if (brineList != null && i < brineList.length) {
            ever(brineList[i], (_) => recalcCorrectedSolids());
          }
        }
      }

      // ── 7. Excess Lime = Mud Alkalinity (Pm) × 1.295 ─────────────────────
      //    Excel: =IFERROR(L49*1.295,"")
      //    L49 = "Mud Alkalinity (Pm)" user-input row
      final elTarget = _excessLimeKey;
      if (elTarget != null) {
        _watchOneOpt(i, _alkalinityKey, elTarget, (a) {
          final v = double.tryParse(a) ?? 0;
          return v == 0 ? '' : (v * 1.295).toStringAsFixed(2);
        });
      }

      // ── 8. Whole Mud Alkalinity (POM) — EDITABLE, user enters directly ────
      //    Not auto-calculated. Used as source for CaCl2 Conc below.

      // ── 9. CaCl2 Concentration (mg/l) = 1.565 × Whole Mud Chlorides ───────
      //    Excel: =1.565*L51  where L51 = "Whole Mud Chlorides (mg/l)" row
      //    User enters Whole Mud Chlorides → CaCl2 Concentration auto-fills
      final cacl2ConcTarget = _cacl2ConcKey;
      if (cacl2ConcTarget != null) {
        _watchOneOpt(i, _wholeMudChlorideKey, cacl2ConcTarget, (a) {
          final v = double.tryParse(a) ?? 0;
          return v == 0 ? '' : (v * 1.565).toStringAsFixed(2);
        });
      }

      // ── 10. CaCl2 (% wt) = 100*(1.565*WholeMudChlorides/10000)/
      //                            ((1.565*WholeMudChlorides/10000)+Water%)
      //    Formula: =100*(1.565*L51/10000)/((1.565*L51/10000)+L47)
      final cacl2WtTarget = _cacl2PctWtKey;
      if (cacl2WtTarget != null) {
        _watchTwoOpt(i, _wholeMudChlorideKey, _waterKey, cacl2WtTarget, (a, b) {
          final chlorides = double.tryParse(a) ?? 0;
          final water     = double.tryParse(b) ?? 0;
          if (chlorides == 0) return '';
          final frac = 1.565 * chlorides / 10000;
          if (frac + water == 0) return '';
          return (100 * frac / (frac + water)).toStringAsFixed(2);
        });
      }

      // ── 11. Water Phase Salinity (WPS) ppm = CaCl2 Conc × 10000 ──────────
      //    Excel: =IFERROR(10000*L55,"")  — L55=CaCl2 Concentration(mg/l)
      //    CaCl2 Conc is itself auto-calc (step 9), so WPS cascades from MBT
      final wpsTarget = _wpsSaltPercentKey;
      if (wpsTarget != null) {
        _watchOneOpt(i, _cacl2ConcKey, wpsTarget, (a) {
          final v = double.tryParse(a) ?? 0;
          return v == 0 ? '' : (v * 10000).toStringAsFixed(0);
        });
      }

      // ── 12. Water Phase Salinity (WPS) mg/l = CaCl2 Conc × 10000 × BrineSG
      //    Excel: =IFERROR(10000*L55*L61,"")
      final wpsPpmTarget = _wpsSaltPpmKey;
      if (wpsPpmTarget != null && wpsPpmTarget != wpsTarget) {
        _watchTwoOpt(i, _cacl2ConcKey, _lgsKey, wpsPpmTarget, (a, b) {
          final conc   = double.tryParse(a) ?? 0;
          final factor = double.tryParse(b) ?? 0;
          if (conc == 0) return '';
          return (conc * 10000 * (factor == 0 ? 1.0 : factor)).toStringAsFixed(0);
        });
      }
    }
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // isAutoCalc
  // ═══════════════════════════════════════════════════════════════════════════

  bool isAutoCalc(String fieldName) {
    final k = fieldName.toLowerCase().replaceAll('*', '').trim();
    // PV, YP (in property table — transferred from rheology, but keep editable)
    // LSRYP
    if (k == 'lsryp' || k.contains('lsryp')) return true;
    // Oil/Water Ratio
    if (k.contains('oil') && k.contains('water') && k.contains('ratio')) return true;
    // Total Solids — "*Solids (% vol)" matches as "solids (% vol)" after stripping *
    if ((k == 'solids' || k.contains('total solids') ||
        (k.startsWith('solids') && !k.contains('corr') && !k.contains('drill'))) &&
        !k.contains('corr') && !k.contains('drill')) return true;
    // Corrected Solids
    if (k.contains('corrected solids') || k.contains('corr. solids')) return true;
    // Excess Lime
    if (k.contains('excess lime')) return true;
    // CaCl2 Concentration (mg/l) — auto-calc = 1.565 × MBT
    if (k.contains('cacl2 concentration') || k.contains('cacl2 conc') ||
        (k.startsWith('cacl2') && k.contains('mg'))) return true;
    // CaCl2 (% wt) — auto-calc from MBT + Water
    if (k.startsWith('cacl2') && (k.contains('wt') || k.contains('%'))) return true;
    // Water Phase Salinity
    if (k.contains('water phase salinity') || k.contains('water phase sal')) return true;
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBOUNCED SOLID ANALYSIS SAVE WATCHERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupSolidAnalysisWatchers() {
    for (int si = 0; si < 3; si++) {
      final sampleIdx = si;
      // Watch all fields that affect Solid Analysis calculation
      final sourceKeys = [
        _mwKey,
        _solidsKey,
        _oilKey,
        _waterKey,
        _bariteKey,
        _bentoniteKey,
        _cacl2PctWtKey,   // drives brineSG via formula
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
    solidSaveStatus['$sampleIdx']?.value = 'idle';
    _debounceTimers[sampleIdx] = Timer(_kSaveDebounce, () => _saveSolidAnalysis(sampleIdx));
  }

  Future<void> _saveSolidAnalysis(int sampleIdx) async {
    final vals = _extractSampleValues(sampleIdx);
    if (vals['mudWeight'] == 0) return;

    solidSaveStatus['$sampleIdx']?.value = 'saving';
    try {
      final body = jsonEncode({
        'mudWeight':    vals['mudWeight'],
        'retortSolids': vals['retortSolids'],
        'oilVol':       vals['oilVol'],
        'waterVol':     vals['waterVol'],
        'bariteLb':     vals['bariteLb'],
        'bentoniteLb':  vals['bentoniteLb'],
        'cacl2Pct':     vals['cacl2Pct'],
        'oilSG':        vals['oilSG'],
        'hgsSG':        vals['hgsSG'],
        'lgsSG':        vals['lgsSG'],
        'sampleIndex':  sampleIdx,
      });

      final existingId = _solidAnalysisIds[sampleIdx];
      http.Response response;

      if (existingId == null) {
        response = await http.post(
          Uri.parse('${_kBaseUrl}solids'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
        if (response.statusCode == 201) {
          final data = jsonDecode(response.body)['data'];
          _solidAnalysisIds[sampleIdx] = data['_id'] as String?;
          _updateResultFromData(sampleIdx, data);
        }
      } else {
        response = await http.put(
          Uri.parse('${_kBaseUrl}solids/$existingId'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'];
          _updateResultFromData(sampleIdx, data);
        }
      }

      solidSaveStatus['$sampleIdx']?.value =
          (response.statusCode == 200 || response.statusCode == 201) ? 'saved' : 'error';
    } catch (e) {
      debugPrint('[SolidsAnalysis] Save error (sample $sampleIdx): $e');
      solidSaveStatus['$sampleIdx']?.value = 'error';
    }
  }

  void _updateResultFromData(int sampleIdx, Map<String, dynamic> data) {
    final result = Map<String, List<String>>.from(solidAnalysisResult);

    void set(String key, dynamic val) {
      result.putIfAbsent(key, () => ['-', '-', '-']);
      final list = List<String>.from(result[key]!);
      while (list.length < 3) { list.add('-'); }
      list[sampleIdx] = _fmt(val);
      result[key] = list;
    }

    // Map backend response fields → dialog row names
    set('LGS (%)',               data['lgsPercent']);
    set('LGS (lb/bbl)',          data['lgsLb']);
    set('HGS (%)',               data['hgsPercent']);
    set('Diss Solids (%)',       data['dissolvedSolids']);
    set('Corr. Solids (%)',      data['correctedSolids']);
    set('Brine SG',              data['brineSG']);
    set('HGS (lb/bbl)',          data['hgsLb']);
    set('Bentonite (%)',         data['bentPercent']);
    set('Bentonite (lb/bbl)',    data['bentoniteLb']);
    set('Drill Solids (%)',      data['drillSolidsPercent']);
    set('Drill Solids (lb/bbl)', data['drillSolidsLb']);
    set('DS/Bent Ratio',         data['dsBentRatio']);
    set('Avg. SG of Solids',     data['avgSG']);

    solidAnalysisResult.value = result;
  }

  Future<void> fetchSolidAnalysis() async {
    isSolidAnalysisLoading.value = true;
    solidAnalysisError.value = '';
    try {
      for (int i = 0; i < 3; i++) { await _saveSolidAnalysis(i); }
    } catch (e) {
      solidAnalysisError.value = e.toString();
    } finally {
      isSolidAnalysisLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // _extractSampleValues — collects all inputs for Solid Analysis backend
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, double> _extractSampleValues(int index) {
    double readField(String? key) {
      if (key == null) return 0;
      final vals = propertyTable[key];
      if (vals == null || index >= vals.length) return 0;
      return double.tryParse(vals[index].value) ?? 0;
    }

    // Read CaCl2 (% wt) — used by backend for Brine Density formula
    // Formula: brineSG = 0.99707 + 0.007923*CaCl2 + 0.00004964*CaCl2²
    final cacl2Pct = readField(_cacl2PctWtKey);

    return {
      'mudWeight':    readField(_mwKey),
      'retortSolids': readField(_solidsKey),
      'oilVol':       readField(_oilKey),
      'waterVol':     readField(_waterKey),
      'bariteLb':     readField(_bariteKey),
      'bentoniteLb':  readField(_bentoniteKey),
      'cacl2Pct':     cacl2Pct,
      // SG values from Specific Gravity panel (user-editable TextControllers)
      'oilSG':   double.tryParse(oilSgController.text)  ?? 0.81,
      'hgsSG':   double.tryParse(hgsSgController.text)  ?? 4.20,
      'lgsSG':   double.tryParse(lgsSgController.text)  ?? 2.60,
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
  }

  void removeAddedPropertyRow(String name) {
    if (name.isEmpty) return;
    propertyTable.remove(name);
  }

  void changeFluidType(String type) {
    selectedFluidType.value = type;
    loadFluidTypeData();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RHEOLOGY
  // ═══════════════════════════════════════════════════════════════════════════

  void _initRheologyTable() => _updateRheologyRows();

  void changeModel(String model) {
    rheologyModel.value = model;
    _updateRheologyRows();
  }

  void _updateRheologyRows() {
    final rows = rheologyModel.value == 'Bingham'
        ? ['600', '300', '200', '100', '6', '3', 'PV (cP)', 'YP (lbf/100ft2)']
        : rheologyModel.value == 'Power Law'
            ? ['600', '300', '200', '100', '6', '3', 'n', 'K (lbf-s^n/100ft2)']
            : ['600', '300', '200', '100', '6', '3', 'Yield Stress (lbf/100ft2)', 'n', 'K (lbf-s^n/100ft2)'];
    rheologyTable.clear();
    for (var r in rows) {
      rheologyTable[r] = List.generate(samples.length, (_) => ''.obs);
    }
  }

  void calculateRheology() {
    for (int i = 0; i < samples.length; i++) {
      final r600 = double.tryParse(rheologyTable['600']?[i].value ?? '') ?? 0;
      final r300 = double.tryParse(rheologyTable['300']?[i].value ?? '') ?? 0;
      final r3   = double.tryParse(rheologyTable['3']?[i].value   ?? '') ?? 0;
      final r6   = double.tryParse(rheologyTable['6']?[i].value   ?? '') ?? 0;

      switch (rheologyModel.value) {
        case 'Bingham':
          if (r600 > 0 || r300 > 0) {
            final pv = r600 - r300;
            rheologyTable['PV (cP)']?[i].value         = pv.toStringAsFixed(1);
            rheologyTable['YP (lbf/100ft2)']?[i].value = (r300 - pv).toStringAsFixed(1);
          }
        case 'Power Law':
          if (r600 > 0 && r300 > 0) {
            final n = 3.32 * _log10(r600 / r300);
            final k = 510 * r300 / _pow(511, n);
            rheologyTable['n']?[i].value                   = n.toStringAsFixed(3);
            rheologyTable['K (lbf-s^n/100ft2)']?[i].value = k.toStringAsFixed(3);
          }
        case 'HB':
          if (r3 > 0 || r6 > 0) {
            rheologyTable['Yield Stress (lbf/100ft2)']?[i].value =
                (2 * r3 - r6).clamp(0.0, double.infinity).toStringAsFixed(2);
          }
          if (r600 > 0 && r300 > 0) {
            final n = 3.32 * _log10(r600 / r300);
            final k = 510 * r300 / _pow(511, n);
            rheologyTable['n']?[i].value                   = n.toStringAsFixed(3);
            rheologyTable['K (lbf-s^n/100ft2)']?[i].value = k.toStringAsFixed(3);
          }
      }
    }
    rheologyTable.refresh();
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
    if (rk == 'yp (lbf/100ft2)' || rk == 'yp') return rn == 'yp' || rn == 'yp (lbf/100ft2)';
    if (rk == 'n' && rn == 'n') return true;
    if (rk.contains('yield stress') && rn.contains('yield')) return true;
    if (rk.contains('k (') && rn.contains('k (')) return true;
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REACTIVE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch one source field → update target (if both exist in propertyTable)
  void _watchOneOpt(int si, String? src, String? target, String Function(String) fn) {
    if (src == null || target == null) return;
    final s = propertyTable[src];
    final t = propertyTable[target];
    if (s == null || t == null || si >= s.length || si >= t.length) return;
    t[si].value = fn(s[si].value);
    ever(s[si], (_) => t[si].value = fn(s[si].value));
  }

  /// Watch two source fields → update target (if all exist in propertyTable)
  void _watchTwoOpt(int si, String? srcA, String? srcB, String? target,
      String Function(String, String) fn) {
    if (srcA == null || srcB == null || target == null) return;
    final a = propertyTable[srcA];
    final b = propertyTable[srcB];
    final t = propertyTable[target];
    if (a == null || b == null || t == null ||
        si >= a.length || si >= b.length || si >= t.length) return;
    t[si].value = fn(a[si].value, b[si].value);
    ever(a[si], (_) => t[si].value = fn(a[si].value, b[si].value));
    ever(b[si], (_) => t[si].value = fn(a[si].value, b[si].value));
  }

  // Keep old _watchOne/_watchTwo signatures for backward compatibility
  void _watchOne(int si, String? src, String target, String Function(String) fn) =>
      _watchOneOpt(si, src, target, fn);

  void _watchTwo(int si, String? srcA, String? srcB, String target,
      String Function(String, String) fn) =>
      _watchTwoOpt(si, srcA, srcB, target, fn);

  // ═══════════════════════════════════════════════════════════════════════════
  // MATH HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  double _log10(double x) => x > 0 ? 0.4342944819 * _ln(x) : 0;

  double _ln(double x) {
    if (x <= 0) return 0;
    double r = 0, y = (x - 1) / (x + 1), y2 = y * y, t = y;
    for (int i = 0; i < 50; i++) { r += t / (2 * i + 1); t *= y2; }
    return 2 * r;
  }

  double _pow(double base, double exp) =>
      base <= 0 ? 0 : _expM(exp * _ln(base));

  double _expM(double x) {
    double r = 1, t = 1;
    for (int i = 1; i <= 50; i++) { t *= x / i; r += t; }
    return r;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onClose() {
    for (final t in _debounceTimers.values) { t?.cancel(); }
    fluidnameController.dispose();
    oilSgController.dispose();
    hgsSgController.dispose();
    lgsSgController.dispose();
    shaleCecController.dispose();
    bentCecController.dispose();
    super.onClose();
  }
}