import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
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
  }) : description = TextEditingController(text: desc),
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
  String currentWellId = currentBackendWellId;
  Worker? _wellWorker;
  Worker? _reportWorker;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String? get _currentReportId {
    final reportId = reportContext.selectedReportId.value.trim();
    return reportId.isEmpty ? null : reportId;
  }

  String? get _currentReportNo {
    final reportNo = reportContext.selectedReportNumber.trim();
    return reportNo.isEmpty ? null : reportNo;
  }

  @override
  void onInit() {
    super.onInit();
    _initEmptyRows();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (wellId) {
      currentWellId = wellId.trim();
      fetchDrillStrings();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      fetchDrillStrings();
    });
    currentWellId = currentBackendWellId;
    fetchDrillStrings();
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
      final hasContent =
          last.description.text.isNotEmpty ||
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
  }

  void addEmptyRow() {
    final entry = DrillStringEntry();
    _attachListeners(entry);
    entries.add(entry);
  }

  // ─── API: FETCH ───────────────────────────────
  Future<void> fetchDrillStrings() async {
    if (currentWellId.isEmpty) {
      _resetRows();
      return;
    }

    isLoading.value = true;
    try {
      final uri = Uri.parse('${baseUrl}drill-string').replace(
        queryParameters: {
          'wellId': currentWellId,
          if (_currentReportId != null) 'reportId': _currentReportId!,
        },
      );
      final response = await http.get(uri, headers: _headers);
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
      _resetRows();
    } finally {
      isLoading.value = false;
    }
  }

  // ─── API: ADD ROW ─────────────────────────────
  Future<void> saveRow(int rowIndex) async {
    final entry = entries[rowIndex];
    if (entry.description.text.isEmpty) return;
    if (currentWellId.isEmpty) return;
    isSaving.value = true;
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}drill-string'),
        headers: _headers,
        body: jsonEncode(_payloadFor(entry)),
      );
      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final newId = json['data']['_id'];
        // Rebuild entry with id
        final updated = DrillStringEntry(
          id: newId,
          desc: entry.description.text,
          odVal: entry.od.text,
          wt: entry.weightPpf.text,
          idVal: entry.idCtrl.text,
          gr: entry.grade.text,
          len: entry.length.text,
        );
        _attachListeners(updated);
        entry.dispose();
        entries[rowIndex] = updated;
        entries.refresh();
      }
    } catch (e) {
      print('DrillString save error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ─── API: SAVE ALL unsaved rows ───────────────
  Future<Map<String, dynamic>> saveAll() async {
    final unsaved = entries
        .asMap()
        .entries
        .where((e) => e.value.id == null && e.value.description.text.isNotEmpty)
        .toList();
    if (unsaved.isEmpty) {
      return {'success': true, 'message': 'No new Drill String rows to save'};
    }
    if (currentWellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    isSaving.value = true;
    int successCount = 0;
    try {
      for (final entry in unsaved) {
        final rowIndex = entry.key;
        final e = entry.value;
        final response = await http.post(
          Uri.parse('${baseUrl}drill-string'),
          headers: _headers,
          body: jsonEncode(_payloadFor(e)),
        );
        if (response.statusCode == 201) {
          successCount++;
          final json = jsonDecode(response.body);
          final newId = json['data']['_id'];
          final updated = DrillStringEntry(
            id: newId,
            desc: e.description.text,
            odVal: e.od.text,
            wt: e.weightPpf.text,
            idVal: e.idCtrl.text,
            gr: e.grade.text,
            len: e.length.text,
          );
          _attachListeners(updated);
          e.dispose();
          entries[rowIndex] = updated;
        }
      }
      entries.refresh();
      _recalcTotal();
      return {
        'success': true,
        'message': '$successCount Drill String rows saved successfully',
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
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final e in entries) {
      e.dispose();
    }
    super.onClose();
  }

  void _resetRows() {
    for (final e in entries) {
      e.dispose();
    }
    entries.clear();
    _initEmptyRows();
    totalLength.value = 0;
    entries.refresh();
  }

  Map<String, dynamic> _payloadFor(DrillStringEntry entry) => {
    ...entry.toJson(),
    'wellId': currentWellId,
    if (_currentReportId != null) 'reportId': _currentReportId,
    if (_currentReportNo != null) 'reportNo': _currentReportNo,
  };
}
