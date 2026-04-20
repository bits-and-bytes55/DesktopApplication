import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
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
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => load(force: true),
    );
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    _unitWorkers.clear();
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
    for (final controller in fields.values) {
      controller.text =
          _convertText(controller.text, _fluidVolumeUnit, nextFluidVolumeUnit);
    }
    extraLossVolumeController.text = _convertText(
      extraLossVolumeController.text,
      _fluidVolumeUnit,
      nextFluidVolumeUnit,
    );
    _fluidVolumeUnit = nextFluidVolumeUnit;
  }

  double _number(String key) {
    final parsed =
        double.tryParse(fields[key]!.text.trim().replaceAll(',', '')) ?? 0;
    return AppUnits.convertValue(parsed, _fluidVolumeUnit, '(bbl)') ?? parsed;
  }

  double _extraLossNumber() {
    final parsed =
        double.tryParse(extraLossVolumeController.text.trim().replaceAll(',', '')) ?? 0;
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
        entry.value.text = value == null
            ? ''
            : _convertText(value.toString(), '(bbl)', _fluidVolumeUnit);
      }
      final extraLossLabel = (item['extraLossLabel'] ?? '').toString();
      selectedExtraLoss.value =
          extraLossOptions.contains(extraLossLabel) ? extraLossLabel : '';
      final extraLossVolume = item['extraLossVolume'];
      extraLossVolumeController.text = extraLossVolume == null
          ? ''
          : _convertText(extraLossVolume.toString(), '(bbl)', _fluidVolumeUnit);
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
