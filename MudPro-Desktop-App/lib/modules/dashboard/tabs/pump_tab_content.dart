import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/pump_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/sce_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pump_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/sce_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// ─── Local row model for Pump page ────────────────────────────────────────────
class _PumpRow {
  String? id;
  int rowNumber;
  final RxString model = ''.obs;
  final RxString type = ''.obs;
  final RxString linerId = ''.obs;
  final RxString rodOd = ''.obs;
  final RxString strokeLength = ''.obs;
  final RxString efficiency = ''.obs;
  final RxString displacement = ''.obs;
  final RxString spm = ''.obs;
  final RxString rate = ''.obs;
  final RxString maxPumpP = ''.obs;
  final RxString maxHp = ''.obs;
  final RxString surfaceLen = ''.obs;
  final RxString surfaceId = ''.obs;

  _PumpRow({this.id, this.rowNumber = 0});

  factory _PumpRow.fromPumpModel(PumpModel model) {
    final row = _PumpRow(id: model.id, rowNumber: model.rowNumber.value);
    row.model.value = model.model.value;
    row.type.value = model.type.value;
    row.linerId.value = model.linerId.value;
    row.rodOd.value = model.rodOd.value;
    row.strokeLength.value = model.strokeLength.value;
    row.efficiency.value = model.efficiency.value;
    row.displacement.value = model.displacement.value;
    row.spm.value = model.spm.value;
    row.rate.value = model.rate.value;
    row.maxPumpP.value = model.maxPumpP.value;
    row.maxHp.value = model.maxHp.value;
    row.surfaceLen.value = model.surfaceLen.value;
    row.surfaceId.value = model.surfaceId.value;
    return row;
  }

  PumpModel toPumpModel(int index) {
    return PumpModel(
      id: id,
      rowNumber: rowNumber > 0 ? rowNumber : index + 1,
      type: type.value,
      model: model.value,
      linerId: linerId.value,
      rodOd: rodOd.value,
      strokeLength: strokeLength.value,
      efficiency: efficiency.value,
      spm: spm.value,
      displacement: displacement.value,
      rate: rate.value,
      maxPumpP: maxPumpP.value,
      maxHp: maxHp.value,
      surfaceLen: surfaceLen.value,
      surfaceId: surfaceId.value,
    );
  }

  bool get hasData =>
      model.value.isNotEmpty ||
      type.value.isNotEmpty ||
      linerId.value.isNotEmpty ||
      rodOd.value.isNotEmpty ||
      strokeLength.value.isNotEmpty ||
      efficiency.value.isNotEmpty ||
      spm.value.isNotEmpty ||
      maxPumpP.value.isNotEmpty ||
      maxHp.value.isNotEmpty ||
      surfaceLen.value.isNotEmpty ||
      surfaceId.value.isNotEmpty;

  void clear() {
    model.value = '';
    type.value = '';
    linerId.value = '';
    rodOd.value = '';
    strokeLength.value = '';
    efficiency.value = '';
    displacement.value = '';
    spm.value = '';
    rate.value = '';
    maxPumpP.value = '';
    maxHp.value = '';
    surfaceLen.value = '';
    surfaceId.value = '';
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
  bool plot;
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

  _ShakerRow({this.id, this.plot = false});

  static int _resolveEnabledScreens(ShakerModel shaker) {
    final parsed = int.tryParse(shaker.screens.value) ?? 0;
    if (parsed > 0) {
      return parsed;
    }

    final values = [
      shaker.screen1.value,
      shaker.screen2.value,
      shaker.screen3.value,
      shaker.screen4.value,
      shaker.screen5.value,
      shaker.screen6.value,
      shaker.screen7.value,
      shaker.screen8.value,
    ];

    var maxIndex = 0;
    for (int i = 0; i < values.length; i++) {
      if (values[i].trim().isNotEmpty) {
        maxIndex = i + 1;
      }
    }
    return maxIndex;
  }

  factory _ShakerRow.fromModel(ShakerModel shaker) {
    final row = _ShakerRow(id: shaker.id, plot: shaker.plot.value);
    row.shakerType.value = shaker.shaker.value;
    row.model.value = shaker.model.value;
    row.screen1.value = shaker.screen1.value;
    row.screen2.value = shaker.screen2.value;
    row.screen3.value = shaker.screen3.value;
    row.screen4.value = shaker.screen4.value;
    row.screen5.value = shaker.screen5.value;
    row.screen6.value = shaker.screen6.value;
    row.screen7.value = shaker.screen7.value;
    row.screen8.value = shaker.screen8.value;
    row.time.value = shaker.time.value;
    row.oocWt.value = shaker.oocWt.value;
    row.enabledScreens.value = _resolveEnabledScreens(shaker);
    return row;
  }

  ShakerModel toModel() {
    return ShakerModel(
      id: id,
      shaker: shakerType.value,
      model: model.value,
      screens: enabledScreens.value > 0 ? enabledScreens.value.toString() : '',
      plot: plot,
      screen1: screen1.value,
      screen2: screen2.value,
      screen3: screen3.value,
      screen4: screen4.value,
      screen5: screen5.value,
      screen6: screen6.value,
      screen7: screen7.value,
      screen8: screen8.value,
      time: time.value,
      oocWt: oocWt.value,
    );
  }

  bool get hasData =>
      shakerType.value.isNotEmpty ||
      model.value.isNotEmpty ||
      time.value.isNotEmpty ||
      oocWt.value.isNotEmpty ||
      screen1.value.isNotEmpty ||
      screen2.value.isNotEmpty ||
      screen3.value.isNotEmpty ||
      screen4.value.isNotEmpty ||
      screen5.value.isNotEmpty ||
      screen6.value.isNotEmpty ||
      screen7.value.isNotEmpty ||
      screen8.value.isNotEmpty;
}

class _OtherSceRow {
  String? id;
  bool plot;
  final RxString type = ''.obs;
  final RxString model = ''.obs;
  final RxString uf = ''.obs;
  final RxString of_ = ''.obs;
  final RxString time = ''.obs;
  final RxString oocWt = ''.obs;

  _OtherSceRow({this.id, this.plot = false});

  factory _OtherSceRow.fromModel(OtherSceModel sce) {
    final row = _OtherSceRow(id: sce.id, plot: sce.plot.value);
    row.type.value = sce.type.value;
    row.model.value = sce.model1.value;
    row.uf.value = sce.uf.value;
    row.of_.value = sce.of.value;
    row.time.value = sce.time.value;
    row.oocWt.value = sce.oocWt.value;
    return row;
  }

  OtherSceModel toModel() {
    return OtherSceModel(
      id: id,
      type: type.value,
      model1: model.value,
      plot: plot,
      uf: uf.value,
      of: of_.value,
      time: time.value,
      oocWt: oocWt.value,
    );
  }

  bool get hasData =>
      type.value.isNotEmpty ||
      model.value.isNotEmpty ||
      uf.value.isNotEmpty ||
      of_.value.isNotEmpty ||
      time.value.isNotEmpty ||
      oocWt.value.isNotEmpty;
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
  final List<Worker> _unitWorkers = <Worker>[];
  Worker? _wellWorker;
  Worker? _reportWorker;
  final RxBool _isSyncing = false.obs;
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
  final ReportApiService _reportApi = ReportApiService();
  Timer? _summarySaveDebounce;
  final RxBool _isSavingSummary = false.obs;
  bool _hydratingSummary = false;

  final RxString _summaryPumpRate = ''.obs;
  final RxString _summaryPumpPressure = ''.obs;
  final RxString _summaryBoostPumpRate = ''.obs;
  final RxString _summaryReturnRate = ''.obs;
  final RxString _summaryDhToolsPressureLoss = ''.obs;
  final RxString _summaryMotorPressureLoss = ''.obs;

  static const List<String> _legacyShakerTypes = ['Shaker', 'Cleaner', 'Dryer'];
  static const List<String> _legacyOtherSceTypes = [
    'Degasser',
    'Desander',
    'Desilter',
    'Centrifuge',
    'Barite Rec.',
  ];
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
  static const double _topSectionMinWidth = 1110;
  static const double _leftSectionViewportWidth = 820;
  static const double _shakerTableMinWidth = 770;
  static const double _otherSceTableMinWidth = 520;

  String get _currentWellId => padWellContext.selectedWellId.value.trim();

  String? get _currentReportId {
    final reportId = reportContext.selectedReportId.value.trim();
    return reportId.isEmpty ? null : reportId;
  }

  String? get _currentReportNo {
    final reportNo = reportContext.selectedReportNumber.trim();
    return reportNo.isEmpty ? null : reportNo;
  }

  List<String> get _shakerTypes => _mergeOptions([
    ...SceController.shakerLabels,
    ..._legacyShakerTypes,
  ], sceController.availableShakerTypes);

  List<String> get _otherSceTypes => _mergeOptions([
    ...SceController.otherSceLabels,
    ..._legacyOtherSceTypes,
  ], sceController.availableOtherSceTypes);

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
      (_) => _reloadPageData(),
    );
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => _reloadPageData(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadPageData();
    });
  }

  Widget _horizontalViewport({
    required double viewportWidth,
    required double minContentWidth,
    required Widget child,
  }) {
    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(viewportWidth, minContentWidth),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _summarySaveDebounce?.cancel();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    _wellWorker?.dispose();
    _reportWorker?.dispose();
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

    _summaryPumpRate.value = _convertText(
      _summaryPumpRate.value,
      _flowUnit,
      nextFlowUnit,
    );
    _summaryBoostPumpRate.value = _convertText(
      _summaryBoostPumpRate.value,
      _flowUnit,
      nextFlowUnit,
    );
    _summaryReturnRate.value = _convertText(
      _summaryReturnRate.value,
      _flowUnit,
      nextFlowUnit,
    );
    _summaryPumpPressure.value = _convertText(
      _summaryPumpPressure.value,
      _pressureUnit,
      nextPressureUnit,
    );
    _summaryDhToolsPressureLoss.value = _convertText(
      _summaryDhToolsPressureLoss.value,
      _pressureUnit,
      nextPressureUnit,
    );
    _summaryMotorPressureLoss.value = _convertText(
      _summaryMotorPressureLoss.value,
      _pressureUnit,
      nextPressureUnit,
    );

    _diameterUnit = nextDiameterUnit;
    _lengthUnit = nextLengthUnit;
    _displacementUnit = nextDisplacementUnit;
    _flowUnit = nextFlowUnit;
    _pressureUnit = nextPressureUnit;
    _powerUnit = nextPowerUnit;
    _mudWeightUnit = nextMudWeightUnit;
    _pumpRows.refresh();
    _sceRows.refresh();
    _syncComputedSummaryFields();
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

  String _formatNumber(double value, {int decimals = 2}) {
    if (!value.isFinite) {
      return '';
    }
    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _formatFromBase(double value, String baseUnit, String displayUnit) {
    final converted =
        AppUnits.convertValue(value, baseUnit, displayUnit) ?? value;
    return _formatNumber(converted);
  }

  double _parseToBase(String rawValue, String displayUnit, String baseUnit) {
    final parsed = double.tryParse(rawValue.trim()) ?? 0;
    return AppUnits.convertValue(parsed, displayUnit, baseUnit) ?? parsed;
  }

  void _loadSummaryFromSelectedReport() {
    final summary = reportContext.selectedReport?.pumpRateAndPressure;
    _hydratingSummary = true;
    _summaryBoostPumpRate.value = _formatFromBase(
      summary?.boostPumpRate ?? 0,
      '(gpm)',
      _flowUnit,
    );
    _summaryPumpPressure.value = _formatFromBase(
      summary?.pumpPressure ?? 0,
      '(psi)',
      _pressureUnit,
    );
    _summaryDhToolsPressureLoss.value = _formatFromBase(
      summary?.dhToolsPressureLoss ?? 0,
      '(psi)',
      _pressureUnit,
    );
    _summaryMotorPressureLoss.value = _formatFromBase(
      summary?.motorPressureLoss ?? 0,
      '(psi)',
      _pressureUnit,
    );
    _hydratingSummary = false;
    _syncComputedSummaryFields();
  }

  void _syncComputedSummaryFields() {
    double pumpRateBase = 0;
    for (final row in _pumpRows) {
      final rowRate = double.tryParse(row.rate.value.trim());
      if (rowRate == null || rowRate <= 0) {
        continue;
      }
      pumpRateBase +=
          AppUnits.convertValue(rowRate, _flowUnit, '(gpm)') ?? rowRate;
    }

    final boostPumpRateBase = _parseToBase(
      _summaryBoostPumpRate.value,
      _flowUnit,
      '(gpm)',
    );
    final returnRateBase = pumpRateBase + boostPumpRateBase;

    _summaryPumpRate.value = _formatFromBase(pumpRateBase, '(gpm)', _flowUnit);
    _summaryReturnRate.value = _formatFromBase(
      returnRateBase,
      '(gpm)',
      _flowUnit,
    );
  }

  void _onSummaryValueChanged(RxString target, String value) {
    target.value = value;
    _syncComputedSummaryFields();
    if (_hydratingSummary) {
      return;
    }
    _scheduleSummarySave();
  }

  void _scheduleSummarySave() {
    if (_currentReportId == null) {
      return;
    }
    _summarySaveDebounce?.cancel();
    _summarySaveDebounce = Timer(
      const Duration(milliseconds: 700),
      () => _persistSummaryValues(),
    );
  }

  Future<void> _persistSummaryValues() async {
    final reportId = _currentReportId;
    if (reportId == null) {
      return;
    }

    final payload = {
      'pumpRateAndPressure': {
        'pumpRate': _parseToBase(_summaryPumpRate.value, _flowUnit, '(gpm)'),
        'pumpPressure': _parseToBase(
          _summaryPumpPressure.value,
          _pressureUnit,
          '(psi)',
        ),
        'boostPumpRate': _parseToBase(
          _summaryBoostPumpRate.value,
          _flowUnit,
          '(gpm)',
        ),
        'returnRate': _parseToBase(
          _summaryReturnRate.value,
          _flowUnit,
          '(gpm)',
        ),
        'dhToolsPressureLoss': _parseToBase(
          _summaryDhToolsPressureLoss.value,
          _pressureUnit,
          '(psi)',
        ),
        'motorPressureLoss': _parseToBase(
          _summaryMotorPressureLoss.value,
          _pressureUnit,
          '(psi)',
        ),
      },
    };

    try {
      _isSavingSummary.value = true;
      await _reportApi.updateReport(reportId, payload);
      await reportContext.reloadData();
      reportContext.selectReport(reportId);
    } catch (e) {
      _showMessage(
        'Failed to save summary: ${_friendlyMessage(e)}',
        isSuccess: false,
      );
    } finally {
      _isSavingSummary.value = false;
    }
  }

  List<String> _mergeOptions(List<String> preferred, Iterable<String> extra) {
    final ordered = <String>[];
    final seen = <String>{};

    for (final value in [...preferred, ...extra]) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) {
        continue;
      }
      ordered.add(trimmed);
    }

    return ordered;
  }

  void _resetLocalRows() {
    _pumpRows.assignAll(
      List.generate(
        _initialPumpRows,
        (index) => _PumpRow(rowNumber: index + 1),
      ),
    );
    _shakerRows.assignAll(
      List.generate(_initialShakerRows, (_) => _ShakerRow()),
    );
    _sceRows.assignAll(List.generate(_initialSceRows, (_) => _OtherSceRow()));
    _hydratingSummary = true;
    _summaryPumpRate.value = '';
    _summaryPumpPressure.value = '';
    _summaryBoostPumpRate.value = '';
    _summaryReturnRate.value = '';
    _summaryDhToolsPressureLoss.value = '';
    _summaryMotorPressureLoss.value = '';
    _hydratingSummary = false;
  }

  void _syncPumpRowsFromController() {
    final rows = pumpController.pumps
        .where((pump) => pump.hasData)
        .map(_PumpRow.fromPumpModel)
        .toList();

    if (rows.isEmpty) {
      rows.addAll(
        List.generate(
          _initialPumpRows,
          (index) => _PumpRow(rowNumber: index + 1),
        ),
      );
    } else {
      while (rows.length < _initialPumpRows) {
        rows.add(_PumpRow(rowNumber: rows.length + 1));
      }
      if (rows.last.hasData) {
        rows.add(_PumpRow(rowNumber: rows.length + 1));
      }
    }

    _pumpRows.assignAll(rows);
  }

  void _syncShakerRowsFromController() {
    final rows = sceController.shakers
        .where((shaker) => shaker.hasData)
        .map(_ShakerRow.fromModel)
        .toList();

    if (rows.isEmpty) {
      rows.addAll(List.generate(_initialShakerRows, (_) => _ShakerRow()));
    } else {
      while (rows.length < _initialShakerRows) {
        rows.add(_ShakerRow());
      }
      if (rows.last.hasData) {
        rows.add(_ShakerRow());
      }
    }

    _shakerRows.assignAll(rows);
  }

  void _syncOtherSceRowsFromController() {
    final rows = sceController.otherSce
        .where((sce) => sce.hasData)
        .map(_OtherSceRow.fromModel)
        .toList();

    if (rows.isEmpty) {
      rows.addAll(List.generate(_initialSceRows, (_) => _OtherSceRow()));
    } else {
      while (rows.length < _initialSceRows) {
        rows.add(_OtherSceRow());
      }
      if (rows.last.hasData) {
        rows.add(_OtherSceRow());
      }
    }

    _sceRows.assignAll(rows);
  }

  Future<void> _reloadPageData({bool showError = true}) async {
    _summarySaveDebounce?.cancel();
    final wellId = _currentWellId;
    if (wellId.isEmpty) {
      _resetLocalRows();
      return;
    }

    try {
      _isSyncing.value = true;
      await Future.wait([
        pumpController.loadPumps(wellId),
        sceController.loadSceData(wellId),
      ]);
      _syncPumpRowsFromController();
      _syncShakerRowsFromController();
      _syncOtherSceRowsFromController();
      _loadSummaryFromSelectedReport();
    } catch (e) {
      if (showError) {
        _showMessage(
          'Failed to load pump page data: ${_friendlyMessage(e)}',
          isSuccess: false,
        );
      }
    } finally {
      _isSyncing.value = false;
    }
  }

  Future<void> _savePumpRows() async {
    final wellId = _currentWellId;
    if (wellId.isEmpty) {
      _showMessage('Select a well before saving pumps', isSuccess: false);
      return;
    }

    final rowsToProcess = _pumpRows
        .where((row) => row.hasData || row.id != null)
        .toList();
    if (rowsToProcess.isEmpty) {
      _showMessage('No pumps to save', isSuccess: false);
      return;
    }

    try {
      _isSyncing.value = true;

      for (int index = 0; index < _pumpRows.length; index++) {
        final row = _pumpRows[index];
        if (!row.hasData && row.id == null) {
          continue;
        }

        if (!row.hasData && row.id != null) {
          await pumpController.repository.deletePump(
            row.id!,
            wellId: wellId,
            reportId: _currentReportId,
            reportNo: _currentReportNo,
          );
          continue;
        }

        final payload = row.toPumpModel(index).toJson();
        if (row.id != null) {
          await pumpController.repository.updatePump(
            row.id!,
            payload,
            wellId: wellId,
            reportId: _currentReportId,
            reportNo: _currentReportNo,
          );
        } else {
          await pumpController.repository.createPump(
            wellId,
            payload,
            reportId: _currentReportId,
            reportNo: _currentReportNo,
          );
        }
      }

      await _reloadPageData(showError: false);
      await _persistSummaryValues();
      _showMessage('Pump rows saved successfully');
    } catch (e) {
      _showMessage(
        'Failed to save pumps: ${_friendlyMessage(e)}',
        isSuccess: false,
      );
    } finally {
      _isSyncing.value = false;
    }
  }

  Future<void> _saveShakerRows() async {
    final wellId = _currentWellId;
    if (wellId.isEmpty) {
      _showMessage('Select a well before saving shakers', isSuccess: false);
      return;
    }

    final rowsToProcess = _shakerRows
        .where((row) => row.hasData || row.id != null)
        .toList();
    if (rowsToProcess.isEmpty) {
      _showMessage('No shakers to save', isSuccess: false);
      return;
    }

    try {
      _isSyncing.value = true;

      for (final row in _shakerRows) {
        if (!row.hasData && row.id == null) {
          continue;
        }

        if (!row.hasData && row.id != null) {
          await sceController.repository.deleteShaker(
            row.id!,
            reportId: _currentReportId,
            reportNo: _currentReportNo,
          );
          continue;
        }

        final payload = row.toModel().toJson();
        if (row.id != null) {
          await sceController.repository.updateShaker(
            row.id!,
            payload,
            reportId: _currentReportId,
            reportNo: _currentReportNo,
          );
        } else {
          await sceController.repository.createShaker(
            wellId,
            payload,
            reportId: _currentReportId,
            reportNo: _currentReportNo,
          );
        }
      }

      await _reloadPageData(showError: false);
      _showMessage('Shaker rows saved successfully');
    } catch (e) {
      _showMessage(
        'Failed to save shakers: ${_friendlyMessage(e)}',
        isSuccess: false,
      );
    } finally {
      _isSyncing.value = false;
    }
  }

  Future<void> _saveOtherSceRows() async {
    final wellId = _currentWellId;
    if (wellId.isEmpty) {
      _showMessage('Select a well before saving equipment', isSuccess: false);
      return;
    }

    final rowsToProcess = _sceRows
        .where((row) => row.hasData || row.id != null)
        .toList();
    if (rowsToProcess.isEmpty) {
      _showMessage('No equipment rows to save', isSuccess: false);
      return;
    }

    try {
      _isSyncing.value = true;

      for (final row in _sceRows) {
        if (!row.hasData && row.id == null) {
          continue;
        }

        if (!row.hasData && row.id != null) {
          await sceController.repository.deleteOtherSce(
            row.id!,
            reportId: _currentReportId,
            reportNo: _currentReportNo,
          );
          continue;
        }

        final payload = row.toModel().toJson();
        if (row.id != null) {
          await sceController.repository.updateOtherSce(
            row.id!,
            payload,
            reportId: _currentReportId,
            reportNo: _currentReportNo,
          );
        } else {
          await sceController.repository.createOtherSce(
            wellId,
            payload,
            reportId: _currentReportId,
            reportNo: _currentReportNo,
          );
        }
      }

      await _reloadPageData(showError: false);
      _showMessage('Other SCE rows saved successfully');
    } catch (e) {
      _showMessage(
        'Failed to save equipment: ${_friendlyMessage(e)}',
        isSuccess: false,
      );
    } finally {
      _isSyncing.value = false;
    }
  }

  String _friendlyMessage(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  void _showMessage(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
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

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AppUnits.signature;
      return Scaffold(
        backgroundColor: const Color(0xffF4F6FA),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth;
            final leftViewportWidth = math.min(
              pageWidth,
              _leftSectionViewportWidth,
            );

            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Flexible(
                    flex: 3,
                    child: _horizontalViewport(
                      viewportWidth: pageWidth,
                      minContentWidth: _topSectionMinWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pump table — fixed max width, narrower
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 780),
                              child: _pumpTable(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Summary box — wider fixed width
                          SizedBox(width: 310, child: _summaryBox()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: leftViewportWidth,
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
                      child: SizedBox(
                        width: leftViewportWidth,
                        child: _horizontalViewport(
                          viewportWidth: leftViewportWidth,
                          minContentWidth: _shakerTableMinWidth,
                          child: _shakerTable(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: leftViewportWidth,
                        child: _horizontalViewport(
                          viewportWidth: leftViewportWidth,
                          minContentWidth: _otherSceTableMinWidth,
                          child: _otherSCETable(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
                  _headerCell("Model", 100),
                  _verticalDivider(),
                  _headerCell("Type", 85),
                  _verticalDivider(),
                  _headerCell("Liner ID\n(in)", 68),
                  _verticalDivider(),
                  _headerCell("Rod OD\n(in)", 68),
                  _verticalDivider(),
                  _headerCell("Stk. Length\n(in)", 80),
                  _verticalDivider(),
                  _headerCell("Efficiency\n(%)", 75),
                  _verticalDivider(),
                  _headerCell("Displ.\n(bbl/stk)", 80),
                  _verticalDivider(),
                  _headerCell("Stroke\n(stk/min)", 80),
                  _verticalDivider(),
                  _headerCell("Rate\n(gpm)", 68),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final isLocked = dashboard.isLocked.value;
              final models = pumpController.availablePumpModels.toList();
              // React to _pumpRows list changes
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
                            width: 100,
                            child: _pumpModelDropdown(
                              row: row,
                              models: models,
                              isLocked: isLocked,
                              rowIndex: index,
                            ),
                          ),
                          _verticalDivider(),
                          _dataCell(
                            width: 85,
                            child: Obx(() => _readOnlyCell(row.type.value)),
                          ),
                          _verticalDivider(),
                          _dataCell(
                            width: 68,
                            child: Obx(() => _readOnlyCell(row.linerId.value)),
                          ),
                          _verticalDivider(),
                          _dataCell(
                            width: 68,
                            child: Obx(() => _readOnlyCell(row.rodOd.value)),
                          ),
                          _verticalDivider(),
                          _dataCell(
                            width: 80,
                            child: Obx(
                              () => _readOnlyCell(row.strokeLength.value),
                            ),
                          ),
                          _verticalDivider(),
                          _dataCell(
                            width: 75,
                            child: Obx(
                              () => _readOnlyCell(row.efficiency.value),
                            ),
                          ),
                          _verticalDivider(),
                          _dataCell(
                            width: 80,
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
                            width: 80,
                            child: _spmField(
                              row: row,
                              isLocked: isLocked,
                              rowIndex: index,
                            ),
                          ),
                          _verticalDivider(),
                          _dataCell(
                            width: 68,
                            child: Obx(
                              () => _readOnlyCell(
                                row.rate.value.isEmpty ? '-' : row.rate.value,
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
          _sectionActions(
            saveLabel: 'Save Pumps',
            onRefresh: _reloadPageData,
            onSave: _savePumpRows,
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
      return TextField(
        enabled: !isLocked,
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (val) {
          row.spm.value = val;
          row.recalculateRate();
          // ✅ Auto-add row when last row has data
          _checkAddPumpRow(rowIndex);
          _syncComputedSummaryFields();
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
                    _syncComputedSummaryFields();
                    return;
                  }

                  final source = pumpController.pumps.firstWhereOrNull(
                    (p) => p.model.value == selected && p.hasData,
                  );

                  if (source != null) {
                    row.model.value = selected;
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
                  _syncComputedSummaryFields();
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
                  _headerCell("Shaker", 100),
                  _verticalDivider(),
                  _headerCell("Model", 120),
                  _verticalDivider(),
                  _headerCellWithSubheaders(
                    "Screen",
                    List.generate(
                      _totalScreenCols,
                      (i) => _subHeaderCell("${i + 1}", 48),
                    ),
                  ),
                  _verticalDivider(),
                  _headerCell("Time\n(hr)", 70),
                  _verticalDivider(),
                  _headerCell("OOC Wt.\n(%)", 75),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final isLocked = dashboard.isLocked.value;
              final shakerModels = sceController.availableShakerModels.toList();
              final rows = _shakerRows.toList(); // react to list changes
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
                              width: 100,
                              child: _shakerTypeDropdown(
                                row: row,
                                isLocked: isLocked,
                                rowIndex: index,
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: 120,
                              child: _shakerModelDropdown(
                                row: row,
                                models: shakerModels,
                                isLocked: isLocked,
                                rowIndex: index,
                              ),
                            ),
                            _verticalDivider(),
                            ..._buildScreenCols(row, isLocked),
                            _verticalDivider(),
                            _dataCell(
                              width: 70,
                              child: _rxTextField(row.time, isLocked),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: 75,
                              child: _rxTextField(row.oocWt, isLocked),
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
          _sectionActions(
            saveLabel: 'Save Shakers',
            onRefresh: _reloadPageData,
            onSave: _saveShakerRows,
          ),
        ],
      ),
    );
  }

  Widget _shakerTypeDropdown({
    required _ShakerRow row,
    required bool isLocked,
    required int rowIndex,
  }) {
    return Obx(() {
      final current = row.shakerType.value.isEmpty
          ? null
          : row.shakerType.value;
      final safe = _shakerTypes.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (sel) {
                  row.shakerType.value = sel ?? '';
                  // ✅ Auto-add row when last row gets a type selected
                  _checkAddShakerRow(rowIndex);
                },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('', style: TextStyle(fontSize: 9)),
            ),
            ..._shakerTypes.map(
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
                  row.model.value = sel ?? '';
                  if (sel != null && sel.isNotEmpty) {
                    final data = await sceController.getShakerDataByModel(sel);
                    if (data != null) {
                      final apiType = data['shaker']?.toString() ?? '';
                      if (row.shakerType.value.isEmpty && apiType.isNotEmpty) {
                        row.shakerType.value = apiType;
                      }
                      final n =
                          int.tryParse(data['screens']?.toString() ?? '0') ?? 0;
                      row.enabledScreens.value = n;
                    }
                    // ✅ Auto-add row when last row's model is selected
                    _checkAddShakerRow(rowIndex);
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

  List<Widget> _buildScreenCols(_ShakerRow row, bool isLocked) {
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
          width: 48,
          child: Obx(() {
            final isEnabled = !isLocked && idx < row.enabledScreens.value;
            return TextField(
              enabled: isEnabled,
              controller: TextEditingController(text: fields[idx].value)
                ..selection = TextSelection.collapsed(
                  offset: fields[idx].value.length,
                ),
              onChanged: (v) => fields[idx].value = v,
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
                color: Colors.black.withValues(alpha: 0.04),
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
    for (final row in _shakerRows) {
      if (row.model.value.isEmpty) continue;
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
      for (
        int i = 0;
        i < row.enabledScreens.value && i < _totalScreenCols;
        i++
      ) {
        fields[i].value = fillVal;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  OTHER SCE TABLE
  // ═══════════════════════════════════════════════════════════

  Widget _otherSCETable() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
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
                  _headerCell("SCE", 90),
                  _verticalDivider(),
                  _headerCell("Model", 110),
                  _verticalDivider(),
                  _headerCell("U/F\n(ppg)", 70),
                  _verticalDivider(),
                  _headerCell("O/F\n(ppg)", 70),
                  _verticalDivider(),
                  _headerCell("Time\n(hr)", 70),
                  _verticalDivider(),
                  _headerCell("OOC Wt.\n(%)", 75),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final isLocked = dashboard.isLocked.value;
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
                              width: 90,
                              child: _sceTypeDropdown(
                                row: row,
                                isLocked: isLocked,
                                rowIndex: index,
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: 110,
                              child: _sceModelDropdown(
                                row: row,
                                models: sceModels,
                                isLocked: isLocked,
                                rowIndex: index,
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: 70,
                              child: _rxTextField(row.uf, isLocked),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: 70,
                              child: _rxTextField(row.of_, isLocked),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: 70,
                              child: _rxTextField(row.time, isLocked),
                            ),
                            _verticalDivider(),
                            _dataCell(
                              width: 75,
                              child: _rxTextField(row.oocWt, isLocked),
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
          _sectionActions(
            saveLabel: 'Save Equipment',
            onRefresh: _reloadPageData,
            onSave: _saveOtherSceRows,
          ),
        ],
      ),
    );
  }

  Widget _sceTypeDropdown({
    required _OtherSceRow row,
    required bool isLocked,
    required int rowIndex,
  }) {
    return Obx(() {
      final current = row.type.value.isEmpty ? null : row.type.value;
      final safe = _otherSceTypes.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (sel) {
                  row.type.value = sel ?? '';
                  if (sel == null) row.model.value = '';
                  // ✅ Auto-add row when last row gets a type
                  _checkAddSceRow(rowIndex);
                },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('', style: TextStyle(fontSize: 9)),
            ),
            ..._otherSceTypes.map(
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
              : (sel) async {
                  row.model.value = sel ?? '';
                  if (sel != null &&
                      sel.isNotEmpty &&
                      row.type.value.trim().isEmpty) {
                    final data = await sceController.getOtherSceDataByModel(
                      sel,
                    );
                    final apiType = data?['type']?.toString().trim() ?? '';
                    if (apiType.isNotEmpty) {
                      row.type.value = apiType;
                    }
                  }
                  // ✅ Auto-add row when last row's model is selected
                  _checkAddSceRow(rowIndex);
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
                  _summaryItem(
                    label: "Pump Rate",
                    unit: _flowUnit,
                    value: _summaryPumpRate,
                    readOnly: true,
                  ),
                  const SizedBox(height: 8),
                  _summaryItem(
                    label: "Pump Pressure",
                    unit: _pressureUnit,
                    value: _summaryPumpPressure,
                    onChanged: (value) =>
                        _onSummaryValueChanged(_summaryPumpPressure, value),
                  ),
                  const SizedBox(height: 8),
                  _summaryItem(
                    label: "Boost Pump Rate",
                    unit: _flowUnit,
                    value: _summaryBoostPumpRate,
                    onChanged: (value) =>
                        _onSummaryValueChanged(_summaryBoostPumpRate, value),
                  ),
                  const SizedBox(height: 8),
                  _summaryItem(
                    label: "Return Rate",
                    unit: _flowUnit,
                    value: _summaryReturnRate,
                    readOnly: true,
                  ),
                  const SizedBox(height: 8),
                  _summaryItem(
                    label: "DH Tools P. Loss",
                    unit: _pressureUnit,
                    value: _summaryDhToolsPressureLoss,
                    onChanged: (value) => _onSummaryValueChanged(
                      _summaryDhToolsPressureLoss,
                      value,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _summaryItem(
                    label: "Motor P. Loss",
                    unit: _pressureUnit,
                    value: _summaryMotorPressureLoss,
                    onChanged: (value) => _onSummaryValueChanged(
                      _summaryMotorPressureLoss,
                      value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionActions({
    required String saveLabel,
    required Future<void> Function({bool showError}) onRefresh,
    required Future<void> Function() onSave,
  }) {
    return Obx(() {
      final isLocked = dashboard.isLocked.value;
      final isBusy =
          _isSyncing.value ||
          _isSavingSummary.value ||
          pumpController.isLoading.value ||
          sceController.isLoading.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: isBusy ? null : () => onRefresh(showError: true),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text(
                'Refresh',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: isLocked || isBusy ? null : onSave,
              icon: isBusy
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 14),
              label: Text(
                isBusy ? 'Working...' : saveLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _summaryItem({
    required String label,
    required String unit,
    required RxString value,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
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
            child: Obx(() {
              final text = value.value;
              final controller = TextEditingController(text: text)
                ..selection = TextSelection.collapsed(offset: text.length);
              final locked = dashboard.isLocked.value;

              return TextField(
                enabled: !locked,
                readOnly: readOnly,
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: readOnly ? null : onChanged,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 9,
                  color: locked ? Colors.grey.shade400 : Colors.black87,
                ),
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
                  fillColor: readOnly
                      ? const Color(0xffF2F7FC)
                      : Colors.grey.shade50,
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
              );
            }),
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

  Widget _rxTextField(RxString rxValue, bool isLocked) {
    return Obx(
      () => TextField(
        enabled: !isLocked,
        controller: TextEditingController(text: rxValue.value)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: rxValue.value.length),
          ),
        onChanged: (v) => rxValue.value = v,
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
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ],
    border: Border.all(color: Colors.grey.shade300, width: 0.5),
  );
}
