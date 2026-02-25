import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import '../model/pump_model.dart';

class PumpController extends GetxController {
  final AuthRepository repository = AuthRepository();

  final pumps = <PumpModel>[].obs;
  final availablePumpModels = <String>[].obs;
  final isLoading = false.obs;

  String currentWellId = '507f1f77bcf86cd799439011';

  @override
  void onInit() {
    super.onInit();
    _initializeEmptyRows();
  }

  void _initializeEmptyRows() {
    pumps.clear();
    for (int i = 0; i < 10; i++) {
      pumps.add(PumpModel(rowNumber: i + 1));
    }
  }

  /// Public method - called from view whenever any field changes
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

      final result = await repository.getPumps(wellId);

      if (result['success']) {
        final List<dynamic> pumpData = result['data'] ?? [];

        pumps.clear();

        for (var data in pumpData) {
          final pump = PumpModel.fromJson(data);
          pumps.add(pump);
        }

        // Ensure minimum 10 rows
        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }

        // Add extra row if last one has data
        checkAndAddNewRow();

        pumps.refresh();
        _extractAvailablePumpModels(pumpData);
      } else {
        _initializeEmptyRows();
      }
    } catch (e) {
      print('❌ Error loading pumps: $e');
      _initializeEmptyRows();
    } finally {
      isLoading.value = false;
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
  }

  Future<void> savePump(int index) async {
    final pump = pumps[index];
    if (!pump.hasData) return;

    try {
      isLoading.value = true;

      Map<String, dynamic> result;
      final pumpData = pump.toJson();

      if (pump.id != null) {
        result = await repository.updatePump(pump.id!, pumpData);
      } else {
        result = await repository.createPump(currentWellId, pumpData);
      }

      if (result['success']) {
        // Replace with backend-returned pump (includes server-calculated displacement & rate)
        final updatedPump = PumpModel.fromJson(result['data']);
        pumps[index] = updatedPump;

        checkAndAddNewRow();
        pumps.refresh();

        Get.snackbar(
          'Success',
          'Pump saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        throw Exception(result['message'] ?? 'Failed to save pump');
      }
    } catch (e) {
      print("❌ Save error: $e");
      Get.snackbar(
        'Error',
        'Failed to save pump: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveAllPumps() async {
    final pumpsWithData = pumps.where((pump) => pump.hasData).toList();

    if (pumpsWithData.isEmpty) {
      Get.snackbar(
        'Info',
        'No pumps to save',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < pumps.length; i++) {
        final pump = pumps[i];
        if (pump.hasData) {
          try {
            await savePump(i);
            successCount++;
          } catch (e) {
            failCount++;
          }
        }
      }

      await loadPumps(currentWellId);

      Get.snackbar(
        'Success',
        'Saved $successCount pumps${failCount > 0 ? ', $failCount failed' : ''}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save pumps: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletePump(int index) async {
    final pump = pumps[index];

    if (pump.id == null) {
      pumps[index] = PumpModel(rowNumber: index + 1);
      return true;
    }

    try {
      isLoading.value = true;

      final result = await repository.deletePump(pump.id!);

      if (result['success']) {
        pumps.removeAt(index);

        for (int i = index; i < pumps.length; i++) {
          pumps[i].rowNumber.value = i + 1;
        }

        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }

        Get.snackbar(
          'Success',
          'Pump deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return true;
      } else {
        throw Exception(result['message'] ?? 'Failed to delete pump');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete pump: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  int get pumpCount {
    return pumps.where((pump) => pump.hasData).length;
  }

  Future<Map<String, dynamic>?> getPumpDataByModel(String model) async {
    try {
      final result = await repository.getPumps(currentWellId);
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