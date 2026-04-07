import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

import '../model/pump_model.dart';

class PumpController extends GetxController {
  final AuthRepository repository = AuthRepository();

  final pumps = <PumpModel>[].obs;
  final availablePumpModels = <String>[].obs;
  final isLoading = false.obs;
  final updatingRows = <int>{}.obs;

  String currentWellId = '507f1f77bcf86cd799439011';

  final Map<int, Timer> _debounceTimers = {};
  OptionsController? _optionsController;
  Worker? _unitSystemWorker;
  Worker? _customUnitsWorker;
  Map<String, String> _knownUnits = const {};

  @override
  void onInit() {
    super.onInit();

    if (Get.isRegistered<OptionsController>()) {
      _optionsController = Get.find<OptionsController>();
      _knownUnits = _snapshotUnits();
      _unitSystemWorker = ever(_optionsController!.unitSystem, (_) => _syncDisplayedUnits());
      _customUnitsWorker = ever<Map<String, String>>(
        _optionsController!.customUnits,
        (_) => _syncDisplayedUnits(),
      );
    }

    loadPumps(currentWellId);
  }

  @override
  void onClose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _unitSystemWorker?.dispose();
    _customUnitsWorker?.dispose();
    super.onClose();
  }

  void _initializeEmptyRows() {
    pumps.clear();
    for (var index = 0; index < 10; index++) {
      pumps.add(PumpModel(rowNumber: index + 1));
    }
  }

  void onFieldChanged(int index) {
    checkAndAddNewRow();

    final pump = pumps[index];
    if (pump.id != null) {
      _scheduleAutoUpdate(index);
    }
  }

  void _scheduleAutoUpdate(int index) {
    _debounceTimers[index]?.cancel();
    updatingRows.add(index);
    updatingRows.refresh();

    _debounceTimers[index] = Timer(
      const Duration(milliseconds: 800),
      () async => _autoUpdatePump(index),
    );
  }

  Future<void> _autoUpdatePump(int index) async {
    if (index >= pumps.length) {
      return;
    }

    final pump = pumps[index];
    if (pump.id == null || !pump.hasData) {
      updatingRows.remove(index);
      updatingRows.refresh();
      return;
    }

    try {
      final result = await repository.updatePump(pump.id!, pump.toJson());

      if (result['success'] == true) {
        final updated = PumpModel.fromJson(result['data'] as Map<String, dynamic>);
        pump.displacement.value = updated.displacement.value;
        pump.rate.value = updated.rate.value;
        debugPrint('Auto-updated pump row ${index + 1}');
      } else {
        debugPrint('Auto-update failed: ${result['message']}');
      }
    } catch (error) {
      debugPrint('Auto-update error: $error');
    } finally {
      updatingRows.remove(index);
      updatingRows.refresh();
      _debounceTimers.remove(index);
    }
  }

  void checkAndAddNewRow() {
    if (pumps.isEmpty) {
      return;
    }

    final lastPump = pumps.last;
    if (lastPump.hasData && pumps.length < 50) {
      pumps.add(PumpModel(rowNumber: pumps.length + 1));
      pumps.refresh();
    }
  }

  void setWellId(String wellId) {
    currentWellId = wellId;
    loadPumps(wellId);
  }

  Future<void> loadPumps(String wellId) async {
    try {
      isLoading.value = true;
      currentWellId = wellId;

      final result = await repository.getPumps(wellId);
      if (result['success'] == true) {
        final pumpData = (result['data'] as List<dynamic>? ?? <dynamic>[]);

        pumps
          ..clear()
          ..addAll(
            pumpData.map((data) => PumpModel.fromJson(data as Map<String, dynamic>)),
          );

        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }

        checkAndAddNewRow();
        pumps.refresh();
        _extractAvailablePumpModels(pumpData);
      } else {
        _initializeEmptyRows();
      }
    } catch (error) {
      debugPrint('Error loading pumps: $error');
      _initializeEmptyRows();
    } finally {
      isLoading.value = false;
    }
  }

  void _extractAvailablePumpModels(List<dynamic> pumpData) {
    final models = <String>{};

    for (final pump in pumpData) {
      if (pump is Map<String, dynamic>) {
        final model = pump['model']?.toString() ?? '';
        if (model.isNotEmpty) {
          models.add(model);
        }
      }
    }

    availablePumpModels.assignAll(models.toList()..sort());
    debugPrint('Loaded ${availablePumpModels.length} pump models for dropdown');
  }

  Future<void> savePump(int index) async {
    final pump = pumps[index];
    if (!pump.hasData) {
      return;
    }

    try {
      isLoading.value = true;

      final pumpData = pump.toJson();
      final Map<String, dynamic> result = pump.id != null
          ? await repository.updatePump(pump.id!, pumpData)
          : await repository.createPump(currentWellId, pumpData);

      if (result['success'] == true) {
        pumps[index] = PumpModel.fromJson(result['data'] as Map<String, dynamic>);
        checkAndAddNewRow();
        pumps.refresh();
        await loadPumps(currentWellId);
      } else {
        throw Exception(result['message'] ?? 'Failed to save pump');
      }
    } catch (error) {
      debugPrint('Save error: $error');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveAllPumps() async {
    final pumpsWithData = pumps.where((pump) => pump.hasData).toList();
    if (pumpsWithData.isEmpty) {
      return;
    }

    try {
      isLoading.value = true;
      var successCount = 0;
      var failCount = 0;

      for (var index = 0; index < pumps.length; index++) {
        if (!pumps[index].hasData) {
          continue;
        }

        try {
          await savePump(index);
          successCount++;
        } catch (_) {
          failCount++;
        }
      }

      await loadPumps(currentWellId);
      debugPrint('Saved $successCount pumps, $failCount failed');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletePump(int index) async {
    final pump = pumps[index];

    _debounceTimers[index]?.cancel();
    _debounceTimers.remove(index);
    updatingRows.remove(index);

    if (pump.id == null) {
      pumps[index] = PumpModel(rowNumber: index + 1);
      return true;
    }

    try {
      isLoading.value = true;
      final result = await repository.deletePump(pump.id!);

      if (result['success'] == true) {
        pumps.removeAt(index);

        for (var rowIndex = index; rowIndex < pumps.length; rowIndex++) {
          pumps[rowIndex].rowNumber.value = rowIndex + 1;
        }

        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }

        await loadPumps(currentWellId);
        return true;
      }

      throw Exception(result['message'] ?? 'Failed to delete pump');
    } finally {
      isLoading.value = false;
    }
  }

  int get pumpCount => pumps.where((pump) => pump.hasData).length;

  Future<Map<String, dynamic>?> getPumpDataByModel(String model) async {
    try {
      final result = await repository.getPumps(currentWellId);
      if (result['success'] == true) {
        final pumpData = result['data'] as List<dynamic>? ?? <dynamic>[];
        final match = pumpData.cast<Map<String, dynamic>?>().firstWhereOrNull(
              (pump) => pump?['model'] == model,
            );
        return match;
      }
      return null;
    } catch (error) {
      debugPrint('Error fetching pump data: $error');
      return null;
    }
  }

  Map<String, String> _snapshotUnits() {
    return AppUnits.snapshotUnits(const ['1', '2', '11', '17', '22', '26']);
  }

  void _syncDisplayedUnits() {
    final nextUnits = _snapshotUnits();
    if (_knownUnits.isEmpty) {
      _knownUnits = nextUnits;
      return;
    }

    for (final pump in pumps) {
      pump.linerId.value = AppUnits.convertText(
        rawValue: pump.linerId.value,
        fromUnit: _knownUnits['2'] ?? '(in)',
        toUnit: nextUnits['2'] ?? '(in)',
        precision: 4,
      );
      pump.rodOd.value = AppUnits.convertText(
        rawValue: pump.rodOd.value,
        fromUnit: _knownUnits['2'] ?? '(in)',
        toUnit: nextUnits['2'] ?? '(in)',
        precision: 4,
      );
      pump.strokeLength.value = AppUnits.convertText(
        rawValue: pump.strokeLength.value,
        fromUnit: _knownUnits['2'] ?? '(in)',
        toUnit: nextUnits['2'] ?? '(in)',
        precision: 4,
      );
      pump.displacement.value = AppUnits.convertText(
        rawValue: pump.displacement.value,
        fromUnit: _knownUnits['11'] ?? '(bbl/stk)',
        toUnit: nextUnits['11'] ?? '(bbl/stk)',
        precision: 4,
      );
      pump.rate.value = AppUnits.convertText(
        rawValue: pump.rate.value,
        fromUnit: _knownUnits['17'] ?? '(gpm)',
        toUnit: nextUnits['17'] ?? '(gpm)',
        precision: 4,
      );
      pump.maxPumpP.value = AppUnits.convertText(
        rawValue: pump.maxPumpP.value,
        fromUnit: _knownUnits['22'] ?? '(psi)',
        toUnit: nextUnits['22'] ?? '(psi)',
        precision: 2,
      );
      pump.maxHp.value = AppUnits.convertText(
        rawValue: pump.maxHp.value,
        fromUnit: _knownUnits['26'] ?? '(HP)',
        toUnit: nextUnits['26'] ?? '(HP)',
        precision: 2,
      );
      pump.surfaceLen.value = AppUnits.convertText(
        rawValue: pump.surfaceLen.value,
        fromUnit: _knownUnits['1'] ?? '(m)',
        toUnit: nextUnits['1'] ?? '(m)',
        precision: 4,
      );
      pump.surfaceId.value = AppUnits.convertText(
        rawValue: pump.surfaceId.value,
        fromUnit: _knownUnits['2'] ?? '(in)',
        toUnit: nextUnits['2'] ?? '(in)',
        precision: 4,
      );
    }

    pumps.refresh();
    _knownUnits = nextUnits;
  }
}
