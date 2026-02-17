import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import '../model/pump_model.dart';

class PumpController extends GetxController {
  final AuthRepository repository = AuthRepository();

  // Pump list with 10 rows initially
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
    // Load available pump models
    _loadAvailablePumpModels();
  }

  // Initialize 10 empty rows
  void _initializeEmptyRows() {
    pumps.clear();
    for (int i = 0; i < 10; i++) {
      pumps.add(PumpModel(rowNumber: i + 1));
    }
  }

  // Load available pump models from API
  Future<void> _loadAvailablePumpModels() async {
    try {
      final models = await getAvailablePumpModels();
      availablePumpModels.assignAll(models);
      print('✅ Loaded ${models.length} pump models');
    } catch (e) {
      print('❌ Error loading pump models: $e');
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
          pumps.add(PumpModel.fromJson(data));
        }
        
        // Fill remaining rows with empty pumps to maintain at least 10 rows
        while (pumps.length < 10) {
          pumps.add(PumpModel(rowNumber: pumps.length + 1));
        }
        
        // Check if we need to add one more row at the end
        _checkAndAddNewRow();
        
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



  // Manual save with feedback
  Future<void> savePump(int index) async {
    if (currentWellId == null) {
      print('❌ No well selected');
      throw Exception('No well selected');
    }

    final pump = pumps[index];

    // Check if pump has any data
    if (!pump.hasData) {
      print('❌ No data to save');
      throw Exception('Please fill at least one field');
    }

    try {
      isLoading.value = true;
      print('💾 Manually saving pump at index $index');
      print('📝 Pump data: ${pump.toJson()}');

      Map<String, dynamic> result;

      if (pump.id != null) {
        // Update existing pump
        print('🔄 Updating pump: ${pump.id}');
        result = await repository.updatePump(pump.id!, pump.toJson());
      } else {
        // Create new pump
        print('➕ Creating pump for well: $currentWellId');
        result = await repository.createPump(currentWellId!, pump.toJson());
      }

      print('📦 Result: $result');

      if (result['success']) {
        // Update pump with returned data
        final updatedPump = PumpModel.fromJson(result['data']);
        pumps[index] = updatedPump;
        
        // Check if we need to add a new row
        _checkAndAddNewRow();
        
        print('✅ Pump saved successfully');
      } else {
        print('❌ Save failed: ${result['message']}');
        throw Exception(result['message'] ?? 'Failed to save pump');
      }
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
        return true;
      } else {
        print('❌ Delete failed: ${result['message']}');
        throw Exception(result['message'] ?? 'Failed to delete pump');
      }
    } catch (e) {
      print('❌ Error deleting pump: $e');
      throw Exception('Failed to delete pump: $e');
    } finally {
      isLoading.value = false;
    }
  }



  // Get pump count (only counting pumps with data)
  int get pumpCount {
    return pumps.where((pump) => pump.hasData).length;
  }

  // Get all available pump models from API
  Future<List<String>> getAvailablePumpModels() async {
    try {
      final result = await repository.getPumps(currentWellId);
      if (result['success']) {
        final List<dynamic> pumpData = result['data'] ?? [];
        final Set<String> models = {};
        for (var pump in pumpData) {
          if (pump['model'] != null && pump['model'].toString().isNotEmpty) {
            models.add(pump['model'].toString());
          }
        }
        return models.toList()..sort();
      }
      return [];
    } catch (e) {
      print('Error fetching pump models: $e');
      return [];
    }
  }

  // Get pump data by model
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
