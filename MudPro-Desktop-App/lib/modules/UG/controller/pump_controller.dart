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

  // Track which rows are currently being auto-updated
  final updatingRows = <int>{}.obs;

  String currentWellId = currentBackendWellId;

  // Debounce timers per row index — 800ms after last keystroke
  final Map<int, Timer> _debounceTimers = {};
  Worker? _reportWorker;
  int _loadGeneration = 0;

  @override
  void onInit() {
    super.onInit();
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      _cancelPendingUpdates();
      if (currentWellId.isNotEmpty) {
        loadPumps(currentWellId);
      } else {
        _initializeEmptyRows();
      }
    });
    // ✅ FIXED: Load pumps on init so availablePumpModels gets populated
    if (currentWellId.isNotEmpty) {
      loadPumps(currentWellId);
    } else {
      _initializeEmptyRows();
    }
  }

  @override
  void onClose() {
    _reportWorker?.dispose();
    _cancelPendingUpdates();
    super.onClose();
  }

  void _cancelPendingUpdates() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    updatingRows.clear();
    updatingRows.refresh();
  }

  void _initializeEmptyRows() {
    pumps.clear();
    for (int i = 0; i < 10; i++) {
      pumps.add(PumpModel(rowNumber: i + 1));
    }
  }

  Map<String, dynamic>? _extractEntity(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  void _applySavedPump(PumpModel target, dynamic rawData) {
    final data = _extractEntity(rawData);
    if (data == null) return;

    final savedId = (data['_id'] ?? data['id'])?.toString();
    if (savedId != null && savedId.isNotEmpty) {
      target.id = savedId;
    }
    target.displacement.value =
        data['displacement']?.toString() ?? target.displacement.value;
    target.rate.value = data['rate']?.toString() ?? target.rate.value;
  }

  /// Called from view on every field change
  void onFieldChanged(int index) {
    checkAndAddNewRow();

    if (index >= pumps.length) return;
    final pump = pumps[index];
    if (pump.hasData) {
      _scheduleAutoUpdate(index);
    }
  }

  /// Debounced auto-update: waits 800ms after last change then hits PUT API
  void _scheduleAutoUpdate(int index) {
    _debounceTimers[index]?.cancel();

    updatingRows.add(index);
    updatingRows.refresh();

    _debounceTimers[index] =
        Timer(const Duration(milliseconds: 800), () async {
      await _autoUpdatePump(index);
    });
  }

  Future<void> _autoUpdatePump(int index) async {
    if (index >= pumps.length) return;

    final pump = pumps[index];
    if (!pump.hasData || currentWellId.isEmpty) {
      updatingRows.remove(index);
      updatingRows.refresh();
      return;
    }

    try {
      final pumpData = pump.toJson();
      final result = await repository.createPump(
        currentWellId,
        pumpData,
        includeReportScope: false,
      );

      if (result['success']) {
        final updated = PumpModel.fromJson(
          result['data'] as Map<String, dynamic>,
        );
        pump.id = updated.id ?? pump.id;
        pump.displacement.value = updated.displacement.value;
        pump.rate.value = updated.rate.value;
        final modelText = pump.model.value.trim();
        if (modelText.isNotEmpty && !availablePumpModels.contains(modelText)) {
          availablePumpModels.add(modelText);
          availablePumpModels.sort();
        }
        print('✅ Auto-updated pump row ${index + 1}');
      } else {
        print('❌ Auto-update failed: ${result['message']}');
      }
    } catch (e) {
      print('❌ Auto-update error: $e');
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

  /// ✅ setWellId called from parent (UG/Dashboard) when well changes
  void setWellId(String wellId) {
    _cancelPendingUpdates();
    currentWellId = wellId;
    loadPumps(wellId);
  }

  Future<void> loadPumps(String wellId) async {
    final generation = ++_loadGeneration;
    try {
      isLoading.value = true;
      currentWellId = wellId;

      final result = await repository.getPumps(
        wellId,
        includeReportScope: false,
      );
      if (generation != _loadGeneration) return;

      if (result['success']) {
        final List<dynamic> pumpData = result['data'] ?? [];

        pumps.clear();

        for (var data in pumpData) {
          pumps.add(PumpModel.fromJson(data));
        }

        // ✅ Always ensure minimum 10 empty rows
        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }

        checkAndAddNewRow();
        pumps.refresh();

        // ✅ Extract models for dropdown
        _extractAvailablePumpModels(pumpData);
      } else {
        _initializeEmptyRows();
      }
    } catch (e) {
      print('❌ Error loading pumps: $e');
      _initializeEmptyRows();
    } finally {
      if (generation == _loadGeneration) {
        isLoading.value = false;
      }
    }
  }

  void _extractAvailablePumpModels(List<dynamic> pumpData) {
    final Set<String> models = {};
    for (var pump in pumpData) {
      if (pump['model'] != null && pump['model'].toString().isNotEmpty) {
        models.add(pump['model'].toString());
      }
    }
    availablePumpModels.assignAll(models.toList()..sort());
    print('✅ Loaded ${availablePumpModels.length} pump models for dropdown');
  }

  /// Manual save — for NEW (unsaved) pumps only
  Future<void> savePump(int index) async {
    final pump = pumps[index];
    if (!pump.hasData) return;
    if (currentWellId.isEmpty) {
      throw Exception('No backend well selected');
    }

    try {
      Map<String, dynamic> result;
      final pumpData = pump.toJson();

      result = (await repository.createPump(
        currentWellId,
        pumpData,
        includeReportScope: false,
      )) as Map<String, dynamic>;

      if (result['success']) {
        _applySavedPump(pump, result['data']);
        checkAndAddNewRow();
        final modelText = pump.model.value.trim();
        if (modelText.isNotEmpty && !availablePumpModels.contains(modelText)) {
          availablePumpModels.add(modelText);
          availablePumpModels.sort();
        }

        // Get.snackbar(
        //   'Success',
        //   'Pump saved successfully',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.green,
        //   colorText: Colors.white,
        //   duration: const Duration(seconds: 2),
        // );
      } else {
        throw Exception(result['message'] ?? 'Failed to save pump');
      }
    } catch (e) {
      print("❌ Save error: $e");
      // Get.snackbar(
      //   'Error',
      //   'Failed to save pump: $e',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
      rethrow;
    }
  }

  Future<void> saveAllPumps() async {
    final pumpsWithData = pumps.where((pump) => pump.hasData).toList();

    if (pumpsWithData.isEmpty) {
      // Get.snackbar('Info', 'No pumps to save',
      //     snackPosition: SnackPosition.BOTTOM,
      //     backgroundColor: Colors.orange,
      //     colorText: Colors.white);
      return;
    }

    try {
      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < pumps.length; i++) {
        if (pumps[i].hasData) {
          try {
            await savePump(i);
            successCount++;
          } catch (e) {
            failCount++;
          }
        }
      }
      // Get.snackbar(
      //   'Success',
      //   'Saved $successCount pumps${failCount > 0 ? ', $failCount failed' : ''}',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
      //   colorText: Colors.white,
      // );
    } catch (e) {
      // Get.snackbar('Error', 'Failed to save pumps: $e',
      //     snackPosition: SnackPosition.BOTTOM,
      //     backgroundColor: Colors.red,
      //     colorText: Colors.white);
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
      final result = await repository.deletePump(
        pump.id!,
        includeReportScope: false,
      );

      if (result['success']) {
        pumps.removeAt(index);

        for (int i = index; i < pumps.length; i++) {
          pumps[i].rowNumber.value = i + 1;
        }

        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }

        // ✅ Refresh models after delete
        await loadPumps(currentWellId);

        // Get.snackbar('Success', 'Pump deleted successfully',
        //     snackPosition: SnackPosition.BOTTOM,
        //     backgroundColor: Colors.green,
        //     colorText: Colors.white);

        return true;
      } else {
        throw Exception(result['message'] ?? 'Failed to delete pump');
      }
    } catch (e) {
      // Get.snackbar('Error', 'Failed to delete pump: $e',
      //     snackPosition: SnackPosition.BOTTOM,
      //     backgroundColor: Colors.red,
      //     colorText: Colors.white);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  int get pumpCount => pumps.where((p) => p.hasData).length;

  /// ✅ Fetch pump data by model for dropdown auto-fill
  Future<Map<String, dynamic>?> getPumpDataByModel(String model) async {
    try {
      final result = await repository.getPumps(
        currentWellId,
        includeReportScope: false,
      );
      if (result['success']) {
        final List<dynamic> pumpData = result['data'] ?? [];
        return pumpData.firstWhere(
          (pump) => pump['model'] == model,
          orElse: () => null,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching pump data: $e');
      return null;
    }
  }
}
