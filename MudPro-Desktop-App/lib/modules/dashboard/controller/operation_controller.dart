import 'dart:async';

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/empty_Activesystem_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_loss_active_system_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_loss_storage_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/other_vol_addition_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

enum OperationType {
  consumeServices,
  consumeProduct,
  receiveProduct,
  returnProduct,
  transferMud,
  receiveMud,
  returnLostMud,
  addWater,
  switchPit,
  switchMudType,
  emptyActiveSystem,
  otherVolAddition,
  mudLossActiveSystem,
  mudLossStorage,
}

class _OperationSelectionEntry {
  const _OperationSelectionEntry({
    required this.operation,
    required this.token,
  });

  final OperationType operation;
  final String token;
}

class OperationController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  Worker? _wellWorker;
  Worker? _reportWorker;
  Timer? _operationSelectionSaveTimer;
  bool _isApplyingOperationSelectionState = false;

  RxBool isLocked = true.obs;
  RxInt selectedRowIndex = 0.obs;
  RxString addWaterVolume = "".obs; // Track Add Water locally
  RxDouble totalVolume =
      0.0.obs; // Track overall total volume (Products + Water)
  final isMenuLoading = false.obs;
  final menuError = ''.obs;

  // ── Add Water State ────────────────────────────────────────────────────────
  final RxString addWaterTo = "Active System".obs;
  final RxString addWaterMainVol = "".obs;
  final RxList<String> addWaterExtraRows = <String>["", ""].obs;
  final RxList<String> addWaterRecordIds = <String>[].obs;
  final isAddWaterLoading = false.obs;
  String _loadedAddWaterWellId = '';
  String _loadedAddWaterReportId = '';
  Timer? _addWaterAutoSaveTimer;
  bool _isApplyingAddWaterState = false;
  final List<Worker> _addWaterAutoSaveWorkers = <Worker>[];

  String _formatVolume(double value) {
    if (value <= 0 || value.isNaN) return '';
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  double _parseVolume(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0.0;

  Map<String, dynamic>? _extractEntity(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    if (value is Map && value['data'] is List) {
      final items = value['data'] as List;
      if (items.isNotEmpty && items.first is Map) {
        return Map<String, dynamic>.from(items.first as Map);
      }
    }
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  void _resetAddWaterState() {
    addWaterTo.value = "Active System";
    addWaterMainVol.value = "";
    addWaterExtraRows.assignAll(["", ""]);
    addWaterRecordIds.clear();
  }

  List<String> _collectAddWaterVolumes() {
    final values = <String>[];
    if (double.tryParse(addWaterMainVol.value.trim()) != null &&
        double.parse(addWaterMainVol.value.trim()) > 0) {
      values.add(addWaterMainVol.value.trim());
    }
    for (final row in addWaterExtraRows) {
      final trimmed = row.trim();
      final parsed = double.tryParse(trimmed);
      if (parsed != null && parsed > 0) {
        values.add(trimmed);
      }
    }
    return values;
  }

  bool get _hasAddWaterData =>
      addWaterRecordIds.isNotEmpty || _collectAddWaterVolumes().isNotEmpty;

  void _scheduleAddWaterAutoSave() {
    if (_isApplyingAddWaterState ||
        isAddWaterLoading.value ||
        !_hasAddWaterData) {
      return;
    }
    _addWaterAutoSaveTimer?.cancel();
    _addWaterAutoSaveTimer = Timer(const Duration(milliseconds: 850), () async {
      if (_isApplyingAddWaterState ||
          isAddWaterLoading.value ||
          !_hasAddWaterData) {
        return;
      }
      await saveAddWater();
    });
  }

  Future<void> _refreshPitState() async {
    if (!Get.isRegistered<PitController>()) return;
    final pitCtrl = Get.find<PitController>();
    await pitCtrl.fetchAllPits();
    await pitCtrl.fetchSelectedPits();
    await pitCtrl.fetchUnselectedPits();
    await pitCtrl.fetchVolumeNameData();
  }

  Future<void> loadAddWater({bool force = false}) async {
    _addWaterAutoSaveTimer?.cancel();
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();
    if (wellId.isEmpty || reportId.isEmpty) {
      _isApplyingAddWaterState = true;
      _loadedAddWaterWellId = '';
      _loadedAddWaterReportId = '';
      _resetAddWaterState();
      _isApplyingAddWaterState = false;
      return;
    }
    if (!force &&
        _loadedAddWaterWellId == wellId &&
        _loadedAddWaterReportId == reportId &&
        !isAddWaterLoading.value) {
      return;
    }

    isAddWaterLoading.value = true;
    _isApplyingAddWaterState = true;
    try {
      final result = await _repository.getAddWaterList(wellId);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load Add Water');
      }

      final envelope = result['data'];
      final data = envelope is Map<String, dynamic>
          ? envelope['data']
          : envelope is Map
          ? Map<String, dynamic>.from(envelope)['data']
          : null;
      final items = data is List
          ? List<Map<String, dynamic>>.from(data)
          : const <Map<String, dynamic>>[];
      final chronologicalItems = items.reversed.toList();

      if (chronologicalItems.isEmpty) {
        _resetAddWaterState();
        _loadedAddWaterWellId = wellId;
        _loadedAddWaterReportId = reportId;
        return;
      }

      final volumes = chronologicalItems
          .map(
            (item) =>
                _formatVolume(_parseVolume((item['volume'] ?? '').toString())),
          )
          .toList();
      final recordIds = chronologicalItems
          .map((item) => (item['_id'] ?? item['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      addWaterTo.value =
          (chronologicalItems.first['to'] ?? 'Active System')
              .toString()
              .trim()
              .isEmpty
          ? 'Active System'
          : (chronologicalItems.first['to'] ?? 'Active System').toString();
      addWaterMainVol.value = volumes.isNotEmpty ? volumes.first : "";

      final extras = volumes.length > 1 ? volumes.skip(1).toList() : <String>[];
      while (extras.length < 2) {
        extras.add("");
      }
      if (extras.isNotEmpty && extras.last.trim().isNotEmpty) {
        extras.add("");
      }
      addWaterExtraRows.assignAll(extras);
      addWaterRecordIds.assignAll(recordIds);
      _loadedAddWaterWellId = wellId;
      _loadedAddWaterReportId = reportId;
    } catch (_) {
      _resetAddWaterState();
    } finally {
      _isApplyingAddWaterState = false;
      isAddWaterLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> saveAddWater() async {
    _addWaterAutoSaveTimer?.cancel();
    final wellId = currentBackendWellId;
    if (wellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    final reportId = reportContext.selectedReportId.value.trim();
    if (reportId.isEmpty) {
      return {'success': false, 'message': 'No report selected'};
    }
    final enteredTo = addWaterTo.value.trim().isEmpty
        ? 'Active System'
        : addWaterTo.value.trim();
    final enteredVolumes = _collectAddWaterVolumes();

    if (_loadedAddWaterWellId != wellId ||
        _loadedAddWaterReportId != reportId) {
      if (enteredVolumes.isEmpty && addWaterRecordIds.isEmpty) {
        await loadAddWater(force: true);
      } else {
        _loadedAddWaterWellId = wellId;
        _loadedAddWaterReportId = reportId;
      }
    }

    final currentIds = addWaterRecordIds.toList();
    final errors = <String>[];
    var successCount = 0;

    if (enteredVolumes.isEmpty) {
      if (currentIds.isEmpty) {
        return {'success': true, 'message': 'No Add Water data to save'};
      }
      for (final id in currentIds) {
        final deleteRes = await _repository.deleteAddWater(wellId, id);
        if (deleteRes['success'] == true) {
          successCount++;
        } else {
          errors.add(deleteRes['message']?.toString() ?? 'Delete failed');
        }
      }
      if (errors.isEmpty) {
        _resetAddWaterState();
        await _refreshPitState();
      }
      return {
        'success': errors.isEmpty,
        'message': errors.isEmpty
            ? 'Add Water cleared successfully'
            : 'Cleared $successCount rows, errors: ${errors.join(", ")}',
      };
    }

    for (var index = 0; index < enteredVolumes.length; index++) {
      final body = {
        'to': enteredTo,
        'volume': _parseVolume(enteredVolumes[index]),
      };
      final existingId = index < currentIds.length ? currentIds[index] : '';
      final result = existingId.isNotEmpty
          ? await _repository.updateAddWater(wellId, existingId, body)
          : await _repository.createAddWater(wellId, body);
      if (result['success'] == true) {
        if (existingId.isEmpty) {
          final savedData = _extractEntity(result['data']);
          final savedId = (savedData?['_id'] ?? savedData?['id'])?.toString();
          if (savedId != null && savedId.isNotEmpty) {
            if (index < currentIds.length) {
              currentIds[index] = savedId;
            } else {
              currentIds.add(savedId);
            }
          }
        }
        successCount++;
      } else {
        errors.add('Row ${index + 1}: ${result['message']}');
      }
    }

    for (
      var index = enteredVolumes.length;
      index < currentIds.length;
      index++
    ) {
      final deleteRes = await _repository.deleteAddWater(
        wellId,
        currentIds[index],
      );
      if (deleteRes['success'] == true) {
        successCount++;
      } else {
        errors.add('Delete row ${index + 1}: ${deleteRes['message']}');
      }
    }

    if (errors.isEmpty) {
      addWaterRecordIds.assignAll(
        currentIds.take(enteredVolumes.length).where((id) => id.isNotEmpty),
      );
      _loadedAddWaterWellId = wellId;
      _loadedAddWaterReportId = reportId;
      await _refreshPitState();
    }

    return {
      'success': errors.isEmpty,
      'message': errors.isEmpty
          ? 'Add Water saved successfully'
          : 'Saved $successCount changes, errors: ${errors.join(", ")}',
    };
  }

  final List<OperationType> _fallbackOperations = OperationType.values;
  final availableOperations = <OperationType>[].obs;

  RxList<OperationType?> dropdownValues = <OperationType?>[].obs;
  RxList<String> operationSelectionTokens = <String>[].obs;
  RxList<bool> isDropdownOpen = <bool>[].obs;
  final deletingOperationRowIndex = (-1).obs;
  final backendLabels = <OperationType, String>{}.obs;

  final Map<OperationType, String> labels = {
    OperationType.consumeServices: "Consume Services",
    OperationType.consumeProduct: "Consume Product",
    OperationType.receiveProduct: "Receive Product",
    OperationType.returnProduct: "Return Product",
    OperationType.transferMud: "Transfer Mud",
    OperationType.receiveMud: "Receive Mud",
    OperationType.returnLostMud: "Return / Lost Mud",
    OperationType.addWater: "Add Water",
    OperationType.switchPit: "Switch Pit",
    OperationType.switchMudType: "Switch Mud Type",
    OperationType.emptyActiveSystem: "Empty Active System",
    OperationType.otherVolAddition: "Other Vol. Addition - Active System",
    OperationType.mudLossActiveSystem: "Mud Loss - Active System",
    OperationType.mudLossStorage: "Mud Loss - Storage",
  };

  // ---------- RETURN / LOST MUD ----------
  RxBool premixedMud = false.obs;
  RxBool leased = false.obs;

  final List<String> returnLostLabels = [
    "From",
    "To",
    "Vol. Returned",
    "MW",
    "Mud Type",
    "BOL",
    "Vol. Lost",
    "Cost of Lost (Pre-tax)",
    "",
  ];

  final List<String> returnLostUnits = [
    "",
    "",
    "(bbl)",
    "(ppg)",
    "",
    "",
    "(bbl)",
    "(\$)",
    "",
  ];

  // which row uses dropdown (From & To)
  final RxList<bool> returnLostDropdownIndex = <bool>[
    true,
    true,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ].obs;

  // dropdown values per row
  final RxList<String> returnLostDropdownValue = List.generate(
    9,
    (_) => "Active System",
  ).obs;

  List<OperationType> get dropdownItems => availableOperations.isNotEmpty
      ? availableOperations
      : _fallbackOperations;

  String labelFor(OperationType operation) =>
      backendLabels[operation] ?? labels[operation] ?? operation.name;

  String _normalizeOperationKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  OperationType? _mapBackendOperation(String description) {
    final key = _normalizeOperationKey(description);

    const aliases = <OperationType, List<String>>{
      OperationType.consumeServices: ['consume services', 'consume service'],
      OperationType.consumeProduct: ['consume product'],
      OperationType.receiveProduct: ['receive product'],
      OperationType.returnProduct: ['return product'],
      OperationType.transferMud: ['transfer mud'],
      OperationType.receiveMud: ['receive mud'],
      OperationType.returnLostMud: [
        'return mud',
        'return lost mud',
        'return lost mud',
      ],
      OperationType.addWater: ['add water'],
      OperationType.switchPit: ['switch pit'],
      OperationType.switchMudType: ['switch mud type', 'switch mudtype'],
      OperationType.emptyActiveSystem: [
        'empty active system',
        'empty fluid active system',
        'empty fluid in active system',
      ],
      OperationType.otherVolAddition: [
        'other vol addition active system',
        'other vol addition',
        'other volume addition active system',
      ],
      OperationType.mudLossActiveSystem: ['mud loss active system'],
      OperationType.mudLossStorage: ['mud loss storage'],
    };

    for (final entry in aliases.entries) {
      if (entry.value.contains(key)) {
        return entry.key;
      }
    }

    return null;
  }

  List<_OperationSelectionEntry> _reportSelectionsForChoices(
    List<OperationType> choices,
  ) {
    final saved =
        reportContext.selectedReport?.operationSelections ?? const <String>[];
    final selected = <_OperationSelectionEntry>[];
    final legacyCounts = <OperationType, int>{};
    for (final raw in saved) {
      final match = _operationTypeFromName(raw);
      if (match == null || !choices.contains(match)) {
        continue;
      }
      final token = _operationTokenFromSavedValue(raw, match, legacyCounts);
      selected.add(_OperationSelectionEntry(operation: match, token: token));
    }
    return selected;
  }

  OperationType? _operationTypeFromName(String name) {
    final typeName = name.split('::').first.trim();
    for (final operation in OperationType.values) {
      if (operation.name == typeName) return operation;
    }
    return null;
  }

  String _operationTokenFromSavedValue(
    String raw,
    OperationType operation,
    Map<OperationType, int> legacyCounts,
  ) {
    final clean = raw.trim();
    if (clean.contains('::')) return clean;

    final index = legacyCounts[operation] ?? 0;
    legacyCounts[operation] = index + 1;
    return '${operation.name}::legacy$index';
  }

  String _newOperationSelectionToken(OperationType operation) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final existingCount = operationSelectionTokens
        .where((token) => token.startsWith('${operation.name}::'))
        .length;
    return '${operation.name}::${now}_$existingCount';
  }

  String operationInstanceKeyAt(int index) {
    if (index < 0 || index >= dropdownValues.length) return '';
    final operation = dropdownValues[index];
    if (operation == null) return '';
    if (index < operationSelectionTokens.length) {
      final token = operationSelectionTokens[index].trim();
      if (token.isNotEmpty) return token;
    }
    return '${operation.name}::row$index';
  }

  List<String> _operationSelectionPayload() {
    final selected = <String>[];
    for (var i = 0; i < dropdownValues.length; i++) {
      final operation = dropdownValues[i];
      if (operation == null) continue;
      final token = i < operationSelectionTokens.length
          ? operationSelectionTokens[i].trim()
          : '';
      selected.add(token.isNotEmpty ? token : '${operation.name}::row$i');
    }
    return selected;
  }

  void _applyAvailableOperations(List<OperationType> operations) {
    final choices = operations.isNotEmpty ? operations : _fallbackOperations;
    final reportSelections = _reportSelectionsForChoices(choices);

    final nextSelections = List<OperationType?>.filled(choices.length, null);
    final nextTokens = List<String>.filled(choices.length, '');
    for (
      var i = 0;
      i < reportSelections.length && i < nextSelections.length;
      i++
    ) {
      nextSelections[i] = reportSelections[i].operation;
      nextTokens[i] = reportSelections[i].token;
    }

    _isApplyingOperationSelectionState = true;
    availableOperations.assignAll(choices);
    dropdownValues.assignAll(nextSelections);
    operationSelectionTokens.assignAll(nextTokens);
    isDropdownOpen.assignAll(List.generate(choices.length, (_) => false));
    _isApplyingOperationSelectionState = false;

    final firstSelected = nextSelections.indexWhere((item) => item != null);
    selectedRowIndex.value = firstSelected == -1 ? 0 : firstSelected;
  }

  Future<bool> setOperationAt(int index, OperationType? operation) async {
    if (index < 0 || index >= dropdownValues.length) return false;

    final nextSelections = dropdownValues.toList();
    final nextTokens = operationSelectionTokens.toList();
    while (nextTokens.length < nextSelections.length) {
      nextTokens.add('');
    }
    final previousOperation = nextSelections[index];
    final previousToken = nextTokens[index].trim();

    if (previousOperation != null && previousOperation != operation) {
      final wellId = currentBackendWellId.trim();
      final reportId = reportContext.selectedReportId.value.trim();
      if (wellId.isEmpty || reportId.isEmpty || previousToken.isEmpty) {
        menuError.value = 'Cannot replace operation before report data loads';
        return false;
      }

      deletingOperationRowIndex.value = index;
      try {
        final result = await _repository.deleteOperationData(
          wellId: wellId,
          operationType: previousOperation.name,
          operationInstanceKey: previousToken,
        );
        if (result['success'] != true) {
          menuError.value =
              result['message']?.toString() ??
              'Failed to remove previous operation data';
          return false;
        }
        _clearLocalStateForOperation(
          previousOperation,
          wellId,
          previousToken,
        );
      } catch (error) {
        menuError.value = error.toString().replaceFirst(
          RegExp(r'^Exception:\s*'),
          '',
        );
        return false;
      } finally {
        deletingOperationRowIndex.value = -1;
      }
    }

    nextSelections[index] = operation;
    if (operation == null) {
      nextTokens[index] = '';
    } else if (previousOperation != operation || nextTokens[index].isEmpty) {
      nextTokens[index] = _newOperationSelectionToken(operation);
    }
    dropdownValues.assignAll(nextSelections);
    operationSelectionTokens.assignAll(nextTokens);
    selectedRowIndex.value = index;
    await _saveOperationSelectionsNow();
    await _refreshPitState();
    return true;
  }

  void _scheduleOperationSelectionSave() {
    if (_isApplyingOperationSelectionState) return;
    _operationSelectionSaveTimer?.cancel();
    _operationSelectionSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveOperationSelectionsNow();
    });
  }

  Future<void> _saveOperationSelectionsNow() async {
    if (_isApplyingOperationSelectionState ||
        reportContext.selectedReport == null) {
      return;
    }
    _operationSelectionSaveTimer?.cancel();
    try {
      await reportContext.updateSelectedReport({
        'operationSelections': _operationSelectionPayload(),
      });
    } catch (e) {
      menuError.value = e.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );
    }
  }

  void _removeOperationSelectionAt(int index) {
    if (index < 0 || index >= dropdownValues.length) return;

    final rawSelections = dropdownValues.toList();
    final rawTokens = operationSelectionTokens.toList();
    while (rawTokens.length < rawSelections.length) {
      rawTokens.add('');
    }
    rawSelections.removeAt(index);
    rawTokens.removeAt(index);
    rawSelections.add(null);
    rawTokens.add('');
    final selected = rawSelections.whereType<OperationType>().toList();
    final selectedTokens = <String>[];
    for (var i = 0; i < rawSelections.length; i++) {
      if (rawSelections[i] != null) {
        selectedTokens.add(rawTokens[i]);
      }
    }
    final nextSelections = List<OperationType?>.filled(
      dropdownItems.length,
      null,
    );
    final nextTokens = List<String>.filled(dropdownItems.length, '');
    for (var i = 0; i < selected.length && i < nextSelections.length; i++) {
      nextSelections[i] = selected[i];
      nextTokens[i] = i < selectedTokens.length ? selectedTokens[i] : '';
    }

    dropdownValues.assignAll(nextSelections);
    operationSelectionTokens.assignAll(nextTokens);
    isDropdownOpen.assignAll(
      List.generate(nextSelections.length, (_) => false),
    );
    selectedRowIndex.value = selected.isEmpty
        ? 0
        : index.clamp(0, selected.length - 1).toInt();
  }

  void _clearLocalStateForOperation(
    OperationType operation,
    String wellId,
    String instanceKey,
  ) {
    switch (operation) {
      case OperationType.addWater:
        _resetAddWaterState();
        _loadedAddWaterWellId = wellId;
        _loadedAddWaterReportId = reportContext.selectedReportId.value.trim();
        break;
      case OperationType.transferMud:
        if (Get.isRegistered<PitController>()) {
          Get.find<PitController>().clearTransferMudLocalState();
        }
        break;
      case OperationType.otherVolAddition:
        if (Get.isRegistered<OtherVolAdditionController>(tag: instanceKey)) {
          Get.find<OtherVolAdditionController>(
            tag: instanceKey,
          ).clearLocalState();
        }
        break;
      case OperationType.mudLossActiveSystem:
        if (Get.isRegistered<MudLossActiveSystemController>(
          tag: instanceKey,
        )) {
          Get.find<MudLossActiveSystemController>(
            tag: instanceKey,
          ).clearLocalState();
        }
        break;
      case OperationType.mudLossStorage:
        if (Get.isRegistered<MudLossStorageController>(tag: instanceKey)) {
          Get.find<MudLossStorageController>(
            tag: instanceKey,
          ).clearLocalState();
        }
        break;
      case OperationType.emptyActiveSystem:
        if (Get.isRegistered<EmptyActiveSystemController>(tag: instanceKey)) {
          Get.find<EmptyActiveSystemController>(
            tag: instanceKey,
          ).clearLocalState();
        }
        break;
      default:
        break;
    }
  }

  Future<Map<String, dynamic>> deleteOperationRow(int index) async {
    if (index < 0 || index >= dropdownValues.length) {
      return {'success': false, 'message': 'Invalid operation row'};
    }

    final operation = dropdownValues[index];
    if (operation == null) {
      return {'success': true, 'message': 'No operation selected'};
    }

    final wellId = currentBackendWellId.trim();
    if (wellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    final reportId = reportContext.selectedReportId.value.trim();
    if (reportId.isEmpty) {
      return {'success': false, 'message': 'No report selected'};
    }

    deletingOperationRowIndex.value = index;
    try {
      final operationInstanceKey = operationInstanceKeyAt(index);
      final result = await _repository.deleteOperationData(
        wellId: wellId,
        operationType: operation.name,
        operationInstanceKey: operationInstanceKey,
      );

      if (result['success'] == true) {
        _clearLocalStateForOperation(operation, wellId, operationInstanceKey);
        _removeOperationSelectionAt(index);
        await _saveOperationSelectionsNow();
        await _refreshPitState();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      deletingOperationRowIndex.value = -1;
    }
  }

  Future<void> fetchOperationsMenu() async {
    isMenuLoading.value = true;
    menuError.value = '';
    try {
      final result = await _repository.getOperations(activeOnly: true);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to fetch operations');
      }

      final envelope = result['data'];
      final data = envelope is Map<String, dynamic>
          ? envelope['data']
          : envelope is Map
          ? envelope['data']
          : null;

      final items = data is List ? data : const [];
      final mappedOperations = <OperationType>[];
      final nextLabels = <OperationType, String>{};

      for (final rawItem in items) {
        if (rawItem is! Map) continue;
        final item = Map<String, dynamic>.from(rawItem);
        final description = item['description']?.toString().trim() ?? '';
        if (description.isEmpty) continue;

        final operation = _mapBackendOperation(description);
        if (operation == null || mappedOperations.contains(operation)) {
          continue;
        }

        mappedOperations.add(operation);
        nextLabels[operation] = description;
      }

      backendLabels.assignAll(nextLabels);
      _applyAvailableOperations(mappedOperations);
    } catch (e) {
      menuError.value = e.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );
      backendLabels.clear();
      _applyAvailableOperations(_fallbackOperations);
    } finally {
      isMenuLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _applyAvailableOperations(_fallbackOperations);
    fetchOperationsMenu();
    loadAddWater();
    _addWaterAutoSaveWorkers.addAll([
      ever<String>(addWaterTo, (_) => _scheduleAddWaterAutoSave()),
      ever<String>(addWaterMainVol, (_) => _scheduleAddWaterAutoSave()),
      ever<List<String>>(addWaterExtraRows, (_) => _scheduleAddWaterAutoSave()),
    ]);
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      _loadedAddWaterWellId = '';
      _loadedAddWaterReportId = '';
      loadAddWater(force: true);
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      _applyAvailableOperations(
        availableOperations.isNotEmpty
            ? availableOperations.toList()
            : _fallbackOperations,
      );
      _loadedAddWaterWellId = '';
      _loadedAddWaterReportId = '';
      loadAddWater(force: true);
    });
  }

  @override
  void onClose() {
    _addWaterAutoSaveTimer?.cancel();
    _operationSelectionSaveTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _addWaterAutoSaveWorkers) {
      worker.dispose();
    }
    super.onClose();
  }
}
