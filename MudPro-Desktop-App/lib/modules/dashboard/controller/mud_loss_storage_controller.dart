import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
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

  bool get isValidForSave {
    final dumpValue = double.tryParse(dump.value.trim()) ?? 0;
    final evaporationValue = double.tryParse(evaporation.value.trim()) ?? 0;
    final pitCleaningValue = double.tryParse(pitCleaning.value.trim()) ?? 0;
    return storage.value.trim().isNotEmpty &&
        (dumpValue > 0 || evaporationValue > 0 || pitCleaningValue > 0);
  }

  Map<String, dynamic> toBody() => {
        'storage': storage.value.trim(),
        'dump': double.tryParse(dump.value.trim()) ?? 0,
        'evaporation': double.tryParse(evaporation.value.trim()) ?? 0,
        'pitCleaning': double.tryParse(pitCleaning.value.trim()) ?? 0,
      };

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

  Worker? _wellWorker;

  String get wellId => currentBackendWellId.trim();

  @override
  void onInit() {
    super.onInit();
    _ensureMinimumRows();
    load();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) => load(force: true));
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    for (final row in rows) {
      row.dispose();
    }
    super.onClose();
  }

  void _ensureMinimumRows() {
    while (rows.length < 6) {
      rows.add(MudLossStorageEntry());
    }
  }

  void ensureTrailingRow() {
    if (rows.isEmpty || rows.last.hasAnyData) {
      rows.add(MudLossStorageEntry());
    }
    _ensureMinimumRows();
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

  Future<void> load({bool force = false}) async {
    if (wellId.isEmpty) {
      _resetRows();
      return;
    }
    if (isLoading.value && !force) return;

    isLoading.value = true;
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
            dump: (item['dump'] ?? '').toString(),
            evaporation: (item['evaporation'] ?? '').toString(),
            pitCleaning: (item['pitCleaning'] ?? '').toString(),
          ),
        );
      }
      _ensureMinimumRows();
      ensureTrailingRow();
    } catch (_) {
      _resetRows();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> save() async {
    if (wellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }

    final existingRows = rows.where((row) => row.id.value.isNotEmpty).toList();
    final filledRows = rows.where((row) => row.isValidForSave).toList();
    final errors = <String>[];
    var successCount = 0;

    if (filledRows.isEmpty) {
      if (existingRows.isEmpty) {
        return {'success': true, 'message': 'No Mud Loss - Storage data to save'};
      }
      for (final row in existingRows) {
        final result = await _repository.deleteMudLossStorage(wellId, row.id.value);
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
