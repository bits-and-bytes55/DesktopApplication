import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class OtherVolAdditionController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  final isLoading = false.obs;
  final recordId = RxnString();
  final formationController = TextEditingController();
  final cuttingsController = TextEditingController();
  final volumeNotFluidController = TextEditingController();
  final dynamicRows = <Map<String, String>>[
    {'label': '', 'volume': ''},
    {'label': '', 'volume': ''},
  ].obs;

  Worker? _wellWorker;
  final List<Worker> _unitWorkers = [];
  late String _fluidVolumeUnit;

  String get wellId => currentBackendWellId.trim();

  @override
  void onInit() {
    super.onInit();
    _fluidVolumeUnit = AppUnits.fluidVolume;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(AppUnits.controller.selectedCustomSystemId, (_) => _handleUnitChange()),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
    load();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) => load(force: true));
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    _unitWorkers.clear();
    formationController.dispose();
    cuttingsController.dispose();
    volumeNotFluidController.dispose();
    super.onClose();
  }

  Future<void> _refreshPitState() async {
    if (!Get.isRegistered<PitController>()) return;
    final pitCtrl = Get.find<PitController>();
    await pitCtrl.fetchAllPits();
    await pitCtrl.fetchSelectedPits();
    await pitCtrl.fetchUnselectedPits();
    await pitCtrl.fetchVolumeNameData();
  }

  void _clearFields() {
    formationController.clear();
    cuttingsController.clear();
    volumeNotFluidController.clear();
    recordId.value = null;
  }

  String _formatConverted(double value) {
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _convertText(String value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    final parsed = double.tryParse(value.trim().replaceAll(',', ''));
    if (parsed == null) return value;
    final result = AppUnits.convertValue(parsed, fromUnit, toUnit);
    return result == null ? value : _formatConverted(result);
  }

  void _handleUnitChange() {
    final nextFluidVolumeUnit = AppUnits.fluidVolume;
    if (_fluidVolumeUnit == nextFluidVolumeUnit) return;
    for (final controller in [
      formationController,
      cuttingsController,
      volumeNotFluidController,
    ]) {
      controller.text =
          _convertText(controller.text, _fluidVolumeUnit, nextFluidVolumeUnit);
    }
    _fluidVolumeUnit = nextFluidVolumeUnit;
  }

  double _number(TextEditingController controller) {
    final parsed = double.tryParse(controller.text.trim().replaceAll(',', '')) ?? 0;
    return AppUnits.convertValue(parsed, _fluidVolumeUnit, '(bbl)') ?? parsed;
  }

  Future<void> load({bool force = false}) async {
    if (wellId.isEmpty) {
      _clearFields();
      return;
    }
    if (isLoading.value && !force) return;

    isLoading.value = true;
    try {
      final result = await _repository.getOtherVolAdditionList(wellId);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load Other Vol Addition');
      }
      final envelope = result['data'];
      final data = envelope is Map<String, dynamic>
          ? envelope['data']
          : envelope is Map
              ? Map<String, dynamic>.from(envelope)['data']
              : null;
      final items = data is List ? data : const [];
      if (items.isEmpty) {
        _clearFields();
        return;
      }

      final item = Map<String, dynamic>.from(items.first as Map);
      recordId.value = (item['_id'] ?? item['id'] ?? '').toString();
      formationController.text = _convertText(
        (item['formation'] ?? '').toString(),
        '(bbl)',
        _fluidVolumeUnit,
      );
      cuttingsController.text = _convertText(
        (item['cuttings'] ?? '').toString(),
        '(bbl)',
        _fluidVolumeUnit,
      );
      volumeNotFluidController.text =
          _convertText(
        (item['volumeNotFluid'] ?? '').toString(),
        '(bbl)',
        _fluidVolumeUnit,
      );
    } catch (_) {
      _clearFields();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> save() async {
    if (wellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }

    final body = {
      'formation': _number(formationController),
      'cuttings': _number(cuttingsController),
      'volumeNotFluid': _number(volumeNotFluidController),
    };

    final total = (body['formation'] as double) +
        (body['cuttings'] as double) +
        (body['volumeNotFluid'] as double);

    if (total <= 0) {
      if (recordId.value == null || recordId.value!.isEmpty) {
        return {'success': true, 'message': 'No Other Vol Addition data to save'};
      }
      final deleteRes = await _repository.deleteOtherVolAddition(
        wellId,
        recordId.value!,
      );
      if (deleteRes['success'] == true) {
        _clearFields();
        await _refreshPitState();
      }
      return deleteRes;
    }

    final result = recordId.value != null && recordId.value!.isNotEmpty
        ? await _repository.updateOtherVolAddition(wellId, recordId.value!, body)
        : await _repository.createOtherVolAddition(wellId, body);

    if (result['success'] == true) {
      await load(force: true);
      await _refreshPitState();
    }
    return result;
  }
}
