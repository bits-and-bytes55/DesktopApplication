import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_api_service.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';

class PadWellController extends GetxController {
  final PadWellApiService _api;

  PadWellController({PadWellApiService? api})
    : _api = api ?? PadWellApiService();

  final pads = <AppPad>[].obs;
  final wells = <AppWell>[].obs;
  final selectedPadId = ''.obs;
  final selectedWellId = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    reloadData();
  }

  Future<void> reloadData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final fetchedPads = await _api.fetchPads(includeWells: true);
      var fetchedWells = _flattenWells(fetchedPads);

      if (fetchedWells.isEmpty) {
        fetchedWells = await _api.fetchWells(includePad: true);
      }

      final padsWithWells = _attachWellsToPads(fetchedPads, fetchedWells);

      pads.assignAll(padsWithWells);
      wells.assignAll(fetchedWells);
      _ensureValidSelection();
    } catch (e) {
      pads.clear();
      wells.clear();
      selectedPadId.value = '';
      selectedWellId.value = '';
      errorMessage.value = e.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectPad(String padId) {
    selectedPadId.value = padId;
    final firstWell = _firstWhereOrNull(wells, (well) => well.padId == padId);
    if (firstWell != null) {
      selectedWellId.value = firstWell.id;
    } else {
      selectedWellId.value = '';
    }
  }

  void selectWell(String wellId) {
    final well = _firstWhereOrNull(wells, (item) => item.id == wellId);
    if (well == null) return;

    selectedWellId.value = well.id;
    if (well.padId.isNotEmpty) {
      selectedPadId.value = well.padId;
    }
  }

  AppPad? get selectedPad {
    if (selectedPadId.value.isEmpty) return null;
    return _firstWhereOrNull(pads, (pad) => pad.id == selectedPadId.value);
  }

  AppWell? get selectedWell {
    if (selectedWellId.value.isEmpty) return null;
    return _firstWhereOrNull(wells, (well) => well.id == selectedWellId.value);
  }

  String get selectedWellName => selectedWell?.displayName ?? '';

  String get selectedPadName {
    final pad = selectedPad;
    if (pad != null) return pad.displayName;
    final well = selectedWell;
    final padRef = well?.pad;
    if (padRef?.fieldBlock.isNotEmpty == true) return padRef!.fieldBlock;
    return '';
  }

  AppPad? padForWell(AppWell? well) {
    if (well == null) return null;
    return _firstWhereOrNull(pads, (pad) => pad.id == well.padId);
  }

  List<AppWell> wellsForPad(String padId) =>
      wells.where((well) => well.padId == padId).toList();

  bool get hasSelectedPad => selectedPad != null;

  bool get hasSelectedWell => selectedWell != null;

  bool isPadReady(AppPad? pad) {
    if (pad == null) return false;
    return pad.fieldBlock.isNotEmpty &&
        pad.rig.isNotEmpty &&
        pad.operator.isNotEmpty &&
        pad.country.isNotEmpty;
  }

  bool isWellReady(AppWell? well) {
    if (well == null) return false;
    return isPadReady(padForWell(well)) &&
        well.wellNameNo.isNotEmpty &&
        well.apiWellNo.isNotEmpty &&
        well.spudDate.isNotEmpty;
  }

  bool get isSelectedPadReadyForWellCreation {
    return isPadReady(selectedPad);
  }

  bool get isSelectedWellReadyForReportCreation {
    return isWellReady(selectedWell);
  }

  String get padReadinessMessage {
    final pad = selectedPad;
    if (pad == null) {
      return 'Create and save a pad first.';
    }
    if (pad.fieldBlock.isEmpty ||
        pad.rig.isEmpty ||
        pad.operator.isEmpty ||
        pad.country.isEmpty) {
      return 'Complete pad fields: Field/Block, Rig, Operator, and Country.';
    }
    return '';
  }

  String get wellReadinessMessage {
    final well = selectedWell;
    if (well == null) {
      return 'Create and save a well first.';
    }
    if (!isSelectedPadReadyForWellCreation) {
      return padReadinessMessage;
    }
    if (well.wellNameNo.isEmpty ||
        well.apiWellNo.isEmpty ||
        well.spudDate.isEmpty) {
      return 'Complete well fields: Well Name, API Well No., and Spud Date.';
    }
    return '';
  }

  List<AppWell> _flattenWells(List<AppPad> pads) {
    final seen = <String>{};
    final output = <AppWell>[];

    for (final pad in pads) {
      for (final well in pad.wells) {
        final key = well.id.isEmpty ? '${pad.id}:${well.displayName}' : well.id;
        if (seen.add(key)) output.add(well);
      }
    }

    return output;
  }

  List<AppPad> _attachWellsToPads(List<AppPad> pads, List<AppWell> wells) {
    return pads
        .map(
          (pad) => pad.copyWith(
            wells: wells.where((well) => well.padId == pad.id).toList(),
          ),
        )
        .toList();
  }

  void _ensureValidSelection() {
    if (wells.isEmpty) {
      selectedWellId.value = '';
      selectedPadId.value = pads.isEmpty ? '' : pads.first.id;
      return;
    }

    final hasSelectedWell = wells.any(
      (well) => well.id == selectedWellId.value,
    );
    if (!hasSelectedWell) {
      selectedWellId.value = wells.first.id;
    }

    final activeWell = selectedWell;
    if (activeWell?.padId.isNotEmpty == true) {
      selectedPadId.value = activeWell!.padId;
      return;
    }

    final hasSelectedPad = pads.any((pad) => pad.id == selectedPadId.value);
    selectedPadId.value = hasSelectedPad ? selectedPadId.value : '';
  }

  Future<Map<String, dynamic>> createPad(Map<String, dynamic> payload) async {
    final result = await _api.createPad(payload);
    final padId = _extractEntityId(result['data']);
    await reloadData();
    if (padId.isNotEmpty) {
      selectPad(padId);
    }
    return result;
  }

  Future<Map<String, dynamic>> updateSelectedPad(
    Map<String, dynamic> payload,
  ) async {
    final pad = selectedPad;
    if (pad == null) {
      throw Exception('No pad selected');
    }

    final result = await _api.updatePad(pad.id, payload);
    await reloadData();
    selectPad(pad.id);
    return result;
  }

  Future<Map<String, dynamic>> deleteSelectedPad() async {
    final pad = selectedPad;
    if (pad == null) {
      throw Exception('No pad selected');
    }

    final deletedPadId = pad.id;
    final result = await _api.deletePad(deletedPadId);
    await reloadData();
    if (selectedPadId.value == deletedPadId) {
      if (pads.isNotEmpty) {
        selectPad(pads.first.id);
      } else {
        selectedPadId.value = '';
        selectedWellId.value = '';
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> createWell(Map<String, dynamic> payload) async {
    final result = await _api.createWell(payload);
    final wellId = _extractEntityId(result['data']);
    await reloadData();
    if (wellId.isNotEmpty) {
      selectWell(wellId);
    }
    return result;
  }

  Future<Map<String, dynamic>> updateSelectedWell(
    Map<String, dynamic> payload,
  ) async {
    final well = selectedWell;
    if (well == null) {
      throw Exception('No well selected');
    }

    final result = await _api.updateWell(well.id, payload);
    await reloadData();
    selectWell(well.id);
    return result;
  }

  Future<Map<String, dynamic>> deleteSelectedWell() async {
    final well = selectedWell;
    if (well == null) {
      throw Exception('No well selected');
    }

    final preferredPadId = well.padId;
    final deletedWellId = well.id;
    final result = await _api.deleteWell(deletedWellId);
    await reloadData();

    if (selectedWellId.value == deletedWellId) {
      final nextWell = _firstWhereOrNull(
        wells,
        (item) => item.padId == preferredPadId,
      );
      if (nextWell != null) {
        selectWell(nextWell.id);
      } else if (pads.any((pad) => pad.id == preferredPadId)) {
        selectPad(preferredPadId);
      }
    }

    return result;
  }
}

PadWellController get padWellContext => Get.isRegistered<PadWellController>()
    ? Get.find<PadWellController>()
    : Get.put(PadWellController());

String get currentBackendWellId => padWellContext.selectedWellId.value;

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

String _extractEntityId(dynamic data) {
  if (data is Map<String, dynamic>) {
    return (data['_id'] ?? data['id'] ?? '').toString().trim();
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    return (map['_id'] ?? map['id'] ?? '').toString().trim();
  }
  return '';
}
