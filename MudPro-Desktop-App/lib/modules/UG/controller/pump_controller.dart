import 'dart:async';

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pump_model.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class PumpController extends GetxController {
  final AuthRepository repository = AuthRepository();

  final pumps = <PumpModel>[].obs;
  final availablePumpModels = <String>[].obs;
  final isLoading = false.obs;
  final updatingRows = <int>{}.obs;

  String currentWellId = currentBackendWellId;
  final Map<int, Timer> _debounceTimers = {};
  Worker? _wellWorker;
  Worker? _reportWorker;

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
    _wellWorker = ever<String>(padWellContext.selectedWellId, (wellId) {
      if (wellId.trim().isEmpty) {
        currentWellId = '';
        _initializeEmptyRows();
        availablePumpModels.clear();
        return;
      }
      setWellId(wellId.trim());
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      if (currentWellId.isNotEmpty) {
        loadPumps(currentWellId);
      }
    });

    if (currentWellId.isNotEmpty) {
      loadPumps(currentWellId);
    } else {
      _initializeEmptyRows();
    }
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.onClose();
  }

  void _initializeEmptyRows() {
    pumps.clear();
    for (int i = 0; i < 10; i++) {
      pumps.add(PumpModel(rowNumber: i + 1));
    }
    pumps.refresh();
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

    _debounceTimers[index] = Timer(const Duration(milliseconds: 800), () async {
      await _autoUpdatePump(index);
    });
  }

  Future<void> _autoUpdatePump(int index) async {
    if (index >= pumps.length) return;

    final pump = pumps[index];
    if (pump.id == null || !pump.hasData) {
      updatingRows.remove(index);
      updatingRows.refresh();
      return;
    }

    try {
      final result = await repository.updatePump(
        pump.id!,
        pump.toJson(),
        wellId: currentWellId,
        reportId: _currentReportId,
        reportNo: _currentReportNo,
      );

      if (result['success']) {
        final updated = PumpModel.fromJson(
          result['data'] as Map<String, dynamic>,
        );
        pumps[index] = updated;
        pumps.refresh();
        print('Auto-updated pump row ${index + 1}');
      } else {
        print('Pump auto-update failed: ${result['message']}');
      }
    } catch (e) {
      print('Pump auto-update error: $e');
    } finally {
      updatingRows.remove(index);
      updatingRows.refresh();
      _debounceTimers.remove(index);
    }
  }

  void checkAndAddNewRow() {
    if (pumps.isEmpty) return;
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

      final result = await repository.getPumps(
        wellId,
        reportId: _currentReportId,
      );

      if (result['success']) {
        final List<dynamic> pumpData = result['data'] ?? [];

        pumps.clear();
        for (final data in pumpData) {
          if (data is Map<String, dynamic>) {
            pumps.add(PumpModel.fromJson(data));
          } else if (data is Map) {
            pumps.add(PumpModel.fromJson(Map<String, dynamic>.from(data)));
          }
        }

        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }

        checkAndAddNewRow();
        pumps.refresh();
        _extractAvailablePumpModels(pumpData);
      } else {
        _initializeEmptyRows();
      }
    } catch (e) {
      print('Error loading pumps: $e');
      _initializeEmptyRows();
    } finally {
      isLoading.value = false;
    }
  }

  void _extractAvailablePumpModels(List<dynamic> pumpData) {
    final models = <String>{};
    for (final pump in pumpData) {
      if (pump is! Map) continue;
      final model = pump['model']?.toString().trim() ?? '';
      if (model.isNotEmpty) {
        models.add(model);
      }
    }
    availablePumpModels.assignAll(models.toList()..sort());
  }

  Future<void> savePump(int index) async {
    final pump = pumps[index];
    if (!pump.hasData) return;
    if (currentWellId.isEmpty) {
      throw Exception('No backend well selected');
    }

    try {
      isLoading.value = true;

      final result = pump.id != null
          ? await repository.updatePump(
              pump.id!,
              pump.toJson(),
              wellId: currentWellId,
              reportId: _currentReportId,
              reportNo: _currentReportNo,
            )
          : await repository.createPump(
              currentWellId,
              pump.toJson(),
              reportId: _currentReportId,
              reportNo: _currentReportNo,
            );

      if (result['success']) {
        pumps[index] = PumpModel.fromJson(
          Map<String, dynamic>.from(result['data'] as Map),
        );
        checkAndAddNewRow();
        pumps.refresh();
        await loadPumps(currentWellId);
      } else {
        throw Exception(result['message'] ?? 'Failed to save pump');
      }
    } catch (e) {
      print('Pump save error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveAllPumps() async {
    final pumpsWithData = pumps.where((pump) => pump.hasData).toList();
    if (pumpsWithData.isEmpty) return;

    try {
      isLoading.value = true;
      for (int i = 0; i < pumps.length; i++) {
        if (pumps[i].hasData) {
          await savePump(i);
        }
      }
      await loadPumps(currentWellId);
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
      pumps.refresh();
      return true;
    }

    try {
      isLoading.value = true;
      final result = await repository.deletePump(
        pump.id!,
        wellId: currentWellId,
        reportId: _currentReportId,
        reportNo: _currentReportNo,
      );

      if (result['success']) {
        pumps.removeAt(index);
        for (int i = index; i < pumps.length; i++) {
          pumps[i].rowNumber.value = i + 1;
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

  int get pumpCount => pumps.where((p) => p.hasData).length;

  Future<Map<String, dynamic>?> getPumpDataByModel(String model) async {
    try {
      final result = await repository.getPumps(
        currentWellId,
        reportId: _currentReportId,
      );
      if (result['success']) {
        final List<dynamic> pumpData = result['data'] ?? [];
        return pumpData
            .cast<Map?>()
            .firstWhereOrNull((pump) => pump?['model'] == model)
            ?.cast<String, dynamic>();
      }
      return null;
    } catch (e) {
      print('Error fetching pump data: $e');
      return null;
    }
  }
}
