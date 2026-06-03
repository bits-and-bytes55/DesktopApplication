import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class MudLossStorageEntry {
  MudLossStorageEntry({
    String id = '',
    String storage = '',
    String dump = '',
    String evaporation = '',
    String pitCleaning = '',
  }) : id = id.obs,
       storage = storage.obs,
       dump = dump.obs,
       evaporation = evaporation.obs,
       pitCleaning = pitCleaning.obs,
       dumpController = TextEditingController(text: dump),
       evaporationController = TextEditingController(text: evaporation),
       pitCleaningController = TextEditingController(text: pitCleaning);

  final RxString id;
  final RxString storage;
  final RxString dump;
  final RxString evaporation;
  final RxString pitCleaning;
  final TextEditingController dumpController;
  final TextEditingController evaporationController;
  final TextEditingController pitCleaningController;

  bool get hasAnyData =>
      storage.value.trim().isNotEmpty ||
      dump.value.trim().isNotEmpty ||
      evaporation.value.trim().isNotEmpty ||
      pitCleaning.value.trim().isNotEmpty;

  bool get hasAnyVolumeInput =>
      dump.value.trim().isNotEmpty ||
      evaporation.value.trim().isNotEmpty ||
      pitCleaning.value.trim().isNotEmpty;

  bool get isValidForSave {
    final dumpValue = _parseNumber(dump.value);
    final evaporationValue = _parseNumber(evaporation.value);
    final pitCleaningValue = _parseNumber(pitCleaning.value);
    return storage.value.trim().isNotEmpty &&
        (dumpValue > 0 || evaporationValue > 0 || pitCleaningValue > 0);
  }

  Map<String, dynamic> toBody() => {
    'storage': storage.value.trim(),
    'dump': _parseNumber(dump.value),
    'evaporation': _parseNumber(evaporation.value),
    'pitCleaning': _parseNumber(pitCleaning.value),
  };

  static double _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0;

  static String formatVolume(dynamic value) {
    final parsed = _parseNumber(value?.toString() ?? '');
    if (parsed == 0 && (value == null || value.toString().trim().isEmpty)) {
      return '';
    }
    return parsed
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void dispose() {
    dumpController.dispose();
    evaporationController.dispose();
    pitCleaningController.dispose();
  }
}

class MudLossStorageController extends GetxController {
  MudLossStorageController({required this.instanceKey});

  final String instanceKey;
  final AuthRepository _repository = AuthRepository();
  final rows = <MudLossStorageEntry>[].obs;
  final isLoading = false.obs;
  Timer? _autoSaveTimer;
  bool _isApplyingState = false;
  String _loadedWellId = '';
  String _loadedReportId = '';
  String _lastValidationMessage = '';
  DateTime? _lastValidationAt;
  final Map<String, double> _savedTotalsById = {};
  final Map<String, String> _savedStorageById = {};

  Worker? _wellWorker;
  Worker? _reportWorker;

  String get wellId => currentBackendWellId.trim();

  @override
  void onInit() {
    super.onInit();
    _ensureMinimumRows();
    load();
    _wellWorker = ever<String>(
      padWellContext.selectedWellId,
      (_) => load(force: true),
    );
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => load(force: true),
    );
  }

  @override
  void onClose() {
    _autoSaveTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final row in rows) {
      row.dispose();
    }
    super.onClose();
  }

  String _formatVolume(dynamic value) {
    return MudLossStorageEntry.formatVolume(value);
  }

  double _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0;

  double _rowTotal(MudLossStorageEntry row) {
    return _parseNumber(row.dump.value) +
        _parseNumber(row.evaporation.value) +
        _parseNumber(row.pitCleaning.value);
  }

  String _normalizedStorage(String value) => value.trim().toLowerCase();

  double _savedLossForStorage(String storage) {
    final normalized = _normalizedStorage(storage);
    var total = 0.0;
    for (final entry in _savedTotalsById.entries) {
      if (_normalizedStorage(_savedStorageById[entry.key] ?? '') ==
          normalized) {
        total += entry.value;
      }
    }
    return total;
  }

  double _storageAvailableVolume(String storage) {
    if (!Get.isRegistered<PitController>()) return 0;
    final pitCtrl = Get.find<PitController>();
    final normalized = _normalizedStorage(storage);
    if (normalized.isEmpty) return 0;

    final storageRows = pitCtrl.volumeNameData['storageTable'];
    if (storageRows is List) {
      for (final rawRow in storageRows) {
        if (rawRow is! Map) continue;
        final pitName = (rawRow['pitName'] ?? '').toString().trim();
        if (_normalizedStorage(pitName) != normalized) continue;
        final calculated = _parseNumber(
          (rawRow['calculatedVol'] ?? '').toString(),
        );
        final measured = _parseNumber((rawRow['measuredVol'] ?? '').toString());
        final base = calculated.abs() >= 0.005 ? calculated : measured;
        return base + _savedLossForStorage(storage);
      }
    }

    for (final pit in pitCtrl.unselectedPits) {
      if (_normalizedStorage(pit.pitName) == normalized) {
        return (pit.volume?.value ?? 0) + _savedLossForStorage(storage);
      }
    }
    return 0;
  }

  void _showValidationMessage(String message) {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return;

    final now = DateTime.now();
    if (_lastValidationMessage == cleanMessage &&
        _lastValidationAt != null &&
        now.difference(_lastValidationAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastValidationMessage = cleanMessage;
    _lastValidationAt = now;

    Get.snackbar(
      'Mud Loss - Storage',
      cleanMessage,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }

  void _rememberSavedRow(MudLossStorageEntry row) {
    final id = row.id.value.trim();
    if (id.isEmpty) return;
    _savedTotalsById[id] = _rowTotal(row);
    _savedStorageById[id] = row.storage.value.trim();
  }

  void _forgetSavedRow(String id) {
    _savedTotalsById.remove(id);
    _savedStorageById.remove(id);
  }

  Map<String, dynamic>? _extractEntity(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    if (value is Map && value['data'] is List && value['data'].isNotEmpty) {
      final first = value['data'].first;
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  bool _belongsToThisInstance(Map<String, dynamic> item) {
    final key = (item['operationInstanceKey'] ?? '').toString().trim();
    if (key == instanceKey) return true;
    return key.isEmpty && instanceKey == 'mudLossStorage::legacy0';
  }

  void _ensureMinimumRows() {
    while (rows.length < 20) {
      rows.add(MudLossStorageEntry());
    }
  }

  void ensureTrailingRow() {
    _ensureMinimumRows();
  }

  bool get _hasData => rows.any((row) => row.hasAnyData);

  void scheduleAutoSave() {
    if (_isApplyingState || isLoading.value || !_hasData) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 850), () async {
      if (_isApplyingState || isLoading.value || !_hasData) return;
      await save();
    });
  }

  Future<void> flushPendingAutoSave() async {
    if (!(_autoSaveTimer?.isActive ?? false)) return;
    _autoSaveTimer?.cancel();
    if (_isApplyingState || isLoading.value || !_hasData) return;
    await save();
  }

  Future<void> _refreshPitState() async {
    if (!Get.isRegistered<PitController>()) return;
    final pitCtrl = Get.find<PitController>();
    await pitCtrl.fetchAllPits();
    await pitCtrl.fetchSelectedPits();
    await pitCtrl.fetchUnselectedPits();
    await pitCtrl.fetchVolumeNameData();
  }

  void _disposeRows() {
    for (final row in rows) {
      row.dispose();
    }
    rows.assignAll([]);
  }

  void _resetRows() {
    _disposeRows();
    _savedTotalsById.clear();
    _savedStorageById.clear();
    _ensureMinimumRows();
  }

  void clearLocalState() {
    _autoSaveTimer?.cancel();
    _isApplyingState = true;
    _resetRows();
    _loadedWellId = wellId;
    _loadedReportId = reportContext.selectedReportId.value.trim();
    _isApplyingState = false;
  }

  Future<void> load({bool force = false}) async {
    final currentWellId = wellId;
    final currentReportId = reportContext.selectedReportId.value.trim();
    if (currentWellId.isEmpty) {
      _isApplyingState = true;
      _resetRows();
      _loadedWellId = '';
      _loadedReportId = '';
      _isApplyingState = false;
      return;
    }
    if (!force &&
        _loadedWellId == currentWellId &&
        _loadedReportId == currentReportId &&
        !isLoading.value) {
      return;
    }
    if ((_autoSaveTimer?.isActive ?? false) &&
        _loadedWellId == currentWellId &&
        _loadedReportId == currentReportId) {
      return;
    }
    _autoSaveTimer?.cancel();
    if (isLoading.value && !force) return;

    isLoading.value = true;
    _isApplyingState = true;
    try {
      final result = await _repository.getMudLossStorageList(wellId);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load Mud Loss Storage');
      }

      final envelope = result['data'];
      final data = envelope is Map<String, dynamic>
          ? envelope['data']
          : envelope is Map
          ? Map<String, dynamic>.from(envelope)['data']
          : null;
      final items = data is List
          ? data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .where(_belongsToThisInstance)
                .toList()
                .reversed
                .toList()
          : const [];

      _disposeRows();
      _savedTotalsById.clear();
      _savedStorageById.clear();
      for (final rawItem in items) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        final entry = MudLossStorageEntry(
          id: (item['_id'] ?? item['id'] ?? '').toString(),
          storage: (item['storage'] ?? '').toString(),
          dump: _formatVolume(item['dump']),
          evaporation: _formatVolume(item['evaporation']),
          pitCleaning: _formatVolume(item['pitCleaning']),
        );
        rows.add(entry);
        _rememberSavedRow(entry);
      }
      _ensureMinimumRows();
      ensureTrailingRow();
      _loadedWellId = currentWellId;
      _loadedReportId = currentReportId;
    } catch (_) {
      _resetRows();
      _loadedWellId = currentWellId;
      _loadedReportId = currentReportId;
    } finally {
      _isApplyingState = false;
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> save() async {
    _autoSaveTimer?.cancel();
    if (wellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }

    final existingRows = rows.where((row) => row.id.value.isNotEmpty).toList();
    final candidateRows = rows.where((row) => row.hasAnyData).toList();
    final filledRows = rows.where((row) => row.isValidForSave).toList();
    final errors = <String>[];
    var successCount = 0;

    for (final row in candidateRows) {
      if (row.isValidForSave) continue;
      final rowNumber = rows.indexOf(row) + 1;
      if (row.storage.value.trim().isEmpty && row.hasAnyVolumeInput) {
        errors.add('Row $rowNumber: select a storage pit');
      } else {
        errors.add('Row $rowNumber: enter a volume greater than 0');
      }
    }

    final totalsByStorage = <String, double>{};
    final storageLabels = <String, String>{};
    for (final row in filledRows) {
      final storage = row.storage.value.trim();
      final key = _normalizedStorage(storage);
      totalsByStorage[key] = (totalsByStorage[key] ?? 0) + _rowTotal(row);
      storageLabels[key] = storage;
    }

    for (final entry in totalsByStorage.entries) {
      final storage = storageLabels[entry.key] ?? entry.key;
      final available = _storageAvailableVolume(storage);
      if (available <= 0.005) {
        errors.add('Storage $storage has no available volume');
      } else if (entry.value > available + 0.005) {
        errors.add(
          'Storage $storage loss cannot exceed ${_formatVolume(available)} bbl',
        );
      }
    }

    if (errors.isNotEmpty) {
      _showValidationMessage(errors.first);
      return {'success': false, 'message': errors.join(' | ')};
    }

    if (filledRows.isEmpty) {
      if (existingRows.isEmpty) {
        return {
          'success': true,
          'message': 'No Mud Loss - Storage data to save',
        };
      }
      for (final row in existingRows) {
        final result = await _repository.deleteMudLossStorage(
          wellId,
          row.id.value,
        );
        if (result['success'] == true) {
          successCount++;
          _forgetSavedRow(row.id.value);
          row.id.value = '';
        } else {
          errors.add(result['message']?.toString() ?? 'Delete failed');
        }
      }
      if (errors.isEmpty) {
        _ensureMinimumRows();
        _loadedWellId = wellId;
        _loadedReportId = reportContext.selectedReportId.value.trim();
        await _refreshPitState();
      }
      return {
        'success': errors.isEmpty,
        'message': errors.isEmpty
            ? 'Mud Loss - Storage cleared successfully'
            : 'Cleared $successCount rows, errors: ${errors.join(", ")}',
      };
    }

    final currentIds = existingRows.map((row) => row.id.value).toList();
    final deletedIds = <String>{};
    for (var index = 0; index < filledRows.length; index++) {
      final row = filledRows[index];
      final body = {
        ...row.toBody(),
        'rowNumber': rows.indexOf(row) + 1,
        'operationInstanceKey': instanceKey,
      };
      final result = row.id.value.isNotEmpty
          ? await _repository.updateMudLossStorage(wellId, row.id.value, body)
          : await _repository.createMudLossStorage(wellId, body);
      if (result['success'] == true) {
        final savedData = _extractEntity(result['data']);
        final savedId = (savedData?['_id'] ?? savedData?['id'])?.toString();
        if (savedId != null && savedId.isNotEmpty) {
          row.id.value = savedId;
        }
        _rememberSavedRow(row);
        successCount++;
      } else {
        errors.add('Row ${index + 1}: ${result['message']}');
      }
    }

    final filledIds = filledRows
        .map((row) => row.id.value)
        .where((id) => id.isNotEmpty)
        .toSet();
    for (final id in currentIds.where((id) => !filledIds.contains(id))) {
      final deleteRes = await _repository.deleteMudLossStorage(wellId, id);
      if (deleteRes['success'] == true) {
        deletedIds.add(id);
        _forgetSavedRow(id);
        successCount++;
      } else {
        errors.add(deleteRes['message']?.toString() ?? 'Delete failed');
      }
    }

    if (errors.isEmpty) {
      for (final row in rows) {
        if (deletedIds.contains(row.id.value)) {
          row.id.value = '';
        }
      }
      _ensureMinimumRows();
      _loadedWellId = wellId;
      _loadedReportId = reportContext.selectedReportId.value.trim();
      await _refreshPitState();
    }
    return {
      'success': errors.isEmpty,
      'message': errors.isEmpty
          ? 'Mud Loss - Storage saved successfully'
          : 'Saved $successCount changes, errors: ${errors.join(", ")}',
    };
  }

  Map<String, String> rowSnapshot(MudLossStorageEntry row) {
    return {
      'storage': row.storage.value,
      'dump': row.dump.value,
      'evaporation': row.evaporation.value,
      'pitCleaning': row.pitCleaning.value,
    };
  }

  void applyRowSnapshot(MudLossStorageEntry row, Map<String, String> snapshot) {
    _setRowText(row, storage: snapshot['storage'] ?? '');
    _setRowText(row, dump: snapshot['dump'] ?? '');
    _setRowText(row, evaporation: snapshot['evaporation'] ?? '');
    _setRowText(row, pitCleaning: snapshot['pitCleaning'] ?? '');
    ensureTrailingRow();
  }

  void clearRowLocal(MudLossStorageEntry row) {
    _setRowText(row, storage: '');
    _setRowText(row, dump: '');
    _setRowText(row, evaporation: '');
    _setRowText(row, pitCleaning: '');
  }

  Future<Map<String, dynamic>> deleteRow(MudLossStorageEntry row) async {
    _autoSaveTimer?.cancel();
    final id = row.id.value.trim();
    if (id.isEmpty) {
      clearRowLocal(row);
      return {'success': true, 'message': 'Row cleared'};
    }

    final result = await _repository.deleteMudLossStorage(wellId, id);
    if (result['success'] == true) {
      _forgetSavedRow(id);
      row.id.value = '';
      clearRowLocal(row);
      await _refreshPitState();
    }
    return result;
  }

  void _setRowText(
    MudLossStorageEntry row, {
    String? storage,
    String? dump,
    String? evaporation,
    String? pitCleaning,
  }) {
    if (storage != null) row.storage.value = storage;
    if (dump != null) {
      row.dump.value = dump;
      row.dumpController.text = dump;
    }
    if (evaporation != null) {
      row.evaporation.value = evaporation;
      row.evaporationController.text = evaporation;
    }
    if (pitCleaning != null) {
      row.pitCleaning.value = pitCleaning;
      row.pitCleaningController.text = pitCleaning;
    }
  }
}
