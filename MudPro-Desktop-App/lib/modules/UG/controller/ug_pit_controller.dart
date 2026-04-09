import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';

// ── Transfer Mud Row Data ────
class TransferRowData {
  String pitName = '';
  String volume = '';
  String? savedId;        // The parent document _id
  String? transferItemId; // The individual transfer item _id inside transfers[]
  final TextEditingController volumeController = TextEditingController();
  Timer? _debounce;

  TransferRowData({this.pitName = '', this.volume = '', this.savedId, this.transferItemId}) {
    volumeController.text = volume;
  }

  Map<String, dynamic> toTransferMap(bool notTreated) {
    return {
      'pitName': pitName,
      'volume': double.tryParse(volume) ?? 0.0,
      'notTreatedMud': notTreated,
    };
  }

  void dispose() {
    _debounce?.cancel();
    volumeController.dispose();
  }
}

// Static well ID
const String kControllerWellId = '67f1a2b3c4d5e6f7890a1111';

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

  @override
  void onInit() {
    super.onInit();
    // Use static well ID; override if passed via arguments
    currentWellId =
        Get.arguments?['wellId'] ?? kControllerWellId;
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
    if (currentWellId == null) {
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
    if (currentWellId == null) return;

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
    if (currentWellId == null) return;

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
    if (currentWellId == null) {
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
        capacity: pitModel?.capacity?.value,
        initialActive: pitModel?.initialActive?.value,
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
        capacity: pitModel?.capacity?.value ?? 0,
        initialActive: pitModel?.initialActive?.value ?? true,
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
    if (currentWellId == null) return;
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
          capacity: pitModel?.capacity?.value ?? 0,
          initialActive: pitModel?.initialActive?.value ?? true,
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
    if (currentWellId == null) return;
    isLoadingTransfer.value = true;
    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getTransferMud(currentWellId!);
      if (result['success'] == true) {
        // backend returns { success, count, data: [ { _id, from, transfers:[{pitName,volume,_id}], ... } ] }
        final raw = result['data'];
        final List records = (raw is Map && raw['data'] is List)
            ? raw['data']
            : (raw is List ? raw : []);

        for (var r in transferRows) r.dispose();
        transferRows.clear();

        for (var doc in records) {
          // Each document has a transfers array
          final from = doc['from']?.toString() ?? '';
          final docId = doc['_id']?.toString();
          final List transfers = doc['transfers'] is List ? doc['transfers'] : [];

          for (var t in transfers) {
            transferRows.add(TransferRowData(
              pitName: t['pitName']?.toString() ?? '',
              volume: (t['volume'] ?? 0).toString(),
              savedId: docId,
              transferItemId: t['_id']?.toString(),
            ));
          }

          // Store from for the document
          if (transfers.isNotEmpty && from.isNotEmpty) {
            selectedFromPit.value = from;
          }
        }

        // Always maintain at least 5 rows
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
    if (currentWellId == null) return {'success': false, 'message': 'Well ID missing'};

    final authRepo = AuthRepository();
    int successCount = 0;
    int failCount = 0;

    final unsavedRows = transferRows.where((r) => r.pitName.isNotEmpty && r.savedId == null).toList();

    if (unsavedRows.isEmpty) {
      return {'success': true, 'message': 'No new transfers to save'};
    }

    try {
      final payload = {
        'wellId': currentWellId!,
        'from': selectedFromPit.value,
        'transfers': unsavedRows.map((r) => r.toTransferMap(notTreatedMud.value)).toList(),
      };
      
      final result = await authRepo.createTransferMud(currentWellId!, payload);
      
      if (result['success'] == true) {
        // Mark all as saved - bulk success
        // Note: Backend ideally returns the new transfers with IDs
        // If not, we just mark them locally saved so we don't save twice.
        for (var row in unsavedRows) {
          row.savedId = "SAVED_${DateTime.now().millisecondsSinceEpoch}";
        }
        transferRows.refresh();
        return {
          'success': true, 
          'message': 'Saved ${unsavedRows.length} transfers successfully'
        };
      } else {
        return {
          'success': false, 
          'message': result['message'] ?? 'Failed to save transfers'
        };
      }
    } catch (e) {
      debugPrint('Error saving transfer mud batch: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }


  /// Called when volume changes inline on a saved row — debounced PUT
  void onTransferVolumeChanged(int index, String newVolume) {
    if (index >= transferRows.length) return;
    final row = transferRows[index];
    row.volume = newVolume;
    row._debounce?.cancel();
    row._debounce = Timer(const Duration(milliseconds: 1500), () {
      _updateTransferMudRow(row);
    });
  }

  Future<void> _updateTransferMudRow(TransferRowData row) async {
    if (row.savedId == null || currentWellId == null) return;
    if (row.pitName.isEmpty) return;
    try {
      final authRepo = AuthRepository();
      final body = {
        'from': selectedFromPit.value,
        'transfers': [{
          'pitName': row.pitName,
          'volume': double.tryParse(row.volume) ?? 0.0,
        }],
      };
      final res = await authRepo.updateTransferMud(currentWellId!, row.savedId!, body);
      if (res['success'] == true) {
        debugPrint('✅ Transfer Mud row updated: ${row.pitName}');
      } else {
        debugPrint('❌ Failed to update transfer row: ${res["message"]}');
      }
    } catch (e) {
      debugPrint('Error updating transfer mud row: $e');
    }
  }


  void checkAndAddTransferRow() {
    final lastRow = transferRows.lastOrNull;
    if (lastRow != null && lastRow.pitName.isNotEmpty) {
      transferRows.add(TransferRowData());
    }
  }

  Future<void> deleteTransferRow(int index) async {
    if (index >= transferRows.length) return;
    final row = transferRows[index];

    if (row.savedId != null) {
      try {
        final authRepo = AuthRepository();
        final res = await authRepo.deleteTransferMud(currentWellId!, row.savedId!);
        if (res['success'] != true) {
          _showAlert('Failed to delete: ${res["message"]}', isError: true);
          return;
        }
        debugPrint('✅ Transfer Mud deleted: ${row.savedId}');
      } catch (e) {
        _showAlert('Error deleting transfer: $e', isError: true);
        return;
      }
    }

    row.dispose();
    transferRows.removeAt(index);
    while (transferRows.length < 5) {
      transferRows.add(TransferRowData());
    }
    transferRows.refresh();
  }

  @override
  void onClose() {
    for (var row in transferRows) {
      row.dispose();
    }
    super.onClose();
  }
}