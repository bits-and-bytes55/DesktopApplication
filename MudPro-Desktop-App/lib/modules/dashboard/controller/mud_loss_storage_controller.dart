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
  final AuthRepository _repository = AuthRepository();
  final rows = <MudLossStorageEntry>[].obs;
  final isLoading = false.obs;
  Timer? _autoSaveTimer;
  bool _isApplyingState = false;

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
    _ensureMinimumRows();
  }

  void clearLocalState() {
    _autoSaveTimer?.cancel();
    _isApplyingState = true;
    _resetRows();
    _isApplyingState = false;
  }

  Future<void> load({bool force = false}) async {
    _autoSaveTimer?.cancel();
    if (wellId.isEmpty) {
      _isApplyingState = true;
      _resetRows();
      _isApplyingState = false;
      return;
    }
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
      final items = data is List ? data.reversed.toList() : const [];

      _disposeRows();
      for (final rawItem in items) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        rows.add(
          MudLossStorageEntry(
            id: (item['_id'] ?? item['id'] ?? '').toString(),
            storage: (item['storage'] ?? '').toString(),
            dump: _formatVolume(item['dump']),
            evaporation: _formatVolume(item['evaporation']),
            pitCleaning: _formatVolume(item['pitCleaning']),
          ),
        );
      }
      _ensureMinimumRows();
      ensureTrailingRow();
    } catch (_) {
      _resetRows();
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

    if (errors.isNotEmpty) {
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
        } else {
          errors.add(result['message']?.toString() ?? 'Delete failed');
        }
      }
      if (errors.isEmpty) {
        await load(force: true);
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
    for (var index = 0; index < filledRows.length; index++) {
      final row = filledRows[index];
      final body = row.toBody();
      final result = row.id.value.isNotEmpty
          ? await _repository.updateMudLossStorage(wellId, row.id.value, body)
          : await _repository.createMudLossStorage(wellId, body);
      if (result['success'] == true) {
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
        successCount++;
      } else {
        errors.add(deleteRes['message']?.toString() ?? 'Delete failed');
      }
    }

    if (errors.isEmpty) {
      await load(force: true);
      await _refreshPitState();
    }
    return {
      'success': errors.isEmpty,
      'message': errors.isEmpty
          ? 'Mud Loss - Storage saved successfully'
          : 'Saved $successCount changes, errors: ${errors.join(", ")}',
    };
  }
}
