import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
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

class OperationController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  Worker? _wellWorker;

  RxBool isLocked = true.obs;
  RxInt selectedRowIndex = 0.obs;
  RxString addWaterVolume = "".obs; // Track Add Water locally
  RxDouble totalVolume = 0.0.obs; // Track overall total volume (Products + Water)
  final isMenuLoading = false.obs;
  final menuError = ''.obs;

  // ── Add Water State ────────────────────────────────────────────────────────
  final RxString addWaterTo = "Active System".obs;
  final RxString addWaterMainVol = "".obs;
  final RxList<String> addWaterExtraRows = <String>["", ""].obs;
  final RxList<String> addWaterRecordIds = <String>[].obs;
  final isAddWaterLoading = false.obs;
  String _loadedAddWaterWellId = '';

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

  Future<void> _refreshPitState() async {
    if (!Get.isRegistered<PitController>()) return;
    final pitCtrl = Get.find<PitController>();
    await pitCtrl.fetchAllPits();
    await pitCtrl.fetchSelectedPits();
    await pitCtrl.fetchUnselectedPits();
    await pitCtrl.fetchVolumeNameData();
  }

  Future<void> loadAddWater({bool force = false}) async {
    final wellId = currentBackendWellId.trim();
    if (wellId.isEmpty) {
      _loadedAddWaterWellId = '';
      _resetAddWaterState();
      return;
    }
    if (!force && _loadedAddWaterWellId == wellId && !isAddWaterLoading.value) {
      return;
    }

    isAddWaterLoading.value = true;
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
      final items = data is List ? List<Map<String, dynamic>>.from(data) : const <Map<String, dynamic>>[];
      final chronologicalItems = items.reversed.toList();

      if (chronologicalItems.isEmpty) {
        _resetAddWaterState();
        _loadedAddWaterWellId = wellId;
        return;
      }

      final volumes = chronologicalItems
          .map((item) => (item['volume'] ?? '').toString())
          .toList();
      final recordIds = chronologicalItems
          .map((item) => (item['_id'] ?? item['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      addWaterTo.value = (chronologicalItems.first['to'] ?? 'Active System')
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
    } catch (_) {
      _resetAddWaterState();
    } finally {
      isAddWaterLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> saveAddWater() async {
    final wellId = currentBackendWellId;
    if (wellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    if (_loadedAddWaterWellId != wellId) {
      await loadAddWater(force: true);
    }

    final volumes = _collectAddWaterVolumes();
    final errors = <String>[];
    var successCount = 0;

    if (volumes.isEmpty) {
      if (addWaterRecordIds.isEmpty) {
        return {'success': true, 'message': 'No Add Water data to save'};
      }
      for (final id in addWaterRecordIds) {
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

    final currentIds = addWaterRecordIds.toList();
    for (var index = 0; index < volumes.length; index++) {
      final body = {
        'to': addWaterTo.value,
        'volume': double.parse(volumes[index]),
      };
      final existingId = index < currentIds.length ? currentIds[index] : '';
      final result = existingId.isNotEmpty
          ? await _repository.updateAddWater(wellId, existingId, body)
          : await _repository.createAddWater(wellId, body);
      if (result['success'] == true) {
        successCount++;
      } else {
        errors.add('Row ${index + 1}: ${result['message']}');
      }
    }

    for (var index = volumes.length; index < currentIds.length; index++) {
      final deleteRes = await _repository.deleteAddWater(wellId, currentIds[index]);
      if (deleteRes['success'] == true) {
        successCount++;
      } else {
        errors.add('Delete row ${index + 1}: ${deleteRes['message']}');
      }
    }

    if (errors.isEmpty) {
      await loadAddWater(force: true);
      await _refreshPitState();
    }

    return {
      'success': errors.isEmpty,
      'message': errors.isEmpty
          ? 'Add Water saved successfully'
          : 'Saved $successCount changes, errors: ${errors.join(", ")}'
    };
  }

  final List<OperationType> _fallbackOperations = OperationType.values;
  final availableOperations = <OperationType>[].obs;

  RxList<OperationType?> dropdownValues = <OperationType?>[].obs;
  RxList<bool> isDropdownOpen = <bool>[].obs;
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
    OperationType.otherVolAddition:
        "Other Vol. Addition - Active System",
    OperationType.mudLossActiveSystem:
        "Mud Loss - Active System",
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
final RxList<bool> returnLostDropdownIndex =
    <bool>[true, true, false, false, false, false, false, false, false].obs;

  // dropdown values per row
final RxList<String> returnLostDropdownValue =
    List.generate(9, (_) => "Active System").obs;

  List<OperationType> get dropdownItems =>
      availableOperations.isNotEmpty ? availableOperations : _fallbackOperations;

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
      OperationType.consumeServices: [
        'consume services',
        'consume service',
      ],
      OperationType.consumeProduct: [
        'consume product',
      ],
      OperationType.receiveProduct: [
        'receive product',
      ],
      OperationType.returnProduct: [
        'return product',
      ],
      OperationType.transferMud: [
        'transfer mud',
      ],
      OperationType.receiveMud: [
        'receive mud',
      ],
      OperationType.returnLostMud: [
        'return lost mud',
        'return lost mud',
      ],
      OperationType.addWater: [
        'add water',
      ],
      OperationType.switchPit: [
        'switch pit',
      ],
      OperationType.switchMudType: [
        'switch mud type',
        'switch mudtype',
      ],
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
      OperationType.mudLossActiveSystem: [
        'mud loss active system',
      ],
      OperationType.mudLossStorage: [
        'mud loss storage',
      ],
    };

    for (final entry in aliases.entries) {
      if (entry.value.contains(key)) {
        return entry.key;
      }
    }

    return null;
  }

  void _applyAvailableOperations(List<OperationType> operations) {
    final choices = operations.isNotEmpty ? operations : _fallbackOperations;
    final previousSelections = dropdownValues
        .whereType<OperationType>()
        .where(choices.contains)
        .toList();

    final nextSelections = List<OperationType?>.filled(choices.length, null);
    for (var i = 0; i < previousSelections.length && i < nextSelections.length; i++) {
      nextSelections[i] = previousSelections[i];
    }

    if (nextSelections.isNotEmpty && nextSelections.first == null) {
      nextSelections[0] = choices.first;
    }
    if (nextSelections.length > 1 && nextSelections[1] == null) {
      nextSelections[1] = choices.length > 1 ? choices[1] : null;
    }

    availableOperations.assignAll(choices);
    dropdownValues.assignAll(nextSelections);
    isDropdownOpen.assignAll(List.generate(choices.length, (_) => false));

    if (selectedRowIndex.value >= nextSelections.length) {
      selectedRowIndex.value = 0;
    }
    if (nextSelections.isNotEmpty &&
        nextSelections[selectedRowIndex.value] == null) {
      final firstSelected = nextSelections.indexWhere((item) => item != null);
      selectedRowIndex.value = firstSelected == -1 ? 0 : firstSelected;
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
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      _loadedAddWaterWellId = '';
      loadAddWater(force: true);
    });
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    super.onClose();
  }
}
