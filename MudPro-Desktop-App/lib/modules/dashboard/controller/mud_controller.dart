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
  final oilSgController     = TextEditingController(text: '0.81');
  final hgsSgController     = TextEditingController(text: '4.10');
  final lgsSgController     = TextEditingController(text: '2.40');
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

  // Retort solids input row — "*Solids (% vol)" from API
  // After _findKey strips '*': "solids (% vol)"
  // Must NOT match "Total Solids", "Corrected Solids", "Drill Solids"
  // Must NOT match the auto-calc Total Solids output row
  String? get _solidsKey => _findKey((k) =>
      (k == 'solids' || k.startsWith('solids') || k == 'retort solids') &&
      !k.contains('total') && !k.contains('corr') &&
      !k.contains('drill') && !k.contains('adj') && !k.contains('salt'));

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
  // Must match: "Whole Mud Chlorides (mg/l)", "Whole Mud Chlorides"
  // Must NOT match: "Mud Alkalinity", "Water", or other mud fields
  String? get _wholeMudChlorideKey => _findKey((k) =>
      k.contains('whole mud chloride') ||
      k == 'whole mud chlorides' ||
      (k.contains('chloride') && k.contains('mud') && !k.contains('calcium')));

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

  // "Total Solids" OUTPUT row — auto-calculated as 100-(Oil+Water)
  // Must NOT match "*Solids (% vol)" retort input row
  String? get _totalSolidsKey => _findKey((k) =>
      (k == 'total solids' || k.contains('total solids')) &&
      !k.contains('corr') && !k.contains('drill'));

  String? get _correctedSolidsKey => _findKey((k) =>
      k.contains('corrected solids') || k.contains('corr. solids'));

  String? get _excessLimeKey => _findKey((k) =>
      k.contains('excess lime'));

  String? get _wholeMudAlkKey => _findKey((k) =>
      (k.contains('whole mud alkalinity') || k.contains('alkalinity (pom)') ||
       k.contains('alkalinity(pom)') || k.contains('mud alkalinity (pm)')));

  // Water Phase Salinity (WPS) ppm — first WPS row
  // Excel row 55: =IFERROR(10000*L54,"")  — L54=CaCl2(% wt)
  String? get _wpsSaltPercentKey => _findKey((k) =>
      (k.contains('water phase salinity') || k.contains('water phase sal')) &&
      k.contains('ppm'));

  // Water Phase Salinity (WPS) mg/l — second WPS row
  // Excel row 56: =IFERROR(10000*L54*L61,"")  — L54=CaCl2(% wt), L61=Brine Density SG
  String? get _wpsSaltPpmKey => _findKey((k) =>
      (k.contains('water phase salinity') || k.contains('water phase sal')) &&
      (k.contains('mg') || k.contains('mg/l')));

  // Brine Density (SG) — L61 in Excel, used for WPS mg/l calculation
  // This is in the Solid Analysis section of the table
  String? get _brineDensitySgKey => _findKey((k) =>
      k == 'brine density' ||
      k.contains('brine density') ||
      k == 'brine density (sg)' ||
      k == 'brine sg');

  String? get _bariteKey => _findKey((k) =>
      k == 'barite' || (k.contains('barite') && !k.contains('brine')));

  String? get _bentoniteKey => _findKey((k) =>
      k == 'bentonite' || k.contains('bentonite'));

  String? get _brineDensityKey => _findKey((k) =>
      k == 'brine density' || k.contains('brine density'));

  // ── WBM-specific key getters ─────────────────────────────────────────────
  // Sand Content row — WBM auto-calc
  String? get _sandContentKey => _findKey((k) =>
      k == 'sand content' || k.contains('sand content'));

  // Filtrate Alkalinity (Pf) — WBM auto-calc = API Filtrate × 1.295
  String? get _filtAlkPfKey => _findKey((k) =>
      k.contains('filtrate alkalinity') && (k.contains('pf') || k.contains('(pf)')));

  // Filtrate Alkalinity (Mf) — WBM auto-calc = Mud Filtrate × 1.295
  String? get _filtAlkMfKey => _findKey((k) =>
      k.contains('filtrate alkalinity') && (k.contains('mf') || k.contains('(mf)')));

  // Calcium — WBM auto-calc = 1.565 × Chlorides
  String? get _calciumKey => _findKey((k) =>
      k == 'calcium' || k.startsWith('calcium') && !k.contains('chloride'));

  // Chlorides input — WBM source for Calcium and Mud Chlorides
  // Must NOT match 'whole mud chlorides' (that's OBM)
  String? get _chloridesInputKey => _findKey((k) =>
      (k == 'chlorides' || k.startsWith('chlorides') || k == '*chlorides') &&
      !k.contains('whole') && !k.contains('mud') && !k.contains('calcium'));

  // Mud Chlorides — WBM auto-calc = 10000 × CaCl2 (% wt)
  String? get _mudChloridesMglKey => _findKey((k) =>
      (k.contains('mud chloride') || k == 'mud chlorides') &&
      !k.contains('whole'));

  // KCl — WBM auto-calc = 10000 × CaCl2 × BrineSG
  String? get _kclKey => _findKey((k) =>
      k == 'kcl' || k.startsWith('kcl'));

  // API Filtrate — source for Filtrate Alkalinity Pf (WBM)
  String? get _apiFiltratePfKey => _findKey((k) =>
      k.contains('api filtrate') ||
      (k.contains('filtrate') && !k.contains('alkalinity') && !k.contains('hthp')));

  // Mud Filtrate — source for Filtrate Alkalinity Mf (WBM)
  String? get _mudFiltrateMfKey => _findKey((k) =>
      (k == 'mud filtrate' || k.contains('mud filtrate') || k.contains('filtrate alkalinity (mf)')) &&
      !k.contains('api') && !k.contains('hthp') && !k.contains('alkalinity'));

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
    debugPrint('[AutoCalc] _wpsSaltPercentKey(ppm)=$_wpsSaltPercentKey  _wpsSaltPpmKey(mgl)=$_wpsSaltPpmKey  _brineDensitySgKey=$_brineDensitySgKey');

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

      // ── 5. Solids (% vol) = 100 − (Oil% + Water%) ─────────────────────────
      //    Excel: =IF(100-(L46+L47)<100, 100-(L46+L47), "")
      //    This applies to BOTH "Solids (% vol)" and "Total Solids (% vol)"
      final solidsTarget = _solidsKey;
      final tsTarget     = _totalSolidsKey;
      _watchTwoOpt(i, _oilKey, _waterKey, solidsTarget, (a, b) {
        final oil   = double.tryParse(a) ?? 0;
        final water = double.tryParse(b) ?? 0;
        if (oil == 0 && water == 0) return '';
        final solids = 100 - (oil + water);
        return solids < 100 ? solids.toStringAsFixed(2) : '';
      });
      if (tsTarget != null && tsTarget != solidsTarget) {
        _watchTwoOpt(i, _oilKey, _waterKey, tsTarget, (a, b) {
          final oil   = double.tryParse(a) ?? 0;
          final water = double.tryParse(b) ?? 0;
          if (oil == 0 && water == 0) return '';
          final solids = 100 - (oil + water);
          return solids < 100 ? solids.toStringAsFixed(2) : '';
        });
      }

      // ── 6. Corrected Solids = 100 − (Oil% + Brine%) ──────────────────────
      //    Excel: =IFERROR(100-(L46+L62),"")
      //    L46=Oil%, L62=Brine(% vol).
      //    Brine(% vol) is NOT always a row. We calculate it.
      final csTarget = _correctedSolidsKey;
      if (csTarget != null) {
        void recalcCorrectedSolids() {
          final oilVal    = propertyTable[_oilKey]?[i].value ?? '';
          final waterVal  = propertyTable[_waterKey]?[i].value ?? '';
          final saltPctVal = propertyTable[_cacl2PctWtKey]?[i].value ?? '';

          final O = double.tryParse(oilVal) ?? 0;
          final W = double.tryParse(waterVal) ?? 0;
          final S = double.tryParse(saltPctVal) ?? 0;

          if (O == 0 && W == 0) {
            propertyTable[csTarget]?[i].value = '';
            return;
          }

          // Brine Density SG = 0.99707 + (0.007923 * S) + (0.00004964 * S^2)
          final brineSG = 0.99707 + (0.007923 * S) + (0.00004964 * S * S);
          // Brine Vol % = (W * 100) / (BrineSG * (100 - S) * 0.99707)
          // Matching Excel logic exactly
          final brineVol = (100 * W) / (brineSG * (100 - S) * 0.99707);

          propertyTable[csTarget]?[i].value = (100 - (O + brineVol)).toStringAsFixed(2);
        }

        ever(propertyTable[_oilKey]![i], (_) => recalcCorrectedSolids());
        ever(propertyTable[_waterKey]![i], (_) => recalcCorrectedSolids());
        if (_cacl2PctWtKey != null) {
          ever(propertyTable[_cacl2PctWtKey!]![i], (_) => recalcCorrectedSolids());
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

      // ── 11. Water Phase Salinity (WPS) ppm = CaCl2(% wt) × 10000 ──────────
      //    Excel row 55: =IFERROR(10000*L54,"")
      //    L54 = CaCl2 (% wt) — auto-calc field
      final wpsTarget = _wpsSaltPercentKey;
      if (wpsTarget != null) {
        _watchOneOpt(i, _cacl2PctWtKey, wpsTarget, (a) {
          final v = double.tryParse(a) ?? 0;
          return v == 0 ? '' : (v * 10000).toStringAsFixed(0);
        });
      }

      // ── 12. Water Phase Salinity (WPS) mg/l = CaCl2(% wt) × 10000 × BrineDensity(SG)
      //    Excel row 56: =IFERROR(10000*L54*L61,"")
      //    L54 = CaCl2 (% wt), L61 = Brine Density (SG)
      final wpsMglTarget = _wpsSaltPpmKey;
      if (wpsMglTarget != null) {
        void recalcWpsMgl() {
          final saltPctVal = propertyTable[_cacl2PctWtKey]?[i].value ?? '';
          final S = double.tryParse(saltPctVal) ?? 0;
          if (S == 0) {
            propertyTable[wpsMglTarget]?[i].value = '';
            return;
          }
          final brineSG = 0.99707 + (0.007923 * S) + (0.00004964 * S * S);
          propertyTable[wpsMglTarget]?[i].value = (S * 10000 * brineSG).toStringAsFixed(0);
        }

        if (_cacl2PctWtKey != null) {
          ever(propertyTable[_cacl2PctWtKey!]![i], (_) => recalcWpsMgl());
        }
      }

      // ── 13. Brine Density (SG) Row (if exists) ───────────────────────────
      final bdTarget = _brineDensitySgKey;
      if (bdTarget != null) {
        _watchOneOpt(i, _cacl2PctWtKey, bdTarget, (a) {
          final s = double.tryParse(a) ?? 0;
          if (s == 0) return '';
          return (0.99707 + (0.007923 * s) + (0.00004964 * s * s)).toStringAsFixed(3);
        });
      }

      // ── WBM-only auto-calculations ──────────────────────────────────────
      if (selectedFluidType.value == 'Water-based') {

        // WBM-1. Sand Content = ROUNDUP(100*Solids/(Solids+Oil)) & "/" & ROUNDDOWN(100*Oil/(Oil+Solids))
        //   Excel: =IFERROR(ROUNDUP(100*L46/(L46+L47),0) & "/" & ROUNDDOWN(100*L47/(L47+L46),0), "")
        //   L46 = *Solids (% vol), L47 = *Oil (% vol)  [for WBM, 'Oil' cell holds the sand fraction]
        final scTarget = _sandContentKey;
        if (scTarget != null) {
          _watchTwoOpt(i, _solidsKey, _oilKey, scTarget, (a, b) {
            final s = double.tryParse(a) ?? 0;
            final o = double.tryParse(b) ?? 0;
            if (s == 0 && o == 0) return '';
            final total = s + o;
            if (total == 0) return '';
            return '${(100 * s / total).ceil()}/${(100 * o / total).floor()}';
          });
        }

        // WBM-3. Filtrate Alkalinity (Mf) = API Filtrate × 1.295
        //   Source: API Filtrate (L49 in Excel)
        final filtMfTarget = _filtAlkMfKey;
        if (filtMfTarget != null) {
          _watchOneOpt(i, _apiFiltratePfKey, filtMfTarget, (a) {
            final v = double.tryParse(a) ?? 0;
            return v == 0 ? '' : (v * 1.295).toStringAsFixed(2);
          });
        }

        // WBM-4. Calcium = 1.565 × Chlorides
        //   Excel: =1.565*L51  — L51 = Chlorides
        final calciumTarget = _calciumKey;
        if (calciumTarget != null) {
          _watchOneOpt(i, _chloridesInputKey, calciumTarget, (a) {
            final v = double.tryParse(a) ?? 0;
            return v == 0 ? '' : (v * 1.565).toStringAsFixed(2);
          });
        }

        // WBM-5. Mud Chlorides = 10000 × CaCl2 (% wt)
        //   Excel: =IFERROR(10000*L54,"")  — L54 = CaCl2 (% wt)
        final mudChlTarget = _mudChloridesMglKey;
        if (mudChlTarget != null) {
          _watchOneOpt(i, _cacl2PctWtKey, mudChlTarget, (a) {
            final v = double.tryParse(a) ?? 0;
            return v == 0 ? '' : (v * 10000).toStringAsFixed(0);
          });
        }

        // WBM-6. KCl = 10000 × CaCl2 (% wt) × BrineSG
        //   Excel: =IFERROR(10000*L54*L61,"")  — L54=CaCl2, L61=BrineSG
        final kclTarget = _kclKey;
        if (kclTarget != null) {
          _watchOneOpt(i, _cacl2PctWtKey, kclTarget, (a) {
            final s = double.tryParse(a) ?? 0;
            if (s == 0) return '';
            final brineSG = 0.99707 + (0.007923 * s) + (0.00004964 * s * s);
            return (s * 10000 * brineSG).toStringAsFixed(0);
          });
        }
      }
    } // end for loop
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
    // Solids row - MUST match _solidsKey logic and be read-only
    if ((k == 'solids' || k.startsWith('solids') || k == 'retort solids') &&
        !k.contains('total') && !k.contains('corr') &&
        !k.contains('drill') && !k.contains('adj') && !k.contains('salt')) return true;

    // Total Solids output row only — NOT "*Solids (% vol)" retort input
    if ((k == 'total solids' || k.contains('total solids')) &&
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
    // WBM auto-calc fields
    if (k == 'sand content' || k.contains('sand content')) return true;
    if (k.contains('filtrate alkalinity') && (k.contains('mf') || k.contains('(mf)'))) return true;
    if (k == 'calcium' || (k.startsWith('calcium') && !k.contains('chloride'))) return true;
    if ((k.contains('mud chloride') || k == 'mud chlorides') && !k.contains('whole')) return true;
    if (k == 'kcl' || k.startsWith('kcl')) return true;
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
        'fluidType':    selectedFluidType.value,  // WBM vs OBM branching
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