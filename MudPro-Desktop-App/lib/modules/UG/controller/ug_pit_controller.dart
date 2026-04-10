import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
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
  final Map<String, Map<String, TextEditingController>> activePitControllers =
      {};

  // Track modified pits for single-pit update on global Save
  final Set<String> modifiedPitIds = {};

  Timer? _debounceTimer;
  Worker? _wellWorker;
  Worker? _reportWorker;

  bool get _hasWellId => currentWellId != null && currentWellId!.isNotEmpty;
  String? get _currentReportId {
    final reportId = reportContext.selectedReportId.value.trim();
    return reportId.isEmpty ? null : reportId;
  }

  List<PitModel> get activePitRows =>
      pits.where((pit) => pit.initialActive.value).toList();

  List<PitModel> get storagePitRows =>
      pits.where((pit) => !pit.initialActive.value).toList();

  @override
  void onInit() {
    super.onInit();
    currentWellId = Get.arguments?['wellId'] ?? kControllerWellId;
    _wellWorker = ever<String>(padWellContext.selectedWellId, (wellId) {
      if (wellId.isEmpty || wellId == currentWellId) return;
      currentWellId = wellId;
      fetchAllPits();
      fetchVolumeNameData();
      fetchTransferMud();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      if (!_hasWellId) return;
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
      final result = await authRepo.getAllPits(
        currentWellId!,
        reportId: _currentReportId,
      );

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null) {
          if (data is List) {
            final allPits = data.isNotEmpty && data.first is PitModel
                ? List<PitModel>.from(data)
                : data
                      .map(
                        (item) =>
                            PitModel.fromJson(item as Map<String, dynamic>),
                      )
                      .toList();
            pits.value = allPits;
            _disposePitControllers();
          } else {
            pits.clear();
            _disposePitControllers();
          }
        } else {
          pits.clear();
          _disposePitControllers();
        }

        totalCapacity.value = _calculateDouble(result['totalCapacity']);
        _updateSeparatedLists();
        _ensureDraftRows();
      } else {
        _showAlert(result['message'] ?? 'Failed to fetch pits', isError: true);
        _ensureDraftRows();
      }
    } catch (e) {
      debugPrint('Error fetching pits: $e');
      _showAlert('Error fetching pits', isError: true);
      _ensureDraftRows();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSelectedPits() async {
    if (!_hasWellId) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getSelectedPits(
        currentWellId!,
        reportId: _currentReportId,
      );

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null && data is List) {
          final allPits = data.isNotEmpty && data.first is PitModel
              ? List<PitModel>.from(data)
              : data
                    .map(
                      (item) => PitModel.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
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
      final result = await authRepo.getUnselectedPits(
        currentWellId!,
        reportId: _currentReportId,
      );

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null && data is List) {
          final allPits = data.isNotEmpty && data.first is PitModel
              ? List<PitModel>.from(data)
              : data
                    .map(
                      (item) => PitModel.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
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
        .where(
          (pit) =>
              pit.id == null &&
              pit.pitName.isNotEmpty &&
              pit.capacity.value > 0,
        )
        .map(
          (pit) => {
            'pitName': pit.pitName,
            'capacity': pit.capacity.value,
            'initialActive': pit.initialActive.value,
            'volume': pit.volume?.value ?? 0.0,
            'density': pit.density?.value ?? 0.0,
            'fluidType': pit.fluidType?.value ?? '',
          },
        )
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
        reportId: _currentReportId,
      );

      if (result['success'] == true) {
        _showAlert(
          '${newPits.length} pit(s) saved successfully',
          isError: false,
        );
        await fetchAllPits();
      } else {
        _showAlert(result['message'] ?? 'Failed to save pits', isError: true);
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
      final pitModel =
          pits.firstWhereOrNull((p) => p.id == pitId) ??
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
        reportId: _currentReportId,
      );

      if (result['success'] == true) {
        debugPrint('Master pit $pitId updated successfully');
        final savedPit = result['data'] as PitModel?;
        if (savedPit != null && savedPit.id != null && savedPit.id != pitId) {
          if (activePitControllers.containsKey(pitId)) {
            activePitControllers[savedPit.id!] = activePitControllers.remove(
              pitId,
            )!;
          }
          if (modifiedPitIds.remove(pitId)) {
            modifiedPitIds.add(savedPit.id!);
          }
          if (pitModel != null) {
            pitModel.id = savedPit.id;
            pitModel.reportId = savedPit.reportId;
          }
        }
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
        reportId: _currentReportId,
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
        _showAlert(
          result['message'] ?? 'Failed to update pit volume',
          isError: true,
        );
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
      final result = await authRepo.getVolumeNameCalculation(
        currentWellId!,
        reportId: _currentReportId,
      );
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

  Map<String, TextEditingController> getPitCtrl(
    String pitId, {
    String pitName = '',
    double vol = 0,
    double density = 0,
    String fluid = '',
  }) {
    if (!activePitControllers.containsKey(pitId)) {
      activePitControllers[pitId] = {
        'pitName': TextEditingController(text: pitName),
        'volume': TextEditingController(text: vol.toStringAsFixed(2)),
        'density': TextEditingController(text: density.toStringAsFixed(2)),
        'fluidType': TextEditingController(text: fluid),
      };
    }
    return activePitControllers[pitId]!;
  }

  // Refined: Update only modified pits individually via PUT /pit/:id
  Future<Map<String, dynamic>> saveAllActivePits() async {
    if (!_hasWellId) {
      return {'success': false, 'message': 'Well ID is required'};
    }

    final List<String> errors = [];
    final authRepo = AuthRepository();
    int successCount = 0;

    final draftPits = pits
        .where((pit) => pit.id == null && _isDraftFilled(pit))
        .map(
          (pit) => {
            'pitName': pit.pitName.trim(),
            'capacity': _draftCapacity(pit),
            'initialActive': pit.initialActive.value,
            'volume': pit.volume?.value ?? 0,
            'density': pit.density?.value ?? 0,
            'fluidType': pit.fluidType?.value ?? '',
          },
        )
        .toList();

    if (draftPits.isNotEmpty) {
      try {
        final result = await authRepo.bulkAddPits(
          pits: draftPits,
          wellId: currentWellId!,
          reportId: _currentReportId,
        );
        if (result['success'] == true) {
          successCount += draftPits.length;
          await fetchAllPits();
        } else {
          errors.add(result['message'] ?? 'Failed to create pit rows');
        }
      } catch (e) {
        errors.add('Failed to create pit rows: $e');
      }
    }

    if (modifiedPitIds.isEmpty && draftPits.isEmpty) {
      return {'success': true, 'message': 'No changes to save'};
    }

    // Create a copy to iterate to avoid concurrent modification issues
    final idsToUpdate = List<String>.from(modifiedPitIds);

    for (final pitId in idsToUpdate) {
      if (pitId.isEmpty) continue;

      final ctrls = activePitControllers[pitId];
      if (ctrls == null) continue;

      // Find the pit model across all lists to get its name & latest config
      final pitModel =
          pits.firstWhereOrNull((p) => p.id == pitId) ??
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
          reportId: _currentReportId,
        );

        if (result['success'] == true) {
          successCount++;
          modifiedPitIds.remove(pitId);
          final savedPit = result['data'] as PitModel?;
          if (savedPit != null && savedPit.id != null && pitModel != null) {
            pitModel.id = savedPit.id;
            pitModel.reportId = savedPit.reportId;
          }

          // Update local model
          if (pitModel != null) {
            pitModel.volume?.value =
                double.tryParse(ctrls['volume']!.text) ?? 0;
            pitModel.density?.value =
                double.tryParse(ctrls['density']!.text) ?? 0;
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
      return {
        'success': true,
        'message': 'All $successCount pits updated successfully',
      };
    } else {
      return {
        'success': successCount > 0,
        'message': 'Pits: $successCount saved, ${errors.length} failed',
        'errors': errors,
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
        reportId: _currentReportId,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    selectedPits.value = pits
        .where((p) => p.id != null && p.initialActive.value)
        .toList();
    unselectedPits.value = pits
        .where((p) => p.id != null && !p.initialActive.value)
        .toList();
    _updateCapacities();
  }

  void _updateCapacities() {
    totalCapacity.value = pits
        .where((pit) => pit.id != null)
        .fold(0.0, (sum, pit) => sum + pit.capacity.value);
  }

  void updateDraftPit({
    required PitModel pit,
    String? pitName,
    double? volume,
    double? density,
    String? fluidType,
  }) {
    if (pit.id != null) return;

    if (pitName != null) {
      pit.pitName = pitName;
    }
    if (volume != null) {
      pit.volume?.value = volume;
      if (pit.capacity.value <= 0 || pit.capacity.value.isNaN) {
        pit.capacity.value = volume;
      } else if (volume > pit.capacity.value) {
        pit.capacity.value = volume;
      }
    }
    if (density != null) {
      pit.density?.value = density;
    }
    if (fluidType != null) {
      pit.fluidType?.value = fluidType;
    }

    pits.refresh();
    _ensureDraftRows();
  }

  String controllerKeyForPit(PitModel pit, String section, int index) {
    if (pit.id != null && pit.id!.isNotEmpty) {
      return pit.id!;
    }
    return '$section-draft-$index';
  }

  bool isDraftPit(PitModel pit) => pit.id == null;

  void _ensureDraftRows() {
    final hasActiveDraft = pits.any(
      (pit) => pit.id == null && pit.initialActive.value && _isBlankDraft(pit),
    );
    final hasStorageDraft = pits.any(
      (pit) => pit.id == null && !pit.initialActive.value && _isBlankDraft(pit),
    );

    if (!hasActiveDraft) {
      pits.add(PitModel(pitName: '', capacity: 0.0, initialActive: true));
    }

    if (!hasStorageDraft) {
      pits.add(PitModel(pitName: '', capacity: 0.0, initialActive: false));
    }
  }

  bool _isBlankDraft(PitModel pit) {
    return pit.pitName.trim().isEmpty &&
        pit.capacity.value == 0 &&
        (pit.volume?.value ?? 0) == 0 &&
        (pit.density?.value ?? 0) == 0 &&
        (pit.fluidType?.value ?? '').trim().isEmpty;
  }

  bool _isDraftFilled(PitModel pit) {
    return pit.pitName.trim().isNotEmpty &&
        ((pit.volume?.value ?? 0) > 0 || pit.capacity.value > 0);
  }

  double _draftCapacity(PitModel pit) {
    final volume = pit.volume?.value ?? 0;
    if (pit.capacity.value > 0) {
      return pit.capacity.value >= volume ? pit.capacity.value : volume;
    }
    return volume;
  }

  void _disposePitControllers() {
    for (final ctrls in activePitControllers.values) {
      for (final ctrl in ctrls.values) {
        ctrl.dispose();
      }
    }
    activePitControllers.clear();
  }

  void onRowFilled(int index) {
    final pit = pits[index];
    if (pit.id == null && pit.pitName.isNotEmpty && pit.capacity.value > 0) {
      pits.add(PitModel(pitName: '', capacity: 0.0, initialActive: false));
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
      final result = await authRepo.getTransferMud(
        currentWellId!,
        reportId: _currentReportId,
      );
      if (result['success'] == true) {
        final List data = result['data'] is List
            ? result['data']
            : (result['data']['data'] ?? []);

        for (var r in transferRows) {
          r.volumeController.dispose();
        }
        transferRows.clear();

        for (var item in data) {
          final transfers = (item['transfers'] as List? ?? []);
          if (transfers.isEmpty) {
            transferRows.add(
              TransferRowData(
                pitName: '',
                volume: '',
                savedId: item['_id']?.toString(),
              ),
            );
            continue;
          }

          for (final transfer in transfers) {
            transferRows.add(
              TransferRowData(
                pitName: transfer['pitName']?.toString() ?? '',
                volume: transfer['volume']?.toString() ?? '',
                savedId: item['_id']?.toString(),
              ),
            );
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
    final filledRows = transferRows.where((r) => r.pitName.isNotEmpty).toList();

    if (filledRows.isEmpty) {
      return {'success': true, 'message': 'No transfers to save'};
    }

    try {
      int successCount = 0;
      final List<String> errors = [];

      for (final row in filledRows) {
        final payload = {
          'wellId': currentWellId!,
          'from': selectedFromPit.value,
          'transfers': [row.toTransferMap(notTreatedMud.value)],
        };

        final result = row.savedId == null
            ? await authRepo.createTransferMud(
                currentWellId!,
                payload,
                reportId: _currentReportId,
              )
            : await authRepo.updateTransferMud(
                currentWellId!,
                row.savedId!,
                payload,
                reportId: _currentReportId,
              );

        if (result['success'] == true) {
          final savedEnvelope = result['data'];
          final saved = savedEnvelope is Map ? savedEnvelope['data'] : null;
          final parsedId = saved is Map ? saved['_id']?.toString() : null;
          row.savedId = parsedId ?? row.savedId;
          successCount++;
        } else {
          errors.add(result['message']?.toString() ?? 'Unknown transfer error');
        }
      }

      transferRows.refresh();
      await fetchTransferMud();
      await fetchAllPits();
      await fetchVolumeNameData();

      return {
        'success': errors.isEmpty,
        'message': errors.isEmpty
            ? 'Saved $successCount transfers successfully'
            : 'Saved/updated $successCount transfers, ${errors.length} failed',
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
        final res = await authRepo.deleteTransferMud(
          currentWellId!,
          row.savedId!,
          reportId: _currentReportId,
        );
        if (res['success'] != true) {
          _showAlert(
            'Failed to delete transfer: ${res['message']}',
            isError: true,
          );
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
    await fetchTransferMud();
    await fetchAllPits();
    await fetchVolumeNameData();
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
    _reportWorker?.dispose();
    _disposePitControllers();
    for (var row in transferRows) {
      row.volumeController.dispose();
    }
    super.onClose();
  }
}
