import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class OtherVolAdditionController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  final isLoading = false.obs;
  final recordId = RxnString();
  final formationController = TextEditingController();
  final cuttingsController = TextEditingController();
  final volumeNotFluidController = TextEditingController();
  final selectedDropdownAddition = ''.obs;

  static const List<String> additionOptions = [
    'Formation',
    'Cuttings',
    'Volume Not Fluid',
  ];

  Worker? _wellWorker;
  Worker? _reportWorker;

  String get wellId => currentBackendWellId.trim();

  @override
  void onInit() {
    super.onInit();
    load();
    _wellWorker = ever<String>(
      padWellContext.selectedWellId,
      (_) => _reloadForContext(),
    );
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => _reloadForContext(),
    );
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
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
    selectedDropdownAddition.value = '';
    recordId.value = null;
  }

  TextEditingController controllerForAddition(String label) {
    switch (label) {
      case 'Formation':
        return formationController;
      case 'Cuttings':
        return cuttingsController;
      case 'Volume Not Fluid':
        return volumeNotFluidController;
      default:
        return formationController;
    }
  }

  Future<void> _reloadForContext() async {
    _clearFields();
    await load(force: true);
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0;
  }

  String _formatNumber(dynamic value) {
    final n = _parseNumber(value?.toString() ?? '');
    if (n == 0 && (value == null || value.toString().trim().isEmpty)) {
      return '';
    }
    return n.toStringAsFixed(2);
  }

  double _number(TextEditingController controller) {
    return _parseNumber(controller.text);
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map && value['data'] is List) return value['data'] as List;
    return const [];
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
      final items = _extractList(result['data']);
      if (items.isEmpty) {
        _clearFields();
        return;
      }

      final item = Map<String, dynamic>.from(items.first as Map);
      recordId.value = (item['_id'] ?? item['id'] ?? '').toString();
      formationController.text = _formatNumber(item['formation']);
      cuttingsController.text = _formatNumber(item['cuttings']);
      volumeNotFluidController.text = _formatNumber(item['volumeNotFluid']);
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
