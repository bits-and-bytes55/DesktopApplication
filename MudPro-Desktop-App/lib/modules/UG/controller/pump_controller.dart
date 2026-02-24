import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import '../model/pump_model.dart';

class PumpController extends GetxController {
  final AuthRepository repository = AuthRepository();

  // Pump list with dynamic rows
  final pumps = <PumpModel>[].obs;

  // Available pump models from API
  final availablePumpModels = <String>[].obs;

  // Loading state
  final isLoading = false.obs;

  // Current well ID - always set to static ID
  String currentWellId = '507f1f77bcf86cd799439011';

  @override
  void onInit() {
    super.onInit();
    // Initialize with 10 empty rows
    _initializeEmptyRows();
  }

  // Initialize 10 empty rows
  void _initializeEmptyRows() {
    pumps.clear();
    for (int i = 0; i < 10; i++) {
      pumps.add(PumpModel(rowNumber: i + 1));
    }
  }

  // Check if we need to add a new row
  void _checkAndAddNewRow() {
    if (pumps.isEmpty) return;
    
    // Check if last row has any data
    final lastPump = pumps.last;
    if (lastPump.hasData && pumps.length < 50) { // Max 50 rows
      pumps.add(PumpModel(rowNumber: pumps.length + 1));
      print('✅ Added new row: ${pumps.length}');
    }
  }

  // Set well ID (call this when well is selected)
  void setWellId(String wellId) {
    print('🔧 Setting well ID: $wellId');
    currentWellId = wellId;
    loadPumps(wellId);
  }

  // Load pumps for a well
  Future<void> loadPumps(String wellId) async {
    try {
      print('📡 Loading pumps for well: $wellId');
      isLoading.value = true;
      currentWellId = wellId;
      
      final result = await repository.getPumps(wellId);
      print('📦 Result from API: $result');
      
      if (result['success']) {
        final List<dynamic> pumpData = result['data'] ?? [];
        print('✅ Loaded ${pumpData.length} pumps from API');
        
        // Clear existing pumps
        pumps.clear();
        
        // Add fetched pumps
        for (var data in pumpData) {
          final pump = PumpModel.fromJson(data);
          print('📋 Pump ${pump.rowNumber.value}: type=${pump.type.value}, model=${pump.model.value}, disp=${pump.displacement.value}, rate=${pump.rate.value}');
          pumps.add(pump);
        }
        
        // Fill remaining rows with empty pumps to maintain at least 10 rows
        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }
        
        // Check if we need to add one more row at the end
        _checkAndAddNewRow();
        
        // Force UI refresh
        pumps.refresh();
        
        // Load available pump models from the fetched data
        _extractAvailablePumpModels(pumpData);
        
        print('✅ Total rows after loading: ${pumps.length}');
      } else {
        print('❌ Failed to load pumps: ${result['message']}');
        _initializeEmptyRows();
      }
    } catch (e) {
      print('❌ Error loading pumps: $e');
      _initializeEmptyRows();
    } finally {
      isLoading.value = false;
    }
  }

  // Extract unique pump models from API response
  void _extractAvailablePumpModels(List<dynamic> pumpData) {
    final Set<String> models = {};
    for (var pump in pumpData) {
      if (pump['model'] != null && pump['model'].toString().isNotEmpty) {
        models.add(pump['model'].toString());
      }
    }
    availablePumpModels.assignAll(models.toList()..sort());
    print('✅ Extracted ${models.length} unique pump models');
  }

  // Save single pump
  Future<void> savePump(int index) async {
    final pump = pumps[index];

    if (!pump.hasData) return;

    try {
      isLoading.value = true;

      Map<String, dynamic> result;
      final pumpData = pump.toJson();

      if (pump.id != null) {
        // Update existing pump
        print('📝 Updating pump: ${pump.id}');
        result = await repository.updatePump(pump.id!, pumpData);
      } else {
        // Create new pump
        print('➕ Creating new pump');
        result = await repository.createPump(currentWellId, pumpData);
      }

      if (result['success']) {
        // IMPORTANT: Replace with backend returned pump (includes calculated displacement and rate)
        final updatedPump = PumpModel.fromJson(result['data']);
        pumps[index] = updatedPump;
        
        // Check if we need to add a new row at the end
        _checkAndAddNewRow();
        
        // Refresh to show updated values
        pumps.refresh();
        
        print('✅ Pump saved successfully - Disp: ${updatedPump.displacement.value}, Rate: ${updatedPump.rate.value}');
        
        // Show success message
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

  // Bulk save all pumps
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

      // Reload pumps to ensure we have latest data
      await loadPumps(currentWellId);

      Get.snackbar(
        'Success',
        'Saved $successCount pumps${failCount > 0 ? ', $failCount failed' : ''}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Bulk save error: $e');
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

  // Delete pump
  Future<bool> deletePump(int index) async {
    final pump = pumps[index];

    if (pump.id == null) {
      // Just clear the row if it's not saved yet
      print('🗑️ Clearing unsaved row $index');
      pumps[index] = PumpModel(rowNumber: index + 1);
      return true;
    }

    try {
      isLoading.value = true;
      print('🗑️ Deleting pump: ${pump.id}');

      final result = await repository.deletePump(pump.id!);
      print('📦 Delete result: $result');

      if (result['success']) {
        // Remove the pump and reorder row numbers
        pumps.removeAt(index);
        
        // Update row numbers for remaining pumps
        for (int i = index; i < pumps.length; i++) {
          pumps[i].rowNumber.value = i + 1;
        }
        
        // Ensure we have at least 10 rows
        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }
        
        print('✅ Pump deleted successfully');
        
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
      print('❌ Error deleting pump: $e');
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

  // Get pump count (only counting pumps with data)
  int get pumpCount {
    return pumps.where((pump) => pump.hasData).length;
  }

  // Get pump data by model (for dropdown selection)
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