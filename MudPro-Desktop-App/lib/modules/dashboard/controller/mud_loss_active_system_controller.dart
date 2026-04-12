import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class MudLossActiveSystemController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  final isLoading = false.obs;
  final recordId = RxnString();
  final dynamicRows = <Map<String, String>>[
    {'loss': '', 'volume': ''},
    {'loss': '', 'volume': ''},
  ].obs;

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
    for (final controller in fields.values) {
      controller.dispose();
    }
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
    recordId.value = null;
  }

  double _number(String key) => double.tryParse(fields[key]!.text.trim()) ?? 0;

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
        entry.value.text = value == null ? '' : value.toString();
      }
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
