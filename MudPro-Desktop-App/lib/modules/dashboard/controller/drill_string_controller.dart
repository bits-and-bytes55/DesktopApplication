import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class DrillStringEntry {
  final String? id;
  TextEditingController description;
  TextEditingController od;
  TextEditingController weightPpf;
  TextEditingController idCtrl;
  TextEditingController grade;
  TextEditingController length;

  DrillStringEntry({
    this.id,
    String desc = '',
    String odVal = '',
    String wt = '',
    String idVal = '',
    String gr = '',
    String len = '',
  })  : description = TextEditingController(text: desc),
        od = TextEditingController(text: odVal),
        weightPpf = TextEditingController(text: wt),
        idCtrl = TextEditingController(text: idVal),
        grade = TextEditingController(text: gr),
        length = TextEditingController(text: len);

  void dispose() {
    description.dispose();
    od.dispose();
    weightPpf.dispose();
    idCtrl.dispose();
    grade.dispose();
    length.dispose();
  }

  bool get hasContent =>
      description.text.trim().isNotEmpty ||
      od.text.trim().isNotEmpty ||
      weightPpf.text.trim().isNotEmpty ||
      idCtrl.text.trim().isNotEmpty ||
      grade.text.trim().isNotEmpty ||
      length.text.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'description': description.text,
        'od': double.tryParse(od.text) ?? 0,
        'weightPpf': double.tryParse(weightPpf.text) ?? 0,
        'id': double.tryParse(idCtrl.text) ?? 0,
        'grade': grade.text,
        'length': double.tryParse(length.text) ?? 0,
      };
}

class DrillStringController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;

  var entries = <DrillStringEntry>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  var totalLength = 0.0.obs;
  final List<Worker> _unitWorkers = <Worker>[];
  Timer? _autoSaveTimer;
  bool _isApplyingState = false;
  late String _lengthUnit;
  late String _diameterUnit;
  late String _lineDensityUnit;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri _buildScopedUri(String path) {
    final queryParameters = <String, String>{};
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();

    if (wellId.isNotEmpty) {
      queryParameters['wellId'] = wellId;
    }
    if (reportId.isNotEmpty) {
      queryParameters['reportId'] = reportId;
    }

    return Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
  }

  Map<String, dynamic> _withScope(Map<String, dynamic> payload) {
    final body = Map<String, dynamic>.from(payload);
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();

    if (wellId.isNotEmpty) {
      body['wellId'] = wellId;
    }
    if (reportId.isNotEmpty) {
      body['reportId'] = reportId;
    }

    return body;
  }

  bool get _hasSavableRows => entries.any((entry) => entry.hasContent);

  void _scheduleAutoSave() {
    if (_isApplyingState || isLoading.value || !_hasSavableRows) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 850), () async {
      if (_isApplyingState || isLoading.value || !_hasSavableRows) return;
      if (isSaving.value) {
        _scheduleAutoSave();
        return;
      }
      await saveAll();
    });
  }

  @override
  void onInit() {
    super.onInit();
    _initEmptyRows();
    _lengthUnit = AppUnits.length;
    _diameterUnit = AppUnits.diameter;
    _lineDensityUnit = AppUnits.lineDensity;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
      ever<String>(padWellContext.selectedWellId, (_) => fetchDrillStrings()),
      ever<String>(reportContext.selectedReportId, (_) => fetchDrillStrings()),
    ]);
    fetchDrillStrings();
  }

  void _handleUnitChange() {
    final nextLengthUnit = AppUnits.length;
    final nextDiameterUnit = AppUnits.diameter;
    final nextLineDensityUnit = AppUnits.lineDensity;
    if (_lengthUnit == nextLengthUnit &&
        _diameterUnit == nextDiameterUnit &&
        _lineDensityUnit == nextLineDensityUnit) {
      return;
    }

    for (final entry in entries) {
      entry.od.text =
          _convertText(entry.od.text, _diameterUnit, nextDiameterUnit);
      entry.idCtrl.text =
          _convertText(entry.idCtrl.text, _diameterUnit, nextDiameterUnit);
      entry.weightPpf.text = _convertText(
        entry.weightPpf.text,
        _lineDensityUnit,
        nextLineDensityUnit,
      );
      entry.length.text =
          _convertText(entry.length.text, _lengthUnit, nextLengthUnit);
    }

    _lengthUnit = nextLengthUnit;
    _diameterUnit = nextDiameterUnit;
    _lineDensityUnit = nextLineDensityUnit;
    entries.refresh();
    _recalcTotal();
    _scheduleAutoSave();
  }

  String _convertText(String rawValue, String fromUnit, String toUnit) {
    if (rawValue.trim().isEmpty || fromUnit == toUnit) {
      return rawValue;
    }
    final parsed = double.tryParse(rawValue.replaceAll(',', ''));
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

  void _initEmptyRows() {
    for (int i = 0; i < 5; i++) {
      final entry = DrillStringEntry();
      _attachListeners(entry);
      entries.add(entry);
    }
  }

  void _attachListeners(DrillStringEntry entry) {
    entry.length.addListener(_recalcTotal);
    entry.description.addListener(_scheduleAutoSave);
    entry.od.addListener(_scheduleAutoSave);
    entry.weightPpf.addListener(_scheduleAutoSave);
    entry.idCtrl.addListener(_scheduleAutoSave);
    entry.grade.addListener(_scheduleAutoSave);
    entry.length.addListener(_scheduleAutoSave);
  }

  void _recalcTotal() {
    double sum = 0;
    for (final e in entries) {
      sum += double.tryParse(e.length.text) ?? 0;
    }
    totalLength.value = sum;
  }

  /// Auto-add a new empty row when last row has any content
  void onCellChanged(int rowIndex) {
    if (rowIndex == entries.length - 1) {
      final last = entries[rowIndex];
      final hasContent = last.description.text.isNotEmpty ||
          last.od.text.isNotEmpty ||
          last.weightPpf.text.isNotEmpty ||
          last.idCtrl.text.isNotEmpty ||
          last.grade.text.isNotEmpty ||
          last.length.text.isNotEmpty;
      if (hasContent) {
        addEmptyRow();
      }
    }
    _recalcTotal();
    _scheduleAutoSave();
  }

  void addEmptyRow() {
    final entry = DrillStringEntry();
    _attachListeners(entry);
    entries.add(entry);
  }

  // ─── API: FETCH ───────────────────────────────
  Future<void> fetchDrillStrings() async {
    _autoSaveTimer?.cancel();
    final wellId = currentBackendWellId.trim();
    if (wellId.isEmpty) {
      _isApplyingState = true;
      for (final e in entries) {
        e.dispose();
      }
      entries.clear();
      _initEmptyRows();
      totalLength.value = 0.0;
      _isApplyingState = false;
      return;
    }

    isLoading.value = true;
    _isApplyingState = true;
    try {
      final response = await http.get(
        _buildScopedUri('drill-string'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List items = json['data'] ?? [];

        // dispose old
        for (final e in entries) {
          e.dispose();
        }
        entries.clear();

        if (items.isEmpty) {
          _initEmptyRows();
        } else {
          for (final item in items) {
            final entry = DrillStringEntry(
              id: item['_id'],
              desc: item['description'] ?? '',
              odVal: (item['od'] ?? 0).toString(),
              wt: (item['weightPpf'] ?? 0).toString(),
              idVal: (item['id'] ?? 0).toString(),
              gr: item['grade'] ?? '',
              len: (item['length'] ?? 0).toString(),
            );
            _attachListeners(entry);
            entries.add(entry);
          }
          // Always ensure at least 5 rows visible
          while (entries.length < 5) {
            final e = DrillStringEntry();
            _attachListeners(e);
            entries.add(e);
          }
          // Add one empty row at end for input
          final e = DrillStringEntry();
          _attachListeners(e);
          entries.add(e);
        }

        totalLength.value = json['totalLength']?.toDouble() ?? 0.0;
      }
    } catch (e) {
      print('DrillString fetch error: $e');
    } finally {
      _isApplyingState = false;
      isLoading.value = false;
    }
  }

  // ─── API: ADD ROW ─────────────────────────────
  Future<void> saveRow(int rowIndex) async {
    _autoSaveTimer?.cancel();
    final entry = entries[rowIndex];
    if (!entry.hasContent) return;
    isSaving.value = true;
    try {
      await _saveEntry(rowIndex, entry);
      entries.refresh();
    } catch (e) {
      print('DrillString save error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ─── API: SAVE ALL unsaved rows ───────────────
  Future<bool> _saveEntry(int rowIndex, DrillStringEntry entry) async {
    final isUpdate = entry.id != null && entry.id!.isNotEmpty;
    final response = isUpdate
        ? await http.put(
            Uri.parse('${baseUrl}drill-string/${entry.id}'),
            headers: _headers,
            body: jsonEncode(_withScope(entry.toJson())),
          )
        : await http.post(
            Uri.parse('${baseUrl}drill-string'),
            headers: _headers,
            body: jsonEncode(_withScope(entry.toJson())),
          );

    if (response.statusCode != 200 && response.statusCode != 201) {
      return false;
    }

    final json = jsonDecode(response.body);
    final saved = json['data'];
    final savedId = (saved is Map ? saved['_id'] : null)?.toString();
    if (savedId == null || savedId.isEmpty) return true;

    final updated = DrillStringEntry(
      id: savedId,
      desc: entry.description.text,
      odVal: entry.od.text,
      wt: entry.weightPpf.text,
      idVal: entry.idCtrl.text,
      gr: entry.grade.text,
      len: entry.length.text,
    );
    _attachListeners(updated);
    entry.dispose();
    if (rowIndex >= 0 && rowIndex < entries.length) {
      entries[rowIndex] = updated;
    }
    return true;
  }

  Future<Map<String, dynamic>> saveAll() async {
    _autoSaveTimer?.cancel();
    final candidates =
        entries.asMap().entries.where((e) => e.value.hasContent).toList();
    if (candidates.isEmpty) {
      return {'success': true, 'message': 'No Drill String rows to save'};
    }
    isSaving.value = true;
    int successCount = 0;
    final errors = <String>[];
    try {
      for (final entry in candidates) {
        final rowIndex = entry.key;
        final saved = await _saveEntry(rowIndex, entry.value);
        if (saved) {
          successCount++;
        } else {
          errors.add('Row ${rowIndex + 1} failed');
        }
      }
      entries.refresh();
      _recalcTotal();
      return {
        'success': errors.isEmpty,
        'message': errors.isEmpty
            ? '$successCount Drill String rows saved successfully'
            : '$successCount saved, ${errors.length} failed',
        if (errors.isNotEmpty) 'errors': errors,
      };
    } catch (e) {
      print('DrillString saveAll error: $e');
      return {'success': false, 'message': 'Error saving Drill String: $e'};
    } finally {
      isSaving.value = false;
    }
  }

  // ─── API: DELETE ROW ──────────────────────────
  Future<void> deleteRow(int rowIndex) async {
    final entry = entries[rowIndex];
    if (entry.id != null) {
      try {
        await http.delete(
          Uri.parse('${baseUrl}drill-string/${entry.id}'),
          headers: _headers,
        );
      } catch (e) {
        print('DrillString delete error: $e');
      }
    }
    entry.dispose();
    entries.removeAt(rowIndex);
    if (entries.isEmpty) _initEmptyRows();
    _recalcTotal();
  }

  @override
  void onClose() {
    _autoSaveTimer?.cancel();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    for (final e in entries) {
      e.dispose();
    }
    super.onClose();
  }
}
