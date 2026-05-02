import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart'
    show kControllerWellId;
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class CasedHoleEntry {
  String? id;
  int sortOrder;
  TextEditingController description;
  TextEditingController od;
  TextEditingController wt;
  TextEditingController idCtrl;
  TextEditingController top;
  TextEditingController shoe;
  TextEditingController length;

  CasedHoleEntry({
    this.id,
    this.sortOrder = 0,
    String desc = '',
    String odVal = '',
    String wtVal = '',
    String idVal = '',
    String topVal = '',
    String shoeVal = '',
    String lenVal = '',
  }) : description = TextEditingController(text: desc),
       od = TextEditingController(text: odVal),
       wt = TextEditingController(text: wtVal),
       idCtrl = TextEditingController(text: idVal),
       top = TextEditingController(text: topVal),
       shoe = TextEditingController(text: shoeVal),
       length = TextEditingController(text: lenVal);

  void dispose() {
    description.dispose();
    od.dispose();
    wt.dispose();
    idCtrl.dispose();
    top.dispose();
    shoe.dispose();
    length.dispose();
  }

  bool get hasContent =>
      description.text.trim().isNotEmpty ||
      od.text.trim().isNotEmpty ||
      wt.text.trim().isNotEmpty ||
      idCtrl.text.trim().isNotEmpty ||
      top.text.trim().isNotEmpty ||
      shoe.text.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    if (id != null && id!.isNotEmpty) 'recordId': id,
    'sortOrder': sortOrder,
    'description': description.text,
    'od': od.text,
    'wt': wt.text,
    'id': idCtrl.text,
    'top': top.text,
    'shoe': shoe.text,
    'type': '',
    'bit': '',
    'toc': kCasedHoleTocMarker,
  };
}

class CasedHoleUIController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;
  final reportContext = Get.find<ReportContextController>();

  var entries = <CasedHoleEntry>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  Worker? _wellWorker;
  Worker? _reportWorker;
  final List<Worker> _unitWorkers = <Worker>[];
  Timer? _autoSaveTimer;
  bool _isApplyingState = false;
  late String _lengthUnit;
  late String _diameterUnit;
  late String _lineDensityUnit;

  Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

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
    ]);
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      fetchTableCasings();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      fetchTableCasings();
    });
  }

  @override
  void onClose() {
    _autoSaveTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    for (final e in entries) {
      e.dispose();
    }
    super.onClose();
  }

  bool get _hasSavableRows => entries.any(
    (entry) => entry.hasContent && entry.idCtrl.text.trim().isNotEmpty,
  );

  void _ensureMinimumRows() {
    while (entries.length < 6) {
      final entry = CasedHoleEntry(sortOrder: entries.length);
      _attachListeners(entry);
      entries.add(entry);
    }

    if (entries.isEmpty || entries.last.hasContent) {
      final entry = CasedHoleEntry(sortOrder: entries.length);
      _attachListeners(entry);
      entries.add(entry);
    }
  }

  void _reindexRows() {
    for (var i = 0; i < entries.length; i++) {
      entries[i].sortOrder = i;
    }
  }

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
      entry.od.text = _convertText(
        entry.od.text,
        _diameterUnit,
        nextDiameterUnit,
      );
      entry.wt.text = _convertText(
        entry.wt.text,
        _lineDensityUnit,
        nextLineDensityUnit,
      );
      entry.idCtrl.text = _convertText(
        entry.idCtrl.text,
        _diameterUnit,
        nextDiameterUnit,
      );
      entry.top.text = _convertText(
        entry.top.text,
        _lengthUnit,
        nextLengthUnit,
      );
      entry.shoe.text = _convertText(
        entry.shoe.text,
        _lengthUnit,
        nextLengthUnit,
      );
      recalcLength(entry);
    }
    entries.refresh();

    _lengthUnit = nextLengthUnit;
    _diameterUnit = nextDiameterUnit;
    _lineDensityUnit = nextLineDensityUnit;
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
    for (int i = 0; i < 6; i++) {
      final entry = CasedHoleEntry(sortOrder: entries.length);
      _attachListeners(entry);
      entries.add(entry);
    }
  }

  void _attachListeners(CasedHoleEntry entry) {
    entry.top.addListener(() => recalcLength(entry));
    entry.shoe.addListener(() => recalcLength(entry));
    entry.description.addListener(_scheduleAutoSave);
    entry.od.addListener(_scheduleAutoSave);
    entry.wt.addListener(_scheduleAutoSave);
    entry.idCtrl.addListener(_scheduleAutoSave);
    entry.top.addListener(_scheduleAutoSave);
    entry.shoe.addListener(_scheduleAutoSave);
  }

  void recalcLength(CasedHoleEntry e) {
    final topStr = e.top.text.trim().replaceAll(',', '');
    final shoeStr = e.shoe.text.trim().replaceAll(',', '');

    final t = double.tryParse(topStr);
    final s = double.tryParse(shoeStr);

    if (t != null && s != null) {
      final len = (s - t).abs();
      e.length.text = len.toStringAsFixed(1);
    } else {
      e.length.text = '';
    }
  }

  void checkAndAddRow(int rowIndex) {
    if (rowIndex == entries.length - 1) {
      final last = entries[rowIndex];
      final hasContent =
          last.description.text.isNotEmpty ||
          last.od.text.isNotEmpty ||
          last.wt.text.isNotEmpty ||
          last.idCtrl.text.isNotEmpty ||
          last.top.text.isNotEmpty ||
          last.shoe.text.isNotEmpty;
      if (hasContent) {
        final e = CasedHoleEntry(sortOrder: entries.length);
        _attachListeners(e);
        entries.add(e);
      }
    }
  }

  void addRowFromCasing(CasingRow casing) {
    final entry = CasedHoleEntry(
      sortOrder: entries.length,
      desc: casing.description.value,
      odVal: _convertText(casing.od.value, '(in)', _diameterUnit),
      wtVal: _convertText(casing.wt.value, '(lb/ft)', _lineDensityUnit),
      idVal: _convertText(casing.id.value, '(in)', _diameterUnit),
      topVal: _convertText(casing.top.value, '(ft)', _lengthUnit),
      shoeVal: _convertText(casing.shoe.value, '(ft)', _lengthUnit),
    );

    final emptyIndex = entries.indexWhere(
      (e) =>
          e.description.text.isEmpty &&
          e.od.text.isEmpty &&
          e.wt.text.isEmpty &&
          e.idCtrl.text.isEmpty &&
          e.top.text.isEmpty &&
          e.shoe.text.isEmpty,
    );

    _attachListeners(entry);
    recalcLength(entry);

    if (emptyIndex != -1) {
      entries[emptyIndex].dispose();
      entries[emptyIndex] = entry;
    } else {
      entries.add(entry);
    }

    if (entries.last.hasContent) {
      final empty = CasedHoleEntry(sortOrder: entries.length);
      _attachListeners(empty);
      entries.add(empty);
    }
    _reindexRows();
    entries.refresh();
  }

  Future<void> fetchTableCasings() async {
    _autoSaveTimer?.cancel();
    if (kControllerWellId.isEmpty) return;
    isLoading.value = true;
    _isApplyingState = true;
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}casing/$kControllerWellId').replace(
          queryParameters: {
            if (reportContext.selectedReportId.value.isNotEmpty)
              'reportId': reportContext.selectedReportId.value,
          },
        ),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];

        for (final e in entries) {
          e.dispose();
        }
        entries.clear();
        for (final item in data) {
          if (item['wellId'] != kControllerWellId) continue;
          if ((item['toc'] ?? '').toString() != kCasedHoleTocMarker) continue;

          final entry = CasedHoleEntry(
            id: item['_id'],
            sortOrder: (item['sortOrder'] as num?)?.toInt() ?? entries.length,
            desc: item['description']?.toString() ?? '',
            odVal: item['od']?.toString() ?? '',
            wtVal: item['wt']?.toString() ?? '',
            idVal: item['id']?.toString() ?? '',
            topVal: item['top']?.toString() ?? '',
            shoeVal: item['shoe']?.toString() ?? '',
          );
          final t = double.tryParse(entry.top.text);
          final s = double.tryParse(entry.shoe.text);
          if (t != null && s != null) {
            entry.length.text = (s - t).toStringAsFixed(1);
          }

          _attachListeners(entry);
          entries.add(entry);
        }
        if (entries.isEmpty) _initEmptyRows();
        _ensureMinimumRows();
        _reindexRows();
      }
    } catch (e) {
      print('CasedHole fetch error: $e');
    } finally {
      _isApplyingState = false;
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> saveAll() async {
    _autoSaveTimer?.cancel();
    if (kControllerWellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    isSaving.value = true;
    final List<String> errors = [];
    int successCount = 0;
    try {
      final authRepo = AuthRepository();
      final List<CasedHoleEntry> allRows = entries
          .where((e) => e.hasContent && e.idCtrl.text.trim().isNotEmpty)
          .toList();
      _reindexRows();

      for (final entry in allRows) {
        final payload = entry.toJson();
        payload['wellId'] = kControllerWellId;
        if (reportContext.selectedReportId.value.isNotEmpty) {
          payload['reportId'] = reportContext.selectedReportId.value;
        }

        final result = await authRepo.saveCasing(payload);

        if (result['success'] == true) {
          successCount++;
          final data = result['data']?['data'];
          if (data != null && (entry.id == null || entry.id!.isEmpty)) {
            final newId = data['_id'];
            if (newId != null) {
              entry.id = newId.toString();
            }
          }
        } else {
          final rowLabel = entry.description.text.trim().isNotEmpty
              ? entry.description.text.trim()
              : 'ID ${entry.idCtrl.text.trim()}';
          errors.add('Failed to save row $rowLabel: ${result['message']}');
        }
      }

      _ensureMinimumRows();

      if (errors.isEmpty) {
        return {
          'success': true,
          'message': 'Casing data saved successfully ($successCount items)',
        };
      } else {
        return {
          'success': successCount > 0,
          'message': 'Casing: $successCount saved, ${errors.length} failed',
          'errors': errors,
        };
      }
    } catch (e) {
      print('CasedHole saveAll error: $e');
      return {'success': false, 'message': 'Error saving casing: $e'};
    } finally {
      isSaving.value = false;
    }
  }

  List<String> copyRow(int rowIndex) {
    final entry = entries[rowIndex];
    return [
      entry.description.text,
      entry.od.text,
      entry.wt.text,
      entry.idCtrl.text,
      entry.top.text,
      entry.shoe.text,
    ];
  }

  void pasteRow(int rowIndex, List<String> values) {
    while (entries.length <= rowIndex) {
      final entry = CasedHoleEntry(sortOrder: entries.length);
      _attachListeners(entry);
      entries.add(entry);
    }

    final entry = entries[rowIndex];
    final data = List<String>.from(values);
    while (data.length < 6) {
      data.add('');
    }

    entry.description.text = data[0];
    entry.od.text = data[1];
    entry.wt.text = data[2];
    entry.idCtrl.text = data[3];
    entry.top.text = data[4];
    entry.shoe.text = data[5];
    recalcLength(entry);
    checkAndAddRow(rowIndex);
    _reindexRows();
    entries.refresh();
    _scheduleAutoSave();
  }

  void clearRow(int rowIndex) {
    final entry = entries[rowIndex];
    entry.description.clear();
    entry.od.clear();
    entry.wt.clear();
    entry.idCtrl.clear();
    entry.top.clear();
    entry.shoe.clear();
    entry.length.clear();
    _ensureMinimumRows();
    entries.refresh();
    _scheduleAutoSave();
  }

  Future<void> deleteRow(int rowIndex) async {
    if (rowIndex < 0 || rowIndex >= entries.length) return;
    final entry = entries[rowIndex];
    final rowId = entry.id;
    if (rowId != null && rowId.isNotEmpty && kControllerWellId.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('${baseUrl}casing/$kControllerWellId/$rowId').replace(
            queryParameters: {
              if (reportContext.selectedReportId.value.isNotEmpty)
                'reportId': reportContext.selectedReportId.value,
            },
          ),
          headers: _headers,
        );
      } catch (e) {
        print('CasedHole delete error: $e');
      }
    }

    entry.dispose();
    entries.removeAt(rowIndex);
    _ensureMinimumRows();
    _reindexRows();
    entries.refresh();
    _scheduleAutoSave();
  }

  void moveRowToTop(int rowIndex) {
    if (rowIndex <= 0 || rowIndex >= entries.length) return;
    final entry = entries.removeAt(rowIndex);
    entries.insert(0, entry);
    _ensureMinimumRows();
    _reindexRows();
    entries.refresh();
    _scheduleAutoSave();
  }

  void moveRowToBottom(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= entries.length) return;
    final entry = entries.removeAt(rowIndex);
    final targetIndex = entries.isNotEmpty && !entries.last.hasContent
        ? entries.length - 1
        : entries.length;
    entries.insert(targetIndex.clamp(0, entries.length), entry);
    _ensureMinimumRows();
    _reindexRows();
    entries.refresh();
    _scheduleAutoSave();
  }
}
