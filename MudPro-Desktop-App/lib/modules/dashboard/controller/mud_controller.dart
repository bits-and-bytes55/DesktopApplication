import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/mud_properties_controller.dart';
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

// ─── Change to your actual backend base URL ───────────────────────────────────
const String _kBaseUrl = ApiEndpoint.baseUrl;

// ─── Debounce duration: waits this long after last keystroke before saving ────
const Duration _kSaveDebounce = Duration(milliseconds: 800);

class MudController extends GetxController {
  final samples = ['1', '2', '3', 'Plan-L', 'Plan-H'];

  final _mudPropsCtrl   = MudPropertiesController();
  final othersController = OthersController();

  var selectedFluidType = 'Water-based'.obs;

  final propertyTable      = <String, List<RxString>>{}.obs;
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

  // ── Solid Analysis state ────────────────────────────────────────────────────
  // Results shown in the dialog (map of row-name → [sample1, sample2, sample3])
  final solidAnalysisResult  = <String, List<String>>{}.obs;
  var isSolidAnalysisLoading = false.obs;
  var solidAnalysisError     = ''.obs;

  // ── Upsert tracking ────────────────────────────────────────────────────────
  // One DB record id per sample index (0=sample1, 1=sample2, 2=sample3)
  // null = not yet created, non-null = PUT to update
  final _solidAnalysisIds = <int, String?>{0: null, 1: null, 2: null};

  // One debounce timer per sample slot
  final _debounceTimers = <int, Timer?>{};

  // Save-status indicator per sample (for optional UI dot)
  // 'idle' | 'saving' | 'saved' | 'error'
  final solidSaveStatus = <String, RxString>{
    '0': 'idle'.obs,
    '1': 'idle'.obs,
    '2': 'idle'.obs,
  };

  // ── Source field names for solid-analysis inputs ────────────────────────────
  // These must match keys in propertyTable (case-insensitive lookup in _findKey)
  static const _kMW         = 'mw';
  static const _kSolids     = 'solids';
  static const _kOil        = 'oil';
  static const _kWater      = 'water';
  static const _kBarite     = 'barite';
  static const _kBentonite  = 'bentonite';

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
      // Reset upsert IDs when fluid type changes
      for (int i = 0; i < 3; i++) { _solidAnalysisIds[i] = null; }

      await Future.wait([
        _loadLeftTableFromMudProperties(),
        _loadDropdownFromOthers(),
      ]);

      _setupAutoCalculations();
      _setupSolidAnalysisWatchers(); // wire debounced save
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
      List<String> props = switch (selectedFluidType.value) {
        'Water-based' => selected.waterBased,
        'Oil-based'   => selected.oilBased,
        'Synthetic'   => selected.synthetic,
        _             => <String>[],
      };
      _addCommonFields();
      for (final name in props) {
        if (name.isNotEmpty) {
          propertyTable[name] = List.generate(samples.length, (_) => ''.obs);
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
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI AUTO-CALCULATIONS (instant, no API)
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupAutoCalculations() {
    for (int i = 0; i < samples.length; i++) {
      // 1. Oil/Water Ratio
      _watchTwo(i, _oilKey, _waterKey, 'Oil/water Ratio', (a, b) {
        final oil   = double.tryParse(a) ?? 0;
        final water = double.tryParse(b) ?? 0;
        if (oil <= 0 && water <= 0) return '';
        if (water == 0) return '${oil.toStringAsFixed(0)}/0';
        return (oil / water).toStringAsFixed(2);
      });

      // 2. Excess Lime = Alkalinity Mud × 1.3
      _watchOne(i, _alkalinityKey, 'Excess Lime', (a) {
        final v = double.tryParse(a) ?? 0;
        return v == 0 ? '' : (v * 1.3).toStringAsFixed(2);
      });

      // 3. Solids Adjusted for Salt (approximate)
      _watchTwo(i, _solidsKey, _waterKey, 'Solids Adjusted for Salt', (a, b) {
        final solids = double.tryParse(a) ?? 0;
        final water  = double.tryParse(b) ?? 0;
        if (solids == 0) return '';
        return (solids - water * 0.02).clamp(0, 100).toStringAsFixed(2);
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBOUNCED SOLID ANALYSIS SAVE WATCHERS
  // Watches the 5 source fields for each of the first 3 samples.
  // On any change → debounce 800ms → POST (first time) or PUT (subsequent).
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupSolidAnalysisWatchers() {
    for (int si = 0; si < 3; si++) {
      final sampleIdx = si;

      // All 5 fields that drive solid analysis — fetched fresh each time
      // so newly added rows (barite, bentonite etc.) are picked up too
      final sourceKeys = [
        _mwKey,
        _solidsKey,
        _bariteKey,
        _bentoniteKey,
        _brineDensityKey,
      ];

      for (final key in sourceKeys) {
        if (key == null) continue;
        final list = propertyTable[key];
        if (list == null || sampleIdx >= list.length) continue;

        ever(list[sampleIdx], (_) {
          _scheduleSolidAnalysisSave(sampleIdx);
        });
      }
    }
  }

  /// Cancel any pending timer for this sample, start a new one.
  void _scheduleSolidAnalysisSave(int sampleIdx) {
    _debounceTimers[sampleIdx]?.cancel();
    solidSaveStatus['$sampleIdx']?.value = 'idle';

    _debounceTimers[sampleIdx] = Timer(_kSaveDebounce, () {
      _saveSolidAnalysis(sampleIdx);
    });
  }

  /// POST (first time) or PUT (subsequent) for the given sample index.
  Future<void> _saveSolidAnalysis(int sampleIdx) async {
    final vals = _extractSampleValues(sampleIdx);

    // Skip if no mud weight — nothing to calculate
    if (vals['mudWeight'] == 0) return;

    solidSaveStatus['$sampleIdx']?.value = 'saving';

    try {
      final body = jsonEncode({
        'mudWeight':    vals['mudWeight'],
        'retortSolids': vals['retortSolids'],
        'bariteLb':     vals['bariteLb'],
        'bentoniteLb':  vals['bentoniteLb'],
        'brineSG':      vals['brineSG'],
        'sampleIndex':  sampleIdx,
      });

      final existingId = _solidAnalysisIds[sampleIdx];
      http.Response response;

      if (existingId == null) {
        // ── First save → POST ──────────────────────────────────────────
        response = await http.post(
          Uri.parse('${_kBaseUrl}solids'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
        if (response.statusCode == 201) {
          final data = jsonDecode(response.body)['data'];
          _solidAnalysisIds[sampleIdx] = data['_id'] as String?;
          debugPrint('[SolidsAnalysis] Sample $sampleIdx CREATED — id: ${_solidAnalysisIds[sampleIdx]}');
          _updateResultFromData(sampleIdx, data);
        }
      } else {
        // ── Subsequent save → PUT ──────────────────────────────────────
        response = await http.put(
          Uri.parse('${_kBaseUrl}solids/$existingId'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'];
          debugPrint('[SolidsAnalysis] Sample $sampleIdx UPDATED — id: $existingId');
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

  /// Writes one sample column of values into solidAnalysisResult.
  void _updateResultFromData(int sampleIdx, Map<String, dynamic> data) {
    final result = Map<String, List<String>>.from(solidAnalysisResult);

    void set(String key, dynamic val) {
      result.putIfAbsent(key, () => ['-', '-', '-']);
      final list = List<String>.from(result[key]!);
      while (list.length < 3) { list.add('-'); }
      list[sampleIdx] = _fmt(val);
      result[key] = list;
    }

    set('LGS (%)',             data['lgsPercent']);
    set('LGS (lb/bbl)',        data['lgsLb']);
    set('HGS (%)',             data['hgsPercent']);
    set('Diss Solids (%)',     data['dissolvedSolids']);
    set('Corr. Solids (%)',    data['correctedSolids']);
    set('Brine SG',            data['brineSG']);
    set('HGS (lb/bbl)',        data['hgsLb']);
    set('Bentonite (%)',       data['bentPercent']);
    set('Bentonite (lb/bbl)', data['bentoniteLb']);
    set('Drill Solids (%)',   data['drillSolidsPercent']);
    set('Drill Solids (lb/bbl)', data['drillSolidsLb']);
    set('DS/Bent Ratio',      data['dsBentRatio']);
    set('Avg. SG of Solids', data['avgSG']);

    solidAnalysisResult.value = result;
  }

  // ─── Also keep the manual "open dialog" fetch ───────────────────────────────
  // When dialog opens, load all 3 samples at once if any are missing.
  Future<void> fetchSolidAnalysis() async {
    isSolidAnalysisLoading.value = true;
    solidAnalysisError.value = '';

    try {
      for (int i = 0; i < 3; i++) {
        await _saveSolidAnalysis(i);
      }
    } catch (e) {
      solidAnalysisError.value = e.toString();
    } finally {
      isSolidAnalysisLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS: field lookup + value extraction
  // ═══════════════════════════════════════════════════════════════════════════

  String? _findKey(bool Function(String) test) {
    for (final key in propertyTable.keys) {
      if (test(key.toLowerCase().replaceAll('*', '').trim())) return key;
    }
    return null;
  }

  // ── Field key getters — match property table row names (strip * prefix) ──────
  // Note: _findKey() strips '*' before calling the test, so we never see '*' here.
  String? get _mwKey => _findKey((k) =>
      k == 'mw' || k.contains('mud weight'));

  String? get _solidsKey => _findKey((k) =>
      k == 'solids' &&
      !k.contains('drill') && !k.contains('adj') && !k.contains('salt'));

  String? get _oilKey => _findKey((k) =>
      k == 'oil' &&
      !k.contains('ratio') && !k.contains('sg') && !k.contains('water'));

  String? get _waterKey => _findKey((k) =>
      k == 'water' &&
      !k.contains('activity') && !k.contains('sg') && !k.contains('oil'));

  String? get _alkalinityKey => _findKey((k) => k.contains('alkalinity mud'));

  // Barite: exact 'barite' field
  String? get _bariteKey => _findKey((k) =>
      k == 'barite' || k.contains('barite') && !k.contains('brine'));

  // Bentonite lb/bbl field directly
  String? get _bentoniteKey => _findKey((k) =>
      k == 'bentonite' || k.contains('bentonite'));

  // Brine density field (oil-based muds) in ppg
  String? get _brineDensityKey => _findKey((k) =>
      k == 'brine density' || k.contains('brine density'));

  Map<String, double> _extractSampleValues(int index) {
    double mw = 0, solids = 0, oil = 0, water = 0, barite = 0, bentonite = 0;
    double brineDensityDirect = 0; // ppg, if available directly

    double _readField(String? key) {
      if (key == null) return 0;
      final vals = propertyTable[key];
      if (vals == null || index >= vals.length) return 0;
      return double.tryParse(vals[index].value) ?? 0;
    }

    mw              = _readField(_mwKey);
    solids          = _readField(_solidsKey);
    oil             = _readField(_oilKey);
    water           = _readField(_waterKey);
    barite          = _readField(_bariteKey);
    bentonite       = _readField(_bentoniteKey);
    brineDensityDirect = _readField(_brineDensityKey);

    // ── Brine SG ──────────────────────────────────────────────────────────
    // Priority 1: direct "Brine Density" field in ppg → convert to SG
    // Priority 2: default 1.00 (fresh water) — safe for water-based muds
    // We do NOT derive brine SG from mass balance here because it requires
    // accurate retort oil/water/solids fractions that may not be filled yet,
    // and produces garbage (10.56 etc.) when fields are partially filled.
    double brineSg = 1.00;
    if (brineDensityDirect > 0) {
      brineSg = (brineDensityDirect / 8.33).clamp(0.9, 2.5);
    }

    return {
      'mudWeight':    mw,
      'retortSolids': solids,
      'bariteLb':     barite,
      'bentoniteLb':  bentonite,
      'brineSG':      brineSg,
    };
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    final d = double.tryParse(v.toString());
    return d == null ? v.toString() : d.toStringAsFixed(2);
  }

  bool isAutoCalc(String fieldName) {
    final k = fieldName.toLowerCase().replaceAll('*', '').trim();
    return k == 'oil/water ratio' || k == 'excess lime' || k == 'solids adjusted for salt';
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
      if (double.tryParse(entry.key) != null) continue; // skip RPM rows
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
    // No snackbar — silent transfer
  }

  bool _rowMatches(String rowName, String rheologyKey) {
    final rn = rowName.toLowerCase().replaceAll('*', '').trim();
    final rk = rheologyKey.toLowerCase().trim();

    // PV — exact field only, must NOT match "t. for pv" or "t for pv"
    if (rk == 'pv (cp)' || rk == 'pv') {
      return rn == 'pv' || rn == 'pv (cp)';
    }
    // YP
    if (rk == 'yp (lbf/100ft2)' || rk == 'yp') {
      return rn == 'yp' || rn == 'yp (lbf/100ft2)';
    }
    // n, K, Yield Stress for Power Law / HB
    if (rk == 'n'                   && rn == 'n')              return true;
    if (rk.contains('yield stress') && rn.contains('yield'))   return true;
    if (rk.contains('k (')          && rn.contains('k ('))     return true;
    return false;
  }

  // ─── Reactive helpers ──────────────────────────────────────────────────────

  void _watchOne(int si, String? src, String target, String Function(String) fn) {
    if (src == null) return;
    final s = propertyTable[src];
    final t = propertyTable[target];
    if (s == null || t == null || si >= s.length || si >= t.length) return;
    t[si].value = fn(s[si].value);
    ever(s[si], (_) => t[si].value = fn(s[si].value));
  }

  void _watchTwo(int si, String? srcA, String? srcB, String target,
      String Function(String, String) fn) {
    if (srcA == null || srcB == null) return;
    final a = propertyTable[srcA];
    final b = propertyTable[srcB];
    final t = propertyTable[target];
    if (a == null || b == null || t == null ||
        si >= a.length || si >= b.length || si >= t.length) return;
    t[si].value = fn(a[si].value, b[si].value);
    ever(a[si], (_) => t[si].value = fn(a[si].value, b[si].value));
    ever(b[si], (_) => t[si].value = fn(a[si].value, b[si].value));
  }

  // ─── Math ──────────────────────────────────────────────────────────────────

  double _log10(double x) => x > 0 ? 0.4342944819 * _ln(x) : 0;

  double _ln(double x) {
    if (x <= 0) return 0;
    double r = 0, y = (x - 1) / (x + 1), y2 = y * y, t = y;
    for (int i = 0; i < 50; i++) { r += t / (2 * i + 1); t *= y2; }
    return 2 * r;
  }

  double _pow(double base, double exp) => base <= 0 ? 0 : _expM(exp * _ln(base));

  double _expM(double x) {
    double r = 1, t = 1;
    for (int i = 1; i <= 50; i++) { t *= x / i; r += t; }
    return r;
  }

  // ─── Dispose ───────────────────────────────────────────────────────────────

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