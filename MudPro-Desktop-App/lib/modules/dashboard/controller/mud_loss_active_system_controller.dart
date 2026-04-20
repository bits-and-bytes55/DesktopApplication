import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class MudLossActiveSystemController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  final isLoading = false.obs;
  final recordId = RxnString();
  final selectedExtraLoss = ''.obs;
  final extraLossVolumeController = TextEditingController();

  static const List<String> extraLossOptions = [
    'Trip Loss',
    'Displacement',
    'Left in hole',
    'Spilled',
    'Isolated contaminated Vol',
  ];

  final Map<String, TextEditingController> fields = {
    'cuttingsRetention': TextEditingController(),
    'seepage': TextEditingController(),
    'dump': TextEditingController(),
    'shakers': TextEditingController(),
    'centrifuge': TextEditingController(),
    'evaporation': TextEditingController(),
    'pitCleaning': TextEditingController(),
    'formation': TextEditingController(),
    'abandonInHole': TextEditingController(),
    'leftBehindCasing': TextEditingController(),
    'tripping': TextEditingController(),
  };

  Worker? _wellWorker;
  Worker? _reportWorker;

  String get wellId => currentBackendWellId.trim();

  @override
  void onInit() {
    super.onInit();
    load();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) => load(force: true));
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => load(force: true),
    );
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final controller in fields.values) {
      controller.dispose();
    }
    extraLossVolumeController.dispose();
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
    for (final controller in fields.values) {
      controller.clear();
    }
    selectedExtraLoss.value = '';
    extraLossVolumeController.clear();
    recordId.value = null;
  }

  String _formatNumber(dynamic value) {
    final parsed = _parseNumber(value?.toString() ?? '');
    if (parsed == 0 && (value == null || value.toString().trim().isEmpty)) {
      return '';
    }
    return parsed
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  double _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0;

  double _number(String key) {
    return _parseNumber(fields[key]!.text);
  }

  double _extraLossNumber() {
    return _parseNumber(extraLossVolumeController.text);
  }

  Future<void> load({bool force = false}) async {
    if (wellId.isEmpty) {
      _clearFields();
      return;
    }
    if (isLoading.value && !force) return;

    isLoading.value = true;
    try {
      final result = await _repository.getMudLossList(wellId);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load Mud Loss');
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
      for (final entry in fields.entries) {
        final value = item[entry.key];
        entry.value.text = _formatNumber(value);
      }
      final extraLossLabel = (item['extraLossLabel'] ?? '').toString();
      selectedExtraLoss.value =
          extraLossOptions.contains(extraLossLabel) ? extraLossLabel : '';
      final extraLossVolume = item['extraLossVolume'];
      extraLossVolumeController.text = _formatNumber(extraLossVolume);
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

    final body = <String, dynamic>{
      'cuttingsRetention': _number('cuttingsRetention'),
      'seepage': _number('seepage'),
      'dump': _number('dump'),
      'shakers': _number('shakers'),
      'centrifuge': _number('centrifuge'),
      'evaporation': _number('evaporation'),
      'pitCleaning': _number('pitCleaning'),
      'formation': _number('formation'),
      'abandonInHole': _number('abandonInHole'),
      'leftBehindCasing': _number('leftBehindCasing'),
      'tripping': _number('tripping'),
      'extraLossLabel': selectedExtraLoss.value.trim(),
      'extraLossVolume': _extraLossNumber(),
    };

    final total = body.values
        .map((value) => value is num ? value.toDouble() : 0.0)
        .fold<double>(0, (sum, value) => sum + value);

    if (total <= 0) {
      if (recordId.value == null || recordId.value!.isEmpty) {
        return {'success': true, 'message': 'No Mud Loss data to save'};
      }
      final deleteRes = await _repository.deleteMudLoss(wellId, recordId.value!);
      if (deleteRes['success'] == true) {
        _clearFields();
        await _refreshPitState();
      }
      return deleteRes;
    }

    final result = recordId.value != null && recordId.value!.isNotEmpty
        ? await _repository.updateMudLoss(wellId, recordId.value!, body)
        : await _repository.createMudLoss(wellId, body);

    if (result['success'] == true) {
      await load(force: true);
      await _refreshPitState();
    }
    return result;
  }
}
