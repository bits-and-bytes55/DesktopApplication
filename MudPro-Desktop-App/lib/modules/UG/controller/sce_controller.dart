import 'dart:async';

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
  final isSavingShakers = false.obs;
  final isSavingOtherSce = false.obs;
  final Map<int, Timer> _shakerAutosaveTimers = {};
  final Map<int, Timer> _otherSceAutosaveTimers = {};
  final Set<int> _dirtyShakerRows = <int>{};
  final Set<int> _dirtyOtherSceRows = <int>{};
  Future<void>? _flushFuture;

  // ✅ FIX: maxScreenCols — driven by "No. of Screen" field from SCE data
  // Default 8 (all enabled). Updated when SCE data is loaded.
  final _maxScreenCols = 8.obs;
  int get maxScreenCols => _maxScreenCols.value;

  String? currentWellId = currentBackendWellId.isEmpty
      ? null
      : currentBackendWellId;

  static const List<String> shakerLabels = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'Mud Cleaner',
    'Dryer',
  ];

  static String displayShakerLabel(String value) {
    final text = value.trim();
    final number = int.tryParse(text);
    if (number != null && number >= 1 && number <= 10) {
      return 'Shaker $number';
    }
    return text;
  }

  static bool isStandardShakerLabel(String value) {
    final text = value.trim();
    final number = int.tryParse(text);
    if (number != null && number >= 1 && number <= 10) return true;

    final lower = text.toLowerCase();
    if (!lower.startsWith('shaker ')) return false;
    final shakerNumber = int.tryParse(lower.replaceFirst('shaker ', '').trim());
    return shakerNumber != null && shakerNumber >= 1 && shakerNumber <= 10;
  }

  bool _plotValue(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
  static const List<String> otherSceLabels = [
    'Degasser',
    'Desander',
    'Desilter',
    'Centrifuge',
    'Barite Rec.',
  ];

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

  @override
  void onClose() {
    for (final timer in _shakerAutosaveTimers.values) {
      timer.cancel();
    }
    for (final timer in _otherSceAutosaveTimers.values) {
      timer.cancel();
    }
    super.onClose();
  }

  Future<void> flushPendingAutosaves() {
    final activeFlush = _flushFuture;
    if (activeFlush != null) return activeFlush;

    final future = _flushPendingAutosavesNow();
    _flushFuture = future.whenComplete(() {
      _flushFuture = null;
    });
    return _flushFuture!;
  }

  Future<void> _flushPendingAutosavesNow() async {
    final hasPendingChanges =
        _dirtyShakerRows.isNotEmpty || _dirtyOtherSceRows.isNotEmpty;
    _dirtyShakerRows.clear();
    _dirtyOtherSceRows.clear();

    for (final timer in _shakerAutosaveTimers.values) {
      timer.cancel();
    }
    for (final timer in _otherSceAutosaveTimers.values) {
      timer.cancel();
    }
    _shakerAutosaveTimers.clear();
    _otherSceAutosaveTimers.clear();

    if (!hasPendingChanges) return;

    for (var index = 0; index < shakers.length; index++) {
      final shaker = shakers[index];
      if (!shaker.hasData) continue;
      await saveShaker(index);
    }

    for (var index = 0; index < otherSce.length; index++) {
      final sce = otherSce[index];
      if (sce.type.value.trim().isEmpty && index < otherSceLabels.length) {
        sce.type.value = otherSceLabels[index];
      }
      if (!sce.hasData) continue;
      await saveOtherSce(index);
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

  void refreshAvailableTypesFromCurrentRows() {
    final shakerTypes = <String>{};
    final shakerModels = <String>{};
    for (final shaker in shakers) {
      if (!shaker.plot.value || !shaker.hasData) continue;
      if (!isStandardShakerLabel(shaker.shaker.value)) continue;
      final label = displayShakerLabel(shaker.shaker.value);
      if (label.isNotEmpty) shakerTypes.add(label);
      final model = shaker.model.value.trim();
      if (model.isNotEmpty) shakerModels.add(model);
    }

    final sceTypes = <String>{};
    final sceModels = <String>{};
    for (final sce in otherSce) {
      if (!sce.plot.value || !sce.hasData) continue;
      final type = sce.type.value.trim();
      if (type.isNotEmpty) sceTypes.add(type);
      final model = sce.model1.value.trim();
      if (model.isNotEmpty) sceModels.add(model);
    }

    availableShakerTypes.assignAll(shakerTypes.toList()..sort());
    availableShakerModels.assignAll(shakerModels.toList()..sort());
    availableOtherSceTypes.assignAll(sceTypes.toList()..sort());
    availableOtherSceModels.assignAll(sceModels.toList()..sort());
  }

  // ================= LOAD DATA =================

  Future<void> loadSceData(String wellId) async {
    try {
      await flushPendingAutosaves();
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
      final result = await repository.getShakers(
        wellId,
        includeReportId: false,
      );
      if (result['success']) {
        final List<dynamic> shakerData = _mergeDuplicateRows(
          result['data'] ?? [],
          keyField: 'shaker',
          mergeFields: const [
            'model',
            'screens',
            'screen1',
            'screen2',
            'screen3',
            'screen4',
            'screen5',
            'screen6',
            'screen7',
            'screen8',
            'time',
            'oocWt',
          ],
        );

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
    if (_maxScreenCols.value == 0) {
      _maxScreenCols.value = 8; // default all enabled
    }
  }

  Future<void> loadOtherSce(String wellId) async {
    try {
      final result = await repository.getOtherSce(
        wellId,
        includeReportId: false,
      );
      if (result['success']) {
        final List<dynamic> sceData = _mergeDuplicateRows(
          result['data'] ?? [],
          keyField: 'type',
          mergeFields: const [
            'model1',
            'model2',
            'model3',
            'uf',
            'of',
            'time',
            'oocWt',
          ],
        );

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

  List<Map<String, dynamic>> _mergeDuplicateRows(
    List<dynamic> rows, {
    required String keyField,
    required List<String> mergeFields,
  }) {
    final merged = <String, Map<String, dynamic>>{};

    for (final raw in rows) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final key = item[keyField]?.toString().trim() ?? '';
      if (key.isEmpty) continue;

      final current = merged[key];
      if (current == null) {
        merged[key] = item;
        continue;
      }

      current['_id'] = item['_id'] ?? current['_id'];
      current['id'] = item['id'] ?? current['id'];
      current[keyField] = key;
      current['plot'] = current['plot'] == true || item['plot'] == true;

      for (final field in mergeFields) {
        final next = item[field]?.toString() ?? '';
        if (next.trim().isNotEmpty) {
          current[field] = next;
        }
      }
    }

    return merged.values.toList(growable: false);
  }

  // ================= SHAKER OPERATIONS =================

  Map<String, dynamic>? _extractEntity(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  void _applySavedShaker(ShakerModel target, dynamic rawData) {
    final data = _extractEntity(rawData);
    final savedId = (data?['_id'] ?? data?['id'])?.toString();
    if (savedId != null && savedId.isNotEmpty) {
      target.id = savedId;
    }
  }

  void _applySavedOtherSce(OtherSceModel target, dynamic rawData) {
    final data = _extractEntity(rawData);
    final savedId = (data?['_id'] ?? data?['id'])?.toString();
    if (savedId != null && savedId.isNotEmpty) {
      target.id = savedId;
    }
  }

  Future<void> saveShaker(int index) async {
    if (currentWellId == null) return;
    try {
      final shaker = shakers[index];
      if (!shaker.hasData) return;
      isSavingShakers.value = true;

      final result = await repository.createShaker(
        currentWellId!,
        shaker.toJson(),
        includeReportId: false,
      );

      if (result['success']) {
        _applySavedShaker(shaker, result['data']);
        shaker.isEditing.value = false;
      }
    } catch (e) {
      print('❌ Error saving shaker: $e');
    } finally {
      isSavingShakers.value = false;
    }
  }

  Future<void> deleteShaker(int index) async {
    final shaker = shakers[index];
    if (shaker.id == null) {
      resetShakerRow(index);
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

      isSavingShakers.value = true;
      final result = await repository.deleteShaker(shaker.id!);
      if (result['success']) {
        resetShakerRow(index);
      }
    } catch (e) {
      print('❌ Error deleting shaker: $e');
    } finally {
      isSavingShakers.value = false;
    }
  }

  void enableShakerEditMode(int index) => shakers[index].isEditing.value = true;

  void cancelShakerEdit(int index) {
    shakers[index].isEditing.value = false;
    if (shakers[index].id != null && currentWellId != null) {
      loadSceData(currentWellId!);
    }
  }

  void resetShakerRow(int index) {
    _shakerAutosaveTimers[index]?.cancel();
    _shakerAutosaveTimers.remove(index);
    _dirtyShakerRows.remove(index);
    final label = index < shakerLabels.length
        ? shakerLabels[index]
        : shakers[index].shaker.value;
    shakers[index] = ShakerModel(shaker: label);
  }

  void scheduleShakerAutosave(int index) {
    if (index < 0 || index >= shakers.length || currentWellId == null) return;
    refreshAvailableTypesFromCurrentRows();
    _dirtyShakerRows.add(index);
    _shakerAutosaveTimers[index]?.cancel();
    _shakerAutosaveTimers[index] = Timer(
      const Duration(milliseconds: 850),
      () async {
        await flushPendingAutosaves();
      },
    );
  }

  // ================= OTHER SCE OPERATIONS =================

  Future<void> saveOtherSce(int index) async {
    if (currentWellId == null) return;
    try {
      final sce = otherSce[index];
      if (sce.type.value.trim().isEmpty && index < otherSceLabels.length) {
        sce.type.value = otherSceLabels[index];
      }
      if (!sce.hasData) return;
      isSavingOtherSce.value = true;

      final result = await repository.createOtherSce(
        currentWellId!,
        sce.toJson(),
        includeReportId: false,
      );

      if (result['success']) {
        _applySavedOtherSce(sce, result['data']);
        sce.isEditing.value = false;
      }
    } catch (e) {
      print('❌ Error saving other SCE: $e');
    } finally {
      isSavingOtherSce.value = false;
    }
  }

  Future<void> deleteOtherSce(int index) async {
    final sce = otherSce[index];
    if (sce.id == null) {
      resetOtherSceRow(index);
      return;
    }

    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete SCE'),
          content: const Text(
            'Are you sure you want to delete this SCE equipment?',
          ),
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

      isSavingOtherSce.value = true;
      final result = await repository.deleteOtherSce(sce.id!);
      if (result['success']) {
        resetOtherSceRow(index);
      }
    } catch (e) {
      print('❌ Error deleting other SCE: $e');
    } finally {
      isSavingOtherSce.value = false;
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

  void resetOtherSceRow(int index) {
    _otherSceAutosaveTimers[index]?.cancel();
    _otherSceAutosaveTimers.remove(index);
    _dirtyOtherSceRows.remove(index);
    final label = index < otherSceLabels.length
        ? otherSceLabels[index]
        : otherSce[index].type.value;
    otherSce[index] = OtherSceModel(type: label);
  }

  void scheduleOtherSceAutosave(int index) {
    if (index < 0 || index >= otherSce.length || currentWellId == null) return;
    refreshAvailableTypesFromCurrentRows();
    _dirtyOtherSceRows.add(index);
    _otherSceAutosaveTimers[index]?.cancel();
    _otherSceAutosaveTimers[index] = Timer(
      const Duration(milliseconds: 850),
      () async {
        await flushPendingAutosaves();
      },
    );
  }

  // ================= GETTERS =================

  int get shakerCount => shakers.where((s) => s.hasData).length;
  int get otherSceCount => otherSce.where((s) => s.hasData).length;

  // ================= LOAD AVAILABLE TYPES & MODELS =================

  Future<void> loadAvailableTypes(String wellId) async {
    try {
      // Load shakers
      final shakerResult = await repository.getShakers(
        wellId,
        includeReportId: false,
      );
      if (shakerResult['success']) {
        final List<dynamic> shakerData = shakerResult['data'] ?? [];

        final Set<String> shakerTypes = {};
        final Set<String> shakerModels = {};

        for (var shaker in shakerData) {
          if (!_plotValue(shaker['plot'])) continue;
          if (!isStandardShakerLabel(shaker['shaker']?.toString() ?? '')) {
            continue;
          }
          if (shaker['shaker'] != null &&
              shaker['shaker'].toString().isNotEmpty) {
            shakerTypes.add(displayShakerLabel(shaker['shaker'].toString()));
          }
          if (shaker['model'] != null &&
              shaker['model'].toString().isNotEmpty) {
            shakerModels.add(shaker['model'].toString());
          }
        }

        availableShakerTypes.assignAll(shakerTypes.toList()..sort());
        availableShakerModels.assignAll(shakerModels.toList()..sort());
      }

      // Load other SCE
      final sceResult = await repository.getOtherSce(
        wellId,
        includeReportId: false,
      );
      if (sceResult['success']) {
        final List<dynamic> sceData = sceResult['data'] ?? [];

        final Set<String> sceTypes = {};
        final Set<String> sceModels = {};

        for (var sce in sceData) {
          if (!_plotValue(sce['plot'])) continue;
          if (sce['type'] != null && sce['type'].toString().isNotEmpty) {
            sceTypes.add(sce['type'].toString());
          }
          if (sce['model1'] != null && sce['model1'].toString().isNotEmpty) {
            sceModels.add(sce['model1'].toString());
          }
        }

        availableOtherSceTypes.assignAll(sceTypes.toList()..sort());
        availableOtherSceModels.assignAll(sceModels.toList()..sort());
      }

      print(
        '✅ Loaded available types: ${availableShakerTypes.length} shakers, ${availableOtherSceTypes.length} SCE types',
      );
      print(
        '✅ Loaded available models: ${availableShakerModels.length} shaker models, ${availableOtherSceModels.length} SCE models',
      );
    } catch (e) {
      print('❌ Error loading available types: $e');
      availableShakerTypes.assignAll(['Shaker', 'Cleaner', 'Degasser']);
      availableOtherSceTypes.assignAll([
        'Degasser',
        'Desander',
        'Desilter',
        'Centrifuge',
      ]);
    }
  }

  // ── Lookup by TYPE ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getShakerDataByType(String type) async {
    try {
      final result = await repository.getShakers(
        currentWellId ?? '',
        includeReportId: false,
      );
      if (result['success']) {
        final List<dynamic> shakerData = result['data'] ?? [];
        return shakerData.firstWhere(
          (shaker) =>
              _plotValue(shaker['plot']) &&
              isStandardShakerLabel(shaker['shaker']?.toString() ?? '') &&
              (shaker['shaker'] == type ||
                  displayShakerLabel(shaker['shaker']?.toString() ?? '') ==
                      type),
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
      final result = await repository.getOtherSce(
        currentWellId ?? '',
        includeReportId: false,
      );
      if (result['success']) {
        final List<dynamic> sceData = result['data'] ?? [];
        return sceData.firstWhere(
          (sce) => _plotValue(sce['plot']) && sce['type'] == type,
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
      final result = await repository.getShakers(
        currentWellId ?? '',
        includeReportId: false,
      );
      if (result['success']) {
        final List<dynamic> shakerData = result['data'] ?? [];
        return shakerData.firstWhere(
          (shaker) =>
              _plotValue(shaker['plot']) &&
              isStandardShakerLabel(shaker['shaker']?.toString() ?? '') &&
              shaker['model'] == model,
          orElse: () => null,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching shaker data by model: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOtherSceDataByModel(String model) async {
    try {
      final result = await repository.getOtherSce(
        currentWellId ?? '',
        includeReportId: false,
      );
      if (result['success']) {
        final List<dynamic> sceData = result['data'] ?? [];
        return sceData.firstWhere(
          (sce) => _plotValue(sce['plot']) && sce['model1'] == model,
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
