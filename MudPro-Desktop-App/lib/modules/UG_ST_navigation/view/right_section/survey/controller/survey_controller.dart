import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/survey_model.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class SurveyController extends GetxController {
  static const int stationMinimumRows = 19;
  static const int annotationMinimumRows = 10;

  final UgStController ugStController = Get.find<UgStController>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final selectedTab = 0.obs;

  final plannedSurvey = true.obs;
  final annotationEnabled = true.obs;
  final projectAziEnabled = false.obs;
  final projectAzi = ''.obs;

  final stations = <SurveyStationRow>[].obs;
  final annotations = <SurveyAnnotationRow>[].obs;

  final selectedStationIndex = (-1).obs;
  final selectedAnnotationIndex = (-1).obs;

  final rotationX = (-0.55).obs;
  final rotationY = (0.75).obs;
  final zoom = 1.0.obs;

  final projectAziController = TextEditingController();

  Worker? _wellWorker;
  Worker? _reportWorker;
  final List<Worker> _unitWorkers = <Worker>[];
  Timer? _autosaveTimer;

  SurveyStationRow? _stationClipboard;
  SurveyAnnotationRow? _annotationClipboard;

  String? _currentWellId;
  late String _lengthUnit;

  bool get isLocked => ugStController.isLocked.value;

  bool get hasStationSelection =>
      selectedStationIndex.value >= 0 &&
      selectedStationIndex.value < stations.length;

  bool get hasAnnotationSelection =>
      selectedAnnotationIndex.value >= 0 &&
      selectedAnnotationIndex.value < annotations.length;

  bool get hasStationClipboard => _stationClipboard != null;
  bool get hasAnnotationClipboard => _annotationClipboard != null;

  static const List<String> annotationSymbols = [
    '',
    'circle_open',
    'circle_filled',
    'square_cross',
    'square_filled',
    'square_grid',
    'triangle',
  ];

  Map<String, String> get _queryParams => {
    if (reportContext.selectedReportId.value.trim().isNotEmpty)
      'reportId': reportContext.selectedReportId.value.trim(),
    if (reportContext.selectedReportNumber.trim().isNotEmpty)
      'reportNo': reportContext.selectedReportNumber.trim(),
  };

  @override
  void onInit() {
    super.onInit();
    _lengthUnit = AppUnits.length;
    _currentWellId = padWellContext.selectedWellId.value.trim().isNotEmpty
        ? padWellContext.selectedWellId.value.trim()
        : null;
    _replaceStations(
      List.generate(stationMinimumRows, (_) => SurveyStationRow.blank()),
    );
    _replaceAnnotations(
      List.generate(annotationMinimumRows, (_) => SurveyAnnotationRow.blank()),
    );

    _wellWorker = ever<String>(padWellContext.selectedWellId, (wellId) {
      _currentWellId = wellId.trim().isEmpty ? null : wellId.trim();
      loadSurvey();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      loadSurvey();
    });
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);

    if (_currentWellId != null && _currentWellId!.isNotEmpty) {
      loadSurvey();
    }
  }

  @override
  void onClose() {
    _autosaveTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    for (final row in stations) {
      row.dispose();
    }
    for (final row in annotations) {
      row.dispose();
    }
    projectAziController.dispose();
    super.onClose();
  }

  Future<void> loadSurvey() async {
    final wellId = _currentWellId;
    if (wellId == null || wellId.isEmpty) {
      _resetBlank();
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoint.baseUrl}survey/$wellId',
        ).replace(queryParameters: _queryParams),
        headers: ApiEndpoint.jsonHeaders,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = Map<String, dynamic>.from(body['data'] ?? {});
          plannedSurvey.value = data['plannedSurvey'] != false;
          annotationEnabled.value = data['annotationEnabled'] != false;
          projectAziEnabled.value = data['projectAziEnabled'] == true;
          projectAzi.value = (data['projectAzi'] ?? '').toString();
          if (projectAziController.text != projectAzi.value) {
            projectAziController.value = projectAziController.value.copyWith(
              text: projectAzi.value,
              selection: TextSelection.collapsed(
                offset: projectAzi.value.length,
              ),
            );
          }

          final nextStations = ((data['rows'] as List?) ?? const [])
              .map(
                (item) => SurveyStationRow.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .map(_displayStationRow)
              .toList();
          final nextAnnotations = ((data['annotations'] as List?) ?? const [])
              .map(
                (item) => SurveyAnnotationRow.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .map(_displayAnnotationRow)
              .toList();

          _replaceStations(nextStations);
          _replaceAnnotations(nextAnnotations);
          _recalculateAllRows();
          return;
        }
      }
      _resetBlank();
    } catch (_) {
      _resetBlank();
    } finally {
      isLoading.value = false;
    }
  }

  void _resetBlank() {
    plannedSurvey.value = true;
    annotationEnabled.value = true;
    projectAziEnabled.value = false;
    projectAzi.value = '';
    projectAziController.clear();
    _replaceStations(
      List.generate(stationMinimumRows, (_) => SurveyStationRow.blank()),
    );
    _replaceAnnotations(
      List.generate(annotationMinimumRows, (_) => SurveyAnnotationRow.blank()),
    );
    _recalculateAllRows();
  }

  Future<void> saveSurvey() async {
    final wellId = _currentWellId;
    if (wellId == null || wellId.isEmpty) return;

    isSaving.value = true;
    try {
      final payload = {
        'wellId': wellId,
        if (reportContext.selectedReportId.value.trim().isNotEmpty)
          'reportId': reportContext.selectedReportId.value.trim(),
        if (reportContext.selectedReportNumber.trim().isNotEmpty)
          'reportNo': reportContext.selectedReportNumber.trim(),
        'plannedSurvey': plannedSurvey.value,
        'annotationEnabled': annotationEnabled.value,
        'projectAziEnabled': projectAziEnabled.value,
        'projectAzi': projectAzi.value.trim(),
        'rows': _trimmedStations().asMap().entries.map((entry) {
          return {'rowNumber': entry.key + 1, ..._stationBaseJson(entry.value)};
        }).toList(),
        'annotations': _trimmedAnnotations().asMap().entries.map((entry) {
          return {
            'rowNumber': entry.key + 1,
            ..._annotationBaseJson(entry.value),
          };
        }).toList(),
      };

      await http.put(
        Uri.parse(
          '${ApiEndpoint.baseUrl}survey/$wellId',
        ).replace(queryParameters: _queryParams),
        headers: ApiEndpoint.jsonHeaders,
        body: json.encode(payload),
      );
    } finally {
      isSaving.value = false;
    }
  }

  void scheduleAutosave() {
    final wellId = _currentWellId;
    if (wellId == null || wellId.isEmpty) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 900), () async {
      await saveSurvey();
    });
  }

  void _handleUnitChange() {
    final nextLengthUnit = AppUnits.length;
    if (_lengthUnit == nextLengthUnit) return;

    for (final row in stations) {
      row.md = _convertText(row.md, _lengthUnit, nextLengthUnit);
      row.syncEditableControllers();
    }
    for (final row in annotations) {
      row.md = _convertText(row.md, _lengthUnit, nextLengthUnit);
      row.syncEditableControllers();
    }
    _lengthUnit = nextLengthUnit;
    _recalculateAllRows();
    annotations.refresh();
  }

  void setSelectedTab(int index) {
    selectedTab.value = index;
  }

  void setPlannedSurvey(bool value) {
    plannedSurvey.value = value;
    scheduleAutosave();
  }

  void calculateSurvey() {
    _recalculateAllRows();
    scheduleAutosave();
  }

  void setAnnotationEnabled(bool value) {
    annotationEnabled.value = value;
    annotations.refresh();
    scheduleAutosave();
  }

  void setProjectAziEnabled(bool value) {
    projectAziEnabled.value = value;
    _recalculateAllRows();
    scheduleAutosave();
  }

  void updateProjectAzi(String value) {
    projectAzi.value = value;
    _recalculateAllRows();
    scheduleAutosave();
  }

  void selectStation(int index) {
    selectedStationIndex.value = index;
  }

  void selectAnnotation(int index) {
    selectedAnnotationIndex.value = index;
  }

  void updateStationField(int index, String field, String value) {
    if (index < 0 || index >= stations.length) return;
    final row = stations[index];
    switch (field) {
      case 'md':
        row.md = value;
        break;
      case 'inc':
        row.inc = value;
        break;
      case 'azi':
        row.azi = value;
        break;
      default:
        return;
    }
    _recalculateAllRows();
    scheduleAutosave();
  }

  void pasteStationTriples(int startIndex, List<List<String>> rows) {
    if (isLocked || rows.isEmpty) return;
    final safeStart = startIndex < 0 ? 0 : startIndex;
    while (stations.length < safeStart + rows.length) {
      stations.add(SurveyStationRow.blank());
    }

    for (var rowOffset = 0; rowOffset < rows.length; rowOffset++) {
      final values = rows[rowOffset];
      if (values.isEmpty) continue;
      final station = stations[safeStart + rowOffset];
      if (values.isNotEmpty) station.md = values[0];
      if (values.length > 1) station.inc = values[1];
      if (values.length > 2) station.azi = values[2];
      station.syncEditableControllers();
    }

    selectedStationIndex.value = safeStart;
    _padStations();
    stations.refresh();
    scheduleAutosave();
  }

  void updateAnnotationField(int index, String field, String value) {
    if (index < 0 || index >= annotations.length) return;
    final row = annotations[index];
    switch (field) {
      case 'md':
        row.md = value;
        break;
      case 'annotation':
        row.annotation = value;
        break;
      default:
        return;
    }
    annotations.refresh();
    scheduleAutosave();
  }

  void setAnnotationSymbol(int index, String symbol) {
    if (index < 0 || index >= annotations.length || isLocked) return;
    annotations[index].symbol = symbol;
    annotations.refresh();
    scheduleAutosave();
  }

  void cycleAnnotationSymbol(int index) {
    if (index < 0 || index >= annotations.length || isLocked) return;
    final current = annotations[index].symbol.trim();
    final nextIndex =
        (annotationSymbols.indexOf(current) + 1) % annotationSymbols.length;
    annotations[index].symbol = annotationSymbols[nextIndex];
    annotations.refresh();
    scheduleAutosave();
  }

  void insertStationAfter(int index) {
    final safeIndex = index < 0 ? stations.length - 1 : index;
    stations.insert(safeIndex + 1, SurveyStationRow.blank());
    _padStations();
    stations.refresh();
    selectedStationIndex.value = safeIndex + 1;
    scheduleAutosave();
  }

  void copySelectedStation() {
    if (!hasStationSelection) return;
    _stationClipboard = stations[selectedStationIndex.value].clone();
  }

  void cutSelectedStation() {
    if (!hasStationSelection || isLocked) return;
    _stationClipboard = stations[selectedStationIndex.value].clone();
    deleteSelectedStation();
  }

  void pasteStationIntoSelected() {
    if (!hasStationSelection || _stationClipboard == null || isLocked) return;
    stations[selectedStationIndex.value].dispose();
    stations[selectedStationIndex.value] = _stationClipboard!.clone();
    _recalculateAllRows();
    scheduleAutosave();
  }

  void deleteSelectedStation() {
    if (!hasStationSelection || isLocked) return;
    final row = stations.removeAt(selectedStationIndex.value);
    row.dispose();
    _padStations();
    if (selectedStationIndex.value >= stations.length) {
      selectedStationIndex.value = stations.length - 1;
    }
    _recalculateAllRows();
    scheduleAutosave();
  }

  void moveSelectedStationUp() {
    if (!hasStationSelection || isLocked || selectedStationIndex.value <= 0) {
      return;
    }
    final index = selectedStationIndex.value;
    final row = stations.removeAt(index);
    stations.insert(index - 1, row);
    selectedStationIndex.value = index - 1;
    _recalculateAllRows();
    scheduleAutosave();
  }

  void moveSelectedStationDown() {
    if (!hasStationSelection ||
        isLocked ||
        selectedStationIndex.value >= stations.length - 1) {
      return;
    }
    final index = selectedStationIndex.value;
    final row = stations.removeAt(index);
    stations.insert(index + 1, row);
    selectedStationIndex.value = index + 1;
    _recalculateAllRows();
    scheduleAutosave();
  }

  void moveSelectedStationToTop() {
    if (!hasStationSelection || isLocked || selectedStationIndex.value <= 0) {
      return;
    }
    final row = stations.removeAt(selectedStationIndex.value);
    stations.insert(0, row);
    selectedStationIndex.value = 0;
    _recalculateAllRows();
    scheduleAutosave();
  }

  void moveSelectedStationToBottom() {
    if (!hasStationSelection ||
        isLocked ||
        selectedStationIndex.value >= stations.length - 1) {
      return;
    }
    final row = stations.removeAt(selectedStationIndex.value);
    stations.add(row);
    _padStations();
    selectedStationIndex.value = stations.length - 1;
    _recalculateAllRows();
    scheduleAutosave();
  }

  void removeEmptyRows() {
    if (isLocked) return;
    final compact = stations
        .where((row) => row.hasAnyData)
        .map((e) => e.clone())
        .toList();
    _replaceStations(compact);
    _recalculateAllRows();
    scheduleAutosave();
  }

  void adjustAziAngle(double delta) {
    if (isLocked) return;
    for (final row in stations) {
      if (!row.hasEditableData || row.azi.trim().isEmpty) continue;
      final current = _toDouble(row.azi);
      var adjusted = current + delta;
      while (adjusted < 0) {
        adjusted += 360;
      }
      while (adjusted >= 360) {
        adjusted -= 360;
      }
      row.azi = adjusted.toStringAsFixed(2);
      row.syncEditableControllers();
    }
    _recalculateAllRows();
    scheduleAutosave();
  }

  void importSurveyRows(List<SurveyStationRow> importedRows) {
    if (isLocked) return;
    final next = importedRows.map((row) => row.clone()).toList();
    _replaceStations(next);
    stations.refresh();
    scheduleAutosave();
  }

  void insertAnnotationAfter(int index) {
    final safeIndex = index < 0 ? annotations.length - 1 : index;
    annotations.insert(safeIndex + 1, SurveyAnnotationRow.blank());
    _padAnnotations();
    annotations.refresh();
    selectedAnnotationIndex.value = safeIndex + 1;
    scheduleAutosave();
  }

  void copySelectedAnnotation() {
    if (!hasAnnotationSelection) return;
    _annotationClipboard = annotations[selectedAnnotationIndex.value].clone();
  }

  void cutSelectedAnnotation() {
    if (!hasAnnotationSelection || isLocked) return;
    _annotationClipboard = annotations[selectedAnnotationIndex.value].clone();
    deleteSelectedAnnotation();
  }

  void pasteAnnotationIntoSelected() {
    if (!hasAnnotationSelection || _annotationClipboard == null || isLocked) {
      return;
    }
    annotations[selectedAnnotationIndex.value].dispose();
    annotations[selectedAnnotationIndex.value] = _annotationClipboard!.clone();
    annotations.refresh();
    scheduleAutosave();
  }

  void deleteSelectedAnnotation() {
    if (!hasAnnotationSelection || isLocked) return;
    final row = annotations.removeAt(selectedAnnotationIndex.value);
    row.dispose();
    _padAnnotations();
    if (selectedAnnotationIndex.value >= annotations.length) {
      selectedAnnotationIndex.value = annotations.length - 1;
    }
    annotations.refresh();
    scheduleAutosave();
  }

  void moveSelectedAnnotationToTop() {
    if (!hasAnnotationSelection ||
        isLocked ||
        selectedAnnotationIndex.value <= 0) {
      return;
    }
    final row = annotations.removeAt(selectedAnnotationIndex.value);
    annotations.insert(0, row);
    selectedAnnotationIndex.value = 0;
    annotations.refresh();
    scheduleAutosave();
  }

  void moveSelectedAnnotationToBottom() {
    if (!hasAnnotationSelection ||
        isLocked ||
        selectedAnnotationIndex.value >= annotations.length - 1) {
      return;
    }
    final row = annotations.removeAt(selectedAnnotationIndex.value);
    annotations.add(row);
    _padAnnotations();
    selectedAnnotationIndex.value = annotations.length - 1;
    annotations.refresh();
    scheduleAutosave();
  }

  List<SurveyPlotPoint> get plotPoints {
    final points = <SurveyPlotPoint>[];
    for (final row in stations) {
      if (!row.hasEditableData) continue;
      final md = _toDouble(row.md);
      final inc = _toDouble(row.inc);
      final azi = _toDouble(row.azi);
      final tvd = _toDouble(row.tvd);
      final vsec = _toDouble(row.vsec);
      final north = _toDouble(row.northSouth);
      final east = _toDouble(row.eastWest);
      final dogleg = _toDouble(row.dogleg);
      if (md.isNaN || inc.isNaN || azi.isNaN) continue;
      points.add(
        SurveyPlotPoint(
          md: md,
          inc: inc,
          azi: azi,
          tvd: tvd,
          vsec: vsec,
          northSouth: north,
          eastWest: east,
          dogleg: dogleg,
        ),
      );
    }
    return points;
  }

  List<SurveyAnnotationMarker> get annotationMarkers {
    if (!annotationEnabled.value) return const [];
    final markers = <SurveyAnnotationMarker>[];
    for (final row in annotations) {
      final md = _toDouble(row.md);
      if (md < 0 ||
          row.annotation.trim().isEmpty ||
          row.symbol.trim().isEmpty) {
        continue;
      }
      markers.add(
        SurveyAnnotationMarker(
          md: md,
          label: row.annotation.trim(),
          symbol: row.symbol.trim(),
        ),
      );
    }
    return markers;
  }

  void rotateLeft() => rotationY.value -= 0.12;
  void rotateRight() => rotationY.value += 0.12;
  void rotateUp() => rotationX.value -= 0.12;
  void rotateDown() => rotationX.value += 0.12;
  void zoomIn() => zoom.value = math.min(2.2, zoom.value + 0.1);
  void zoomOut() => zoom.value = math.max(0.5, zoom.value - 0.1);
  void reset3DView() {
    rotationX.value = -0.55;
    rotationY.value = 0.75;
    zoom.value = 1.0;
  }

  SurveyPlotPoint? pointForAnnotationMd(double md) {
    const tolerance = 0.05;
    SurveyPlotPoint? match;
    double? smallest;
    for (final point in plotPoints) {
      final delta = (point.md - md).abs();
      if (delta <= tolerance && (smallest == null || delta < smallest)) {
        smallest = delta;
        match = point;
      }
    }
    return match;
  }

  SurveyPlotPoint pointAtMd(double md) {
    final points = plotPoints;
    if (points.isEmpty) {
      return const SurveyPlotPoint(
        md: 0,
        inc: 0,
        azi: 0,
        tvd: 0,
        vsec: 0,
        northSouth: 0,
        eastWest: 0,
        dogleg: 0,
      );
    }
    if (md <= points.first.md) return points.first;
    if (md >= points.last.md) return points.last;

    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      if (md <= current.md) {
        final span = current.md - previous.md;
        final t = span <= 0 ? 0.0 : (md - previous.md) / span;
        return SurveyPlotPoint(
          md: md,
          inc: _lerp(previous.inc, current.inc, t),
          azi: _lerp(previous.azi, current.azi, t),
          tvd: _lerp(previous.tvd, current.tvd, t),
          vsec: _lerp(previous.vsec, current.vsec, t),
          northSouth: _lerp(previous.northSouth, current.northSouth, t),
          eastWest: _lerp(previous.eastWest, current.eastWest, t),
          dogleg: _lerp(previous.dogleg, current.dogleg, t),
        );
      }
    }
    return points.last;
  }

  void _replaceStations(List<SurveyStationRow> next) {
    for (final row in stations) {
      row.dispose();
    }
    stations.assignAll(next);
    _padStations();
    selectedStationIndex.value = -1;
  }

  void _replaceAnnotations(List<SurveyAnnotationRow> next) {
    for (final row in annotations) {
      row.dispose();
    }
    annotations.assignAll(next);
    _padAnnotations();
    selectedAnnotationIndex.value = -1;
  }

  void _padStations() {
    while (stations.length < stationMinimumRows) {
      stations.add(SurveyStationRow.blank());
    }
  }

  void _padAnnotations() {
    while (annotations.length < annotationMinimumRows) {
      annotations.add(SurveyAnnotationRow.blank());
    }
  }

  List<SurveyStationRow> _trimmedStations() {
    final next = stations.map((row) => row.clone()).toList();
    while (next.isNotEmpty && !next.last.hasAnyData) {
      next.removeLast();
    }
    return next;
  }

  List<SurveyAnnotationRow> _trimmedAnnotations() {
    final next = annotations.map((row) => row.clone()).toList();
    while (next.isNotEmpty && !next.last.hasData) {
      next.removeLast();
    }
    return next;
  }

  void _recalculateAllRows() {
    SurveyStationRow? previous;
    double cumulativeTvd = 0;
    double cumulativeNorth = 0;
    double cumulativeEast = 0;
    final validRows = <SurveyStationRow>[];

    for (final row in stations) {
      row.syncEditableControllers();
      row.tvd = '';
      row.vsec = '';
      row.northSouth = '';
      row.eastWest = '';
      row.dogleg = '';

      if (!row.hasEditableData) {
        previous = null;
        cumulativeTvd = 0;
        cumulativeNorth = 0;
        cumulativeEast = 0;
        continue;
      }

      validRows.add(row);

      final md = _toDouble(row.md);
      final incDeg = _toDouble(row.inc);
      final aziDeg = _toDouble(row.azi);

      if (previous == null) {
        row.tvd = _format(md >= 0 ? 0 : 0, 1);
        row.northSouth = _format(0, 1);
        row.eastWest = _format(0, 1);
        row.vsec = _format(0, 1);
        previous = row;
        continue;
      }

      final previousMd = _toDouble(previous.md);
      final previousInc = _degreesToRadians(_toDouble(previous.inc));
      final previousAzi = _degreesToRadians(_toDouble(previous.azi));
      final currentInc = _degreesToRadians(incDeg);
      final currentAzi = _degreesToRadians(aziDeg);
      final deltaMd = md - previousMd;

      if (deltaMd <= 0) {
        row.tvd = previous.tvd;
        row.northSouth = previous.northSouth;
        row.eastWest = previous.eastWest;
        row.vsec = previous.vsec;
        row.dogleg = previous.dogleg;
        previous = row;
        continue;
      }

      final cosDogleg =
          (math.cos(previousInc) * math.cos(currentInc)) +
          (math.sin(previousInc) *
              math.sin(currentInc) *
              math.cos(currentAzi - previousAzi));
      final doglegRadians = math.acos(cosDogleg.clamp(-1.0, 1.0));
      final ratioFactor = doglegRadians.abs() < 1e-9
          ? 1.0
          : (2 / doglegRadians) * math.tan(doglegRadians / 2);
      final deltaTvd =
          (deltaMd / 2) *
          (math.cos(previousInc) + math.cos(currentInc)) *
          ratioFactor;
      final deltaNorth =
          (deltaMd / 2) *
          ((math.sin(previousInc) * math.cos(previousAzi)) +
              (math.sin(currentInc) * math.cos(currentAzi))) *
          ratioFactor;
      final deltaEast =
          (deltaMd / 2) *
          ((math.sin(previousInc) * math.sin(previousAzi)) +
              (math.sin(currentInc) * math.sin(currentAzi))) *
          ratioFactor;

      cumulativeTvd += deltaTvd;
      cumulativeNorth += deltaNorth;
      cumulativeEast += deltaEast;

      final doglegInterval = AppUnits.dogleg.contains('30m') ? 30.0 : 100.0;
      final doglegSeverity =
          (doglegRadians * 180 / math.pi) * doglegInterval / deltaMd;

      row.tvd = _format(cumulativeTvd, 1);
      row.northSouth = _format(cumulativeNorth, 1);
      row.eastWest = _format(cumulativeEast, 1);
      row.vsec = _format(
        _calculateVerticalSection(cumulativeNorth, cumulativeEast),
        1,
      );
      row.dogleg = _format(doglegSeverity, 2);
      previous = row;
    }

    if (validRows.length > 1 && validRows.first.dogleg.trim().isEmpty) {
      validRows.first.dogleg = validRows[1].dogleg;
    }

    stations.refresh();
  }

  double _calculateVerticalSection(double north, double east) {
    if (!projectAziEnabled.value) {
      return math.sqrt((north * north) + (east * east));
    }
    final project = _degreesToRadians(_toDouble(projectAzi.value));
    return (north * math.cos(project)) + (east * math.sin(project));
  }

  double _toDouble(String value) => double.tryParse(value.trim()) ?? 0.0;

  double _degreesToRadians(double value) => value * math.pi / 180;

  double _lerp(double a, double b, double t) => a + ((b - a) * t);

  String _format(double value, int digits) => value.toStringAsFixed(digits);

  SurveyStationRow _displayStationRow(SurveyStationRow row) {
    return SurveyStationRow(
      md: _convertText(row.md, '(ft)', AppUnits.length),
      inc: row.inc,
      azi: row.azi,
      tvd: _convertText(row.tvd, '(ft)', AppUnits.length),
      vsec: _convertText(row.vsec, '(ft)', AppUnits.length),
      northSouth: _convertText(row.northSouth, '(ft)', AppUnits.length),
      eastWest: _convertText(row.eastWest, '(ft)', AppUnits.length),
      dogleg: _convertText(row.dogleg, '(°/100ft)', AppUnits.dogleg),
    );
  }

  SurveyAnnotationRow _displayAnnotationRow(SurveyAnnotationRow row) {
    return SurveyAnnotationRow(
      md: _convertText(row.md, '(ft)', AppUnits.length),
      annotation: row.annotation,
      symbol: row.symbol,
    );
  }

  Map<String, dynamic> _stationBaseJson(SurveyStationRow row) => {
    'md': _convertText(row.md, AppUnits.length, '(ft)').trim(),
    'inc': row.inc.trim(),
    'azi': row.azi.trim(),
    'tvd': _convertText(row.tvd, AppUnits.length, '(ft)').trim(),
    'vsec': _convertText(row.vsec, AppUnits.length, '(ft)').trim(),
    'northSouth': _convertText(row.northSouth, AppUnits.length, '(ft)').trim(),
    'eastWest': _convertText(row.eastWest, AppUnits.length, '(ft)').trim(),
    'dogleg': _convertText(row.dogleg, AppUnits.dogleg, '(°/100ft)').trim(),
  };

  Map<String, dynamic> _annotationBaseJson(SurveyAnnotationRow row) => {
    'md': _convertText(row.md, AppUnits.length, '(ft)').trim(),
    'annotation': row.annotation.trim(),
    'symbol': row.symbol.trim(),
  };

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
}
