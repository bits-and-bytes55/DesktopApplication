import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/pump_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/sce_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// ─── Local row model for Pump page ────────────────────────────────────────────
class _PumpRow {
  String? id;
  int rowNumber = 0;
  final RxString model = ''.obs;
  final RxString type = ''.obs;
  final RxString linerId = ''.obs;
  final RxString rodOd = ''.obs;
  final RxString strokeLength = ''.obs;
  final RxString efficiency = ''.obs;
  final RxString displacement = ''.obs;
  final RxString spm = ''.obs;
  final RxString rate = ''.obs;

  bool get hasData => model.value.isNotEmpty;

  void clear() {
    id = null;
    model.value = '';
    type.value = '';
    linerId.value = '';
    rodOd.value = '';
    strokeLength.value = '';
    efficiency.value = '';
    displacement.value = '';
    spm.value = '';
    rate.value = '';
  }

  void recalculateRate() {
    final displacementValue = double.tryParse(displacement.value) ?? 0;
    final s = double.tryParse(spm.value) ?? 0;
    if (displacementValue <= 0 || s <= 0) {
      rate.value = '';
      return;
    }
    final displacementBase =
        AppUnits.convertValue(
          displacementValue,
          AppUnits.strokeDisplacement,
          '(bbl/stk)',
        ) ??
        displacementValue;
    final rateBase = displacementBase * s * 42;
    final rateValue =
        AppUnits.convertValue(rateBase, '(gpm)', AppUnits.drillingFlowRate) ??
        rateBase;
    rate.value = rateValue.toStringAsFixed(1);
  }
}

// ─── Local row models for SCE ─────────────────────────────────────────────────
class _ShakerRow {
  String? id;
  final RxString shakerType = ''.obs;
  final RxString model = ''.obs;
  final RxString screen1 = ''.obs;
  final RxString screen2 = ''.obs;
  final RxString screen3 = ''.obs;
  final RxString screen4 = ''.obs;
  final RxString screen5 = ''.obs;
  final RxString screen6 = ''.obs;
  final RxString screen7 = ''.obs;
  final RxString screen8 = ''.obs;
  final RxString time = ''.obs;
  final RxString oocWt = ''.obs;
  final RxInt enabledScreens = 0.obs;

  bool get hasData => model.value.isNotEmpty || shakerType.value.isNotEmpty;
}

class _OtherSceRow {
  String? id;
  final RxString type = ''.obs;
  final RxString model = ''.obs;
  final RxString uf = ''.obs;
  final RxString of_ = ''.obs;
  final RxString time = ''.obs;
  final RxString oocWt = ''.obs;

  bool get hasData => type.value.isNotEmpty || model.value.isNotEmpty;
}

class _ReportSaveScope {
  final String wellId;
  final String reportId;

  const _ReportSaveScope({required this.wellId, required this.reportId});

  bool get isValid => wellId.trim().isNotEmpty && reportId.trim().isNotEmpty;
}

// ─── PumpPage ─────────────────────────────────────────────────────────────────
class PumpPage extends StatefulWidget {
  const PumpPage({super.key});

  @override
  State<PumpPage> createState() => _PumpPageState();
}

class _PumpPageState extends State<PumpPage> {
  late final PumpController pumpController;
  late final SceController sceController;
  late final DashboardController dashboard;
  final ReportApiService _reportApi = ReportApiService();
  final List<Worker> _unitWorkers = <Worker>[];
  Worker? _wellWorker;
  Worker? _reportWorker;
  final Map<_ShakerRow, Timer> _shakerSaveTimers = {};
  final Map<_OtherSceRow, Timer> _otherSceSaveTimers = {};
  final Map<_PumpRow, Timer> _pumpSaveTimers = {};
  final Map<_ShakerRow, _ReportSaveScope> _shakerSaveScopes = {};
  final Map<_OtherSceRow, _ReportSaveScope> _otherSceSaveScopes = {};
  final Map<_PumpRow, _ReportSaveScope> _pumpSaveScopes = {};
  Timer? _pumpSummarySaveTimer;
  _ReportSaveScope? _pumpSummarySaveScope;
  Map<String, String>? _pumpSummarySaveValues;
  final RxString _summaryPumpRate = ''.obs;
  final RxString _summaryPumpPressure = ''.obs;
  final RxString _summaryDhToolsLoss = ''.obs;
  final RxString _summaryMotorLoss = ''.obs;
  late String _diameterUnit;
  late String _lengthUnit;
  late String _displacementUnit;
  late String _flowUnit;
  late String _pressureUnit;
  late String _powerUnit;
  late String _mudWeightUnit;

  final ScrollController shakerScrollController = ScrollController();
  final ScrollController sceScrollController = ScrollController();

  // RxList so Obx can react to new rows being added
  final RxList<_PumpRow> _pumpRows = <_PumpRow>[].obs;
  final RxList<_ShakerRow> _shakerRows = <_ShakerRow>[].obs;
  final RxList<_OtherSceRow> _sceRows = <_OtherSceRow>[].obs;

  final RxString _screenFillSelected = ''.obs;
  int? _activeScreenRowIndex;
  int? _activeScreenColumnIndex;

  static const int _totalScreenCols = 8;
  static const List<String> _screenValueOptions = [
    '270',
    '230',
    '200',
    '170',
    '140',
    '120',
    '100',
    '80',
    '60',
    '40',
  ];

  // ── How many blank rows to keep at the bottom of each table ──────
  static const int _initialPumpRows = 4;
  static const int _initialShakerRows = 4;
  static const int _initialSceRows = 4;
  static const double _pumpTableWidth = 712;
  static const double _shakerTableWidth = 760;
  static final Map<String, List<Map<String, dynamic>>> _cachedShakerRows = {};
  static final Map<String, List<Map<String, dynamic>>> _cachedOtherSceRows = {};

  @override
  void initState() {
    super.initState();
    pumpController = Get.isRegistered<PumpController>()
        ? Get.find<PumpController>()
        : Get.put(PumpController());
    sceController = Get.isRegistered<SceController>()
        ? Get.find<SceController>()
        : Get.put(SceController());
    dashboard = Get.find<DashboardController>();
    _diameterUnit = AppUnits.diameter;
    _lengthUnit = AppUnits.length;
    _displacementUnit = AppUnits.strokeDisplacement;
    _flowUnit = AppUnits.drillingFlowRate;
    _pressureUnit = AppUnits.pressure;
    _powerUnit = AppUnits.power;
    _mudWeightUnit = AppUnits.mudWeight;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);

    // Seed with initial empty rows
    _pumpRows.addAll(List.generate(_initialPumpRows, (_) => _PumpRow()));
    _shakerRows.addAll(List.generate(_initialShakerRows, (_) => _ShakerRow()));
    _sceRows.addAll(List.generate(_initialSceRows, (_) => _OtherSceRow()));
    _wellWorker = ever<String>(
      padWellContext.selectedWellId,
      (_) => _loadReportRows(),
    );
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => _loadReportRows(),
    );
    _unitWorkers.addAll([
      ever(sceController.shakers, (_) => _loadReportSceRows()),
      ever(sceController.otherSce, (_) => _loadReportSceRows()),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReportRows());
  }

  @override
  void deactivate() {
    unawaited(_flushPendingPageSaves());
    super.deactivate();
  }

  @override
  void dispose() {
    unawaited(_flushPendingPageSaves());
    for (final timer in _shakerSaveTimers.values) {
      timer.cancel();
    }
    for (final timer in _otherSceSaveTimers.values) {
      timer.cancel();
    }
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    shakerScrollController.dispose();
    sceScrollController.dispose();
    super.dispose();
  }

  void _handleUnitChange() {
    final nextDiameterUnit = AppUnits.diameter;
    final nextLengthUnit = AppUnits.length;
    final nextDisplacementUnit = AppUnits.strokeDisplacement;
    final nextFlowUnit = AppUnits.drillingFlowRate;
    final nextPressureUnit = AppUnits.pressure;
    final nextPowerUnit = AppUnits.power;
    final nextMudWeightUnit = AppUnits.mudWeight;
    if (_diameterUnit == nextDiameterUnit &&
        _lengthUnit == nextLengthUnit &&
        _displacementUnit == nextDisplacementUnit &&
        _flowUnit == nextFlowUnit &&
        _pressureUnit == nextPressureUnit &&
        _powerUnit == nextPowerUnit &&
        _mudWeightUnit == nextMudWeightUnit) {
      return;
    }

    for (final row in _pumpRows) {
      row.linerId.value = _convertText(
        row.linerId.value,
        _diameterUnit,
        nextDiameterUnit,
      );
      row.rodOd.value = _convertText(
        row.rodOd.value,
        _diameterUnit,
        nextDiameterUnit,
      );
      row.strokeLength.value = _convertText(
        row.strokeLength.value,
        _lengthUnit,
        nextLengthUnit,
      );
      row.displacement.value = _convertText(
        row.displacement.value,
        _displacementUnit,
        nextDisplacementUnit,
      );
      row.rate.value = _convertText(row.rate.value, _flowUnit, nextFlowUnit);
    }

    for (final row in _sceRows) {
      row.uf.value = _convertText(
        row.uf.value,
        _mudWeightUnit,
        nextMudWeightUnit,
      );
      row.of_.value = _convertText(
        row.of_.value,
        _mudWeightUnit,
        nextMudWeightUnit,
      );
    }

    _diameterUnit = nextDiameterUnit;
    _lengthUnit = nextLengthUnit;
    _displacementUnit = nextDisplacementUnit;
    _flowUnit = nextFlowUnit;
    _pressureUnit = nextPressureUnit;
    _powerUnit = nextPowerUnit;
    _mudWeightUnit = nextMudWeightUnit;
    _pumpRows.refresh();
    _sceRows.refresh();
  }

  String _convertText(String rawValue, String fromUnit, String toUnit) {
    if (rawValue.trim().isEmpty || fromUnit == toUnit) {
      return rawValue;
    }
    final parsed = double.tryParse(rawValue);
    if (parsed == null) {
      return rawValue;
    }
    final result = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (result == null) {
      return rawValue;
    }
    return result
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  // ── Auto-row helpers ─────────────────────────────────────────────

  /// Call after any pump row gets data. Ensures there is always at least
  /// one empty row at the bottom.
  void _checkAddPumpRow(int changedIndex) {
    if (changedIndex == _pumpRows.length - 1 &&
        _pumpRows[changedIndex].hasData) {
      _pumpRows.add(_PumpRow());
    }
  }

  void _checkAddShakerRow(int changedIndex) {
    if (changedIndex == _shakerRows.length - 1 &&
        _shakerRows[changedIndex].hasData) {
      _shakerRows.add(_ShakerRow());
    }
  }

  void _checkAddSceRow(int changedIndex) {
    if (changedIndex == _sceRows.length - 1 && _sceRows[changedIndex].hasData) {
      _sceRows.add(_OtherSceRow());
    }
  }

  Future<void> _loadReportRows() async {
    final wellId = currentBackendWellId.trim();
    if (wellId.isNotEmpty) {
      sceController.currentWellId = wellId;
    }
    _loadPumpSummaryFields();
    await Future.wait([
      if (wellId.isNotEmpty) sceController.loadAvailableTypes(wellId),
      _loadReportPumpRows(),
      _loadReportSceRows(),
    ]);
  }

  void _loadPumpSummaryFields() {
    final values =
        reportContext.selectedReport?.pumpRateAndPressure ??
        const <String, String>{};
    _summaryPumpRate.value = _summaryValue(values['pumpRate']);
    _summaryPumpPressure.value = _summaryValue(values['pumpPressure']);
    _summaryDhToolsLoss.value = _summaryValue(values['dhToolsPressureLoss']);
    _summaryMotorLoss.value = _summaryValue(values['motorPressureLoss']);
  }

  String _summaryValue(String? value) {
    final text = value?.trim() ?? '';
    final parsed = double.tryParse(text);
    if (parsed != null && parsed == 0) return '';
    return text;
  }

  Future<void> _loadReportPumpRows() async {
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();
    if (wellId.isEmpty || reportId.isEmpty) return;

    final result = await pumpController.repository.getPumps(wellId);
    if (result['success'] != true) return;

    final rows = (result['data'] as List? ?? const [])
        .whereType<Map>()
        .map(_pumpRowFromMap)
        .toList(growable: true);

    while (rows.length < _initialPumpRows) {
      rows.add(_PumpRow()..rowNumber = rows.length + 1);
    }
    _pumpRows.assignAll(rows);
  }

  Future<void> _loadReportSceRows() async {
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();
    if (wellId.isEmpty || reportId.isEmpty) return;
    final cacheKey = '$wellId::$reportId';

    final setupShakerResult = await sceController.repository.getShakers(
      wellId,
      includeReportId: false,
    );
    final setupOtherResult = await sceController.repository.getOtherSce(
      wellId,
      includeReportId: false,
    );
    final localSetupShakers = sceController.shakers
        .where((row) => row.hasData)
        .map((row) => row.toJson())
        .toList(growable: false);
    final localSetupOtherSce = sceController.otherSce
        .where((row) => row.hasData)
        .map((row) => row.toJson())
        .toList(growable: false);
    if (setupShakerResult['success'] == true || localSetupShakers.isNotEmpty) {
      final cachedRows = _cachedShakerRows[cacheKey];
      final rows = cachedRows == null
          ? List.generate(_initialShakerRows, (_) => _ShakerRow())
          : cachedRows.map(_shakerRowFromMap).toList(growable: true);
      while (rows.length < _initialShakerRows) {
        rows.add(_ShakerRow());
      }
      _activeScreenRowIndex = null;
      _activeScreenColumnIndex = null;
      _shakerRows.assignAll(rows);
    }

    if (setupOtherResult['success'] == true || localSetupOtherSce.isNotEmpty) {
      final cachedRows = _cachedOtherSceRows[cacheKey];
      final rows = cachedRows == null
          ? List.generate(_initialSceRows, (_) => _OtherSceRow())
          : cachedRows.map(_otherSceRowFromMap).toList(growable: true);
      while (rows.length < _initialSceRows) {
        rows.add(_OtherSceRow());
      }
      _sceRows.assignAll(rows);
    }
  }

  void _clearShakerRow(_ShakerRow row) {
    row.id = null;
    row.shakerType.value = '';
    row.model.value = '';
    row.enabledScreens.value = 0;
    row.screen1.value = '';
    row.screen2.value = '';
    row.screen3.value = '';
    row.screen4.value = '';
    row.screen5.value = '';
    row.screen6.value = '';
    row.screen7.value = '';
    row.screen8.value = '';
    row.time.value = '';
    row.oocWt.value = '';
  }

  void _clearOtherSceRow(_OtherSceRow row) {
    row.id = null;
    row.type.value = '';
    row.model.value = '';
    row.uf.value = '';
    row.of_.value = '';
    row.time.value = '';
    row.oocWt.value = '';
  }

  void _rememberReportSceRows() {
    final scope = _currentSaveScope();
    if (!scope.isValid) return;
    final cacheKey = '${scope.wellId}::${scope.reportId}';

    final shakerRows = _shakerRows
        .where((row) => row.hasData)
        .map(_shakerRowToMap)
        .toList(growable: false);
    if (shakerRows.isEmpty) {
      _cachedShakerRows.remove(cacheKey);
    } else {
      _cachedShakerRows[cacheKey] = shakerRows;
    }

    final otherRows = _sceRows
        .where((row) => row.hasData)
        .map(_otherSceRowToMap)
        .toList(growable: false);
    if (otherRows.isEmpty) {
      _cachedOtherSceRows.remove(cacheKey);
    } else {
      _cachedOtherSceRows[cacheKey] = otherRows;
    }
  }

  Map<String, dynamic> _shakerRowToMap(_ShakerRow row) => {
    if (row.id != null) '_id': row.id,
    'shaker': row.shakerType.value,
    'model': row.model.value,
    'screens': row.enabledScreens.value > 0
        ? row.enabledScreens.value.toString()
        : '',
    'screen1': row.screen1.value,
    'screen2': row.screen2.value,
    'screen3': row.screen3.value,
    'screen4': row.screen4.value,
    'screen5': row.screen5.value,
    'screen6': row.screen6.value,
    'screen7': row.screen7.value,
    'screen8': row.screen8.value,
    'time': row.time.value,
    'oocWt': row.oocWt.value,
  };

  Map<String, dynamic> _otherSceRowToMap(_OtherSceRow row) => {
    if (row.id != null) '_id': row.id,
    'type': row.type.value,
    'model1': row.model.value,
    'uf': row.uf.value,
    'of': row.of_.value,
    'time': row.time.value,
    'oocWt': row.oocWt.value,
  };

  _PumpRow _pumpRowFromMap(Map item) {
    final row = _PumpRow();
    row.id = item['_id']?.toString() ?? item['id']?.toString();
    row.rowNumber = int.tryParse(item['rowNumber']?.toString() ?? '') ?? 0;
    row.model.value = item['model']?.toString() ?? '';
    row.type.value = item['type']?.toString() ?? '';
    row.linerId.value = item['linerId']?.toString() ?? '';
    row.rodOd.value = item['rodOd']?.toString() ?? '';
    row.strokeLength.value = item['strokeLength']?.toString() ?? '';
    row.efficiency.value = item['efficiency']?.toString() ?? '';
    row.displacement.value = item['displacement']?.toString() ?? '';
    row.spm.value = item['spm']?.toString() ?? '';
    row.rate.value = item['rate']?.toString() ?? '';
    return row;
  }

  _ShakerRow _shakerRowFromMap(Map item) {
    final row = _ShakerRow();
    row.id = item['_id']?.toString() ?? item['id']?.toString();
    row.shakerType.value = SceController.displayShakerLabel(
      item['shaker']?.toString() ?? '',
    );
    row.model.value = item['model']?.toString() ?? '';
    row.screen1.value = item['screen1']?.toString() ?? '';
    row.screen2.value = item['screen2']?.toString() ?? '';
    row.screen3.value = item['screen3']?.toString() ?? '';
    row.screen4.value = item['screen4']?.toString() ?? '';
    row.screen5.value = item['screen5']?.toString() ?? '';
    row.screen6.value = item['screen6']?.toString() ?? '';
    row.screen7.value = item['screen7']?.toString() ?? '';
    row.screen8.value = item['screen8']?.toString() ?? '';
    row.time.value = item['time']?.toString() ?? '';
    row.oocWt.value = item['oocWt']?.toString() ?? '';
    row.enabledScreens.value =
        int.tryParse(item['screens']?.toString() ?? '') ?? 0;
    return row;
  }

  _OtherSceRow _otherSceRowFromMap(Map item) {
    final row = _OtherSceRow();
    row.id = item['_id']?.toString() ?? item['id']?.toString();
    row.type.value = item['type']?.toString() ?? '';
    row.model.value = item['model1']?.toString() ?? '';
    row.uf.value = item['uf']?.toString() ?? '';
    row.of_.value = item['of']?.toString() ?? '';
    row.time.value = item['time']?.toString() ?? '';
    row.oocWt.value = item['oocWt']?.toString() ?? '';
    return row;
  }

  _ReportSaveScope _currentSaveScope() {
    return _ReportSaveScope(
      wellId: currentBackendWellId.trim(),
      reportId: reportContext.selectedReportId.value.trim(),
    );
  }

  void _scheduleSavePumpRow(_PumpRow row, int rowIndex) {
    final scope = _currentSaveScope();
    if (dashboard.isLocked.value || !row.hasData || !scope.isValid) {
      return;
    }
    row.rowNumber = row.rowNumber > 0 ? row.rowNumber : rowIndex + 1;
    _pumpSaveScopes[row] = scope;
    _pumpSaveTimers[row]?.cancel();
    _pumpSaveTimers[row] = Timer(
      const Duration(milliseconds: 850),
      () {
        _pumpSaveTimers.remove(row);
        _pumpSaveScopes.remove(row);
        unawaited(_savePumpRow(row, rowIndex, scope: scope));
      },
    );
  }

  void _savePumpRowNow(_PumpRow row, int rowIndex) {
    _pumpSaveTimers.remove(row)?.cancel();
    final scope = _pumpSaveScopes.remove(row) ?? _currentSaveScope();
    unawaited(_savePumpRow(row, rowIndex, scope: scope));
  }

  Future<void> _flushPendingPageSaves() async {
    final pendingPumpRows = _pumpSaveTimers.keys.toList();
    for (final timer in _pumpSaveTimers.values) {
      timer.cancel();
    }
    _pumpSaveTimers.clear();

    final futures = <Future<void>>[];
    for (final row in pendingPumpRows) {
      final index = _pumpRows.indexOf(row);
      final scope = _pumpSaveScopes.remove(row);
      if (index >= 0) {
        futures.add(_savePumpRow(row, index, scope: scope));
      }
    }

    if (_pumpSummarySaveTimer?.isActive ?? false) {
      _pumpSummarySaveTimer?.cancel();
      futures.add(
        _savePumpSummary(
          scope: _pumpSummarySaveScope,
          values: _pumpSummarySaveValues,
        ),
      );
    }
    _pumpSummarySaveTimer = null;
    _pumpSummarySaveScope = null;
    _pumpSummarySaveValues = null;

    final pendingShakerRows = _shakerSaveTimers.keys.toList();
    for (final timer in _shakerSaveTimers.values) {
      timer.cancel();
    }
    _shakerSaveTimers.clear();
    for (final row in pendingShakerRows) {
      futures.add(_saveShakerRow(row, scope: _shakerSaveScopes.remove(row)));
    }

    final pendingOtherSceRows = _otherSceSaveTimers.keys.toList();
    for (final timer in _otherSceSaveTimers.values) {
      timer.cancel();
    }
    _otherSceSaveTimers.clear();
    for (final row in pendingOtherSceRows) {
      futures.add(
        _saveOtherSceRow(row, scope: _otherSceSaveScopes.remove(row)),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _savePumpRow(
    _PumpRow row,
    int rowIndex, {
    _ReportSaveScope? scope,
  }) async {
    final targetScope = scope ?? _currentSaveScope();
    if (!row.hasData || !targetScope.isValid) {
      return;
    }
    row.rowNumber = row.rowNumber > 0 ? row.rowNumber : rowIndex + 1;
    final payload = {
      'rowNumber': row.rowNumber,
      'model': row.model.value.trim(),
      'type': row.type.value.trim(),
      'linerId': double.tryParse(row.linerId.value.trim()) ?? 0,
      'rodOd': double.tryParse(row.rodOd.value.trim()) ?? 0,
      'strokeLength': double.tryParse(row.strokeLength.value.trim()) ?? 0,
      'efficiency': double.tryParse(row.efficiency.value.trim()) ?? 0,
      'spm': double.tryParse(row.spm.value.trim()) ?? 0,
    };

    try {
      final result = await pumpController.repository.createPump(
        targetScope.wellId,
        payload,
        reportIdOverride: targetScope.reportId,
      );

      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map) {
          row.id = data['_id']?.toString() ?? row.id;
          row.displacement.value =
              data['displacement']?.toString() ?? row.displacement.value;
          row.rate.value = data['rate']?.toString() ?? row.rate.value;
        }
      }
    } catch (e) {
      debugPrint('Pump report autosave error: $e');
    }
  }

  void _scheduleSavePumpSummary() {
    final scope = _currentSaveScope();
    if (dashboard.isLocked.value || !scope.isValid) {
      return;
    }

    final values = _currentPumpSummaryValues();
    _pumpSummarySaveScope = scope;
    _pumpSummarySaveValues = values;
    _pumpSummarySaveTimer?.cancel();
    _pumpSummarySaveTimer = Timer(
      const Duration(milliseconds: 850),
      () {
        _pumpSummarySaveTimer = null;
        _pumpSummarySaveScope = null;
        _pumpSummarySaveValues = null;
        unawaited(_savePumpSummary(scope: scope, values: values));
      },
    );
  }

  Map<String, String> _currentPumpSummaryValues() {
    return {
      'pumpRate': _summaryPumpRate.value.trim(),
      'pumpPressure': _summaryPumpPressure.value.trim(),
      'dhToolsPressureLoss': _summaryDhToolsLoss.value.trim(),
      'motorPressureLoss': _summaryMotorLoss.value.trim(),
    };
  }

  Future<void> _savePumpSummary({
    _ReportSaveScope? scope,
    Map<String, String>? values,
  }) async {
    final reportId = (scope ?? _currentSaveScope()).reportId.trim();
    if (reportId.isEmpty) return;

    final nextValues = values ?? _currentPumpSummaryValues();
    final reportIndex = reportContext.reports.indexWhere(
      (item) => item.id == reportId,
    );
    final existing = reportIndex >= 0
        ? reportContext.reports[reportIndex].pumpRateAndPressure
        : const <String, String>{};
    final payload = {
      'pumpRateAndPressure': {
        ...existing,
        'pumpRate': double.tryParse(nextValues['pumpRate'] ?? '') ?? 0,
        'pumpPressure': double.tryParse(nextValues['pumpPressure'] ?? '') ?? 0,
        'dhToolsPressureLoss':
            double.tryParse(nextValues['dhToolsPressureLoss'] ?? '') ?? 0,
        'motorPressureLoss':
            double.tryParse(nextValues['motorPressureLoss'] ?? '') ?? 0,
      },
    };

    try {
      await _reportApi.updateReport(reportId, payload);
      _applyPumpSummaryToContext(reportId, nextValues);
    } catch (e) {
      debugPrint('Pump summary autosave error: $e');
    }
  }

  void _applyPumpSummaryToContext(
    String reportId,
    Map<String, String> values,
  ) {
    final index = reportContext.reports.indexWhere(
      (item) => item.id == reportId,
    );
    if (index < 0) return;

    final existing = reportContext.reports[index].pumpRateAndPressure;
    reportContext.reports[index] = reportContext.reports[index].copyWith(
      pumpRateAndPressure: {
        ...existing,
        ...values,
      },
    );
  }

  void _scheduleSaveShakerRow(_ShakerRow row) {
    final scope = _currentSaveScope();
    if (dashboard.isLocked.value || !row.hasData || !scope.isValid) {
      return;
    }
    _rememberReportSceRows();
    _shakerSaveScopes[row] = scope;
    _shakerSaveTimers[row]?.cancel();
    _shakerSaveTimers[row] = Timer(
      const Duration(milliseconds: 850),
      () {
        _shakerSaveTimers.remove(row);
        _shakerSaveScopes.remove(row);
        unawaited(_saveShakerRow(row, scope: scope));
      },
    );
  }

  Future<void> _saveShakerRow(
    _ShakerRow row, {
    _ReportSaveScope? scope,
  }) async {
    final targetScope = scope ?? _currentSaveScope();
    if (!row.hasData || !targetScope.isValid) return;
    final rowIndex = _shakerRows.indexOf(row);
    final shakerKey = row.shakerType.value.trim().isNotEmpty
        ? row.shakerType.value.trim()
        : (rowIndex >= 0 ? 'Shaker ${rowIndex + 1}' : '');
    if (shakerKey.isEmpty) return;
    row.shakerType.value = shakerKey;
    final payload = {
      'shaker': shakerKey,
      'model': row.model.value.trim(),
      'screens': row.enabledScreens.value > 0
          ? row.enabledScreens.value.toString()
          : '',
      'plot': true,
      'screen1': row.screen1.value.trim(),
      'screen2': row.screen2.value.trim(),
      'screen3': row.screen3.value.trim(),
      'screen4': row.screen4.value.trim(),
      'screen5': row.screen5.value.trim(),
      'screen6': row.screen6.value.trim(),
      'screen7': row.screen7.value.trim(),
      'screen8': row.screen8.value.trim(),
      'time': row.time.value.trim(),
      'oocWt': row.oocWt.value.trim(),
    };

    try {
      final result = await sceController.repository.createShaker(
        targetScope.wellId,
        payload,
        reportIdOverride: targetScope.reportId,
      );

      if (result['success'] == true) {
        row.id = result['data']?['_id']?.toString() ?? row.id;
        _rememberReportSceRows();
      }
    } catch (e) {
      debugPrint('Shaker report autosave error: $e');
    }
  }

  void _scheduleSaveOtherSceRow(_OtherSceRow row) {
    final scope = _currentSaveScope();
    if (dashboard.isLocked.value || !row.hasData || !scope.isValid) {
      return;
    }
    _rememberReportSceRows();
    _otherSceSaveScopes[row] = scope;
    _otherSceSaveTimers[row]?.cancel();
    _otherSceSaveTimers[row] = Timer(
      const Duration(milliseconds: 850),
      () {
        _otherSceSaveTimers.remove(row);
        _otherSceSaveScopes.remove(row);
        unawaited(_saveOtherSceRow(row, scope: scope));
      },
    );
  }

  Future<void> _saveOtherSceRow(
    _OtherSceRow row, {
    _ReportSaveScope? scope,
  }) async {
    final targetScope = scope ?? _currentSaveScope();
    if (!row.hasData || !targetScope.isValid) return;
    final payload = {
      'type': row.type.value.trim(),
      'model1': row.model.value.trim(),
      'plot': true,
      'uf': row.uf.value.trim(),
      'of': row.of_.value.trim(),
      'time': row.time.value.trim(),
      'oocWt': row.oocWt.value.trim(),
    };

    if ((payload['type'] as String).isEmpty) return;

    try {
      final result = await sceController.repository.createOtherSce(
        targetScope.wellId,
        payload,
        reportIdOverride: targetScope.reportId,
      );

      if (result['success'] == true) {
        row.id = result['data']?['_id']?.toString() ?? row.id;
        _rememberReportSceRows();
      }
    } catch (e) {
      debugPrint('Other SCE report autosave error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AppUnits.signature;
      return Scaffold(
        backgroundColor: const Color(0xffF4F6FA),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Flexible(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pump table — fixed max width, narrower
                    Expanded(child: _pumpTable()),
                    const SizedBox(width: 12),
                    // Summary box — wider fixed width
                    SizedBox(width: 310, child: _summaryBox()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _screenAutoFillBar(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: double.infinity, child: _shakerTable()),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: double.infinity,
                    child: _otherSCETable(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  PUMP TABLE
  // ═══════════════════════════════════════════════════════════

  Widget _pumpTable() {
    return Container(
      decoration: _boxStyle(),
      child: Column(
        children: [
          _tableHeader("Pump", Icons.settings),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const baseCellWidth = 704.0;
                const dividerWidth = 8.0;
                final contentWidth = constraints.hasBoundedWidth
                    ? math.max(_pumpTableWidth, constraints.maxWidth)
                    : _pumpTableWidth;
                final scale = (contentWidth - dividerWidth) / baseCellWidth;
                double w(double width) => width * scale;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                             _headerCell("Model", w(100)),
                            _verticalDivider(),
                            _headerCell("Type", w(85)),
                            _verticalDivider(),
                            _headerCell("Liner ID\n(in)", w(68)),
                            _verticalDivider(),
                            _headerCell("Rod OD\n(in)", w(68)),
                            _verticalDivider(),
                            _headerCell("Stk. Length\n(in)", w(80)),
                            _verticalDivider(),
                            _headerCell("Efficiency\n(%)", w(75)),
                            _verticalDivider(),
                            _headerCell("Displ.\n(bbl/stk)", w(80)),
                            _verticalDivider(),
                            _headerCell("Stroke\n(stk/min)", w(80)),
                            _verticalDivider(),
                            _headerCell("Rate\n(gpm)", w(68)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        final isLocked = dashboard.isLocked.value;
                        final models = pumpController.availablePumpModels
                            .toList();
                        final rows = _pumpRows.toList();
                        return ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: index % 2 == 0
                                    ? Colors.white
                                    : Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    _dataCell(
                                      width: w(100),
                                      child: _pumpModelDropdown(
                                        row: row,
                                        models: models,
                                        isLocked: isLocked,
                                        rowIndex: index,
                                      ),
                                    ),
                                    _verticalDivider(),
                                    _dataCell(
                                      width: w(85),
                                      child: Obx(
                                        () => _readOnlyCell(row.type.value),
                                      ),
                                    ),
                                    _verticalDivider(),
                                    _dataCell(
                                      width: w(68),
                                      child: Obx(
                                        () => _readOnlyCell(row.linerId.value),
                                      ),
                                    ),
                                    _verticalDivider(),
                                    _dataCell(
                                      width: w(68),
                                      child: Obx(
                                        () => _readOnlyCell(row.rodOd.value),
                                      ),
                                    ),
                                    _verticalDivider(),
                                    _dataCell(
                                      width: w(80),
                                      child: Obx(
                                        () => _readOnlyCell(
                                          row.strokeLength.value,
                                        ),
                                      ),
                                    ),
                                    _verticalDivider(),
                                    _dataCell(
                                      width: w(75),
                                      child: Obx(
                                        () =>
                                            _readOnlyCell(row.efficiency.value),
                                      ),
                                    ),
                                    _verticalDivider(),
                                    _dataCell(
                                      width: w(80),
                                      child: Obx(
                                        () => _readOnlyCell(
                                          row.displacement.value.isEmpty
                                              ? '-'
                                              : row.displacement.value,
                                        ),
                                      ),
                                    ),
                                    _verticalDivider(),
                                    _dataCell(
                                      width: w(80),
                                      child: _spmField(
                                        row: row,
                                        isLocked: isLocked,
                                        rowIndex: index,
                                      ),
                                    ),
                                    _verticalDivider(),
                                    _dataCell(
                                      width: w(68),
                                      child: Obx(
                                        () => _readOnlyCell(
                                          row.rate.value.isEmpty
                                              ? '-'
                                              : row.rate.value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// SPM field — triggers rate calculation AND auto-row generation
  Widget _spmField({
    required _PumpRow row,
    required bool isLocked,
    required int rowIndex,
  }) {
    return Obx(() {
      final ctrl = TextEditingController(text: row.spm.value)
        ..selection = TextSelection.collapsed(offset: row.spm.value.length);
      return Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            _savePumpRowNow(row, rowIndex);
          }
        },
        child: TextField(
          enabled: !isLocked,
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            row.spm.value = val;
            row.recalculateRate();
          // ✅ Auto-add row when last row has data
            _checkAddPumpRow(rowIndex);
            _scheduleSavePumpRow(row, rowIndex);
          },
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: isLocked ? Colors.grey.shade400 : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            filled: isLocked,
            fillColor: isLocked ? Colors.grey.shade50 : null,
          ),
        ),
      );
    });
  }

  /// Model dropdown — filling model also triggers auto-row generation
  Widget _pumpModelDropdown({
    required _PumpRow row,
    required List<String> models,
    required bool isLocked,
    required int rowIndex,
  }) {
    return Obx(() {
      final current = row.model.value.isEmpty ? null : row.model.value;
      final safeVal = models.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeVal,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (selected) {
                  if (selected == null || selected.isEmpty) {
                    row.clear();
                    return;
                  }

                  final source = pumpController.pumps.firstWhereOrNull(
                    (p) => p.model.value == selected && p.hasData,
                  );

                  row.model.value = selected;
                  if (source != null) {
                    row.type.value = source.type.value;
                    row.linerId.value = source.linerId.value;
                    final rodVal = double.tryParse(source.rodOd.value) ?? 0;
                    row.rodOd.value = rodVal > 0 ? source.rodOd.value : '';
                    row.strokeLength.value = source.strokeLength.value;
                    row.efficiency.value = source.efficiency.value;
                    row.displacement.value = source.displacement.value;
                    row.spm.value = '';
                    row.rate.value = '';
                  }
                  // ✅ Auto-add row when last row's model is selected
                  _checkAddPumpRow(rowIndex);
                  _savePumpRowNow(row, rowIndex);
                },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('', style: TextStyle(fontSize: 9)),
            ),
            ...models.map(
              (m) => DropdownMenuItem<String?>(
                value: m,
                child: Text(m, style: const TextStyle(fontSize: 9)),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  SHAKER TABLE
  // ═══════════════════════════════════════════════════════════

  Widget _shakerTable() {
    return Container(
      decoration: _boxStyle(),
      child: Column(
        children: [
          _tableHeader("Shaker", Icons.filter_alt),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const baseCellWidth = 749.0;
                const dividerWidth = 11.0;
                final contentWidth = constraints.hasBoundedWidth
                    ? math.max(_shakerTableWidth, constraints.maxWidth)
                    : _shakerTableWidth;
                final scale = (contentWidth - dividerWidth) / baseCellWidth;
                double w(double width) => width * scale;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _headerCell("Shaker", w(100)),
                            _verticalDivider(),
                            _headerCell("Model", w(120)),
                            _verticalDivider(),
                            _headerCellWithSubheaders(
                              "Screen",
                              List.generate(
                                _totalScreenCols,
                                (i) => _subHeaderCell("${i + 1}", w(48)),
                              ),
                            ),
                            _verticalDivider(),
                            _headerCell("Time\n(hr)", w(70)),
                            _verticalDivider(),
                            _headerCell("OOC Wt.\n(%)", w(75)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        final isLocked = dashboard.isLocked.value;
                        final shakerTypes = sceController.availableShakerTypes
                            .toList();
                        final shakerModels = sceController.availableShakerModels
                            .toList();
                        final rows = _shakerRows.toList();
                        return Scrollbar(
                          controller: shakerScrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: shakerScrollController,
                            itemCount: rows.length,
                            itemBuilder: (ctx, index) {
                              final row = rows[index];
                              return Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  color: index % 2 == 0
                                      ? Colors.white
                                      : Colors.grey.shade50,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      _dataCell(
                                        width: w(100),
                                        child: _shakerTypeDropdown(
                                          row: row,
                                          types: shakerTypes,
                                          isLocked: isLocked,
                                          rowIndex: index,
                                        ),
                                      ),
                                      _verticalDivider(),
                                      _dataCell(
                                        width: w(120),
                                        child: _shakerModelDropdown(
                                          row: row,
                                          models: shakerModels,
                                          isLocked: isLocked,
                                          rowIndex: index,
                                        ),
                                      ),
                                      _verticalDivider(),
                                      ..._buildScreenCols(row, isLocked, w),
                                      _verticalDivider(),
                                      _dataCell(
                                        width: w(70),
                                        child: _rxTextField(
                                          row.time,
                                          isLocked,
                                          onChanged: () =>
                                              _scheduleSaveShakerRow(row),
                                        ),
                                      ),
                                      _verticalDivider(),
                                      _dataCell(
                                        width: w(75),
                                        child: _rxTextField(
                                          row.oocWt,
                                          isLocked,
                                          onChanged: () =>
                                              _scheduleSaveShakerRow(row),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _shakerTypeDropdown({
    required _ShakerRow row,
    required List<String> types,
    required bool isLocked,
    required int rowIndex,
  }) {
    return Obx(() {
      final current = row.shakerType.value.isEmpty
          ? null
          : row.shakerType.value;
      final safe = types.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (sel) {
                  if (sel == null || sel.isEmpty) {
                    _clearShakerRow(row);
                    _rememberReportSceRows();
                    _shakerRows.refresh();
                    return;
                  }
                  row.shakerType.value = sel;
                  // ✅ Auto-add row when last row gets a type selected
                  _checkAddShakerRow(rowIndex);
                  _scheduleSaveShakerRow(row);
                },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('', style: TextStyle(fontSize: 9)),
            ),
            ...types.map(
              (t) => DropdownMenuItem<String?>(
                value: t,
                child: Text(t, style: const TextStyle(fontSize: 9)),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _shakerModelDropdown({
    required _ShakerRow row,
    required List<String> models,
    required bool isLocked,
    required int rowIndex,
  }) {
    return Obx(() {
      final current = row.model.value.isEmpty ? null : row.model.value;
      final safe = models.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (sel) async {
                  if (sel == null || sel.isEmpty) {
                    _clearShakerRow(row);
                    _rememberReportSceRows();
                    _shakerRows.refresh();
                    return;
                  }
                  row.model.value = sel;
                  if (sel.isNotEmpty) {
                    final data = await sceController.getShakerDataByModel(sel);
                    if (data != null) {
                      final apiType = SceController.displayShakerLabel(
                        data['shaker']?.toString() ?? '',
                      );
                      if (row.shakerType.value.isEmpty && apiType.isNotEmpty) {
                        row.shakerType.value = apiType;
                      }
                      final n =
                          int.tryParse(data['screens']?.toString() ?? '0') ?? 0;
                      row.enabledScreens.value = n;
                    }
                    if (row.shakerType.value.trim().isEmpty) {
                      row.shakerType.value = 'Shaker ${rowIndex + 1}';
                    }
                    // ✅ Auto-add row when last row's model is selected
                    _checkAddShakerRow(rowIndex);
                    _scheduleSaveShakerRow(row);
                  } else {
                    row.enabledScreens.value = 0;
                    row.screen1.value = '';
                    row.screen2.value = '';
                    row.screen3.value = '';
                    row.screen4.value = '';
                    row.screen5.value = '';
                    row.screen6.value = '';
                    row.screen7.value = '';
                    row.screen8.value = '';
                    _scheduleSaveShakerRow(row);
                  }
                },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('', style: TextStyle(fontSize: 9)),
            ),
            ...models.map(
              (m) => DropdownMenuItem<String?>(
                value: m,
                child: Text(m, style: const TextStyle(fontSize: 9)),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildScreenCols(
    _ShakerRow row,
    bool isLocked,
    double Function(double) w,
  ) {
    final fields = [
      row.screen1,
      row.screen2,
      row.screen3,
      row.screen4,
      row.screen5,
      row.screen6,
      row.screen7,
      row.screen8,
    ];
    final List<Widget> cols = [];
    for (int i = 0; i < _totalScreenCols; i++) {
      final idx = i;
      cols.add(
        _dataCell(
          width: w(48),
          child: Obx(() {
            final isEnabled = !isLocked && idx < row.enabledScreens.value;
            return TextField(
              enabled: isEnabled,
              onTap: () {
                _activeScreenRowIndex = _shakerRows.indexOf(row);
                _activeScreenColumnIndex = idx;
              },
              controller: TextEditingController(text: fields[idx].value)
                ..selection = TextSelection.collapsed(
                  offset: fields[idx].value.length,
                ),
              onChanged: (v) {
                _activeScreenRowIndex = _shakerRows.indexOf(row);
                _activeScreenColumnIndex = idx;
                fields[idx].value = v;
                _scheduleSaveShakerRow(row);
              },
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isEnabled ? Colors.black87 : Colors.grey.shade400,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: !isEnabled,
                fillColor: isEnabled ? null : Colors.grey.shade100,
              ),
            );
          }),
        ),
      );
      if (i < _totalScreenCols - 1) cols.add(_verticalDivider());
    }
    return cols;
  }

  // ═══════════════════════════════════════════════════════════
  //  SCREEN AUTO-FILL BAR
  // ═══════════════════════════════════════════════════════════

  Widget _screenAutoFillBar() {
    return Obx(() {
      final isLocked = dashboard.isLocked.value;
      return IntrinsicWidth(
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 22,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.shade50 : Colors.white,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: DropdownButton<String>(
                      value: _screenFillSelected.value.isEmpty
                          ? null
                          : _screenFillSelected.value,
                      isExpanded: true,
                      isDense: true,
                      hint: Text(
                        'Value',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down, size: 13),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black87,
                      ),
                      menuMaxHeight: 200,
                      onChanged: isLocked
                          ? null
                          : (sel) {
                              if (sel != null) _screenFillSelected.value = sel;
                            },
                      items: _screenValueOptions
                          .map(
                            (v) => DropdownMenuItem<String>(
                              value: v,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  v,
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                height: 22,
                child: ElevatedButton(
                  onPressed: isLocked ? null : _autoFillScreenValues,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  child: const Text(
                    'Fill',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _autoFillScreenValues() {
    final fillVal = _screenFillSelected.value.trim();
    if (fillVal.isEmpty) return;
    final rowIndex = _activeScreenRowIndex;
    final columnIndex = _activeScreenColumnIndex;
    if (rowIndex == null ||
        columnIndex == null ||
        rowIndex < 0 ||
        rowIndex >= _shakerRows.length) {
      return;
    }

    final row = _shakerRows[rowIndex];
    if (row.model.value.isEmpty ||
        columnIndex < 0 ||
        columnIndex >= row.enabledScreens.value ||
        columnIndex >= _totalScreenCols) {
      return;
    }

    final fields = [
      row.screen1,
      row.screen2,
      row.screen3,
      row.screen4,
      row.screen5,
      row.screen6,
      row.screen7,
      row.screen8,
    ];
    fields[columnIndex].value = fillVal;
    _scheduleSaveShakerRow(row);
  }

  // ═══════════════════════════════════════════════════════════
  //  OTHER SCE TABLE
  // ═══════════════════════════════════════════════════════════

  Widget _otherSCETable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const baseCellWidth = 485.0;
        const dividerWidth = 6.0;
        final contentWidth = constraints.hasBoundedWidth
            ? math.max(baseCellWidth + dividerWidth, constraints.maxWidth)
            : baseCellWidth + dividerWidth;
        final scale = (contentWidth - dividerWidth - 1) / baseCellWidth;
        double w(double width) => width * scale;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            child: Container(
              decoration: _boxStyle(),
              child: Column(
        children: [
          _tableHeader("Other SCE", Icons.build),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _headerCell("SCE", w(90)),
                  _verticalDivider(),
                  _headerCell("Model", w(110)),
                  _verticalDivider(),
                  _headerCell("U/F\n(ppg)", w(70)),
                  _verticalDivider(),
                  _headerCell("O/F\n(ppg)", w(70)),
                  _verticalDivider(),
                  _headerCell("Time\n(hr)", w(70)),
                  _verticalDivider(),
                  _headerCell("OOC Wt.\n(%)", w(75)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final isLocked = dashboard.isLocked.value;
              final sceTypes = sceController.availableOtherSceTypes.toList();
              final sceModels = sceController.availableOtherSceModels.toList();
              final rows = _sceRows.toList(); // react to list changes
              return Scrollbar(
                controller: sceScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: sceScrollController,
                  itemCount: rows.length,
                  itemBuilder: (ctx, index) {
                    final row = rows[index];
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: index % 2 == 0
                            ? Colors.white
                            : Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _dataCell(
                              width: w(90),
                              child: _sceTypeDropdown(
                                row: row,
                                types: sceTypes,
                                isLocked: isLocked,
                                rowIndex: index,
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: w(110),
                              child: _sceModelDropdown(
                                row: row,
                                models: sceModels,
                                isLocked: isLocked,
                                rowIndex: index,
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: w(70),
                              child: _rxTextField(
                                row.uf,
                                isLocked,
                                onChanged: () => _scheduleSaveOtherSceRow(row),
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: w(70),
                              child: _rxTextField(
                                row.of_,
                                isLocked,
                                onChanged: () => _scheduleSaveOtherSceRow(row),
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: w(70),
                              child: _rxTextField(
                                row.time,
                                isLocked,
                                onChanged: () => _scheduleSaveOtherSceRow(row),
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: w(75),
                              child: _rxTextField(
                                row.oocWt,
                                isLocked,
                                onChanged: () => _scheduleSaveOtherSceRow(row),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sceTypeDropdown({
    required _OtherSceRow row,
    required List<String> types,
    required bool isLocked,
    required int rowIndex,
  }) {
    return Obx(() {
      final current = row.type.value.isEmpty ? null : row.type.value;
      final safe = types.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (sel) {
                  if (sel == null || sel.isEmpty) {
                    _clearOtherSceRow(row);
                    _rememberReportSceRows();
                    _sceRows.refresh();
                    return;
                  }
                  row.type.value = sel;
                  // ✅ Auto-add row when last row gets a type
                  _checkAddSceRow(rowIndex);
                  _scheduleSaveOtherSceRow(row);
                },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('', style: TextStyle(fontSize: 9)),
            ),
            ...types.map(
              (t) => DropdownMenuItem<String?>(
                value: t,
                child: Text(t, style: const TextStyle(fontSize: 9)),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _sceModelDropdown({
    required _OtherSceRow row,
    required List<String> models,
    required bool isLocked,
    required int rowIndex,
  }) {
    return Obx(() {
      final current = row.model.value.isEmpty ? null : row.model.value;
      final safe = models.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (sel) {
                  if (sel == null || sel.isEmpty) {
                    _clearOtherSceRow(row);
                    _rememberReportSceRows();
                    _sceRows.refresh();
                    return;
                  }
                  row.model.value = sel;
                  // ✅ Auto-add row when last row's model is selected
                  _checkAddSceRow(rowIndex);
                  _scheduleSaveOtherSceRow(row);
                },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                '',
                style: TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
            ...models.map(
              (m) => DropdownMenuItem<String?>(
                value: m,
                child: Text(m, style: const TextStyle(fontSize: 9)),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  SUMMARY BOX
  // ═══════════════════════════════════════════════════════════

  Widget _summaryBox() {
    return Container(
      decoration: _boxStyle(),
      child: Column(
        children: [
          _tableHeader("Summary", Icons.summarize),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _summaryItem("Pump Rate", "gpm", _summaryPumpRate),
                  const SizedBox(height: 8),
                  _summaryItem("Pump Pressure", "psi", _summaryPumpPressure),
                  const SizedBox(height: 8),
                  _summaryItem("DH Tools P. Loss", "psi", _summaryDhToolsLoss),
                  const SizedBox(height: 8),
                  _summaryItem("Motor P. Loss", "psi", _summaryMotorLoss),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String unit, RxString value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppUnits.label(label),
              style: const TextStyle(fontSize: 9, color: Colors.black87),
            ),
          ),
          SizedBox(
            width: 95,
            height: 24,
            child: Obx(
              () => TextField(
                enabled: !dashboard.isLocked.value,
                controller: TextEditingController(text: value.value)
                  ..selection = TextSelection.collapsed(
                    offset: value.value.length,
                  ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (text) {
                  value.value = text;
                  _scheduleSavePumpSummary();
                },
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 9),
                decoration: InputDecoration(
                  hintText: "0.0",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 9,
                  ),
                  suffix: Text(
                    AppUnits.unitSuffix(unit),
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _tableHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          AppUnits.label(text),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _headerCellWithSubheaders(String mainText, List<Widget> subHeaders) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            mainText,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Row(children: subHeaders),
      ],
    );
  }

  Widget _subHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontSize: 7, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _verticalDivider() => Container(width: 1, color: Colors.grey.shade300);

  Widget _dataCell({required Widget child, required double width}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: child,
      ),
    );
  }

  Widget _readOnlyCell(String text) {
    return Text(
      text.isEmpty ? '-' : text,
      style: TextStyle(
        fontSize: 9,
        color: text.isEmpty || text == '-'
            ? Colors.grey.shade400
            : Colors.black54,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _rxTextField(
    RxString rxValue,
    bool isLocked, {
    VoidCallback? onChanged,
  }) {
    return Obx(
      () => TextField(
        enabled: !isLocked,
        controller: TextEditingController(text: rxValue.value)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: rxValue.value.length),
          ),
        onChanged: (v) {
          rxValue.value = v;
          onChanged?.call();
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }

  BoxDecoration _boxStyle() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(4),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ],
    border: Border.all(color: Colors.grey.shade300, width: 0.5),
  );
}
