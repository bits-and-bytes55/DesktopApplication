import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import '../model/sce_model.dart';
import './UG_controller.dart';

class SceController extends GetxController {
  final AuthRepository repository = AuthRepository();
  
  // Get UG controller for lock state
  UgController get ugController => Get.find<UgController>();
  
  // Shaker list
  final shakers = <ShakerModel>[].obs;
  
  // Other SCE list
  final otherSce = <OtherSceModel>[].obs;

  // Available types from API
  final availableShakerTypes = <String>[].obs;
  final availableOtherSceTypes = <String>[].obs;

  // Loading state
  final isLoading = false.obs;
  
  // Current well ID - Static for now
  String? currentWellId = "507f1f77bcf86cd799439011";
  
  // Minimum rows
  static const int MIN_SHAKER_ROWS = 10;
  static const int MIN_OTHER_SCE_ROWS = 5;

  @override
  void onInit() {
    super.onInit();
    // Initialize with empty rows only
    initializeEmptyShakers();
    initializeEmptyOtherSce();
    // Only load dropdown options, don't populate rows with data
    if (currentWellId != null) {
      loadAvailableTypes(currentWellId!);
    }
  }

  // ================= INITIALIZATION =================
  
  void initializeEmptyShakers() {
    shakers.clear();
    for (int i = 0; i < MIN_SHAKER_ROWS; i++) {
      shakers.add(ShakerModel(shaker: ''));
    }
  }

  void initializeEmptyOtherSce() {
    otherSce.clear();
    for (int i = 0; i < MIN_OTHER_SCE_ROWS; i++) {
      otherSce.add(OtherSceModel());
    }
  }

  // ================= LOAD DATA =================
  
  Future<void> loadSceData(String wellId) async {
    try {
      isLoading.value = true;
      currentWellId = wellId;

      print('🔄 Loading SCE data for well: $wellId');

      // Load shakers, other SCE, and available types in parallel
      await Future.wait([
        loadShakers(wellId),
        loadOtherSce(wellId),
        loadAvailableTypes(wellId),
      ]);

      print('✅ SCE data loaded successfully');
    } catch (e) {
      print('❌ Error loading SCE data: $e');

    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadShakers(String wellId) async {
    try {
      print('🔄 Fetching shakers for well: $wellId');
      final result = await repository.getShakers(wellId);
      
      print('📦 Shakers API Response: $result');
      
      if (result['success']) {
        final List<dynamic> shakerData = result['data'] ?? [];
        
        shakers.clear();
        
        // Add fetched shakers
        for (var data in shakerData) {
          shakers.add(ShakerModel.fromJson(data));
        }
        
        // Ensure minimum rows
        while (shakers.length < MIN_SHAKER_ROWS) {
          shakers.add(ShakerModel(shaker: ''));
        }
        
        print('✅ Loaded ${shakerData.length} shakers');
      } else {
        print('⚠️ Failed to load shakers: ${result['message']}');
        initializeEmptyShakers();
      }
    } catch (e) {
      print('❌ Error loading shakers: $e');
      initializeEmptyShakers();
    }
  }

  Future<void> loadOtherSce(String wellId) async {
    try {
      print('🔄 Fetching other SCE for well: $wellId');
      final result = await repository.getOtherSce(wellId);
      
      print('📦 Other SCE API Response: $result');
      
      if (result['success']) {
        final List<dynamic> sceData = result['data'] ?? [];
        
        otherSce.clear();
        
        // Add fetched SCE
        for (var data in sceData) {
          otherSce.add(OtherSceModel.fromJson(data));
        }
        
        // Ensure minimum rows
        while (otherSce.length < MIN_OTHER_SCE_ROWS) {
          otherSce.add(OtherSceModel());
        }
        
        print('✅ Loaded ${sceData.length} other SCE');
      } else {
        print('⚠️ Failed to load other SCE: ${result['message']}');
        initializeEmptyOtherSce();
      }
    } catch (e) {
      print('❌ Error loading other SCE: $e');
      initializeEmptyOtherSce();
    }
  }

  // ================= SHAKER OPERATIONS =================
  
  Future<void> saveShaker(int index) async {
    if (currentWellId == null) {
      print('⚠️ No well ID available');
      return;
    }

    try {
      final shaker = shakers[index];
      
      // Check if shaker has any data
      if (!shaker.hasData) {
        print('⚠️ Shaker has no data to save');
        return;
      }

      isLoading.value = true;

      Map<String, dynamic> result;
      
      if (shaker.id != null) {
        // Update existing shaker
        result = await repository.updateShaker(shaker.id!, shaker.toJson());
      } else {
        // Create new shaker
        result = await repository.createShaker(currentWellId!, shaker.toJson());
      }

      if (result['success']) {
        // Update shaker with returned data
        final updatedShaker = ShakerModel.fromJson(result['data']);
        shakers[index] = updatedShaker;
        
        // Exit edit mode
        shaker.isEditing.value = false;
        
        // Check if this was the last row and add new one if needed
        checkAndAddShakerRow();
        
        print('✅ Shaker saved successfully');
      } else {
       print('❌ Failed to save shaker: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error saving shaker: $e');
      
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteShaker(int index) async {
    final shaker = shakers[index];
    
    if (shaker.id == null) {
      // Just clear the row if it's not saved yet
      shakers[index] = ShakerModel(shaker: shaker.shaker.value);
      return;
    }

    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Shaker'),
          content: const Text('Are you sure you want to delete this shaker?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isLoading.value = true;

      final result = await repository.deleteShaker(shaker.id!);

      if (result['success']) {
        // Replace deleted shaker with empty one
        shakers[index] = ShakerModel(shaker: shaker.shaker.value);
        
        print('✅ Shaker deleted successfully');
      } else {
        print('❌ Failed to delete shaker');
      }
    } catch (e) {
      print('❌ Error deleting shaker: $e');
     
    } finally {
      isLoading.value = false;
    }
  }

  void enableShakerEditMode(int index) {
    shakers[index].isEditing.value = true;
  }

  void cancelShakerEdit(int index) {
    final shaker = shakers[index];
    shaker.isEditing.value = false;
    
    if (shaker.id != null && currentWellId != null) {
      loadSceData(currentWellId!);
    }
  }

  void checkAndAddShakerRow() {
    // Check if last row has data
    if (shakers.isNotEmpty && shakers.last.hasData) {
      // Add new empty row
      shakers.add(ShakerModel(shaker: ''));
    }
  }

  // ================= OTHER SCE OPERATIONS =================
  
  Future<void> saveOtherSce(int index) async {
    if (currentWellId == null) {
      print('⚠️ No well ID available');
      return;
    }

    try {
      final sce = otherSce[index];
      
      if (!sce.hasData) {
        print('⚠️ SCE has no data to save');
        return;
      }

      isLoading.value = true;

      Map<String, dynamic> result;
      
      if (sce.id != null) {
        result = await repository.updateOtherSce(sce.id!, sce.toJson());
      } else {
        result = await repository.createOtherSce(currentWellId!, sce.toJson());
      }

      if (result['success']) {
        final updatedSce = OtherSceModel.fromJson(result['data']);
        otherSce[index] = updatedSce;
        
        sce.isEditing.value = false;
        
        // Check if this was the last row and add new one if needed
        checkAndAddOtherSceRow();
        
        print('✅ Other SCE saved successfully');
      } else {
        print('❌ Failed to save SCE: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error saving other SCE: $e');
     
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteOtherSce(int index) async {
    final sce = otherSce[index];
    
    if (sce.id == null) {
      otherSce[index] = OtherSceModel();
      return;
    }

    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete SCE'),
          content: const Text('Are you sure you want to delete this SCE equipment?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isLoading.value = true;

      final result = await repository.deleteOtherSce(sce.id!);

      if (result['success']) {
        otherSce[index] = OtherSceModel();
        
        print('✅ Other SCE deleted successfully');
      } else {
        print('❌ Failed to delete other SCE');
      }
    } catch (e) {
      print('❌ Error deleting other SCE: $e');
     
    } finally {
      isLoading.value = false;
    }
  }

  void enableOtherSceEditMode(int index) {
    otherSce[index].isEditing.value = true;
  }

  void cancelOtherSceEdit(int index) {
    final sce = otherSce[index];
    sce.isEditing.value = false;
    
    if (sce.id != null && currentWellId != null) {
      loadSceData(currentWellId!);
    }
  }

  void checkAndAddOtherSceRow() {
    if (otherSce.isNotEmpty && otherSce.last.hasData) {
      otherSce.add(OtherSceModel());
    }
  }

  // ================= GETTERS =================

  int get shakerCount {
    return shakers.where((s) => s.hasData).length;
  }

  int get otherSceCount {
    return otherSce.where((s) => s.hasData).length;
  }

  // Load available types from API
  Future<void> loadAvailableTypes(String wellId) async {
    try {
      // Load shaker types
      final shakerResult = await repository.getShakers(wellId);
      if (shakerResult['success']) {
        final List<dynamic> shakerData = shakerResult['data'] ?? [];
        final Set<String> shakerTypes = {};
        for (var shaker in shakerData) {
          if (shaker['shaker'] != null && shaker['shaker'].toString().isNotEmpty) {
            shakerTypes.add(shaker['shaker'].toString());
          }
        }
        // Add default types if no data
        if (shakerTypes.isEmpty) {
          shakerTypes.addAll(['Shaker', 'Cleaner', 'Degasser']);
        }
        availableShakerTypes.assignAll(shakerTypes.toList()..sort());
      }

      // Load other SCE types
      final sceResult = await repository.getOtherSce(wellId);
      if (sceResult['success']) {
        final List<dynamic> sceData = sceResult['data'] ?? [];
        final Set<String> sceTypes = {};
        for (var sce in sceData) {
          if (sce['type'] != null && sce['type'].toString().isNotEmpty) {
            sceTypes.add(sce['type'].toString());
          }
        }
        // Add default types if no data
        if (sceTypes.isEmpty) {
          sceTypes.addAll(['Degasser', 'Desander', 'Desilter', 'Centrifuge']);
        }
        availableOtherSceTypes.assignAll(sceTypes.toList()..sort());
      }

      print('✅ Loaded available types: ${availableShakerTypes.length} shakers, ${availableOtherSceTypes.length} SCE types');
    } catch (e) {
      print('❌ Error loading available types: $e');
      // Set default types on error
      availableShakerTypes.assignAll(['Shaker', 'Cleaner', 'Degasser']);
      availableOtherSceTypes.assignAll(['Degasser', 'Desander', 'Desilter', 'Centrifuge']);
    }
  }

  // Get all available shaker types from API
  Future<List<String>> getAvailableShakerTypes() async {
    try {
      final result = await repository.getShakers(currentWellId ?? '');
      if (result['success']) {
        final List<dynamic> shakerData = result['data'] ?? [];
        final Set<String> types = {};
        for (var shaker in shakerData) {
          if (shaker['shaker'] != null && shaker['shaker'].toString().isNotEmpty) {
            types.add(shaker['shaker'].toString());
          }
        }
        if (types.isEmpty) {
          return ['Shaker', 'Cleaner', 'Degasser'];
        }
        return types.toList()..sort();
      }
      return ['Shaker', 'Cleaner', 'Degasser'];
    } catch (e) {
      print('Error fetching shaker types: $e');
      return ['Shaker', 'Cleaner', 'Degasser'];
    }
  }

  // Get shaker data by type
  Future<Map<String, dynamic>?> getShakerDataByType(String type) async {
    try {
      final result = await repository.getShakers(currentWellId ?? '');
      if (result['success']) {
        final List<dynamic> shakerData = result['data'] ?? [];
        return shakerData.firstWhere(
          (shaker) => shaker['shaker'] == type,
          orElse: () => null,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching shaker data: $e');
      return null;
    }
  }

  // Get all available other SCE types from API
  Future<List<String>> getAvailableOtherSceTypes() async {
    try {
      final result = await repository.getOtherSce(currentWellId ?? '');
      if (result['success']) {
        final List<dynamic> sceData = result['data'] ?? [];
        final Set<String> types = {};
        for (var sce in sceData) {
          if (sce['type'] != null && sce['type'].toString().isNotEmpty) {
            types.add(sce['type'].toString());
          }
        }
        if (types.isEmpty) {
          return ['Degasser', 'Desander', 'Desilter', 'Centrifuge'];
        }
        return types.toList()..sort();
      }
      return ['Degasser', 'Desander', 'Desilter', 'Centrifuge'];
    } catch (e) {
      print('Error fetching other SCE types: $e');
      return ['Degasser', 'Desander', 'Desilter', 'Centrifuge'];
    }
  }

  // Get other SCE data by type
  Future<Map<String, dynamic>?> getOtherSceDataByType(String type) async {
    try {
      final result = await repository.getOtherSce(currentWellId ?? '');
      if (result['success']) {
        final List<dynamic> sceData = result['data'] ?? [];
        return sceData.firstWhere(
          (sce) => sce['type'] == type,
          orElse: () => null,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching other SCE data: $e');
      return null;
    }
  }
}