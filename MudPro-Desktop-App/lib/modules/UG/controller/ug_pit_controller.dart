import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
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
      'pitName': pitName.trim(),
      'volume': double.tryParse(volume.trim().replaceAll(',', '')) ?? 0.0,
      'notTreatedMud': notTreated,
    };
  }
}

String get kControllerWellId => currentBackendWellId;

class PitController extends GetxController {
  static const int _minVisibleRows = 25;

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
  String _activeTransferOperationInstanceKey = '';

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
  Timer? _pitAutoSaveTimer;
  Timer? _transferAutoSaveTimer;
  final Map<String, Timer> _pitConfigUpdateTimers = {};
  bool _isApplyingTransferState = false;
  bool _isSavingTransferMud = false;
  bool _needsTransferMudResave = false;
  Worker? _wellWorker;
  Worker? _reportWorker;
  final List<Worker> _transferAutoSaveWorkers = <Worker>[];

  bool get _hasWellId => currentWellId != null && currentWellId!.isNotEmpty;
  bool get _hasTransferOperationInstance =>
      _activeTransferOperationInstanceKey.trim().isNotEmpty;

  List<PitModel> _filterPitsForSelectedReport(List<PitModel> source) => source;

  List<PitModel> get activePitRows =>
      pits.where((pit) => pit.initialActive.value).toList();

  List<PitModel> get storagePitRows => pits
      .where((pit) => !pit.initialActive.value && _isVisibleStoragePit(pit))
      .toList();

  bool get isTransferFromActiveSystem =>
      selectedFromPit.value.trim().toLowerCase() == 'active system';

  bool _isVisibleStoragePit(PitModel pit) {
    if (pit.id == null) {
      return _isDraftFilled(pit);
    }

    final name = pit.pitName.trim();
    if (name.isEmpty) return false;

    final hasValues =
        pit.capacity.value > 0 ||
        (pit.volume?.value ?? 0) > 0 ||
        (pit.density?.value ?? 0) > 0 ||
        (pit.fluidType?.value.trim().isNotEmpty ?? false);

    return name.toLowerCase() != 'pit' || hasValues;
  }

  List<String> get transferDestinationOptions {
    final options = <String>['Active System'];
    for (final pit in [...selectedPits, ...unselectedPits]) {
      final name = pit.pitName.trim();
      if (name.isNotEmpty && !options.contains(name)) {
        options.add(name);
      }
    }
    return options;
  }

  @override
  void onInit() {
    super.onInit();
    currentWellId = Get.arguments?['wellId'] ?? kControllerWellId;
    _initializeTransferRows();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (wellId) {
      if (wellId.isEmpty || wellId == currentWellId) return;
      _debounceTimer?.cancel();
      _pitAutoSaveTimer?.cancel();
      modifiedPitIds.clear();
      currentWellId = wellId;
      fetchAllPits();
      fetchVolumeNameData();
      if (_hasTransferOperationInstance) fetchTransferMud();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      _debounceTimer?.cancel();
      _pitAutoSaveTimer?.cancel();
      modifiedPitIds.clear();
      fetchVolumeNameData();
      if (_hasTransferOperationInstance) fetchTransferMud();
    });
    _transferAutoSaveWorkers.addAll([
      ever<String>(selectedFromPit, (_) => scheduleTransferMudAutoSave()),
      ever<bool>(notTreatedMud, (_) => scheduleTransferMudAutoSave()),
    ]);
    if (_hasWellId) {
      fetchAllPits();
      fetchVolumeNameData();
      if (_hasTransferOperationInstance) fetchTransferMud();
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _pitAutoSaveTimer?.cancel();
    _transferAutoSaveTimer?.cancel();
    for (final timer in _pitConfigUpdateTimers.values) {
      timer.cancel();
    }
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _transferAutoSaveWorkers) {
      worker.dispose();
    }
    for (final row in transferRows) {
      row.volumeController.dispose();
    }
    _disposePitControllers();
    super.onClose();
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
                : data
                      .map(
                        (item) =>
                            PitModel.fromJson(item as Map<String, dynamic>),
                      )
                      .toList();
            pits.value = _filterPitsForSelectedReport(allPits);
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
      final result = await authRepo.getSelectedPits(currentWellId!);

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
          selectedPits.value = _filterPitsForSelectedReport(allPits);
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
              : data
                    .map(
                      (item) => PitModel.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
          unselectedPits.value = _filterPitsForSelectedReport(allPits);
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
    schedulePitAutoSave();
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
      );

      if (result['success'] == true) {
        debugPrint('Master pit $pitId updated successfully');
        // Update local model values if different
        if (pitModel != null) {
          pitModel.volume?.value = volume;
          pitModel.density?.value = density;
          pitModel.fluidType?.value = fluidType;
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
  Future<void> fetchVolumeNameData({String? operationInstanceKey}) async {
    if (!_hasWellId) return;
    isLoadingVolume.value = true;
    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getVolumeNameCalculation(
        currentWellId!,
        operationInstanceKey: operationInstanceKey,
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
    bool syncExisting = false,
  }) {
    final volumeText = _displayNumber(vol);
    final densityText = _displayNumber(density);
    if (!activePitControllers.containsKey(pitId)) {
      activePitControllers[pitId] = {
        'pitName': TextEditingController(text: pitName),
        'volume': TextEditingController(text: volumeText),
        'density': TextEditingController(text: densityText),
        'fluidType': TextEditingController(text: fluid),
      };
    } else if (syncExisting &&
        !pitId.contains('-draft-') &&
        !modifiedPitIds.contains(pitId)) {
      final ctrls = activePitControllers[pitId]!;
      _syncControllerText(ctrls['pitName'], pitName);
      _syncControllerText(ctrls['volume'], volumeText);
      _syncControllerText(ctrls['density'], densityText);
      _syncControllerText(ctrls['fluidType'], fluid);
    }
    return activePitControllers[pitId]!;
  }

  String _displayNumber(double value) {
    if (value <= 0 || value.isNaN) return '';
    return formatOperationNumber(value);
  }

  void _syncControllerText(TextEditingController? ctrl, String value) {
    if (ctrl == null || ctrl.text == value) return;
    ctrl.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> prepareMeasuredVolumeReportCheck() async {
    _debounceTimer?.cancel();
    _pitAutoSaveTimer?.cancel();

    if (pits.where((pit) => pit.id != null).isEmpty) {
      await fetchAllPits();
    }

    if (_hasPendingPitChanges) {
      final result = await saveAllActivePits();
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Pit save failed');
      }
    } else {
      await fetchVolumeNameData();
    }
  }

  bool hasMeasuredVolumeReportWarning() {
    const tolerance = 0.005;
    final rows = storagePitRows;
    for (var index = 0; index < rows.length; index++) {
      final pit = rows[index];
      final calculated = storageCalculatedVolumeForPit(pit);
      final measuredText = _measuredVolumeTextForPit(pit, index);
      final measuredTextTrimmed = measuredText?.trim();

      if (measuredText != null && measuredTextTrimmed!.isEmpty) {
        if (calculated.abs() >= tolerance) return true;
        continue;
      }

      final measured = measuredText == null
          ? storageMeasuredVolumeForPit(pit)
          : _parseVolume(measuredTextTrimmed!);

      if ((measured - calculated).abs() >= tolerance) return true;
    }
    return false;
  }

  double storageCalculatedVolumeForPit(
    PitModel pit, {
    Map<String, dynamic>? volumeNameData,
  }) {
    final rows = (volumeNameData ?? this.volumeNameData)['storageTable'];
    if (rows is List) {
      final match = rows.cast<dynamic>().firstWhereOrNull((row) {
        if (row is! Map) return false;
        final id = row['_id']?.toString() ?? '';
        final name = row['pitName']?.toString().trim() ?? '';
        return (pit.id != null && id == pit.id) || name == pit.pitName.trim();
      });

      if (match is Map) {
        final calculatedVol = _calculateDouble(match['calculatedVol']);
        final measuredVol = _calculateDouble(
          match['measuredVol'] ?? pit.volume?.value,
        );
        final displayVol = _hasExplicitDistributionForPit(pit)
            ? calculatedVol
            : calculatedVol - measuredVol;
        return displayVol.abs() < 0.005 ? 0.0 : displayVol;
      }
    }

    return 0.0;
  }

  double storageMeasuredVolumeForPit(
    PitModel pit, {
    Map<String, dynamic>? volumeNameData,
  }) {
    final rows = (volumeNameData ?? this.volumeNameData)['storageTable'];
    if (rows is List) {
      final match = rows.cast<dynamic>().firstWhereOrNull((row) {
        if (row is! Map) return false;
        final id = row['_id']?.toString() ?? '';
        final name = row['pitName']?.toString().trim() ?? '';
        return (pit.id != null && id == pit.id) || name == pit.pitName.trim();
      });

      if (match is Map) {
        return _calculateDouble(match['measuredVol'] ?? match['volume']);
      }
    }

    return 0.0;
  }

  Map<dynamic, dynamic>? activeTableRowForPit(
    PitModel pit, {
    Map<String, dynamic>? volumeNameData,
  }) {
    final rows = (volumeNameData ?? this.volumeNameData)['activePitsTable'];
    if (rows is! List) return null;

    final pitId = pit.id?.trim() ?? '';
    final pitName = pit.pitName.trim().toLowerCase();

    return rows.cast<dynamic>().firstWhereOrNull((row) {
          if (row is! Map) return false;
          final rowId = row['_id']?.toString().trim() ?? '';
          final rowName = row['pitName']?.toString().trim().toLowerCase() ?? '';
          return (pitId.isNotEmpty && rowId == pitId) ||
              (pitName.isNotEmpty && rowName == pitName);
        })
        as Map<dynamic, dynamic>?;
  }

  double activeMeasuredVolumeForPit(
    PitModel pit, {
    Map<String, dynamic>? volumeNameData,
  }) {
    final row = activeTableRowForPit(pit, volumeNameData: volumeNameData);
    if (row == null) return 0.0;
    return _calculateDouble(row['measuredVol'] ?? row['volume']);
  }

  double activeMwForPit(PitModel pit, {Map<String, dynamic>? volumeNameData}) {
    final row = activeTableRowForPit(pit, volumeNameData: volumeNameData);
    if (row == null) return pit.density?.value ?? 0.0;
    return _calculateDouble(row['mw'] ?? row['density']);
  }

  String activeMudForPit(PitModel pit, {Map<String, dynamic>? volumeNameData}) {
    final row = activeTableRowForPit(pit, volumeNameData: volumeNameData);
    if (row == null) return pit.fluidType?.value ?? '';
    return (row['mud'] ?? row['fluidType'] ?? pit.fluidType?.value ?? '')
        .toString();
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
        final result = await authRepo.updatePitVolumeData(
          id: pitId,
          wellId: currentWellId!,
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

    // Keep text controllers intact during autosave; only refresh calculated summary.
    await fetchVolumeNameData();

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

  Future<Map<String, dynamic>> switchPitStatusWithVolume({
    required PitModel pit,
    required bool initialActive,
    double? volume,
  }) async {
    final pitId = pit.id?.trim() ?? '';
    if (pitId.isEmpty) {
      return {'success': false, 'message': 'Pit is not saved yet'};
    }

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.updatePit(
        id: pitId,
        pitName: pit.pitName.trim(),
        capacity: pit.capacity.value,
        initialActive: initialActive,
        volume: volume ?? pit.volume?.value,
        density: pit.density?.value,
        fluidType: pit.fluidType?.value,
      );

      if (result['success'] == true) {
        _showAlert(
          initialActive ? 'Moved to active pit' : 'Moved to storage',
          isError: false,
        );
        await fetchAllPits();
        await fetchVolumeNameData();
      } else {
        _showAlert(result['message'] ?? 'Failed to update pit', isError: true);
      }

      return result;
    } catch (e) {
      debugPrint('Error switching pit status: $e');
      _showAlert('Error updating pit', isError: true);
      return {'success': false, 'message': 'Error updating pit'};
    }
  }

  void schedulePitConfigSave(PitModel pit) {
    final pitId = pit.id?.trim() ?? '';
    if (pitId.isEmpty) {
      schedulePitAutoSave();
      return;
    }

    _pitConfigUpdateTimers[pitId]?.cancel();
    _pitConfigUpdateTimers[pitId] = Timer(
      const Duration(milliseconds: 800),
      () async {
        try {
          final authRepo = AuthRepository();
          final result = await authRepo.updatePit(
            id: pitId,
            pitName: pit.pitName.trim(),
            capacity: pit.capacity.value,
            initialActive: pit.initialActive.value,
            volume: pit.volume?.value,
            density: pit.density?.value,
            fluidType: pit.fluidType?.value,
          );

          if (result['success'] == true) {
            final updated = result['data'];
            if (updated is PitModel) {
              final index = pits.indexWhere((item) => item.id == pitId);
              if (index != -1) {
                pits[index] = updated;
              }
            }
            _updateSeparatedLists();
            pits.refresh();
          }
        } catch (e) {
          debugPrint('Error saving pit config: $e');
        }
      },
    );
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
      _pitConfigUpdateTimers[pit.id!]?.cancel();
      _pitConfigUpdateTimers.remove(pit.id!);
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
    schedulePitAutoSave();
  }

  String controllerKeyForPit(PitModel pit, String section, int index) {
    if (pit.id != null && pit.id!.isNotEmpty) {
      return pit.id!;
    }
    return '$section-draft-$index';
  }

  String? _measuredVolumeTextForPit(PitModel pit, int index) {
    final key = controllerKeyForPit(pit, 'storage', index);
    return activePitControllers[key]?['volume']?.text;
  }

  double _parseVolume(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0.0;
  }

  bool _hasExplicitDistributionForPit(PitModel pit) {
    final distributionState = volumeNameData['consumeProductDistribution'];
    final distributionRows = distributionState is Map
        ? distributionState['distributions']
        : null;
    if (distributionRows is! List) return false;

    final pitName = pit.pitName.trim().toLowerCase();
    if (pitName.isEmpty) return false;

    return distributionRows.any((row) {
      if (row is! Map) return false;
      final rowPit = (row['pitName'] ?? '').toString().trim().toLowerCase();
      return rowPit == pitName && _calculateDouble(row['volume']) > 0;
    });
  }

  bool isDraftPit(PitModel pit) => pit.id == null;

  void _ensureDraftRows() {
    while (pits.length < _minVisibleRows) {
      pits.add(PitModel(pitName: '', capacity: 0.0, initialActive: false));
    }
  }

  bool _isDraftFilled(PitModel pit) {
    return pit.pitName.trim().isNotEmpty &&
        ((pit.volume?.value ?? 0) > 0 || pit.capacity.value > 0);
  }

  bool get _hasPendingPitChanges {
    final hasDraftChanges = pits.any(
      (pit) => pit.id == null && _isDraftFilled(pit),
    );
    return modifiedPitIds.isNotEmpty || hasDraftChanges;
  }

  void schedulePitAutoSave() {
    if (!_hasWellId) return;

    _pitAutoSaveTimer?.cancel();
    _pitAutoSaveTimer = Timer(const Duration(milliseconds: 1200), () async {
      if (isSaving.value || isLoading.value || !_hasPendingPitChanges) {
        return;
      }
      await saveAllActivePits();
    });
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
    if (index < 0 || index >= pits.length) return;
    _ensureDraftRows();
    pits.refresh();
  }

  bool isRowFilled(PitModel pit) {
    return pit.pitName.trim().isNotEmpty && pit.capacity.value > 0;
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

  Future<void> setTransferMudInstanceKey(String instanceKey) async {
    final nextKey = instanceKey.trim();
    if (nextKey.isEmpty) {
      clearTransferMudLocalState();
      _activeTransferOperationInstanceKey = '';
      return;
    }

    if (_activeTransferOperationInstanceKey == nextKey &&
        transferRows.isNotEmpty) {
      return;
    }

    _transferAutoSaveTimer?.cancel();
    if (_activeTransferOperationInstanceKey.isNotEmpty &&
        _hasTransferData &&
        !_isApplyingTransferState) {
      await saveTransferMud();
    }

    _activeTransferOperationInstanceKey = nextKey;
    clearTransferMudLocalState();
    if (_hasWellId) {
      await fetchTransferMud();
    }
  }

  Future<void> fetchTransferMud() async {
    _transferAutoSaveTimer?.cancel();
    if (!_hasWellId) return;
    final instanceKey = _activeTransferOperationInstanceKey.trim();
    if (instanceKey.isEmpty) {
      clearTransferMudLocalState();
      return;
    }
    isLoadingTransfer.value = true;
    _isApplyingTransferState = true;
    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getTransferMud(
        currentWellId!,
        operationInstanceKey: instanceKey,
      );
      if (result['success'] == true) {
        final List data = result['data'] is List
            ? result['data']
            : (result['data']['data'] ?? []);
        String? detectedSource;

        for (var r in transferRows) {
          r.volumeController.dispose();
        }
        transferRows.clear();

        for (var item in data) {
          final itemKey = (item['operationInstanceKey'] ?? '')
              .toString()
              .trim();
          final isLegacyFirst =
              itemKey.isEmpty && instanceKey == 'transferMud::legacy0';
          if (itemKey != instanceKey && !isLegacyFirst) continue;
          detectedSource ??= item['from']?.toString().trim();
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
                volume: formatOperationInputText(
                  transfer['volume']?.toString() ?? '',
                  trimFallback: true,
                ),
                savedId: item['_id']?.toString(),
              ),
            );
          }
        }

        while (transferRows.length < 5) {
          transferRows.add(TransferRowData());
        }
        if ((detectedSource ?? '').isNotEmpty) {
          selectedFromPit.value = detectedSource!;
        }
        transferRows.refresh();
      }
    } catch (e) {
      debugPrint('Error fetching transfer mud: $e');
    } finally {
      _isApplyingTransferState = false;
      isLoadingTransfer.value = false;
    }
  }

  Future<void> saveDraftPit(PitModel pit) async {
    if (!_hasWellId || pit.id != null || !_isDraftFilled(pit)) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.addPit(
        pitName: pit.pitName.trim(),
        capacity: _draftCapacity(pit),
        initialActive: pit.initialActive.value,
        wellId: currentWellId!,
      );

      if (result['success'] == true) {
        await fetchAllPits();
      } else {
        _showAlert(result['message'] ?? 'Failed to add pit', isError: true);
      }
    } catch (e) {
      debugPrint('Error saving draft pit: $e');
      _showAlert('Error saving pit', isError: true);
    }
  }

  void removeDraftPit(PitModel pit) {
    if (pit.id != null) return;
    pits.remove(pit);
    _ensureDraftRows();
    pits.refresh();
  }

  void normalizeTransferRowsForSource() {
    final allowedDestinations = transferDestinationOptions.toSet();
    var changed = false;

    for (final row in transferRows) {
      if (row.pitName.isNotEmpty &&
          !allowedDestinations.contains(row.pitName)) {
        row.pitName = '';
        changed = true;
      }
    }

    if (changed) {
      transferRows.refresh();
      scheduleTransferMudAutoSave();
    }
  }

  void clearTransferMudLocalState() {
    _transferAutoSaveTimer?.cancel();
    _isApplyingTransferState = true;
    for (final row in transferRows) {
      row.volumeController.dispose();
    }
    transferRows
      ..clear()
      ..addAll(List.generate(5, (_) => TransferRowData()));
    selectedFromPit.value = 'Active System';
    notTreatedMud.value = false;
    selectedRowIndex.value = 0;
    transferRows.refresh();
    _isApplyingTransferState = false;
  }

  bool get _hasTransferData => transferRows.any(
    (row) =>
        (row.savedId ?? '').isNotEmpty ||
        row.pitName.trim().isNotEmpty ||
        row.volume.trim().isNotEmpty,
  );

  void scheduleTransferMudAutoSave() {
    if (_isApplyingTransferState ||
        isLoadingTransfer.value ||
        !_hasTransferData) {
      return;
    }
    _transferAutoSaveTimer?.cancel();
    _transferAutoSaveTimer = Timer(const Duration(milliseconds: 850), () async {
      if (_isApplyingTransferState ||
          isLoadingTransfer.value ||
          !_hasTransferData) {
        return;
      }
      await saveTransferMud();
    });
  }

  String? _validateTransferRow(TransferRowData row) {
    final source = selectedFromPit.value.trim();
    final destination = row.pitName.trim();
    final volume = double.tryParse(row.volume.trim()) ?? 0;

    if (source.isEmpty) {
      return 'Select a source pit first';
    }
    if (destination.isEmpty) {
      return 'Select a destination pit';
    }
    if (volume <= 0) {
      return 'Enter a volume greater than 0';
    }
    if (source.toLowerCase() == destination.toLowerCase()) {
      return 'Source and destination cannot be the same';
    }
    if (!transferDestinationOptions.contains(destination)) {
      return 'Select a valid destination';
    }

    return null;
  }

  Future<Map<String, dynamic>> saveTransferMud() async {
    _transferAutoSaveTimer?.cancel();
    if (!_hasWellId) return {'success': false, 'message': 'Well ID missing'};
    final instanceKey = _activeTransferOperationInstanceKey.trim();
    if (instanceKey.isEmpty) {
      return {'success': false, 'message': 'Operation row missing'};
    }

    if (_isSavingTransferMud) {
      _needsTransferMudResave = true;
      return {'success': true, 'message': 'Transfer save queued'};
    }
    _isSavingTransferMud = true;
    _needsTransferMudResave = false;

    final authRepo = AuthRepository();

    try {
      final clearedSavedRows = transferRows
          .where(
            (r) =>
                r.savedId != null &&
                (r.pitName.trim().isEmpty || r.volume.trim().isEmpty),
          )
          .toList();
      final candidateRows = transferRows
          .where(
            (r) =>
                !clearedSavedRows.contains(r) &&
                (r.pitName.trim().isNotEmpty || r.volume.trim().isNotEmpty),
          )
          .toList();

      if (candidateRows.isEmpty && clearedSavedRows.isEmpty) {
        return {'success': true, 'message': 'No transfers to save'};
      }

      int successCount = 0;
      final List<String> errors = [];
      final validRows = <TransferRowData>[];

      for (final row in clearedSavedRows) {
        final deleteRes = await authRepo.deleteTransferMud(
          currentWellId!,
          row.savedId!,
          operationInstanceKey: instanceKey,
        );
        if (deleteRes['success'] == true) {
          successCount++;
          row.savedId = null;
          row.pitName = '';
          row.volume = '';
          row.volumeController.clear();
        } else {
          errors.add(deleteRes['message']?.toString() ?? 'Delete failed');
        }
      }

      for (final row in candidateRows) {
        final rowNumber = transferRows.indexOf(row) + 1;
        final validationError = _validateTransferRow(row);
        if (validationError != null) {
          errors.add('Row $rowNumber: $validationError');
          continue;
        }
        validRows.add(row);
      }

      if (validRows.isEmpty && errors.isNotEmpty) {
        return {
          'success': false,
          'message': errors.join(' | '),
          'errors': errors,
        };
      }

      for (final row in validRows) {
        final payload = {
          'wellId': currentWellId!,
          'operationInstanceKey': instanceKey,
          'from': selectedFromPit.value,
          'transfers': [row.toTransferMap(notTreatedMud.value)],
        };

        final result = row.savedId == null
            ? await authRepo.createTransferMud(currentWellId!, payload)
            : await authRepo.updateTransferMud(
                currentWellId!,
                row.savedId!,
                payload,
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

      await fetchAllPits();
      await fetchVolumeNameData();

      return {
        'success': errors.isEmpty,
        'message': errors.isEmpty
            ? 'Saved $successCount transfers successfully'
            : successCount > 0
            ? 'Saved/updated $successCount transfers, ${errors.length} failed'
            : errors.join(' | '),
        if (errors.isNotEmpty) 'errors': errors,
      };
    } catch (e) {
      debugPrint('Error saving transfer mud batch: $e');
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      _isSavingTransferMud = false;
      if (_needsTransferMudResave) {
        _needsTransferMudResave = false;
        scheduleTransferMudAutoSave();
      }
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
          operationInstanceKey: _activeTransferOperationInstanceKey.trim(),
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
    await fetchAllPits();
    await fetchVolumeNameData();
  }

  Future<void> clearTransferRow(int index) async {
    if (index < 0 || index >= transferRows.length) return;

    final row = transferRows[index];
    if ((row.savedId ?? '').isNotEmpty) {
      await deleteTransferRow(index);
      return;
    }

    row.pitName = '';
    row.volume = '';
    row.volumeController.clear();
    transferRows.refresh();
  }

  void insertTransferRowAfter(int index) {
    final insertAt = index < 0
        ? 0
        : (index + 1 > transferRows.length ? transferRows.length : index + 1);
    transferRows.insert(insertAt, TransferRowData());
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
}
