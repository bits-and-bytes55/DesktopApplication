import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

// ── Transfer Mud Row Data ────
class TransferRowData {
  String pitName = '';
  String volume = '';
  String? savedId;
  final TextEditingController volumeController = TextEditingController();

  TransferRowData({this.pitName = '', this.volume = '', this.savedId}) {
    volumeController.text = volume;
  }

  Map<String, dynamic> toTransferMap(bool notTreated) {
    return {
      'pitName': pitName,
      'volume': double.tryParse(volume) ?? 0.0,
      'notTreatedMud': notTreated,
    };
  }
}

String get kControllerWellId => currentBackendWellId;

class PitController extends GetxController {
  final isLoading = false.obs;
  final isSaving = false.obs;
  final pits = <PitModel>[].obs;
  final selectedPits = <PitModel>[].obs;
  final unselectedPits = <PitModel>[].obs;

  // Transfer Mud State
  final transferRows = <TransferRowData>[].obs;
  final isLoadingTransfer = false.obs;
  final notTreatedMud = false.obs;
  final selectedFromPit = 'Active System'.obs;
  final selectedRowIndex = 0.obs;

  final totalCapacity = 0.0.obs;

  String? currentWellId;

  // UI state migrated from PitPage for global Save access
  final RxMap<String, dynamic> volumeNameData = <String, dynamic>{}.obs;
  final RxBool isLoadingVolume = false.obs;
  final Map<String, Map<String, TextEditingController>> activePitControllers = {};
  
  // Track modified pits for single-pit update on global Save
  final Set<String> modifiedPitIds = {};
  
  Timer? _debounceTimer;
  Worker? _wellWorker;

  bool get _hasWellId => currentWellId != null && currentWellId!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    currentWellId =
        Get.arguments?['wellId'] ?? kControllerWellId;
    _wellWorker = ever<String>(padWellContext.selectedWellId, (wellId) {
      if (wellId.isEmpty || wellId == currentWellId) return;
      currentWellId = wellId;
      fetchAllPits();
      fetchVolumeNameData();
      fetchTransferMud();
    });
    fetchAllPits();
    fetchVolumeNameData();
    // Initialize Transfer Mud
    _initializeTransferRows();
    fetchTransferMud();
  }

  void _initializeTransferRows() {
    if (transferRows.isEmpty) {
      for (int i = 0; i < 5; i++) {
        transferRows.add(TransferRowData());
      }
    }
  }

  // ================= FETCH OPERATIONS =================

  Future<void> fetchAllPits() async {
    if (!_hasWellId) {
      _showAlert('Well ID is required', isError: true);
      return;
    }

    isLoading.value = true;
    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getAllPits(currentWellId!);

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null) {
          if (data is List) {
            final allPits = data.isNotEmpty && data.first is PitModel
                ? List<PitModel>.from(data)
                : data.map((item) => PitModel.fromJson(item as Map<String, dynamic>)).toList();
            pits.value = allPits;
          } else {
            pits.clear();
          }
        } else {
          pits.clear();
        }

        totalCapacity.value = _calculateDouble(result['totalCapacity']);
        _updateSeparatedLists();
        _ensureEmptyRow();
      } else {
        _showAlert(result['message'] ?? 'Failed to fetch pits',
            isError: true);
        _ensureEmptyRow();
      }
    } catch (e) {
      debugPrint('Error fetching pits: $e');
      _showAlert('Error fetching pits', isError: true);
      _ensureEmptyRow();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSelectedPits() async {
    if (!_hasWellId) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getSelectedPits(currentWellId!);

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null && data is List) {
          final allPits = data.isNotEmpty && data.first is PitModel
              ? List<PitModel>.from(data)
              : data.map((item) => PitModel.fromJson(item as Map<String, dynamic>)).toList();
          selectedPits.value = allPits;
        } else {
          selectedPits.clear();
        }
      }
    } catch (e) {
      debugPrint('Error fetching selected pits: $e');
    }
  }

  Future<void> fetchUnselectedPits() async {
    if (!_hasWellId) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getUnselectedPits(currentWellId!);

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null && data is List) {
          final allPits = data.isNotEmpty && data.first is PitModel
              ? List<PitModel>.from(data)
              : data.map((item) => PitModel.fromJson(item as Map<String, dynamic>)).toList();
          unselectedPits.value = allPits;
        } else {
          unselectedPits.clear();
        }
      }
    } catch (e) {
      debugPrint('Error fetching unselected pits: $e');
    }
  }

  // _filterLatestPits method removed 

  // ================= BULK SAVE NEW PITS =================

  Future<void> bulkSavePits() async {
    if (!_hasWellId) {
      _showAlert('Well ID is required', isError: true);
      return;
    }

    final newPits = pits
        .where((pit) =>
            pit.id == null &&
            pit.pitName.isNotEmpty &&
            pit.capacity.value > 0)
        .map((pit) => {
              'pitName': pit.pitName,
              'capacity': pit.capacity.value,
              'initialActive': pit.initialActive.value,
              'volume': pit.volume?.value ?? 0.0,
              'density': pit.density?.value ?? 0.0,
              'fluidType': pit.fluidType?.value ?? '',
            })
        .toList();

    if (newPits.isEmpty) {
      _showAlert('No new pits to save', isError: true);
      return;
    }

    isSaving.value = true;
    try {
      final authRepo = AuthRepository();
      final result = await authRepo.bulkAddPits(
        pits: newPits,
        wellId: currentWellId!,
      );

      if (result['success'] == true) {
        _showAlert('${newPits.length} pit(s) saved successfully',
            isError: false);
        await fetchAllPits();
      } else {
        _showAlert(result['message'] ?? 'Failed to save pits',
            isError: true);
      }
    } catch (e) {
      debugPrint('Error saving pits: $e');
      _showAlert('Error saving pits', isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  // ================= UPDATE ACTIVE PIT VOLUME DATA =================

  /// Called on every keystroke with a debounce to update the master pit record (PUT)
  void onPitFieldChanged({
    required String pitId,
    required double volume,
    required double density,
    required String fluidType,
  }) {
    _debounceTimer?.cancel();
    
    // Mark as modified immediately
    if (pitId.isNotEmpty) {
      modifiedPitIds.add(pitId);
    }

    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      updatePitMaster(
        pitId: pitId,
        volume: volume,
        density: density,
        fluidType: fluidType,
      );
    });
  }

  /// Updates the master pit record via PUT /pit/:id (No new records created)
  Future<void> updatePitMaster({
    required String pitId,
    required double volume,
    required double density,
    required String fluidType,
  }) async {
    if (pitId.isEmpty) return;
    try {
      final authRepo = AuthRepository();
      // Find the pit model context
      final pitModel = pits.firstWhereOrNull((p) => p.id == pitId) ??
                      selectedPits.firstWhereOrNull((p) => p.id == pitId) ??
                      unselectedPits.firstWhereOrNull((p) => p.id == pitId);
      
      final result = await authRepo.updatePit(
        id: pitId,
        pitName: pitModel?.pitName,
        capacity: pitModel?.capacity.value,
        initialActive: pitModel?.initialActive.value,
        volume: volume,
        density: density,
        fluidType: fluidType,
      );

      if (result['success'] == true) {
        debugPrint('Master pit $pitId updated successfully');
        // Update local model values if different
        if (pitModel != null) {
          pitModel.volume?.value = volume;
          pitModel.density?.value = density;
          pitModel.fluidType?.value = fluidType;
          pits.refresh();
        }
      }
    } catch (e) {
      debugPrint('Error in updatePitMaster: $e');
    }
  }

  /// Called from save button to trigger calculation (POST)
  Future<void> updatePitVolumeData({
    required String pitId,
    required double volume,
    required double density,
    required String fluidType,
  }) async {
    try {
      final authRepo = AuthRepository();

      // Find the pit model to get its name & other details (required by backend)
      final pitModel = pits.firstWhereOrNull((p) => p.id == pitId);
      final String pitName = pitModel?.pitName ?? 'Unknown Pit';

      final result = await authRepo.updatePitVolumeData(
        id: pitId,
        wellId: currentWellId ?? kControllerWellId,
        pitName: pitName,
        volume: volume,
        density: density,
        fluidType: fluidType,
        capacity: pitModel?.capacity.value ?? 0,
        initialActive: pitModel?.initialActive.value ?? true,
      );
      if (result['success'] == true) {
        // Update local model
        final idx = pits.indexWhere((p) => p.id == pitId);
        if (idx != -1) {
          pits[idx].volume?.value = volume;
          pits[idx].density?.value = density;
          pits[idx].fluidType?.value = fluidType;
          pits.refresh();
          _updateSeparatedLists();
        }
      } else {
        _showAlert(result['message'] ?? 'Failed to update pit volume',
            isError: true);
      }
    } catch (e) {
      debugPrint('Error updating pit volume: $e');
      _showAlert('Error updating pit volume', isError: true);
    }
  }

  // ================= NEW VOLUME NAME & SAVE DATA =================
  Future<void> fetchVolumeNameData() async {
    if (!_hasWellId) return;
    isLoadingVolume.value = true;
    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getVolumeNameCalculation(currentWellId!);
      if (result['success'] == true) {
        final inner = result['data'];
        // auth_repo wraps the raw JSON as result['data'], so the actual
        // calculation payload is at inner['data']
        final payload = (inner is Map && inner['data'] != null)
            ? Map<String, dynamic>.from(inner['data'])
            : Map<String, dynamic>.from(inner ?? {});
        
        // Duplication filters removed to display all database records correctly
        
        volumeNameData.value = payload;
      }
    } catch (e) {
      debugPrint('Error fetching volume name: $e');
    } finally {
      isLoadingVolume.value = false;
    }
  }

  Map<String, TextEditingController> getPitCtrl(String pitId,
      {double vol = 0, double density = 0, String fluid = ''}) {
    if (!activePitControllers.containsKey(pitId)) {
      activePitControllers[pitId] = {
        'volume': TextEditingController(
            text: vol.toStringAsFixed(2)),
        'density': TextEditingController(
            text: density.toStringAsFixed(2)),
        'fluidType': TextEditingController(text: fluid),
      };
    } else {
      // Refresh values from latest API data so UI stays up to date after refetch
      final existing = activePitControllers[pitId]!;
      existing['volume']!.text = vol.toStringAsFixed(2);
      existing['density']!.text = density.toStringAsFixed(2);
      existing['fluidType']!.text = fluid;
    }
    return activePitControllers[pitId]!;
  }

  // Refined: Update only modified pits individually via PUT /pit/:id
  Future<Map<String, dynamic>> saveAllActivePits() async {
    if (modifiedPitIds.isEmpty) {
      return {'success': true, 'message': 'No changes to save'};
    }

    final List<String> errors = [];
    final authRepo = AuthRepository();
    int successCount = 0;
    
    // Create a copy to iterate to avoid concurrent modification issues
    final idsToUpdate = List<String>.from(modifiedPitIds);
    
    for (final pitId in idsToUpdate) {
      if (pitId.isEmpty) continue;

      final ctrls = activePitControllers[pitId];
      if (ctrls == null) continue;

      // Find the pit model across all lists to get its name & latest config
      final pitModel = pits.firstWhereOrNull((p) => p.id == pitId) ??
                      selectedPits.firstWhereOrNull((p) => p.id == pitId) ??
                      unselectedPits.firstWhereOrNull((p) => p.id == pitId);
                      
      final String pitName = pitModel?.pitName ?? 'Unknown Pit';

      try {
        // Hit the single-pit update API (PUT /pit/:id) as requested
        final result = await authRepo.updatePit(
          id: pitId,
          pitName: pitName,
          volume: double.tryParse(ctrls['volume']!.text) ?? 0,
          density: double.tryParse(ctrls['density']!.text) ?? 0,
          fluidType: ctrls['fluidType']!.text,
          capacity: pitModel?.capacity.value ?? 0,
          initialActive: pitModel?.initialActive.value ?? true,
        );

        if (result['success'] == true) {
          successCount++;
          modifiedPitIds.remove(pitId);
          
          // Update local model
          if (pitModel != null) {
            pitModel.volume?.value = double.tryParse(ctrls['volume']!.text) ?? 0;
            pitModel.density?.value = double.tryParse(ctrls['density']!.text) ?? 0;
            pitModel.fluidType?.value = ctrls['fluidType']!.text;
          }
        } else {
          errors.add('Pit "$pitName" update failed: ${result['message']}');
        }
      } catch (e) {
        errors.add('Pit "$pitName" update error: $e');
      }
    }
    
    // Refresh both master list and calculations summary to ensure UI reflects the latest state
    await fetchAllPits();
    await fetchVolumeNameData();
    pits.refresh();
    
    if (errors.isEmpty) {
      return {'success': true, 'message': 'All $successCount pits updated successfully'};
    } else {
      return {
        'success': successCount > 0, 
        'message': 'Pits: $successCount saved, ${errors.length} failed',
        'errors': errors
      };
    }
  }

  // ================= UPDATE OPERATIONS =================

  Future<void> togglePitActive(PitModel pit) async {
    if (pit.id == null) return;

    final newStatus = !pit.initialActive.value;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.updatePit(
        id: pit.id!,
        initialActive: newStatus,
      );

      if (result['success'] == true) {
        _showAlert('Status updated', isError: false);
        await fetchAllPits();
      } else {
        _showAlert(result['message'] ?? 'Failed to update', isError: true);
      }
    } catch (e) {
      debugPrint('Error toggling status: $e');
      _showAlert('Error updating status', isError: true);
    }
  }

  // ================= DELETE OPERATIONS =================

  Future<void> deletePit(PitModel pit) async {
    if (pit.id == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Pit'),
        content: Text('Delete "${pit.pitName}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.deletePit(pit.id!);

      if (result['success'] == true) {
        _showAlert('Pit deleted', isError: false);
        await fetchAllPits();
      } else {
        _showAlert(result['message'] ?? 'Failed to delete', isError: true);
      }
    } catch (e) {
      debugPrint('Error deleting pit: $e');
      _showAlert('Error deleting', isError: true);
    }
  }

  // ================= HELPER METHODS =================

  void _updateSeparatedLists() {
    selectedPits.value =
        pits.where((p) => p.id != null && p.initialActive.value).toList();
    unselectedPits.value =
        pits.where((p) => p.id != null && !p.initialActive.value).toList();
    _updateCapacities();
  }

  void _updateCapacities() {
    totalCapacity.value = pits
        .where((pit) => pit.id != null)
        .fold(0.0, (sum, pit) => sum + pit.capacity.value);
  }

  void _ensureEmptyRow() {
    final hasEmptyRow = pits.any(
        (p) => p.id == null && p.pitName.isEmpty && p.capacity.value == 0);

    if (!hasEmptyRow) {
      pits.add(PitModel(
        pitName: '',
        capacity: 0.0,
        initialActive: false,
      ));
    }
  }

  void onRowFilled(int index) {
    final pit = pits[index];
    if (pit.id == null &&
        pit.pitName.isNotEmpty &&
        pit.capacity.value > 0) {
      pits.add(PitModel(
        pitName: '',
        capacity: 0.0,
        initialActive: false,
      ));
    }
  }

  bool isRowFilled(PitModel pit) {
    return pit.pitName.isNotEmpty && pit.capacity.value > 0;
  }

  double _calculateDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void showError(String message) => debugPrint('Error: $message');
  void showSuccess(String message) => debugPrint('Success: $message');

  void _showAlert(String message, {bool isError = false}) {
    if (isError) {
      showError(message);
    } else {
      showSuccess(message);
    }
  }

  // ================= TRANSFER MUD OPERATIONS =================

  Future<void> fetchTransferMud() async {
    if (!_hasWellId) return;
    isLoadingTransfer.value = true;
    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getTransferMud(currentWellId!);
      if (result['success'] == true) {
        final List data = result['data'] is List ? result['data'] : (result['data']['data'] ?? []);
        
        for (var r in transferRows) {
          r.volumeController.dispose();
        }
        transferRows.clear();

        for (var item in data) {
          final transfers = (item['transfers'] as List? ?? []);
          if (transfers.isEmpty) {
            transferRows.add(TransferRowData(
              pitName: '',
              volume: '',
              savedId: item['_id']?.toString(),
            ));
            continue;
          }

          for (final transfer in transfers) {
            transferRows.add(TransferRowData(
              pitName: transfer['pitName']?.toString() ?? '',
              volume: transfer['volume']?.toString() ?? '',
              savedId: item['_id']?.toString(),
            ));
          }
        }

        while (transferRows.length < 5) {
          transferRows.add(TransferRowData());
        }
        transferRows.refresh();
      }
    } catch (e) {
      debugPrint('Error fetching transfer mud: $e');
    } finally {
      isLoadingTransfer.value = false;
    }
  }

  Future<Map<String, dynamic>> saveTransferMud() async {
    if (!_hasWellId) return {'success': false, 'message': 'Well ID missing'};

    final authRepo = AuthRepository();
    final unsavedRows = transferRows.where((r) => r.pitName.isNotEmpty && r.savedId == null).toList();

    if (unsavedRows.isEmpty) {
      return {'success': true, 'message': 'No new transfers to save'};
    }

    try {
      int successCount = 0;
      final List<String> errors = [];

      for (final row in unsavedRows) {
        final payload = {
          'wellId': currentWellId!,
          'from': selectedFromPit.value,
          'transfers': [row.toTransferMap(notTreatedMud.value)],
        };

        final result = await authRepo.createTransferMud(currentWellId!, payload);

        if (result['success'] == true) {
          final saved = result['data'];
          row.savedId = saved is Map ? saved['_id']?.toString() : null;
          successCount++;
        } else {
          errors.add(result['message']?.toString() ?? 'Unknown transfer error');
        }
      }

      transferRows.refresh();

      return {
        'success': errors.isEmpty,
        'message': errors.isEmpty
            ? 'Saved $successCount transfers successfully'
            : 'Saved $successCount transfers, ${errors.length} failed',
        if (errors.isNotEmpty) 'errors': errors,
      };
    } catch (e) {
      debugPrint('Error saving transfer mud batch: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<void> deleteTransferRow(int index) async {
    if (index >= transferRows.length) return;

    final row = transferRows[index];
    if (row.savedId != null) {
      if (!_hasWellId) {
        _showAlert('Well ID missing', isError: true);
        return;
      }
      try {
        final authRepo = AuthRepository();
        final res =
            await authRepo.deleteTransferMud(currentWellId!, row.savedId!);
        if (res['success'] != true) {
          _showAlert('Failed to delete transfer: ${res['message']}', isError: true);
          return;
        }
      } catch (e) {
        _showAlert('Error deleting transfer: $e', isError: true);
        return;
      }
    }

    row.volumeController.dispose();
    transferRows.removeAt(index);
    
    while (transferRows.length < 5) {
      transferRows.add(TransferRowData());
    }
    transferRows.refresh();
  }

  void checkAndAddTransferRow() {
    if (transferRows.length >= 5) {
      final lastRow = transferRows.last;
      if (lastRow.pitName.isNotEmpty) {
        transferRows.add(TransferRowData());
      }
    }
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    for (var row in transferRows) {
      row.volumeController.dispose();
    }
    super.onClose();
  }
}
