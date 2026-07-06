import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

const int _planColumnCount = 31;
const int _planMinimumRows = 18;
const Duration _casingAutoSaveDelay = Duration(milliseconds: 300);

List<Map<String, String>> _defaultPlanSummary() => [
  {'type': 'TD', 'amount': '', 'unit': '(ft)'},
  {'type': 'Days', 'amount': '', 'unit': '(-)'},
  {'type': 'Total Cost', 'amount': '', 'unit': '(Kwd)'},
];

List<String> _normalizePlanRow(List<dynamic>? values) {
  final row = List<String>.filled(_planColumnCount, '');
  if (values == null) return row;
  final limit = values.length < _planColumnCount
      ? values.length
      : _planColumnCount;
  for (var i = 0; i < limit; i++) {
    row[i] = (values[i] ?? '').toString();
  }
  return row;
}

List<List<String>> _padPlanRows(List<List<String>> rows) {
  final padded = rows.map((row) => _normalizePlanRow(row)).toList();
  while (padded.length < _planMinimumRows) {
    padded.add(List<String>.filled(_planColumnCount, ''));
  }
  return padded;
}

class UgStController extends GetxController {
  var selectedWellTab = 0.obs; // 0 = Well
  var selectedWellId = Rx<String?>(null);
  var isLocked = true.obs;
  var isLoading = false.obs;
  Worker? _selectedWellWorker;
  Worker? _dashboardLockWorker;
  Worker? _reportWorker;
  final List<Worker> _unitWorkers = <Worker>[];
  Timer? _casingAutoSaveTimer;
  Timer? _planAutoSaveTimer;
  CasingRow? _pendingCasingAutoSave;
  bool _isSavingCasing = false;
  bool _isSavingPlan = false;
  late String _planLengthUnit;
  late String _planMudWeightUnit;
  late String _planFunnelViscosityUnit;
  late String _planViscosityUnit;
  late String _planYieldPointUnit;
  late String _planSmallVolumeUnit;
  late String _planMassVolumeRatioUnit;
  final selectedCasingDeleteKey = ''.obs;

  final casingVerticalScroll = ScrollController();
  final casingHorizontalScroll = ScrollController();
  final isPlanLoading = false.obs;

  @override
  void onInit() {
    _planLengthUnit = AppUnits.length;
    _planMudWeightUnit = AppUnits.mudWeight;
    _planFunnelViscosityUnit = AppUnits.funnelViscosity;
    _planViscosityUnit = AppUnits.viscosity;
    _planYieldPointUnit = AppUnits.yieldPoint;
    _planSmallVolumeUnit = AppUnits.smallVolume;
    _planMassVolumeRatioUnit = AppUnits.massVolumeRatio;
    final context = padWellContext;
    selectedWellId.value = context.selectedWellId.value.isEmpty
        ? null
        : context.selectedWellId.value;
    final dashboardController = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : null;
    if (dashboardController != null) {
      isLocked.value = dashboardController.isLocked.value;
      _dashboardLockWorker = ever<bool>(dashboardController.isLocked, (locked) {
        if (isLocked.value != locked) {
          isLocked.value = locked;
        }
      });
    }
    _selectedWellWorker = ever<String>(context.selectedWellId, (wellId) {
      selectedWellId.value = wellId.isEmpty ? null : wellId;
      fetchCasings();
      fetchPlan();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      fetchPlan();
    });
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handlePlanUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handlePlanUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handlePlanUnitChange()),
    ]);
    fetchCasings();
    fetchPlan();
    super.onInit();
  }

  @override
  void onClose() {
    unawaited(flushPendingCasingSave());
    casingVerticalScroll.dispose();
    casingHorizontalScroll.dispose();
    _casingAutoSaveTimer?.cancel();
    _planAutoSaveTimer?.cancel();
    _selectedWellWorker?.dispose();
    _dashboardLockWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    super.onClose();
  }

  // Summary table data
  final summaryData = _defaultPlanSummary().obs;

  // Big plan table data
  final planData = <List<String>>[].obs;

  final casings = <CasingRow>[].obs;

  String get _selectedWellId => (selectedWellId.value ?? '').trim();

  String casingRowKey(CasingRow row) => row.dbId?.trim().isNotEmpty == true
      ? row.dbId!
      : identityHashCode(row).toString();

  void selectCasingForDelete(CasingRow row) {
    selectedCasingDeleteKey.value = casingRowKey(row);
  }

  bool _hasCasingData(CasingRow row) =>
      row.description.value.trim().isNotEmpty ||
      row.type.value.trim().isNotEmpty ||
      row.od.value.trim().isNotEmpty ||
      row.wt.value.trim().isNotEmpty ||
      row.id.value.trim().isNotEmpty ||
      row.top.value.trim().isNotEmpty ||
      row.shoe.value.trim().isNotEmpty ||
      row.bit.value.trim().isNotEmpty ||
      row.toc.value.trim().isNotEmpty;

  void scheduleCasingAutoSave(CasingRow row) {
    if (isLocked.value ||
        isLoading.value ||
        _selectedWellId.isEmpty ||
        !_hasCasingData(row)) {
      return;
    }
    _pendingCasingAutoSave = row;
    _casingAutoSaveTimer?.cancel();
    _casingAutoSaveTimer = Timer(_casingAutoSaveDelay, () async {
      final pending = _pendingCasingAutoSave;
      if (pending == null ||
          isLocked.value ||
          isLoading.value ||
          !_hasCasingData(pending)) {
        return;
      }
      if (_isSavingCasing) {
        scheduleCasingAutoSave(pending);
        return;
      }
      _isSavingCasing = true;
      try {
        final isNew = pending.dbId == null || pending.dbId!.trim().isEmpty;
        final saved = isNew
            ? await addCasing(pending, refresh: false)
            : await updateCasing(pending, refresh: false);
        if (saved && isNew) {
          casings.refresh();
        }
      } finally {
        _isSavingCasing = false;
      }
    });
  }

  Future<void> flushPendingCasingSave() async {
    final pending = _pendingCasingAutoSave;
    _casingAutoSaveTimer?.cancel();
    _casingAutoSaveTimer = null;
    if (pending == null ||
        isLocked.value ||
        isLoading.value ||
        _selectedWellId.isEmpty ||
        !_hasCasingData(pending)) {
      return;
    }

    while (_isSavingCasing) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    _isSavingCasing = true;
    try {
      final isNew = pending.dbId == null || pending.dbId!.trim().isEmpty;
      final saved = isNew
          ? await addCasing(pending, refresh: false)
          : await updateCasing(pending, refresh: false);
      if (saved && isNew) {
        casings.refresh();
      }
    } finally {
      _isSavingCasing = false;
      if (identical(_pendingCasingAutoSave, pending)) {
        _pendingCasingAutoSave = null;
      }
    }
  }

  Map<String, String> get _casingQueryParams => const {};

  Map<String, String> get _planQueryParams => {
    if (reportContext.selectedReportId.value.trim().isNotEmpty)
      'reportId': reportContext.selectedReportId.value.trim(),
    if (reportContext.selectedReportNumber.trim().isNotEmpty)
      'reportNo': reportContext.selectedReportNumber.trim(),
  };

  Future<void> fetchCasings() async {
    final wellId = _selectedWellId;
    if (wellId.isEmpty) {
      casings.clear();
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoint.baseUrl}casing/$wellId',
        ).replace(queryParameters: _casingQueryParams),
        headers: ApiEndpoint.jsonHeaders,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success']) {
          final List<dynamic> data = body['data'];
          casings.assignAll(
            data
                .where(
                  (e) =>
                      e is Map &&
                      (e['toc'] ?? '').toString() != kCasedHoleTocMarker,
                )
                .map((e) => CasingRow.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
          );
          selectedCasingDeleteKey.value = '';
        }
      }
    } catch (e) {
      print('Error fetching casings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool _hasPlanDataRow(List<String> row) =>
      row.any((value) => value.trim().isNotEmpty);

  List<List<String>> _trimmedPlanRows() {
    final rows = planData.map((row) => _normalizePlanRow(row)).toList();
    while (rows.isNotEmpty && !_hasPlanDataRow(rows.last)) {
      rows.removeLast();
    }
    return rows;
  }

  List<Map<String, String>> _normalizedSummaryPayload() {
    final defaults = _defaultPlanSummary();
    return List<Map<String, String>>.generate(defaults.length, (index) {
      final existing = index < summaryData.length
          ? summaryData[index]
          : <String, String>{};
      return {
        'type': existing['type']?.trim().isNotEmpty == true
            ? existing['type']!.trim()
            : defaults[index]['type']!,
        'amount': index == 0
            ? _convertText(
                existing['amount']?.trim() ?? '',
                AppUnits.length,
                '(ft)',
              )
            : existing['amount']?.trim() ?? '',
        'unit': defaults[index]['unit']!,
      };
    });
  }

  List<Map<String, String>> _displayPlanSummary(
    List<Map<String, String>> summary,
  ) {
    final defaults = _defaultPlanSummary();
    return List<Map<String, String>>.generate(defaults.length, (index) {
      final existing = index < summary.length
          ? summary[index]
          : defaults[index];
      final amount = (existing['amount'] ?? '').toString();
      return {
        'type': (existing['type'] ?? defaults[index]['type'] ?? '').toString(),
        'amount': index == 0
            ? _convertText(amount, '(ft)', AppUnits.length)
            : amount,
        'unit': index == 0 ? AppUnits.length : defaults[index]['unit']!,
      };
    });
  }

  List<String> _displayPlanRow(List<dynamic>? values) {
    final row = _normalizePlanRow(values);
    for (var i = 0; i < row.length; i++) {
      final baseUnit = _planBaseUnitForColumn(i);
      if (baseUnit == null) continue;
      row[i] = _convertText(row[i], baseUnit, _planActiveUnitForColumn(i)!);
    }
    return row;
  }

  List<String> _storePlanRow(List<String> values) {
    final row = _normalizePlanRow(values);
    for (var i = 0; i < row.length; i++) {
      final baseUnit = _planBaseUnitForColumn(i);
      if (baseUnit == null) continue;
      row[i] = _convertText(row[i], _planActiveUnitForColumn(i)!, baseUnit);
    }
    return row;
  }

  String? _planBaseUnitForColumn(int column) {
    if (column == 0) return '(ft)';
    if (column == 3 || column == 4) return '(ppg)';
    if (column == 5 || column == 6) return '(sec/qt)';
    if (column == 7 || column == 8) return '(cP)';
    if (column == 9 || column == 10) return '(lbf/100ft2)';
    if (column == 11 || column == 12 || column == 13 || column == 14) {
      return '(mL)';
    }
    if (column == 27 || column == 28) return '(lb/bbl)';
    return null;
  }

  String? _planActiveUnitForColumn(int column) {
    if (column == 0) return AppUnits.length;
    if (column == 3 || column == 4) return AppUnits.mudWeight;
    if (column == 5 || column == 6) return AppUnits.funnelViscosity;
    if (column == 7 || column == 8) return AppUnits.viscosity;
    if (column == 9 || column == 10) return AppUnits.yieldPoint;
    if (column == 11 || column == 12 || column == 13 || column == 14) {
      return AppUnits.smallVolume;
    }
    if (column == 27 || column == 28) return AppUnits.massVolumeRatio;
    return null;
  }

  void _handlePlanUnitChange() {
    final nextLengthUnit = AppUnits.length;
    final nextMudWeightUnit = AppUnits.mudWeight;
    final nextFunnelViscosityUnit = AppUnits.funnelViscosity;
    final nextViscosityUnit = AppUnits.viscosity;
    final nextYieldPointUnit = AppUnits.yieldPoint;
    final nextSmallVolumeUnit = AppUnits.smallVolume;
    final nextMassVolumeRatioUnit = AppUnits.massVolumeRatio;

    if (_planLengthUnit == nextLengthUnit &&
        _planMudWeightUnit == nextMudWeightUnit &&
        _planFunnelViscosityUnit == nextFunnelViscosityUnit &&
        _planViscosityUnit == nextViscosityUnit &&
        _planYieldPointUnit == nextYieldPointUnit &&
        _planSmallVolumeUnit == nextSmallVolumeUnit &&
        _planMassVolumeRatioUnit == nextMassVolumeRatioUnit) {
      return;
    }

    if (summaryData.isNotEmpty) {
      summaryData[0]['amount'] = _convertText(
        summaryData[0]['amount'] ?? '',
        _planLengthUnit,
        nextLengthUnit,
      );
      summaryData[0]['unit'] = nextLengthUnit;
      summaryData.refresh();
    }

    final nextRows = planData.map((source) {
      final row = _normalizePlanRow(source);
      row[0] = _convertText(row[0], _planLengthUnit, nextLengthUnit);
      for (final column in [3, 4]) {
        row[column] = _convertText(
          row[column],
          _planMudWeightUnit,
          nextMudWeightUnit,
        );
      }
      for (final column in [5, 6]) {
        row[column] = _convertText(
          row[column],
          _planFunnelViscosityUnit,
          nextFunnelViscosityUnit,
        );
      }
      for (final column in [7, 8]) {
        row[column] = _convertText(
          row[column],
          _planViscosityUnit,
          nextViscosityUnit,
        );
      }
      for (final column in [9, 10]) {
        row[column] = _convertText(
          row[column],
          _planYieldPointUnit,
          nextYieldPointUnit,
        );
      }
      for (final column in [11, 12, 13, 14]) {
        row[column] = _convertText(
          row[column],
          _planSmallVolumeUnit,
          nextSmallVolumeUnit,
        );
      }
      for (final column in [27, 28]) {
        row[column] = _convertText(
          row[column],
          _planMassVolumeRatioUnit,
          nextMassVolumeRatioUnit,
        );
      }
      return row;
    }).toList();

    _planLengthUnit = nextLengthUnit;
    _planMudWeightUnit = nextMudWeightUnit;
    _planFunnelViscosityUnit = nextFunnelViscosityUnit;
    _planViscosityUnit = nextViscosityUnit;
    _planYieldPointUnit = nextYieldPointUnit;
    _planSmallVolumeUnit = nextSmallVolumeUnit;
    _planMassVolumeRatioUnit = nextMassVolumeRatioUnit;

    planData.assignAll(_padPlanRows(nextRows));
  }

  String _convertText(String value, String fromUnit, String toUnit) {
    final raw = value.trim();
    if (raw.isEmpty || fromUnit == toUnit) return value;
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) return value;
    final converted = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (converted == null) return value;
    return converted
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> fetchPlan() async {
    final wellId = _selectedWellId;
    if (wellId.isEmpty) {
      summaryData.assignAll(_defaultPlanSummary());
      planData.assignAll(_padPlanRows([]));
      return;
    }

    isPlanLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoint.baseUrl}well-plan/$wellId',
        ).replace(queryParameters: _planQueryParams),
        headers: ApiEndpoint.jsonHeaders,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true) {
          final data = Map<String, dynamic>.from(body['data'] ?? {});
          final rawSummary = (data['summary'] as List?) ?? const [];
          final defaults = _defaultPlanSummary();
          final nextSummary = List<Map<String, String>>.generate(
            defaults.length,
            (index) {
              final entry = index < rawSummary.length
                  ? Map<String, dynamic>.from(rawSummary[index] as Map)
                  : <String, dynamic>{};
              return {
                'type': (entry['type'] ?? defaults[index]['type'] ?? '')
                    .toString(),
                'amount': (entry['amount'] ?? '').toString(),
                'unit': (entry['unit'] ?? defaults[index]['unit'] ?? '')
                    .toString(),
              };
            },
          );
          final rawRows = (data['rows'] as List?) ?? const [];
          final nextRows = rawRows.map((entry) {
            final map = Map<String, dynamic>.from(entry as Map);
            final values = (map['values'] as List?) ?? const [];
            return _normalizePlanRow(values);
          }).toList();
          summaryData.assignAll(_displayPlanSummary(nextSummary));
          planData.assignAll(
            _padPlanRows(nextRows.map(_displayPlanRow).toList()),
          );
          return;
        }
      }
    } catch (e) {
      print('Error fetching plan: $e');
    } finally {
      isPlanLoading.value = false;
    }

    summaryData.assignAll(_defaultPlanSummary());
    planData.assignAll(_padPlanRows([]));
  }

  Future<bool> savePlan({bool refreshAfterSave = false}) async {
    final wellId = _selectedWellId;
    if (wellId.isEmpty) return false;

    final payload = {
      'wellId': wellId,
      if (reportContext.selectedReportId.value.trim().isNotEmpty)
        'reportId': reportContext.selectedReportId.value.trim(),
      if (reportContext.selectedReportNumber.trim().isNotEmpty)
        'reportNo': reportContext.selectedReportNumber.trim(),
      'summary': _normalizedSummaryPayload(),
      'rows': _trimmedPlanRows().asMap().entries.map((entry) {
        return {
          'rowNumber': entry.key + 1,
          'values': _storePlanRow(entry.value),
        };
      }).toList(),
    };

    try {
      final response = await http.put(
        Uri.parse(
          '${ApiEndpoint.baseUrl}well-plan/$wellId',
        ).replace(queryParameters: _planQueryParams),
        headers: ApiEndpoint.jsonHeaders,
        body: json.encode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (refreshAfterSave) {
          await fetchPlan();
        }
        return true;
      }
    } catch (e) {
      print('Error saving plan: $e');
    }
    return false;
  }

  void schedulePlanAutoSave() {
    if (isLocked.value || isPlanLoading.value || _selectedWellId.isEmpty)
      return;
    _planAutoSaveTimer?.cancel();
    _planAutoSaveTimer = Timer(const Duration(milliseconds: 900), () async {
      if (isLocked.value || isPlanLoading.value || _selectedWellId.isEmpty)
        return;
      if (_isSavingPlan) {
        schedulePlanAutoSave();
        return;
      }
      _isSavingPlan = true;
      try {
        await savePlan();
      } finally {
        _isSavingPlan = false;
      }
    });
  }

  void updateSummaryData(
    int index,
    String key,
    String value, {
    bool notify = false,
    bool autoSave = true,
  }) {
    if (index < 0 || index >= summaryData.length) return;
    summaryData[index][key] = value;
    if (notify) summaryData.refresh();
    if (autoSave) schedulePlanAutoSave();
  }

  void updatePlanData(
    int row,
    int col,
    String value, {
    bool notify = false,
    bool autoSave = true,
  }) {
    if (row < 0 || col < 0) return;
    while (planData.length <= row) {
      planData.add(List<String>.filled(_planColumnCount, ''));
    }
    final current = _normalizePlanRow(planData[row]);
    current[col] = value;
    planData[row] = current;
    if (notify) planData.refresh();
    if (autoSave) schedulePlanAutoSave();
  }

  void insertPlanRow(int index, {List<String>? values}) {
    final row = _normalizePlanRow(values);
    final safeIndex = index < 0
        ? 0
        : (index > planData.length ? planData.length : index);
    planData.insert(safeIndex, row);
    while (planData.length < _planMinimumRows) {
      planData.add(List<String>.filled(_planColumnCount, ''));
    }
    planData.refresh();
    schedulePlanAutoSave();
  }

  void replacePlanRow(int index, List<String> values) {
    if (index < 0) return;
    while (planData.length <= index) {
      planData.add(List<String>.filled(_planColumnCount, ''));
    }
    planData[index] = _normalizePlanRow(values);
    planData.refresh();
    schedulePlanAutoSave();
  }

  void deletePlanRow(int index) {
    if (index < 0 || index >= planData.length) return;
    planData.removeAt(index);
    while (planData.length < _planMinimumRows) {
      planData.add(List<String>.filled(_planColumnCount, ''));
    }
    planData.refresh();
    schedulePlanAutoSave();
  }

  void movePlanRowToTop(int index) {
    final rows = _trimmedPlanRows();
    if (index <= 0 || index >= rows.length) return;
    final row = rows.removeAt(index);
    rows.insert(0, _normalizePlanRow(row));
    planData.assignAll(_padPlanRows(rows));
    schedulePlanAutoSave();
  }

  void movePlanRowToBottom(int index) {
    final rows = _trimmedPlanRows();
    if (index < 0 || index >= rows.length) return;
    final row = rows.removeAt(index);
    rows.add(_normalizePlanRow(row));
    planData.assignAll(_padPlanRows(rows));
    schedulePlanAutoSave();
  }

  void refreshPlanSummaryFromRows() {
    final trimmed = _trimmedPlanRows();
    if (trimmed.isEmpty) {
      for (var i = 0; i < summaryData.length; i++) {
        summaryData[i]['amount'] = '';
      }
    } else {
      final last = trimmed.last;
      summaryData[0]['amount'] = last[0];
      summaryData[1]['amount'] = last[1];
      summaryData[2]['amount'] = last[2];
    }
    summaryData.refresh();
    schedulePlanAutoSave();
  }

  Future<bool> addCasing(CasingRow casing, {bool refresh = true}) async {
    final wellId = _selectedWellId;
    if (wellId.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiEndpoint.baseUrl}casing',
        ).replace(queryParameters: _casingQueryParams),
        headers: ApiEndpoint.jsonHeaders,
        body: json.encode({
          ...casing.toJson(),
          'wellId': wellId,
        }),
      );
      if (response.statusCode == 201) {
        final Map<String, dynamic> body = json.decode(response.body);
        final id = body['data']?['_id']?.toString();
        if (id != null && id.isNotEmpty) {
          casing.dbId = id;
        }
        if (refresh) fetchCasings();
        return true;
      }
    } catch (e) {
      print('Error adding casing: $e');
    }
    return false;
  }

  Future<bool> updateCasing(CasingRow casing, {bool refresh = true}) async {
    final wellId = _selectedWellId;
    if (wellId.isEmpty || casing.dbId == null) return false;
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiEndpoint.baseUrl}casing/$wellId/${casing.dbId}',
        ).replace(queryParameters: _casingQueryParams),
        headers: ApiEndpoint.jsonHeaders,
        body: json.encode({
          ...casing.toJson(),
          'wellId': wellId,
        }),
      );
      if (response.statusCode == 200) {
        if (refresh) fetchCasings();
        return true;
      }
    } catch (e) {
      print('Error updating casing: $e');
    }
    return false;
  }

  Future<void> deleteCasing(String dbId) async {
    final wellId = _selectedWellId;
    if (wellId.isEmpty) return;

    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiEndpoint.baseUrl}casing/$wellId/$dbId',
        ).replace(queryParameters: _casingQueryParams),
        headers: ApiEndpoint.jsonHeaders,
      );
      if (response.statusCode == 200) {
        selectedCasingDeleteKey.value = '';
        fetchCasings();
      }
    } catch (e) {
      print('Error deleting casing: $e');
    }
  }

  // Interval list
  final intervals = <String>[].obs;

  final sectionData = [
    SectionPoint(0, 0),
    SectionPoint(500, 20),
    SectionPoint(1000, 40),
    SectionPoint(2000, 60),
    SectionPoint(4000, 120),
    SectionPoint(6000, 200),
    SectionPoint(8000, 400),
  ];

  // Selected index
  final selectedIndex = (-1).obs;

  // Counter for new interval naming
  int _newIntervalCount = 3;

  void select(int index) {
    selectedIndex.value = index;
  }

  void insertBefore() {
    if (selectedIndex.value == -1) return;

    intervals.insert(
      selectedIndex.value,
      'New Interval (${_newIntervalCount++})',
    );
  }

  void insertAfter() {
    if (selectedIndex.value == -1) return;

    intervals.insert(
      selectedIndex.value + 1,
      'New Interval (${_newIntervalCount++})',
    );
  }

  void removeInterval() {
    if (selectedIndex.value == -1) return;

    intervals.removeAt(selectedIndex.value);
    selectedIndex.value = -1;
  }

  void switchWellTab(int index) async {
    // If moving AWAY from Inventory tab (index 1)
    if (selectedWellTab.value == 1 && index != 1) {
      final ugCtrl = Get.isRegistered<UgController>()
          ? Get.find<UgController>()
          : null;

      if (ugCtrl != null && ugCtrl.isInventoryDirty()) {
        final result = await Get.dialog<String>(
          AlertDialog(
            title: Text(
              'Unsaved Changes',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
            content: Text(
              'You have unsaved data in the new entry rows. Would you like to save before switching?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: 'cancel'),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Get.back(result: 'discard'),
                child: Text('Discard', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: 'save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (result == 'cancel') return;
        if (result == 'save') {
          await ugCtrl.saveInventory();
        }
        // If 'discard' or successful 'save', proceed to switch
      }
    }

    selectedWellTab.value = index;
  }

  void toggleLock() {
    final next = !isLocked.value;
    isLocked.value = next;

    if (Get.isRegistered<DashboardController>()) {
      final dashboardController = Get.find<DashboardController>();
      if (dashboardController.isLocked.value != next) {
        dashboardController.isLocked.value = next;
      }
    }
  }
}
