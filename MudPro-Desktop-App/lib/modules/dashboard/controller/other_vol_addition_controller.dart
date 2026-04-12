import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
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

  String get wellId => currentBackendWellId.trim();

  @override
  void onInit() {
    super.onInit();
    load();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) => load(force: true));
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
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

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

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
      formationController.text = (item['formation'] ?? '').toString();
      cuttingsController.text = (item['cuttings'] ?? '').toString();
      volumeNotFluidController.text =
          (item['volumeNotFluid'] ?? '').toString();
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
