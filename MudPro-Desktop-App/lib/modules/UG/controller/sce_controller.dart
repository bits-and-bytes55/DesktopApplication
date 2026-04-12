import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import '../model/sce_model.dart';
import './UG_controller.dart';

class SceController extends GetxController {
  final AuthRepository repository = AuthRepository();

  UgController get ugController => Get.find<UgController>();

  final shakers = <ShakerModel>[].obs;
  final otherSce = <OtherSceModel>[].obs;

  // Dedicated lists for Pump/Operation page to keep them independent from Setup
  final operationShakers = <ShakerModel>[].obs;
  final operationOtherSce = <OtherSceModel>[].obs;

  // Available types from API
  final availableShakerTypes = <String>[].obs;
  final availableOtherSceTypes = <String>[].obs;

  // Available models from API
  final availableShakerModels = <String>[].obs;
  final availableOtherSceModels = <String>[].obs;

  final isLoading = false.obs;

  // ✅ FIX: maxScreenCols — driven by "No. of Screen" field from SCE data
  // Default 8 (all enabled). Updated when SCE data is loaded.
  final _maxScreenCols = 8.obs;
  int get maxScreenCols => _maxScreenCols.value;

  String? currentWellId = currentBackendWellId.isEmpty ? null : currentBackendWellId;

  static const List<String> shakerLabels = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
    'Mud Cleaner', 'Dryer',
  ];
  static const List<String> otherSceLabels = [
    'Degasser',
    'Desander',
    'Desilter',
    'Centrifuge',
    'Barite Rec.',
  ];

  static const int MIN_SHAKER_ROWS = 12; // Matches label count
  static const int MIN_OTHER_SCE_ROWS = 5; // Matches label count

  @override
  void onInit() {
    super.onInit();
    initializeEmptyShakers();
    initializeEmptyOtherSce();
    initializeOperationLists();
    if (currentWellId != null && currentWellId!.isNotEmpty) {
      loadAvailableTypes(currentWellId!);
    }
  }

  // ================= INITIALIZATION =================

  void initializeEmptyShakers() {
    shakers.clear();
    for (var label in shakerLabels) {
      shakers.add(ShakerModel(shaker: label));
    }
  }

  void initializeEmptyOtherSce() {
    otherSce.clear();
    for (var label in otherSceLabels) {
      otherSce.add(OtherSceModel(type: label));
    }
  }

  void initializeOperationLists() {
    operationShakers.clear();
    for (int i = 0; i < 10; i++) {
      operationShakers.add(ShakerModel(shaker: ''));
    }
    operationOtherSce.clear();
    for (int i = 0; i < 10; i++) {
      operationOtherSce.add(OtherSceModel(type: ''));
    }
  }

  // ================= LOAD DATA =================

  Future<void> loadSceData(String wellId) async {
    try {
      isLoading.value = true;
      currentWellId = wellId;

      await Future.wait([
        loadShakers(wellId),
        loadOtherSce(wellId),
        loadAvailableTypes(wellId),
      ]);
    } catch (e) {
      print('❌ Error loading SCE data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadShakers(String wellId) async {
    try {
      final result = await repository.getShakers(wellId);
      if (result['success']) {
        final List<dynamic> shakerData = result['data'] ?? [];
        
        // Reset to empty with labels first
        initializeEmptyShakers();
        
        // Populate existing ones by matching shaker label
        for (var data in shakerData) {
          final label = data['shaker']?.toString() ?? '';
          final idx = shakers.indexWhere((s) => s.shaker.value == label);
          if (idx != -1) {
            shakers[idx] = ShakerModel.fromJson(data);
          } else {
            // If it's a custom shaker not in our labels, add it
            shakers.add(ShakerModel.fromJson(data));
          }
        }

        // ✅ Update maxScreenCols from loaded data
        _updateMaxScreenCols(shakerData);
      } else {
        initializeEmptyShakers();
      }
    } catch (e) {
      print('❌ Error loading shakers: $e');
      initializeEmptyShakers();
    }
  }

  /// Reads 'screens' field from API data to determine how many screen cols are active
  void _updateMaxScreenCols(List<dynamic> shakerData) {
    int maxCols = 0;
    for (var shaker in shakerData) {
      final screens = int.tryParse(shaker['screens']?.toString() ?? '') ?? 0;
      if (screens > maxCols) maxCols = screens;
    }
    // Clamp between 0 and 8
    _maxScreenCols.value = maxCols.clamp(0, 8);
    if (_maxScreenCols.value == 0) _maxScreenCols.value = 8; // default all enabled
  }

  Future<void> loadOtherSce(String wellId) async {
    try {
      final result = await repository.getOtherSce(wellId);
      if (result['success']) {
        final List<dynamic> sceData = result['data'] ?? [];
        
        // Reset to empty with labels
        initializeEmptyOtherSce();
        
        for (var data in sceData) {
          final label = data['type']?.toString() ?? '';
          final idx = otherSce.indexWhere((s) => s.type.value == label);
          if (idx != -1) {
            otherSce[idx] = OtherSceModel.fromJson(data);
          } else {
            // If it's a custom SCE type not in our labels, add it
            otherSce.add(OtherSceModel.fromJson(data));
          }
        }
      } else {
        initializeEmptyOtherSce();
      }
    } catch (e) {
      print('❌ Error loading other SCE: $e');
      initializeEmptyOtherSce();
    }
  }

  // ================= SHAKER OPERATIONS =================

  Future<void> saveShaker(int index) async {
    if (currentWellId == null) return;
    try {
      final shaker = shakers[index];
      if (!shaker.hasData) return;
      isLoading.value = true;

      Map<String, dynamic> result;
      if (shaker.id != null) {
        result = (await repository.updateShaker(shaker.id!, shaker.toJson())) as Map<String, dynamic>;
      } else {
        result =
            (await repository.createShaker(currentWellId!, shaker.toJson())) as Map<String, dynamic>;
      }

      if (result['success']) {
        final updatedShaker = ShakerModel.fromJson(result['data']);
        shakers[index] = updatedShaker;
        shaker.isEditing.value = false;
        checkAndAddShakerRow();
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
      shakers[index] = ShakerModel(shaker: shaker.shaker.value);
      return;
    }

    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Shaker'),
          content:
              const Text('Are you sure you want to delete this shaker?'),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Get.back(result: true),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete')),
          ],
        ),
      );
      if (confirmed != true) return;

      isLoading.value = true;
      final result = await repository.deleteShaker(shaker.id!);
      if (result['success']) {
        shakers[index] = ShakerModel(shaker: shaker.shaker.value);
      }
    } catch (e) {
      print('❌ Error deleting shaker: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void enableShakerEditMode(int index) =>
      shakers[index].isEditing.value = true;

  void cancelShakerEdit(int index) {
    shakers[index].isEditing.value = false;
    if (shakers[index].id != null && currentWellId != null) {
      loadSceData(currentWellId!);
    }
  }

  void checkAndAddShakerRow() {
    if (shakers.isNotEmpty && shakers.last.hasData) {
      shakers.add(ShakerModel(shaker: ''));
    }
  }

  // ================= OTHER SCE OPERATIONS =================

  Future<void> saveOtherSce(int index) async {
    if (currentWellId == null) return;
    try {
      final sce = otherSce[index];
      if (!sce.hasData) return;
      isLoading.value = true;

      Map<String, dynamic> result;
      if (sce.id != null) {
        result = (await repository.updateOtherSce(sce.id!, sce.toJson())) as Map<String, dynamic>;
      } else {
        result =
            (await repository.createOtherSce(currentWellId!, sce.toJson())) as Map<String, dynamic>;
      }

      if (result['success']) {
        final updatedSce = OtherSceModel.fromJson(result['data']);
        otherSce[index] = updatedSce;
        sce.isEditing.value = false;
        checkAndAddOtherSceRow();
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
          content: const Text(
              'Are you sure you want to delete this SCE equipment?'),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Get.back(result: true),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete')),
          ],
        ),
      );
      if (confirmed != true) return;

      isLoading.value = true;
      final result = await repository.deleteOtherSce(sce.id!);
      if (result['success']) {
        otherSce[index] = OtherSceModel();
      }
    } catch (e) {
      print('❌ Error deleting other SCE: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void enableOtherSceEditMode(int index) =>
      otherSce[index].isEditing.value = true;

  void cancelOtherSceEdit(int index) {
    otherSce[index].isEditing.value = false;
    if (otherSce[index].id != null && currentWellId != null) {
      loadSceData(currentWellId!);
    }
  }

  void checkAndAddOtherSceRow() {
    if (otherSce.isNotEmpty && otherSce.last.hasData) {
      otherSce.add(OtherSceModel());
    }
  }

  // ================= GETTERS =================

  int get shakerCount => shakers.where((s) => s.hasData).length;
  int get otherSceCount => otherSce.where((s) => s.hasData).length;

  // ================= LOAD AVAILABLE TYPES & MODELS =================

  Future<void> loadAvailableTypes(String wellId) async {
    try {
      // Load shakers
      final shakerResult = await repository.getShakers(wellId);
      if (shakerResult['success']) {
        final List<dynamic> shakerData = shakerResult['data'] ?? [];

        final Set<String> shakerTypes = {};
        final Set<String> shakerModels = {};

        for (var shaker in shakerData) {
          if (shaker['shaker'] != null &&
              shaker['shaker'].toString().isNotEmpty) {
            shakerTypes.add(shaker['shaker'].toString());
          }
          if (shaker['model'] != null &&
              shaker['model'].toString().isNotEmpty) {
            shakerModels.add(shaker['model'].toString());
          }
        }

        if (shakerTypes.isEmpty) {
          shakerTypes.addAll(['Shaker', 'Cleaner', 'Degasser']);
        }

        availableShakerTypes.assignAll(shakerTypes.toList()..sort());
        availableShakerModels.assignAll(shakerModels.toList()..sort());
      }

      // Load other SCE
      final sceResult = await repository.getOtherSce(wellId);
      if (sceResult['success']) {
        final List<dynamic> sceData = sceResult['data'] ?? [];

        final Set<String> sceTypes = {};
        final Set<String> sceModels = {};

        for (var sce in sceData) {
          if (sce['type'] != null && sce['type'].toString().isNotEmpty) {
            sceTypes.add(sce['type'].toString());
          }
          if (sce['model1'] != null &&
              sce['model1'].toString().isNotEmpty) {
            sceModels.add(sce['model1'].toString());
          }
        }

        if (sceTypes.isEmpty) {
          sceTypes.addAll(
              ['Degasser', 'Desander', 'Desilter', 'Centrifuge']);
        }

        availableOtherSceTypes.assignAll(sceTypes.toList()..sort());
        availableOtherSceModels.assignAll(sceModels.toList()..sort());
      }

      print(
          '✅ Loaded available types: ${availableShakerTypes.length} shakers, ${availableOtherSceTypes.length} SCE types');
      print(
          '✅ Loaded available models: ${availableShakerModels.length} shaker models, ${availableOtherSceModels.length} SCE models');
    } catch (e) {
      print('❌ Error loading available types: $e');
      availableShakerTypes.assignAll(['Shaker', 'Cleaner', 'Degasser']);
      availableOtherSceTypes
          .assignAll(['Degasser', 'Desander', 'Desilter', 'Centrifuge']);
    }
  }

  // ── Lookup by TYPE ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getShakerDataByType(String type) async {
    try {
      final result =
          await repository.getShakers(currentWellId ?? '');
      if (result['success']) {
        final List<dynamic> shakerData = result['data'] ?? [];
        return shakerData.firstWhere(
          (shaker) => shaker['shaker'] == type,
          orElse: () => null,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching shaker data by type: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOtherSceDataByType(String type) async {
    try {
      final result =
          await repository.getOtherSce(currentWellId ?? '');
      if (result['success']) {
        final List<dynamic> sceData = result['data'] ?? [];
        return sceData.firstWhere(
          (sce) => sce['type'] == type,
          orElse: () => null,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching other SCE data by type: $e');
      return null;
    }
  }

  // ── Lookup by MODEL ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getShakerDataByModel(String model) async {
    try {
      final result =
          await repository.getShakers(currentWellId ?? '');
      if (result['success']) {
        final List<dynamic> shakerData = result['data'] ?? [];
        return shakerData.firstWhere(
          (shaker) => shaker['model'] == model,
          orElse: () => null,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching shaker data by model: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOtherSceDataByModel(
      String model) async {
    try {
      final result =
          await repository.getOtherSce(currentWellId ?? '');
      if (result['success']) {
        final List<dynamic> sceData = result['data'] ?? [];
        return sceData.firstWhere(
          (sce) => sce['model1'] == model,
          orElse: () => null,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching other SCE data by model: $e');
      return null;
    }
  }

  // ── Legacy helpers ───────────────────────────────────────────────────────

  Future<List<String>> getAvailableShakerTypes() async {
    return availableShakerTypes.toList();
  }

  Future<List<String>> getAvailableOtherSceTypes() async {
    return availableOtherSceTypes.toList();
  }

  // ✅ Get screens count by model from loaded shaker data
  int getScreensByModel(String model) {
    if (model.isEmpty) return 8; // Default to all 8 if no model
    
    for (var shaker in shakers) {
      if (shaker.model.value == model && shaker.screens.value.isNotEmpty) {
        final screens = int.tryParse(shaker.screens.value) ?? 8;
        return screens.clamp(1, 8);
      }
    }
    return 8; // Default to all 8 if not found
  }
}
